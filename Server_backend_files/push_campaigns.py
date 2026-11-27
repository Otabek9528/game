"""
push_campaigns.py
=================
Messages to the app's users from the admin panel (/admin/push): write one
(bold, italic, underline, strikethrough, links, quotes, photos), choose who
gets it, see how it will look, test it on your own phone, send it now or at
a set time, and follow what happened to every phone.

What a campaign is
------------------
    title     the notification's first line. Plain text: no phone shows
              formatting in a notification, on Android or iOS.
    html      the message: <b> <i> <u> <s> <a href> <blockquote> and line
              breaks, nothing else (Telegram's HTML, so the same text can go
              to the bot). The notification shows it as plain text, cut to
              fit; the app's inbox shows it whole and formatted. App versions
              from before this show it whole but plain, links still tappable.
    images    photos uploaded here (re-encoded, at most 10). The first shows
              large in the notification on Android; all show in the message.
              iOS shows no photo in a notification without a notification
              service extension, which the app doesn't have.
    target    an app section the message's button opens (optional)
    ttl_hours how long FCM keeps trying a phone that is off
    audience  who: see _people()

Every person who gets it finds it in the app's inbox, phone notifications on
or off; phones that take notifications get one too.

Sending
-------
"Send" and a schedule that comes due both set the campaign to `sending`; a
worker thread in this process does the rest, so the panel never waits:

    1. the audience is counted again and one row per phone is written to
       `deliveries` (unique per campaign and phone);
    2. each person gets the message in their inbox (unique per campaign and
       person in app_accounts' inbox);
    3. phones are sent to in batches, PUSH_CONCURRENCY at a time. A row is
       marked `sending` (and committed) before its request, `sent` after.

Retries and duplicates: a temporary failure (network, FCM busy or over quota)
is tried again after 1, 5 and 20 minutes, or later when FCM says so. A dead
token (app uninstalled) is forgotten and never retried; an error retrying
can't fix is not retried. A row found `sending` after a restart is marked
`unknown` and never re-sent: FCM may already have it. Every notification of a
campaign carries the same Android tag and iOS collapse id, so even a second
copy would replace the first on the phone instead of showing twice.

Mass-send guards: the panel shows exactly who before sending, and the server
refuses unless the count it is shown is still the count (expected_users); the
same message sent in the last 24 hours needs a second confirmation; a
campaign moves draft -> sending once (a second click finds it sending); if the
first phones all fail for the message itself, the campaign stops.

What is measured
----------------
    sent      FCM accepted it for the phone. Not proof of delivery.
    failed    dead token, an error retries didn't fix, or unknown (above)
    received  the phone got it. Android only, and only app versions that
              report (sessions.reports); iOS can't report this.
    opened    the notification was tapped (apps that report)
    read      the message was opened in the app (apps that report)
    clicked   a link in it was tapped (apps that report)

Rates are over the phones (or people) whose app reports, never over all of
them. The app reports to POST /api/app/push-event with the delivery's id and
a key only this server can make (in the push's data and the inbox's).

Endpoints
---------
Admin (the /admin login; changes also need the X-Push-Panel header):

    GET    /admin/push                            the panel
    GET    /api/admin/push/overview               campaigns (filters) with their numbers
    POST   /api/admin/push/campaigns              a new draft
    GET    /api/admin/push/campaigns/<id>
    PUT    /api/admin/push/campaigns/<id>         save (draft or scheduled)
    DELETE /api/admin/push/campaigns/<id>         drafts only
    POST   /api/admin/push/campaigns/<id>/duplicate
    POST   /api/admin/push/campaigns/<id>/test    {"user_ids"}: sent now, results back
    POST   /api/admin/push/campaigns/<id>/send    {"expected_users", "when", "at", "tz", "confirm_duplicate"}
    POST   /api/admin/push/campaigns/<id>/cancel  scheduled -> draft; sending -> stops
    GET    /api/admin/push/campaigns/<id>/report
    GET    /api/admin/push/campaigns/<id>/deliveries[.csv]
    GET    /api/admin/push/campaigns.csv
    POST   /api/admin/push/audience               {"audience"} -> who, counted
    GET    /api/admin/push/users?q=|recent=1      people, to pick
    GET    /api/admin/push/testers  POST {"user_id","label"}  DELETE /testers/<id>
    POST   /api/admin/push/media                  a photo (multipart "file")

Public:

    GET    /api/push/media/<id>.jpg               the photos
    POST   /api/app/push-event                    {"d", "k", "e", "link"?} from the app

Configuration (app.config or environment):

    PUSH_CAMPAIGNS_DB   data/push_campaigns.sqlite
    PUSH_MEDIA_DIR      data/push_media
    PUSH_PUBLIC_BASE    https://vegukin-api.duckdns.org (the photos' addresses)
    PUSH_CONCURRENCY    requests to FCM at a time (8)
    PUSH_WORKER         0 to not start the worker (tests)
"""

import csv
import hashlib
import hmac
import html
import io
import json
import logging
import os
import random
import re
import secrets
import sqlite3
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser
from zoneinfo import ZoneInfo

import requests
from flask import Blueprint, Response, current_app, jsonify, redirect, request, send_file, send_from_directory, session

import app_accounts
import app_push
import push_telegram

bp = Blueprint('push_campaigns', __name__)
logger = logging.getLogger(__name__)

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = '/home/ubuntu/vegukin_api/data'

TS = '%Y-%m-%d %H:%M:%S'
TITLE_MAX = 120
TEXT_MAX = 4000          # Telegram's 4096, with room for the title
IMAGES_MAX = 10          # Telegram's album
NAME_MAX = 120
TEST_MAX = 10
TTL_HOURS = (1, 6, 24, 72, 168, 672)
BATCH = 200
LEASE = timedelta(minutes=10)     # a batch takes seconds; 200 timeouts at 8 a time, ~4 minutes
LATE = timedelta(hours=2)         # a schedule missed by more (server off) is not sent late
RETRY_AFTER = (60, 300, 1200)        # seconds before the 2nd, 3rd and 4th try
TRIES = len(RETRY_AFTER) + 1
DUPLICATE_WINDOW = timedelta(hours=24)
POLL_SECONDS = 5
PHOTO_IN_MAX = 15 * 1024 * 1024
PHOTO_SIDE = 1600
PHOTO_OUT_MAX = 900_000             # FCM takes notification images up to 1 MB
STATUSES = ('draft', 'scheduled', 'sending', 'paused', 'done', 'cancelled', 'failed')
CHANNELS = ('app', 'telegram')
TG_FIRST_BATCH = 20       # the first Telegram batch is small: a wrong bot shows itself early
TG_WORKERS = 12
QUIET_DAYS = 30           # an install with no push token, not opened for this long, is left out
EVENTS = {'received': 'received_at', 'opened': 'opened_at', 'read': 'read_at', 'clicked': 'clicked_at'}
CLICKS_MAX = 100

# What a tap on the message's button opens: the app's sections, as
# featureForPush() in the app reads a link (lib/features/home/feature_catalog.dart).
WEB_BASE = 'https://vegukin-twa.pages.dev/'
SECTIONS = {
    'mosque': ('🕌', 'Mosques', 'pages/places/places.html?type=mosque'),
    'restaurant': ('🍽️', 'Restaurants', 'pages/places/places.html?type=restaurant'),
    'shop': ('🏪', 'Shops', 'pages/places/places.html?type=shop'),
    'notifications': ('🔔', 'Notifications', 'pages/notifications/notifications.html'),
    'qibla': ('🕋', 'Qibla', 'pages/qibla/qibla.html'),
    'qna': ('🌐', 'Questions & answers', 'pages/questions/qna.html'),
    'barcode': ('🧪', 'Halal check', 'pages/barcode/barcode.html'),
    'housing': ('🏠', 'Housing', 'pages/housing/housing.html'),
    'cars': ('🚘', 'Cars', 'pages/cars/cars.html'),
    'hikorea': ('🛂', 'HiKorea', 'pages/hikorea/hikorea.html'),
    'jobs': ('💼', 'Jobs', 'pages/job-group/job-group.html'),
    'parcel': ('📦', 'Parcels', 'pages/parcel/parcel.html'),
    'links': ('🔗', 'Links', 'pages/links/links.html'),
    'donation': ('🤝', 'Donation', 'pages/donation/donation.html'),
    'community': ('👥', 'Community', 'pages/community/community.html'),
}

# FCM's error codes, said plainly, for the report.
ERRORS = {
    'UNREGISTERED': 'The app was uninstalled, or its data cleared. The token is forgotten; '
                    'this phone is not tried again.',
    'SENDER_ID_MISMATCH': 'The token belongs to another Firebase project. Forgotten.',
    'INVALID_ARGUMENT': 'FCM refused the message or the token (a bad token is forgotten).',
    'QUOTA_EXCEEDED': 'Too many messages at once for FCM. Tried again later.',
    'UNAVAILABLE': 'FCM was busy. Tried again later.',
    'INTERNAL': 'FCM had an internal error. Tried again later.',
    'THIRD_PARTY_AUTH_ERROR': 'iPhone: the APNs key in Firebase is missing or wrong. '
                              'Firebase console -> Project settings -> Cloud Messaging -> Apple app.',
    'NETWORK': 'The server could not reach FCM. Tried again later.',
    'NO_ACCESS': 'The server could not sign in to Firebase (the service account file).',
    'RESTARTED': 'The server stopped while this phone was being sent to. Not sent again, '
                 'so nobody gets it twice; FCM may or may not have it.',
    'STOPPED': 'The campaign was stopped before this phone.',
    'NO_FCM': 'Push is not set up on this server (FIREBASE_SERVICE_ACCOUNT).',
    'TG_BLOCKED': 'Telegram: has blocked the bot. Tried again in every campaign, in case they unblock it.',
    'TG_CHAT_NOT_FOUND': 'Telegram: hasn\'t started the bot (or a wrong id). Tried again in every campaign.',
    'TG_DELETED': 'Telegram: deleted their account. Left out of later campaigns: it can\'t come back.',
    'TG_RETRY_AFTER': 'Telegram asked to slow down. Everyone waited as asked; tried again.',
    'TG_NETWORK': 'The server could not reach Telegram. Tried again.',
    'TG_SERVER': 'Telegram had an error. Tried again.',
    'TG_FORMAT': 'Telegram could not read the formatting. Nothing else will go either: fix the text.',
    'TG_PHOTO_URL': 'Telegram could not fetch the photo from this server.',
    'TG_FILE': 'Telegram no longer knows the stored photo; it was sent again from the server.',
    'TG_BAD_REQUEST': 'Telegram refused the message (see what it said).',
    'TG_WRONG_BOT': 'Not marked blocked: the campaign stopped because nobody on the list could be reached, '
                    'which means a wrong bot or a wrong list.',
}

SCHEMA = """
CREATE TABLE IF NOT EXISTS campaigns (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT NOT NULL DEFAULT '',
    status         TEXT NOT NULL DEFAULT 'draft',
    title          TEXT NOT NULL DEFAULT '',
    html           TEXT NOT NULL DEFAULT '',
    images         TEXT NOT NULL DEFAULT '[]',    -- media ids, in order
    target         TEXT,                          -- a SECTIONS key
    ttl_hours      INTEGER NOT NULL DEFAULT 72,
    audience       TEXT NOT NULL DEFAULT '{"mode": "all"}',
    is_template    INTEGER NOT NULL DEFAULT 0,
    copied_from    INTEGER,
    scheduled_at   TEXT,                          -- UTC
    schedule_tz    TEXT,
    created_at     TEXT NOT NULL,
    updated_at     TEXT NOT NULL,
    started_at     TEXT,
    finished_at    TEXT,
    fanned_out     INTEGER NOT NULL DEFAULT 0,
    users          INTEGER,                       -- counted when sending started
    phones         INTEGER,
    stop_requested INTEGER NOT NULL DEFAULT 0,
    lease_until    TEXT,
    error          TEXT,
    tests          INTEGER NOT NULL DEFAULT 0,    -- test runs so far
    version        INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns (status);

-- One per campaign and phone; token_hash '' for a person whose phones take
-- no notifications (the inbox only). test: 0 for the campaign, n for its
-- n-th test run.
CREATE TABLE IF NOT EXISTS deliveries (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_id  INTEGER NOT NULL,
    user_id      INTEGER NOT NULL,
    token_hash   TEXT NOT NULL DEFAULT '',
    push_token   TEXT,                             -- until it is sent to
    platform     TEXT,
    lang         TEXT,
    reports      INTEGER NOT NULL DEFAULT 0,
    inbox_id     INTEGER,
    status       TEXT NOT NULL,                    -- pending sending retry sent dead failed unknown skipped inbox
    attempts     INTEGER NOT NULL DEFAULT 0,
    next_try_at  TEXT,
    error_code   TEXT,
    error        TEXT,
    fcm_id       TEXT,
    sent_at      TEXT,
    received_at  TEXT,
    opened_at    TEXT,
    read_at      TEXT,
    clicked_at   TEXT,
    clicks       INTEGER NOT NULL DEFAULT 0,
    test         INTEGER NOT NULL DEFAULT 0,
    UNIQUE (campaign_id, test, user_id, token_hash)
);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries (campaign_id, test, status);
CREATE INDEX IF NOT EXISTS idx_deliveries_user ON deliveries (user_id);

CREATE TABLE IF NOT EXISTS clicks (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_id  INTEGER NOT NULL,
    delivery_id  INTEGER NOT NULL,
    link         TEXT,
    at           TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_clicks_campaign ON clicks (campaign_id);

CREATE TABLE IF NOT EXISTS media (
    id          TEXT PRIMARY KEY,
    width       INTEGER NOT NULL,
    height      INTEGER NOT NULL,
    bytes       INTEGER NOT NULL,
    name        TEXT,
    created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS testers (
    user_id   INTEGER PRIMARY KEY,
    label     TEXT,
    added_at  TEXT NOT NULL
);

-- The bot's people (uploaded from the broadcast script's CSV). blocked_at:
-- Telegram said they can't be messaged; later campaigns skip them.
CREATE TABLE IF NOT EXISTS tg_users (
    user_id          INTEGER PRIMARY KEY,
    username         TEXT,
    added_at         TEXT NOT NULL,
    blocked_at       TEXT,
    blocked_reason   TEXT,
    blocked_campaign INTEGER
);
"""

