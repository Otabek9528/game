"""
place_notifications_api.py
==========================
Watching places and areas, and the Telegram bot messages that follow.

Registered by places_api_protected.py as `place_notifications_bp`. The schema
and the background sender are started by init_place_notifications(app).

Mini App endpoints — signed Telegram initData in X-Init-Data, verified with
the same code as the social-link submissions:

    GET    /api/notify/me                      my areas + watched places
    POST   /api/notify/watch/<place_id>        {"lang": "uz"}
    DELETE /api/notify/watch/<place_id>
    POST   /api/notify/areas                   see _area_from_body()
    PUT    /api/notify/areas/<area_id>
    DELETE /api/notify/areas/<area_id>

    PUT    /api/notify/delivery                {"telegram", "push"}  how a Telegram
                                               user is told: the bot, the app, or both
    POST   /api/notify/hello                   {"lang"}  re-enable + a test message
    POST   /api/notify/claim/<place_id>        {"lang"}  restaurants and shops
    POST   /api/notify/announce/<place_id>     {"text", "lang"}  waits for the admin
    GET    /api/notify/announce/<place_id>/reach   how many would receive it

Signed in, limited per person (anti-scraping):
    GET    /api/places/in-radius?lat=..&lon=..   or  ?address=..
           places within 10 km of a point, for the add-area preview

Admin (session):
    GET    /api/admin/notify/reach?place_id=..[&lat=..&lon=..&type=..&event=..]
    GET    /api/admin/notify/stats
    GET    /api/admin/announcements?status=pending|approved|rejected|all
    POST   /api/admin/announcements                 {"place_id", "text"}  post now
    PUT    /api/admin/announcements/<id>            {"text"}  (pending only)
    DELETE /api/admin/announcements/<id>
    POST   /api/admin/announcements/<id>/approve    {"text"?}  sends it
    POST   /api/admin/announcements/<id>/reject
    GET    /api/admin/claims?status=pending|all
    POST   /api/admin/claims/<id>/approve | /reject
    GET    /api/admin/owners
    GET    /api/admin/notify/watch-counts           {place_id: watchers} for the place list
    GET    /api/admin/notify/places                 most-watched places
    GET    /api/admin/notify/places/<place_id>      who watches it, which areas cover it
    GET    /api/admin/notify/subscribers?q=..       people, searchable by name or ID
    GET    /api/admin/notify/subscribers/<tg_id>    one person: watches, areas, messages
    GET    /api/admin/notify/areas                  every area watch
    GET    /api/admin/notify/messages?status=..     the outbox, newest first
    PUT    /api/admin/owners/<place_id>             {"tg_id", "username"?}  assign
    DELETE /api/admin/owners/<place_id>             revoke

Used by places_api_protected.py:
    wants_notify(*values)                        was the panel's Send box ticked
    optional_user()                              signed-in user or None
    place_watch_info(conn, place_id, user)       extra fields for /api/place/<id>
    prepare_place_event(conn, kind, place, ...)  who gets what, nothing written
    enqueue_messages(messages, event_ref)        into the outbox, sender woken
    delete_place_notify_rows(conn, place_id)     cascade when a place is deleted

Why an outbox: Telegram allows roughly 30 messages a second per bot. Sending
inside the admin's save request would block it for as long as the fan-out
takes, and a Telegram hiccup would fail the save. Messages are written to
notify_outbox instead and a single background thread sends them, backing off
on 429 and switching off subscribers who blocked the bot (403).

The API runs as one process, so one sender thread is enough and needs no
locking between workers. Running it under several gunicorn workers would
send duplicates — that would need a claim column first.

Configuration (set on app.config by places_api_protected.py):
    PLACE_NOTIFY_DB              path to main_db.sqlite
    PLACE_NOTIFY_BOT_TOKEN       bot token used to send
    PLACE_NOTIFY_KAKAO_KEY       Kakao REST key, for geocoding area addresses
    PLACE_NOTIFY_WEBAPP_URL      base URL of the Mini App's places folder, e.g.
                                 https://example.com/pages/places/ — "Open
                                 place" opens places-detail.html under it;
                                 "Stop" and the welcome message open the
                                 notifications page in its sibling folder,
                                 ../notifications/notifications.html.
                                 Empty: messages go out without buttons.
    PLACE_NOTIFY_SEND_PER_SECOND default 20 (Telegram's limit is ~30)
    PLACE_NOTIFY_ADMIN_CHAT_ID   who gets the "waiting for approval" pings
                                 (default: PLACE_SUBMISSIONS_ADMIN_CHAT_ID)
    PLACE_NOTIFY_ADMIN_URL       the panel those pings link to
                                 (default: PLACE_SUBMISSIONS_ADMIN_URL)
Environment:
    PLACE_NOTIFY_DISABLE_SENDER=1  do not start the sender thread (tests)
"""

import html
import json
import logging
import os
import re
import sqlite3
import threading
import time
from collections import deque
from datetime import datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt
from urllib.parse import urljoin

import requests
from flask import Blueprint, current_app, jsonify, request, session

import app_push
from app_accounts import is_app_user, on_user_deleted, on_user_moved
from place_submissions_api import resolve_submitter, submitter_name

bp = Blueprint('place_notifications', __name__)
logger = logging.getLogger(__name__)


# ============================================
# CONSTANTS
# ============================================

DEFAULT_DB_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'

LANGS = ('uz', 'ru', 'en')
RADII_KM = (1, 3, 5, 10)
MAX_RADIUS_KM = max(RADII_KM)

# Frontend type keys <-> main_db.Building_type
TYPE_BY_BUILDING = {'Masjid': 'mosque', 'Oshxona': 'restaurant', "Do'kon": 'shop'}
BUILDING_BY_TYPE = {v: k for k, v in TYPE_BY_BUILDING.items()}
TYPE_KEYS = ('mosque', 'restaurant', 'shop')

# Not a product limit — the product has none. This only stops a script from
# filling the table through the API.
MAX_AREAS_PER_USER = 50
# Anti-scraping. The number of areas is not what matters: enough big circles
# around city addresses would cover most of Korea and turn the bot into a
# feed of every opening and change. So each person gets a budget of ground:
# all their areas together may cover at most as much as two of the largest
# circles (2 x 10 km, about 630 km2) — e.g. 8 x 5 km, 22 x 3 km or 200 x 1 km.
# Overlaps count.
AREA_BUDGET_KM2 = 2 * 3.141592653589793 * MAX_RADIUS_KM ** 2
# Creating or changing areas, per person per day, so the budget cannot be
# walked across the country one move at a time.
AREA_SAVES_PER_DAY = 10
# The add-area preview, per person: enough to try addresses and radii, not
# to sweep the map.
PREVIEWS_PER_10_MIN = 60
PREVIEW_CENTERS_PER_DAY = 30
LABEL_MAX = 120

# Sender behaviour
BATCH_SIZE = 25
MAX_ATTEMPTS = 5
RETRY_DELAYS = (30, 120, 600, 3600)          # seconds, after the 1st..4th failure
IDLE_POLL_SECONDS = 15                        # wake-up even without a nudge
# The outbox doubles as the message log in the panel. Delivered and failed
# messages older than this are deleted once a day, so the table stays small.
OUTBOX_KEEP_DAYS = 90
PRUNE_EVERY_SECONDS = 24 * 3600

# Same clock and text format as place_submissions_api: KST, sortable as TEXT.
KST = timezone(timedelta(hours=9))
TS_FORMAT = '%Y-%m-%d %H:%M:%S'


# ============================================
# BOT TEXT
# ============================================
# Mirrors the "bot" and "admin" sections (and areas.currentLocation) of
# pages/places/places.text.js in the frontend repo, which is where the words
# are reviewed. This server cannot read that file, so the two must be edited
# together.

BOT_TEXT = {
    "newMosque":          {"uz": "Yangi masjid ochildi",
                           "ru": "Открылась новая мечеть",
                           "en": "New mosque opened"},
    "newRestaurant":      {"uz": "Yangi oshxona ochildi",
                           "ru": "Открылся новый ресторан",
                           "en": "New restaurant opened"},
    "newShop":            {"uz": "Yangi do‘kon ochildi",
                           "ru": "Открылся новый магазин",
                           "en": "New shop opened"},
    "phoneChanged":       {"uz": "Telefon raqami o‘zgardi",
                           "ru": "Изменился номер телефона",
                           "en": "Phone number changed"},
    "nameChanged":        {"uz": "Nomi o‘zgardi",
                           "ru": "Изменилось название",
                           "en": "Name changed"},
    "closed":             {"uz": "Joy yopildi",
                           "ru": "Место закрылось",
                           "en": "Place closed"},
    "closedBody":         {"uz": "{name} endi ishlamaydi.",
                           "ru": "{name} больше не работает.",
                           "en": "{name} is no longer open."},
    "removedFromList":    {"uz": "Kuzatuv ro‘yxatingizdan olib tashlandi.",
                           "ru": "Удалено из ваших отслеживаемых мест.",
                           "en": "It has been removed from your watched places."},
    "whyArea":            {"uz": "Hududingiz: {area} · {km} km",
                           "ru": "Ваш район: {area} · {km} км",
                           "en": "Your area: {area} · {km} km"},
    "whyPlace":           {"uz": "Siz bu joyni kuzatyapsiz",
                           "ru": "Вы следите за этим местом",
                           "en": "You’re watching this place"},
    "announcement":       {"uz": "{name} · e’lon",
                           "ru": "{name} · объявление",
                           "en": "{name} · announcement"},
    "fromOwner":          {"uz": "Joy egasidan",
                           "ru": "От владельца",
                           "en": "From the owner"},
    "btnOpen":            {"uz": "Joyni ochish",
                           "ru": "Открыть",
                           "en": "Open place"},
    "btnStop":            {"uz": "To‘xtatish",
                           "ru": "Отключить",
                           "en": "Stop"},
    "btnSettings":        {"uz": "Bildirishnomalar",
                           "ru": "Уведомления",
                           "en": "Notifications"},
    "welcomeTitle":       {"uz": "Bildirishnomalar yoqildi",
                           "ru": "Уведомления включены",
                           "en": "Notifications are on"},
    "welcomeBody":        {"uz": "Kuzatayotgan joylaringiz va hududlaringiz bo‘yicha yangiliklar shu yerga keladi.",
                           "ru": "Новости о местах и районах, за которыми вы следите, будут приходить сюда.",
                           "en": "News about the places and areas you watch will arrive here."},
    "stoppedArea":        {"uz": "Bu hudud bo‘yicha xabarlar to‘xtatildi.",
                           "ru": "Сообщения по этому району отключены.",
                           "en": "Messages for this area are off."},
    "stoppedPlace":       {"uz": "Bu joy bo‘yicha xabarlar to‘xtatildi.",
                           "ru": "Сообщения по этому месту отключены.",
                           "en": "Messages for this place are off."},
    "approved":           {"uz": "E’loningiz tasdiqlandi va {n} kishiga yuborildi.",
                           "ru": "Ваше объявление одобрено и отправлено {n} людям.",
                           "en": "Your announcement was approved and sent to {n} people."},
    "rejected":           {"uz": "E’loningiz rad etildi. Savollar bo‘lsa, administratorga yozing.",
                           "ru": "Ваше объявление отклонено. Если есть вопросы, напишите администратору.",
                           "en": "Your announcement was declined. Message the admin if you have questions."},
    "claimApproved":      {"uz": "Siz {name} egasi sifatida tasdiqlandingiz.",
                           "ru": "Вы подтверждены как владелец «{name}».",
                           "en": "You’re now confirmed as the owner of {name}."},
    "claimRejected":      {"uz": "{name} egaligi bo‘yicha so‘rovingiz tasdiqlanmadi. Savollar bo‘lsa, administratorga yozing.",
                           "ru": "Ваш запрос на владение «{name}» не подтверждён. Если есть вопросы, напишите администратору.",
                           "en": "Your ownership request for {name} wasn’t approved. Message the admin if you have questions."},
    "admin_pendingPost":  {"uz": "Yangi e’lon tasdiqlashni kutmoqda",
                           "ru": "Новое объявление ждёт проверки",
                           "en": "New announcement awaiting approval"},
    "admin_pendingClaim": {"uz": "Yangi egalik so‘rovi",
                           "ru": "Новый запрос на владение",
                           "en": "New ownership request"},
    "admin_last7":        {"uz": "Oxirgi 7 kunda: {n} ta e’lon",
                           "ru": "За 7 дней: {n} объявл.",
                           "en": "Last 7 days: {n} posts"},
    "admin_openPanel":    {"uz": "Admin panelda ochish",
                           "ru": "Открыть в админке",
                           "en": "Open in admin panel"},
    "admin_roleOwner":    {"uz": "ega",
                           "ru": "владелец",
                           "en": "owner"},
    "currentLocation":    {"uz": "Joriy joylashuvim",
                           "ru": "Моё местоположение",
                           "en": "My current location"},
}


