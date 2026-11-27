"""
place_submissions_api.py
========================
Community-submitted social links and owner notes for places, with admin
moderation: the public submit endpoint and the admin review queue.

Registered by places_api_protected.py as `place_submissions_bp`.

Public endpoint
---------------
    POST /api/place/<place_id>/submit
        headers: X-Init-Data: <raw Telegram WebApp initData>
        body:    {"field": "telegram|tiktok|instagram|note", "value": "..."}

Nothing here writes to `main_db` — a submission only ever creates a `pending`
row. Values reach the place itself through the admin approve path in Phase 4.

Every rejection carries a stable machine-readable `code` alongside the English
`error` text, so the mini-app can localise the message per code instead of
displaying server English to Uzbek/Russian users.

Configuration (set on app.config by places_api_protected.py, defaults below):
    PLACE_SUBMISSIONS_DB               path to main_db.sqlite
    PLACE_SUBMISSIONS_BOT_TOKEN        bot token, used for initData HMAC + notify
    PLACE_SUBMISSIONS_ADMIN_CHAT_ID    Telegram chat that receives new-submission pings
    PLACE_SUBMISSIONS_ADMIN_URL        link included in that ping
    PLACE_SUBMISSIONS_REQUIRE_SIGNATURE  verify initData (default True)
"""

import hashlib
import hmac
import html
import json
import logging
import re
import sqlite3
import threading
from datetime import datetime, timedelta, timezone
from urllib.parse import parse_qsl, urlparse, unquote

import requests
from flask import Blueprint, current_app, jsonify, request, session

bp = Blueprint('place_submissions', __name__)
logger = logging.getLogger(__name__)


# ============================================
# CONFIGURATION
# ============================================

DEFAULT_DB_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'
DEFAULT_ADMIN_CHAT_ID = 352835325
DEFAULT_ADMIN_URL = 'https://vegukin-api.duckdns.org/admin/places'

# Rolling 24h quota per Telegram user, counted across every place and field and
# across every status. A real contributor filling in one place needs at most 4
# (three socials + note); 5 leaves room for that plus one correction elsewhere.
MAX_SUBMISSIONS_PER_DAY = 5

# Long enough for opening hours + days off + a short announcement, short enough
# to render in a card without a "read more".
NOTE_MAX_LENGTH = 500
NOTE_MIN_LENGTH = 2

# initData older than this is refused, so a leaked initData string from an old
# session cannot be replayed indefinitely.
INIT_DATA_MAX_AGE_SECONDS = 24 * 60 * 60

# Fields Telegram appends AFTER computing `hash`, so they are not part of the
# data-check-string. `signature` arrived with Bot API 7.10 (Ed25519, for
# third-party validation) and silently broke every validator that hashed
# whatever it received — the symptom is that every submission from an
# up-to-date client fails verification while older clients still work.
POST_HASH_FIELDS = ('signature',)

# KST, matching store_interaction() in places_api_protected.py. created_at is
# stored as 'YYYY-MM-DD HH:MM:SS' so it sorts and range-compares as plain TEXT.
KST = timezone(timedelta(hours=9))
TS_FORMAT = '%Y-%m-%d %H:%M:%S'

# field -> main_db column. Names line up 1:1 so approve is a lookup.
FIELD_COLUMNS = {
    'telegram': 'telegram_url',
    'tiktok': 'tiktok_url',
    'instagram': 'instagram_url',
    'note': 'owner_note',
}

FIELD_LABELS = {
    'telegram': 'Telegram',
    'tiktok': 'TikTok',
    'instagram': 'Instagram',
    'note': 'Info note',
}


def _cfg(key, default):
    try:
        return current_app.config.get(key, default)
    except RuntimeError:      # outside an app context (unit tests)
        return default