# Columns added after update 17: (table, column, type).
_ADDED = [
    ('campaigns', 'channels', 'TEXT NOT NULL DEFAULT \'["app"]\''),
    ('campaigns', 'tg_title', 'INTEGER NOT NULL DEFAULT 1'),       # the title as the first bold line
    ('campaigns', 'tg_preview', 'INTEGER NOT NULL DEFAULT 0'),     # link previews under the text
    ('campaigns', 'tg_track', 'INTEGER NOT NULL DEFAULT 0'),       # links through this server, counted
    ('campaigns', 'tg_skip_app', 'INTEGER NOT NULL DEFAULT 1'),    # no Telegram for those the app notifies
    ('campaigns', 'tg_file_ids', 'TEXT'),                          # the photos, as Telegram stored them
    ('campaigns', 'canary', 'INTEGER'),                            # pause after this many people
    ('campaigns', 'canary_done', 'INTEGER NOT NULL DEFAULT 0'),
    ('campaigns', 'tg_users', 'INTEGER'),                          # counted when sending started
    ('deliveries', 'channel', 'TEXT NOT NULL DEFAULT \'app\''),
]


# ============================================
# PLUMBING
# ============================================

class _Settings:
    """What the worker thread needs without a Flask app context."""
    db = os.path.join(DATA, 'push_campaigns.sqlite')
    media = os.path.join(DATA, 'push_media')
    base = 'https://vegukin-api.duckdns.org'
    accounts_db = None
    concurrency = 8
    key = b''
    tg_bot = None


S = _Settings()
_wake = threading.Event()
_worker = None
_local = threading.local()


def _now():
    return datetime.now(timezone.utc).replace(microsecond=0)


def _fmt(dt):
    return dt.strftime(TS) if dt else None


def _iso(ts):
    return ts.replace(' ', 'T') + 'Z' if ts else None


def _db():
    conn = sqlite3.connect(S.db, timeout=15)
    conn.row_factory = sqlite3.Row
    return conn


def _accounts():
    return app_accounts._db(S.accounts_db)


def _err(code, message, status=400, **extra):
    return jsonify({'success': False, 'code': code, 'error': message, **extra}), status


def init_push_campaigns(app):
    """Tables, settings, the hooks into accounts, and the worker (once)."""
    global _worker
    cfg = lambda k, d=None: app.config.get(k) or os.getenv(k) or d
    S.db = cfg('PUSH_CAMPAIGNS_DB', S.db)
    S.media = cfg('PUSH_MEDIA_DIR', S.media)
    S.base = str(cfg('PUSH_PUBLIC_BASE', S.base)).rstrip('/')
    S.accounts_db = app.config.get('APP_ACCOUNTS_DB')
    S.concurrency = max(1, min(int(cfg('PUSH_CONCURRENCY', 8)), 32))
    secret = cfg('PUSH_EVENTS_KEY') or app.secret_key or ''
    if not secret:
        raise RuntimeError('push_campaigns needs app.secret_key (or PUSH_EVENTS_KEY)')
    S.key = hmac.new(str(secret).encode(), b'push-campaign-events', hashlib.sha256).digest()
    os.makedirs(S.media, exist_ok=True)
    tg_token = cfg('PUSH_TELEGRAM_BOT_TOKEN')
    S.tg_bot = push_telegram.Bot(str(tg_token).strip(), rate=float(cfg('PUSH_TELEGRAM_RATE', 25))) if tg_token else None
    conn = _db()
    try:
        conn.execute('PRAGMA journal_mode=WAL')
        conn.executescript(SCHEMA)
        for table, column, kind in _ADDED:
            if column not in {r['name'] for r in conn.execute(f"PRAGMA table_info({table})")}:
                conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {kind}")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_deliveries_channel ON deliveries (campaign_id, test, channel, status)")
        conn.commit()
    finally:
        conn.close()
    _mark_old_installs()
    _clean_tg_list()
    app_accounts.on_user_moved(_move_user)
    app_accounts.on_user_deleted(_delete_user)
    if str(cfg('PUSH_WORKER', '1')) not in ('0', 'false', 'False') and _worker is None:
        _worker = threading.Thread(target=_work_forever, name='push-campaigns', daemon=True)
        _worker.start()


def _clean_tg_list():
    """App installs and WhatsApp phone numbers uploaded with the bot's list (before it was checked)."""
    conn = _db()
    try:
        cur = conn.execute("DELETE FROM tg_users WHERE user_id <= 0 OR user_id > ?", (push_telegram.TELEGRAM_ID_MAX,))
        conn.commit()
        if cur.rowcount:
            logger.info(f'[CAMPAIGN] Telegram list: {cur.rowcount} ids that are not Telegram users taken out')
    finally:
        conn.close()


def _mark_old_installs():
    """Sessions an earlier campaign found dead (before installs could be marked gone), still without a token."""
    conn = _db()
    try:
        dead = [r[0] for r in conn.execute(
            "SELECT DISTINCT token_hash FROM deliveries WHERE status = 'dead' AND token_hash NOT IN ('', 'telegram')")]
    finally:
        conn.close()
    if not dead:
        return
    acc = _accounts()
    try:
        for k in range(0, len(dead), 500):
            chunk = dead[k:k + 500]
            acc.execute(f"UPDATE sessions SET gone_at = ? WHERE gone_at IS NULL AND push_token IS NULL "
                        f"AND token_hash IN ({','.join('?' * len(chunk))})", (_fmt(_now()), *chunk))
        acc.commit()
    except sqlite3.OperationalError:
        pass            # accounts not set up on this host
    finally:
        acc.close()


def _move_user(old_id, new_id):
    conn = _db()
    try:
        conn.execute("UPDATE OR IGNORE deliveries SET user_id = ? WHERE user_id = ?", (new_id, old_id))
        conn.execute("UPDATE OR IGNORE testers SET user_id = ? WHERE user_id = ?", (new_id, old_id))
        conn.execute("DELETE FROM testers WHERE user_id = ?", (old_id,))
        conn.commit()
    finally:
        conn.close()


def _delete_user(user_id):
    """Their deliveries go; the campaign's totals keep them as counted when it went out."""
    conn = _db()
    try:
        conn.execute("DELETE FROM clicks WHERE delivery_id IN (SELECT id FROM deliveries WHERE user_id = ?)",
                     (user_id,))
        conn.execute("DELETE FROM deliveries WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM testers WHERE user_id = ?", (user_id,))
        conn.commit()
    finally:
        conn.close()


def event_key(delivery_id):
    """What the app sends back with a delivery's id, so nobody else can report for it."""
    return hmac.new(S.key, f'd{int(delivery_id)}'.encode(), hashlib.sha256).hexdigest()[:20]


def media_url(media_id):
    return f'{S.base}/api/push/media/{media_id}.jpg'


def section_url(target):
    return WEB_BASE + SECTIONS[target][2] if target in SECTIONS else None


# ============================================
# THE MESSAGE: SANITIZING AND PLAIN TEXT
# ============================================

_STYLES = ('quote', 'a', 'b', 'i', 'u', 's')      # outermost first
_TAG_STYLE = {'b': 'b', 'strong': 'b', 'i': 'i', 'em': 'i', 'u': 'u', 'ins': 'u',
              's': 's', 'strike': 's', 'del': 's', 'blockquote': 'quote', 'a': 'a'}
_BLOCKS = {'p', 'div', 'li', 'ul', 'ol', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'tr', 'table', 'blockquote', 'pre'}
_DROP = {'script', 'style', 'head', 'title', 'template', 'noscript', 'iframe', 'object'}
_SCHEMES = ('http://', 'https://', 'tg://', 'mailto:', 'tel:')


def safe_href(href):
    """A link people can be sent to, or None. 'example.org' -> https://example.org."""
    href = str(href or '').strip()
    if not href or any(c in href for c in '\r\n\t<>"\'') or len(href) > 2000:
        return None
    low = href.lower()
    if low.startswith(_SCHEMES):
        return href
    if ':' in href.split('/')[0] or href.startswith(('/', '#', '.')):
        return None             # javascript:, data:, relative links
    if re.match(r'^[\w.-]+\.[a-z]{2,}([/?#]|$)', href, re.I):
        return 'https://' + href
    return None


class _Runs(HTMLParser):
    """HTML -> [(text, {'b', 'i', ..., ('a', href)})]: only what is allowed, nesting fixed."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.runs = []
        self.open = []          # [(tag, style or None)]
        self.drop = 0

    def _at_line_start(self):
        return not self.runs or self.runs[-1][0].endswith('\n')

    def _newline(self):
        if not self._at_line_start():
            self._text('\n', block=True)

    def _style(self):
        styles = {}
        for _, st in self.open:
            if st:
                styles[st[0]] = st[1]
        return styles

    def _text(self, text, block=False):
        if self.drop or not text:
            return
        styles = {} if block else self._style()
        if block and 'quote' in self._style():
            styles = {'quote': True}
        self.runs.append((text, styles))

    def handle_starttag(self, tag, attrs):
        if tag in _DROP:
            self.drop += 1
            return
        if self.drop:
            return
        if tag == 'br':
            self._text('\n', block=True)
            return
        if tag in _BLOCKS:
            self._newline()
        style = _TAG_STYLE.get(tag)
        if style == 'a':
            href = safe_href(dict(attrs).get('href'))
            st = ('a', href) if href and 'a' not in self._style() else None
        elif style:
            st = (style, True)
        else:
            st = None
        if tag in ('img', 'hr', 'input', 'meta', 'link'):   # void: never closed
            return
        self.open.append((tag, st))
        if tag == 'li':
            self._text('• ')

    def handle_startendtag(self, tag, attrs):
        if tag == 'br':
            self._text('\n', block=True)

    def handle_endtag(self, tag):
        if tag in _DROP:
            self.drop = max(0, self.drop - 1)
            return
        if self.drop:
            return
        for i in range(len(self.open) - 1, -1, -1):
            if self.open[i][0] == tag:
                del self.open[i:]
                break
        if tag in _BLOCKS:
            self._newline()

    def handle_data(self, data):
        self._text(data.replace('\r', ''))


def _serialize(runs):
    """Runs -> HTML with the tags opened and closed in one fixed order."""
    out, open_ = [], []
    for text, styles in runs:
        want = [(s, styles[s]) for s in _STYLES if s in styles]
        keep = 0
        while keep < len(open_) and keep < len(want) and open_[keep] == want[keep]:
            keep += 1
        for s, _ in reversed(open_[keep:]):
            out.append(f'</{"blockquote" if s == "quote" else s}>')
        for s, v in want[keep:]:
            if s == 'quote':
                out.append('<blockquote>')
            elif s == 'a':
                out.append(f'<a href="{html.escape(v, quote=True)}">')
            else:
                out.append(f'<{s}>')
        open_ = want
        out.append(html.escape(text, quote=False))
    for s, _ in reversed(open_):
        out.append(f'</{"blockquote" if s == "quote" else s}>')
    return ''.join(out)


def _tidy(runs):
    """No blank lines at either end, at most one blank line in a row."""
    text = ''.join(t for t, _ in runs)
    if not text.strip():
        return []
    # Work on the characters with their styles, then join equal neighbours.
    chars = [(c, st) for t, st in runs for c in t]
    while chars and chars[0][0].isspace():
        chars.pop(0)
    while chars and chars[-1][0].isspace():
        chars.pop()
    kept, newlines = [], 0
    for c, st in chars:
        if c == '\n':
            newlines += 1
            if newlines > 2:
                continue
        elif not c.isspace():
            newlines = 0
        kept.append((c, st))
    merged = []
    for c, st in kept:
        if merged and merged[-1][1] == st:
            merged[-1] = (merged[-1][0] + c, st)
        else:
            merged.append((c, st))
    return merged


def clean_html(raw):
    """(html, plain): the message as kept and as the notification and old apps show it."""
    parser = _Runs()
    parser.feed(str(raw or ''))
    parser.close()
    runs = _tidy(parser.runs)
    return _serialize(runs), _plain(runs)


def _plain(runs):
    """Links written out when their words aren't the address."""
    out, i = [], 0
    while i < len(runs):
        text, st = runs[i]
        href = st.get('a')
        if not href:
            out.append(text)
            i += 1
            continue
        label = ''
        while i < len(runs) and runs[i][1].get('a') == href:
            label += runs[i][0]
            i += 1
        bare = re.sub(r'^(https?://|mailto:|tel:)', '', href).rstrip('/')
        out.append(label if bare in label else f'{label} ({href})')
    return ''.join(out)


def push_body(plain):
    """What the notification carries: the text without the quote marks and blank lines."""
    lines = [l.strip() for l in plain.split('\n')]
    return app_push.preview('\n'.join(l for l in lines if l))


# ============================================
# CAMPAIGNS
# ============================================

def _load(conn, cid):
    return conn.execute("SELECT * FROM campaigns WHERE id = ?", (cid,)).fetchone()


def _audience(row):
    try:
        a = json.loads(row['audience'] or '{}')
        return a if isinstance(a, dict) else {}
    except ValueError:
        return {}


def _channels(row):
    try:
        ch = [c for c in json.loads(row['channels'] or '[]') if c in CHANNELS]
    except (ValueError, IndexError, KeyError):
        ch = []
    return ch


def _tg_text(row):
    """The message as the bot sends it (links not yet tracked)."""
    return push_telegram.message_html(row['title'], row['html'], bool(row['tg_title']))


def _images(row):
    try:
        return [i for i in json.loads(row['images'] or '[]') if isinstance(i, str)]
    except ValueError:
        return []


def _view(row, numbers=None):
    plain = clean_html(row['html'])[1]
    v = {
        'id': row['id'], 'name': row['name'], 'status': row['status'], 'title': row['title'],
        'html': row['html'], 'plain': plain, 'push_body': push_body(plain) if plain else '',
        'images': [{'id': i, 'url': media_url(i)} for i in _images(row)],
        'target': row['target'], 'ttl_hours': row['ttl_hours'], 'audience': _clean_audience(_audience(row)),
        'is_template': bool(row['is_template']), 'copied_from': row['copied_from'],
        'scheduled_at': _iso(row['scheduled_at']), 'schedule_tz': row['schedule_tz'],
        'created_at': _iso(row['created_at']), 'updated_at': _iso(row['updated_at']),
        'started_at': _iso(row['started_at']), 'finished_at': _iso(row['finished_at']),
        'users': row['users'], 'phones': row['phones'], 'error': row['error'],
        'stop_requested': bool(row['stop_requested']), 'tests': row['tests'], 'version': row['version'],
        'channels': _channels(row), 'tg_title': bool(row['tg_title']), 'tg_preview': bool(row['tg_preview']),
        'tg_track': bool(row['tg_track']), 'tg_skip_app': bool(row['tg_skip_app']),
        'tg_length': push_telegram.visible_length(_tg_text(row)), 'tg_users': row['tg_users'],
        'canary': row['canary'], 'canary_done': bool(row['canary_done']),
    }
    if numbers is not None:
        v['numbers'] = numbers
    return v


