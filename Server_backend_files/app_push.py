"""
app_push.py
===========
Push notifications to the Muslim Vegukin app, through Firebase Cloud
Messaging (HTTP v1). Used by the place notifications sender in the API and
by the HiKorea poller (poll.py), which runs outside Flask.

Who gets what:

    an app-only account (id <= -9e12)     a push to each of their phones
    a Telegram id                         the Telegram message as before, and
                                          a push to each phone signed in with
                                          that Telegram account

Messages are written for Telegram (HTML); html_to_push() turns one into a
title and a body. The notification's first bold line is its title.

Configuration (environment, or app.config inside the API):

    APP_ACCOUNTS_DB            accounts.sqlite (phones and their push tokens)
    FIREBASE_SERVICE_ACCOUNT   the service account JSON from the Firebase
                               console (Project settings -> Service accounts).
                               Default: firebase-service-account.json next to
                               this file, if it is there. Neither: no pushes,
                               everything else unchanged.
"""

import html
import logging
import os
import re
import threading

import requests

import app_accounts

logger = logging.getLogger(__name__)

FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'
ANDROID_CHANNEL = 'alerts'
TITLE_MAX = 120
BODY_MAX = 1000
DEFAULT_TITLE = 'Muslim Vegukin'

DEFAULT_SERVICE_ACCOUNT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                       'firebase-service-account.json')

_credentials = None
_credentials_lock = threading.Lock()


def _cfg(key, default=None):
    return app_accounts._cfg(key, default)


def _service_account():
    path = _cfg('FIREBASE_SERVICE_ACCOUNT')
    if path:
        return path
    return DEFAULT_SERVICE_ACCOUNT if os.path.exists(DEFAULT_SERVICE_ACCOUNT) else None


def enabled():
    return bool(_service_account())


def _access():
    """(project_id, bearer token) for FCM, refreshed when near expiry."""
    global _credentials
    from google.auth.transport.requests import Request
    from google.oauth2 import service_account
    with _credentials_lock:
        if _credentials is None:
            _credentials = service_account.Credentials.from_service_account_file(
                _service_account(), scopes=[FCM_SCOPE])
        if not _credentials.valid:
            _credentials.refresh(Request())
        return _credentials.project_id, _credentials.token


# ============================================
# TEXT
# ============================================

_TAG = re.compile(r'<[^>]+>')


def _plain(fragment):
    return html.unescape(_TAG.sub('', fragment)).strip()


def html_to_message(text):
    """(title, whole text) from a Telegram HTML message. Rules (━━━) and
    blank lines go."""
    lines = [l for l in str(text or '').split('\n')]
    title = None
    for i, line in enumerate(lines):
        if not line.strip():
            continue
        if '<b>' in line and _plain(line):
            title = _plain(line)
            del lines[i]
        break
    body_lines = []
    for line in lines:
        plain = _plain(line)
        if not plain or set(plain) <= set('━─-=_ '):
            continue
        body_lines.append(plain)
    return (title or DEFAULT_TITLE)[:TITLE_MAX], '\n'.join(body_lines)


def preview(text):
    """What a notification can carry of a long text."""
    return text if len(text) <= BODY_MAX else text[:BODY_MAX - 1].rstrip() + '…'


def html_to_push(text):
    """(title, body) from a Telegram HTML message, the body cut to what a
    notification carries."""
    title, whole = html_to_message(text)
    return title, preview(whole)


def link_from_buttons(buttons):
    """The first button's address (web_app or url), for the app to open on tap."""
    try:
        for row in (buttons or {}).get('inline_keyboard', []):
            for b in row:
                url = (b.get('web_app') or {}).get('url') or b.get('url')
                if url:
                    return url
    except AttributeError:
        pass
    return None


# ============================================
# SENDING
# ============================================

