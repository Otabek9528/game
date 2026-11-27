"""
mosque_timetable_api.py
=======================
A mosque's congregation (iqamah) times and its Eid prayers, kept by the
community. Anyone signed in (the same sign-in as for reviews) can change them,
and the change shows at once: there is no approval step. Every save is kept in
mosque_timetable_history, so the admin can see who changed what and put an
earlier version back.

    PUT /api/place/<id>/timetable   {"fajr", "dhuhr", "asr", "maghrib", "isha", "jumuah"}
                                    each "HH:MM" (KST) or null to clear it
    PUT /api/place/<id>/eid         {"key": "fitr-1448", "sessions": ["07:00", ...], "date": "YYYY-MM-DD" | null}

A key left out of the body keeps what is there; null clears it. Both answer
with the mosque's `timetable` and `eid`, as GET /api/place/<id> now carries
them for mosques (timetable_info()).

Eid
---
Each Eid is one occurrence: the Ramadan Eid ('fitr') or Eid al-Adha ('adha')
of one Hijri year, keyed "fitr-1448". Times belong to an occurrence, so last
year's are never shown as this year's; the edit sheet only offers them to copy.

The page always shows the next occurrence. EID_DATES holds each one's expected
date (the Umm al-Qura calendar, as Gregorian dates). Nobody has to enter a
date: an editor may move it up to EID_DATE_SHIFT_DAYS days when the community
announces another day, and until then it is shown as approximate. An
occurrence stays the current one until EID_SHOWN_DAYS_AFTER days after its
date, so a date one day off never hides the times on the real day; then the
next one takes its place. The Hijri year is only a key: nothing shows it.

Who edited is for the admin only: the public answers carry the date of the
last change, never a name or id.

Configuration: app.config["PLACES_DB"] (main_db.sqlite), as places_public_api.py.
"""

import json
import logging
import re
import sqlite3
from datetime import date, datetime, timedelta, timezone

from flask import Blueprint, jsonify, request

from place_submissions_api import resolve_submitter, submitter_name

logger = logging.getLogger(__name__)

bp = Blueprint('mosque_timetable', __name__)

DEFAULT_DB_PATH = '/home/ubuntu/vegukin_api/data/main_db.sqlite'
KST = timezone(timedelta(hours=9))
TS_FORMAT = '%Y-%m-%d %H:%M:%S'

MOSQUE_BUILDING_TYPE = 'Masjid'
PRAYERS = ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jumuah')
EID_KINDS = ('fitr', 'adha')
EID_SESSIONS_MAX = 3
EID_DATE_SHIFT_DAYS = 3
EID_SHOWN_DAYS_AFTER = 2
STALE_AFTER_DAYS = 60
# A brake on scripts, far above what one person does by hand; not moderation.
SAVES_PER_HOUR = 30

# (kind, Hijri year, expected Gregorian date): 1 Shawwal and 10 Dhu al-Hijjah
# in the Umm al-Qura calendar. 1455 has a second Ramadan Eid in 2033.
# Add the next years before the last one passes (a warning is logged when
# fewer than two are left).
EID_DATES = (
    ('fitr', 1447, '2026-03-20'), ('adha', 1447, '2026-05-27'),
    ('fitr', 1448, '2027-03-09'), ('adha', 1448, '2027-05-16'),
    ('fitr', 1449, '2028-02-26'), ('adha', 1449, '2028-05-05'),
    ('fitr', 1450, '2029-02-14'), ('adha', 1450, '2029-04-24'),
    ('fitr', 1451, '2030-02-04'), ('adha', 1451, '2030-04-13'),
    ('fitr', 1452, '2031-01-24'), ('adha', 1452, '2031-04-02'),
    ('fitr', 1453, '2032-01-14'), ('adha', 1453, '2032-03-22'),
    ('fitr', 1454, '2033-01-02'), ('adha', 1454, '2033-03-11'),
    ('fitr', 1455, '2033-12-23'), ('adha', 1455, '2034-03-01'),
    ('fitr', 1456, '2034-12-12'), ('adha', 1456, '2035-02-18'),
    ('fitr', 1457, '2035-12-01'), ('adha', 1457, '2036-02-07'),
)