def _clean_audience(a):
    """The audience as kept: known keys, sane values."""
    a = a if isinstance(a, dict) else {}
    ids = lambda v: sorted({int(x) for x in (v or []) if str(x).lstrip('-').isdigit()})[:5000]
    days = lambda v: max(1, min(int(v), 3650)) if str(v or '').isdigit() and int(v) > 0 else None
    out = {
        'mode': a.get('mode') if a.get('mode') in ('all', 'filter', 'users') else 'all',
        'platforms': [p for p in a.get('platforms') or [] if p in app_accounts.PLATFORMS],
        'langs': [l for l in a.get('langs') or [] if l in app_accounts.LANGS],
        'signed_in': a.get('signed_in') if a.get('signed_in') in ('yes', 'no') else 'any',
        'providers': [p for p in a.get('providers') or [] if p in app_accounts.PROVIDERS],
        'active_days': days(a.get('active_days')),
        'inactive_days': days(a.get('inactive_days')),
        'installed_from': _utc_or_none(a.get('installed_from')),
        'installed_to': _utc_or_none(a.get('installed_to')),
        'reports_only': bool(a.get('reports_only')),
        'push_only': bool(a.get('push_only')),
        'recent_hours': days(a.get('recent_hours')),
        'include': ids(a.get('include')),
        'exclude': ids(a.get('exclude')),
    }
    return out


def _utc_or_none(v):
    """An ISO instant from the panel ('2026-11-01T00:00:00Z') -> 'YYYY-MM-DD HH:MM:SS' UTC."""
    if not v:
        return None
    try:
        dt = datetime.fromisoformat(str(v).replace('Z', '+00:00'))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return _fmt(dt.astimezone(timezone.utc))


def _apply(row, body):
    """Fields from the panel -> (sets, args), validated. Raises ValueError with what is wrong."""
    sets = {}
    if 'name' in body:
        sets['name'] = str(body.get('name') or '').strip()[:NAME_MAX]
    if 'title' in body:
        sets['title'] = ' '.join(str(body.get('title') or '').split())[:TITLE_MAX]
    if 'html' in body:
        cleaned, plain = clean_html(body.get('html'))
        if len(plain) > TEXT_MAX:
            raise ValueError(f'The message is {len(plain)} characters; at most {TEXT_MAX}.')
        sets['html'] = cleaned
    if 'images' in body:
        ids = [str(i) for i in (body.get('images') or [])]
        if len(ids) > IMAGES_MAX:
            raise ValueError(f'At most {IMAGES_MAX} photos.')
        conn = _db()
        try:
            known = {r['id'] for r in conn.execute(
                f"SELECT id FROM media WHERE id IN ({','.join('?' * len(ids))})", ids)} if ids else set()
        finally:
            conn.close()
        missing = [i for i in ids if i not in known]
        if missing:
            raise ValueError('A photo is not on the server any more; upload it again.')
        sets['images'] = json.dumps(ids)
        if row is None or ids != _images(row):
            sets['tg_file_ids'] = None        # Telegram's copies are of the old photos
    if 'target' in body:
        t = body.get('target') or None
        if t is not None and t not in SECTIONS:
            raise ValueError('Unknown section.')
        sets['target'] = t
    if 'ttl_hours' in body:
        try:
            ttl = int(body.get('ttl_hours'))
        except (TypeError, ValueError):
            ttl = 72
        sets['ttl_hours'] = ttl if ttl in TTL_HOURS else 72
    if 'audience' in body:
        sets['audience'] = json.dumps(_clean_audience(body.get('audience')))
    if 'is_template' in body:
        sets['is_template'] = 1 if body.get('is_template') else 0
    if 'channels' in body:
        sets['channels'] = json.dumps([c for c in CHANNELS if c in (body.get('channels') or [])])
    for key in ('tg_title', 'tg_preview', 'tg_track', 'tg_skip_app'):
        if key in body:
            sets[key] = 1 if body.get(key) else 0
    return sets


def _problems(row):
    """What stops this campaign from being sent, as sentences ([] when nothing)."""
    out = []
    channels = _channels(row)
    if not channels:
        out.append('Choose where it goes: the app, Telegram, or both.')
    if not row['title'].strip():
        out.append('It needs a title: the notification\'s first line.')
    plain = clean_html(row['html'])[1]
    if not plain.strip():
        out.append('It needs some text.')
    if 'app' in channels and not app_push.enabled():
        out.append('Push is not set up on this server (FIREBASE_SERVICE_ACCOUNT).')
    if 'telegram' in channels:
        if not S.tg_bot:
            out.append('Telegram is not set up on this server (PUSH_TELEGRAM_BOT_TOKEN in .env).')
        if push_telegram.visible_length(_tg_text(row)) > push_telegram.TEXT_MAX:
            out.append(f'Too long for Telegram: at most {push_telegram.TEXT_MAX} characters with the title.')
    return out


# ============================================
# WHO: THE AUDIENCE
# ============================================

def _people(audience, conn_accounts=None, stats=None):
    """
    The audience -> [{'id', 'phones': [phone], 'all_phones': n, 'lang', 'platform', 'reports'}].
    phones: the matching phones that take notifications. A person with
    matching phones of which none does gets the message in the inbox only.

    Filters are on phones (platform, language, when installed, when last
    open, the app reporting) and people (signed in or not, with which
    account). 'users' takes just the ids in include; exclude always applies.
    """
    a = _clean_audience(audience)
    own = conn_accounts is None
    conn = conn_accounts or _accounts()
    try:
        rows = conn.execute(
            "SELECT s.token_hash, s.push_token, s.platform, s.lang, s.created_at, s.seen_at, s.gone_at, "
            "COALESCE(s.reports, 0) AS reports, a.id AS account_id, a.tg_id, "
            "(SELECT group_concat(provider) FROM identities i WHERE i.account_id = a.id) AS providers "
            "FROM sessions s JOIN accounts a ON a.id = s.account_id ORDER BY s.seen_at DESC").fetchall()
    except sqlite3.OperationalError:
        rows = []
    finally:
        if own:
            conn.close()
    now = _now()
    quiet = _fmt(now - timedelta(days=QUIET_DAYS))
    active = _fmt(now - timedelta(days=a['active_days'])) if a['active_days'] else None
    inactive = _fmt(now - timedelta(days=a['inactive_days'])) if a['inactive_days'] else None
    include, exclude = set(a['include']), set(a['exclude'])
    recent = _recent_receivers(a['recent_hours']) if a['recent_hours'] else set()
    people = {}
    for r in rows:
        # Old installs: the app reinstalled or moved to a new phone left its old session behind.
        if r['gone_at'] or (not r['push_token'] and r['seen_at'] < quiet):
            if stats is not None:
                stats['old_installs'] = stats.get('old_installs', 0) + 1
            continue
        uid = int(r['tg_id']) if r['tg_id'] else app_accounts.app_user_id(r['account_id'])
        if uid in exclude or uid in recent:
            continue
        if a['mode'] == 'users':
            if uid not in include:
                continue
        else:
            providers = set((r['providers'] or '').split(',')) - {''}
            if a['platforms'] and r['platform'] not in a['platforms']:
                continue
            if a['langs'] and r['lang'] not in a['langs']:
                continue
            if a['signed_in'] == 'yes' and not providers or a['signed_in'] == 'no' and providers:
                continue
            if a['providers'] and not providers & set(a['providers']):
                continue
            if active and r['seen_at'] < active:
                continue
            if inactive and r['seen_at'] >= inactive:
                continue
            if a['installed_from'] and r['created_at'] < a['installed_from']:
                continue
            if a['installed_to'] and r['created_at'] > a['installed_to']:
                continue
            if a['reports_only'] and not r['reports']:
                continue
        p = people.setdefault(uid, {'id': uid, 'phones': [], 'all_phones': 0, 'lang': r['lang'],
                                    'platform': r['platform'], 'reports': 0, 'seen_at': r['seen_at']})
        p['all_phones'] += 1
        p['reports'] = max(p['reports'], r['reports'])
        if r['push_token']:
            p['phones'].append({'token_hash': r['token_hash'], 'push_token': r['push_token'],
                                'platform': r['platform'], 'lang': r['lang'], 'reports': r['reports']})
    out = list(people.values())
    if a['push_only']:
        out = [p for p in out if p['phones']]
    return out


def _recent_receivers(hours):
    conn = _db()
    try:
        since = _fmt(_now() - timedelta(hours=hours))
        return {r[0] for r in conn.execute(
            "SELECT DISTINCT user_id FROM deliveries WHERE test = 0 AND status IN ('sent', 'inbox') "
            "AND COALESCE(sent_at, '') >= ?", (since,))}
    finally:
        conn.close()


def _names(user_ids):
    """{id: {'name', 'provider', 'detail'}} for people signed in; nothing for the anonymous."""
    ids = [int(i) for i in user_ids]
    if not ids:
        return {}
    tg = [i for i in ids if i > 0]
    app = {-(i) - app_accounts.APP_ID_BASE: i for i in ids if app_accounts.is_app_user(i)}
    out = {}
    conn = _accounts()
    try:
        for chunk in (tg[k:k + 500] for k in range(0, len(tg), 500)):
            for r in conn.execute(
                    f"SELECT a.tg_id AS uid, i.provider, i.name, i.detail FROM accounts a "
                    f"JOIN identities i ON i.account_id = a.id WHERE a.tg_id IN ({','.join('?' * len(chunk))}) "
                    f"ORDER BY i.updated_at", chunk):
                out[int(r['uid'])] = {'name': r['name'], 'provider': r['provider'], 'detail': r['detail']}
        keys = list(app)
        for chunk in (keys[k:k + 500] for k in range(0, len(keys), 500)):
            for r in conn.execute(
                    f"SELECT account_id, provider, name, detail FROM identities "
                    f"WHERE account_id IN ({','.join('?' * len(chunk))}) ORDER BY updated_at", chunk):
                out[app[r['account_id']]] = {'name': r['name'], 'provider': r['provider'], 'detail': r['detail']}
    except sqlite3.OperationalError:
        pass
    finally:
        conn.close()
    return out


def _tg_people(a, segment, skip_app):
    """
    Who the bot messages: ([{'id', 'username'}], {why skipped: n}, size of the list).

        Everyone         the bot's list, and app users signed in with Telegram
        A segment        only people in it who signed in to the app with
                         Telegram: the list has no language or activity
        Chosen people    the chosen Telegram ids

    Never those Telegram called blocked, those left out, or (skip_app) those
    whose phone gets the push anyway.
    """
    conn = _db()
    try:
        rows = conn.execute("SELECT user_id, username, blocked_at, blocked_reason FROM tg_users").fetchall()
    finally:
        conn.close()
    # Who blocked the bot may unblock it: tried every time. A deleted account never comes back.
    deleted = {r['user_id'] for r in rows if r['blocked_at'] and 'deactivated' in (r['blocked_reason'] or '').lower()}
    listed = {r['user_id']: r['username'] for r in rows if r['user_id'] not in deleted}
    if a['mode'] == 'users':
        candidates = [i for i in a['include'] if push_telegram.is_telegram_id(i)]
    elif a['mode'] == 'filter':
        candidates = [p['id'] for p in segment if push_telegram.is_telegram_id(p['id'])]
    else:
        on_list = [r['user_id'] for r in rows]
        candidates = on_list + [p['id'] for p in segment
                                if push_telegram.is_telegram_id(p['id']) and p['id'] not in set(on_list)]
    exclude = set(a['exclude'])
    recent = _recent_receivers(a['recent_hours']) if a['recent_hours'] else set()
    notified = {p['id'] for p in segment if p['phones']} if skip_app else set()
    out, skipped, seen = [], {'deleted': 0, 'left_out': 0, 'recent': 0, 'in_app': 0}, set()
    for uid in candidates:
        if uid in seen:
            continue
        seen.add(uid)
        why = ('deleted' if uid in deleted else 'left_out' if uid in exclude else 'recent' if uid in recent
               else 'in_app' if uid in notified else None)
        if why:
            skipped[why] += 1
        else:
            out.append({'id': uid, 'username': listed.get(uid)})
    return out, skipped, len(rows)


def estimate(audience, channels=('app',), tg_skip_app=True):
    """The audience counted, per channel, as the panel shows it before sending."""
    a = _clean_audience(audience)
    channels = [c for c in CHANNELS if c in (channels or [])]
    stats = {}
    segment = _people(a, stats=stats)
    people = segment if 'app' in channels else []
    phones = [ph for p in people for ph in p['phones']]
    by_lang, by_platform = {}, {}
    for p in people:
        by_lang[p['lang']] = by_lang.get(p['lang'], 0) + 1
    for ph in phones:
        by_platform[ph['platform']] = by_platform.get(ph['platform'], 0) + 1
    sample = people[:60]
    names = _names([p['id'] for p in sample])
    missing = []
    if a['mode'] == 'users':
        found = {p['id'] for p in people}
        missing = [i for i in a['include'] if i not in found and i not in set(a['exclude'])]
    return {
        'users': len(people),
        'notified_users': sum(1 for p in people if p['phones']),
        'inbox_only': sum(1 for p in people if not p['phones']),
        'phones': len(phones),
        'reporting_phones': sum(1 for ph in phones if ph['reports']),
        'by_platform': by_platform,
        'by_lang': by_lang,
        'missing': missing,
        'sample': [{'id': p['id'], 'phones': len(p['phones']), 'platform': p['platform'], 'lang': p['lang'],
                    'seen_at': _iso(p['seen_at']), **names.get(p['id'], {})} for p in sample],
        'audience': a,
        'channels': channels,
        'old_installs': stats.get('old_installs', 0) if 'app' in channels else 0,
        'telegram': _tg_estimate(a, segment, tg_skip_app and 'app' in channels) if 'telegram' in channels else None,
    }


