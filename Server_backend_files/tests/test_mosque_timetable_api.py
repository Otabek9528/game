import json
import sqlite3
from datetime import date, datetime, timedelta

import pytest
from flask import Flask

import mosque_timetable_api as mt

ALI = {'id': 111, 'username': 'ali', 'first_name': 'Ali'}
VALI = {'id': 222, 'first_name': 'Vali'}
MOSQUE, RESTAURANT, MISSING = 1, 2, 99


@pytest.fixture
def db(tmp_path):
    path = str(tmp_path / 'main_db.sqlite')
    conn = sqlite3.connect(path)
    # The live table's relevant columns: Unique_number is TEXT there.
    conn.execute('CREATE TABLE main_db (Building_type TEXT, Name TEXT, Unique_number TEXT)')
    conn.executemany('INSERT INTO main_db VALUES (?, ?, ?)',
                     [('Masjid', 'Ansan Markaziy Masjidi', '1'), ('Oshxona', 'Somsa', '2')])
    conn.commit()
    conn.close()
    return path


@pytest.fixture
def clock(monkeypatch):
    """The KST "now" the module sees; set clock.now to move it."""
    class Clock:
        now = datetime(2026, 11, 27, 12, 0, tzinfo=mt.KST)
    monkeypatch.setattr(mt, '_now', lambda: Clock.now)
    return Clock


@pytest.fixture
def who(monkeypatch):
    """Who is signed in; who.user = None for nobody."""
    class Who:
        user = ALI
    def resolve():
        if Who.user is None:
            return None, ('sign_in_required', 'Please sign in first.')
        return Who.user, None
    monkeypatch.setattr(mt, 'resolve_submitter', resolve)
    return Who


@pytest.fixture
def client(db, clock, who):
    app = Flask(__name__)
    app.config['PLACES_DB'] = db
    app.register_blueprint(mt.bp)
    mt.init_mosque_timetables(app)
    return app.test_client()


def info(db, place_id=MOSQUE, today=None):
    conn = sqlite3.connect(db)
    conn.row_factory = sqlite3.Row
    try:
        return mt.timetable_info(conn, place_id, today)
    finally:
        conn.close()


def history(db):
    conn = sqlite3.connect(db)
    conn.row_factory = sqlite3.Row
    try:
        return [dict(r) for r in conn.execute('SELECT * FROM mosque_timetable_history ORDER BY id')]
    finally:
        conn.close()


DAILY = {'fajr': '06:00', 'dhuhr': '13:00', 'asr': '16:15', 'maghrib': '18:25', 'isha': '20:00', 'jumuah': '13:30'}


# ---------------------------------------------------------------- Eid dates

def test_eid_dates_are_in_order_and_unique():
    days = [o['expected'] for o in mt.OCCURRENCES]
    assert days == sorted(days)
    assert len({o['key'] for o in mt.OCCURRENCES}) == len(mt.OCCURRENCES)
    for kind, year, _ in mt.EID_DATES:
        assert kind in mt.EID_KINDS and 1447 <= year


def test_eid_dates_spacing_matches_the_lunar_year():
    by_key = {o['key']: o['expected'] for o in mt.OCCURRENCES}
    for kind in mt.EID_KINDS:
        years = sorted(y for k, y, _ in mt.EID_DATES if k == kind)
        for a, b in zip(years, years[1:]):
            gap = (by_key[f'{kind}-{b}'] - by_key[f'{kind}-{a}']).days
            assert 353 <= gap <= 356, (kind, a, b, gap)
    for year in {y for _, y, _ in mt.EID_DATES}:
        # 1 Shawwal to 10 Dhu al-Hijjah: two months of 29-30 days, plus 9.
        assert 67 <= (by_key[f'adha-{year}'] - by_key[f'fitr-{year}']).days <= 69


def test_current_eid_today_is_ramadan_eid_2027():
    occ, day = mt.current_eid(date(2026, 11, 27))
    assert occ['key'] == 'fitr-1448' and day == date(2027, 3, 9)


def test_current_eid_stays_two_days_after_then_moves_on():
    assert mt.current_eid(date(2027, 3, 11))[0]['key'] == 'fitr-1448'
    assert mt.current_eid(date(2027, 3, 12))[0]['key'] == 'adha-1448'


