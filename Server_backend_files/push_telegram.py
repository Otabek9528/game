"""
push_telegram.py
================
The Telegram side of push campaigns (push_campaigns.py): one campaign can go
to the app and, from the bot, to the people on the bot's list.

What it keeps from the broadcast script (reklama_8.py):

  - one pace for the whole process, 25 calls a second (Telegram allows about
    30), and when Telegram answers 429 everyone waits what it asks, plus half
    a second;
  - a photo is uploaded once: the first send gives Telegram's file_id, which
    every later send reuses (kept with the campaign, so tests warm it too);
  - one call per person when it fits: one photo with the text as its caption,
    or an album with the caption on its first photo. A text over 1024
    characters goes as photos, then the text;
  - "blocked" (403, chat not found) is noted, and tried again in the next
    campaign: people unblock bots. Only a deleted account ("user is
    deactivated") is left out from then on. Network trouble and Telegram's own
    errors are tried again, 3 times;
  - a crash never sends twice: each person is marked before the call.

What it adds: the formatting from the panel's editor (Telegram's own HTML),
the title as the first bold line, link previews off by default, tests, the
canary pause (push_campaigns), and link taps counted when asked: http(s)
links then pass through this server (see tracked_html()).

Telegram tells a bot nothing about delivery or reading, so "sent" here means
the message is in the person's chat; there are no read or open numbers.
"""

import csv
import html
import io
import logging
import re
import threading
import time

import requests

logger = logging.getLogger(__name__)

API = 'https://api.telegram.org/bot{token}/{method}'
CAPTION_MAX = 1024
TEXT_MAX = 4096
ALBUM_MAX = 10
NETWORK_TRIES = 3

# A Telegram user id is positive and, so far, at most 10 digits (they are
# handed out in order; the newest are around 8.5 billion). What else turns up
# in lists built from the stats log: app installs (negative, "Android app" /
# "iOS app") and WhatsApp users, whose id there is their phone number
# (821012345678, 998901234567: 11 to 13 digits). Neither can get a bot's
# message. Raise this when Telegram's ids reach 10 billion.
TELEGRAM_ID_MAX = 10 ** 10 - 1


def is_telegram_id(uid):
    return 0 < int(uid) <= TELEGRAM_ID_MAX
SLOW_DOWN_TRIES = 5

# Telegram's answers that mean this person can never be messaged (the script's list).
DEAD_CHAT_MARKERS = (
    'chat not found',
    'user is deactivated',
    'peer_id_invalid',
    'user not found',
    'bot was blocked',
    'chat_id is empty',
    'bot can\'t initiate conversation',
    'bot can\'t send messages to bots',
)


class RateLimiter:
    """One pace for every thread: calls are spaced 1/rate apart; pause() holds them all."""

    def __init__(self, rate_per_second):
        self.interval = 1.0 / max(0.1, float(rate_per_second))
        self._lock = threading.Lock()
        self._next = 0.0

    def acquire(self):
        with self._lock:
            now = time.monotonic()
            if self._next < now:
                self._next = now
            wait = self._next - now
            self._next += self.interval
        if wait > 0:
            time.sleep(wait)

    def pause(self, seconds):
        with self._lock:
            self._next = max(self._next, time.monotonic() + seconds)


class Bot:
    """The bot that sends, with the shared pace. call() never raises."""

    def __init__(self, token, rate=25, sleep=time.sleep):
        self.token = token
        self.limiter = RateLimiter(rate)
        self._local = threading.local()
        self._me = None
        self.sleep = sleep

    def _http(self):
        s = getattr(self._local, 'session', None)
        if s is None:
            s = self._local.session = requests.Session()
        return s

    def call(self, method, payload):
        """{'ok': True, 'result': ...} or {'ok': False, 'status', 'error', 'retry_after'?}."""
        self.limiter.acquire()
        try:
            resp = self._http().post(API.format(token=self.token, method=method), json=payload, timeout=30)
        except requests.RequestException as e:
            return {'ok': False, 'status': 0, 'error': f'network: {e.__class__.__name__}'}
        try:
            data = resp.json()
        except ValueError:
            data = {}
        if resp.status_code == 200 and data.get('ok'):
            return {'ok': True, 'result': data.get('result')}
        out = {'ok': False, 'status': data.get('error_code') or resp.status_code,
               'error': str(data.get('description') or resp.reason or '')[:300]}
        retry_after = (data.get('parameters') or {}).get('retry_after')
        if retry_after is not None:
            out['retry_after'] = float(retry_after)
        return out

    def username(self):
        """The bot's @name (asked once), or None when the token doesn't work."""
        if self._me is None:
            r = self.call('getMe', {})
            self._me = (r['result'] or {}).get('username') if r['ok'] else ''
        return self._me or None


# ============================================
# THE MESSAGE
# ============================================

def message_html(title, body_html, with_title=True):
    """The text as the bot sends it: the title as a bold first line, then the message."""
    head = f'<b>{html.escape(title, quote=False)}</b>' if with_title and title.strip() else ''
    return '\n\n'.join(p for p in (head, body_html) if p)


def visible_length(text_html):
    """What Telegram counts against its limits: the text without tags and entities."""
    return len(html.unescape(re.sub(r'<[^>]+>', '', text_html)))


