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

Configuration: app.config["PLACES_DB"] (main_db.sqlite), as places_public_api.py.
"""

import json
import logging
import re
import sqlite3
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
        try:
            changed = write(conn, now)
        except InputError as e:
            conn.execute('ROLLBACK')
            return _err(e.code, e.message)
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