OCCURRENCES = tuple(
    {'key': f'{kind}-{year}', 'eid': kind, 'hijri_year': year, 'expected': date.fromisoformat(day)}
    for kind, year, day in sorted(EID_DATES, key=lambda r: r[2]))

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

CREATE TABLE IF NOT EXISTS mosque_eid (
    place_id         INTEGER NOT NULL,
    eid              TEXT NOT NULL CHECK (eid IN ('fitr', 'adha')),
    hijri_year       INTEGER NOT NULL,
    date             TEXT,               -- set by an editor; NULL: the expected date
    sessions         TEXT NOT NULL,      -- JSON list of "HH:MM", ascending, at most 3
    updated_at       TEXT NOT NULL,
    updated_by       INTEGER,
    updated_by_name  TEXT,
    PRIMARY KEY (place_id, eid, hijri_year)
);

-- Every save: what the section held before and after (JSON; NULL = empty).
CREATE TABLE IF NOT EXISTS mosque_timetable_history (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id         INTEGER NOT NULL,
    section          TEXT NOT NULL CHECK (section IN ('daily', 'eid')),
    eid_key          TEXT,
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


def _err(code, message, status=400, **extra):
    payload = {'success': False, 'code': code, 'error': message}
    payload.update(extra)
    return jsonify(payload), status


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
    left = [o for o in OCCURRENCES if o['expected'] >= _now().date()]
    if len(left) < 2:
        logger.warning('[TIMETABLE] EID_DATES has %d Eid(s) left: add the next years', len(left))


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
    if value is None:
        return []
    if not isinstance(value, list):
        raise InputError('invalid_input', 'sessions: expected a list of HH:MM')
    times = sorted({t for t in (parse_time(v, 'sessions') for v in value) if t})
    if len(times) > EID_SESSIONS_MAX:
        raise InputError('too_many_sessions', f'At most {EID_SESSIONS_MAX} Eid prayers')
    return times


def parse_eid_date(value, occurrence):
    """The day an editor set, within EID_DATE_SHIFT_DAYS of the expected one; None clears it."""
    if value is None or value == '':
        return None
    try:
        day = date.fromisoformat(str(value).strip())
    except ValueError:
        raise InputError('invalid_date', 'date: expected YYYY-MM-DD')
    if abs((day - occurrence['expected']).days) > EID_DATE_SHIFT_DAYS:
        raise InputError('date_out_of_range',
                         f'date: within {EID_DATE_SHIFT_DAYS} days of {occurrence["expected"].isoformat()}')
    return day.isoformat()


def _sessions(row):
    if not row:
        return []
    try:
        return [t for t in json.loads(row['sessions'] or '[]') if isinstance(t, str)]
    except ValueError:
        return []


def _day(ts):
    """The KST date of a stored timestamp."""
    return datetime.strptime(ts, TS_FORMAT).date()


# ============================================
# WHICH EID
# ============================================

def current_eid(today, dates=None):
    """
    (occurrence, its date) the page shows on `today`, or (None, None) past the
    end of EID_DATES. dates: {key: date} an editor set for this mosque.
    """
    dates = dates or {}
    for occ in OCCURRENCES:
        day = dates.get(occ['key']) or occ['expected']
        if today <= day + timedelta(days=EID_SHOWN_DAYS_AFTER):
            return occ, day
    return None, None


def _eid_rows(conn, place_id):
    return {f"{r['eid']}-{r['hijri_year']}": r
            for r in conn.execute("SELECT * FROM mosque_eid WHERE place_id = ?", (place_id,))}


def _set_dates(rows):
    return {key: date.fromisoformat(r['date']) for key, r in rows.items() if r['date']}


# ============================================
# WHAT THE PAGE GETS
# ============================================

def _daily_out(row, today):
    if not row or all(row[p] is None for p in PRAYERS):
        return None
    updated = _day(row['updated_at'])
    out = {p: row[p] for p in PRAYERS}
    out['updatedAt'] = updated.isoformat()
    out['stale'] = (today - updated).days > STALE_AFTER_DAYS
    return out


def _eid_out(rows, today):
    occ, day = current_eid(today, _set_dates(rows))
    if not occ:
        return None
    row = rows.get(occ['key'])
    previous = rows.get(f"{occ['eid']}-{occ['hijri_year'] - 1}")
    return {
        'key': occ['key'],
        'eid': occ['eid'],
        'year': day.year,
        'date': day.isoformat(),
        'expectedDate': occ['expected'].isoformat(),
        'approximate': not (row and row['date']),
        'sessions': _sessions(row),
        'updatedAt': _day(row['updated_at']).isoformat() if row else None,
        # Only for the edit sheet's "last year" shortcut; never shown as current.
        'lastYear': _sessions(previous) or None,
    }


def timetable_info(conn, place_id, today=None):
    """
    {'timetable', 'eid'} for /api/place/<id> of a mosque. conn needs
    sqlite3.Row rows. Never raises: a missing table (init not run) must not
    take the detail page down.
    """
    today = today or _now().date()
    daily, rows = None, {}
    try:
        daily = _daily_out(conn.execute("SELECT * FROM mosque_timetables WHERE place_id = ?",
                                        (place_id,)).fetchone(), today)
        rows = _eid_rows(conn, place_id)
    except sqlite3.Error as e:
        logger.warning(f'timetable_info({place_id}) failed: {e}')
    return {'timetable': daily, 'eid': _eid_out(rows, today)}


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


def _history(conn, place_id, section, eid_key, old, new, user, now, source='public'):
    conn.execute(
        "INSERT INTO mosque_timetable_history (place_id, section, eid_key, old_value, new_value, "
        "editor_id, editor_name, source, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (place_id, section, eid_key,
         json.dumps(old, ensure_ascii=False) if old is not None else None,
         json.dumps(new, ensure_ascii=False) if new is not None else None,
         int(user['id']) if user else None, submitter_name(user) if user else 'admin', source, _fmt(now)))