def _tg_estimate(a, segment, skip_app):
    people, skipped, size = _tg_people(a, segment, skip_app)
    rate = S.tg_bot.limiter.interval if S.tg_bot else 1 / 25
    return {'users': len(people), 'skipped': skipped, 'list': size, 'configured': bool(S.tg_bot),
            'minutes': round(len(people) * rate / 60, 1),
            'sample': [{**p, **_names([p['id']]).get(p['id'], {})} for p in people[:30]]}


# ============================================
# SENDING
# ============================================

def _fcm_message(c, delivery, extra_data=None):
    """The FCM v1 message for one phone of campaign row c."""
    plain = clean_html(c['html'])[1]
    images = _images(c)
    data = {'kind': 'campaign', 'c': str(c['id']), 'd': str(delivery['id']), 'k': event_key(delivery['id'])}
    if delivery['inbox_id']:
        data['inbox_id'] = str(delivery['inbox_id'])
    url = section_url(c['target'])
    if url:
        data['url'] = url
    data.update(extra_data or {})
    tag = f"c{c['id']}" + (f"t{delivery['test']}" if delivery['test'] else '')
    ttl = int(c['ttl_hours'] or 72) * 3600
    notification = {'title': c['title'], 'body': push_body(plain)}
    if images:
        notification['image'] = media_url(images[0])
    return {
        'token': delivery['push_token'],
        'notification': notification,
        'data': data,
        'android': {'priority': 'high', 'ttl': f'{ttl}s', 'collapse_key': tag,
                    'notification': {'channel_id': app_push.ANDROID_CHANNEL, 'tag': tag}},
        'apns': {'headers': {'apns-collapse-id': tag,
                             'apns-expiration': str(int((_now() + timedelta(seconds=ttl)).timestamp()))},
                 'payload': {'aps': {'sound': 'default'}}},
        'fcm_options': {'analytics_label': f"campaign_{c['id']}"},
    }


def _http():
    s = getattr(_local, 'session', None)
    if s is None:
        s = _local.session = requests.Session()
    return s


def _send_one(c, d):
    try:
        return app_push.send_detailed(_fcm_message(c, d), http=_http())
    except Exception as e:            # never lose a row's outcome to a bug in one message
        logger.exception('[CAMPAIGN] sending')
        return {'outcome': 'failed', 'code': 'ERROR', 'error': str(e)[:200]}


def _record(conn, d, result, now):
    """One phone's outcome -> its row. Returns the push token to forget, if dead."""
    outcome = result.get('outcome')
    if outcome == 'sent':
        conn.execute("UPDATE deliveries SET status = 'sent', sent_at = ?, fcm_id = ?, push_token = NULL, "
                     "error_code = NULL, error = NULL, next_try_at = NULL WHERE id = ?",
                     (_fmt(now), result.get('id'), d['id']))
        if d.get('channel') == 'telegram':
            conn.execute("UPDATE tg_users SET blocked_at = NULL, blocked_reason = NULL, blocked_campaign = NULL "
                         "WHERE user_id = ? AND blocked_at IS NOT NULL", (d['user_id'],))
        return None
    code, error = result.get('code'), result.get('error')
    if outcome == 'dead':
        conn.execute("UPDATE deliveries SET status = 'dead', push_token = NULL, error_code = ?, error = ?, "
                     "next_try_at = NULL WHERE id = ?", (code, error, d['id']))
        return d['push_token']
    if outcome == 'blocked':
        conn.execute("UPDATE deliveries SET status = 'blocked', error_code = ?, error = ?, next_try_at = NULL "
                     "WHERE id = ?", (code, error, d['id']))
        conn.execute("INSERT OR IGNORE INTO tg_users (user_id, added_at) VALUES (?, ?)",
                     (d['user_id'], _fmt(now)))
        conn.execute("UPDATE tg_users SET blocked_at = ?, blocked_reason = ?, blocked_campaign = ? "
                     "WHERE user_id = ? AND blocked_at IS NULL", (_fmt(now), error, d['campaign_id'], d['user_id']))
        return None
    if outcome == 'retry' and d['attempts'] < TRIES and not d['test']:
        wait = max(RETRY_AFTER[min(d['attempts'], len(RETRY_AFTER)) - 1], result.get('retry_after') or 0)
        conn.execute("UPDATE deliveries SET status = 'retry', next_try_at = ?, error_code = ?, error = ? "
                     "WHERE id = ?", (_fmt(now + timedelta(seconds=wait)), code, error, d['id']))
        return None
    conn.execute("UPDATE deliveries SET status = 'failed', push_token = NULL, error_code = ?, error = ?, "
                 "next_try_at = NULL WHERE id = ?", (code, error, d['id']))
    return None


def _send_rows(c, rows):
    """Send to these delivery rows (already marked 'sending'), record each outcome."""
    if not rows:
        return
    if len(rows) == 1 or S.concurrency == 1:
        results = [_send_one(c, d) for d in rows]
    else:
        with ThreadPoolExecutor(max_workers=min(S.concurrency, len(rows))) as pool:
            results = list(pool.map(lambda d: _send_one(c, d), rows))
    now = _now()
    dead = []
    conn = _db()
    try:
        for d, result in zip(rows, results):
            token = _record(conn, d, result, now)
            if token:
                dead.append(token)
        conn.commit()
    finally:
        conn.close()
    for token in dead:
        try:
            app_accounts.forget_push_token(token, S.accounts_db)
        except sqlite3.Error as e:
            logger.warning(f'[CAMPAIGN] could not forget a dead token: {e}')


# --- Telegram ---

_BARE_URL = re.compile(r'https?://[^\s<>"\']+')


def _trackable(href):
    """Links that can pass through this server: web pages, not Telegram's own (they open inside Telegram)."""
    low = (href or '').lower()
    host = re.sub(r'^https?://', '', low).split('/')[0]
    return low.startswith(('http://', 'https://')) and host not in ('t.me', 'telegram.me', 'telegram.org')


def _tg_runs(c):
    """The bot's text as runs, with bare web addresses made links (when links are counted)."""
    parser = _Runs()
    parser.feed(_tg_text(c))
    parser.close()
    if not c['tg_track']:
        return parser.runs
    runs = []
    for text, st in parser.runs:
        if st.get('a'):
            runs.append((text, st))
            continue
        at = 0
        for m in _BARE_URL.finditer(text):
            url = m.group(0).rstrip('.,;:!?)»”\'')
            if not _trackable(url):
                continue
            if m.start() > at:
                runs.append((text[at:m.start()], st))
            runs.append((url, {**st, 'a': url}))
            at = m.start() + len(url)
        if at < len(text):
            runs.append((text[at:], st))
    return runs


def campaign_links(c):
    """The campaign's countable links, in order: what /api/push/r/<delivery>/<n> leads to."""
    out = []
    for _, st in _tg_runs(c):
        href = st.get('a')
        if href and _trackable(href) and href not in out:
            out.append(href)
    return out


def tg_html(c, delivery_id):
    """The bot's text for one person: with counted links, each web link goes through this server first."""
    if not c['tg_track']:
        return _tg_text(c)
    links = campaign_links(c)
    key = event_key(delivery_id)
    runs = [(text, {**st, 'a': f"{S.base}/api/push/r/{delivery_id}/{links.index(st['a'])}?k={key}"})
            if st.get('a') in links else (text, st) for text, st in _tg_runs(c)]
    return _serialize(runs)


def _tg_photos(c):
    """(photos, stored): Telegram's file_ids when it has the campaign's photos, else their addresses."""
    images = _images(c)
    try:
        ids = [i for i in json.loads(c['tg_file_ids'] or '[]') if isinstance(i, str) and i]
    except ValueError:
        ids = []
    if images and len(ids) == len(images):
        return ids, True
    return [media_url(i) for i in images], False


def _save_file_ids(cid, ids):
    conn = _db()
    try:
        conn.execute("UPDATE campaigns SET tg_file_ids = ? WHERE id = ?", (json.dumps(ids) if ids else None, cid))
        conn.commit()
    finally:
        conn.close()


def _send_tg_one(c, d, photos):
    try:
        text = tg_html(c, d['id'])
        preview = bool(c['tg_preview']) and not c['tg_track']
        r = push_telegram.send(S.tg_bot, d['user_id'], text, photos, preview=preview)
        if r['outcome'] == 'stale_files':
            # Telegram forgot the stored photos: from the server again, and forget the ids.
            _save_file_ids(c['id'], None)
            r = push_telegram.send(S.tg_bot, d['user_id'], text, [media_url(i) for i in _images(c)], preview=preview)
            if r['outcome'] == 'stale_files':
                r = {**r, 'outcome': 'failed'}
        return r
    except Exception as e:
        logger.exception('[CAMPAIGN] telegram')
        return {'outcome': 'failed', 'code': 'ERROR', 'error': str(e)[:200]}


def _send_tg_rows(c, rows):
    """
    Send these Telegram rows (marked 'sending'). Photos are uploaded by the
    first send that works and reused by every send after it.
    """
    if not rows:
        return
    if not S.tg_bot:
        results = [(d, {'outcome': 'failed', 'code': 'TG_NO_TOKEN', 'error': 'PUSH_TELEGRAM_BOT_TOKEN is not set'})
                   for d in rows]
    else:
        photos, stored = _tg_photos(c)
        results, rest = [], list(rows)
        while photos and not stored and rest:
            d = rest.pop(0)
            r = _send_tg_one(c, d, photos)
            results.append((d, r))
            if r.get('file_ids') and len(r['file_ids']) == len(photos):
                photos, stored = r['file_ids'], True
                _save_file_ids(c['id'], photos)
            elif len(results) >= 5:
                break           # nobody took it yet: each send uploads on its own
        if rest:
            with ThreadPoolExecutor(max_workers=min(TG_WORKERS, len(rest))) as pool:
                results += list(zip(rest, pool.map(lambda d: _send_tg_one(c, d, photos), rest)))
    now = _now()
    conn = _db()
    try:
        for d, r in results:
            _record(conn, d, r, now)
        conn.commit()
    finally:
        conn.close()


def _tg_hopeless(cid):
    """
    The first Telegram sends tell whether the rest can work: all "chat not
    found" means a wrong bot or a wrong list; all refused for the text means
    the text. (what, why) or None.
    """
    conn = _db()
    try:
        r = conn.execute(
            "SELECT SUM(status = 'sent') AS sent, SUM(status NOT IN ('pending', 'sending')) AS done, "
            "SUM(status = 'blocked' AND error_code = 'TG_CHAT_NOT_FOUND') AS lost, "
            "SUM(status = 'failed' AND error_code IN ('TG_FORMAT', 'TG_BAD_REQUEST', 'TG_PHOTO_URL', 'TG_NO_TOKEN')) AS bad "
            "FROM deliveries WHERE campaign_id = ? AND test = 0 AND channel = 'telegram'", (cid,)).fetchone()
        sent, done, lost, bad = (r['sent'] or 0), (r['done'] or 0), (r['lost'] or 0), (r['bad'] or 0)
        if sent == 0 and lost >= 15 and lost >= 0.9 * done:
            return 'wrong_bot', (f'Stopped: the first {lost} people on Telegram all came back "chat not found". '
                                 f'Either PUSH_TELEGRAM_BOT_TOKEN is not the bot these people started, or the list holds ids '
                                 f'that are not Telegram users. Nobody was marked blocked.')
        if sent == 0 and bad >= 5:
            e = conn.execute("SELECT error FROM deliveries WHERE campaign_id = ? AND channel = 'telegram' AND "
                             "status = 'failed' AND error IS NOT NULL LIMIT 1", (cid,)).fetchone()
            return 'message', f'Stopped: Telegram refused the first messages ({e["error"] if e else "?"}).'
        return None
    finally:
        conn.close()


def _unblock_campaign(cid):
    """A wrong bot: its "blocked" answers say nothing about the people."""
    conn = _db()
    try:
        conn.execute("UPDATE tg_users SET blocked_at = NULL, blocked_reason = NULL, blocked_campaign = NULL "
                     "WHERE blocked_campaign = ?", (cid,))
        conn.execute("UPDATE deliveries SET status = 'failed', error_code = 'TG_WRONG_BOT' WHERE campaign_id = ? "
                     "AND channel = 'telegram' AND status = 'blocked'", (cid,))
        conn.commit()
    finally:
        conn.close()


def _put_in_inboxes(c, test=0, only_users=None):
    """
    Each person of this campaign (or test run) without an inbox row gets
    one. A campaign's row is unique per person in the inbox itself, so this
    can run again after a crash without a second copy. Test runs make a new
    row every time.
    """
    cid = c['id']
    conn = _db()
    try:
        firsts = conn.execute(
            "SELECT user_id, MIN(id) AS d FROM deliveries WHERE campaign_id = ? AND test = ? AND channel = 'app' "
            "AND inbox_id IS NULL GROUP BY user_id", (cid, test)).fetchall()
    finally:
        conn.close()
    if only_users is not None:
        firsts = [f for f in firsts if f['user_id'] in only_users]
    if not firsts:
        return
    cleaned, plain = clean_html(c['html'])
    images = json.dumps([media_url(i) for i in _images(c)]) if _images(c) else None
    body = push_body(plain)
    url = section_url(c['target'])
    now = _fmt(_now())
    placed = {}
    acc = _accounts()
    try:
        for f in firsts:
            data = {'kind': 'campaign', 'c': cid, 'd': f['d'], 'k': event_key(f['d'])}
            if url:
                data['url'] = url
            if test:
                data['test'] = test
            cur = acc.execute(
                "INSERT OR IGNORE INTO inbox (user_id, title, body, data, created_at, text, images, html, campaign_id) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (f['user_id'], c['title'], body, json.dumps(data, ensure_ascii=False), now,
                 plain if plain != body else None, images, cleaned, None if test else cid))
            if cur.rowcount:
                placed[f['user_id']] = cur.lastrowid
            else:
                row = acc.execute("SELECT id FROM inbox WHERE user_id = ? AND campaign_id = ?",
                                  (f['user_id'], cid)).fetchone()
                if row:
                    placed[f['user_id']] = row['id']
        acc.execute("DELETE FROM inbox WHERE created_at < ?", (_fmt(_now() - app_accounts.INBOX_KEEP),))
        acc.commit()
    finally:
        acc.close()
    conn = _db()
    try:
        conn.executemany("UPDATE deliveries SET inbox_id = ? WHERE campaign_id = ? AND test = ? AND user_id = ? "
                         "AND channel = 'app'", [(iid, cid, test, uid) for uid, iid in placed.items()])
        conn.execute("UPDATE deliveries SET sent_at = ? WHERE campaign_id = ? AND test = ? "
                     "AND status = 'inbox' AND sent_at IS NULL AND inbox_id IS NOT NULL", (now, cid, test))
        conn.commit()
    finally:
        conn.close()


