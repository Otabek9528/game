"""Messages about prayer time changes: gathered, told once, to the right people."""
import json
import sqlite3
from datetime import datetime, timedelta

import pytest
from flask import Flask

import app_push
import mosque_timetable_api as mt
import place_notifications_api as pn

ALI = {'id': 111, 'username': 'ali'}           # edits
VALI = {'id': 222, 'username': 'vali'}         # edits too
T0 = datetime(2027, 2, 24, 14, 0, tzinfo=mt.KST)
DAILY = {'fajr': '06:00', 'dhuhr': '13:00', 'asr': '16:15', 'maghrib': '18:25', 'isha': '20:00', 'jumuah': '13:30'}


@pytest.fixture
def env(tmp_path, monkeypatch):
    db = str(tmp_path / 'main_db.sqlite')
    conn = sqlite3.connect(db)
    conn.execute('CREATE TABLE main_db (Building_type TEXT, Name TEXT, Unique_number TEXT, City_English TEXT, '
                 'Actual_address TEXT, Tel TEXT, Latitude REAL, Longitude REAL)')
    conn.executemany('INSERT INTO main_db VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
        ('Masjid', 'Ansan Markaziy Masjidi', '1', 'Ansan', 'Wongok', '010', 37.3300, 126.8000),
        ('Masjid', 'Busan Al-Fatah', '4', 'Busan', 'Geumjeong', '', 35.2400, 129.0900)])
    conn.commit()
    conn.close()
    pn.init_schema(db)

    class Env:
        now = T0
        user = ALI
        mode = 'dry_run'
    monkeypatch.setattr(mt, '_now', lambda: Env.now)
    monkeypatch.setattr(mt, 'resolve_submitter', lambda allow_anonymous=False: (Env.user, None))

    def make(mode='dry_run'):
        app = Flask(__name__)
        app.secret_key = 'test'
        app.config.update(PLACES_DB=db, PLACE_NOTIFY_DB=db, TESTING=True, TIMETABLE_NOTIFY=mode,
                          PLACE_NOTIFY_WEBAPP_URL='https://example.pages.dev/pages/places/')
        app.register_blueprint(mt.bp)
        mt.init_mosque_timetables(app)
        return app
    Env.make = staticmethod(make)
    Env.db = db
    Env.app = make()
    Env.client = Env.app.test_client()

    # Who listens: 501 watches the mosque; 502 has a 3 km area round it (mosques
    # ticked); 503's area is mosques-off; ali watches it too (he edits: not told).
    sql = sqlite3.connect(db)
    now = mt._fmt(T0)
    for uid, lang in ((501, 'uz'), (502, 'ru'), (503, 'en'), (111, 'uz'), (222, 'uz')):
        sql.execute("INSERT INTO notify_subscribers (tg_id, username, lang, active, created_at, updated_at) "
                    "VALUES (?, ?, ?, 1, ?, ?)", (uid, f'u{uid}', lang, now, now))
    for uid in (501, 111):
        sql.execute("INSERT INTO place_watches (tg_id, place_id, created_at) VALUES (?, 1, ?)", (uid, now))
    sql.execute("INSERT INTO area_watches (tg_id, source, label, lat, lon, radius_km, types, created_at, updated_at) "
                "VALUES (502, 'address', 'Ansan', 37.3310, 126.8010, 3, 'mosque,restaurant', ?, ?)", (now, now))
    sql.execute("INSERT INTO area_watches (tg_id, source, label, lat, lon, radius_km, types, created_at, updated_at) "
                "VALUES (503, 'address', 'Ansan', 37.3310, 126.8010, 3, 'restaurant', ?, ?)", (now, now))
    sql.commit()
    sql.close()
    return Env


def rows(env, sql, *args):
    conn = sqlite3.connect(env.db)
    conn.row_factory = sqlite3.Row
    try:
        return [dict(r) for r in conn.execute(sql, args)]
    finally:
        conn.close()


def log(env):
    return rows(env, "SELECT * FROM timetable_notify_log ORDER BY id")


def flush(env, minutes_later):
    with env.app.app_context():
        return mt.flush_notices(env.now + timedelta(minutes=minutes_later))