def _saved(conn, place_id, changed):
    out = {'success': True, 'changed': changed}
    out.update(timetable_info(conn, place_id))
    return jsonify(out)


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
            (place_id, *(new[p] for p in PRAYERS), _fmt(now),
             int(user['id']) if user else None, submitter_name(user) if user else 'admin'))
    _history(conn, place_id, 'daily', None, old, new, user, now, source)
    return True


def write_eid(conn, place_id, occurrence, new, user, now, source='public'):
    """
    The Eid occurrence's date and sessions, in the caller's transaction.
    new: {'date': "YYYY-MM-DD"|None, 'sessions': [...]}. Returns whether
    anything changed.
    """
    key = occurrence['key']
    row = conn.execute("SELECT * FROM mosque_eid WHERE place_id = ? AND eid = ? AND hijri_year = ?",
                       (place_id, occurrence['eid'], occurrence['hijri_year'])).fetchone()
    old = {'date': row['date'], 'sessions': _sessions(row)} if row else None
    new = new if (new['date'] or new['sessions']) else None
    if old == new:
        return False
    if new is None:
        conn.execute("DELETE FROM mosque_eid WHERE place_id = ? AND eid = ? AND hijri_year = ?",
                     (place_id, occurrence['eid'], occurrence['hijri_year']))
    else:
        conn.execute(
            "INSERT INTO mosque_eid (place_id, eid, hijri_year, date, sessions, updated_at, updated_by, "
            "updated_by_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?) "
            "ON CONFLICT(place_id, eid, hijri_year) DO UPDATE SET date = excluded.date, "
            "sessions = excluded.sessions, updated_at = excluded.updated_at, "
            "updated_by = excluded.updated_by, updated_by_name = excluded.updated_by_name",
            (place_id, occurrence['eid'], occurrence['hijri_year'], new['date'],
             json.dumps(new['sessions']), _fmt(now),
             int(user['id']) if user else None, submitter_name(user) if user else 'admin'))
    _history(conn, place_id, 'eid', key, old, new, user, now, source)
    return True


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

    now = _now()
    conn = _db()
    conn.isolation_level = None          # BEGIN IMMEDIATE / COMMIT by hand
    try:
        refused = _begin_edit(conn, place_id, int(user['id']), now)
        if refused:
            conn.execute('ROLLBACK')
            return refused
        row = conn.execute("SELECT * FROM mosque_timetables WHERE place_id = ?", (place_id,)).fetchone()
        new = {p: given[p] if p in given else (row[p] if row else None) for p in PRAYERS}
        changed = write_daily(conn, place_id, new, user, now)
        conn.execute('COMMIT')
        if changed:
            logger.info('[TIMETABLE] mosque %s daily times changed by %s', place_id, user['id'])
        return _saved(conn, place_id, changed)
    except sqlite3.Error:
        if conn.in_transaction:
            conn.execute('ROLLBACK')
        logger.exception('Timetable save for place %s failed', place_id)
        return _err('server_error', 'Could not save the times.', 500)
    finally:
        conn.close()