def _fan_out(cid):
    """The audience, counted now, -> one delivery row per phone. Once per campaign."""
    conn = _db()
    try:
        c = _load(conn, cid)
        if c['fanned_out']:
            return
        channels = _channels(c)
        a = _clean_audience(_audience(c))
        segment = _people(a)
        people = segment if 'app' in channels else []
        rows = []
        for p in people:
            if p['phones']:
                for ph in p['phones']:
                    rows.append((cid, p['id'], ph['token_hash'], ph['push_token'], ph['platform'], ph['lang'],
                                 ph['reports'], 'pending', 'app'))
            else:
                rows.append((cid, p['id'], '', None, p['platform'], p['lang'], p['reports'], 'inbox', 'app'))
        tg = []
        if 'telegram' in channels:
            tg, _, _ = _tg_people(a, segment, bool(c['tg_skip_app']) and 'app' in channels)
            random.shuffle(tg)
            rows += [(cid, t['id'], 'telegram', None, 'telegram', None, 0, 'pending', 'telegram') for t in tg]
        conn.executemany(
            "INSERT OR IGNORE INTO deliveries (campaign_id, user_id, token_hash, push_token, platform, lang, "
            "reports, status, channel) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
        conn.execute("UPDATE campaigns SET fanned_out = 1, users = ?, phones = ?, tg_users = ?, updated_at = ? "
                     "WHERE id = ?", (len(people), sum(len(p['phones']) for p in people), len(tg), _fmt(_now()), cid))
        conn.commit()
    finally:
        conn.close()
    logger.info(f'[CAMPAIGN] {cid}: {len(people)} app people, {len(tg)} on Telegram, {len(rows)} rows')


def _take_lease(cid):
    """This worker sends campaign cid until the lease runs out (renewed per batch)."""
    now = _now()
    conn = _db()
    try:
        cur = conn.execute("UPDATE campaigns SET lease_until = ? WHERE id = ? AND status = 'sending' "
                           "AND (lease_until IS NULL OR lease_until < ?)", (_fmt(now + LEASE), cid, _fmt(now)))
        if not cur.rowcount:
            conn.commit()
            return False
        # Rows left 'sending' by a worker that stopped: FCM may have them. Never again.
        conn.execute("UPDATE deliveries SET status = 'unknown', push_token = NULL, error_code = 'RESTARTED', "
                     "error = ? WHERE campaign_id = ? AND test = 0 AND status = 'sending'",
                     (ERRORS['RESTARTED'], cid))
        conn.commit()
        return True
    finally:
        conn.close()


def _renew_lease(cid):
    conn = _db()
    try:
        conn.execute("UPDATE campaigns SET lease_until = ? WHERE id = ?", (_fmt(_now() + LEASE), cid))
        conn.commit()
    finally:
        conn.close()


def _claim(cid, channel='app', limit=BATCH):
    """The next rows due, marked 'sending' with one more attempt, before any request goes."""
    if limit <= 0:
        return []
    now = _fmt(_now())
    conn = _db()
    try:
        rows = conn.execute(
            "SELECT * FROM deliveries WHERE campaign_id = ? AND test = 0 AND channel = ? AND "
            "(push_token IS NOT NULL OR channel = 'telegram') AND "
            "(status = 'pending' OR (status = 'retry' AND next_try_at <= ?)) ORDER BY id LIMIT ?",
            (cid, channel, now, limit)).fetchall()
        if rows:
            conn.executemany("UPDATE deliveries SET status = 'sending', attempts = attempts + 1 WHERE id = ?",
                             [(r['id'],) for r in rows])
            conn.commit()
        return [{**dict(r), 'attempts': r['attempts'] + 1} for r in rows]
    finally:
        conn.close()


def _stop(cid, status, error=None, code='STOPPED'):
    """End campaign cid: rows not yet sent are skipped."""
    now = _fmt(_now())
    conn = _db()
    try:
        conn.execute("UPDATE deliveries SET status = 'skipped', push_token = NULL, error_code = ?, error = ? "
                     "WHERE campaign_id = ? AND test = 0 AND status IN ('pending', 'retry')",
                     (code, error or ERRORS['STOPPED'], cid))
        conn.execute("UPDATE campaigns SET status = ?, finished_at = ?, updated_at = ?, lease_until = NULL, "
                     "error = COALESCE(?, error) WHERE id = ?", (status, now, now, error, cid))
        conn.commit()
    finally:
        conn.close()


def _hopeless(cid):
    """The first phones all failed for the message itself: the rest would too."""
    conn = _db()
    try:
        r = conn.execute(
            "SELECT SUM(status = 'sent' AND token_hash != '') AS sent, "
            "SUM(status = 'failed' AND error_code IN ('INVALID_ARGUMENT', 'ERROR')) AS bad "
            "FROM deliveries WHERE campaign_id = ? AND test = 0 AND channel = 'app'", (cid,)).fetchone()
        if (r['sent'] or 0) == 0 and (r['bad'] or 0) >= 5:
            e = conn.execute("SELECT error FROM deliveries WHERE campaign_id = ? AND status = 'failed' "
                             "AND channel = 'app' AND error IS NOT NULL LIMIT 1", (cid,)).fetchone()
            return e['error'] if e else 'FCM refused the message.'
        return None
    finally:
        conn.close()


def _finish_if_done(cid):
    conn = _db()
    try:
        left = conn.execute("SELECT COUNT(*) FROM deliveries WHERE campaign_id = ? AND test = 0 "
                            "AND status IN ('pending', 'sending', 'retry')", (cid,)).fetchone()[0]
        if left:
            conn.execute("UPDATE campaigns SET lease_until = NULL WHERE id = ?", (cid,))
        else:
            now = _fmt(_now())
            conn.execute("UPDATE campaigns SET status = 'done', finished_at = ?, updated_at = ?, "
                         "lease_until = NULL WHERE id = ? AND status = 'sending'", (now, now, cid))
            logger.info(f'[CAMPAIGN] {cid}: done')
        conn.commit()
    finally:
        conn.close()


def _attempted(cid):
    """{channel: rows tried so far} (not the inbox-only ones)."""
    conn = _db()
    try:
        return {r['channel']: r['n'] for r in conn.execute(
            "SELECT channel, COUNT(*) AS n FROM deliveries WHERE campaign_id = ? AND test = 0 "
            "AND status NOT IN ('pending', 'inbox') GROUP BY channel", (cid,))}
    finally:
        conn.close()


def _with_inbox_ids(rows):
    """The rows' inbox ids, read again: they were placed after the rows were claimed."""
    if not rows:
        return rows
    conn = _db()
    try:
        ids = dict(conn.execute(f"SELECT id, inbox_id FROM deliveries WHERE id IN ({','.join('?' * len(rows))})",
                                [r['id'] for r in rows]).fetchall())
    finally:
        conn.close()
    return [{**r, 'inbox_id': ids.get(r['id'])} for r in rows]


def run_campaign(cid):
    """
    Everything due for campaign cid, now. Safe to call from anywhere at any time.

    The app's phones first (fast), then Telegram (25 a second). Each batch's
    people get the message in their inbox just before their push, so a
    canary pause leaves the rest without it. With a canary of N, it pauses
    once N phones and N Telegram chats were tried.
    """
    if not _take_lease(cid):
        return
    try:
        _fan_out(cid)
        while True:
            conn = _db()
            try:
                c = _load(conn, cid)
            finally:
                conn.close()
            if c['stop_requested']:
                _stop(cid, 'cancelled')
                return
            limit = {'app': BATCH, 'telegram': BATCH}
            done = _attempted(cid)
            if not done.get('telegram'):
                limit['telegram'] = TG_FIRST_BATCH
            if c['canary'] and not c['canary_done']:
                for ch in limit:
                    limit[ch] = min(limit[ch], max(0, c['canary'] - done.get(ch, 0)))
            rows = _claim(cid, 'app', limit['app'])
            if rows:
                _put_in_inboxes(c, only_users={r['user_id'] for r in rows})
                _send_rows(c, _with_inbox_ids(rows))
                reason = _hopeless(cid)
                if reason:
                    _stop(cid, 'failed', f'Stopped: the first phones all failed for the message itself ({reason}).')
                    return
                _renew_lease(cid)
                continue
            rows = _claim(cid, 'telegram', limit['telegram'])
            if rows:
                _send_tg_rows(c, rows)
                stop = _tg_hopeless(cid)
                if stop:
                    if stop[0] == 'wrong_bot':
                        _unblock_campaign(cid)
                    _stop(cid, 'failed', stop[1])
                    return
                _renew_lease(cid)
                continue
            break
        if c['canary'] and not c['canary_done'] and _left(cid):
            _pause(cid)
            return
        _put_in_inboxes(c)          # the people with notifications off, and anyone missed
        _finish_if_done(cid)
    except Exception:
        logger.exception(f'[CAMPAIGN] {cid}')
        conn = _db()
        try:
            conn.execute("UPDATE campaigns SET lease_until = NULL WHERE id = ?", (cid,))
            conn.commit()
        finally:
            conn.close()


def _left(cid):
    """Rows still to send now (not waiting for a retry)."""
    conn = _db()
    try:
        return conn.execute("SELECT COUNT(*) FROM deliveries WHERE campaign_id = ? AND test = 0 "
                            "AND status = 'pending'", (cid,)).fetchone()[0]
    finally:
        conn.close()


def _pause(cid):
    conn = _db()
    try:
        conn.execute("UPDATE campaigns SET status = 'paused', lease_until = NULL, updated_at = ? "
                     "WHERE id = ? AND status = 'sending'", (_fmt(_now()), cid))
        conn.commit()
    finally:
        conn.close()
    logger.info(f'[CAMPAIGN] {cid}: paused after the canary')


def work_once():
    """Start what is due, send what waits. The worker thread calls this every few seconds."""
    now = _fmt(_now())
    conn = _db()
    try:
        for r in conn.execute("SELECT id, scheduled_at FROM campaigns WHERE status = 'scheduled' AND scheduled_at < ?",
                              (_fmt(_now() - LATE),)).fetchall():
            conn.execute("UPDATE campaigns SET status = 'failed', updated_at = ?, error = ? WHERE id = ?",
                         (now, f"Not sent: its time ({_iso(r['scheduled_at'])}) passed while the server was off. "
                               f"Duplicate it to send it now.", r['id']))
        conn.execute("UPDATE campaigns SET status = 'sending', started_at = COALESCE(started_at, ?), "
                     "updated_at = ? WHERE status = 'scheduled' AND scheduled_at <= ?", (now, now, now))
        conn.commit()
        due = [r['id'] for r in conn.execute(
            "SELECT id FROM campaigns WHERE status = 'sending' AND (lease_until IS NULL OR lease_until < ?) "
            "ORDER BY id", (now,))]
    finally:
        conn.close()
    for cid in due:
        run_campaign(cid)
    return bool(due)


def _work_forever():
    logger.info('[CAMPAIGN] worker started')
    while True:
        try:
            work_once()
        except Exception:
            logger.exception('[CAMPAIGN] worker round')
        _wake.wait(POLL_SECONDS)
        _wake.clear()


# ============================================
# NUMBERS
# ============================================

_COUNTS = """
SELECT campaign_id,
  COUNT(DISTINCT CASE WHEN channel = 'app' THEN user_id END)                    AS users,
  SUM(channel = 'app' AND token_hash != '')                                     AS phones,
  COUNT(DISTINCT CASE WHEN channel = 'app' AND token_hash = '' THEN user_id END) AS inbox_only,
  SUM(channel = 'app' AND token_hash != '' AND status IN ('pending', 'sending', 'retry')) AS pending,
  SUM(status = 'retry')                                                         AS retrying,
  SUM(channel = 'app' AND token_hash != '' AND status = 'sent')                 AS sent,
  SUM(channel = 'app' AND status = 'dead')                                      AS dead,
  SUM(channel = 'app' AND status = 'failed')                                    AS failed,
  SUM(channel = 'app' AND status = 'unknown')                                   AS unknown,
  SUM(status = 'skipped')                                                       AS skipped,
  SUM(channel = 'app' AND token_hash != '' AND status = 'sent' AND reports > 0) AS reporting_sent,
  SUM(channel = 'app' AND token_hash != '' AND status = 'sent' AND reports > 0 AND platform = 'android') AS reporting_android,
  SUM(channel = 'app' AND token_hash != '' AND received_at IS NOT NULL AND platform = 'android' AND reports > 0) AS received,
  SUM(channel = 'app' AND token_hash != '' AND opened_at IS NOT NULL)           AS opened,
  COUNT(DISTINCT CASE WHEN channel = 'app' AND reports > 0 THEN user_id END)    AS reporting_users,
  COUNT(DISTINCT CASE WHEN channel = 'app' AND read_at IS NOT NULL THEN user_id END) AS read_users,
  COUNT(DISTINCT CASE WHEN channel = 'app' AND clicks > 0 THEN user_id END)     AS clicked_users,
  SUM(CASE WHEN channel = 'app' THEN clicks ELSE 0 END)                         AS clicks,
  SUM(channel = 'telegram')                                                     AS tg_users,
  SUM(channel = 'telegram' AND status = 'sent')                                 AS tg_sent,
  SUM(channel = 'telegram' AND status = 'blocked')                              AS tg_blocked,
  SUM(channel = 'telegram' AND status IN ('failed', 'unknown'))                 AS tg_failed,
  SUM(channel = 'telegram' AND status IN ('pending', 'sending', 'retry'))       AS tg_pending,
  SUM(channel = 'telegram' AND status = 'skipped')                              AS tg_skipped,
  COUNT(DISTINCT CASE WHEN channel = 'telegram' AND clicks > 0 THEN user_id END) AS tg_clicked_users,
  SUM(CASE WHEN channel = 'telegram' THEN clicks ELSE 0 END)                    AS tg_clicks,
  MIN(CASE WHEN channel = 'telegram' THEN sent_at END)                          AS tg_first,
  MAX(CASE WHEN channel = 'telegram' THEN sent_at END)                          AS tg_last
FROM deliveries WHERE test = 0 {where} GROUP BY campaign_id
"""


def _rate(n, d):
    return round(100.0 * n / d, 1) if d else None


def _numbers(r):
    n = {k: (r[k] or 0) for k in r.keys() if k not in ('campaign_id', 'tg_first', 'tg_last')}
    n['failed_all'] = n['dead'] + n['failed'] + n['unknown']
    attempted = n['sent'] + n['failed_all']
    tg_done = n['tg_sent'] + n['tg_blocked'] + n['tg_failed']
    n['rates'] = {
        # Of the phones FCM was asked to take it to.
        'accepted': _rate(n['sent'], attempted),
        'failure': _rate(n['failed_all'], attempted),
        # Of the Android phones that report and FCM took it for.
        'delivery': _rate(n['received'], n['reporting_android']),
        # Of the phones that report and FCM took it for.
        'open': _rate(n['opened'], n['reporting_sent']),
        # Of the people whose app reports.
        'read': _rate(n['read_users'], n['reporting_users']),
        # Of the people who read it.
        'click': _rate(n['clicked_users'], n['read_users']),
        # Telegram: of the chats tried, in the chat / blocked; of those it reached, tapped a link.
        'tg_delivery': _rate(n['tg_sent'], tg_done),
        'tg_blocked': _rate(n['tg_blocked'], tg_done),
        'tg_click': _rate(n['tg_clicked_users'], n['tg_sent']),
    }
    # How fast Telegram went: messages a second between the first and the last.
    if r['tg_first'] and r['tg_last'] and n['tg_sent'] > 1:
        span = (datetime.strptime(r['tg_last'], TS) - datetime.strptime(r['tg_first'], TS)).total_seconds()
        n['tg_minutes'] = round(span / 60, 1)
        n['tg_per_second'] = round(n['tg_sent'] / span, 1) if span else None
    return n


def _numbers_for(conn, ids):
    if not ids:
        return {}
    rows = conn.execute(_COUNTS.format(where=f"AND campaign_id IN ({','.join('?' * len(ids))})"), ids).fetchall()
    return {r['campaign_id']: _numbers(r) for r in rows}


# ============================================
# ADMIN ENDPOINTS
# ============================================

def _admin(write=False):
    """None when allowed, else the response."""
    if not session.get('admin_logged_in'):
        return _err('not_authenticated', 'Log in at /admin first.', 401)
    if write and request.headers.get('X-Push-Panel') != '1':
        return _err('bad_request', 'Missing X-Push-Panel header.', 400)
    return None


def _guard(fn):
    def wrapper(*args, **kwargs):
        denied = _admin(write=request.method not in ('GET', 'HEAD'))
        return denied or fn(*args, **kwargs)
    wrapper.__name__ = fn.__name__
    return wrapper


@bp.route('/admin/push')
def push_panel():
    if not session.get('admin_logged_in'):
        return redirect('/admin')
    return send_file(current_app.config.get('PUSH_PANEL_HTML') or os.path.join(HERE, 'templates', 'admin_push.html'))


@bp.route('/api/admin/push/overview')
@_guard
def overview():
    """Campaigns, newest first, with their numbers. ?status=&q=&from=&to=&templates=1"""
    where, args = ['1=1'], []
    status = request.args.get('status')
    if status in STATUSES:
        where.append('status = ?')
        args.append(status)
    q = (request.args.get('q') or '').strip()
    if q:
        where.append("(name LIKE ? OR title LIKE ? OR html LIKE ?)")
        args += [f'%{q}%'] * 3
    for key, op in (('from', '>='), ('to', '<=')):
        ts = _utc_or_none(request.args.get(key))
        if ts:
            where.append(f"COALESCE(started_at, scheduled_at, created_at) {op} ?")
            args.append(ts)
    if request.args.get('templates') == '1':
        where.append('is_template = 1')
    conn = _db()
    try:
        rows = conn.execute(f"SELECT * FROM campaigns WHERE {' AND '.join(where)} "
                            f"ORDER BY COALESCE(started_at, scheduled_at, updated_at) DESC LIMIT 300", args).fetchall()
        numbers = _numbers_for(conn, [r['id'] for r in rows])
        counts = {r['status']: r['n'] for r in conn.execute("SELECT status, COUNT(*) AS n FROM campaigns GROUP BY status")}
        testers = [dict(r) for r in conn.execute("SELECT * FROM testers ORDER BY added_at")]
    finally:
        conn.close()
    names = _names([t['user_id'] for t in testers])
    return jsonify({
        'success': True,
        'campaigns': [_view(r, numbers.get(r['id'])) for r in rows],
        'counts': counts,
        'testers': [{**t, **names.get(t['user_id'], {}), 'added_at': _iso(t['added_at'])} for t in testers],
        'sections': [{'id': k, 'emoji': v[0], 'label': v[1]} for k, v in SECTIONS.items()],
        'ttl_hours': TTL_HOURS,
        'push_enabled': app_push.enabled(),
        'telegram': _tg_info(),
        'limits': {'title': TITLE_MAX, 'text': TEXT_MAX, 'images': IMAGES_MAX, 'body': app_push.BODY_MAX,
                   'tg_caption': push_telegram.CAPTION_MAX, 'tg_text': push_telegram.TEXT_MAX},
    })


def _tg_info():
    """The bot and its list, for the panel."""
    conn = _db()
    try:
        r = conn.execute(
            "SELECT COUNT(*) AS n, SUM(blocked_at IS NOT NULL AND COALESCE(blocked_reason, '') NOT LIKE '%deactivated%') "
            "AS blocked, SUM(COALESCE(blocked_reason, '') LIKE '%deactivated%') AS deleted, MAX(added_at) AS last "
            "FROM tg_users").fetchone()
    finally:
        conn.close()
    bot = S.tg_bot.username() if S.tg_bot else None
    return {'configured': bool(S.tg_bot), 'bot': bot, 'token_works': bool(bot) if S.tg_bot else None,
            'list': r['n'] or 0, 'blocked': r['blocked'] or 0, 'deleted': r['deleted'] or 0,
            'reachable': (r['n'] or 0) - (r['deleted'] or 0), 'updated_at': _iso(r['last'])}


@bp.route('/api/admin/push/campaigns', methods=['POST'])
@_guard
def create():
    body = request.get_json(silent=True) or {}
    now = _fmt(_now())
    try:
        sets = _apply(None, body)
    except ValueError as e:
        return _err('invalid', str(e))
    conn = _db()
    try:
        cur = conn.execute("INSERT INTO campaigns (created_at, updated_at) VALUES (?, ?)", (now, now))
        cid = cur.lastrowid
        if sets:
            conn.execute(f"UPDATE campaigns SET {', '.join(f'{k} = ?' for k in sets)} WHERE id = ?",
                         (*sets.values(), cid))
        conn.commit()
        row = _load(conn, cid)
    finally:
        conn.close()
    return jsonify({'success': True, 'campaign': _view(row)}), 201


@bp.route('/api/admin/push/campaigns/<int:cid>', methods=['GET', 'PUT', 'DELETE'])
@_guard
def campaign(cid):
    conn = _db()
    try:
        row = _load(conn, cid)
        if not row:
            return _err('not_found', 'No such campaign.', 404)
        if request.method == 'GET':
            return jsonify({'success': True, 'campaign': _view(row, _numbers_for(conn, [cid]).get(cid)),
                            'problems': _problems(row)})
        if request.method == 'DELETE':
            if row['status'] != 'draft':
                return _err('not_draft', 'Only drafts can be deleted; sent campaigns stay in the history.', 409)
            conn.execute("DELETE FROM deliveries WHERE campaign_id = ?", (cid,))
            conn.execute("DELETE FROM campaigns WHERE id = ?", (cid,))
            conn.commit()
            return jsonify({'success': True, 'deleted': cid})
        body = request.get_json(silent=True) or {}
        if row['status'] not in ('draft', 'scheduled'):
            # A finished campaign can still become (or stop being) a template.
            if set(body) - {'version'} == {'is_template'}:
                conn.execute("UPDATE campaigns SET is_template = ? WHERE id = ?",
                             (1 if body.get('is_template') else 0, cid))
                conn.commit()
                return jsonify({'success': True, 'campaign': _view(_load(conn, cid))})
            return _err('locked', 'It has been sent: duplicate it to send something like it.', 409)
        if 'version' in body and int(body.get('version') or 0) != row['version']:
            return _err('stale', 'It was changed elsewhere (another tab?). Reload to see the latest.', 409,
                        campaign=_view(row))
        try:
            sets = _apply(row, body)
        except ValueError as e:
            return _err('invalid', str(e))
        sets['updated_at'] = _fmt(_now())
        conn.execute(f"UPDATE campaigns SET {', '.join(f'{k} = ?' for k in sets)}, version = version + 1 "
                     f"WHERE id = ?", (*sets.values(), cid))
        conn.commit()
        row = _load(conn, cid)
        return jsonify({'success': True, 'campaign': _view(row), 'problems': _problems(row)})
    finally:
        conn.close()


@bp.route('/api/admin/push/campaigns/<int:cid>/duplicate', methods=['POST'])
@_guard
def duplicate(cid):
    """A new draft with this one's content and audience: to send something like it again."""
    now = _fmt(_now())
    conn = _db()
    try:
        row = _load(conn, cid)
        if not row:
            return _err('not_found', 'No such campaign.', 404)
        name = row['name'] or row['title']
        cur = conn.execute(
            "INSERT INTO campaigns (name, title, html, images, target, ttl_hours, audience, copied_from, "
            "created_at, updated_at, channels, tg_title, tg_preview, tg_track, tg_skip_app, tg_file_ids) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (f'{name} (copy)'[:NAME_MAX] if name else '', row['title'], row['html'], row['images'], row['target'],
             row['ttl_hours'], row['audience'], cid, now, now, row['channels'], row['tg_title'], row['tg_preview'],
             row['tg_track'], row['tg_skip_app'], row['tg_file_ids']))
        conn.commit()
        new = _load(conn, cur.lastrowid)
    finally:
        conn.close()
    return jsonify({'success': True, 'campaign': _view(new)}), 201


