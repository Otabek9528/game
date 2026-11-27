"""
mosque_timetable_api.py
=======================
A mosque's congregation (iqamah) times and its Eid prayer times, kept by the
community. Anyone signed in (the same sign-in as for reviews) can change them,
and the change shows at once: there is no approval step. Every save is kept in
mosque_timetable_history, so the admin can see who changed what and put an
earlier version back.

    PUT /api/place/<id>/timetable   {"fajr", "dhuhr", "asr", "maghrib", "isha", "jumuah"}
                                    each "HH:MM" (KST) or null to clear it;
                                    a key left out keeps what is there
    PUT /api/place/<id>/eid         {"fitr": ["07:00", "08:30"], "adha": ["07:30"]}
                                    0-3 times each; a key left out keeps what is there, [] clears

Both answer with the mosque's `timetable` and `eid`, as GET /api/place/<id>
now carries them for mosques (timetable_info()).

Admin (the places panel's Timetables tab; the panel's session login):

    GET    /api/admin/timetables                          every mosque, with or without times
    GET    /api/admin/timetables/<id>/history?before=<n>  its saves, newest first, 50 a page
    PUT    /api/admin/timetables/<id>                     {"daily": {...}, "fitr": [...], "adha": [...]}
    DELETE /api/admin/timetables/<id>?section=daily|fitr|adha|all
    POST   /api/admin/timetables/history/<n>/restore      puts back what was there before save n

Admin changes are saved like anyone's, with history (source 'admin'), so a
clear or a restore can itself be undone.

Eid
---
Two rows per mosque: the Ramadan Eid ('fitr') and Eid al-Adha ('adha'), each
with its own times and the date they were last changed. There is no Eid date:
the "last updated" date is what tells people which year the times were for.
Like the daily times, each is marked `stale` when nobody has changed it for
STALE_AFTER_DAYS days.

Who edited is for the admin only: the public answers carry the date of the
last change, never a name or id.

Messages
--------
A change is told to the mosque's watchers and to the people whose area
covers it (place_notifications_api decides who, and delivers by the bot and
the app), except whoever made it and anyone who switched these messages off:

    GET/PUT /api/notify/timetable-updates   {"on": true|false}

Saves are gathered, not told one by one. Once nobody has changed a mosque
for NOTIFY_QUIET_MINUTES (or NOTIFY_MAX_WAIT_MINUTES after the first change),
one message says what differs from before the first change; nothing goes out
when it was put back. A mosque sends at most NOTIFY_PER_DAY a day. Every
outcome is logged for the panel (GET /api/admin/timetables/messages).

app.config["TIMETABLE_NOTIFY"]: 'on' sends; 'dry_run' (the default) does all
of it except sending, so the panel shows who would have been told; 'off'
neither gathers nor sends.

Configuration: app.config["PLACES_DB"] (main_db.sqlite), as places_public_api.py.
"""

import html
import json
import logging
import os
import re
import sqlite3
import threading
import time
from datetime import datetime, timedelta, timezone

from flask import Blueprint, jsonify, request, session

from place_submissions_api import resolve_submitter, submitter_name

logger = logging.getLogger(__name__)

bp = Blueprint('mosque_timetable', __name__)

DEFAULT_DB_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'
KST = timezone(timedelta(hours=9))
TS_FORMAT = '%Y-%m-%d %H:%M:%S'

MOSQUE_BUILDING_TYPE = 'Masjid'
PRAYERS = ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jumuah')
EIDS = ('fitr', 'adha')
EID_SESSIONS_MAX = 3
STALE_AFTER_DAYS = 60
# A brake on scripts, far above what one person does by hand; not moderation.
SAVES_PER_HOUR = 30
HISTORY_PAGE = 50

NOTIFY_MODES = ('on', 'dry_run', 'off')
NOTIFY_QUIET_MINUTES = 10
NOTIFY_MAX_WAIT_MINUTES = 60
NOTIFY_PER_DAY = 3
NOTIFY_POLL_SECONDS = 60
MESSAGES_PAGE = 100

# The words of the message. Mirrors times.* in pages/places/places.text.js of
# the frontend, which this server cannot read; edit the two together.
MESSAGE_TEXT = {
    'updated': {'uz': 'Namoz vaqtlari yangilandi:', 'ru': 'Время намаза обновлено:',
                'en': 'Prayer times updated:'},
    'fajr':    {'uz': 'Bomdod', 'ru': 'Фаджр', 'en': 'Fajr'},
    'dhuhr':   {'uz': 'Peshin', 'ru': 'Зухр', 'en': 'Dhuhr'},
    'asr':     {'uz': 'Asr', 'ru': 'Аср', 'en': 'Asr'},
    'maghrib': {'uz': 'Shom', 'ru': 'Магриб', 'en': 'Maghrib'},
    'isha':    {'uz': 'Xufton', 'ru': 'Иша', 'en': 'Isha'},
    'jumuah':  {'uz': 'Juma', 'ru': 'Джума', 'en': 'Jumu‘ah'},
    'fitr':    {'uz': 'Ramazon hayiti', 'ru': 'Ураза-байрам', 'en': 'Eid al-Fitr'},
    'adha':    {'uz': 'Qurbon hayiti', 'ru': 'Курбан-байрам', 'en': 'Eid al-Adha'},
}