def _raw(lang, key):
    """Bot text in `lang` as plain text (for button labels and values)."""
    node = BOT_TEXT[key]
    return node.get(lang) or node['uz']


def _t(lang, key, **values):
    """Bot text in `lang`, HTML-escaped, with escaped values filled in."""
    s = html.escape(_raw(lang, key), quote=False)
    for k, v in values.items():
        s = s.replace('{' + k + '}', html.escape(str(v), quote=False))
    return s


# ============================================
# SMALL HELPERS
# ============================================

def _cfg(key, default=None):
    try:
        return current_app.config.get(key, default)
    except RuntimeError:      # outside an app context
        return default


def _db(path=None):
    # timeout: the sender thread and request threads share one SQLite file;
    # wait for a lock rather than failing with "database is locked".
    conn = sqlite3.connect(path or _cfg('PLACE_NOTIFY_DB', DEFAULT_DB_PATH), timeout=10)
    conn.row_factory = sqlite3.Row
    return conn


def _q(conn, sql, args=()):
    """Query with named-column rows, whatever row_factory the caller's connection uses."""
    cur = conn.cursor()
    cur.row_factory = sqlite3.Row
    return cur.execute(sql, args)


def _now():
    return datetime.now(KST)


def _fmt(dt):
    return dt.strftime(TS_FORMAT)


def _err(code, message, status=400, **extra):
    payload = {'success': False, 'code': code, 'error': message}
    payload.update(extra)
    return jsonify(payload), status


def haversine(lat1, lon1, lat2, lon2):
    """Distance in km. Same formula as places_api_protected.haversine."""
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    a = sin((lat2 - lat1) / 2) ** 2 + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2
    return 2 * asin(sqrt(a)) * 6371


def _bbox(lat, lon, km):
    """Lat/lon box around a point, for a cheap SQL prefilter before haversine."""
    dlat = km / 111.0
    dlon = km / (111.0 * max(cos(radians(lat)), 0.01))
    return lat - dlat, lat + dlat, lon - dlon, lon + dlon


def _lang(value):
    return value if value in LANGS else 'uz'


def _truthy(v):
    return str(v).strip().lower() in ('1', 'true', 'yes', 'on')


def wants_notify(*values):
    """True when any of the given request values is a Send tick (1/true/yes/on)."""
    return any(_truthy(v) for v in values if v is not None)


def _clean_label(v):
    v = ' '.join(str(v or '').split())
    return v[:LABEL_MAX] or None


# Per-IP rate limit for the endpoints that cost a geocoder call or scan the
# place table. In-memory, like the Flask-Limiter setup in the main file.
_rate_lock = threading.Lock()
_rate_hits = {}


def _rate_ok(bucket, limit, per_seconds, who=None):
    """Sliding-window limit per IP, or per `who` (a Telegram user id) when given.
    The IP comes from X-Forwarded-For, which a client can fake; limits that
    must hold against scrapers are keyed by the signed-in user instead."""
    if who is None:
        who = request.headers.get('X-Forwarded-For', request.remote_addr or '?').split(',')[0].strip()
    key = (bucket, who)
    now = time.time()
    with _rate_lock:
        q = _rate_hits.setdefault(key, deque())
        while q and now - q[0] > per_seconds:
            q.popleft()
        if len(q) >= limit:
            return False
        q.append(now)
        return True


# ============================================
# SCHEMA
# ============================================

SCHEMA = """
CREATE TABLE IF NOT EXISTS notify_subscribers (
    tg_id       INTEGER PRIMARY KEY,
    username    TEXT,
    lang        TEXT NOT NULL DEFAULT 'uz',
    active      INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL,
    blocked_at  TEXT
);

CREATE TABLE IF NOT EXISTS place_watches (
    tg_id       INTEGER NOT NULL,
    place_id    INTEGER NOT NULL,
    created_at  TEXT NOT NULL,
    PRIMARY KEY (tg_id, place_id)
);
CREATE INDEX IF NOT EXISTS idx_place_watches_place ON place_watches (place_id);

CREATE TABLE IF NOT EXISTS area_watches (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    tg_id       INTEGER NOT NULL,
    source      TEXT NOT NULL CHECK (source IN ('location', 'address')),
    label       TEXT,
    lat         REAL NOT NULL,
    lon         REAL NOT NULL,
    radius_km   INTEGER NOT NULL CHECK (radius_km IN (1, 3, 5, 10)),
    types       TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_area_watches_tg ON area_watches (tg_id);
CREATE INDEX IF NOT EXISTS idx_area_watches_pos ON area_watches (lat, lon);

-- Phase 4 (owners, claims, announcements). Created now so the delete
-- cascade and the detail endpoint already know about them.
CREATE TABLE IF NOT EXISTS place_owners (
    place_id    INTEGER PRIMARY KEY,
    tg_id       INTEGER NOT NULL,
    username    TEXT,
    approved_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS owner_claims (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id    INTEGER NOT NULL,
    tg_id       INTEGER NOT NULL,
    username    TEXT,
    status      TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at  TEXT NOT NULL,
    reviewed_at TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_owner_claims_pending
    ON owner_claims (place_id, tg_id) WHERE status = 'pending';

CREATE TABLE IF NOT EXISTS announcements (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id        INTEGER NOT NULL,
    author_tg_id    INTEGER,
    author_username TEXT,
    author_role     TEXT NOT NULL CHECK (author_role IN ('owner', 'public', 'admin')),
    text            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at      TEXT NOT NULL,
    reviewed_at     TEXT,
    sent_at         TEXT,
    recipients      INTEGER
);
CREATE INDEX IF NOT EXISTS idx_announcements_place ON announcements (place_id, status);

CREATE TABLE IF NOT EXISTS notify_outbox (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    tg_id           INTEGER NOT NULL,
    text            TEXT NOT NULL,
    buttons         TEXT,
    status          TEXT NOT NULL DEFAULT 'queued'
                    CHECK (status IN ('queued', 'sent', 'failed')),
    attempts        INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TEXT NOT NULL,
    event_ref       TEXT,
    created_at      TEXT NOT NULL,
    sent_at         TEXT,
    error           TEXT
);
CREATE INDEX IF NOT EXISTS idx_outbox_due ON notify_outbox (status, next_attempt_at);
"""


def _migrate_area_radii(conn):
    """
    The radii were 5/10/15/20 km and are 1/3/5/10 km. The table's CHECK only
    allowed the old ones, and SQLite cannot change a CHECK in place, so the
    table is rebuilt once: same rows and ids, 15 and 20 km areas become 10 km.
    """
    row = conn.execute("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'area_watches'").fetchone()
    old_sql = row[0] if row else ''
    if '(5, 10, 15, 20)' not in old_sql:
        return
    new_sql = old_sql.replace('(5, 10, 15, 20)', '(1, 3, 5, 10)').replace(
        'area_watches', 'area_watches_new', 1)
    seq = conn.execute("SELECT seq FROM sqlite_sequence WHERE name = 'area_watches'").fetchone()
    cols = 'id, tg_id, source, label, lat, lon, radius_km, types, created_at, updated_at'
    try:
        conn.execute('BEGIN')
        conn.execute(new_sql)
        conn.execute(f"INSERT INTO area_watches_new ({cols}) SELECT id, tg_id, source, label, lat, lon, "
                     f"MIN(radius_km, {MAX_RADIUS_KM}), types, created_at, updated_at FROM area_watches")
        shrunk = conn.execute(f"SELECT COUNT(*) FROM area_watches WHERE radius_km > {MAX_RADIUS_KM}").fetchone()[0]
        conn.execute("DROP TABLE area_watches")
        conn.execute("ALTER TABLE area_watches_new RENAME TO area_watches")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_area_watches_tg ON area_watches (tg_id)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_area_watches_pos ON area_watches (lat, lon)")
        if seq:
            # Ids of deleted areas are not handed out again.
            conn.execute("UPDATE sqlite_sequence SET seq = MAX(seq, ?) WHERE name = 'area_watches'", (seq[0],))
        conn.execute('COMMIT')
        logger.info(f'[NOTIFY] area radii are now {RADII_KM} km; {shrunk} larger area(s) set to {MAX_RADIUS_KM} km')
    except Exception:
        conn.execute('ROLLBACK')
        raise


def init_schema(path):
    conn = _db(path)
    try:
        conn.executescript(SCHEMA)
        # Added after the first release: when the one-time welcome went out.
        cols = {r[1] for r in conn.execute("PRAGMA table_info(notify_subscribers)")}
        if 'welcomed_at' not in cols:
            conn.execute("ALTER TABLE notify_subscribers ADD COLUMN welcomed_at TEXT")
        # Added with the app: a Telegram user's choice of the bot, the app, or both.
        if 'via_telegram' not in cols:
            conn.execute("ALTER TABLE notify_subscribers ADD COLUMN via_telegram INTEGER NOT NULL DEFAULT 1")
        if 'via_push' not in cols:
            conn.execute("ALTER TABLE notify_subscribers ADD COLUMN via_push INTEGER NOT NULL DEFAULT 1")
        # Added with the app: when the message also went to the person's phones.
        cols = {r[1] for r in conn.execute("PRAGMA table_info(notify_outbox)")}
        if 'pushed_at' not in cols:
            conn.execute("ALTER TABLE notify_outbox ADD COLUMN pushed_at TEXT")
        # Areas' counts, the area preview and who hears of a place all read
        # main_db by position; without this each of them reads every row.
        try:
            conn.execute("CREATE INDEX IF NOT EXISTS idx_main_db_lat_lon ON main_db (Latitude, Longitude)")
        except sqlite3.OperationalError:
            pass   # no main_db here (tests of the outbox alone)
        conn.commit()
        _migrate_area_radii(conn)
    finally:
        conn.close()


# ============================================
# IDENTITY
# ============================================

def optional_user():
    """
    The user when the request carries valid initData or an app token, else
    None. An app user who has not signed in counts: they can watch places.
    """
    if not request.headers.get('X-Init-Data') and not request.headers.get('Authorization'):
        return None
    user, err = resolve_submitter(allow_anonymous=True)
    return None if err else user


def _require_user(allow_anonymous=False):
    """
    (user, None) or (None, error_response). allow_anonymous: an app user who
    has not signed in will do (watches and areas only reach the person
    themselves; claims and announcements reach others, so they need a name).
    """
    user, err = resolve_submitter(allow_anonymous=allow_anonymous)
    if err:
        code, message = err
        return None, _err(code, message, 503 if code == 'server_misconfigured' else 401)
    return user, None


def _upsert_subscriber(conn, user, lang):
    """Create or refresh the subscriber; opening the app again re-activates someone the sender switched off."""
    now = _fmt(_now())
    name = submitter_name(user)
    cur = conn.execute(
        "UPDATE notify_subscribers SET username = ?, lang = ?, active = 1, "
        "blocked_at = NULL, updated_at = ? WHERE tg_id = ?",
        (name, _lang(lang), now, int(user['id'])))
    if cur.rowcount == 0:
        conn.execute(
            "INSERT INTO notify_subscribers (tg_id, username, lang, active, created_at, updated_at) "
            "VALUES (?, ?, ?, 1, ?, ?)",
            (int(user['id']), name, _lang(lang), now, now))


def _notifications_page(base):
    """
    The notifications page has its own folder next to the places folder:
    https://x/pages/places/ -> https://x/pages/notifications/notifications.html
    (pages/places/notifications.html still forwards there, for old messages).
    """
    return urljoin(base, '../notifications/notifications.html')