def test_current_eid_follows_a_date_set_by_an_editor():
    dates = {'fitr-1448': date(2027, 3, 10)}
    assert mt.current_eid(date(2027, 3, 12), dates)[0]['key'] == 'fitr-1448'
    assert mt.current_eid(date(2027, 3, 13), dates)[0]['key'] == 'adha-1448'


def test_current_eid_past_the_table_is_none():
    assert mt.current_eid(date(2040, 1, 1)) == (None, None)


# ---------------------------------------------------------------- values

@pytest.mark.parametrize('raw,out', [('06:00', '06:00'), ('6:05', '06:05'), (' 23:59 ', '23:59'),
                                     (None, None), ('', None)])
def test_parse_time_accepts(raw, out):
    assert mt.parse_time(raw, 'fajr') == out


@pytest.mark.parametrize('raw', ['24:00', '12:60', '1200', 'noon', '12:5', 12])
def test_parse_time_refuses(raw):
    with pytest.raises(mt.InputError):
        mt.parse_time(raw, 'fajr')


def test_parse_sessions_sorts_dedupes_and_caps():
    assert mt.parse_sessions(['10:00', '07:00', '07:00', '']) == ['07:00', '10:00']
    with pytest.raises(mt.InputError) as e:
        mt.parse_sessions(['07:00', '08:00', '09:00', '10:00'])
    assert e.value.code == 'too_many_sessions'
    with pytest.raises(mt.InputError):
        mt.parse_sessions('07:00')


# ---------------------------------------------------------------- reading

def test_a_mosque_with_nothing_still_has_the_next_eid(client, db):
    out = info(db)
    assert out['timetable'] is None
    assert out['eid'] == {'key': 'fitr-1448', 'eid': 'fitr', 'year': 2027, 'date': '2027-03-09',
                          'expectedDate': '2027-03-09', 'approximate': True, 'sessions': [],
                          'updatedAt': None, 'lastYear': None}


def test_info_without_tables_does_not_raise(db):
    out = info(db)                      # init never ran on this database
    assert out['timetable'] is None and out['eid']['key']


# ---------------------------------------------------------------- daily times

def test_save_daily_times(client, db):
    r = client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    assert r.status_code == 200
    body = r.get_json()
    assert body['changed'] is True
    assert body['timetable'] == {**DAILY, 'updatedAt': '2026-11-27', 'stale': False}
    assert info(db)['timetable']['maghrib'] == '18:25'
    [h] = history(db)
    assert h['section'] == 'daily' and h['old_value'] is None
    assert json.loads(h['new_value']) == DAILY
    assert h['editor_id'] == 111 and h['editor_name'] == 'ali' and h['source'] == 'public'


def test_signed_out_cannot_save(client, who):
    who.user = None
    r = client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    assert r.status_code == 401 and r.get_json()['code'] == 'sign_in_required'


def test_only_mosques(client):
    assert client.put(f'/api/place/{RESTAURANT}/timetable', json=DAILY).get_json()['code'] == 'not_a_mosque'
    assert client.put(f'/api/place/{MISSING}/timetable', json=DAILY).status_code == 404


def test_bad_time_is_refused_and_nothing_saved(client, db):
    r = client.put(f'/api/place/{MOSQUE}/timetable', json={**DAILY, 'asr': '25:00'})
    assert r.status_code == 400 and r.get_json()['code'] == 'invalid_time'
    assert info(db)['timetable'] is None and history(db) == []


def test_left_out_keeps_null_clears(client, db):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    client.put(f'/api/place/{MOSQUE}/timetable', json={'asr': '16:30', 'jumuah': None})
    t = info(db)['timetable']
    assert t['asr'] == '16:30' and t['jumuah'] is None and t['fajr'] == '06:00'


def test_same_values_change_nothing(client, db):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    r = client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    assert r.get_json()['changed'] is False
    assert len(history(db)) == 1


def test_clearing_every_time_removes_the_timetable(client, db):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    client.put(f'/api/place/{MOSQUE}/timetable', json={p: None for p in mt.PRAYERS})
    assert info(db)['timetable'] is None
    assert history(db)[-1]['new_value'] is None


def test_last_editor_and_history_follow_each_save(client, db, who):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    who.user = VALI
    client.put(f'/api/place/{MOSQUE}/timetable', json={'dhuhr': '13:15'})
    h = history(db)
    assert [x['editor_name'] for x in h] == ['ali', 'Vali']
    assert json.loads(h[1]['old_value'])['dhuhr'] == '13:00'