SCHEMA = """
CREATE TABLE IF NOT EXISTS mosque_timetables (
    place_id         INTEGER PRIMARY KEY,
    fajr             TEXT,
    dhuhr            TEXT,
    asr              TEXT,
    maghrib          TEXT,
    isha             TEXT,
    jumuah           TEXT,
    updated_at       TEXT NOT NULL,      -- KST, TS_FORMAT
    updated_by       INTEGER,
    updated_by_name  TEXT
);

CREATE TABLE IF NOT EXISTS mosque_eid_times (
    place_id         INTEGER NOT NULL,
    eid              TEXT NOT NULL CHECK (eid IN ('fitr', 'adha')),
    sessions         TEXT NOT NULL,      -- JSON list of "HH:MM", ascending, 1-3
    updated_at       TEXT NOT NULL,
    updated_by       INTEGER,
    updated_by_name  TEXT,
    PRIMARY KEY (place_id, eid)
);

-- Every save: what the section held before and after (JSON; NULL = empty).
CREATE TABLE IF NOT EXISTS mosque_timetable_history (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id         INTEGER NOT NULL,
    section          TEXT NOT NULL CHECK (section IN ('daily', 'fitr', 'adha')),
    old_value        TEXT,
    new_value        TEXT,
    editor_id        INTEGER,
    editor_name      TEXT,
    source           TEXT NOT NULL DEFAULT 'public' CHECK (source IN ('public', 'admin')),
    created_at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_mosque_tt_history_place ON mosque_timetable_history (place_id, id);
CREATE INDEX IF NOT EXISTS idx_mosque_tt_history_editor ON mosque_timetable_history (editor_id, created_at);

-- A mosque changed and not yet told: the times before the first such change,
-- and who changed it since (they are not told).
CREATE TABLE IF NOT EXISTS timetable_notify_pending (
    place_id         INTEGER PRIMARY KEY,
    baseline         TEXT NOT NULL,
    editors          TEXT NOT NULL,
    first_at         TEXT NOT NULL,
    last_at          TEXT NOT NULL
);

-- What came of each gathered change, for the panel.
CREATE TABLE IF NOT EXISTS timetable_notify_log (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id         INTEGER NOT NULL,
    place_name       TEXT,
    mode             TEXT NOT NULL CHECK (mode IN ('sent', 'dry_run', 'unchanged', 'capped')),
    recipients       INTEGER NOT NULL DEFAULT 0,
    changes          TEXT,
    created_at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_tt_notify_log_place ON timetable_notify_log (place_id, created_at);
"""

_db_path = DEFAULT_DB_PATH
_notify_mode = 'dry_run'
_notifier_lock = threading.Lock()
_notifier_started = False
_TIME = re.compile(r'^([01]?\d|2[0-3]):([0-5]\d)$')


# ============================================
# PLUMBING
# ============================================

def _now():
    return datetime.now(KST)


def _fmt(dt):
    return dt.strftime(TS_FORMAT)


def _db(path=None):
    conn = sqlite3.connect(path or _db_path, timeout=10)
    conn.row_factory = sqlite3.Row
    return conn


def _err(code, message, status=400):
    return jsonify({'success': False, 'code': code, 'error': message}), status


class InputError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message


def init_schema(path):
    conn = _db(path)
    try:
        conn.executescript(SCHEMA)
        conn.commit()
    finally:
        conn.close()


def init_mosque_timetables(app):
    """
    Create the tables (idempotent), follow people whose app account changes or
    goes, and start the worker that sends the gathered messages.
    """
    global _db_path, _notify_mode
    _db_path = app.config.get('PLACES_DB', DEFAULT_DB_PATH)
    mode = app.config.get('TIMETABLE_NOTIFY', 'dry_run')
    if mode not in NOTIFY_MODES:
        logger.warning('[TIMETABLE] TIMETABLE_NOTIFY=%r is not one of %s: using dry_run', mode, NOTIFY_MODES)
        mode = 'dry_run'
    _notify_mode = mode
    init_schema(_db_path)
    from app_accounts import on_user_moved, on_user_deleted
    on_user_moved(move_editor)
    on_user_deleted(forget_editor)
    if mode != 'off' and not app.config.get('TESTING') and os.getenv('PLACE_NOTIFY_DISABLE_SENDER') != '1':
        start_notifier(app)


# ============================================
# VALUES
# ============================================