def _welcome_message(lang):
    """'Notifications are on' — also proves the bot can reach this person."""
    text = f"<b>{_t(lang, 'welcomeTitle')}</b>\n{_t(lang, 'welcomeBody')}"
    base = (_cfg('PLACE_NOTIFY_WEBAPP_URL') or '').strip()
    buttons = None
    if base.startswith('https://'):
        if not base.endswith('/'):
            base += '/'
        buttons = {'inline_keyboard': [[{'text': _raw(lang, 'btnSettings'),
                                         'web_app': {'url': _notifications_page(base)}}]]}
    return {'text': text, 'buttons': buttons}


def _take_welcome(conn, tg_id):
    """The welcome message for someone's first subscription, once; else None."""
    cur = conn.execute("UPDATE notify_subscribers SET welcomed_at = ? WHERE tg_id = ? AND welcomed_at IS NULL",
                       (_fmt(_now()), int(tg_id)))
    if cur.rowcount == 0:
        return None
    return {'tg_id': int(tg_id), **_welcome_message(_sub_lang(conn, tg_id))}


# ============================================
# PLACES AROUND A POINT
# ============================================

def _place_rows_near(conn, lat, lon, km):
    lo_lat, hi_lat, lo_lon, hi_lon = _bbox(lat, lon, km)
    rows = _q(conn,
        "SELECT Unique_number, Building_type, Latitude, Longitude FROM main_db "
        "WHERE Latitude BETWEEN ? AND ? AND Longitude BETWEEN ? AND ?",
        (lo_lat, hi_lat, lo_lon, hi_lon)).fetchall()
    out = []
    for r in rows:
        t = TYPE_BY_BUILDING.get(r['Building_type'])
        if not t or r['Latitude'] is None or r['Longitude'] is None:
            continue
        d = haversine(lat, lon, r['Latitude'], r['Longitude'])
        if d <= km:
            out.append((d, t, r))
    return out


def _counts(conn, lat, lon, km, types=TYPE_KEYS):
    counts = {t: 0 for t in TYPE_KEYS}
    for _, t, _ in _place_rows_near(conn, lat, lon, km):
        counts[t] += 1
    return counts, sum(counts[t] for t in types)


# ============================================
# GEOCODING  (same order as /api/places/by-address: Kakao, then Nominatim)
# ============================================

class NotExact(Exception):
    """The address names a city, district or road, not one building."""


def geocode(address, exact=False):
    """
    (lat, lon, label) or None. exact=True accepts only an address of one
    building or lot — a road address with its number (회기로 56) or a lot
    address (회기동 1-5) — and raises NotExact for a city, district,
    neighbourhood or a road on its own (대구시, 동대문구, 회기동, 회기로).
    """
    key = _cfg('PLACE_NOTIFY_KAKAO_KEY')
    if key:
        try:
            r = requests.get('https://dapi.kakao.com/v2/local/search/address.json',
                             headers={'Authorization': f'KakaoAK {key}'},
                             params={'query': address}, timeout=5).json()
            docs = r.get('documents') or []
            if docs:
                d = docs[0]
                # Kakao says what it matched: REGION / ROAD (an area or a whole
                # road) or REGION_ADDR / ROAD_ADDR (one numbered address).
                if exact and d.get('address_type') not in ('ROAD_ADDR', 'REGION_ADDR'):
                    raise NotExact()
                road = d.get('road_address') or {}
                label = (road.get('address_name') if d.get('address_type') == 'ROAD_ADDR' else None) \
                    or d.get('address_name') or address
                return float(d['y']), float(d['x']), label
            if 'documents' in r:
                return None      # Kakao answered: no such address
        except NotExact:
            raise
        except Exception as e:
            logger.warning(f'Kakao geocode failed: {e}')
    try:
        r = requests.get('https://nominatim.openstreetmap.org/search',
                         params={'q': address, 'format': 'json', 'limit': 1, 'countrycodes': 'kr',
                                 'addressdetails': 1},
                         headers={'User-Agent': 'MuslimVegukinBot/1.0'}, timeout=5).json()
        if r:
            if exact and not (r[0].get('address') or {}).get('house_number'):
                raise NotExact()
            return float(r[0]['lat']), float(r[0]['lon']), address
    except NotExact:
        raise
    except Exception as e:
        logger.warning(f'Nominatim geocode failed: {e}')
    return None


def _geocode_exact_or_error(address):
    """(lat, lon, label), or raises ValueError(code, message) for the API."""
    try:
        found = geocode(address, exact=True)
    except NotExact:
        raise ValueError('address_not_exact',
                         'Enter a full address with the building number, e.g. 서울 동대문구 회기로 56.')
    if not found:
        raise ValueError('address_not_found', 'That address could not be found.')
    return found


_preview_centers = {}      # tg_id -> (day, {rounded centre, ...})


def _preview_center_ok(uid, lat, lon):
    """At most PREVIEW_CENTERS_PER_DAY different centres (~1 km apart) per
    person per day; looking at the same spot again is free."""
    day = time.strftime('%Y-%m-%d')
    spot = (round(lat, 2), round(lon, 2))
    with _rate_lock:
        d, spots = _preview_centers.get(uid, (day, set()))
        if d != day:
            spots = set()
        if spot not in spots:
            if len(spots) >= PREVIEW_CENTERS_PER_DAY:
                return False
            spots.add(spot)
        _preview_centers[uid] = (day, spots)
        return True


def _area_km2(radius_km):
    return 3.141592653589793 * radius_km ** 2


def _check_area_budget(conn, uid, radius_km, except_id=None):
    """Raises ValueError('area_budget') when this area would take the person's
    areas past AREA_BUDGET_KM2. Editing an area without enlarging it is always
    allowed, so areas saved before the budget existed stay editable."""
    rows = conn.execute("SELECT id, radius_km FROM area_watches WHERE tg_id = ?", (uid,)).fetchall()
    used = sum(_area_km2(r['radius_km']) for r in rows if r['id'] != except_id)
    current = next((r['radius_km'] for r in rows if r['id'] == except_id), None)
    if current is not None and radius_km <= current:
        return
    if used + _area_km2(radius_km) > AREA_BUDGET_KM2 + 1e-6:
        raise ValueError('area_budget', 'Your areas would cover too much ground. '
                                        'Make one smaller or delete one first.')


# ============================================
# DETAIL-PAGE INFO
# ============================================

def place_watch_info(conn, place_id, user=None):
    """
    Extra fields for /api/place/<id>. The watcher count is public; the rest is
    about the signed-in user and stays false without one. Never raises — a
    missing table (init not run yet) must not take the detail page down.
    """
    info = {'watchCount': 0, 'watching': False, 'hasOwner': False, 'isOwner': False,
            'claimPending': False, 'pendingAnnouncements': 0}
    try:
        info['watchCount'] = conn.execute(
            "SELECT COUNT(*) FROM place_watches w JOIN notify_subscribers s "
            "ON s.tg_id = w.tg_id AND s.active = 1 WHERE w.place_id = ?",
            (place_id,)).fetchone()[0]
        owner = conn.execute("SELECT tg_id FROM place_owners WHERE place_id = ?",
                             (place_id,)).fetchone()
        info['hasOwner'] = owner is not None
        if user and user.get('id'):
            uid = int(user['id'])
            info['watching'] = conn.execute(
                "SELECT 1 FROM place_watches WHERE place_id = ? AND tg_id = ?",
                (place_id, uid)).fetchone() is not None
            info['isOwner'] = owner is not None and int(owner[0]) == uid
            info['claimPending'] = conn.execute(
                "SELECT 1 FROM owner_claims WHERE place_id = ? AND tg_id = ? AND status = 'pending'",
                (place_id, uid)).fetchone() is not None
            info['pendingAnnouncements'] = conn.execute(
                "SELECT COUNT(*) FROM announcements WHERE place_id = ? AND author_tg_id = ? "
                "AND status = 'pending'", (place_id, uid)).fetchone()[0]
    except sqlite3.Error as e:
        logger.warning(f'place_watch_info({place_id}) failed: {e}')
    return info


def _watch_count(conn, place_id):
    return conn.execute(
        "SELECT COUNT(*) FROM place_watches w JOIN notify_subscribers s "
        "ON s.tg_id = w.tg_id AND s.active = 1 WHERE w.place_id = ?",
        (place_id,)).fetchone()[0]


# ============================================
# WHO GETS A MESSAGE
# ============================================

def resolve_recipients(conn, place_id, lat, lon, type_key, include_place_watchers=True):
    """
    {tg_id: {'lang', 'kind': 'place'|'area', 'area': row|None}} for one event.

    Place watchers first, then area watchers whose circle contains the place
    and who ticked its type. A person matched more than once gets one entry:
    the place watch wins over an area, and the oldest matching area wins over
    the others, so the "why" line is stable.
    """
    rec = {}
    if include_place_watchers and place_id is not None:
        for r in _q(conn,
                "SELECT s.tg_id, s.lang FROM place_watches w JOIN notify_subscribers s "
                "ON s.tg_id = w.tg_id AND s.active = 1 WHERE w.place_id = ?", (place_id,)):
            rec[int(r['tg_id'])] = {'lang': _lang(r['lang']), 'kind': 'place', 'area': None}

    if lat is None or lon is None or not type_key:
        return rec
    lo_lat, hi_lat, lo_lon, hi_lon = _bbox(lat, lon, MAX_RADIUS_KM)
    for a in _q(conn,
            "SELECT a.*, s.lang FROM area_watches a JOIN notify_subscribers s "
            "ON s.tg_id = a.tg_id AND s.active = 1 "
            "WHERE a.lat BETWEEN ? AND ? AND a.lon BETWEEN ? AND ? ORDER BY a.id",
            (lo_lat, hi_lat, lo_lon, hi_lon)):
        uid = int(a['tg_id'])
        if uid in rec:
            continue
        if type_key not in (a['types'] or '').split(','):
            continue
        if haversine(a['lat'], a['lon'], lat, lon) > a['radius_km']:
            continue
        rec[uid] = {'lang': _lang(a['lang']), 'kind': 'area', 'area': dict(a)}
    return rec


def _why(lang, r, kind):
    """The grey last line: why this person got the message."""
    if r['kind'] == 'place':
        return _t(lang, 'removedFromList' if kind == 'closed' else 'whyPlace')
    a = r['area']
    area = a['label'] if a['source'] == 'address' and a['label'] else _raw(lang, 'currentLocation')
    return _t(lang, 'whyArea', area=area, km=a['radius_km'])


def _diff_line(old, new):
    old = html.escape(str(old)) if old else '—'
    new = html.escape(str(new)) if new else '—'
    return f'<s>{old}</s> → {new}'


def _render(kind, lang, place, changes, r):
    name = html.escape(place.get('name') or '')
    address = html.escape(place.get('address') or '')
    lines = []
    if kind == 'new':
        title_key = {'mosque': 'newMosque', 'restaurant': 'newRestaurant', 'shop': 'newShop'}[place['type_key']]
        lines += [f"<b>{_t(lang, title_key)}</b>", name]
        if address:
            lines.append(address)
    elif kind == 'changed':
        ch = {c[0]: c for c in changes}
        if 'name' in ch:
            lines += [f"<b>{_t(lang, 'nameChanged')}</b>", _diff_line(ch['name'][1], ch['name'][2])]
        if 'phone' in ch:
            lines.append(f"<b>{_t(lang, 'phoneChanged')}</b>")
            if 'name' not in ch:
                lines.append(name)
            lines.append(_diff_line(ch['phone'][1], ch['phone'][2]))
        if 'name' in ch and address:
            lines.append(address)
    elif kind == 'closed':
        lines += [f"<b>{_t(lang, 'closed')}</b>", _t(lang, 'closedBody', name=place.get('name') or '')]
    lines.append(f"<i>{_why(lang, r, kind)}</i>")
    return '\n'.join(lines)


def _buttons(kind, lang, place, r):
    """Inline keyboard of web_app buttons, or None. A closed place gets none."""
    base = (_cfg('PLACE_NOTIFY_WEBAPP_URL') or '').strip()
    if kind == 'closed' or not base.startswith('https://'):
        return None
    if not base.endswith('/'):
        base += '/'
    open_url = f"{base}places-detail.html?type={place['type_key']}&id={place['id']}"
    stop = f"place:{place['id']}" if r['kind'] == 'place' else f"area:{r['area']['id']}"
    stop_url = f"{_notifications_page(base)}?stop={stop}"
    return {'inline_keyboard': [[
        {'text': _raw(lang, 'btnOpen'), 'web_app': {'url': open_url}},
        {'text': _raw(lang, 'btnStop'), 'web_app': {'url': stop_url}},
    ]]}