def _db():
    conn = sqlite3.connect(_cfg('PLACE_SUBMISSIONS_DB', DEFAULT_DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn


def _now():
    return datetime.now(KST)


def _fmt(dt):
    return dt.strftime(TS_FORMAT)


def _err(code, message, status=400, **extra):
    payload = {'success': False, 'code': code, 'error': message}
    payload.update(extra)
    return jsonify(payload), status


# ============================================
# VALUE NORMALISATION
# ============================================
#
# Two jobs, and the second is the important one:
#
#   1. accept the shapes people actually paste (@handle, bare handle, mobile
#      URL, link with tracking junk on the end)
#   2. emit a string that is safe to drop straight into an href
#
# Because every accepted value is rebuilt from a whitelisted host plus a
# character-checked handle, the stored value can never carry a javascript:
# scheme, a foreign host, or markup. The detail page renders it as an href
# without having to re-validate.

class SubmissionValueError(Exception):
    """Rejection carrying a stable code for the frontend to localise."""

    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message


# Zero-width and bidi-control characters. Stripped everywhere: they are
# invisible, so they let two different strings look identical.
INVISIBLES = re.compile('[\\u200b-\\u200f\\u202a-\\u202e\\u2060-\\u2064\\ufeff]')

# C0/C1 controls except newline and tab.
CONTROLS = re.compile(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]')

TELEGRAM_HOSTS = {'t.me', 'telegram.me', 'telegram.dog', 'www.t.me'}
TIKTOK_HOSTS = {'tiktok.com', 'www.tiktok.com', 'm.tiktok.com',
                'vm.tiktok.com', 'vt.tiktok.com'}
TIKTOK_SHORT_HOSTS = {'vm.tiktok.com', 'vt.tiktok.com'}
INSTAGRAM_HOSTS = {'instagram.com', 'www.instagram.com', 'instagr.am',
                   'www.instagr.am'}

# Telegram: 5-32 chars, letter-initial, letters/digits/underscore. Accepting
# from 4 avoids false rejects on a few legacy handles.
RE_TG_HANDLE = re.compile(r'^[A-Za-z][A-Za-z0-9_]{3,31}$')
# Private invite links: t.me/+CODE and the older t.me/joinchat/CODE
RE_TG_INVITE = re.compile(r'^[A-Za-z0-9_-]{5,64}$')

# TikTok: 2-24 chars, letters/digits/underscore/period.
RE_TT_HANDLE = re.compile(r'^[A-Za-z0-9._]{2,24}$')
RE_TT_SHORT = re.compile(r'^[A-Za-z0-9]{4,32}$')

# Instagram: 1-30 chars, letters/digits/underscore/period.
RE_IG_HANDLE = re.compile(r'^[A-Za-z0-9._]{1,30}$')

# Instagram paths that are content, not a profile.
IG_RESERVED = {'p', 'reel', 'reels', 'tv', 'stories', 'explore', 'accounts',
               'direct', 'about', 'developer', 'legal', 'privacy'}


def _clean(raw):
    """Shared first pass: strip invisibles, controls, surrounding whitespace."""
    if raw is None:
        return ''
    if not isinstance(raw, str):
        raw = str(raw)
    raw = raw.replace('\r\n', '\n').replace('\r', '\n')
    raw = INVISIBLES.sub('', raw)
    raw = CONTROLS.sub('', raw)
    return raw.strip()


def _parse_url(value):
    """
    Parse a pasted link. Returns (hostname, [path segments]).

    hostname comes from .hostname, never .netloc — that is what makes
    `https://t.me@evil.com/x` resolve to evil.com and get rejected rather than
    sailing through a naive "does it contain t.me" check.
    """
    candidate = value
    if not re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*://', candidate):
        candidate = 'https://' + candidate

    try:
        parsed = urlparse(candidate)
    except Exception:
        raise SubmissionValueError('invalid_url', 'That does not look like a link.')

    if parsed.scheme not in ('http', 'https'):
        raise SubmissionValueError('invalid_scheme', 'Only http and https links are accepted.')

    host = (parsed.hostname or '').lower()
    if not host:
        raise SubmissionValueError('invalid_url', 'That does not look like a link.')

    # Query and fragment are dropped: they only ever carry tracking junk
    # (?igshid=, ?utm_source=) and would otherwise make two links to the same
    # profile compare as different values.
    segments = [unquote(s) for s in parsed.path.split('/') if s]
    return host, segments


def _wrong_host(platform, host, expected):
    return SubmissionValueError(
        'wrong_host',
        f"That is not a {platform} link (got {host}). Expected {expected}."
    )


def normalise_telegram(raw):
    value = _clean(raw)
    if not value:
        raise SubmissionValueError('empty', 'Please enter a Telegram link or @username.')

    # Bare handle, with or without the @
    if not re.search(r'[/.]', value):
        handle = value.lstrip('@')
        if RE_TG_HANDLE.match(handle):
            return f'https://t.me/{handle}'
        raise SubmissionValueError(
            'invalid_handle',
            'A Telegram username is 5-32 characters: letters, digits and underscores.'
        )

    host, segments = _parse_url(value)
    if host not in TELEGRAM_HOSTS:
        raise _wrong_host('Telegram', host, 't.me')
    if not segments:
        raise SubmissionValueError('incomplete', 'Add the username after t.me/ — for example t.me/muslimvegukin.')

    # t.me/s/channel is the web-preview form of t.me/channel
    if segments[0] == 's' and len(segments) > 1:
        segments = segments[1:]

    first = segments[0]

    if first.startswith('+'):
        code = first[1:]
        if RE_TG_INVITE.match(code):
            return f'https://t.me/+{code}'
        raise SubmissionValueError('invalid_invite', 'That Telegram invite link looks incomplete.')

    if first == 'joinchat':
        if len(segments) > 1 and RE_TG_INVITE.match(segments[1]):
            return f'https://t.me/joinchat/{segments[1]}'
        raise SubmissionValueError('invalid_invite', 'That Telegram invite link looks incomplete.')

    handle = first.lstrip('@')
    if RE_TG_HANDLE.match(handle):
        return f'https://t.me/{handle}'

    raise SubmissionValueError(
        'invalid_handle',
        'A Telegram username is 5-32 characters: letters, digits and underscores.'
    )


def normalise_tiktok(raw):
    value = _clean(raw)
    if not value:
        raise SubmissionValueError('empty', 'Please enter a TikTok link or @username.')

    if not re.search(r'[/.]', value) or (value.startswith('@') and '/' not in value):
        handle = value.lstrip('@').lower()
        if RE_TT_HANDLE.match(handle):
            return f'https://www.tiktok.com/@{handle}'
        raise SubmissionValueError(
            'invalid_handle',
            'A TikTok username is 2-24 characters: letters, digits, dots and underscores.'
        )

    host, segments = _parse_url(value)
    if host not in TIKTOK_HOSTS:
        raise _wrong_host('TikTok', host, 'tiktok.com')

    # vm./vt. links are opaque redirects. Resolving them would mean an outbound
    # request to a user-supplied URL from the API host, so they are kept as-is
    # and the admin sees the real destination when reviewing.
    if host in TIKTOK_SHORT_HOSTS:
        if segments and RE_TT_SHORT.match(segments[0]):
            return f'https://{host}/{segments[0]}'
        raise SubmissionValueError('incomplete', 'That TikTok short link looks incomplete.')

    if not segments:
        raise SubmissionValueError('incomplete', 'Add the username after tiktok.com/ — for example tiktok.com/@muslimvegukin.')

    handle = segments[0].lstrip('@').lower()
    if RE_TT_HANDLE.match(handle):
        return f'https://www.tiktok.com/@{handle}'

    raise SubmissionValueError(
        'invalid_handle',
        'A TikTok username is 2-24 characters: letters, digits, dots and underscores.'
    )


def normalise_instagram(raw):
    value = _clean(raw)
    if not value:
        raise SubmissionValueError('empty', 'Please enter an Instagram link or @username.')

    if not re.search(r'[/.]', value.lstrip('@')) or (value.startswith('@') and '/' not in value):
        handle = value.lstrip('@').lower()
        if RE_IG_HANDLE.match(handle):
            return f'https://www.instagram.com/{handle}/'
        raise SubmissionValueError(
            'invalid_handle',
            'An Instagram username is up to 30 characters: letters, digits, dots and underscores.'
        )

    host, segments = _parse_url(value)
    if host not in INSTAGRAM_HOSTS:
        raise _wrong_host('Instagram', host, 'instagram.com')
    if not segments:
        raise SubmissionValueError('incomplete', 'Add the username after instagram.com/ — for example instagram.com/muslimvegukin.')

    handle = segments[0].lstrip('@').lower()

    if handle in IG_RESERVED:
        raise SubmissionValueError(
            'not_a_profile',
            'That is a link to a post, not to a profile. Please send the profile link.'
        )

    if RE_IG_HANDLE.match(handle):
        return f'https://www.instagram.com/{handle}/'

    raise SubmissionValueError(
        'invalid_handle',
        'An Instagram username is up to 30 characters: letters, digits, dots and underscores.'
    )


def normalise_note(raw):
    value = _clean(raw)
    if not value:
        raise SubmissionValueError('empty', 'Please write something first.')

    # Runs of spaces/tabs collapse, but newlines survive — opening hours are
    # far more readable one line per day. Three or more blank lines collapse to
    # one, so nobody can push the rest of the card off screen.
    value = re.sub(r'[ \t]+', ' ', value)
    value = re.sub(r' *\n *', '\n', value)
    value = re.sub(r'\n{3,}', '\n\n', value).strip()

    if len(value) < NOTE_MIN_LENGTH:
        raise SubmissionValueError('too_short', 'Please write something first.')

    # Rejected rather than truncated: silently cutting someone's text mid-word
    # and calling it success is worse than telling them.
    if len(value) > NOTE_MAX_LENGTH:
        raise SubmissionValueError(
            'too_long',
            f'Please keep it under {NOTE_MAX_LENGTH} characters '
            f'(yours is {len(value)}).'
        )

    return value


NORMALISERS = {
    'telegram': normalise_telegram,
    'tiktok': normalise_tiktok,
    'instagram': normalise_instagram,
    'note': normalise_note,
}


# ============================================
# TELEGRAM IDENTITY
# ============================================

def _data_check_string(data, exclude=()):
    return '\n'.join(f'{k}={data[k]}' for k in sorted(data) if k not in exclude)


def _token_list(bot_token):
    """
    Tokens to try, in order. A Mini App opened from a different bot than the
    one configured here is signed with that bot's token, and the failure is
    indistinguishable from a forgery — so allow extra tokens to be configured
    rather than making it look like an attack.
    """
    tokens = []
    if isinstance(bot_token, str):
        if bot_token:
            tokens.append(bot_token)
    elif bot_token:
        tokens.extend([t for t in bot_token if t])

    extra = _cfg('PLACE_SUBMISSIONS_BOT_TOKENS', None) or []
    if isinstance(extra, str):
        extra = [extra]
    for t in extra:
        if t and t not in tokens:
            tokens.append(t)
    return tokens


def verify_init_data(init_data, bot_token, max_age=INIT_DATA_MAX_AGE_SECONDS):
    """
    Verify Telegram WebApp initData per Telegram's documented algorithm and
    return the user dict.

    initDataUnsafe is exactly that — unsigned, client-controlled, and trivially
    forged with devtools. Attributing a submission to a forged ID would let one
    person spend everyone else's daily quota and pin the blame on a stranger, so
    the raw signed initData string is checked here instead.

    Returns (user_dict, None) or (None, (code, message)).
    """
    if not init_data:
        return None, ('no_init_data', 'Please open this page inside Telegram.')

    tokens = _token_list(bot_token)
    if not tokens:
        logger.error('initData verification requested but no bot token configured')
        return None, ('server_misconfigured', 'Submissions are temporarily unavailable.')

    try:
        pairs = parse_qsl(init_data, keep_blank_values=True, strict_parsing=False)
    except Exception:
        return None, ('bad_init_data', 'Please reopen this page inside Telegram.')

    data = dict(pairs)
    received_hash = data.pop('hash', None)
    if not received_hash:
        return None, ('bad_init_data', 'Please reopen this page inside Telegram.')

    matched = False
    for token in tokens:
        secret_key = hmac.new(b'WebAppData', token.encode(), hashlib.sha256).digest()
        # POST_HASH_FIELDS first — that is correct for current clients. The
        # second pass keeps older clients, which signed everything they sent,
        # working unchanged.
        for exclude in (POST_HASH_FIELDS, ()):
            check_string = _data_check_string(data, exclude)
            expected = hmac.new(secret_key, check_string.encode(), hashlib.sha256).hexdigest()
            if hmac.compare_digest(expected, received_hash):
                matched = True
                break
        if matched:
            break

    if not matched:
        # Field names only — `user` holds personal data and never goes to logs.
        logger.warning(
            'initData signature mismatch: fields=[%s], tokens_tried=%d. '
            'Usually either an unknown field added by a new client, or the '
            'Mini App being served by a bot whose token is not configured.',
            ','.join(sorted(data)), len(tokens))
        return None, ('bad_signature', 'Could not verify your Telegram account.')

    # Freshness: a leaked initData string should not stay usable forever.
    try:
        auth_date = int(data.get('auth_date', '0'))
    except (TypeError, ValueError):
        auth_date = 0
    if auth_date <= 0:
        return None, ('bad_init_data', 'Please reopen this page inside Telegram.')

    age = datetime.now(timezone.utc).timestamp() - auth_date
    if age > max_age:
        return None, ('stale_init_data', 'Your session expired. Please reopen the page.')

    try:
        user = json.loads(data.get('user', '{}'))
    except (TypeError, ValueError):
        user = {}

    if not user.get('id'):
        return None, ('no_user', 'Could not read your Telegram account.')

    return user, None


def resolve_submitter(allow_anonymous=False):
    """
    Identify the submitting user. Returns (user_dict, None) or (None, (code, msg)).

    From the app (Authorization: Bearer): its user, the same shape. Someone who
    has not signed in there is refused with sign_in_required unless
    allow_anonymous (watching places and areas needs no sign-in).
    """
    if request.headers.get('Authorization', '').startswith('Bearer '):
        from app_accounts import ERROR_MESSAGES, resolve_app_user
        user, code = resolve_app_user(allow_anonymous)
        return (user, None) if user else (None, (code, ERROR_MESSAGES[code]))

    bot_token = _token_list(_cfg('PLACE_SUBMISSIONS_BOT_TOKEN', None))
    require = _cfg('PLACE_SUBMISSIONS_REQUIRE_SIGNATURE', True)
    init_data = request.headers.get('X-Init-Data', '')

    if require:
        return verify_init_data(init_data, bot_token)

    # Escape hatch for local debugging only. Never leave this off in production:
    # with it off, the per-user quota is bypassable by editing one number.
    if init_data:
        user, _ = verify_init_data(init_data, bot_token)
        if user:
            return user, None

    body = request.get_json(silent=True) or {}
    unsafe = body.get('user') or {}
    if unsafe.get('id'):
        logger.warning('Accepting UNVERIFIED submitter id=%s — signature check is off',
                       unsafe.get('id'))
        return {'id': unsafe['id'], 'username': unsafe.get('username'),
                'first_name': unsafe.get('first_name')}, None

    return None, ('no_user', 'Could not read your Telegram account.')


def submitter_name(user):
    """The name the admin sees; for an app user without Telegram, with their WhatsApp number or email."""
    name = (user.get('username')
            or user.get('first_name')
            or f"id{user.get('id')}")
    if user.get('contact') and not user.get('username'):
        name = f"{name} ({user['contact']})"
    return name


# ============================================
# ADMIN NOTIFICATION
# ============================================

def notify_admin(place_id, place_name, field, new_value, current_value, user):
    """
    Ping the admin chat. Fire-and-forget in a daemon thread, mirroring
    store_user_if_new() — a Telegram outage must never fail a submission.
    """
    token = _cfg('PLACE_SUBMISSIONS_BOT_TOKEN', None)
    chat_id = _cfg('PLACE_SUBMISSIONS_ADMIN_CHAT_ID', DEFAULT_ADMIN_CHAT_ID)
    admin_url = _cfg('PLACE_SUBMISSIONS_ADMIN_URL', DEFAULT_ADMIN_URL)
    if not token or not chat_id:
        return

    def esc(v):
        return html.escape(str(v) if v is not None else '—')

    username = user.get('username')
    who = f"@{esc(username)}" if username else esc(user.get('first_name') or 'unknown')
    if user.get('contact') and not username:
        who += f" · {esc(user['contact'])}"

    lines = [
        '🆕 <b>New place submission</b>',
        '',
        f"<b>Place:</b> {esc(place_name)} (#{esc(place_id)})",
        f"<b>Field:</b> {esc(FIELD_LABELS.get(field, field))}",
        '',
        f"<b>Current:</b> {esc(current_value) if current_value else '—'}",
        f"<b>Proposed:</b> {esc(new_value)}",
        '',
        f"<b>From:</b> {who} (<code>{esc(user.get('id'))}</code>)",
        '',
        f"Review: {esc(admin_url)}",
    ]
    text = '\n'.join(lines)

    def _send():
        try:
            requests.post(
                f'https://api.telegram.org/bot{token}/sendMessage',
                json={
                    'chat_id': chat_id,
                    'text': text,
                    'parse_mode': 'HTML',
                    # The proposed value is a stranger's URL. Without this,
                    # Telegram would fetch it to build a preview card in the
                    # admin's chat before anyone has reviewed it.
                    'disable_web_page_preview': True,
                },
                timeout=10,
            )
        except Exception as e:
            logger.error(f'Admin notify failed for place {place_id}/{field}: {e}')

    threading.Thread(target=_send, daemon=True).start()


# ============================================
# ENDPOINT
# ============================================

@bp.route('/api/place/<int:place_id>/submit', methods=['POST', 'OPTIONS'])
def submit_place_field(place_id):
    """
    Queue a community-submitted value for one field of one place.

    Always creates a `pending` row and nothing else — approval in the admin
    panel is what writes to main_db.
    """
    if request.method == 'OPTIONS':
        return '', 200

    body = request.get_json(silent=True) or {}
    field = (body.get('field') or '').strip().lower()

    if field not in FIELD_COLUMNS:
        return _err('invalid_field',
                    f"Unknown field. Expected one of: {', '.join(FIELD_COLUMNS)}.")

    user, auth_error = resolve_submitter()
    if auth_error:
        code, message = auth_error
        status = 503 if code == 'server_misconfigured' else 401
        return _err(code, message, status)

    try:
        value = NORMALISERS[field](body.get('value'))
    except SubmissionValueError as e:
        return _err(e.code, e.message)

    column = FIELD_COLUMNS[field]
    tg_id = user['id']
    now = _now()

    conn = None
    try:
        conn = _db()

        place = conn.execute(
            f"SELECT Unique_number, Name, {column} AS current_value "
            "FROM main_db WHERE Unique_number = ?",
            (place_id,)
        ).fetchone()

        if not place:
            return _err('place_not_found', 'That place no longer exists.', 404)

        current_value = place['current_value']

        # Nothing to review if it already says exactly this.
        if current_value and current_value.strip() == value:
            return _err('same_as_current',
                        'That is already what is saved for this place.', 409)

        pending = conn.execute(
            "SELECT id FROM place_submissions "
            "WHERE place_id = ? AND field = ? AND status = 'pending'",
            (place_id, field)
        ).fetchone()

        if pending:
            return _err('already_pending',
                        'A change to this field is already waiting for review.', 409)

        # Rolling 24h window. created_at is KST text in a sortable format, so a
        # string comparison is a correct range query and uses the index.
        window_start = _fmt(now - timedelta(days=1))
        used = conn.execute(
            "SELECT COUNT(*) FROM place_submissions "
            "WHERE submitted_by_tg_id = ? AND created_at >= ?",
            (tg_id, window_start)
        ).fetchone()[0]

        if used >= MAX_SUBMISSIONS_PER_DAY:
            oldest = conn.execute(
                "SELECT created_at FROM place_submissions "
                "WHERE submitted_by_tg_id = ? AND created_at >= ? "
                "ORDER BY created_at ASC LIMIT 1",
                (tg_id, window_start)
            ).fetchone()
            retry_after = None
            if oldest:
                try:
                    first = datetime.strptime(oldest[0], TS_FORMAT).replace(tzinfo=KST)
                    retry_after = max(0, int((first + timedelta(days=1) - now).total_seconds()))
                except ValueError:
                    pass
            return _err('rate_limited',
                        f'You have reached the limit of {MAX_SUBMISSIONS_PER_DAY} '
                        'suggestions per day. Please try again tomorrow.',
                        429, retry_after=retry_after)

        try:
            cur = conn.execute(
                "INSERT INTO place_submissions "
                "(place_id, field, value, current_value, status, "
                " submitted_by_tg_id, submitted_by_username, created_at) "
                "VALUES (?, ?, ?, ?, 'pending', ?, ?, ?)",
                (place_id, field, value, current_value, tg_id,
                 submitter_name(user), _fmt(now))
            )
            conn.commit()
            submission_id = cur.lastrowid
        except sqlite3.IntegrityError:
            # Two submissions for the same field landing together. The partial
            # unique index settles it; the loser gets the same answer as if the
            # SELECT above had seen the row.
            conn.rollback()
            return _err('already_pending',
                        'A change to this field is already waiting for review.', 409)

        logger.info(
            f"Submission #{submission_id}: place {place_id} field={field} "
            f"by {tg_id} ({submitter_name(user)})"
        )

        notify_admin(place_id, place['Name'], field, value, current_value, user)

        return jsonify({
            'success': True,
            'submission_id': submission_id,
            'place_id': place_id,
            'field': field,
            'value': value,
            'status': 'pending',
        }), 201

    except sqlite3.Error as e:
        logger.error(f'DB error in submit for place {place_id}/{field}: {e}')
        return _err('server_error', 'Could not save your suggestion. Please try again.', 500)
    finally:
        if conn:
            conn.close()


# ============================================
# HELPER — used by places_api_protected.py
# ============================================

def move_submitter(old_id, new_id):
    """An app user signed in and their id changed: their suggestions follow (and count to their daily limit)."""
    conn = _db()
    try:
        conn.execute("UPDATE place_submissions SET submitted_by_tg_id = ? WHERE submitted_by_tg_id = ?",
                     (new_id, old_id))
        conn.commit()
    finally:
        conn.close()


def delete_submitter(user_id):
    """The person deleted their app account: suggestions not yet reviewed go; reviewed ones lose their name."""
    conn = _db()
    try:
        conn.execute("DELETE FROM place_submissions WHERE submitted_by_tg_id = ? AND status = 'pending'",
                     (user_id,))
        conn.execute("UPDATE place_submissions SET submitted_by_username = NULL WHERE submitted_by_tg_id = ?",
                     (user_id,))
        conn.commit()
    finally:
        conn.close()


def get_pending_fields(conn, place_id):
    """
    Fields with a submission awaiting review, for /api/place/<id>.

    Lets the detail page show "waiting for review" instead of offering a form
    that would come back 409. Takes an open connection so the detail endpoint
    does not pay for a second one.
    """
    try:
        rows = conn.execute(
            "SELECT field FROM place_submissions "
            "WHERE place_id = ? AND status = 'pending'",
            (place_id,)
        ).fetchall()
        return [r[0] for r in rows]
    except sqlite3.Error as e:
        # A missing table (migration not run) must not take the detail page
        # down — the page simply shows no pending badges.
        logger.warning(f'Could not read pending submissions for {place_id}: {e}')
        return []


# ============================================
# ADMIN QUEUE
# ============================================
#
# Approve writes the value onto the place; reject only stamps the row. Neither
# ever deletes, so the queue doubles as an audit trail of what was proposed and
# what was done about it.

def _admin_guard():
    """Returns an error response when the caller is not a logged-in admin."""
    if not session.get('admin_logged_in'):
        return _err('unauthorized', 'Unauthorized.', 401)
    return None


def _submission_row(conn, submission_id):
    return conn.execute(
        "SELECT s.*, m.Name AS place_name, m.Building_type "
        "FROM place_submissions s "
        "LEFT JOIN main_db m ON m.Unique_number = s.place_id "
        "WHERE s.id = ?",
        (submission_id,)
    ).fetchone()


@bp.route('/api/admin/submissions', methods=['GET'])
def admin_list_submissions():
    """
    The moderation queue.

    LEFT JOIN, so a submission whose place was deleted still appears rather
    than silently vanishing — there is no foreign key to keep them in step.
    """
    guard = _admin_guard()
    if guard:
        return guard

    status = (request.args.get('status') or 'pending').strip().lower()
    if status not in ('pending', 'approved', 'rejected', 'all'):
        status = 'pending'
    try:
        limit = min(int(request.args.get('limit', 200)), 500)
    except (TypeError, ValueError):
        limit = 200

    conn = None
    try:
        conn = _db()
        sql = (
            "SELECT s.id, s.place_id, s.field, s.value, s.current_value, s.status, "
            "       s.submitted_by_tg_id, s.submitted_by_username, s.created_at, "
            "       s.reviewed_at, s.admin_note, "
            "       m.Name AS place_name, m.Building_type "
            "FROM place_submissions s "
            "LEFT JOIN main_db m ON m.Unique_number = s.place_id "
        )
        params = []
        if status != 'all':
            sql += "WHERE s.status = ? "
            params.append(status)
        # Pending first, then newest — the queue is a worklist, not an archive.
        sql += "ORDER BY (s.status = 'pending') DESC, s.created_at DESC LIMIT ?"
        params.append(limit)

        rows = [dict(r) for r in conn.execute(sql, params).fetchall()]

        counts = {'pending': 0, 'approved': 0, 'rejected': 0}
        for r in conn.execute(
                "SELECT status, COUNT(*) AS n FROM place_submissions GROUP BY status"):
            counts[r['status']] = r['n']

        return jsonify({'success': True, 'submissions': rows, 'counts': counts})
    except sqlite3.Error as e:
        logger.error(f'Failed to list submissions: {e}')
        return _err('server_error', str(e), 500)
    finally:
        if conn:
            conn.close()


@bp.route('/api/admin/submissions/<int:submission_id>/approve', methods=['POST'])
def admin_approve_submission(submission_id):
    """Write the proposed value onto the place and stamp the row approved."""
    guard = _admin_guard()
    if guard:
        return guard

    body = request.get_json(silent=True) or {}
    admin_note = (body.get('admin_note') or '').strip() or None
    override = body.get('value')

    conn = None
    try:
        conn = _db()
        row = _submission_row(conn, submission_id)
        if not row:
            return _err('not_found', 'Submission not found.', 404)
        if row['status'] != 'pending':
            return _err('already_reviewed',
                        f"Already {row['status']}.", 409)

        column = FIELD_COLUMNS.get(row['field'])
        if not column:
            return _err('invalid_field', f"Unknown field {row['field']}.", 400)

        place = conn.execute(
            "SELECT 1 FROM main_db WHERE Unique_number = ?", (row['place_id'],)
        ).fetchone()
        if not place:
            return _err('place_missing',
                        'That place no longer exists — reject this instead.', 409)

        # The admin may have corrected the value before approving — a typo in a
        # handle, say. It goes through the same normaliser as a public
        # submission, so an edited value cannot bypass the host whitelist or
        # the note length cap.
        value = row['value']
        if override is not None and str(override).strip() != str(value).strip():
            try:
                value = NORMALISERS[row['field']](override)
            except SubmissionValueError as e:
                return _err(e.code, e.message, 400)

        # Both statements in one transaction: the value landing on the place and
        # the row leaving the queue must happen together or not at all.
        conn.execute('BEGIN')
        try:
            conn.execute(
                f"UPDATE main_db SET {column} = ? WHERE Unique_number = ?",
                (value, row['place_id'])
            )
            # Store what was actually applied, so the history is not a record of
            # something that never landed.
            conn.execute(
                "UPDATE place_submissions "
                "SET status = 'approved', reviewed_at = ?, admin_note = ?, value = ? "
                "WHERE id = ?",
                (_fmt(_now()), admin_note, value, submission_id)
            )
            conn.execute('COMMIT')
        except Exception:
            conn.execute('ROLLBACK')
            raise

        edited = ' (edited by admin)' if value != row['value'] else ''
        logger.info(f"[ADMIN] Approved submission #{submission_id}: "
                    f"place {row['place_id']} {row['field']} = {value}{edited}")
        return jsonify({'success': True,
                        'submission': dict(_submission_row(conn, submission_id))})
    except sqlite3.Error as e:
        logger.error(f'Approve failed for #{submission_id}: {e}')
        return _err('server_error', str(e), 500)
    finally:
        if conn:
            conn.close()


@bp.route('/api/admin/submissions/<int:submission_id>/reject', methods=['POST'])
def admin_reject_submission(submission_id):
    """Stamp the row rejected. The place is untouched and nothing is deleted."""
    guard = _admin_guard()
    if guard:
        return guard

    body = request.get_json(silent=True) or {}
    admin_note = (body.get('admin_note') or '').strip() or None

    conn = None
    try:
        conn = _db()
        row = _submission_row(conn, submission_id)
        if not row:
            return _err('not_found', 'Submission not found.', 404)
        if row['status'] != 'pending':
            return _err('already_reviewed', f"Already {row['status']}.", 409)

        conn.execute(
            "UPDATE place_submissions "
            "SET status = 'rejected', reviewed_at = ?, admin_note = ? WHERE id = ?",
            (_fmt(_now()), admin_note, submission_id)
        )
        conn.commit()

        logger.info(f"[ADMIN] Rejected submission #{submission_id}")
        return jsonify({'success': True,
                        'submission': dict(_submission_row(conn, submission_id))})
    except sqlite3.Error as e:
        logger.error(f'Reject failed for #{submission_id}: {e}')
        return _err('server_error', str(e), 500)
    finally:
        if conn:
            conn.close()