def parse_time(value, field):
    """"HH:MM" (zero-padded) or None for null/empty; InputError otherwise."""
    if value is None or value == '':
        return None
    m = _TIME.match(str(value).strip())
    if not m:
        raise InputError('invalid_time', f'{field}: expected HH:MM')
    return f'{int(m.group(1)):02d}:{m.group(2)}'


def parse_sessions(value, field):
    """One Eid's prayer times: a list of up to EID_SESSIONS_MAX distinct times, ascending."""
    if not isinstance(value, list):
        raise InputError('invalid_input', f'{field}: expected a list of HH:MM')
    times = sorted({t for t in (parse_time(v, field) for v in value) if t})
    if len(times) > EID_SESSIONS_MAX:
        raise InputError('too_many_sessions', f'{field}: at most {EID_SESSIONS_MAX} Eid prayers')
    return times


def _sessions(row):
    if not row:
        return []
    try:
        return [t for t in json.loads(row['sessions'] or '[]') if isinstance(t, str)]
    except ValueError:
        return []


def _updated(row, today):
    """updatedAt (the KST date) and stale, for a stored row."""
    day = datetime.strptime(row['updated_at'], TS_FORMAT).date()
    return {'updatedAt': day.isoformat(), 'stale': (today - day).days > STALE_AFTER_DAYS}


# ============================================
# WHAT THE PAGE GETS
# ============================================

def _daily_out(row, today):
    if not row or all(row[p] is None for p in PRAYERS):
        return None
    out = {p: row[p] for p in PRAYERS}
    out.update(_updated(row, today))
    return out


def _eid_out(row, today):
    sessions = _sessions(row)
    if not sessions:
        return None
    out = {'sessions': sessions}
    out.update(_updated(row, today))
    return out