def place_from_row(row):
    """main_db row (sqlite3.Row or dict) -> the place dict the event code uses."""
    row = dict(row)
    return {
        'id': row.get('Unique_number'),
        'name': row.get('Name'),
        'address': row.get('Actual_address'),
        'phone': row.get('Tel'),
        'building_type': row.get('Building_type'),
        'type_key': TYPE_BY_BUILDING.get(row.get('Building_type')),
        'lat': row.get('Latitude'),
        'lon': row.get('Longitude'),
    }


def _place_point(place):
    """(lat, lon) of a place dict, or (None, None) when it has no usable coordinates."""
    try:
        lat = float(place['lat']) if place.get('lat') not in (None, '') else None
        lon = float(place['lon']) if place.get('lon') not in (None, '') else None
    except (TypeError, ValueError):
        lat = lon = None
    if lat == 0 and lon == 0:          # the panel saves 0,0 when coords are blank
        lat = lon = None
    return lat, lon


def tracked_changes(old_row, new_row):
    """[(field, old, new)] for the fields that may notify: name and phone."""
    changes = []
    for field, col in (('name', 'Name'), ('phone', 'Tel')):
        a = (dict(old_row).get(col) or '').strip()
        b = (dict(new_row).get(col) or '').strip()
        if a != b:
            changes.append((field, a, b))
    return changes


def prepare_place_event(conn, kind, place, changes=None):
    """
    Messages for one event — nothing is written.

    kind: 'new' (area watchers only; nobody can watch a place that did not
    exist), 'changed' (needs `changes`), 'closed'. Call it BEFORE deleting a
    place: the delete cascade removes the watchers it needs to find.
    """
    if kind not in ('new', 'changed', 'closed'):
        raise ValueError(kind)
    if kind == 'changed' and not changes:
        return []
    if not place.get('type_key'):
        return []
    lat, lon = _place_point(place)
    recipients = resolve_recipients(conn, place.get('id'), lat, lon, place['type_key'],
                                    include_place_watchers=(kind != 'new'))
    return [{'tg_id': uid,
             'text': _render(kind, r['lang'], place, changes or [], r),
             'buttons': _buttons(kind, r['lang'], place, r)}
            for uid, r in recipients.items()]


# ============================================
# OUTBOX
# ============================================

_wake = threading.Event()


def enqueue_messages(messages, event_ref, path=None):
    """Write messages to the outbox on its own connection and wake the sender."""
    if not messages:
        return 0
    now = _fmt(_now())
    conn = _db(path)
    try:
        conn.executemany(
            "INSERT INTO notify_outbox (tg_id, text, buttons, status, attempts, "
            "next_attempt_at, event_ref, created_at) VALUES (?, ?, ?, 'queued', 0, ?, ?, ?)",
            [(m['tg_id'], m['text'], json.dumps(m['buttons'], ensure_ascii=False) if m.get('buttons') else None,
              now, event_ref, now) for m in messages])
        conn.commit()
    finally:
        conn.close()
    _wake.set()
    logger.info(f'[NOTIFY] queued {len(messages)} message(s) for {event_ref}')
    return len(messages)


def delete_place_notify_rows(conn, place_id):
    """
    Remove everything keyed by this place. Runs inside the caller's delete
    transaction: Unique_number is reused (the panel assigns max+1), so leftover
    rows would hand this place's watchers and owner to a future place.
    Already-queued outbox messages are left to go out.
    """
    counts = {}
    for table, col in (('place_watches', 'place_id'), ('place_owners', 'place_id'),
                       ('owner_claims', 'place_id'), ('announcements', 'place_id')):
        try:
            counts[table] = conn.execute(f"DELETE FROM {table} WHERE {col} = ?", (place_id,)).rowcount
        except sqlite3.OperationalError:
            counts[table] = 0          # init not run yet
    return counts


# ============================================
# SENDER
# ============================================

def _send_one(token, tg_id, text, buttons):
    """(outcome, detail): outcome is 'sent' | 'retry' | 'blocked' | 'failed'; detail is retry_after or error text."""
    payload = {'chat_id': tg_id, 'text': text, 'parse_mode': 'HTML',
               'disable_web_page_preview': True}
    if buttons:
        payload['reply_markup'] = buttons
    try:
        resp = requests.post(f'https://api.telegram.org/bot{token}/sendMessage',
                             json=payload, timeout=15)
    except Exception as e:
        return 'retry', None, f'network: {e}'
    try:
        data = resp.json()
    except ValueError:
        data = {}
    if resp.status_code == 200 and data.get('ok'):
        return 'sent', None, None
    desc = str(data.get('description') or resp.text)[:300]
    if resp.status_code == 429:
        retry_after = int((data.get('parameters') or {}).get('retry_after') or 5)
        return 'retry', retry_after, desc
    # 403: blocked the bot / deactivated / never started it.
    # 400 "chat not found" is the same thing from our side.
    if resp.status_code == 403 or (resp.status_code == 400 and 'chat not found' in desc.lower()):
        return 'blocked', None, desc
    if resp.status_code >= 500:
        return 'retry', None, desc
    return 'failed', None, desc


def _delivery(conn, tg_id):
    """(telegram, push): how this person wants to be told. App-only accounts
    have no Telegram; a Telegram user has both until they choose."""
    if is_app_user(tg_id):
        return False, True
    try:
        r = conn.execute("SELECT via_telegram, via_push FROM notify_subscribers WHERE tg_id = ?",
                         (tg_id,)).fetchone()
    except sqlite3.OperationalError:
        r = None
    return (True, True) if r is None else (bool(r[0]), bool(r[1]))


def _deliver(conn, token, row, buttons):
    """
    One outbox message, as _send_one() reports it. Someone with only the app
    (a negative id) gets a push; a Telegram user gets what they chose: the
    Telegram message, a push (once) to each phone signed in with that Telegram
    account, or both. Push only but no phone took it: the bot after all,
    rather than nothing.
    """
    if is_app_user(row['tg_id']):
        sent, phones = app_push.push_html(row['tg_id'], row['text'], buttons)
        if sent:
            return 'sent', None, None
        if not phones:
            # Not 'blocked': notifications may be allowed on the phone later.
            return 'failed', None, 'no phone to push to'
        return 'retry', None, 'push failed'
    via_telegram, via_push = _delivery(conn, row['tg_id'])
    pushed = row['pushed_at'] is not None
    if via_push and not pushed and app_push.push_html(row['tg_id'], row['text'], buttons)[0]:
        conn.execute("UPDATE notify_outbox SET pushed_at = ? WHERE id = ?", (_fmt(_now()), row['id']))
        pushed = True
    if not via_telegram and pushed:
        return 'sent', None, None
    outcome, retry_after, detail = _send_one(token, row['tg_id'], row['text'], buttons)
    if outcome == 'blocked' and pushed:
        # The bot can't reach them, the app can: they still hear about it.
        return 'sent', None, None
    return outcome, retry_after, detail


def process_outbox_once(path=None, token=None, per_second=None, sleep=time.sleep):
    """
    Send one batch of due messages. Returns the number of messages handled.
    Split out from the thread so it can be tested and called by hand.
    """
    token = token or _cfg('PLACE_NOTIFY_BOT_TOKEN')
    per_second = per_second or _cfg('PLACE_NOTIFY_SEND_PER_SECOND', 20) or 20
    if not token:
        logger.error('[NOTIFY] no bot token configured; outbox not sent')
        return 0
    conn = _db(path)
    handled = 0
    try:
        now = _now()
        rows = conn.execute(
            "SELECT id, tg_id, text, buttons, attempts, pushed_at FROM notify_outbox "
            "WHERE status = 'queued' AND next_attempt_at <= ? ORDER BY id LIMIT ?",
            (_fmt(now), BATCH_SIZE)).fetchall()
        for row in rows:
            buttons = json.loads(row['buttons']) if row['buttons'] else None
            outcome, retry_after, detail = _deliver(conn, token, row, buttons)
            stamp = _fmt(_now())
            if outcome == 'sent':
                conn.execute("UPDATE notify_outbox SET status = 'sent', sent_at = ?, "
                             "attempts = attempts + 1, error = NULL WHERE id = ?", (stamp, row['id']))
            elif outcome == 'blocked':
                conn.execute("UPDATE notify_outbox SET status = 'failed', attempts = attempts + 1, "
                             "error = ? WHERE id = ?", (detail, row['id']))
                conn.execute("UPDATE notify_subscribers SET active = 0, blocked_at = ? "
                             "WHERE tg_id = ?", (stamp, row['tg_id']))
                # Nothing else queued for them will get through either.
                conn.execute("UPDATE notify_outbox SET status = 'failed', error = 'subscriber inactive' "
                             "WHERE tg_id = ? AND status = 'queued'", (row['tg_id'],))
            elif outcome == 'retry' and retry_after:
                # Flood control is per bot, not per chat: back off everything.
                nxt = _fmt(_now() + timedelta(seconds=retry_after))
                conn.execute("UPDATE notify_outbox SET next_attempt_at = ?, error = ? WHERE id = ?",
                             (nxt, detail, row['id']))
                conn.commit()
                handled += 1
                sleep(retry_after)
                break
            else:
                attempts = row['attempts'] + 1
                if outcome == 'failed' or attempts >= MAX_ATTEMPTS:
                    conn.execute("UPDATE notify_outbox SET status = 'failed', attempts = ?, error = ? "
                                 "WHERE id = ?", (attempts, detail, row['id']))
                else:
                    delay = RETRY_DELAYS[min(attempts - 1, len(RETRY_DELAYS) - 1)]
                    conn.execute("UPDATE notify_outbox SET attempts = ?, next_attempt_at = ?, error = ? "
                                 "WHERE id = ?", (attempts, _fmt(_now() + timedelta(seconds=delay)),
                                                  detail, row['id']))
            conn.commit()
            handled += 1
            sleep(1.0 / per_second)
    finally:
        conn.close()
    return handled


def prune_outbox(path=None, days=OUTBOX_KEEP_DAYS):
    """Delete sent and failed messages older than `days`. Queued ones are never touched."""
    cutoff = _fmt(_now() - timedelta(days=days))
    conn = _db(path)
    try:
        n = conn.execute("DELETE FROM notify_outbox WHERE status IN ('sent', 'failed') AND created_at < ?",
                         (cutoff,)).rowcount
        conn.commit()
    finally:
        conn.close()
    if n:
        logger.info(f'[NOTIFY] pruned {n} outbox message(s) older than {days} days')
    return n


_sender_started = False
_sender_lock = threading.Lock()


def _sender_loop(app):
    last_prune = 0.0
    with app.app_context():
        while True:
            if time.time() - last_prune >= PRUNE_EVERY_SECONDS:
                last_prune = time.time()
                try:
                    prune_outbox()
                except Exception as e:
                    logger.error(f'[NOTIFY] prune failed: {e}')
            try:
                n = process_outbox_once()
            except Exception as e:
                logger.error(f'[NOTIFY] sender error: {e}')
                n = 0
            if n == 0:
                _wake.wait(IDLE_POLL_SECONDS)
                _wake.clear()


def start_sender(app):
    global _sender_started
    with _sender_lock:
        if _sender_started:
            return
        _sender_started = True
    threading.Thread(target=_sender_loop, args=(app,), name='notify-sender', daemon=True).start()
    logger.info('[NOTIFY] sender thread started')


