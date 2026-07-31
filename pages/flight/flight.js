// =====================================================================
// flight.js — Aviachipta narxlari (Seul ⇄ Toshkent)
// Kalendar → kun tanlash → o'sha kundagi barcha chiptalar.
// Barcha matn o'zbek tilida, fayl ichida (i18n ishlatilmaydi).
// =====================================================================

(function () {
  'use strict';

  // ---------------------------------------------------------------------
  // CONSTANTS & STATE
  // ---------------------------------------------------------------------

  const API_BASE = 'https://vegukin-api.duckdns.org/api/flights';

  const state = {
    trip: 'OW',
    origin: 'ICN',
    dest: 'TAS',
    routes: [],
    months: [],
    mi: 0,
    selected: null,
    loading: false,
  };

  const MONTHS_UZ = ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];

  const DOW_UZ = ['Yakshanba', 'Dushanba', 'Seshanba', 'Chorshanba',
    'Payshanba', 'Juma', 'Shanba'];

  const ROUTE_NAMES = {
    'ICN-TAS': 'Seul → Toshkent',
    'TAS-ICN': 'Toshkent → Seul',
  };

  // ---------------------------------------------------------------------
  // TELEGRAM WEBAPP
  // ---------------------------------------------------------------------

  const tg = window.Telegram?.WebApp;
  if (tg) {
    try { tg.ready(); } catch (e) {}
    try { tg.expand(); } catch (e) {}
    try { tg.disableVerticalSwipes(); } catch (e) {}
  }

  function haptic(kind) {
    try {
      if (!tg?.HapticFeedback) return;
      if (kind === 'select') tg.HapticFeedback.selectionChanged();
      else if (kind === 'ok') tg.HapticFeedback.notificationOccurred('success');
      else if (kind === 'err') tg.HapticFeedback.notificationOccurred('error');
      else tg.HapticFeedback.impactOccurred(kind || 'light');
    } catch (e) {}
  }

  // ---------------------------------------------------------------------
  // SMALL HELPERS
  // ---------------------------------------------------------------------

  function $(id) { return document.getElementById(id); }

  function esc(s) {
    if (s == null) return '';
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function logErr(msg, e) {
    try {
      if (window.Logger?.error) { window.Logger.error(msg, e); return; }
    } catch (_) {}
    console.error(msg, e);
  }

  // ---- formatting ----

  function won(n) {
    if (n == null) return '—';
    return new Intl.NumberFormat('en-US').format(Math.round(n)) + ' ₩';
  }

  function wonShort(n) {
    // Kalendar katakchasi tor — "406k" ko'rinishida.
    if (n == null) return '—';
    return Math.round(n / 1000) + 'k ₩';
  }

  function durLong(m) {
    if (m == null) return '—';
    const h = Math.floor(m / 60), mm = m % 60;
    return mm ? `${h} soat ${mm} daq` : `${h} soat`;
  }

  function durShort(m) {
    if (m == null) return '—';
    return `${Math.floor(m / 60)}s`;
  }

  function stopsUz(t) {
    if (t === 0) return "to'g'ridan";
    if (t == null) return '—';
    return `${t} transfer`;
  }

  function monthTitle(ym) {
    const [y, m] = ym.split('-').map(Number);
    return `${MONTHS_UZ[m - 1]} ${y}`;
  }

  function dateTitle(iso) {
    const d = new Date(iso + 'T00:00:00');
    return `${d.getDate()}-${MONTHS_UZ[d.getMonth()].toLowerCase()}, ${DOW_UZ[d.getDay()]}`;
  }

  // ---- toast ----

  let toastTimer;
  function toast(msg) {
    const el = $('toast');
    el.textContent = msg;
    el.hidden = false;
    requestAnimationFrame(() => el.classList.add('show'));
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      el.classList.remove('show');
      setTimeout(() => { el.hidden = true; }, 250);
    }, 3000);
  }

  // ---------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------

  async function api(path, params) {
    const qs = params ? '?' + params.toString() : '';
    let res, data;
    try {
      res = await fetch(API_BASE + path + qs, {
        headers: { 'Content-Type': 'application/json' },
      });
      data = await res.json().catch(() => ({}));
    } catch (e) {
      const err = new Error('network_error'); err.status = 0; throw err;
    }
    if (!res.ok) {
      const err = new Error(data.error || `http_${res.status}`);
      err.status = res.status; err.data = data; throw err;
    }
    return data;
  }

  function baseParams() {
    const p = new URLSearchParams({
      trip: state.trip, origin: state.origin, dest: state.dest,
    });
    if ($('fRisky').checked) p.set('exclude_risky', '1');
    const s = $('fStops').value;
    if (s !== '') p.set('max_stops', s);
    const dmax = $('fDur').value;
    if (dmax !== '') p.set('max_duration', dmax);
    return p;
  }

  function activeFilterCount() {
    let n = 0;
    if ($('fRisky').checked) n++;
    if ($('fStops').value !== '') n++;
    if ($('fDur').value !== '') n++;
    return n;
  }

  function syncFilterBadge() {
    const n = activeFilterCount();
    const badge = $('filterCount');
    badge.textContent = n;
    badge.hidden = n === 0;
  }

  // ---------------------------------------------------------------------
  // BOOT
  // ---------------------------------------------------------------------

  async function boot() {
    try {
      const d = await api('/routes');
      state.routes = d.routes || [];
    } catch (e) {
      logErr('routes failed', e);
      $('grid').innerHTML =
        '<p class="fl-empty" style="grid-column:1/-1">' +
        "Ma'lumot yuklanmadi. Internetni tekshirib, sahifani yangilang.</p>";
      $('stats').textContent = "Holat noma'lum.";
      return;
    }
    fillRoutes();
    loadHealth();
    await loadMonth();
  }

  function fillRoutes() {
    const sel = $('routeSel');
    const pairs = [...new Set(state.routes.map((r) => `${r.origin}-${r.dest}`))];
    sel.innerHTML = pairs.map((p) =>
      `<option value="${esc(p)}">${esc(ROUTE_NAMES[p] || p)}</option>`).join('');
    sel.value = `${state.origin}-${state.dest}`;
    syncMonths();
  }

  function syncMonths() {
    const r = state.routes.find((x) =>
      x.trip === state.trip && x.origin === state.origin && x.dest === state.dest);
    state.months = r ? r.months : [];
    if (state.mi >= state.months.length) state.mi = 0;
  }

  // ---------------------------------------------------------------------
  // CALENDAR
  // ---------------------------------------------------------------------

  async function loadMonth() {
    syncMonths();
    const grid = $('grid');
    const ym = state.months[state.mi];

    if (!ym) {
      $('monthTitle').textContent = '—';
      grid.innerHTML = '<p class="fl-empty" style="grid-column:1/-1">' +
        "Bu yo'nalish bo'yicha hozircha ma'lumot yo'q.</p>";
      return;
    }

    $('monthTitle').textContent = monthTitle(ym);
    $('prevM').disabled = state.mi === 0;
    $('nextM').disabled = state.mi >= state.months.length - 1;
    grid.innerHTML = '<div class="fl-skel" style="grid-column:1/-1"></div>';

    const p = baseParams();
    p.set('month', ym);

    let days = [];
    let filteredOut = new Set();
    try {
      const cal = await api('/calendar', p);
      days = cal.days || [];
      filteredOut = new Set(cal.dates_filtered_out || []);
    } catch (e) {
      logErr('calendar failed', e);
      grid.innerHTML = '<p class="fl-empty" style="grid-column:1/-1">' +
        'Kalendar yuklanmadi. Qaytadan urinib ko\'ring.</p>';
      return;
    }

    if (!days.length) {
      grid.innerHTML = '<p class="fl-empty" style="grid-column:1/-1">' +
        'Bu filtrlar bilan chipta topilmadi. Filtrlarni yumshatib ko\'ring.</p>';
      return;
    }

    const byDate = {};
    days.forEach((d) => { byDate[d.depart_date] = d; });

    const prices = days.map((d) => d.min_price).filter((v) => v != null);
    const lo = Math.min(...prices), hi = Math.max(...prices);
    const span = Math.max(1, hi - lo);

    const [y, m] = ym.split('-').map(Number);
    const offset = (new Date(y, m - 1, 1).getDay() + 6) % 7;   // dushanbadan
    const total = new Date(y, m, 0).getDate();
    const todayIso = new Date().toISOString().slice(0, 10);

    let html = '';
    for (let i = 0; i < offset; i++) html += '<div class="fl-day is-empty"></div>';

    for (let dd = 1; dd <= total; dd++) {
      const iso = `${ym}-${String(dd).padStart(2, '0')}`;
      const d = byDate[iso];

      if (!d || iso < todayIso) {
        const why = (iso >= todayIso && filteredOut.has(iso))
          ? '<span class="fl-daymeta">filtrga mos emas</span>' : '';
        html += `<div class="fl-day is-nodata"><span class="fl-daynum">${dd}</span>${why}</div>`;
        continue;
      }

      // Bar uzunligi = shu oy ichida qanchalik arzon (uzunroq = arzonroq)
      const pct = Math.round(100 - ((d.min_price - lo) / span) * 78);

      html += `
        <button type="button" class="fl-day lv-${esc(d.level)}" data-date="${iso}"
                aria-selected="${state.selected === iso}"
                aria-label="${dd}-${esc(MONTHS_UZ[m - 1].toLowerCase())}, ${won(d.min_price)}">
          <span class="fl-daynum">${dd}</span>
          ${d.min_direct != null ? '<span class="fl-daydot"></span>' : ''}
          <span class="fl-dayprice">${wonShort(d.min_price)}</span>
          <span class="fl-daymeta">${esc(d.best_airline_name || '')} · ${esc(durShort(d.best_duration))}</span>
          <span class="fl-bar"><i style="width:${pct}%"></i></span>
        </button>`;
    }

    grid.innerHTML = html;
    grid.querySelectorAll('.fl-day[data-date]').forEach((el) => {
      el.addEventListener('click', () => { haptic('select'); selectDate(el.dataset.date); });
    });

    if (state.selected && byDate[state.selected]) selectDate(state.selected, true);
  }

  // ---------------------------------------------------------------------
  // ONE DATE
  // ---------------------------------------------------------------------

  async function selectDate(iso, keepScroll) {
    state.selected = iso;
    document.querySelectorAll('.fl-day[data-date]').forEach((el) => {
      el.setAttribute('aria-selected', String(el.dataset.date === iso));
    });

    const box = $('results');
    box.innerHTML = '<p class="fl-empty">Yuklanmoqda…</p>';

    const p = baseParams();
    p.set('depart', iso);
    p.set('sort', $('fSort').value);
    p.set('limit', '40');

    let data;
    try {
      data = await api('/date', p);
    } catch (e) {
      logErr('date failed', e);
      box.innerHTML = '<p class="fl-empty">Chiptalar yuklanmadi. Qaytadan urinib ko\'ring.</p>';
      return;
    }

    if (!data.fares.length) {
      box.innerHTML = `<div class="fl-rhead"><h3 class="fl-rdate">${esc(dateTitle(iso))}</h3></div>
        <p class="fl-empty">Bu filtrlar bilan chipta yo'q. Transferlar sonini oshirib ko'ring.</p>`;
      return;
    }

    let ctx = '';
    if (data.context) {
      ctx = `<div><span class="fl-ctx">Oxirgi ${data.context.sample_days} kunning ` +
        `${data.context.percentile_cheaper_than}% idan arzon</span></div>`;
    }

    const rows = data.fares.map((f) => {
      const conf = f.confidence === 'stable'
        ? `<span class="fl-tag fl-tag-hold">${Math.round(f.held_hours)} soatdan beri shu narx</span>`
        : (f.confidence === 'new'
            ? '<span class="fl-tag fl-tag-new">yangi paydo bo\'ldi</span>' : '');
      const tags =
        (f.passes_quality ? '<span class="fl-tag fl-tag-good">qulay reys</span>' : '') +
        (f.is_risky_gate ? '<span class="fl-tag fl-tag-warn">self-transfer</span>' : '');
      const ret = f.return_date
        ? ` · qaytish ${esc(f.return_date)}` : '';
      return `
        <div class="fl-fare">
          <div class="fl-f-main">
            <div class="fl-f-line1">${esc(f.airline_name || f.airline || '—')}<span class="fl-fno">${esc(f.airline || '')}${esc(f.flight_number || '')}</span>${tags}</div>
            <div class="fl-f-line2">
              ${esc(stopsUz(f.transfers))} · ${esc(durLong(f.duration))}${ret}<br>
              ${conf}<br>
              Sotuvchi: ${esc(f.gate || '—')}${f.also_sold_by ? ` <span class="fl-more">+${f.also_sold_by} boshqa sotuvchi</span>` : ''}
            </div>
            <a class="fl-book" href="${esc(f.url)}" target="_blank" rel="noopener noreferrer">
              Aviasales'da jonli narxni ko'rish →
            </a>
          </div>
          <div class="fl-price">${won(f.price)}</div>
        </div>`;
    }).join('');

    box.innerHTML = `
      <div class="fl-rhead">
        <h3 class="fl-rdate">${esc(dateTitle(iso))}</h3>
        <div class="fl-rmeta">${data.count} ta variant</div>
        ${ctx}
      </div>${rows}
      <p class="fl-disclaimer">Narxlar Aviasales bazasidan olingan va taxminiy.
      Aniq va joriy narxni Aviasales sahifasida ko'rasiz.</p>`;

    if (!keepScroll) {
      box.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  // ---------------------------------------------------------------------
  // DATA STATUS
  // ---------------------------------------------------------------------

  async function loadHealth() {
    let h;
    try {
      h = await api('/health');
    } catch (e) {
      $('stats').textContent = "Holat noma'lum.";
      return;
    }
    const hb = h.heartbeat || {};
    const mins = hb.last_cycle_utc
      ? Math.round((Date.now() - new Date(hb.last_cycle_utc)) / 60000) : null;

    $('stats').innerHTML =
      `<span><b>${new Intl.NumberFormat('en-US').format(h.fares_current)}</b> chipta kuzatilmoqda</span>` +
      `<span>oxirgi yangilanish: <b>${mins == null ? '—' : mins + ' daq oldin'}</b></span>` +
      `<span>tarix: <b>${h.history_days}</b> / ${h.history_days_needed} kun</span>`;

    const pct = Math.min(100, Math.round(100 * h.history_days / h.history_days_needed));
    $('progBar').style.width = pct + '%';
    $('progNote').textContent = h.history_days >= h.history_days_needed
      ? "Tarix yetarli — endi har bir narx oxirgi 60 kun bilan solishtiriladi."
      : "Tarix to'lgach, har bir chipta \"oxirgi 60 kunning N% idan arzon\" degan baho oladi " +
        "va narx tushganda bot o'zi xabar beradi.";
  }

  // ---------------------------------------------------------------------
  // EVENTS
  // ---------------------------------------------------------------------

  function setTrip(t) {
    if (state.trip === t) return;
    state.trip = t;
    state.mi = 0;
    state.selected = null;
    $('btnOW').setAttribute('aria-pressed', String(t === 'OW'));
    $('btnRT').setAttribute('aria-pressed', String(t === 'RT'));
    $('results').innerHTML =
      "<p class=\"fl-empty\">Kalendardan kunni tanlang — o'sha kundagi barcha chiptalar shu yerda ko'rinadi.</p>";
    haptic('select');
    loadMonth();
  }

  $('btnOW').addEventListener('click', () => setTrip('OW'));
  $('btnRT').addEventListener('click', () => setTrip('RT'));

  $('routeSel').addEventListener('change', (e) => {
    const [o, d] = e.target.value.split('-');
    state.origin = o; state.dest = d; state.mi = 0; state.selected = null;
    loadMonth();
  });

  $('prevM').addEventListener('click', () => {
    if (state.mi > 0) { state.mi--; haptic('light'); loadMonth(); }
  });

  $('nextM').addEventListener('click', () => {
    if (state.mi < state.months.length - 1) { state.mi++; haptic('light'); loadMonth(); }
  });

  $('filterToggle').addEventListener('click', () => {
    const panel = $('filterPanel');
    const open = panel.hidden;
    panel.hidden = !open;
    $('filterToggle').setAttribute('aria-expanded', String(open));
  });

  ['fRisky', 'fStops', 'fDur'].forEach((id) => {
    $(id).addEventListener('change', () => { syncFilterBadge(); loadMonth(); });
  });

  $('fSort').addEventListener('change', () => {
    if (state.selected) selectDate(state.selected, true);
  });

  $('filterReset').addEventListener('click', () => {
    $('fRisky').checked = false;
    $('fStops').value = '';
    $('fDur').value = '';
    syncFilterBadge();
    loadMonth();
  });

  // ---------------------------------------------------------------------

  boot();
})();