@bp.route('/api/admin/push/audience', methods=['POST'])
@_guard
def audience():
    body = request.get_json(silent=True) or {}
    return jsonify({'success': True, **estimate(body.get('audience'), body.get('channels') or ['app'],
                                                body.get('tg_skip_app', True))})


@bp.route('/api/admin/push/users')
@_guard
def users():
    """People to pick: ?q= (id, name, @username, e-mail, phone) or ?recent=1 (phones last open)."""
    q = (request.args.get('q') or '').strip()
    conn = _accounts()
    try:
        base = ("SELECT s.platform, s.lang, s.seen_at, s.created_at, s.push_token IS NOT NULL AS push, "
                "COALESCE(s.reports, 0) AS reports, a.id AS account_id, a.tg_id FROM sessions s "
                "JOIN accounts a ON a.id = s.account_id ")
        if q:
            args, cond = [], []
            if q.lstrip('-').isdigit():
                n = int(q)
                cond.append('a.tg_id = ?')
                args.append(n)
                if app_accounts.is_app_user(n):
                    cond.append('a.id = ?')
                    args.append(-n - app_accounts.APP_ID_BASE)
            cond.append("a.id IN (SELECT account_id FROM identities WHERE name LIKE ? OR detail LIKE ?)")
            args += [f'%{q}%', f'%{q}%']
            rows = conn.execute(base + f"WHERE {' OR '.join(cond)} ORDER BY s.seen_at DESC LIMIT 50", args).fetchall()
        else:
            rows = conn.execute(base + "ORDER BY s.seen_at DESC LIMIT 25").fetchall()
    except sqlite3.OperationalError:
        rows = []
    finally:
        conn.close()
    people = {}
    for r in rows:
        uid = int(r['tg_id']) if r['tg_id'] else app_accounts.app_user_id(r['account_id'])
        p = people.setdefault(uid, {'id': uid, 'phones': []})
        p['phones'].append({'platform': r['platform'], 'lang': r['lang'], 'push': bool(r['push']),
                            'reports': bool(r['reports']), 'seen_at': _iso(r['seen_at']),
                            'installed_at': _iso(r['created_at'])})
    # The bot's list: by id or @username.
    if q:
        conn = _db()
        try:
            term = q.lstrip('@')
            for r in conn.execute("SELECT user_id, username, blocked_at FROM tg_users WHERE user_id = ? OR "
                                  "username LIKE ? LIMIT 20", (int(q) if q.lstrip('-').isdigit() else 0, f'%{term}%')):
                p = people.setdefault(r['user_id'], {'id': r['user_id'], 'phones': []})
                p['telegram'] = {'username': r['username'], 'blocked': bool(r['blocked_at'])}
        finally:
            conn.close()
    names = _names(list(people))
    return jsonify({'success': True, 'users': [{**p, **names.get(p['id'], {})} for p in people.values()]})


@bp.route('/api/admin/push/telegram', methods=['GET'])
@_guard
def telegram_info():
    return jsonify({'success': True, **_tg_info()})


@bp.route('/api/admin/push/telegram/list', methods=['POST'])
@_guard
def telegram_list():
    """
    The bot's people, from a CSV like the broadcast script's (id, username).
    mode=add: these join the list; mode=replace: the list becomes this file.
    Who Telegram called blocked stays blocked unless forget_blocked=1.
    """
    f = request.files.get('file')
    if not f:
        return _err('invalid', 'No file.')
    raw = f.read(30 * 1024 * 1024 + 1)
    if len(raw) > 30 * 1024 * 1024:
        return _err('too_big', 'At most 30 MB.')
    skipped = {}
    people = push_telegram.parse_list(raw, skipped)
    if not people:
        return _err('empty', 'No Telegram ids found: the first column should be the id.', skipped=skipped)
    mode = request.form.get('mode') if request.form.get('mode') in ('add', 'replace') else 'add'
    forget = request.form.get('forget_blocked') == '1'
    now = _fmt(_now())
    conn = _db()
    try:
        before = {r[0] for r in conn.execute("SELECT user_id FROM tg_users")}
        if mode == 'replace':
            keep = {uid for uid, _ in people}
            conn.executemany("DELETE FROM tg_users WHERE user_id = ?", [(u,) for u in before - keep])
        conn.executemany("INSERT INTO tg_users (user_id, username, added_at) VALUES (?, ?, ?) "
                         "ON CONFLICT (user_id) DO UPDATE SET username = COALESCE(excluded.username, username)",
                         [(uid, name, now) for uid, name in people])
        if forget:
            conn.executemany("UPDATE tg_users SET blocked_at = NULL, blocked_reason = NULL, blocked_campaign = NULL "
                             "WHERE user_id = ?", [(uid,) for uid, _ in people])
        conn.commit()
    finally:
        conn.close()
    new = sum(1 for uid, _ in people if uid not in before)
    logger.info(f'[CAMPAIGN] Telegram list {mode}: {len(people)} in the file, {new} new')
    return jsonify({'success': True, 'in_file': len(people), 'new': new, 'skipped': skipped,
                    'removed': len(before - {u for u, _ in people}) if mode == 'replace' else 0, **_tg_info()})