def move_user(old_id, new_id):
    """
    An app user signed in and their id changed: their watches, areas, claims and
    queued messages follow. Where both ids have a row, the newer id's is kept.
    """
    conn = _db()
    try:
        if conn.execute("SELECT 1 FROM notify_subscribers WHERE tg_id = ?", (new_id,)).fetchone():
            conn.execute("DELETE FROM notify_subscribers WHERE tg_id = ?", (old_id,))
        else:
            conn.execute("UPDATE notify_subscribers SET tg_id = ? WHERE tg_id = ?", (new_id, old_id))
        for table, col in (('place_watches', 'tg_id'), ('owner_claims', 'tg_id')):
            conn.execute(f"UPDATE OR IGNORE {table} SET {col} = ? WHERE {col} = ?", (new_id, old_id))
            conn.execute(f"DELETE FROM {table} WHERE {col} = ?", (old_id,))
        conn.execute("UPDATE area_watches SET tg_id = ? WHERE tg_id = ?", (new_id, old_id))
        conn.execute("UPDATE place_owners SET tg_id = ? WHERE tg_id = ?", (new_id, old_id))
        conn.execute("UPDATE announcements SET author_tg_id = ? WHERE author_tg_id = ?", (new_id, old_id))
        conn.execute("UPDATE notify_outbox SET tg_id = ? WHERE tg_id = ? AND status = 'queued'", (new_id, old_id))
        conn.commit()
    finally:
        conn.close()


def delete_user(user_id):
    """
    The person deleted their app account. Their subscriptions, claims and
    ownership go; announcements already sent stay, without their name.
    """
    conn = _db()
    try:
        for table in ('notify_subscribers', 'place_watches', 'area_watches', 'owner_claims', 'place_owners'):
            conn.execute(f"DELETE FROM {table} WHERE tg_id = ?", (user_id,))
        conn.execute("DELETE FROM announcements WHERE author_tg_id = ? AND status = 'pending'", (user_id,))
        conn.execute("UPDATE announcements SET author_tg_id = NULL, author_username = NULL "
                     "WHERE author_tg_id = ?", (user_id,))
        conn.execute("DELETE FROM notify_outbox WHERE tg_id = ? AND status = 'queued'", (user_id,))
        conn.commit()
    finally:
        conn.close()


def init_place_notifications(app):
    """Create the tables (idempotent) and start the sender thread."""
    init_schema(app.config.get('PLACE_NOTIFY_DB', DEFAULT_DB_PATH))
    on_user_moved(move_user)
    on_user_deleted(delete_user)
    if not app.config.get('PLACE_NOTIFY_WEBAPP_URL'):
        logger.warning('[NOTIFY] PLACE_NOTIFY_WEBAPP_URL is not set: bot messages will have no buttons')
    if os.getenv('PLACE_NOTIFY_DISABLE_SENDER') != '1':
        start_sender(app)


# ============================================
# MINI APP ENDPOINTS
# ============================================

def _area_out(conn, a):
    types = [t for t in (a['types'] or '').split(',') if t]
    counts, inside = _counts(conn, a['lat'], a['lon'], a['radius_km'], types)
    return {'id': a['id'], 'source': a['source'], 'label': a['label'],
            'lat': a['lat'], 'lon': a['lon'], 'radiusKm': a['radius_km'],
            'types': types, 'insideCount': inside, 'counts': counts}


@bp.route('/api/notify/me', methods=['GET', 'OPTIONS'])
def notify_me():
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    uid = int(user['id'])
    conn = _db()
    try:
        sub = conn.execute("SELECT lang, active FROM notify_subscribers WHERE tg_id = ?", (uid,)).fetchone()
        areas = [_area_out(conn, a) for a in conn.execute(
            "SELECT * FROM area_watches WHERE tg_id = ? ORDER BY id", (uid,))]
        watches = [{
            'placeId': r['place_id'], 'name': r['Name'], 'type': TYPE_BY_BUILDING.get(r['Building_type']),
            'city': r['City_English'], 'photo': r['Photo_path'],
        } for r in conn.execute(
            "SELECT w.place_id, m.Name, m.Building_type, m.City_English, m.Photo_path "
            "FROM place_watches w JOIN main_db m ON m.Unique_number = w.place_id "
            "WHERE w.tg_id = ? ORDER BY w.created_at DESC", (uid,))]
        telegram, push = _delivery(conn, uid)
        return jsonify({'success': True,
                        'subscriber': {'lang': sub['lang'], 'active': bool(sub['active'])} if sub else None,
                        'delivery': {'telegram': telegram, 'push': push, 'canTelegram': not is_app_user(uid),
                                     # Where to send someone the bot can't reach.
                                     'bot': str(_cfg('APP_TELEGRAM_BOT') or '').lstrip('@') or None},
                        'areas': areas, 'watches': watches})
    except sqlite3.Error as e:
        logger.error(f'notify_me failed: {e}')
        return _err('server_error', 'Could not load your subscriptions.', 500)
    finally:
        conn.close()


@bp.route('/api/notify/delivery', methods=['PUT', 'OPTIONS'])
def notify_delivery():
    """A Telegram user's choice: the bot, the app's push, or both (one at least)."""
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    uid = int(user['id'])
    if is_app_user(uid):
        return _err('telegram_only', 'Only an account signed in with Telegram can choose.', 400)
    body = request.get_json(silent=True) or {}
    telegram, push = bool(body.get('telegram')), bool(body.get('push'))
    if not (telegram or push):
        return _err('choose_one', 'Choose at least one way.', 400)
    conn = _db()
    try:
        _upsert_subscriber(conn, user, body.get('lang'))
        conn.execute("UPDATE notify_subscribers SET via_telegram = ?, via_push = ? WHERE tg_id = ?",
                     (int(telegram), int(push), uid))
        conn.commit()
        return jsonify({'success': True, 'delivery': {'telegram': telegram, 'push': push, 'canTelegram': True}})
    except sqlite3.Error as e:
        logger.error(f'notify_delivery failed: {e}')
        return _err('server_error', 'Could not save. Please try again.', 500)
    finally:
        conn.close()


@bp.route('/api/notify/watch/<int:place_id>', methods=['POST', 'DELETE', 'OPTIONS'])
def notify_watch(place_id):
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    uid = int(user['id'])
    body = request.get_json(silent=True) or {}
    conn = _db()
    try:
        if request.method == 'POST':
            if not conn.execute("SELECT 1 FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone():
                return _err('place_not_found', 'That place no longer exists.', 404)
            _upsert_subscriber(conn, user, body.get('lang'))
            conn.execute("INSERT OR IGNORE INTO place_watches (tg_id, place_id, created_at) VALUES (?, ?, ?)",
                         (uid, place_id, _fmt(_now())))
            welcome = _take_welcome(conn, uid)
        else:
            conn.execute("DELETE FROM place_watches WHERE tg_id = ? AND place_id = ?", (uid, place_id))
            welcome = None
        conn.commit()
        if welcome:
            _enqueue_quietly([welcome], f'welcome:{uid}')
        return jsonify({'success': True, 'placeId': place_id,
                        'watching': request.method == 'POST',
                        'watchCount': _watch_count(conn, place_id)})
    except sqlite3.Error as e:
        logger.error(f'notify_watch {place_id} failed: {e}')
        return _err('server_error', 'Could not save. Please try again.', 500)
    finally:
        conn.close()


def _area_from_body(body):
    """
    Validated area fields from a request body, or raises ValueError(code, message).

        source    "location" | "address"
        lat, lon  required for "location"
        address   required for "address" (Korean; geocoded here)
        label     optional display name for "location" (e.g. the district)
        radiusKm  1 | 3 | 5 | 10
        types     non-empty subset of ["mosque", "restaurant", "shop"]
    """
    source = body.get('source')
    if source not in ('location', 'address'):
        raise ValueError('invalid_source', 'source must be "location" or "address".')
    try:
        radius = int(body.get('radiusKm'))
    except (TypeError, ValueError):
        radius = None
    if radius not in RADII_KM:
        raise ValueError('invalid_radius', 'radiusKm must be 1, 3, 5 or 10.')
    types = body.get('types')
    if not isinstance(types, list):
        raise ValueError('invalid_types', 'types must be a list.')
    types = [t for t in TYPE_KEYS if t in types]
    if not types:
        raise ValueError('no_types', 'Choose at least one place type.')

    if source == 'location':
        try:
            lat, lon = float(body.get('lat')), float(body.get('lon'))
        except (TypeError, ValueError):
            raise ValueError('invalid_location', 'lat and lon are required.')
        if not (-90 <= lat <= 90 and -180 <= lon <= 180):
            raise ValueError('invalid_location', 'lat/lon out of range.')
        label = _clean_label(body.get('label'))
    else:
        address = _clean_label(body.get('address'))
        if not address:
            raise ValueError('no_address', 'Enter an address.')
        if not _rate_ok('geocode', 30, 60):
            raise ValueError('rate_limited', 'Too many address lookups. Please wait a minute.')
        found = _geocode_exact_or_error(address)
        lat, lon, label = found[0], found[1], _clean_label(found[2]) or address
    return {'source': source, 'lat': lat, 'lon': lon, 'label': label,
            'radius_km': radius, 'types': ','.join(types)}


@bp.route('/api/notify/areas', methods=['POST', 'OPTIONS'])
def notify_area_create():
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    uid = int(user['id'])
    body = request.get_json(silent=True) or {}
    try:
        fields = _area_from_body(body)
    except ValueError as e:
        code, message = e.args
        return _err(code, message, 429 if code == 'rate_limited' else 400)
    conn = _db()
    try:
        n = conn.execute("SELECT COUNT(*) FROM area_watches WHERE tg_id = ?", (uid,)).fetchone()[0]
        if n >= MAX_AREAS_PER_USER:
            return _err('too_many_areas', f'At most {MAX_AREAS_PER_USER} areas.', 409)
        try:
            _check_area_budget(conn, uid, fields['radius_km'])
        except ValueError as e:
            return _err(e.args[0], e.args[1], 409)
        if not _rate_ok('area-save', AREA_SAVES_PER_DAY, 86400, who=uid):
            return _err('too_many_changes', 'Too many area changes today. Please try again tomorrow.', 429)
        _upsert_subscriber(conn, user, body.get('lang'))
        now = _fmt(_now())
        cur = conn.execute(
            "INSERT INTO area_watches (tg_id, source, label, lat, lon, radius_km, types, created_at, updated_at) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (uid, fields['source'], fields['label'], fields['lat'], fields['lon'],
             fields['radius_km'], fields['types'], now, now))
        welcome = _take_welcome(conn, uid)
        conn.commit()
        if welcome:
            _enqueue_quietly([welcome], f'welcome:{uid}')
        a = conn.execute("SELECT * FROM area_watches WHERE id = ?", (cur.lastrowid,)).fetchone()
        return jsonify({'success': True, 'area': _area_out(conn, a)}), 201
    except sqlite3.Error as e:
        logger.error(f'area create failed: {e}')
        return _err('server_error', 'Could not save. Please try again.', 500)
    finally:
        conn.close()


@bp.route('/api/notify/areas/<int:area_id>', methods=['PUT', 'DELETE', 'OPTIONS'])
def notify_area_update(area_id):
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    uid = int(user['id'])
    body = request.get_json(silent=True) or {}
    conn = _db()
    try:
        # Someone else's area answers exactly like a missing one.
        if not conn.execute("SELECT 1 FROM area_watches WHERE id = ? AND tg_id = ?",
                            (area_id, uid)).fetchone():
            return _err('not_found', 'Area not found.', 404)
        if request.method == 'DELETE':
            conn.execute("DELETE FROM area_watches WHERE id = ? AND tg_id = ?", (area_id, uid))
            conn.commit()
            return jsonify({'success': True, 'deleted': area_id})
        try:
            fields = _area_from_body(body)
            _check_area_budget(conn, uid, fields['radius_km'], except_id=area_id)
        except ValueError as e:
            code, message = e.args
            return _err(code, message, 429 if code == 'rate_limited' else 409 if code == 'area_budget' else 400)
        if not _rate_ok('area-save', AREA_SAVES_PER_DAY, 86400, who=uid):
            return _err('too_many_changes', 'Too many area changes today. Please try again tomorrow.', 429)
        _upsert_subscriber(conn, user, body.get('lang'))
        conn.execute(
            "UPDATE area_watches SET source = ?, label = ?, lat = ?, lon = ?, radius_km = ?, types = ?, "
            "updated_at = ? WHERE id = ? AND tg_id = ?",
            (fields['source'], fields['label'], fields['lat'], fields['lon'], fields['radius_km'],
             fields['types'], _fmt(_now()), area_id, uid))
        conn.commit()
        a = conn.execute("SELECT * FROM area_watches WHERE id = ?", (area_id,)).fetchone()
        return jsonify({'success': True, 'area': _area_out(conn, a)})
    except sqlite3.Error as e:
        logger.error(f'area update {area_id} failed: {e}')
        return _err('server_error', 'Could not save. Please try again.', 500)
    finally:
        conn.close()