@bp.route('/api/place/<int:place_id>/eid', methods=['PUT'])
def put_eid(place_id):
    user, error = _editor()
    if error:
        return error
    body = request.get_json(silent=True)
    if not isinstance(body, dict) or not body.get('key'):
        return _err('invalid_input', 'Expected a JSON object with the Eid key.')

    now = _now()
    conn = _db()
    conn.isolation_level = None
    try:
        refused = _begin_edit(conn, place_id, int(user['id']), now)
        if refused:
            conn.execute('ROLLBACK')
            return refused
        rows = _eid_rows(conn, place_id)
        occ, _ = current_eid(now.date(), _set_dates(rows))
        if not occ or body['key'] != occ['key']:
            # The page was open across the change to the next Eid: it reloads.
            conn.execute('ROLLBACK')
            return _err('eid_changed', 'This Eid has passed. Reload to see the next one.', 409,
                        current=occ['key'] if occ else None)
        row = rows.get(occ['key'])
        try:
            sessions = parse_sessions(body['sessions']) if 'sessions' in body else _sessions(row)
            day = parse_eid_date(body['date'], occ) if 'date' in body else (row['date'] if row else None)
        except InputError as e:
            conn.execute('ROLLBACK')
            return _err(e.code, e.message)
        changed = write_eid(conn, place_id, occ, {'date': day, 'sessions': sessions}, user, now)
        conn.execute('COMMIT')
        if changed:
            logger.info('[TIMETABLE] mosque %s %s changed by %s', place_id, occ['key'], user['id'])
        return _saved(conn, place_id, changed)
    except sqlite3.Error:
        if conn.in_transaction:
            conn.execute('ROLLBACK')
        logger.exception('Eid save for place %s failed', place_id)
        return _err('server_error', 'Could not save the Eid times.', 500)
    finally:
        conn.close()


# ============================================
# PLACES AND PEOPLE GOING
# ============================================

def delete_place_timetable_rows(conn, place_id):
    """
    Everything kept for this place, inside the caller's delete transaction.
    Unique_number is reused (the panel assigns max+1): rows left behind would
    show a deleted mosque's times on a future place.
    """
    deleted = 0
    for table in ('mosque_timetables', 'mosque_eid', 'mosque_timetable_history'):
        try:
            deleted += conn.execute(f"DELETE FROM {table} WHERE place_id = ?", (place_id,)).rowcount
        except sqlite3.OperationalError:
            pass               # init not run yet
    return deleted


_EDITOR_COLUMNS = (('mosque_timetables', 'updated_by', 'updated_by_name'),
                   ('mosque_eid', 'updated_by', 'updated_by_name'),
                   ('mosque_timetable_history', 'editor_id', 'editor_name'))


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