def at(env, minutes):
    env.now = T0 + timedelta(minutes=minutes)


# ---------------------------------------------------------------- gathering

def test_told_once_after_ten_quiet_minutes(env):
    env.client.put('/api/place/1/timetable', json=DAILY)
    assert flush(env, 9) == 0 and log(env) == []
    assert flush(env, 10) == 1
    [entry] = log(env)
    assert entry['mode'] == 'dry_run' and entry['place_name'] == 'Ansan Markaziy Masjidi'
    # 501 (watcher) and 502 (area); not ali who made it, not 503 (no mosques in that area).
    assert entry['recipients'] == 2
    assert [c[0] for c in json.loads(entry['changes'])] == list(mt.PRAYERS)
    assert rows(env, "SELECT * FROM timetable_notify_pending") == []
    assert rows(env, "SELECT * FROM notify_outbox") == []        # dry run: nothing queued


def test_changes_are_gathered_into_one_net_message(env):
    env.client.put('/api/place/1/timetable', json=DAILY)
    at(env, 5)
    env.user = VALI
    env.client.put('/api/place/1/timetable', json={'dhuhr': '13:15'})
    at(env, 8)
    env.client.put('/api/place/1/eid', json={'fitr': ['07:00', '08:30']})
    assert flush(env, 9) == 0                                    # 8 + 9 < 8 + 10
    assert flush(env, 10) == 1
    [entry] = log(env)
    changes = {c[0]: c[2] for c in json.loads(entry['changes'])}
    assert changes['dhuhr'] == '13:15' and changes['fitr'] == ['07:00', '08:30']
    assert entry['recipients'] == 2                              # ali and vali both left out; 222 doesn't watch


def test_a_change_put_back_tells_nobody(env):
    env.client.put('/api/place/1/timetable', json=DAILY)
    flush(env, 10)
    at(env, 30)
    env.client.put('/api/place/1/timetable', json={'asr': '03:00'})
    at(env, 32)
    env.client.put('/api/place/1/timetable', json={'asr': '16:15'})
    flush(env, 10)
    assert [e['mode'] for e in log(env)] == ['dry_run', 'unchanged']
    assert log(env)[1]['recipients'] == 0


def test_steady_editing_still_goes_out_within_an_hour(env):
    for minute in range(0, 70, 5):
        at(env, minute)
        env.client.put('/api/place/1/timetable', json={'fajr': f'06:{minute:02d}'})
        if minute == 60:
            assert flush(env, 0) == 1                          # first change was 60 minutes ago
    assert log(env)[0]['mode'] == 'dry_run'


def test_at_most_three_a_day(env):
    for i in range(4):
        at(env, i * 30)
        env.client.put('/api/place/1/timetable', json={'fajr': f'06:0{i}'})
        flush(env, 10)
    assert [e['mode'] for e in log(env)] == ['dry_run', 'dry_run', 'dry_run', 'capped']
    at(env, 60 * 12)                                             # 02:00 next day, Korea time
    env.client.put('/api/place/1/timetable', json={'fajr': '06:09'})
    flush(env, 10)
    assert log(env)[-1]['mode'] == 'dry_run'


def test_admin_changes_are_told_too(env):
    with env.client.session_transaction() as s:
        s['admin_logged_in'] = True
    env.client.put('/api/admin/timetables/1', json={'adha': ['07:30']})
    flush(env, 10)
    [entry] = log(env)
    assert entry['recipients'] == 3                              # nobody to leave out: ali is told as well


# ---------------------------------------------------------------- sending