@bp.route('/api/places/in-radius', methods=['GET', 'OPTIONS'])
def places_in_radius():
    """
    Places within 10 km of a point, for the add-area preview. Coordinates are
    rounded to ~100 m (finer would not help; coarser would put dots on the
    wrong side of a 1 km ring) and carry no id or name: enough to draw dots and count
    per radius. Signed-in users only, with a per-person limit, so it cannot be
    swept across the map; addresses must be exact, as for saving an area.
    App users who have not signed in may use it, as they may save areas.
    """
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    if not _rate_ok('in-radius', 120, 60) or \
            not _rate_ok('in-radius-user', PREVIEWS_PER_10_MIN, 600, who=int(user['id'])):
        return _err('rate_limited', 'Too many requests. Please wait a minute.', 429)
    address = _clean_label(request.args.get('address'))
    label = None
    if address:
        if not _rate_ok('geocode', 30, 60):
            return _err('rate_limited', 'Too many address lookups. Please wait a minute.', 429)
        try:
            lat, lon, label = _geocode_exact_or_error(address)
        except ValueError as e:
            return _err(e.args[0], e.args[1], 404 if e.args[0] == 'address_not_found' else 400)
    else:
        try:
            lat, lon = float(request.args.get('lat')), float(request.args.get('lon'))
        except (TypeError, ValueError):
            return _err('invalid_location', 'lat and lon, or address, are required.')
    if not _preview_center_ok(int(user['id']), lat, lon):
        return _err('too_many_previews', 'Too many different places looked at today. Please try again tomorrow.', 429)
    conn = _db()
    try:
        rows = _place_rows_near(conn, lat, lon, MAX_RADIUS_KM)
    finally:
        conn.close()
    points = [{'lat': round(r['Latitude'], 3), 'lon': round(r['Longitude'], 3),
               'type': t, 'km': round(d, 1)} for d, t, r in sorted(rows, key=lambda x: x[0])]
    return jsonify({'success': True, 'center': {'lat': lat, 'lon': lon, 'label': label},
                    'radii': list(RADII_KM), 'points': points})


# ============================================
# OWNERS, CLAIMS, ANNOUNCEMENTS
# ============================================
# Restaurants and shops: only the verified owner may post. Mosques: anyone
# signed in. Every post waits for the admin, who is pinged in the bot and
# decides in the panel; nothing reaches subscribers before that. Recipients
# are the place's watchers plus matching area watchers, one message each.

ANNOUNCE_MAX = 1000
OWNABLE_TYPES = ('restaurant', 'shop')
# Not a posting limit (there is none): only the unreviewed backlog per person
# is capped, so a script cannot flood the admin's chat with pings.
MAX_PENDING_PER_USER = 5
ADMIN_QUOTE_MAX = 220