def _file_ids(result):
    """The file_ids Telegram gave the photos of a sendPhoto / sendMediaGroup answer, largest size."""
    messages = result if isinstance(result, list) else [result]
    ids = []
    for m in messages:
        sizes = (m or {}).get('photo') or []
        if sizes:
            ids.append(sizes[-1].get('file_id'))
    return ids


def _classify(r):
    """A failed call -> (outcome, code)."""
    status, error = r.get('status'), (r.get('error') or '').lower()
    if status == 429:
        return 'retry', 'TG_RETRY_AFTER'
    if 'deactivated' in error:
        return 'blocked', 'TG_DELETED'          # a deleted account: never back
    if status == 403 or any(m in error for m in DEAD_CHAT_MARKERS):
        return 'blocked', 'TG_CHAT_NOT_FOUND' if 'not found' in error or 'peer_id' in error else 'TG_BLOCKED'
    if status == 0 or (isinstance(status, int) and status >= 500):
        return 'retry', 'TG_NETWORK' if status == 0 else 'TG_SERVER'
    if 'wrong file' in error or 'file_id' in error or 'wrong remote file' in error:
        return 'stale_files', 'TG_FILE'
    if 'failed to get http url content' in error or 'wrong type of the web page content' in error:
        return 'failed', 'TG_PHOTO_URL'
    if "can't parse entities" in error:
        return 'failed', 'TG_FORMAT'
    return 'failed', 'TG_BAD_REQUEST'


def send(bot, chat_id, text_html, photos, preview=False):
    """
    The message to one chat. photos: file_ids or https addresses, in order.
    A dict like FCM's in app_push.send_detailed():

        outcome    'sent' | 'blocked' | 'retry' | 'failed' | 'stale_files'
                   (the file_ids no longer work: send again with addresses)
        code, error, retry_after
        file_ids   the photos' file_ids, when this call uploaded them

    Tried here up to 3 times on network or Telegram trouble, 5 when Telegram
    asks to slow down (everyone then waits). Photos that went are not sent
    again when the text after them is retried.
    """
    photos = list(photos or [])[:ALBUM_MAX]
    caption = len(photos) > 0 and visible_length(text_html) <= CAPTION_MAX
    steps = []
    if len(photos) == 1:
        p = {'chat_id': chat_id, 'photo': photos[0]}
        if caption:
            p.update(caption=text_html, parse_mode='HTML')
        steps.append(('sendPhoto', p))
    elif photos:
        media = [{'type': 'photo', 'media': ph} for ph in photos]
        if caption:
            media[0].update(caption=text_html, parse_mode='HTML')
        steps.append(('sendMediaGroup', {'chat_id': chat_id, 'media': media}))
    if not caption:
        steps.append(('sendMessage', {'chat_id': chat_id, 'text': text_html, 'parse_mode': 'HTML',
                                      'link_preview_options': {'is_disabled': not preview}}))
    uploaded = None
    for method, payload in steps:
        network = slow = 0
        while True:
            r = bot.call(method, payload)
            if r['ok']:
                if method != 'sendMessage':
                    ids = _file_ids(r['result'])
                    # Sent from addresses: Telegram stored them; reuse its ids from now on.
                    if ids and any(str(ph).startswith(('http://', 'https://')) for ph in photos):
                        uploaded = ids
                break
            outcome, code = _classify(r)
            if code == 'TG_RETRY_AFTER':
                slow += 1
                wait = r.get('retry_after') or 5
                bot.limiter.pause(wait + 0.5)
                logger.warning(f'[TELEGRAM] 429: everyone waits {wait}s')
                if slow < SLOW_DOWN_TRIES:
                    continue
            elif outcome == 'retry':
                network += 1
                if network < NETWORK_TRIES:
                    bot.sleep(2 * network)
                    continue
            result = {'outcome': outcome, 'code': code, 'error': r.get('error')}
            if r.get('retry_after'):
                result['retry_after'] = r['retry_after']
            if uploaded:
                result['file_ids'] = uploaded
            if method == 'sendMessage' and len(steps) > 1 and outcome != 'blocked':
                # The photos are in the chat already; the text isn't.
                result['error'] = f'photos sent, text not: {result["error"]}'
            return result
    out = {'outcome': 'sent'}
    if uploaded:
        out['file_ids'] = uploaded
    return out


# ============================================
# THE LIST
# ============================================

def parse_list(raw, skipped=None):
    """
    The bot's people from a CSV like the script's user_ids_cleaned.csv:
    the id first, the username second (optional), a header row or not.
    [(id, username)], each id once, in the file's order. Ids that can't be
    Telegram users are counted in skipped: {'app': n, 'phone': n}.
    """
    text = raw.decode('utf-8-sig', errors='replace') if isinstance(raw, bytes) else str(raw)
    out, seen = [], set()
    skipped = skipped if skipped is not None else {}
    for row in csv.reader(io.StringIO(text)):
        if not row:
            continue
        first = row[0].strip()
        if not re.fullmatch(r'-?\d{1,20}', first):
            continue                      # a header, or junk
        uid = int(first)
        if uid == 0 or uid in seen:
            continue
        seen.add(uid)
        if not is_telegram_id(uid):
            why = 'app' if uid < 0 else 'phone'
            skipped[why] = skipped.get(why, 0) + 1
            continue
        name = row[1].strip().lstrip('@')[:64] if len(row) > 1 and row[1].strip() else None
        out.append((uid, name))
    return out