def test_on_queues_one_message_each_in_their_language(env):
    env.app = env.make('on')
    env.client = env.app.test_client()
    env.client.put('/api/place/1/timetable', json=DAILY)
    at(env, 1)
    env.client.put('/api/place/1/timetable', json={'dhuhr': '13:15'})
    flush(env, 10)
    out = {r['tg_id']: r for r in rows(env, "SELECT * FROM notify_outbox")}
    assert set(out) == {501, 502}
    uz, ru = out[501]['text'], out[502]['text']
    assert uz.startswith('<b>Ansan Markaziy Masjidi</b>\nNamoz vaqtlari yangilandi:\n')
    assert 'Peshin: — → <b>13:15</b>' in uz and 'Juma: — → <b>13:30</b>' in uz
    assert uz.endswith('<i>Siz bu joyni kuzatyapsiz</i>')
    assert 'Время намаза обновлено:' in ru and 'Зухр: — → <b>13:15</b>' in ru and 'Ваш район: Ansan · 3 км' in ru
    buttons = json.loads(out[501]['buttons'])['inline_keyboard'][0]
    assert 'places-detail.html?type=mosque&id=1' in buttons[0]['web_app']['url']
    assert log(env)[0]['mode'] == 'sent'
    title, body = app_push.html_to_message(uz)                   # what the app shows
    assert title == 'Ansan Markaziy Masjidi' and body.startswith('Namoz vaqtlari yangilandi:')


def test_eid_line_shows_the_new_times(env):
    text = mt.render_message('uz', 'M', [('fitr', [], ['07:00', '08:30']), ('adha', ['07:30'], [])])
    assert 'Ramazon hayiti: <b>07:00 · 08:30</b>' in text and 'Qurbon hayiti: <b>—</b>' in text
    assert 'Eid al-Fitr: <b>07:00 · 08:30</b>' in mt.render_message('en', 'M', [('fitr', [], ['07:00', '08:30'])])
    assert mt.render_message('uz', '<i>x</i>', []).startswith('<b>&lt;i&gt;x&lt;/i&gt;</b>')


def test_off_gathers_nothing(env):
    env.app = env.make('off')
    env.client = env.app.test_client()
    env.client.put('/api/place/1/timetable', json=DAILY)
    assert rows(env, "SELECT * FROM timetable_notify_pending") == []
    assert flush(env, 10) == 0


# ---------------------------------------------------------------- switching it off

def test_switch_off_and_on(env):
    env.user = {'id': 501, 'username': 'u501'}
    assert env.client.get('/api/notify/timetable-updates').get_json()['on'] is True
    assert env.client.put('/api/notify/timetable-updates', json={'on': False}).get_json()['on'] is False
    assert env.client.put('/api/notify/timetable-updates', json={'on': 'no'}).status_code == 400
    env.user = ALI
    env.client.put('/api/place/1/timetable', json=DAILY)
    flush(env, 10)
    assert log(env)[0]['recipients'] == 1                        # only 502 now
    env.user = {'id': 501, 'username': 'u501'}
    assert env.client.put('/api/notify/timetable-updates', json={'on': True}).get_json()['on'] is True


def test_switch_for_someone_who_subscribes_to_nothing(env):
    env.user = {'id': 999}
    assert env.client.get('/api/notify/timetable-updates').get_json() == {'success': True, 'on': True}


# ---------------------------------------------------------------- panel and clean-up

def test_admin_sees_the_log_and_the_mode(env):
    env.client.put('/api/place/1/timetable', json=DAILY)
    at(env, 30)
    env.client.put('/api/place/4/timetable', json={'fajr': '05:00'})
    flush(env, 10)
    assert env.client.get('/api/admin/timetables/messages').status_code == 401
    with env.client.session_transaction() as s:
        s['admin_logged_in'] = True
    d = env.client.get('/api/admin/timetables/messages').get_json()
    assert d['mode'] == 'dry_run' and d['waiting'] == 0
    assert [m['placeName'] for m in d['messages']] == ['Busan Al-Fatah', 'Ansan Markaziy Masjidi']
    assert d['messages'][1]['changes'][0] == ['fajr', None, '06:00']


def test_waiting_changes_are_counted(env):
    env.client.put('/api/place/1/timetable', json=DAILY)
    with env.client.session_transaction() as s:
        s['admin_logged_in'] = True
    assert env.client.get('/api/admin/timetables/messages').get_json()['waiting'] == 1


def test_deleting_the_mosque_drops_what_is_waiting(env):
    env.client.put('/api/place/1/timetable', json=DAILY)
    conn = sqlite3.connect(env.db)
    mt.delete_place_timetable_rows(conn, 1)
    conn.commit()
    conn.close()
    assert flush(env, 10) == 0 and log(env) == []