def timetable_info(conn, place_id, today=None):
    """
    {'timetable': {...} | None, 'eid': {'fitr': {...} | None, 'adha': {...} | None}}
    for /api/place/<id> of a mosque; None where nothing was entered. conn
    needs sqlite3.Row rows. Never raises: a missing table (init not run) must
    not take the detail page down.
    """
    today = today or _now().date()
    out = {'timetable': None, 'eid': {e: None for e in EIDS}}
    try:
        out['timetable'] = _daily_out(conn.execute(
            "SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone(), today)
        for row in conn.execute("SELECT * FROM mosque_eid_times WHERE place_id = ?", (place_id,)):
            if row['eid'] in EIDS:
                out['eid'][row['eid']] = _eid_out(row, today)
    except sqlite3.Error as e:
        logger.warning(f'timetable_info({place_id}) failed: {e}')
    return out


# ============================================
# SAVING
# ============================================

def _editor():
    """(user, None) or (None, error response): the same sign-in as reviews."""
    user, err = resolve_submitter()
    if err:
        code, message = err
        return None, _err(code, message, 503 if code == 'server_misconfigured' else 401)
    return user, None


def _begin_edit(conn, place_id, editor_id, now):
    """Locks the database for this save and checks it may go ahead: None, or an error response."""
    conn.execute('BEGIN IMMEDIATE')
    place = conn.execute("SELECT Building_type FROM main_db WHERE Unique_number = ?", (place_id,)).fetchone()
    if not place:
        return _err('place_not_found', 'That place no longer exists.', 404)
    if place['Building_type'] != MOSQUE_BUILDING_TYPE:
        return _err('not_a_mosque', 'Only mosques have prayer times.', 400)
    recent = conn.execute(
        "SELECT COUNT(*) FROM mosque_timetable_history WHERE editor_id = ? AND created_at >= ?",
        (editor_id, _fmt(now - timedelta(hours=1)))).fetchone()[0]
    if recent >= SAVES_PER_HOUR:
        return _err('too_many_edits', 'Too many changes. Please try again later.', 429)
    return None


def _who(user):
    """(id, name) stored for an editor; an admin save (phase 3) has no user."""
    return (int(user['id']), submitter_name(user)) if user else (None, 'admin')


def _history(conn, place_id, section, old, new, user, now, source):
    editor_id, editor_name = _who(user)
    conn.execute(
        "INSERT INTO mosque_timetable_history (place_id, section, old_value, new_value, "
        "editor_id, editor_name, source, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (place_id, section,
         json.dumps(old, ensure_ascii=False) if old is not None else None,
         json.dumps(new, ensure_ascii=False) if new is not None else None,
         editor_id, editor_name, source, _fmt(now)))


def write_daily(conn, place_id, new, user, now, source='public'):
    """
    Put the six times in place, in the caller's transaction. new: {prayer:
    "HH:MM"|None} for all six. Returns whether anything changed; history is
    written when it did.
    """
    row = conn.execute("SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone()
    old = {p: row[p] for p in PRAYERS} if row and any(row[p] for p in PRAYERS) else None
    new = new if any(new.values()) else None
    if old == new:
        return False
    if new is None:
        conn.execute("DELETE FROM mosque_timetables WHERE place_id = ?", (place_id,))
    else:
        conn.execute(
            "INSERT INTO mosque_timetables (place_id, fajr, dhuhr, asr, maghrib, isha, jumuah, "
            "updated_at, updated_by, updated_by_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
            "ON CONFLICT(place_id) DO UPDATE SET fajr = excluded.fajr, dhuhr = excluded.dhuhr, "
            "asr = excluded.asr, maghrib = excluded.maghrib, isha = excluded.isha, jumuah = excluded.jumuah, "
            "updated_at = excluded.updated_at, updated_by = excluded.updated_by, "
            "updated_by_name = excluded.updated_by_name",
            (place_id, *(new[p] for p in PRAYERS), _fmt(now), *_who(user)))
    _history(conn, place_id, 'daily', old, new, user, now, source)
    return True


def write_eid(conn, place_id, eid, sessions, user, now, source='public'):
    """One Eid's prayer times ('fitr' or 'adha'), in the caller's transaction. Returns whether anything changed."""
    row = conn.execute("SELECT * FROM mosque_eid_times WHERE place_id = ? AND eid = ?", (place_id, eid)).fetchone()
    old = _sessions(row) or None
    new = sessions or None
    if old == new:
        return False
    if new is None:
        conn.execute("DELETE FROM mosque_eid_times WHERE place_id = ? AND eid = ?", (place_id, eid))
    else:
        conn.execute(
            "INSERT INTO mosque_eid_times (place_id, eid, sessions, updated_at, updated_by, updated_by_name) "
            "VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(place_id, eid) DO UPDATE SET sessions = excluded.sessions, "
            "updated_at = excluded.updated_at, updated_by = excluded.updated_by, "
            "updated_by_name = excluded.updated_by_name",
            (place_id, eid, json.dumps(new), _fmt(now), *_who(user)))
    _history(conn, place_id, eid, old, new, user, now, source)
    return True


def _save(place_id, user, write):
    """Runs write(conn, now) -> changed in one locked transaction; the answer both PUTs give."""
    now = _now()
    conn = _db()
    conn.isolation_level = None          # BEGIN IMMEDIATE / COMMIT by hand
    try:
        refused = _begin_edit(conn, place_id, int(user['id']), now)
        if refused:
            conn.execute('ROLLBACK')
            return refused
        before = _state(conn, place_id)
        changed = write(conn, now)
        if changed:
            _gather(conn, place_id, before, int(user['id']), now)
        conn.execute('COMMIT')
        out = {'success': True, 'changed': changed}
        out.update(timetable_info(conn, place_id))
        return jsonify(out)
    except sqlite3.Error:
        if conn.in_transaction:
            conn.execute('ROLLBACK')
        logger.exception('Prayer time save for place %s failed', place_id)
        return _err('server_error', 'Could not save the times.', 500)
    finally:
        conn.close()


@bp.route('/api/place/<int:place_id>/timetable', methods=['PUT'])
def put_timetable(place_id):
    user, error = _editor()
    if error:
        return error
    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        return _err('invalid_input', 'Expected a JSON object.')
    try:
        given = {p: parse_time(body[p], p) for p in PRAYERS if p in body}
    except InputError as e:
        return _err(e.code, e.message)
    if not given:
        return _err('invalid_input', f"Nothing to save. Expected any of: {', '.join(PRAYERS)}.")

    def write(conn, now):
        row = conn.execute("SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone()
        new = {p: given[p] if p in given else (row[p] if row else None) for p in PRAYERS}
        changed = write_daily(conn, place_id, new, user, now)
        if changed:
            logger.info('[TIMETABLE] mosque %s daily times changed by %s', place_id, user['id'])
        return changed

    return _save(place_id, user, write)


@bp.route('/api/place/<int:place_id>/eid', methods=['PUT'])
def put_eid(place_id):
    user, error = _editor()
    if error:
        return error
    body = request.get_json(silent=True)
    if not isinstance(body, dict) or not any(kind in body for kind in EIDS):
        return _err('invalid_input', 'Expected {"fitr": [...], "adha": [...]} (either or both).')
    try:
        given = {kind: parse_sessions(body[kind], kind) for kind in EIDS if kind in body}
    except InputError as e:
        return _err(e.code, e.message)

    def write(conn, now):
        changed = [kind for kind, sessions in given.items()
                   if write_eid(conn, place_id, kind, sessions, user, now)]
        if changed:
            logger.info('[TIMETABLE] mosque %s Eid times (%s) changed by %s', place_id, ', '.join(changed), user['id'])
        return bool(changed)

    return _save(place_id, user, write)


# ============================================
# ADMIN
# ============================================

def _admin_guard():
    """An error response unless the places panel's admin is logged in."""
    if not session.get('admin_logged_in'):
        return _err('unauthorized', 'Unauthorized.', 401)
    return None


def _place_id(value):
    """main_db.Unique_number is TEXT; the tables here use integers."""
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None


def _by(row):
    return {'updatedBy': row['updated_by_name'], 'updatedById': row['updated_by']}


def _admin_item(place, daily_row, eid_rows, edits, today):
    """One mosque as the Timetables tab lists it: the public view plus who changed it last."""
    daily = _daily_out(daily_row, today)
    if daily:
        daily.update(_by(daily_row))
    eid = {}
    for kind in EIDS:
        row = eid_rows.get(kind)
        out = _eid_out(row, today)
        if out:
            out.update(_by(row))
        eid[kind] = out
    count, last = edits or (0, None)
    return {'id': _place_id(place['Unique_number']), 'name': place['Name'], 'city': place['City_English'],
            'address': place['Actual_address'], 'timetable': daily, 'eid': eid,
            'edits': count, 'lastEditAt': last}


def _admin_one(conn, place_id, today):
    place = conn.execute("SELECT Unique_number, Name, City_English, Actual_address FROM main_db "
                         "WHERE Unique_number = ? AND Building_type = ?",
                         (place_id, MOSQUE_BUILDING_TYPE)).fetchone()
    if not place:
        return None
    daily = conn.execute("SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone()
    eids = {r['eid']: r for r in conn.execute("SELECT * FROM mosque_eid_times WHERE place_id = ?", (place_id,))}
    edits = conn.execute("SELECT COUNT(*), MAX(created_at) FROM mosque_timetable_history WHERE place_id = ?",
                         (place_id,)).fetchone()
    return _admin_item(place, daily, eids, (edits[0], edits[1]), today)


@bp.route('/api/admin/timetables', methods=['GET'])
def admin_list_timetables():
    refused = _admin_guard()
    if refused:
        return refused
    today = _now().date()
    conn = _db()
    try:
        places = conn.execute("SELECT Unique_number, Name, City_English, Actual_address FROM main_db "
                              "WHERE Building_type = ? ORDER BY City_English, Name",
                              (MOSQUE_BUILDING_TYPE,)).fetchall()
        daily = {r['place_id']: r for r in conn.execute("SELECT * FROM mosque_timetables")}
        eids = {}
        for r in conn.execute("SELECT * FROM mosque_eid_times"):
            eids.setdefault(r['place_id'], {})[r['eid']] = r
        edits = {r[0]: (r[1], r[2]) for r in conn.execute(
            "SELECT place_id, COUNT(*), MAX(created_at) FROM mosque_timetable_history GROUP BY place_id")}
    finally:
        conn.close()
    mosques = []
    for p in places:
        pid = _place_id(p['Unique_number'])
        if pid is None:
            continue
        mosques.append(_admin_item(p, daily.get(pid), eids.get(pid, {}), edits.get(pid), today))
    return jsonify({'success': True, 'mosques': mosques})


def _history_out(row):
    def parse(v):
        try:
            return json.loads(v) if v is not None else None
        except ValueError:
            return None
    return {'id': row['id'], 'section': row['section'], 'old': parse(row['old_value']),
            'new': parse(row['new_value']), 'editorId': row['editor_id'], 'editorName': row['editor_name'],
            'source': row['source'], 'at': row['created_at']}


@bp.route('/api/admin/timetables/<int:place_id>/history', methods=['GET'])
def admin_timetable_history(place_id):
    refused = _admin_guard()
    if refused:
        return refused
    try:
        before = int(request.args.get('before') or 0)
    except ValueError:
        before = 0
    conn = _db()
    try:
        args = [place_id]
        where = "place_id = ?"
        if before > 0:
            where += " AND id < ?"
            args.append(before)
        rows = conn.execute(f"SELECT * FROM mosque_timetable_history WHERE {where} ORDER BY id DESC LIMIT ?",
                            (*args, HISTORY_PAGE + 1)).fetchall()
    finally:
        conn.close()
    return jsonify({'success': True, 'history': [_history_out(r) for r in rows[:HISTORY_PAGE]],
                    'more': len(rows) > HISTORY_PAGE})


def _admin_save(place_id, write):
    """write(conn, now) in one locked transaction; answers with the mosque as the tab lists it."""
    now = _now()
    conn = _db()
    conn.isolation_level = None
    try:
        conn.execute('BEGIN IMMEDIATE')
        if not conn.execute("SELECT 1 FROM main_db WHERE Unique_number = ? AND Building_type = ?",
                            (place_id, MOSQUE_BUILDING_TYPE)).fetchone():
            conn.execute('ROLLBACK')
            return _err('place_not_found', 'No mosque with that number.', 404)
        before = _state(conn, place_id)
        try:
            changed = write(conn, now)
        except InputError as e:
            conn.execute('ROLLBACK')
            return _err(e.code, e.message)
        if changed:
            _gather(conn, place_id, before, None, now)
        conn.execute('COMMIT')
        if changed:
            logger.info('[TIMETABLE] mosque %s changed by the admin', place_id)
        return jsonify({'success': True, 'changed': changed, 'mosque': _admin_one(conn, place_id, now.date())})
    except sqlite3.Error:
        if conn.in_transaction:
            conn.execute('ROLLBACK')
        logger.exception('Admin prayer time save for place %s failed', place_id)
        return _err('server_error', 'Could not save.', 500)
    finally:
        conn.close()


@bp.route('/api/admin/timetables/<int:place_id>', methods=['PUT'])
def admin_put_timetable(place_id):
    """{"daily": {all six, null clears}, "fitr": [...], "adha": [...]}: any of the three."""
    refused = _admin_guard()
    if refused:
        return refused
    body = request.get_json(silent=True)
    if not isinstance(body, dict) or not any(k in body for k in ('daily',) + EIDS):
        return _err('invalid_input', 'Expected "daily", "fitr" and/or "adha".')
    daily = body.get('daily')
    if 'daily' in body and not isinstance(daily, dict):
        return _err('invalid_input', 'daily: expected an object.')

    def write(conn, now):
        changed = False
        if 'daily' in body:
            changed |= write_daily(conn, place_id, {p: parse_time(daily.get(p), p) for p in PRAYERS},
                                   None, now, source='admin')
        for kind in EIDS:
            if kind in body:
                changed |= write_eid(conn, place_id, kind, parse_sessions(body[kind], kind), None, now,
                                     source='admin')
        return changed

    return _admin_save(place_id, write)


@bp.route('/api/admin/timetables/<int:place_id>', methods=['DELETE'])
def admin_clear_timetable(place_id):
    """Clears the daily times, one Eid, or all three. History keeps what was there."""
    refused = _admin_guard()
    if refused:
        return refused
    section = request.args.get('section', 'all')
    if section not in ('daily', 'all') + EIDS:
        return _err('invalid_input', 'section: daily, fitr, adha or all.')

    def write(conn, now):
        changed = False
        if section in ('daily', 'all'):
            changed |= write_daily(conn, place_id, {p: None for p in PRAYERS}, None, now, source='admin')
        for kind in EIDS:
            if section in (kind, 'all'):
                changed |= write_eid(conn, place_id, kind, [], None, now, source='admin')
        return changed

    return _admin_save(place_id, write)


@bp.route('/api/admin/timetables/history/<int:history_id>/restore', methods=['POST'])
def admin_restore_timetable(history_id):
    """Puts the section back as it was before that save (cleared, if it was empty then)."""
    refused = _admin_guard()
    if refused:
        return refused
    conn = _db()
    try:
        row = conn.execute("SELECT * FROM mosque_timetable_history WHERE id = ?", (history_id,)).fetchone()
    finally:
        conn.close()
    if not row:
        return _err('not_found', 'No such change.', 404)
    entry = _history_out(row)
    old = entry['old']

    def write(conn, now):
        if entry['section'] == 'daily':
            values = old if isinstance(old, dict) else {}
            return write_daily(conn, row['place_id'], {p: values.get(p) for p in PRAYERS}, None, now,
                               source='admin')
        return write_eid(conn, row['place_id'], entry['section'], old if isinstance(old, list) else [],
                         None, now, source='admin')

    return _admin_save(row['place_id'], write)


# ============================================
# MESSAGES
# ============================================

def _state(conn, place_id):
    """Everything a message can be about: the six times and both Eids' lists."""
    row = conn.execute("SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone()
    out = {p: (row[p] if row else None) for p in PRAYERS}
    for kind in EIDS:
        out[kind] = _sessions(conn.execute("SELECT sessions FROM mosque_eid_times WHERE place_id = ? AND eid = ?",
                                           (place_id, kind)).fetchone())
    return out


def changes_between(before, after):
    """[(key, old, new)] in page order: prayers, then the Eids."""
    out = []
    for key in PRAYERS + EIDS:
        empty = [] if key in EIDS else None
        old, new = before.get(key, empty), after.get(key, empty)
        if (old or empty) != (new or empty):
            out.append((key, old or empty, new or empty))
    return out


def _gather(conn, place_id, before, editor_id, now):
    """A save changed the mosque: hold it for one message, in the save's transaction."""
    if _notify_mode == 'off':
        return
    stamp = _fmt(now)
    conn.execute("INSERT OR IGNORE INTO timetable_notify_pending (place_id, baseline, editors, first_at, last_at) "
                 "VALUES (?, ?, '[]', ?, ?)", (place_id, json.dumps(before), stamp, stamp))
    editors = json.loads(conn.execute("SELECT editors FROM timetable_notify_pending WHERE place_id = ?",
                                      (place_id,)).fetchone()[0])
    if editor_id is not None and editor_id not in editors:
        editors.append(editor_id)
    conn.execute("UPDATE timetable_notify_pending SET editors = ?, last_at = ? WHERE place_id = ?",
                 (json.dumps(editors), stamp, place_id))


def _word(lang, key):
    node = MESSAGE_TEXT[key]
    return html.escape(node.get(lang) or node['uz'], quote=False)


def render_message(lang, name, changes):
    """The Telegram text, without the "why" line. Its first line, the mosque in bold, is also the push's title."""
    lines = [f'<b>{html.escape(name or "", quote=False)}</b>', _word(lang, 'updated')]
    for key, old, new in changes:
        if key in EIDS:
            lines.append(f"{_word(lang, key)}: <b>{' · '.join(new) if new else '—'}</b>")
        else:
            lines.append(f"{_word(lang, key)}: {old or '—'} → <b>{new or '—'}</b>")
    return '\n'.join(lines)


def _ensure_optout_column(conn):
    """notify_subscribers.timetable_updates (1: told of prayer time changes). False when that table is not there yet."""
    try:
        cols = {r[1] for r in conn.execute("PRAGMA table_info(notify_subscribers)")}
    except sqlite3.Error:
        return False
    if not cols:
        return False
    if 'timetable_updates' not in cols:
        conn.execute("ALTER TABLE notify_subscribers ADD COLUMN timetable_updates INTEGER NOT NULL DEFAULT 1")
    return True


def _messages(conn, place_row, changes, editors):
    """The outbox rows for one change: who is told, each in their language."""
    import place_notifications_api as pn
    place = pn.place_from_row(place_row)
    if not place.get('type_key'):
        return []
    lat, lon = pn._place_point(place)
    recipients = pn.resolve_recipients(conn, place['id'], lat, lon, place['type_key'])
    for uid in editors:
        recipients.pop(int(uid), None)
    if recipients and _ensure_optout_column(conn):
        ids = list(recipients)
        off = {r[0] for r in conn.execute(
            f"SELECT tg_id FROM notify_subscribers WHERE timetable_updates = 0 "
            f"AND tg_id IN ({','.join('?' * len(ids))})", ids)}
        for uid in off:
            recipients.pop(uid, None)
    return [{'tg_id': uid,
             'text': render_message(r['lang'], place.get('name'), changes) + f"\n<i>{pn._why(r['lang'], r, 'changed')}</i>",
             'buttons': pn._buttons('changed', r['lang'], place, r)}
            for uid, r in recipients.items()]


def flush_notices(now=None):
    """
    Tell people about the mosques that have been quiet long enough. Returns
    how many gathered changes it handled. Run by the worker every minute;
    callable by hand.
    """
    now = now or _now()
    quiet = _fmt(now - timedelta(minutes=NOTIFY_QUIET_MINUTES))
    oldest = _fmt(now - timedelta(minutes=NOTIFY_MAX_WAIT_MINUTES))
    day_start = _fmt(now.replace(hour=0, minute=0, second=0, microsecond=0))
    to_send = []
    conn = _db()
    conn.isolation_level = None
    try:
        conn.execute('BEGIN IMMEDIATE')
        due = conn.execute("SELECT * FROM timetable_notify_pending WHERE last_at <= ? OR first_at <= ?",
                           (quiet, oldest)).fetchall()
        for p in due:
            pid = p['place_id']
            conn.execute("DELETE FROM timetable_notify_pending WHERE place_id = ?", (pid,))
            place_row = conn.execute("SELECT * FROM main_db WHERE Unique_number = ?", (pid,)).fetchone()
            if not place_row:
                continue
            changes = changes_between(json.loads(p['baseline']), _state(conn, pid))
            messages = []
            if not changes:
                mode = 'unchanged'
            elif conn.execute("SELECT COUNT(*) FROM timetable_notify_log WHERE place_id = ? "
                              "AND mode IN ('sent', 'dry_run') AND created_at >= ?",
                              (pid, day_start)).fetchone()[0] >= NOTIFY_PER_DAY:
                mode = 'capped'
            else:
                mode = 'sent' if _notify_mode == 'on' else 'dry_run'
                messages = _messages(conn, place_row, changes, json.loads(p['editors']))
            conn.execute("INSERT INTO timetable_notify_log (place_id, place_name, mode, recipients, changes, created_at) "
                         "VALUES (?, ?, ?, ?, ?, ?)",
                         (pid, place_row['Name'], mode, len(messages),
                          json.dumps([list(c) for c in changes], ensure_ascii=False), _fmt(now)))
            if mode == 'sent' and messages:
                to_send.append((messages, f'place:{pid}:times'))
        conn.execute('COMMIT')
    except Exception:
        if conn.in_transaction:
            conn.execute('ROLLBACK')
        logger.exception('[TIMETABLE] sending the gathered changes failed')
        return 0
    finally:
        conn.close()
    if to_send:
        import place_notifications_api as pn
        for messages, ref in to_send:
            try:
                pn.enqueue_messages(messages, ref)
            except Exception:
                logger.exception('[TIMETABLE] queueing %s failed', ref)
    return len(due)


def _notifier_loop(app):
    with app.app_context():
        while True:
            time.sleep(NOTIFY_POLL_SECONDS)
            try:
                flush_notices()
            except Exception:
                logger.exception('[TIMETABLE] notifier error')


def start_notifier(app):
    global _notifier_started
    with _notifier_lock:
        if _notifier_started:
            return
        _notifier_started = True
    threading.Thread(target=_notifier_loop, args=(app,), name='timetable-notify', daemon=True).start()
    logger.info('[TIMETABLE] notifier started (%s)', _notify_mode)


@bp.route('/api/notify/timetable-updates', methods=['GET', 'PUT', 'OPTIONS'])
def notify_timetable_updates():
    """Whether this person is told when prayer times change: {"on": true|false}."""
    if request.method == 'OPTIONS':
        return '', 200
    user, err = resolve_submitter(allow_anonymous=True)
    if err:
        code, message = err
        return _err(code, message, 503 if code == 'server_misconfigured' else 401)
    uid = int(user['id'])
    conn = _db()
    try:
        if not _ensure_optout_column(conn):
            return jsonify({'success': True, 'on': True})
        if request.method == 'PUT':
            body = request.get_json(silent=True) or {}
            if not isinstance(body.get('on'), bool):
                return _err('invalid_input', 'Expected {"on": true|false}.')
            conn.execute("UPDATE notify_subscribers SET timetable_updates = ? WHERE tg_id = ?",
                         (int(body['on']), uid))
            conn.commit()
        row = conn.execute("SELECT timetable_updates FROM notify_subscribers WHERE tg_id = ?", (uid,)).fetchone()
        return jsonify({'success': True, 'on': bool(row[0]) if row else True})
    except sqlite3.Error as e:
        logger.error(f'timetable-updates for {uid} failed: {e}')
        return _err('server_error', 'Could not save. Please try again.', 500)
    finally:
        conn.close()


@bp.route('/api/admin/timetables/messages', methods=['GET'])
def admin_timetable_messages():
    """What came of the latest gathered changes, newest first, and the mode."""
    refused = _admin_guard()
    if refused:
        return refused
    conn = _db()
    try:
        rows = conn.execute("SELECT * FROM timetable_notify_log ORDER BY id DESC LIMIT ?",
                            (MESSAGES_PAGE,)).fetchall()
        waiting = conn.execute("SELECT COUNT(*) FROM timetable_notify_pending").fetchone()[0]
    finally:
        conn.close()
    out = []
    for r in rows:
        try:
            changes = json.loads(r['changes'] or '[]')
        except ValueError:
            changes = []
        out.append({'id': r['id'], 'placeId': r['place_id'], 'placeName': r['place_name'], 'mode': r['mode'],
                    'recipients': r['recipients'], 'changes': changes, 'at': r['created_at']})
    return jsonify({'success': True, 'mode': _notify_mode, 'waiting': waiting, 'messages': out,
                    'quietMinutes': NOTIFY_QUIET_MINUTES, 'perDay': NOTIFY_PER_DAY})


# ============================================
# PLACES AND PEOPLE GOING
# ============================================

_TABLES = ('mosque_timetables', 'mosque_eid_times', 'mosque_timetable_history',
           'timetable_notify_pending', 'timetable_notify_log')
_EDITOR_COLUMNS = (('mosque_timetables', 'updated_by', 'updated_by_name'),
                   ('mosque_eid_times', 'updated_by', 'updated_by_name'),
                   ('mosque_timetable_history', 'editor_id', 'editor_name'))


def delete_place_timetable_rows(conn, place_id):
    """
    Everything kept for this place, inside the caller's delete transaction.
    Unique_number is reused (the panel assigns max+1): rows left behind would
    show a deleted mosque's times on a future place.
    """
    deleted = 0
    for table in _TABLES:
        try:
            deleted += conn.execute(f"DELETE FROM {table} WHERE place_id = ?", (place_id,)).rowcount
        except sqlite3.OperationalError:
            pass               # init not run yet
    return deleted


def move_editor(old_id, new_id):
    """An app user signed in and their id changed: their edits stay theirs."""
    conn = _db()
    try:
        for table, id_col, _ in _EDITOR_COLUMNS:
            conn.execute(f"UPDATE {table} SET {id_col} = ? WHERE {id_col} = ?", (int(new_id), int(old_id)))
        conn.commit()
    except sqlite3.OperationalError:
        pass
    finally:
        conn.close()


def forget_editor(user_id):
    """The person deleted their app account: the times they entered stay, without who entered them."""
    conn = _db()
    try:
        for table, id_col, name_col in _EDITOR_COLUMNS:
            conn.execute(f"UPDATE {table} SET {id_col} = NULL, {name_col} = NULL WHERE {id_col} = ?",
                         (int(user_id),))
        conn.commit()
    except sqlite3.OperationalError:
        pass
    finally:
        conn.close()
