import json
import sqlite3
from datetime import date, datetime

import pytest
from flask import Flask

import mosque_timetable_api as mt

ALI = {'id': 111, 'username': 'ali', 'first_name': 'Ali'}
VALI = {'id': 222, 'first_name': 'Vali'}
MOSQUE, RESTAURANT, MISSING = 1, 2, 99
NO_EID = {'fitr': None, 'adha': None}


@pytest.fixture
def db(tmp_path):
    path = str(tmp_path / 'main_db.sqlite')
    conn = sqlite3.connect(path)
    # The live table's relevant columns: Unique_number is TEXT there.
    conn.execute('CREATE TABLE main_db (Building_type TEXT, Name TEXT, Unique_number TEXT, '
                 'City_English TEXT, Actual_address TEXT)')
    conn.executemany('INSERT INTO main_db VALUES (?, ?, ?, ?, ?)',
                     [('Masjid', 'Ansan Markaziy Masjidi', '1', 'Ansan', 'Wongok-dong'),
                      ('Oshxona', 'Somsa', '2', 'Ansan', ''),
                      ('Masjid', 'Seoul Central Mosque', '3', 'Seoul', 'Itaewon')])
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
    app.secret_key = 'test'
    app.config['TESTING'] = True                 # no background sender
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
    assert mt.parse_sessions(['10:00', '07:00', '07:00', ''], 'fitr') == ['07:00', '10:00']
    with pytest.raises(mt.InputError) as e:
        mt.parse_sessions(['07:00', '08:00', '09:00', '10:00'], 'fitr')
    assert e.value.code == 'too_many_sessions'
    with pytest.raises(mt.InputError):
        mt.parse_sessions('07:00', 'fitr')
    assert mt.parse_sessions([], 'adha') == []


# ---------------------------------------------------------------- reading

def test_a_mosque_with_nothing_has_neither(client, db):
    assert info(db) == {'timetable': None, 'eid': NO_EID}


def test_info_without_tables_does_not_raise(db):
    assert info(db) == {'timetable': None, 'eid': NO_EID}     # init never ran on this database


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

def test_save_both_eids(client, db):
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['08:30', '07:00'], 'adha': ['07:30']})
    assert r.status_code == 200
    assert r.get_json()['eid'] == {
        'fitr': {'sessions': ['07:00', '08:30'], 'updatedAt': '2026-11-27', 'stale': False},
        'adha': {'sessions': ['07:30'], 'updatedAt': '2026-11-27', 'stale': False}}
    assert [(h['section'], json.loads(h['new_value'])) for h in history(db)] == [
        ('fitr', ['07:00', '08:30']), ('adha', ['07:30'])]


def test_one_eid_left_out_is_kept_with_its_own_date(client, db, clock):
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00'], 'adha': ['07:30']})
    clock.now = datetime(2027, 5, 1, 9, 0, tzinfo=mt.KST)
    eid = client.put(f'/api/place/{MOSQUE}/eid', json={'adha': ['08:00']}).get_json()['eid']
    assert eid['fitr'] == {'sessions': ['07:00'], 'updatedAt': '2026-11-27', 'stale': True}
    assert eid['adha'] == {'sessions': ['08:00'], 'updatedAt': '2027-05-01', 'stale': False}


def test_eid_answer_has_no_date_beyond_last_updated(client):
    eid = client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00']}).get_json()['eid']
    assert set(eid) == {'fitr', 'adha'} and set(eid['fitr']) == {'sessions', 'updatedAt', 'stale'}
    assert eid['adha'] is None


def test_eid_needs_a_known_eid_and_valid_times(client):
    assert client.put(f'/api/place/{MOSQUE}/eid', json={}).get_json()['code'] == 'invalid_input'
    assert client.put(f'/api/place/{MOSQUE}/eid', json={'other': ['07:00']}).get_json()['code'] == 'invalid_input'
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00', '08:00', '09:00', '10:00']})
    assert r.status_code == 400 and r.get_json()['code'] == 'too_many_sessions'
    r = client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00'], 'adha': ['7am']})
    assert r.status_code == 400 and r.get_json()['code'] == 'invalid_time'


def test_bad_second_eid_saves_neither(client, db):
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00'], 'adha': ['7am']})
    assert info(db)['eid'] == NO_EID and history(db) == []


def test_eid_only_for_mosques_and_signed_in(client, who):
    assert client.put(f'/api/place/{RESTAURANT}/eid', json={'fitr': ['07:00']}).status_code == 400
    who.user = None
    assert client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00']}).status_code == 401


def test_eid_same_times_change_nothing(client, db):
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00']})
    assert client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00']}).get_json()['changed'] is False
    assert len(history(db)) == 1


def test_eid_stays_shown_and_goes_stale(client, db):
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00']})
    assert info(db, today=date(2027, 1, 26))['eid']['fitr']['stale'] is False
    later = info(db, today=date(2027, 11, 27))['eid']['fitr']
    assert later['sessions'] == ['07:00'] and later['stale'] is True


def test_clearing_one_eid_removes_only_its_row(client, db):
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00'], 'adha': ['07:30']})
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': []})
    eid = info(db)['eid']
    assert eid['fitr'] is None and eid['adha']['sessions'] == ['07:30']
    assert history(db)[-1]['section'] == 'fitr' and history(db)[-1]['new_value'] is None


# ---------------------------------------------------------------- places and people going