@bp.route('/api/admin/push/telegram/list.csv')
@_guard
def telegram_list_csv():
    conn = _db()
    try:
        rows = conn.execute("SELECT user_id, username, added_at, blocked_at, blocked_reason FROM tg_users "
                            "ORDER BY added_at, user_id").fetchall()
    finally:
        conn.close()
    return _csv('telegram_list.csv', ['user_id', 'username', 'added_at_utc', 'blocked_at_utc', 'blocked_because'],
                [tuple(r) for r in rows])


@bp.route('/api/admin/push/testers', methods=['GET', 'POST'])
@_guard
def testers():
    conn = _db()
    try:
        if request.method == 'POST':
            body = request.get_json(silent=True) or {}
            try:
                uid = int(body.get('user_id'))
            except (TypeError, ValueError):
                return _err('invalid', 'user_id is a number.')
            conn.execute("INSERT OR REPLACE INTO testers (user_id, label, added_at) VALUES (?, ?, ?)",
                         (uid, str(body.get('label') or '').strip()[:60] or None, _fmt(_now())))
            conn.commit()
        rows = [dict(r) for r in conn.execute("SELECT * FROM testers ORDER BY added_at")]
    finally:
        conn.close()
    names = _names([t['user_id'] for t in rows])
    return jsonify({'success': True, 'testers': [{**t, **names.get(t['user_id'], {}), 'added_at': _iso(t['added_at'])}
                                                 for t in rows]})


@bp.route('/api/admin/push/testers/<int:uid>', methods=['DELETE'])
@_guard
def tester_delete(uid):
    conn = _db()
    try:
        conn.execute("DELETE FROM testers WHERE user_id = ?", (uid,))
        conn.commit()
    finally:
        conn.close()
    return jsonify({'success': True})