def _place_row(conn, place_id):
    return _q(conn, "SELECT * FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone()


def _sub_lang(conn, tg_id, default='uz'):
    r = conn.execute("SELECT lang FROM notify_subscribers WHERE tg_id = ?", (tg_id,)).fetchone()
    return _lang(r[0]) if r else default


def _display(user):
    """'Aziz Karimov (@aziz_k)' from Telegram user data; what the admin sees."""
    name = ' '.join(x for x in (user.get('first_name'), user.get('last_name')) if x).strip()
    uname = user.get('username')
    if name and uname:
        return f'{name} (@{uname})'[:LABEL_MAX]
    if user.get('contact'):
        # An app user signed in with WhatsApp or Google: how the admin reaches them.
        return (f"{name} ({user['contact']})" if name else user['contact'])[:LABEL_MAX]
    return (f'@{uname}' if uname else name or f"id{user.get('id')}")[:LABEL_MAX]


def _clean_text(v):
    """Announcement text: line breaks kept, outer whitespace dropped."""
    return str(v or '').replace('\r\n', '\n').replace('\r', '\n').strip()


def _admin_chat():
    return _cfg('PLACE_NOTIFY_ADMIN_CHAT_ID') or _cfg('PLACE_SUBMISSIONS_ADMIN_CHAT_ID')


def _admin_button(lang, tab):
    base = (_cfg('PLACE_NOTIFY_ADMIN_URL') or _cfg('PLACE_SUBMISSIONS_ADMIN_URL') or '').strip()
    if not base.startswith('https://'):
        return None
    return {'inline_keyboard': [[{'text': _raw(lang, 'admin_openPanel'), 'url': f'{base}#{tab}'}]]}


def _last7(conn, place_id):
    since = _fmt(_now() - timedelta(days=7))
    return conn.execute("SELECT COUNT(*) FROM announcements WHERE place_id = ? AND created_at >= ?",
                        (place_id, since)).fetchone()[0]


def _admin_message(conn, text_lines, tab):
    """One ping for the admin chat, or [] when no admin chat is configured."""
    chat = _admin_chat()
    if not chat:
        return []
    lang = _sub_lang(conn, chat)
    return [{'tg_id': int(chat), 'text': '\n'.join(text_lines(lang)), 'buttons': _admin_button(lang, tab)}]


def _ping_post(conn, place_row, who, role, text):
    quote = text if len(text) <= ADMIN_QUOTE_MAX else text[:ADMIN_QUOTE_MAX].rstrip() + '…'
    n = _last7(conn, place_row['Unique_number'])

    def lines(lang):
        writer = html.escape(who) + (f" · {_t(lang, 'admin_roleOwner')}" if role == 'owner' else '')
        return [f"<b>{_t(lang, 'admin_pendingPost')}</b>", html.escape(place_row['Name'] or ''), writer,
                _t(lang, 'admin_last7', n=n), f"<blockquote>{html.escape(quote)}</blockquote>"]
    return _admin_message(conn, lines, 'announcements')


def _ping_claim(conn, place_row, who, tg_id):
    def lines(lang):
        return [f"<b>{_t(lang, 'admin_pendingClaim')}</b>", html.escape(place_row['Name'] or ''),
                f"{html.escape(who)} · ID {int(tg_id)}"]
    return _admin_message(conn, lines, 'claims')


def _plain(conn, tg_id, key, **values):
    """A short message to one person in their own language, no buttons."""
    return {'tg_id': int(tg_id), 'text': _t(_sub_lang(conn, tg_id), key, **values), 'buttons': None}


def announcement_recipients(conn, place_row, exclude=None):
    """resolve_recipients() for a post on this place, minus its author."""
    place = place_from_row(place_row)
    lat, lon = _place_point(place)
    rec = resolve_recipients(conn, place['id'], lat, lon, place['type_key'])
    if exclude is not None:
        rec.pop(int(exclude), None)
    return place, rec


def _render_announcement(lang, place, text, role, r):
    title = _t(lang, 'announcement', name=place.get('name') or '')
    last = _t(lang, 'fromOwner') if role == 'owner' else _why(lang, r, 'announce')
    return f"<b>{title}</b>\n\n{html.escape(text)}\n\n<i>{last}</i>"


def prepare_announcement(conn, place_row, text, role, author_tg_id=None):
    place, rec = announcement_recipients(conn, place_row, exclude=author_tg_id)
    return [{'tg_id': uid, 'text': _render_announcement(r['lang'], place, text, role, r),
             'buttons': _buttons('announce', r['lang'], place, r)}
            for uid, r in rec.items()]


def _pending_by(conn, tg_id):
    a = conn.execute("SELECT COUNT(*) FROM announcements WHERE author_tg_id = ? AND status = 'pending'",
                     (tg_id,)).fetchone()[0]
    c = conn.execute("SELECT COUNT(*) FROM owner_claims WHERE tg_id = ? AND status = 'pending'",
                     (tg_id,)).fetchone()[0]
    return a + c


@bp.route('/api/notify/hello', methods=['POST', 'OPTIONS'])
def notify_hello():
    """
    "Allow" on the notifications page: switch the person back on and send a
    test message. If the bot still cannot reach them, the sender switches them
    off again and the page keeps showing the warning.
    """
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user(allow_anonymous=True)
    if error:
        return error
    if not _rate_ok('hello', 5, 60):
        return _err('rate_limited', 'Too many requests. Please wait a minute.', 429)
    uid = int(user['id'])
    body = request.get_json(silent=True) or {}
    conn = _db()
    try:
        _upsert_subscriber(conn, user, body.get('lang'))
        conn.execute("UPDATE notify_subscribers SET welcomed_at = ? WHERE tg_id = ?", (_fmt(_now()), uid))
        conn.commit()
        msg = {'tg_id': uid, **_welcome_message(_lang(body.get('lang')))}
    except sqlite3.Error as e:
        logger.error(f'hello failed: {e}')
        return _err('server_error', 'Could not save. Please try again.', 500)
    finally:
        conn.close()
    _enqueue_quietly([msg], f'hello:{uid}')
    return jsonify({'success': True})


@bp.route('/api/notify/claim/<int:place_id>', methods=['POST', 'OPTIONS'])
def notify_claim(place_id):
    """'I own this place': sends the signed-in user's Telegram identity to the admin."""
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user()
    if error:
        return error
    uid = int(user['id'])
    body = request.get_json(silent=True) or {}
    conn = _db()
    pings = []
    try:
        row = _place_row(conn, place_id)
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        if TYPE_BY_BUILDING.get(row['Building_type']) not in OWNABLE_TYPES:
            return _err('claim_not_supported', 'Only restaurants and shops have owners.', 400)
        owner = conn.execute("SELECT tg_id FROM place_owners WHERE place_id = ?", (place_id,)).fetchone()
        if owner:
            return _err('has_owner', 'This place already has a confirmed owner.', 409)
        if conn.execute("SELECT 1 FROM owner_claims WHERE place_id = ? AND tg_id = ? AND status = 'pending'",
                        (place_id, uid)).fetchone():
            return jsonify({'success': True, 'claimPending': True})
        if _pending_by(conn, uid) >= MAX_PENDING_PER_USER:
            return _err('too_many_pending', 'Too many requests are waiting for review.', 429)
        _upsert_subscriber(conn, user, body.get('lang'))
        who = _display(user)
        conn.execute("INSERT INTO owner_claims (place_id, tg_id, username, status, created_at) "
                     "VALUES (?, ?, ?, 'pending', ?)", (place_id, uid, who, _fmt(_now())))
        conn.commit()
        pings = _ping_claim(conn, row, who, uid)
    except sqlite3.Error as e:
        logger.error(f'claim {place_id} failed: {e}')
        return _err('server_error', 'Could not send. Please try again.', 500)
    finally:
        conn.close()
    _enqueue_quietly(pings, f'claim:{place_id}:admin')
    return jsonify({'success': True, 'claimPending': True})


def _can_post(conn, row, uid):
    """None when uid may post on this place, else (code, message, status)."""
    t = TYPE_BY_BUILDING.get(row['Building_type'])
    if t == 'mosque':
        return None
    owner = conn.execute("SELECT tg_id FROM place_owners WHERE place_id = ?",
                         (row['Unique_number'],)).fetchone()
    if owner and int(owner[0]) == uid:
        return None
    return 'not_owner', 'Only the confirmed owner can post for this place.', 403


@bp.route('/api/notify/announce/<int:place_id>', methods=['POST', 'OPTIONS'])
def notify_announce(place_id):
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user()
    if error:
        return error
    uid = int(user['id'])
    body = request.get_json(silent=True) or {}
    text = _clean_text(body.get('text'))
    if not text:
        return _err('text_empty', 'Write something first.', 400)
    if len(text) > ANNOUNCE_MAX:
        return _err('text_too_long', f'At most {ANNOUNCE_MAX} characters.', 400)
    conn = _db()
    pings = []
    try:
        row = _place_row(conn, place_id)
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        denied = _can_post(conn, row, uid)
        if denied:
            return _err(*denied)
        if _pending_by(conn, uid) >= MAX_PENDING_PER_USER:
            return _err('too_many_pending', 'Too many posts are waiting for review.', 429)
        role = 'public' if TYPE_BY_BUILDING.get(row['Building_type']) == 'mosque' else 'owner'
        _upsert_subscriber(conn, user, body.get('lang'))
        who = _display(user)
        cur = conn.execute(
            "INSERT INTO announcements (place_id, author_tg_id, author_username, author_role, text, status, "
            "created_at) VALUES (?, ?, ?, ?, ?, 'pending', ?)", (place_id, uid, who, role, text, _fmt(_now())))
        ann_id = cur.lastrowid
        conn.commit()
        pings = _ping_post(conn, row, who, role, text)
        mine = conn.execute("SELECT COUNT(*) FROM announcements WHERE place_id = ? AND author_tg_id = ? "
                            "AND status = 'pending'", (place_id, uid)).fetchone()[0]
    except sqlite3.Error as e:
        logger.error(f'announce {place_id} failed: {e}')
        return _err('server_error', 'Could not send. Please try again.', 500)
    finally:
        conn.close()
    _enqueue_quietly(pings, f'ann:{ann_id}:admin')
    return jsonify({'success': True, 'id': ann_id, 'pendingAnnouncements': mine}), 201


@bp.route('/api/notify/announce/<int:place_id>/reach', methods=['GET', 'OPTIONS'])
def notify_announce_reach(place_id):
    """The composer's 'about N people' line. Only for someone who may post here."""
    if request.method == 'OPTIONS':
        return '', 200
    user, error = _require_user()
    if error:
        return error
    uid = int(user['id'])
    conn = _db()
    try:
        row = _place_row(conn, place_id)
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        denied = _can_post(conn, row, uid)
        if denied:
            return _err(*denied)
        _, rec = announcement_recipients(conn, row, exclude=uid)
        return jsonify({'success': True, 'count': len(rec)})
    except sqlite3.Error as e:
        logger.error(f'announce reach {place_id} failed: {e}')
        return _err('server_error', 'Could not count.', 500)
    finally:
        conn.close()


def _enqueue_quietly(messages, ref):
    """Queue messages after the main change has committed; a failure is logged, not raised."""
    try:
        return enqueue_messages(messages, ref)
    except Exception as e:
        logger.error(f'[NOTIFY] could not queue {ref}: {e}')
        return 0


# ============================================
# ADMIN
# ============================================

def _admin_guard():
    if not session.get('admin_logged_in'):
        return _err('unauthorized', 'Unauthorized.', 401)
    return None


@bp.route('/api/admin/notify/reach', methods=['GET'])
def admin_notify_reach():
    """
    How many people a Send tick would reach — the number shown next to the
    checkbox. For a place that is not saved yet, pass lat/lon/type instead of
    place_id. event=new leaves place watchers out (a new place has none).
    """
    guard = _admin_guard()
    if guard:
        return guard
    a = request.args
    conn = _db()
    try:
        place_id = a.get('place_id', type=int)
        lat, lon = a.get('lat', type=float), a.get('lon', type=float)
        type_key = a.get('type') or None
        if type_key in BUILDING_BY_TYPE.values():
            type_key = TYPE_BY_BUILDING[type_key]
        if place_id is not None and (lat is None or lon is None or not type_key):
            row = conn.execute("SELECT Building_type, Latitude, Longitude FROM main_db WHERE Unique_number = ?",
                               (place_id,)).fetchone()
            if row:
                lat = lat if lat is not None else row['Latitude']
                lon = lon if lon is not None else row['Longitude']
                type_key = type_key or TYPE_BY_BUILDING.get(row['Building_type'])
        rec = resolve_recipients(conn, place_id, lat, lon, type_key,
                                 include_place_watchers=(a.get('event') != 'new'))
        place_n = sum(1 for r in rec.values() if r['kind'] == 'place')
        return jsonify({'success': True, 'count': len(rec),
                        'placeWatchers': place_n, 'areaWatchers': len(rec) - place_n})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/stats', methods=['GET'])
def admin_notify_stats():
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        outbox = {r['status']: r['n'] for r in conn.execute(
            "SELECT status, COUNT(*) AS n FROM notify_outbox GROUP BY status")}
        subs = conn.execute("SELECT SUM(active = 1) AS active, SUM(active = 0) AS inactive "
                            "FROM notify_subscribers").fetchone()
        return jsonify({
            'success': True,
            'outbox': {k: outbox.get(k, 0) for k in ('queued', 'sent', 'failed')},
            'subscribers': {'active': subs['active'] or 0, 'inactive': subs['inactive'] or 0},
            'pendingAnnouncements': conn.execute(
                "SELECT COUNT(*) FROM announcements WHERE status = 'pending'").fetchone()[0],
            'pendingClaims': conn.execute(
                "SELECT COUNT(*) FROM owner_claims WHERE status = 'pending'").fetchone()[0],
            'placeWatches': conn.execute("SELECT COUNT(*) FROM place_watches").fetchone()[0],
            'areaWatches': conn.execute("SELECT COUNT(*) FROM area_watches").fetchone()[0],
            'lastErrors': [dict(r) for r in conn.execute(
                "SELECT id, tg_id, error, created_at FROM notify_outbox WHERE status = 'failed' "
                "ORDER BY id DESC LIMIT 10")],
        })
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


# --- Announcements -------------------------------------------------------

def _ann_out(conn, a, with_reach):
    row = _place_row(conn, a['place_id'])
    out = {k: a[k] for k in ('id', 'place_id', 'author_tg_id', 'author_username', 'author_role', 'text',
                             'status', 'created_at', 'reviewed_at', 'sent_at', 'recipients')}
    out['place'] = {'name': row['Name'], 'type': TYPE_BY_BUILDING.get(row['Building_type'])} if row else None
    out['last7'] = _last7(conn, a['place_id'])
    if with_reach and row:
        out['reach'] = len(announcement_recipients(conn, row, exclude=a['author_tg_id'])[1])
    return out


@bp.route('/api/admin/announcements', methods=['GET'])
def admin_announcements():
    guard = _admin_guard()
    if guard:
        return guard
    status = request.args.get('status', 'pending')
    conn = _db()
    try:
        sql = "SELECT * FROM announcements"
        args = ()
        if status in ('pending', 'approved', 'rejected'):
            sql += " WHERE status = ?"
            args = (status,)
        sql += " ORDER BY id DESC LIMIT 200"
        rows = [_ann_out(conn, a, a['status'] == 'pending') for a in conn.execute(sql, args).fetchall()]
        return jsonify({'success': True, 'announcements': rows})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


def _send_post(conn, ann_id, row, text, role, author_tg_id):
    """Queue an approved post and tell its writer. Returns (recipients, notify_error)."""
    msgs = prepare_announcement(conn, row, text, role, author_tg_id)
    extra = []
    if author_tg_id is not None and role != 'admin':
        extra.append(_plain(conn, author_tg_id, 'approved', n=len(msgs)))
    try:
        enqueue_messages(msgs, f'ann:{ann_id}')
        enqueue_messages(extra, f'ann:{ann_id}:writer')
        return len(msgs), None
    except Exception as e:
        logger.error(f'[NOTIFY] announcement {ann_id}: {e}')
        return len(msgs), str(e)


@bp.route('/api/admin/announcements', methods=['POST'])
def admin_announcement_post():
    """The admin posts on a place directly: no review step, sent at once."""
    guard = _admin_guard()
    if guard:
        return guard
    body = request.get_json(silent=True) or {}
    text = _clean_text(body.get('text'))
    if not text:
        return _err('text_empty', 'Write something first.', 400)
    if len(text) > ANNOUNCE_MAX:
        return _err('text_too_long', f'At most {ANNOUNCE_MAX} characters.', 400)
    conn = _db()
    try:
        row = _place_row(conn, body.get('place_id'))
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        now = _fmt(_now())
        msgs = prepare_announcement(conn, row, text, 'admin')
        cur = conn.execute(
            "INSERT INTO announcements (place_id, author_tg_id, author_username, author_role, text, status, "
            "created_at, reviewed_at, sent_at, recipients) VALUES (?, NULL, 'admin', 'admin', ?, 'approved', "
            "?, ?, ?, ?)", (row['Unique_number'], text, now, now, now, len(msgs)))
        ann_id = cur.lastrowid
        conn.commit()
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()
    try:
        enqueue_messages(msgs, f'ann:{ann_id}')
        err = None
    except Exception as e:
        err = str(e)
    return jsonify({'success': True, 'id': ann_id, 'notified': len(msgs), 'notifyError': err}), 201


@bp.route('/api/admin/announcements/<int:ann_id>', methods=['PUT', 'DELETE'])
def admin_announcement_edit(ann_id):
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        a = conn.execute("SELECT * FROM announcements WHERE id = ?", (ann_id,)).fetchone()
        if not a:
            return _err('not_found', 'Announcement not found.', 404)
        if request.method == 'DELETE':
            # Messages already sent stay in people's chats; this only removes the record.
            conn.execute("DELETE FROM announcements WHERE id = ?", (ann_id,))
            conn.commit()
            return jsonify({'success': True, 'deleted': ann_id})
        if a['status'] != 'pending':
            return _err('not_pending', 'Only a waiting announcement can be edited.', 409)
        text = _clean_text((request.get_json(silent=True) or {}).get('text'))
        if not text:
            return _err('text_empty', 'Write something first.', 400)
        if len(text) > ANNOUNCE_MAX:
            return _err('text_too_long', f'At most {ANNOUNCE_MAX} characters.', 400)
        conn.execute("UPDATE announcements SET text = ? WHERE id = ?", (text, ann_id))
        conn.commit()
        return jsonify({'success': True, 'announcement': _ann_out(
            conn, conn.execute("SELECT * FROM announcements WHERE id = ?", (ann_id,)).fetchone(), True)})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/announcements/<int:ann_id>/<action>', methods=['POST'])
def admin_announcement_decide(ann_id, action):
    guard = _admin_guard()
    if guard:
        return guard
    if action not in ('approve', 'reject'):
        return _err('not_found', 'Unknown action.', 404)
    body = request.get_json(silent=True) or {}
    conn = _db()
    try:
        a = conn.execute("SELECT * FROM announcements WHERE id = ?", (ann_id,)).fetchone()
        if not a:
            return _err('not_found', 'Announcement not found.', 404)
        if a['status'] != 'pending':
            return _err('not_pending', 'This announcement was already decided.', 409)
        now = _fmt(_now())
        if action == 'reject':
            conn.execute("UPDATE announcements SET status = 'rejected', reviewed_at = ? "
                         "WHERE id = ? AND status = 'pending'", (now, ann_id))
            conn.commit()
            if a['author_tg_id'] is not None:
                _enqueue_quietly([_plain(conn, a['author_tg_id'], 'rejected')], f'ann:{ann_id}:writer')
            return jsonify({'success': True, 'status': 'rejected'})

        text = _clean_text(body['text']) if body.get('text') is not None else a['text']
        if not text:
            return _err('text_empty', 'Write something first.', 400)
        if len(text) > ANNOUNCE_MAX:
            return _err('text_too_long', f'At most {ANNOUNCE_MAX} characters.', 400)
        row = _place_row(conn, a['place_id'])
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        n_preview = len(announcement_recipients(conn, row, exclude=a['author_tg_id'])[1])
        # The status check in the WHERE makes a double click approve once.
        cur = conn.execute("UPDATE announcements SET status = 'approved', text = ?, reviewed_at = ?, "
                           "sent_at = ?, recipients = ? WHERE id = ? AND status = 'pending'",
                           (text, now, now, n_preview, ann_id))
        conn.commit()
        if cur.rowcount == 0:
            return _err('not_pending', 'This announcement was already decided.', 409)
        n, err = _send_post(conn, ann_id, row, text, a['author_role'], a['author_tg_id'])
        return jsonify({'success': True, 'status': 'approved', 'notified': n, 'notifyError': err})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


# --- Owner claims and owners ---------------------------------------------

@bp.route('/api/admin/claims', methods=['GET'])
def admin_claims():
    guard = _admin_guard()
    if guard:
        return guard
    status = request.args.get('status', 'pending')
    conn = _db()
    try:
        sql = ("SELECT c.*, m.Name AS place_name, m.Building_type, o.tg_id AS owner_tg_id, "
               "o.username AS owner_username FROM owner_claims c "
               "LEFT JOIN main_db m ON m.Unique_number = c.place_id "
               "LEFT JOIN place_owners o ON o.place_id = c.place_id")
        args = ()
        if status in ('pending', 'approved', 'rejected'):
            sql += " WHERE c.status = ?"
            args = (status,)
        sql += " ORDER BY c.id DESC LIMIT 200"
        rows = [{'id': r['id'], 'place_id': r['place_id'], 'place_name': r['place_name'],
                 'place_type': TYPE_BY_BUILDING.get(r['Building_type']), 'tg_id': r['tg_id'],
                 'username': r['username'], 'status': r['status'], 'created_at': r['created_at'],
                 'reviewed_at': r['reviewed_at'],
                 'current_owner': {'tg_id': r['owner_tg_id'], 'username': r['owner_username']}
                 if r['owner_tg_id'] is not None else None}
                for r in conn.execute(sql, args)]
        return jsonify({'success': True, 'claims': rows})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/claims/<int:claim_id>/<action>', methods=['POST'])
def admin_claim_decide(claim_id, action):
    guard = _admin_guard()
    if guard:
        return guard
    if action not in ('approve', 'reject'):
        return _err('not_found', 'Unknown action.', 404)
    conn = _db()
    try:
        c = conn.execute("SELECT * FROM owner_claims WHERE id = ?", (claim_id,)).fetchone()
        if not c:
            return _err('not_found', 'Claim not found.', 404)
        if c['status'] != 'pending':
            return _err('not_pending', 'This claim was already decided.', 409)
        row = _place_row(conn, c['place_id'])
        name = row['Name'] if row else ''
        now = _fmt(_now())
        new_status = 'approved' if action == 'approve' else 'rejected'
        cur = conn.execute("UPDATE owner_claims SET status = ?, reviewed_at = ? WHERE id = ? AND status = 'pending'",
                           (new_status, now, claim_id))
        if cur.rowcount == 0:
            return _err('not_pending', 'This claim was already decided.', 409)
        if action == 'approve':
            if not row:
                conn.rollback()
                return _err('place_not_found', 'That place no longer exists.', 404)
            # Approving replaces any current owner: this is also how a place is reassigned.
            conn.execute("INSERT OR REPLACE INTO place_owners (place_id, tg_id, username, approved_at) "
                         "VALUES (?, ?, ?, ?)", (c['place_id'], c['tg_id'], c['username'], now))
        conn.commit()
        key = 'claimApproved' if action == 'approve' else 'claimRejected'
        _enqueue_quietly([_plain(conn, c['tg_id'], key, name=name)], f'claim:{claim_id}:claimant')
        return jsonify({'success': True, 'status': new_status})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/owners', methods=['GET'])
def admin_owners():
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        rows = [{'place_id': r['place_id'], 'place_name': r['Name'],
                 'place_type': TYPE_BY_BUILDING.get(r['Building_type']), 'tg_id': r['tg_id'],
                 'username': r['username'], 'approved_at': r['approved_at']}
                for r in conn.execute(
                    "SELECT o.*, m.Name, m.Building_type FROM place_owners o "
                    "LEFT JOIN main_db m ON m.Unique_number = o.place_id ORDER BY m.Name")]
        return jsonify({'success': True, 'owners': rows})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/owners/<int:place_id>', methods=['PUT', 'DELETE'])
def admin_owner_set(place_id):
    """PUT assigns or reassigns the owner by Telegram ID; DELETE revokes."""
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        if request.method == 'DELETE':
            n = conn.execute("DELETE FROM place_owners WHERE place_id = ?", (place_id,)).rowcount
            conn.commit()
            if not n:
                return _err('not_found', 'This place has no owner.', 404)
            return jsonify({'success': True, 'revoked': place_id})
        body = request.get_json(silent=True) or {}
        try:
            tg_id = int(str(body.get('tg_id', '')).strip())
        except ValueError:
            return _err('invalid_tg_id', 'Enter the numeric Telegram ID.', 400)
        if tg_id <= 0:
            return _err('invalid_tg_id', 'Enter the numeric Telegram ID.', 400)
        row = _place_row(conn, place_id)
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        if TYPE_BY_BUILDING.get(row['Building_type']) not in OWNABLE_TYPES:
            return _err('claim_not_supported', 'Only restaurants and shops have owners.', 400)
        username = _clean_label(body.get('username'))
        conn.execute("INSERT OR REPLACE INTO place_owners (place_id, tg_id, username, approved_at) "
                     "VALUES (?, ?, ?, ?)", (place_id, tg_id, username, _fmt(_now())))
        conn.commit()
        return jsonify({'success': True, 'place_id': place_id, 'tg_id': tg_id})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


# --- Watchers: read-only views for the panel -------------------------------

def _preview(text, n=160):
    """A bot message as one plain line: tags dropped, entities decoded."""
    plain = html.unescape(re.sub(r'<[^>]+>', ' ', text or ''))
    plain = ' '.join(plain.split())
    return plain if len(plain) <= n else plain[:n].rstrip() + '…'


def _sub_out(r):
    return {'tg_id': r['tg_id'], 'username': r['username'], 'lang': r['lang'],
            'active': bool(r['active']), 'blocked_at': r['blocked_at'], 'created_at': r['created_at']}


def _watch_counts(conn):
    """{place_id: active watchers} — the same number the place page shows."""
    return {r[0]: r[1] for r in conn.execute(
        "SELECT w.place_id, COUNT(*) FROM place_watches w JOIN notify_subscribers s "
        "ON s.tg_id = w.tg_id AND s.active = 1 GROUP BY w.place_id")}


@bp.route('/api/admin/notify/watch-counts', methods=['GET'])
def admin_watch_counts():
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        return jsonify({'success': True, 'counts': {str(k): v for k, v in _watch_counts(conn).items()}})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/places', methods=['GET'])
def admin_watched_places():
    """Places with at least one watcher, most watched first, with how many areas also cover them."""
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        counts = _watch_counts(conn)
        top = sorted(counts.items(), key=lambda kv: -kv[1])[:200]
        out = []
        for pid, n in top:
            row = _place_row(conn, pid)
            if not row:
                continue
            place = place_from_row(row)
            lat, lon = _place_point(place)
            area_n = len(resolve_recipients(conn, pid, lat, lon, place['type_key'], include_place_watchers=False))
            out.append({'place_id': pid, 'name': row['Name'], 'type': place['type_key'],
                        'city': row['City_English'], 'watchers': n, 'areaCoverage': area_n})
        return jsonify({'success': True, 'places': out})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/places/<int:place_id>', methods=['GET'])
def admin_place_watchers(place_id):
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        row = _place_row(conn, place_id)
        if not row:
            return _err('place_not_found', 'That place no longer exists.', 404)
        place = place_from_row(row)
        watchers = [{**_sub_out(r), 'since': r['since']} for r in _q(conn,
            "SELECT s.*, w.created_at AS since FROM place_watches w JOIN notify_subscribers s "
            "ON s.tg_id = w.tg_id WHERE w.place_id = ? ORDER BY w.created_at DESC", (place_id,))]
        lat, lon = _place_point(place)
        rec = resolve_recipients(conn, place_id, lat, lon, place['type_key'], include_place_watchers=False)
        names = {r['tg_id']: r['username'] for r in _q(conn, "SELECT tg_id, username FROM notify_subscribers")}
        areas = [{'tg_id': uid, 'username': names.get(uid), 'lang': r['lang'], 'area_id': r['area']['id'],
                  'label': r['area']['label'], 'source': r['area']['source'], 'radius_km': r['area']['radius_km']}
                 for uid, r in rec.items() if uid not in {w['tg_id'] for w in watchers}]
        return jsonify({'success': True,
                        'place': {'place_id': place_id, 'name': row['Name'], 'type': place['type_key'],
                                  'city': row['City_English']},
                        'watchers': watchers, 'areaWatchers': areas})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/subscribers', methods=['GET'])
def admin_subscribers():
    guard = _admin_guard()
    if guard:
        return guard
    q = (request.args.get('q') or '').strip().lstrip('@')
    status = request.args.get('status', 'all')
    conn = _db()
    try:
        sql = ("SELECT s.*, "
               "(SELECT COUNT(*) FROM place_watches w WHERE w.tg_id = s.tg_id) AS watches, "
               "(SELECT COUNT(*) FROM area_watches a WHERE a.tg_id = s.tg_id) AS areas, "
               "(SELECT MAX(sent_at) FROM notify_outbox o WHERE o.tg_id = s.tg_id AND o.status = 'sent') AS last_sent "
               "FROM notify_subscribers s WHERE 1 = 1")
        args = []
        if q:
            sql += " AND (s.username LIKE ? OR CAST(s.tg_id AS TEXT) = ?)"
            args += [f'%{q}%', q]
        if status in ('active', 'blocked'):
            sql += " AND s.active = ?"
            args.append(1 if status == 'active' else 0)
        sql += " ORDER BY s.updated_at DESC LIMIT 300"
        rows = [{**_sub_out(r), 'watches': r['watches'], 'areas': r['areas'], 'last_sent': r['last_sent']}
                for r in _q(conn, sql, args)]
        return jsonify({'success': True, 'subscribers': rows})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/subscribers/<int:tg_id>', methods=['GET'])
def admin_subscriber(tg_id):
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        sub = _q(conn, "SELECT * FROM notify_subscribers WHERE tg_id = ?", (tg_id,)).fetchone()
        if not sub:
            return _err('not_found', 'No such subscriber.', 404)
        watches = [{'place_id': r['place_id'], 'name': r['Name'], 'type': TYPE_BY_BUILDING.get(r['Building_type']),
                    'since': r['created_at']} for r in _q(conn,
                   "SELECT w.place_id, w.created_at, m.Name, m.Building_type FROM place_watches w "
                   "LEFT JOIN main_db m ON m.Unique_number = w.place_id WHERE w.tg_id = ? "
                   "ORDER BY w.created_at DESC", (tg_id,))]
        areas = [_area_out(conn, a) for a in _q(conn, "SELECT * FROM area_watches WHERE tg_id = ? ORDER BY id",
                                                 (tg_id,))]
        msgs = [{'id': r['id'], 'event_ref': r['event_ref'], 'status': r['status'], 'created_at': r['created_at'],
                 'sent_at': r['sent_at'], 'error': r['error'], 'preview': _preview(r['text'])}
                for r in _q(conn, "SELECT * FROM notify_outbox WHERE tg_id = ? ORDER BY id DESC LIMIT 20", (tg_id,))]
        owns = [{'place_id': r['place_id'], 'name': r['Name']} for r in _q(conn,
                "SELECT o.place_id, m.Name FROM place_owners o LEFT JOIN main_db m "
                "ON m.Unique_number = o.place_id WHERE o.tg_id = ?", (tg_id,))]
        return jsonify({'success': True, 'subscriber': _sub_out(sub), 'watches': watches,
                        'areas': areas, 'owns': owns, 'messages': msgs})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/areas', methods=['GET'])
def admin_areas():
    guard = _admin_guard()
    if guard:
        return guard
    conn = _db()
    try:
        rows = []
        for a in _q(conn, "SELECT a.*, s.username, s.active FROM area_watches a "
                          "LEFT JOIN notify_subscribers s ON s.tg_id = a.tg_id ORDER BY a.id DESC LIMIT 500"):
            out = _area_out(conn, a)
            out.update({'tg_id': a['tg_id'], 'username': a['username'], 'active': bool(a['active']),
                        'created_at': a['created_at']})
            rows.append(out)
        return jsonify({'success': True, 'areas': rows})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()


@bp.route('/api/admin/notify/messages', methods=['GET'])
def admin_messages():
    guard = _admin_guard()
    if guard:
        return guard
    status = request.args.get('status', 'all')
    conn = _db()
    try:
        sql = ("SELECT o.*, s.username FROM notify_outbox o "
               "LEFT JOIN notify_subscribers s ON s.tg_id = o.tg_id")
        args = ()
        if status in ('queued', 'sent', 'failed'):
            sql += " WHERE o.status = ?"
            args = (status,)
        sql += " ORDER BY o.id DESC LIMIT 200"
        rows = [{'id': r['id'], 'tg_id': r['tg_id'], 'username': r['username'], 'event_ref': r['event_ref'],
                 'status': r['status'], 'attempts': r['attempts'], 'created_at': r['created_at'],
                 'sent_at': r['sent_at'], 'error': r['error'], 'preview': _preview(r['text'])}
                for r in _q(conn, sql, args)]
        return jsonify({'success': True, 'messages': rows})
    except sqlite3.Error as e:
        return _err('server_error', str(e), 500)
    finally:
        conn.close()