def test_stale_after_60_days(client, db, clock):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    assert info(db, today=date(2027, 1, 26))['timetable']['stale'] is False   # 60 days
    assert info(db, today=date(2027, 1, 27))['timetable']['stale'] is True    # 61 days


def test_flood_brake(client, monkeypatch):
    monkeypatch.setattr(mt, 'SAVES_PER_HOUR', 2)
    client.put(f'/api/place/{MOSQUE}/timetable', json={'fajr': '06:00'})
    client.put(f'/api/place/{MOSQUE}/timetable', json={'fajr': '06:05'})
    r = client.put(f'/api/place/{MOSQUE}/timetable', json={'fajr': '06:10'})
    assert r.status_code == 429 and r.get_json()['code'] == 'too_many_edits'


# ---------------------------------------------------------------- Eid

def test_save_eid_sessions(client, db):
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'sessions': ['08:30', '07:00']})
    assert r.status_code == 200
    eid = r.get_json()['eid']
    assert eid['sessions'] == ['07:00', '08:30'] and eid['approximate'] is True
    assert eid['updatedAt'] == '2026-11-27'


def test_eid_date_set_by_an_editor(client, db):
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'date': '2027-03-10'})
    eid = r.get_json()['eid']
    assert eid['date'] == '2027-03-10' and eid['expectedDate'] == '2027-03-09'
    assert eid['approximate'] is False
    # Left out next time: kept.
    eid = client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'sessions': ['07:00']}).get_json()['eid']
    assert eid['date'] == '2027-03-10' and eid['sessions'] == ['07:00']


def test_eid_date_too_far_is_refused(client):
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'date': '2027-03-13'})
    assert r.status_code == 400 and r.get_json()['code'] == 'date_out_of_range'


def test_only_the_current_eid_can_be_edited(client):
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'adha-1448', 'sessions': ['07:00']})
    assert r.status_code == 409
    assert r.get_json()['code'] == 'eid_changed' and r.get_json()['current'] == 'fitr-1448'


def test_last_years_times_are_offered_never_shown(client, db, clock):
    clock.now = datetime(2026, 3, 1, 9, 0, tzinfo=mt.KST)
    client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1447', 'sessions': ['07:00', '09:00']})
    clock.now = datetime(2026, 11, 27, 9, 0, tzinfo=mt.KST)
    eid = info(db, today=date(2026, 11, 27))['eid']
    assert eid['key'] == 'fitr-1448'
    assert eid['sessions'] == [] and eid['lastYear'] == ['07:00', '09:00']


def test_after_eid_the_next_one_shows_empty(client, db):
    client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'sessions': ['07:00']})
    eid = info(db, today=date(2027, 3, 12))['eid']
    assert eid['key'] == 'adha-1448' and eid['sessions'] == [] and eid['approximate'] is True


def test_clearing_the_eid_removes_its_row(client, db):
    client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'sessions': ['07:00']})
    client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'sessions': []})
    assert info(db)['eid']['updatedAt'] is None
    assert history(db)[-1]['eid_key'] == 'fitr-1448' and history(db)[-1]['new_value'] is None


# ---------------------------------------------------------------- places and people going

def test_deleting_the_place_removes_every_row(client, db):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    client.put(f'/api/place/{MOSQUE}/eid', json={'key': 'fitr-1448', 'sessions': ['07:00']})
    conn = sqlite3.connect(db)
    assert mt.delete_place_timetable_rows(conn, MOSQUE) == 4     # daily, eid, 2 history
    conn.commit()
    conn.close()
    assert info(db) == {'timetable': None, 'eid': info(db)['eid']}
    assert info(db)['eid']['sessions'] == [] and history(db) == []


def test_delete_cascade_without_tables_does_not_raise(db):
    conn = sqlite3.connect(db)
    assert mt.delete_place_timetable_rows(conn, MOSQUE) == 0
    conn.close()


def test_hooks_are_registered(client):
    import app_accounts
    assert mt.move_editor in app_accounts.movers and mt.forget_editor in app_accounts.deleters


def test_moved_and_deleted_accounts(client, db):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    mt.move_editor(111, -9000000000005)
    assert history(db)[0]['editor_id'] == -9000000000005
    mt.forget_editor(-9000000000005)
    h = history(db)[0]
    assert h['editor_id'] is None and h['editor_name'] is None
    assert info(db)['timetable']['fajr'] == '06:00'      # the times stay
