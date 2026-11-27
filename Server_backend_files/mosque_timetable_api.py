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
    PUT /api/place/<id>/eid         {"sessions": ["07:00", "08:30"]}: 0-3 times; [] clears them

Both answer with the mosque's `timetable` and `eid`, as GET /api/place/<id>
now carries them for mosques (timetable_info()).

Eid
---
One set of Eid prayer times per mosque, with the date it was last changed.
There is no Eid date and no Eid name: the "last updated" date is what tells
people which Eid the times were for. Like the daily times, they are marked
`stale` when nobody has changed them for STALE_AFTER_DAYS days.

Who edited is for the admin only: the public answers carry the date of the
last change, never a name or id.

Configuration: app.config["PLACES_DB"] (main_db.sqlite), as places_public_api.py.
"""

import json
import logging
import re
import sqlite3
from datetime import datetime, timedelta, timezone

from flask import Blueprint, jsonify, request

from place_submissions_api import resolve_submitter, submitter_name

logger = logging.getLogger(__name__)

bp = Blueprint('mosque_timetable', __name__)

DEFAULT_DB_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'
KST = timezone(timedelta(hours=9))
TS_FORMAT = '%Y-%m-%d %H:%M:%S'

MOSQUE_BUILDING_TYPE = 'Masjid'
PRAYERS = ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jumuah')
EID_SESSIONS_MAX = 3
STALE_AFTER_DAYS = 60
# A brake on scripts, far above what one person does by hand; not moderation.
SAVES_PER_HOUR = 30

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
    place_id         INTEGER PRIMARY KEY,
    sessions         TEXT NOT NULL,      -- JSON list of "HH:MM", ascending, 1-3
    updated_at       TEXT NOT NULL,
    updated_by       INTEGER,
    updated_by_name  TEXT
);

-- Every save: what the section held before and after (JSON; NULL = empty).
CREATE TABLE IF NOT EXISTS mosque_timetable_history (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id         INTEGER NOT NULL,
    section          TEXT NOT NULL CHECK (section IN ('daily', 'eid')),
    old_value        TEXT,
    new_value        TEXT,
    editor_id        INTEGER,
    editor_name      TEXT,
    source           TEXT NOT NULL DEFAULT 'public' CHECK (source IN ('public', 'admin')),
    created_at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_mosque_tt_history_place ON mosque_timetable_history (place_id, id);
CREATE INDEX IF NOT EXISTS idx_mosque_tt_history_editor ON mosque_timetable_history (editor_id, created_at);
"""

_db_path = DEFAULT_DB_PATH
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
    """Create the tables (idempotent) and follow people whose app account changes or goes."""
    global _db_path
    _db_path = app.config.get('PLACES_DB', DEFAULT_DB_PATH)
    init_schema(_db_path)
    from app_accounts import on_user_moved, on_user_deleted
    on_user_moved(move_editor)
    on_user_deleted(forget_editor)


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


def parse_sessions(value):
    """Eid prayer times: a list of up to EID_SESSIONS_MAX distinct times, ascending."""
    if not isinstance(value, list):
        raise InputError('invalid_input', 'sessions: expected a list of HH:MM')
    times = sorted({t for t in (parse_time(v, 'sessions') for v in value) if t})
    if len(times) > EID_SESSIONS_MAX:
        raise InputError('too_many_sessions', f'At most {EID_SESSIONS_MAX} Eid prayers')
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
    {'timetable', 'eid'} for /api/place/<id> of a mosque; each None when
    nothing was entered. conn needs sqlite3.Row rows. Never raises: a
    missing table (init not run) must not take the detail page down.
    """
    today = today or _now().date()
    out = {'timetable': None, 'eid': None}
    try:
        out['timetable'] = _daily_out(conn.execute(
            "SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone(), today)
        out['eid'] = _eid_out(conn.execute(
            "SELECT * FROM mosque_eid_times WHERE place_id = ?", (place_id,)).fetchone(), today)
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


def write_eid(conn, place_id, sessions, user, now, source='public'):
    """The Eid prayer times, in the caller's transaction. Returns whether anything changed."""
    row = conn.execute("SELECT * FROM mosque_eid_times WHERE place_id = ?", (place_id,)).fetchone()
    old = _sessions(row) or None
    new = sessions or None
    if old == new:
        return False
    if new is None:
        conn.execute("DELETE FROM mosque_eid_times WHERE place_id = ?", (place_id,))
    else:
        conn.execute(
            "INSERT INTO mosque_eid_times (place_id, sessions, updated_at, updated_by, updated_by_name) "
            "VALUES (?, ?, ?, ?, ?) ON CONFLICT(place_id) DO UPDATE SET sessions = excluded.sessions, "
            "updated_at = excluded.updated_at, updated_by = excluded.updated_by, "
            "updated_by_name = excluded.updated_by_name",
            (place_id, json.dumps(new), _fmt(now), *_who(user)))
    _history(conn, place_id, 'eid', old, new, user, now, source)
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
        changed = write(conn, now)
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
    if not isinstance(body, dict) or 'sessions' not in body:
        return _err('invalid_input', 'Expected {"sessions": [...]}.')
    try:
        sessions = parse_sessions(body['sessions'])
    except InputError as e:
        return _err(e.code, e.message)

    def write(conn, now):
        changed = write_eid(conn, place_id, sessions, user, now)
        if changed:
            logger.info('[TIMETABLE] mosque %s Eid times changed by %s', place_id, user['id'])
        return changed

    return _save(place_id, user, write)


# ============================================
# PLACES AND PEOPLE GOING
# ============================================

_TABLES = ('mosque_timetables', 'mosque_eid_times', 'mosque_timetable_history')
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