@bp.route('/api/admin/push/campaigns/<int:cid>/test', methods=['POST'])
@_guard
def test_send(cid):
    """
    The campaign as it is saved, now, to a few people (their phones and
    inbox), outside its numbers. The answer says what happened on each phone.
    """
    body = request.get_json(silent=True) or {}
    try:
        ids = sorted({int(i) for i in body.get('user_ids') or []})
    except (TypeError, ValueError):
        return _err('invalid', 'user_ids are numbers.')
    if not ids:
        return _err('invalid', 'Choose who gets the test.')
    if len(ids) > TEST_MAX:
        return _err('invalid', f'At most {TEST_MAX} people in a test.')
    conn = _db()
    try:
        c = _load(conn, cid)
        if not c:
            return _err('not_found', 'No such campaign.', 404)
        problems = _problems(c)
        if problems:
            return _err('not_ready', ' '.join(problems), problems=problems)
        run = c['tests'] + 1
        conn.execute("UPDATE campaigns SET tests = ? WHERE id = ?", (run, cid))
        channels = _channels(c)
        people = _people({'mode': 'users', 'include': ids}) if 'app' in channels else []
        rows = []
        for p in people:
            for ph in p['phones'] or [None]:
                rows.append((cid, p['id'], ph['token_hash'] if ph else '', ph['push_token'] if ph else None,
                             (ph or p)['platform'], (ph or p)['lang'], (ph or p)['reports'],
                             'pending' if ph else 'inbox', run, 'app'))
        # Telegram: every chosen Telegram id, blocked or not (a test should show what happens).
        tg_ids = [i for i in ids if push_telegram.is_telegram_id(i)] if 'telegram' in channels else []
        rows += [(cid, i, 'telegram', None, 'telegram', None, 0, 'pending', run, 'telegram') for i in tg_ids]
        conn.executemany(
            "INSERT OR IGNORE INTO deliveries (campaign_id, user_id, token_hash, push_token, platform, lang, "
            "reports, status, test, channel) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
        conn.commit()
        c = _load(conn, cid)
    finally:
        conn.close()
    _put_in_inboxes(c, test=run)
    conn = _db()
    try:
        pending = [{**dict(r), 'attempts': 1} for r in conn.execute(
            "SELECT * FROM deliveries WHERE campaign_id = ? AND test = ? AND status = 'pending'", (cid, run))]
        conn.executemany("UPDATE deliveries SET status = 'sending', attempts = 1 WHERE id = ?",
                         [(r['id'],) for r in pending])
        conn.commit()
    finally:
        conn.close()
    _send_rows(c, [r for r in pending if r['channel'] == 'app'])
    _send_tg_rows(c, [r for r in pending if r['channel'] == 'telegram'])
    conn = _db()
    try:
        results = [dict(r) for r in conn.execute(
            "SELECT id, user_id, channel, platform, lang, reports, status, error_code, error, "
            "token_hash NOT IN ('', 'telegram') AS phone FROM deliveries WHERE campaign_id = ? AND test = ? "
            "ORDER BY user_id, channel, id", (cid, run))]
    finally:
        conn.close()
    names = _names(ids)
    found = {p['id'] for p in people} | set(tg_ids)
    return jsonify({'success': True, 'run': run,
                    'results': [{**r, **names.get(r['user_id'], {})} for r in results],
                    'not_found': [i for i in ids if i not in found]})


@bp.route('/api/admin/push/campaigns/<int:cid>/send', methods=['POST'])
@_guard
def send(cid):
    """
    {"expected_users": n, "when": "now"|"schedule", "at": "2026-11-10T09:00", "tz": "Asia/Seoul",
     "confirm_duplicate": bool}. Refused when the audience is no longer n people
    (409 audience_changed, with the new count), or the same message went out
    in the last 24 hours and that wasn't confirmed (409 duplicate).
    """
    body = request.get_json(silent=True) or {}
    when = body.get('when') if body.get('when') in ('now', 'schedule') else None
    if not when:
        return _err('invalid', 'when is "now" or "schedule".')
    conn = _db()
    try:
        c = _load(conn, cid)
        if not c:
            return _err('not_found', 'No such campaign.', 404)
        if c['status'] not in ('draft', 'scheduled'):
            return _err('already', f'It is already {c["status"]}.', 409, campaign=_view(c))
        problems = _problems(c)
        if problems:
            return _err('not_ready', ' '.join(problems), problems=problems)
        counted = estimate(_audience(c), _channels(c), bool(c['tg_skip_app']))
        tg_count = (counted['telegram'] or {}).get('users', 0)
        try:
            expected = int(body.get('expected_users'))
            expected_tg = int(body.get('expected_telegram') or 0)
        except (TypeError, ValueError):
            expected, expected_tg = -1, -1
        if counted['users'] == 0 and tg_count == 0:
            return _err('nobody', 'Nobody matches this audience.')
        if expected != counted['users'] or expected_tg != tg_count:
            return _err('audience_changed', f'The audience is now {counted["users"]} in the app and {tg_count} on '
                        f'Telegram, not {expected} and {expected_tg}. Check it and confirm again.', 409,
                        users=counted['users'], telegram=tg_count, estimate=counted)
        try:
            canary = int(body.get('canary') or 0)
        except (TypeError, ValueError):
            canary = 0
        canary = canary if canary > 0 else None
        if not body.get('confirm_duplicate'):
            twin = conn.execute(
                "SELECT id, name, title, started_at FROM campaigns WHERE id != ? AND title = ? AND html = ? "
                "AND status IN ('sending', 'done') AND started_at >= ? ORDER BY started_at DESC LIMIT 1",
                (cid, c['title'], c['html'], _fmt(_now() - DUPLICATE_WINDOW))).fetchone()
            if twin:
                return _err('duplicate', 'The same message went out in the last 24 hours.', 409,
                            other={'id': twin['id'], 'name': twin['name'] or twin['title'],
                                   'started_at': _iso(twin['started_at'])})
        now = _now()
        if when == 'now':
            cur = conn.execute("UPDATE campaigns SET status = 'sending', started_at = ?, scheduled_at = NULL, "
                               "updated_at = ?, error = NULL, stop_requested = 0, canary = ?, canary_done = 0 "
                               "WHERE id = ? AND status IN ('draft', 'scheduled')", (_fmt(now), _fmt(now), canary, cid))
        else:
            try:
                tz = ZoneInfo(str(body.get('tz') or 'Asia/Seoul'))
                local = datetime.fromisoformat(str(body.get('at') or ''))
            except Exception:
                return _err('invalid', 'Choose a date and time.')
            at = (local.replace(tzinfo=tz) if local.tzinfo is None else local).astimezone(timezone.utc)
            if at < now + timedelta(minutes=1):
                return _err('invalid', 'That time has passed: choose one at least a minute from now.')
            if at > now + timedelta(days=60):
                return _err('invalid', 'At most 60 days ahead.')
            cur = conn.execute("UPDATE campaigns SET status = 'scheduled', scheduled_at = ?, schedule_tz = ?, "
                               "updated_at = ?, error = NULL, stop_requested = 0, canary = ?, canary_done = 0 "
                               "WHERE id = ? AND status IN ('draft', 'scheduled')",
                               (_fmt(at), str(body.get('tz') or 'Asia/Seoul'), _fmt(now), canary, cid))
        conn.commit()
        if not cur.rowcount:
            return _err('already', 'It changed meanwhile; reload.', 409)
        row = _load(conn, cid)
    finally:
        conn.close()
    _wake.set()
    logger.info(f'[CAMPAIGN] {cid}: {when} to {counted["users"]} in the app, {tg_count} on Telegram')
    return jsonify({'success': True, 'campaign': _view(row)})


@bp.route('/api/admin/push/campaigns/<int:cid>/cancel', methods=['POST'])
@_guard
def cancel(cid):
    """A scheduled one goes back to being a draft; one sending stops after the batch in hand."""
    conn = _db()
    try:
        c = _load(conn, cid)
        if not c:
            return _err('not_found', 'No such campaign.', 404)
        if c['status'] == 'scheduled':
            conn.execute("UPDATE campaigns SET status = 'draft', scheduled_at = NULL, updated_at = ? "
                         "WHERE id = ? AND status = 'scheduled'", (_fmt(_now()), cid))
        elif c['status'] == 'sending':
            conn.execute("UPDATE campaigns SET stop_requested = 1 WHERE id = ?", (cid,))
        elif c['status'] == 'paused':
            conn.close()
            conn = None
            _stop(cid, 'cancelled')
        else:
            return _err('not_cancellable', f'It is {c["status"]}: nothing to cancel.', 409)
        if conn is None:
            conn = _db()
        conn.commit()
        row = _load(conn, cid)
    finally:
        if conn is not None:
            conn.close()
    _wake.set()
    return jsonify({'success': True, 'campaign': _view(row)})


@bp.route('/api/admin/push/campaigns/<int:cid>/resume', methods=['POST'])
@_guard
def resume(cid):
    """After the canary: the rest."""
    conn = _db()
    try:
        cur = conn.execute("UPDATE campaigns SET status = 'sending', canary_done = 1, updated_at = ? "
                           "WHERE id = ? AND status = 'paused'", (_fmt(_now()), cid))
        conn.commit()
        row = _load(conn, cid)
    finally:
        conn.close()
    if not row:
        return _err('not_found', 'No such campaign.', 404)
    if not cur.rowcount:
        return _err('not_paused', f'It is {row["status"]}, not paused.', 409, campaign=_view(row))
    _wake.set()
    return jsonify({'success': True, 'campaign': _view(row)})


@bp.route('/api/admin/push/campaigns/<int:cid>/report')
@_guard
def report(cid):
    conn = _db()
    try:
        c = _load(conn, cid)
        if not c:
            return _err('not_found', 'No such campaign.', 404)
        numbers = _numbers_for(conn, [cid]).get(cid)
        by = {}
        for key in ('platform', 'lang'):
            only_app = "AND channel = 'app'" if key == 'lang' else ''     # the bot's list has no language
            by[key] = [dict(r) for r in conn.execute(
                f"SELECT COALESCE({key}, '?') AS k, COUNT(DISTINCT user_id) AS users, "
                f"SUM(channel = 'app' AND token_hash != '') AS phones, "
                f"SUM(token_hash != '' AND status = 'sent') AS sent, "
                f"SUM(status IN ('dead', 'failed', 'unknown', 'blocked')) AS failed, "
                f"SUM(received_at IS NOT NULL AND platform = 'android' AND reports > 0) AS received, "
                f"SUM(token_hash != '' AND opened_at IS NOT NULL) AS opened, "
                f"COUNT(DISTINCT CASE WHEN read_at IS NOT NULL THEN user_id END) AS read_users "
                f"FROM deliveries WHERE campaign_id = ? AND test = 0 {only_app} GROUP BY k ORDER BY users DESC",
                (cid,))]
        errors = [{**dict(r), 'explain': ERRORS.get(r['code'] or '', '')} for r in conn.execute(
            "SELECT error_code AS code, status, MIN(error) AS example, COUNT(*) AS n FROM deliveries "
            "WHERE campaign_id = ? AND test = 0 AND error_code IS NOT NULL GROUP BY error_code, status "
            "ORDER BY n DESC", (cid,))]
        start = c['started_at']
        timeline = []
        if start:
            for r in conn.execute(
                    "SELECT CAST((julianday(t) - julianday(?)) * 24 AS INTEGER) AS h, kind, COUNT(*) AS n FROM ("
                    " SELECT sent_at AS t, 'sent' AS kind FROM deliveries WHERE campaign_id = ? AND test = 0 "
                    "   AND token_hash != '' AND sent_at IS NOT NULL"
                    " UNION ALL SELECT received_at, 'received' FROM deliveries WHERE campaign_id = ? AND test = 0 "
                    "   AND received_at IS NOT NULL AND platform = 'android' AND reports > 0"
                    " UNION ALL SELECT opened_at, 'opened' FROM deliveries WHERE campaign_id = ? AND test = 0 "
                    "   AND opened_at IS NOT NULL"
                    " UNION ALL SELECT read_at, 'read' FROM deliveries WHERE campaign_id = ? AND test = 0 "
                    "   AND read_at IS NOT NULL) GROUP BY h, kind HAVING h BETWEEN 0 AND 71 ORDER BY h",
                    (start, cid, cid, cid, cid)):
                timeline.append(dict(r))
        links = [dict(r) for r in conn.execute(
            "SELECT link, COUNT(*) AS clicks, COUNT(DISTINCT d.user_id) AS users FROM clicks k "
            "JOIN deliveries d ON d.id = k.delivery_id WHERE k.campaign_id = ? AND d.test = 0 "
            "GROUP BY link ORDER BY clicks DESC LIMIT 20", (cid,))]
        tests = [dict(r) for r in conn.execute(
            "SELECT test AS run, SUM(channel = 'app' AND token_hash != '') AS phones, "
            "SUM(channel = 'telegram') AS telegram, SUM(status = 'sent') AS sent, "
            "SUM(received_at IS NOT NULL) AS received, SUM(opened_at IS NOT NULL) AS opened, "
            "SUM(read_at IS NOT NULL) AS read FROM deliveries WHERE campaign_id = ? AND test > 0 "
            "GROUP BY test ORDER BY test DESC LIMIT 10", (cid,))]
    finally:
        conn.close()
    return jsonify({'success': True, 'campaign': _view(c, numbers), 'by_platform': by['platform'],
                    'by_lang': by['lang'], 'errors': errors, 'timeline': timeline, 'links': links,
                    'tests': tests})


_LOG_COLUMNS = ('id', 'user_id', 'channel', 'platform', 'lang', 'reports', 'status', 'attempts', 'error_code', 'error',
                'sent_at', 'received_at', 'opened_at', 'read_at', 'clicks')


def _log_query(cid):
    where, args = ['campaign_id = ?', 'test = 0'], [cid]
    status = request.args.get('status')
    groups = {'failed': ('dead', 'failed', 'unknown', 'blocked'), 'pending': ('pending', 'sending', 'retry'),
              'error': ('failed', 'unknown'), 'inbox': None}
    if status == 'inbox':
        where.append("token_hash = ''")
    elif status in groups:
        where.append(f"status IN ({','.join('?' * len(groups[status]))})")
        args += list(groups[status])
    elif status in ('sent', 'dead', 'skipped', 'unknown', 'retry', 'blocked'):
        where.append('status = ?')
        args.append(status)
    elif status in ('received', 'opened', 'read'):
        where.append(f'{status}_at IS NOT NULL')
    elif status == 'clicked':
        where.append('clicks > 0')
    platform = request.args.get('platform')
    if platform in app_accounts.PLATFORMS or platform == 'telegram':
        where.append('platform = ?')
        args.append(platform)
    channel = request.args.get('channel')
    if channel in CHANNELS:
        where.append('channel = ?')
        args.append(channel)
    q = (request.args.get('q') or '').strip()
    if q.lstrip('-').isdigit():
        where.append('user_id = ?')
        args.append(int(q))
    return ' AND '.join(where), args


@bp.route('/api/admin/push/campaigns/<int:cid>/deliveries')
@_guard
def deliveries(cid):
    """The audit log: one row per phone (and per person reached in the inbox only)."""
    where, args = _log_query(cid)
    try:
        page = max(0, int(request.args.get('page') or 0))
        size = max(10, min(100, int(request.args.get('size') or 100)))
    except ValueError:
        page, size = 0, 100
    conn = _db()
    try:
        total = conn.execute(f"SELECT COUNT(*) FROM deliveries WHERE {where}", args).fetchone()[0]
        rows = [dict(r) for r in conn.execute(
            f"SELECT {', '.join(_LOG_COLUMNS)}, token_hash NOT IN ('', 'telegram') AS phone FROM deliveries WHERE {where} "
            f"ORDER BY id LIMIT ? OFFSET ?", (*args, size, page * size))]
    finally:
        conn.close()
    names = _names({r['user_id'] for r in rows})
    usernames = _tg_usernames({r['user_id'] for r in rows if r['channel'] == 'telegram'})
    for r in rows:
        r.update(names.get(r['user_id'], {}))
        if usernames.get(r['user_id']):
            r['username'] = usernames[r['user_id']]
        for k in ('sent_at', 'received_at', 'opened_at', 'read_at'):
            r[k] = _iso(r[k])
        r['explain'] = ERRORS.get(r['error_code'] or '', '')
    return jsonify({'success': True, 'total': total, 'page': page, 'size': size, 'rows': rows})


def _tg_usernames(ids):
    ids = list(ids)
    if not ids:
        return {}
    conn = _db()
    try:
        out = {}
        for k in range(0, len(ids), 500):
            chunk = ids[k:k + 500]
            out.update({r[0]: r[1] for r in conn.execute(
                f"SELECT user_id, username FROM tg_users WHERE user_id IN ({','.join('?' * len(chunk))})", chunk)})
        return out
    finally:
        conn.close()


def _csv_cell(v):
    s = '' if v is None else str(v)
    return "'" + s if s[:1] in ('=', '+', '-', '@', '\t', '\r') and not s.lstrip('-').isdigit() else s


def _csv(name, header, rows):
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(header)
    for r in rows:
        w.writerow([_csv_cell(v) for v in r])
    return Response('﻿' + buf.getvalue(), mimetype='text/csv',
                    headers={'Content-Disposition': f'attachment; filename="{name}"'})


@bp.route('/api/admin/push/campaigns/<int:cid>/deliveries.csv')
@_guard
def deliveries_csv(cid):
    where, args = _log_query(cid)
    conn = _db()
    try:
        rows = conn.execute(f"SELECT {', '.join(_LOG_COLUMNS)}, token_hash NOT IN ('', 'telegram') AS phone "
                            f"FROM deliveries WHERE {where} ORDER BY id", args).fetchall()
    finally:
        conn.close()
    names = _names({r['user_id'] for r in rows})
    usernames = _tg_usernames({r['user_id'] for r in rows if r['channel'] == 'telegram'})
    header = ['delivery', 'user_id', 'name', 'signed_in_with', 'channel', 'platform', 'lang', 'app_reports',
              'phone', 'status', 'attempts', 'error_code', 'error', 'sent_at_utc', 'received_at_utc',
              'opened_at_utc', 'read_at_utc', 'link_taps']
    out = []
    for r in rows:
        n = names.get(r['user_id'], {})
        name = n.get('name') or (f"@{usernames[r['user_id']]}" if usernames.get(r['user_id']) else None)
        out.append([r['id'], r['user_id'], name, n.get('provider'), r['channel'], r['platform'], r['lang'],
                    'yes' if r['reports'] else 'no',
                    'yes' if r['phone'] else ('-' if r['channel'] == 'telegram' else 'no (inbox only)'), r['status'],
                    r['attempts'], r['error_code'], r['error'], r['sent_at'], r['received_at'], r['opened_at'],
                    r['read_at'], r['clicks']])
    return _csv(f'campaign_{cid}_deliveries.csv', header, out)


@bp.route('/api/admin/push/campaigns.csv')
@_guard
def campaigns_csv():
    conn = _db()
    try:
        rows = conn.execute("SELECT * FROM campaigns WHERE status != 'draft' ORDER BY id").fetchall()
        numbers = _numbers_for(conn, [r['id'] for r in rows])
    finally:
        conn.close()
    keys = ('users', 'phones', 'inbox_only', 'sent', 'dead', 'failed', 'unknown', 'skipped', 'pending',
            'reporting_sent', 'received', 'opened', 'read_users', 'clicked_users', 'clicks',
            'tg_users', 'tg_sent', 'tg_blocked', 'tg_failed', 'tg_pending', 'tg_clicked_users', 'tg_clicks')
    rates = ('accepted', 'failure', 'delivery', 'open', 'read', 'click', 'tg_delivery', 'tg_blocked', 'tg_click')
    header = ['id', 'name', 'title', 'status', 'started_at_utc', 'finished_at_utc', *keys,
              *(f'{r}_rate_%' for r in rates)]
    out = []
    for r in rows:
        n = numbers.get(r['id']) or {}
        out.append([r['id'], r['name'], r['title'], r['status'], r['started_at'], r['finished_at'],
                    *(n.get(k, 0) for k in keys), *((n.get('rates') or {}).get(k) for k in rates)])
    return _csv('push_campaigns.csv', header, out)


# ============================================
# PHOTOS
# ============================================

@bp.route('/api/admin/push/media', methods=['POST'])
@_guard
def upload():
    """A photo, re-encoded as JPEG (EXIF and anything else in the file dropped), at most 1600 px a side."""
    f = request.files.get('file')
    if not f:
        return _err('invalid', 'No file.')
    raw = f.read(PHOTO_IN_MAX + 1)
    if len(raw) > PHOTO_IN_MAX:
        return _err('too_big', 'At most 15 MB.')
    from PIL import Image, ImageOps
    Image.MAX_IMAGE_PIXELS = 50_000_000
    try:
        with Image.open(io.BytesIO(raw)) as probe:
            probe.verify()
        img = Image.open(io.BytesIO(raw))
        if img.format not in ('JPEG', 'PNG', 'WEBP', 'GIF'):
            return _err('bad_type', 'Use a JPEG, PNG or WebP photo.')
        img = ImageOps.exif_transpose(img)
        if img.mode in ('RGBA', 'LA', 'P'):
            img = img.convert('RGBA')
            flat = Image.new('RGB', img.size, (255, 255, 255))
            flat.paste(img, mask=img.split()[-1])
            img = flat
        else:
            img = img.convert('RGB')
        img.thumbnail((PHOTO_SIDE, PHOTO_SIDE), Image.LANCZOS)
        out = b''
        for quality in (86, 78, 70, 60):
            buf = io.BytesIO()
            img.save(buf, 'JPEG', quality=quality, optimize=True, progressive=True)
            out = buf.getvalue()
            if len(out) <= PHOTO_OUT_MAX:
                break
    except Exception as e:
        return _err('bad_image', f'Not a photo that can be read ({e.__class__.__name__}).')
    mid = secrets.token_urlsafe(18)
    with open(os.path.join(S.media, f'{mid}.jpg'), 'wb') as fh:
        fh.write(out)
    conn = _db()
    try:
        conn.execute("INSERT INTO media (id, width, height, bytes, name, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                     (mid, img.width, img.height, len(out), (f.filename or '')[:120], _fmt(_now())))
        conn.commit()
    finally:
        conn.close()
    return jsonify({'success': True, 'id': mid, 'url': media_url(mid), 'width': img.width, 'height': img.height,
                    'bytes': len(out)}), 201


_MEDIA_ID = re.compile(r'^[A-Za-z0-9_-]{16,40}$')


@bp.route('/api/push/media/<mid>.jpg')
def media(mid):
    if not _MEDIA_ID.match(mid):
        return _err('not_found', 'No such photo.', 404)
    response = send_from_directory(S.media, f'{mid}.jpg', mimetype='image/jpeg', max_age=31536000)
    response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    return response


# ============================================
# WHAT THE APP REPORTS
# ============================================

_BOTS = re.compile(r'TelegramBot|bot|crawler|spider|preview|facebookexternalhit|WhatsApp|Slack', re.I)


@bp.route('/api/push/r/<int:did>/<int:n>')
def follow(did, n):
    """A counted link (Telegram, when the campaign counts links): note the tap, then go there."""
    if not hmac.compare_digest(request.args.get('k') or '', event_key(did)):
        return Response('Not found', status=404, mimetype='text/plain')
    conn = _db()
    try:
        d = conn.execute("SELECT id, campaign_id, clicks FROM deliveries WHERE id = ?", (did,)).fetchone()
        c = _load(conn, d['campaign_id']) if d else None
        links = campaign_links(c) if c else []
        if n >= len(links):
            return Response('Not found', status=404, mimetype='text/plain')
        # Link previews and other robots open it too; they are not people.
        if not _BOTS.search(request.headers.get('User-Agent', '')) and d['clicks'] < CLICKS_MAX:
            now = _fmt(_now())
            conn.execute("UPDATE deliveries SET clicks = clicks + 1, clicked_at = COALESCE(clicked_at, ?) "
                         "WHERE id = ?", (now, did))
            conn.execute("INSERT INTO clicks (campaign_id, delivery_id, link, at) VALUES (?, ?, ?, ?)",
                         (d['campaign_id'], did, links[n][:500], now))
            conn.commit()
    finally:
        conn.close()
    return redirect(links[n], 302)


@bp.route('/api/app/push-event', methods=['POST'])
def push_event():
    """
    {"d": delivery id, "k": its key, "e": "received"|"opened"|"read"|"clicked", "link"?}.
    The first of each kind is kept (and every link tap). Opening implies the
    phone received it.
    """
    # Phones on one carrier often share an address: generous per address.
    if not app_accounts._rate_ok('push-event', 1200, 60):
        return _err('rate_limited', 'Too many requests.', 429)
    body = request.get_json(silent=True) or {}
    kind = body.get('e')
    try:
        did = int(body.get('d'))
    except (TypeError, ValueError):
        return _err('invalid', 'Bad delivery.')
    if kind not in EVENTS or not hmac.compare_digest(str(body.get('k') or ''), event_key(did)):
        return _err('invalid', 'Bad event.', 403)
    now = _fmt(_now())
    column = EVENTS[kind]
    conn = _db()
    try:
        d = conn.execute("SELECT id, campaign_id, platform, clicks FROM deliveries WHERE id = ?", (did,)).fetchone()
        if not d:
            return jsonify({'success': True, 'known': False})
        conn.execute(f"UPDATE deliveries SET {column} = COALESCE({column}, ?), reports = MAX(reports, 1) "
                     f"WHERE id = ?", (now, did))
        if kind in ('opened', 'read', 'clicked') and d['platform'] == 'android':
            conn.execute("UPDATE deliveries SET received_at = COALESCE(received_at, ?) WHERE id = ?", (now, did))
        if kind == 'clicked' and d['clicks'] < CLICKS_MAX:
            link = str(body.get('link') or '')[:500] or None
            conn.execute("UPDATE deliveries SET clicks = clicks + 1 WHERE id = ?", (did,))
            conn.execute("INSERT INTO clicks (campaign_id, delivery_id, link, at) VALUES (?, ?, ?, ?)",
                         (d['campaign_id'], did, link, now))
        conn.commit()
    finally:
        conn.close()
    return jsonify({'success': True})