def test_deleting_the_place_removes_every_row(client, db):
    client.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    client.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00'], 'adha': ['07:30']})
    conn = sqlite3.connect(db)
    assert mt.delete_place_timetable_rows(conn, MOSQUE) == 7     # daily, 2 Eids, 3 history, 1 waiting message
    conn.commit()
    conn.close()
    assert info(db) == {'timetable': None, 'eid': NO_EID} and history(db) == []


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


# ---------------------------------------------------------------- admin

@pytest.fixture
def admin(client):
    with client.session_transaction() as s:
        s['admin_logged_in'] = True
    return client


def test_admin_needs_the_panel_login(client):
    assert client.get('/api/admin/timetables').status_code == 401
    assert client.put('/api/admin/timetables/1', json={'fitr': ['07:00']}).status_code == 401
    assert client.delete('/api/admin/timetables/1').status_code == 401
    assert client.get('/api/admin/timetables/1/history').status_code == 401
    assert client.post('/api/admin/timetables/history/1/restore').status_code == 401


def test_admin_lists_every_mosque_with_and_without(admin, who):
    admin.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    admin.put(f'/api/place/{MOSQUE}/eid', json={'adha': ['07:30']})
    rows = admin.get('/api/admin/timetables').get_json()['mosques']
    assert [m['id'] for m in rows] == [1, 3]                      # mosques only, by city
    ansan, seoul = rows
    assert ansan['timetable']['fajr'] == '06:00' and ansan['timetable']['updatedBy'] == 'ali'
    assert ansan['timetable']['updatedById'] == 111 and ansan['timetable']['updatedAt'] == '2026-11-27'
    assert ansan['eid']['fitr'] is None and ansan['eid']['adha']['sessions'] == ['07:30']
    assert ansan['edits'] == 2 and ansan['lastEditAt'].startswith('2026-11-27')
    assert seoul['timetable'] is None and seoul['eid'] == NO_EID and seoul['edits'] == 0


def test_admin_edit_is_saved_with_history(admin, db):
    r = admin.put('/api/admin/timetables/3', json={'daily': {'fajr': '6:10', 'jumuah': '13:00'}, 'fitr': ['08:00']})
    body = r.get_json()
    assert r.status_code == 200 and body['changed'] is True
    m = body['mosque']
    assert m['timetable']['fajr'] == '06:10' and m['timetable']['dhuhr'] is None
    assert m['timetable']['updatedBy'] == 'admin' and m['timetable']['updatedById'] is None
    assert m['eid']['fitr']['sessions'] == ['08:00']
    assert {(h['section'], h['source'], h['editor_name']) for h in history(db)} == {
        ('daily', 'admin', 'admin'), ('fitr', 'admin', 'admin')}


def test_admin_edit_refuses_bad_input_and_saves_nothing(admin, db):
    r = admin.put('/api/admin/timetables/3', json={'daily': {'fajr': '06:00'}, 'fitr': ['25:00']})
    assert r.status_code == 400 and r.get_json()['code'] == 'invalid_time'
    assert history(db) == []
    assert admin.put('/api/admin/timetables/2', json={'fitr': ['07:00']}).status_code == 404   # a restaurant
    assert admin.put('/api/admin/timetables/3', json={'daily': 'x'}).status_code == 400


def test_admin_clear_keeps_history(admin, db):
    admin.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    admin.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00'], 'adha': ['07:30']})
    m = admin.delete('/api/admin/timetables/1?section=fitr').get_json()['mosque']
    assert m['eid']['fitr'] is None and m['eid']['adha'] and m['timetable']
    m = admin.delete('/api/admin/timetables/1?section=all').get_json()['mosque']
    assert m['timetable'] is None and m['eid'] == NO_EID
    assert len(history(db)) == 6
    assert admin.delete('/api/admin/timetables/1?section=x').status_code == 400


def test_admin_history_newest_first_and_paged(admin, monkeypatch):
    monkeypatch.setattr(mt, 'HISTORY_PAGE', 2)
    for t in ('06:00', '06:05', '06:10'):
        admin.put(f'/api/place/{MOSQUE}/timetable', json={'fajr': t})
    page = admin.get('/api/admin/timetables/1/history').get_json()
    assert [h['new']['fajr'] for h in page['history']] == ['06:10', '06:05'] and page['more'] is True
    assert page['history'][0]['old']['fajr'] == '06:05' and page['history'][0]['editorName'] == 'ali'
    rest = admin.get(f"/api/admin/timetables/1/history?before={page['history'][-1]['id']}").get_json()
    assert [h['new']['fajr'] for h in rest['history']] == ['06:00'] and rest['more'] is False


def test_admin_restore_puts_back_the_version_before(admin, db, who):
    admin.put(f'/api/place/{MOSQUE}/timetable', json=DAILY)
    who.user = VALI
    admin.put(f'/api/place/{MOSQUE}/timetable', json={'dhuhr': '03:00', 'asr': None})   # vandalism
    bad = admin.get('/api/admin/timetables/1/history').get_json()['history'][0]
    m = admin.post(f"/api/admin/timetables/history/{bad['id']}/restore").get_json()['mosque']
    assert m['timetable']['dhuhr'] == '13:00' and m['timetable']['asr'] == '16:15'
    assert history(db)[-1]['source'] == 'admin'


def test_admin_restore_of_a_first_save_clears(admin):
    admin.put(f'/api/place/{MOSQUE}/eid', json={'fitr': ['07:00']})
    first = admin.get('/api/admin/timetables/1/history').get_json()['history'][0]
    m = admin.post(f"/api/admin/timetables/history/{first['id']}/restore").get_json()['mosque']
    assert m['eid']['fitr'] is None
    assert admin.post('/api/admin/timetables/history/999/restore').status_code == 404