def _send(project, access_token, push_token, title, body, data, image=None):
    """'sent' | 'dead' (forget the token) | 'retry'. image: a photo's address,
    shown large in the notification."""
    message = {
        'token': push_token,
        'notification': {'title': title, 'body': body, **({'image': image} if image else {})},
        'android': {'priority': 'high', 'notification': {'channel_id': ANDROID_CHANNEL}},
        'apns': {'payload': {'aps': {'sound': 'default'}}},
    }
    if data:
        message['data'] = {k: str(v) for k, v in data.items() if v is not None}
    try:
        resp = requests.post(f'https://fcm.googleapis.com/v1/projects/{project}/messages:send',
                             headers={'Authorization': f'Bearer {access_token}'},
                             json={'message': message}, timeout=10)
    except requests.RequestException as e:
        logger.warning(f'[PUSH] network: {e}')
        return 'retry'
    if resp.status_code == 200:
        return 'sent'
    try:
        err = resp.json().get('error', {})
    except ValueError:
        err = {}
    codes = {d.get('errorCode') for d in err.get('details', []) if isinstance(d, dict)}
    codes.add(err.get('status'))
    # Uninstalled, or a token that was never valid ("not a valid FCM registration token").
    bad_token = 'INVALID_ARGUMENT' in codes and 'token' in str(err.get('message', '')).lower()
    if resp.status_code == 404 or 'UNREGISTERED' in codes or (resp.status_code == 400 and bad_token):
        return 'dead'
    logger.warning(f'[PUSH] FCM {resp.status_code}: {str(err)[:300]}')
    return 'retry'


def _retry_after(value):
    try:
        return max(0, min(int(value), 3600))
    except (TypeError, ValueError):
        return None


def send_detailed(message, http=None):
    """
    One prepared FCM v1 message ({'token': ..., 'notification': ..., ...}),
    with everything FCM said about it, for senders that keep a record of
    each phone (push_campaigns.py). A dict:

        outcome      'sent' (FCM accepted it: not yet delivered) |
                     'dead' (the token will never work: forget it) |
                     'retry' (temporary: network, FCM busy or over quota) |
                     'failed' (retrying won't help: the message itself, or
                     the iOS key in Firebase)
        id           FCM's name for the message, when sent
        code         FCM's error code (UNREGISTERED, QUOTA_EXCEEDED, ...)
        error        its explanation, short
        retry_after  seconds FCM asked to wait, when it asked
    http: a requests.Session to reuse connections.
    """
    try:
        project, access_token = _access()
    except Exception as e:
        return {'outcome': 'retry', 'code': 'NO_ACCESS', 'error': str(e)[:200]}
    try:
        resp = (http or requests).post(f'https://fcm.googleapis.com/v1/projects/{project}/messages:send',
                                       headers={'Authorization': f'Bearer {access_token}'},
                                       json={'message': message}, timeout=10)
    except requests.RequestException as e:
        return {'outcome': 'retry', 'code': 'NETWORK', 'error': e.__class__.__name__}
    if resp.status_code == 200:
        try:
            name = resp.json().get('name')
        except ValueError:
            name = None
        return {'outcome': 'sent', 'id': name}
    try:
        err = resp.json().get('error', {})
    except ValueError:
        err = {}
    if not isinstance(err, dict):
        err = {}
    codes = {d.get('errorCode') for d in err.get('details', []) if isinstance(d, dict)} - {None}
    status = err.get('status')
    text = str(err.get('message') or resp.reason or '')[:300]
    result = {'code': next(iter(codes), None) or status or f'HTTP_{resp.status_code}', 'error': text}
    wait = _retry_after(resp.headers.get('Retry-After'))
    if wait is not None:
        result['retry_after'] = wait
    every = codes | {status}
    bad_token = 'INVALID_ARGUMENT' in every and 'token' in text.lower()
    if resp.status_code == 404 or every & {'UNREGISTERED', 'SENDER_ID_MISMATCH'} or (resp.status_code == 400 and bad_token):
        return {**result, 'outcome': 'dead'}
    if 'THIRD_PARTY_AUTH_ERROR' in every:
        return {**result, 'outcome': 'failed'}
    if resp.status_code == 401:
        _forget_access()
        return {**result, 'outcome': 'retry'}
    if resp.status_code in (429, 500, 502, 503, 504) or every & {'UNAVAILABLE', 'INTERNAL', 'QUOTA_EXCEEDED'}:
        return {**result, 'outcome': 'retry'}
    logger.warning(f'[PUSH] FCM {resp.status_code}: {text}')
    return {**result, 'outcome': 'failed'}


def _forget_access():
    """FCM refused our access token: read the service account again next time."""
    global _credentials
    with _credentials_lock:
        _credentials = None


def push_to_user(user_id, title, body, data=None, accounts_db=None, text=None, images=None):
    """
    Push to every phone signed in as this id, and keep it for their inbox.
    body: the notification's text, cut to fit; text: the whole message, for
    the inbox, when longer; images: photo addresses (the first one shows in
    the notification). Returns (sent, phones): phones is how many had a push
    token; sent how many FCM accepted.
    """
    body = preview(body or '')
    kept = app_accounts.add_to_inbox(user_id, title, body, data, accounts_db, text=text, images=images)
    if kept:
        # A tap opens the message in the app when it has no page of its own.
        data = {**(data or {}), 'inbox_id': kept}
    if not enabled():
        return 0, 0
    targets = app_accounts.push_targets(user_id, accounts_db)
    if not targets:
        return 0, 0
    try:
        project, access_token = _access()
    except Exception as e:
        logger.error(f'[PUSH] no FCM access: {e}')
        return 0, len(targets)
    sent = 0
    for _, push_token, _ in targets:
        outcome = _send(project, access_token, push_token, title, body, data, image=(images or [None])[0])
        if outcome == 'sent':
            sent += 1
        elif outcome == 'dead':
            app_accounts.forget_push_token(push_token, accounts_db)
    return sent, len(targets)


def push_to_token(push_token, title, body, data=None):
    """One notification to one phone, kept nowhere: 'sent' | 'dead' | 'retry'."""
    try:
        project, access_token = _access()
    except Exception as e:
        logger.error(f'[PUSH] no FCM access: {e}')
        return 'retry'
    return _send(project, access_token, push_token, title, preview(body), data)


def push_html(user_id, text, buttons=None, data=None, accounts_db=None):
    """push_to_user() for a message written for Telegram."""
    title, whole = html_to_message(text)
    data = dict(data or {})
    url = link_from_buttons(buttons)
    if url:
        data.setdefault('url', url)
    return push_to_user(user_id, title, whole, data, accounts_db, text=whole)


def deliver(user_id, text, send_telegram, data=None, accounts_db=None):
    """
    For senders that only know send_telegram(text, chat_id) -> notify.py's
    result dict (ok, blocked, error). App-only accounts get a push instead;
    Telegram users get both. Same result shape back:

        ok        delivered somewhere
        blocked   nowhere to deliver, ever (Telegram blocked, and no phones)

    An app user whose phone has notifications off is not "blocked": they may
    allow them tomorrow, and their watches should still work then.
    """
    if app_accounts.is_app_user(user_id):
        sent, phones = push_html(user_id, text, data=data, accounts_db=accounts_db)
        if sent:
            return {'ok': True, 'blocked': False, 'error': None, 'pushed': sent}
        error = 'push failed' if phones else 'no phone to push to'
        return {'ok': False, 'blocked': False, 'error': error, 'pushed': 0}
    result = dict(send_telegram(text, chat_id=user_id))
    sent, _ = push_html(user_id, text, data=data, accounts_db=accounts_db)
    result['pushed'] = sent
    if not result.get('ok') and sent:
        result.update(ok=True, blocked=False)
    return result
