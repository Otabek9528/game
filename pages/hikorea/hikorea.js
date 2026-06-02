// =====================================================================
// hikorea.js — HiKorea Slot Watcher (redesigned frontend)
// Flow: home → booth → calendar (→ date detail sheet OR watch setup)
//                    → my watches
// =====================================================================

(function () {
  'use strict';

  // ---------------------------------------------------------------------
  // CONSTANTS & STATE
  // ---------------------------------------------------------------------

  const API_BASE = 'https://vegukin-api.duckdns.org/api/hikorea';

  const SECTIONS = [
    'home', 'by-address', 'booth', 'calendar', 'watch', 'watches',
  ];

  const state = {
    offices: [],
    provinces: [],
    selectedOffice: null,
    selectedDesk: null,
    deskSlots: null,     // cached slots payload for the current desk
    user: null,
    navStack: ['home'],
    sheetOpen: false,
    overlayOpen: false,
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
  if (tg?.initDataUnsafe?.user) {
    const u = tg.initDataUnsafe.user;
    state.user = { id: u.id, username: u.username || null, first_name: u.first_name || null };
  }

  // ---------------------------------------------------------------------
  // SMALL HELPERS
  // ---------------------------------------------------------------------

  function $(id)  { return document.getElementById(id); }
  function $$(s, root) { return Array.from((root || document).querySelectorAll(s)); }

  function haptic(kind) {
    try {
      if (!tg?.HapticFeedback) return;
      if (kind === 'select') tg.HapticFeedback.selectionChanged();
      else if (kind === 'ok')  tg.HapticFeedback.notificationOccurred('success');
      else if (kind === 'err') tg.HapticFeedback.notificationOccurred('error');
      else                     tg.HapticFeedback.impactOccurred(kind || 'light');
    } catch (e) {}
  }

  function esc(s) {
    if (s == null) return '';
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function t(key, fallback) {
    if (window.I18N) {
      const v = I18N.t(key);
      if (v && v !== key) return v;
    }
    return fallback;
  }

  // -- Date helpers --

  // i18n-aware day/month names. Browser locale can't be trusted (often
  // English even on Korean devices), so we pull from our own i18n dictionary
  // with toLocaleDateString as a last-ditch fallback.
  const DOW_KEYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  function fmtDowShort(date) {
    const key = 'hk.dow.' + DOW_KEYS[date.getDay()];
    return t(key, date.toLocaleDateString(undefined, { weekday: 'short' }));
  }
  function fmtDowFull(date) {
    const key = 'hk.dowFull.' + DOW_KEYS[date.getDay()];
    return t(key, date.toLocaleDateString(undefined, { weekday: 'long' }));
  }
  function fmtMonthFull(date) {
    const key = 'hk.month.' + (date.getMonth() + 1);
    return t(key, date.toLocaleDateString(undefined, { month: 'long' }));
  }
  function fmtMonthYear(date) {
    return fmtMonthFull(date) + ' ' + date.getFullYear();
  }
  // "2-Iyun" style — day + full localized month name with a hyphen.
  function fmtDayMonth(date) {
    return date.getDate() + '-' + fmtMonthFull(date);
  }

  function ymdToDate(ymd) {
    return new Date(+ymd.slice(0, 4), +ymd.slice(4, 6) - 1, +ymd.slice(6, 8));
  }

  function dateToYmd(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}${m}${day}`;
  }

  function dateToInputValue(d) {
    // YYYY-MM-DD for <input type="date">
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  function addDays(d, n) {
    const r = new Date(d);
    r.setDate(r.getDate() + n);
    return r;
  }

  function todayYmd() { return dateToYmd(new Date()); }

  function fmtLongDate(ymd) {
    const d = ymdToDate(ymd);
    return `${fmtDowFull(d)}, ${d.getDate()} ${fmtMonthFull(d)} ${d.getFullYear()}`;
  }

  function fmtShortDate(ymd) {
    return fmtDayMonth(ymdToDate(ymd));
  }

  function dowName(ymd) {
    return fmtDowFull(ymdToDate(ymd));
  }

  function monthLabel(y, m /* 0-indexed */) {
    return fmtMonthYear(new Date(y, m, 1));
  }

  function relativeTime(iso) {
    try {
      const then = new Date(iso).getTime();
      const diff = Math.max(0, Date.now() - then);
      const m = Math.floor(diff / 60000);
      if (m < 1) return t('hk.time.now', 'just now');
      if (m < 60) return `${m}m ${t('hk.time.ago', 'ago')}`;
      const h = Math.floor(m / 60);
      if (h < 24) return `${h}h ${t('hk.time.ago', 'ago')}`;
      return `${Math.floor(h / 24)}d ${t('hk.time.ago', 'ago')}`;
    } catch (e) { return ''; }
  }

  // ---------------------------------------------------------------------
  // TOAST
  // ---------------------------------------------------------------------

  let toastTimer = null;
  function toast(msg, kind) {
    const el = $('toast');
    el.textContent = msg;
    el.className = 'hk-toast';
    if (kind) el.classList.add(kind);
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

  async function api(path, opts) {
    opts = opts || {};
    const init = {
      method: opts.method || 'GET',
      headers: { 'Content-Type': 'application/json', ...(opts.headers || {}) },
    };
    if (opts.body) init.body = JSON.stringify(opts.body);
    let res, data;
    try {
      res = await fetch(API_BASE + path, init);
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

  // ---------------------------------------------------------------------
  // NAVIGATION (in-page sections)
  // ---------------------------------------------------------------------

  function showSection(name, opts) {
    opts = opts || {};
    SECTIONS.forEach((s) => {
      const el = $('section-' + s);
      if (el) el.hidden = (s !== name);
    });
    if (!opts.silent && state.navStack[state.navStack.length - 1] !== name) {
      state.navStack.push(name);
    }
    // The scroll container is .hk-container (it has overflow-y: auto),
    // not the window. Reset its scroll on every section change so the
    // user lands at the top of each new screen.
    const container = document.querySelector('.hk-container');
    if (container) container.scrollTop = 0;
    window.scrollTo(0, 0); // belt-and-suspenders for any cases where the
                           // document itself is the scroller (rare here).
  }

  function handleBack() {
    if (state.sheetOpen)   { closeSheet(); return; }
    if (state.overlayOpen) { closeOverlay(); return; }
    if (state.navStack.length > 1) {
      state.navStack.pop();
      showSection(state.navStack[state.navStack.length - 1], { silent: true });
      haptic('light');
    } else {
      window.location.href = '../../index.html';
    }
  }

  if (tg?.BackButton) {
    try { tg.BackButton.show(); tg.BackButton.onClick(handleBack); } catch (e) {}
  }

  // ---------------------------------------------------------------------
  // OFFICE CATALOG
  // ---------------------------------------------------------------------

  async function ensureOfficesLoaded() {
    if (state.offices.length > 0) return;
    try {
      const [oRes, pRes] = await Promise.all([
        api('/offices'),
        api('/provinces'),
      ]);
      state.offices = oRes.offices || [];
      state.provinces = pRes.provinces || [];
    } catch (e) {
      toast(t('hk.err.offices', "Couldn't load offices — try again"), 'error');
    }
  }

  // ---------------------------------------------------------------------
  // SECTION: HOME
  // ---------------------------------------------------------------------

  async function renderHome() {
    await ensureOfficesLoaded();
    renderOfficeList($('officeSearch').value || '');
    await refreshMyWatchesChip();
  }

  function renderOfficeList(filter) {
    const container = $('officeList');
    const needle = (filter || '').trim().toLowerCase();
    const rows = state.offices
      .filter((o) => {
        if (!needle) return true;
        const hay = [o.name_en, o.name_ko, o.short_code]
          .filter(Boolean).join(' ').toLowerCase();
        return hay.includes(needle);
      })
      .sort((a, b) => (a.name_en || '').localeCompare(b.name_en || ''));

    if (rows.length === 0) {
      container.innerHTML = `
        <div class="hk-list-empty">${esc(t('hk.home.noMatch',
          "No offices match. Try a different word, or use 'Find by address' above."))}</div>`;
      return;
    }

    container.innerHTML = rows.map((o) => {
      const n = (o.desks || []).length;
      const counter = n === 1
        ? t('hk.home.oneCounter', '1 counter')
        : `${n} ${t('hk.home.manyCounters', 'counters')}`;
      return `
        <button class="hk-list-item" data-office-id="${esc(o.office_id)}">
          <span class="hk-item-icon">🏢</span>
          <span class="hk-item-body">
            <span class="hk-item-title">${esc(o.name_en || o.name_ko)}</span>
            <span class="hk-item-sub">${esc(o.name_ko || '')} · ${esc(counter)}</span>
          </span>
          <span class="hk-item-arrow">→</span>
        </button>`;
    }).join('');

    $$('.hk-list-item', container).forEach((btn) => {
      btn.addEventListener('click', () => {
        const office = state.offices.find((o) => o.office_id === btn.dataset.officeId);
        if (office) selectOffice(office);
      });
    });
  }

  async function refreshMyWatchesChip() {
    if (!state.user) return;
    try {
      const data = await api(`/watches?telegram_user_id=${encodeURIComponent(state.user.id)}&status=active`);
      const count = (data.watches || []).length;
      $('myWatchesCount').textContent = String(count);
      $('myWatchesChip').hidden = count === 0;
    } catch (e) {
      $('myWatchesChip').hidden = true;
    }
  }

  // ---------------------------------------------------------------------
  // SECTION: BY-ADDRESS
  // ---------------------------------------------------------------------

  function renderProvinces() {
    const sel = $('provinceSelect');
    if (sel.options.length > 1) return;
    state.provinces.forEach((p) => {
      const opt = document.createElement('option');
      opt.value = p.ko;
      opt.textContent = `${p.ko} (${p.en})`;
      sel.appendChild(opt);
    });
  }

  async function doResolveOffice() {
    const province = $('provinceSelect').value;
    const address = $('addressInput').value.trim();
    const resultsEl = $('resolveResults');
    resultsEl.hidden = true;
    resultsEl.innerHTML = '';

    if (!province) {
      toast(t('hk.address.needProvince', 'Pick your province first'), 'error');
      return;
    }
    if (!address) {
      toast(t('hk.address.needAddress', 'Enter your address'), 'error');
      return;
    }

    try {
      const data = await api(
        `/resolve-office?province=${encodeURIComponent(province)}&address=${encodeURIComponent(address)}`,
      );
      const matches = data.matches || [];
      resultsEl.hidden = false;

      if (matches.length === 0) {
        resultsEl.innerHTML = `
          <div class="hk-list-empty">
            ${esc(t('hk.address.noMatch', "Couldn't find an office for that address. Try picking from the list on the home screen."))}
          </div>`;
        return;
      }

      const hint = matches.length === 1
        ? t('hk.address.foundOne', "Here's your office:")
        : t('hk.address.foundMany', 'Pick the one that matches:');

      resultsEl.innerHTML = `
        <p class="hk-resolve-hint">${esc(hint)}</p>
        ${matches.map((m) => `
          <button class="hk-list-item" data-office-id="${esc(m.office_id)}">
            <span class="hk-item-icon">📍</span>
            <span class="hk-item-body">
              <span class="hk-item-title">${esc(m.name_en)}</span>
              <span class="hk-item-sub">${esc(m.name_ko || '')} · ${esc(m.matched_district || '')}</span>
            </span>
            <span class="hk-item-arrow">→</span>
          </button>
        `).join('')}`;

      $$('.hk-list-item', resultsEl).forEach((btn) => {
        btn.addEventListener('click', () => {
          const office = state.offices.find((o) => o.office_id === btn.dataset.officeId);
          if (office) selectOffice(office);
        });
      });
    } catch (e) {
      toast(t('hk.err.resolve', "Couldn't look up office — try again"), 'error');
    }
  }

  // ---------------------------------------------------------------------
  // SECTION: BOOTH PICKER
  // ---------------------------------------------------------------------

  function selectOffice(office) {
    state.selectedOffice = office;
    haptic('select');
    // Skip the booth picker entirely when there's nothing to pick.
    // Saves a tap and removes a confusing "what counter?" decision for
    // people who don't know what booths are. They can still see/change
    // it on the calendar header.
    const desks = office.desks || [];
    if (desks.length === 1) {
      selectDesk(desks[0]);
      return;
    }
    enterBoothPicker();
  }

  function enterBoothPicker() {
    const o = state.selectedOffice;
    $('boothOfficeName').textContent = o.name_en;
    renderBoothList(o.desks || []);
    showSection('booth');
  }

  // Many booths are labelled "... AFTER 09:36" by HiKorea — that's their
  // internal jargon for the afternoon shift. Reframe in plain language.
  function prettifyBoothName(rawBooth) {
    if (!rawBooth) return null;
    let s = rawBooth;
    // Strip parenthetical dates like "(2023.10.14.~)"
    s = s.replace(/\s*\([\d.~\s]+\)\s*/g, ' ').trim();
    if (/AFTER\s*0?9:36/i.test(s)) {
      s = s.replace(/\(?\s*AFTER\s*0?9:36\s*\)?/i, '').trim();
      s = s.replace(/\s{2,}/g, ' ');
      return { primary: s, secondary: t('hk.booth.afternoon', 'Afternoon hours (after 09:36)') };
    }
    return { primary: s, secondary: null };
  }

  function renderBoothList(desks) {
    const container = $('boothList');
    if (!desks.length) {
      container.innerHTML = `
        <div class="hk-list-empty">${esc(t('hk.booth.none', 'No counters available for this office.'))}</div>`;
      return;
    }
    container.innerHTML = desks.map((d) => {
      const pretty = prettifyBoothName(d.booth) || { primary: 'Counter ' + d.desk_seq, secondary: null };
      const details = d.details || pretty.secondary || '';
      return `
        <button class="hk-list-item" data-desk-seq="${d.desk_seq}">
          <span class="hk-item-icon">🎫</span>
          <span class="hk-item-body">
            <span class="hk-item-title">${esc(pretty.primary)}</span>
            ${details ? `<span class="hk-item-sub">${esc(details)}</span>` : ''}
            ${pretty.secondary && pretty.secondary !== details
              ? `<span class="hk-item-sub">⏰ ${esc(pretty.secondary)}</span>` : ''}
          </span>
          <span class="hk-item-arrow">→</span>
        </button>`;
    }).join('');

    $$('.hk-list-item', container).forEach((btn) => {
      btn.addEventListener('click', () => {
        const desk = desks.find((d) => d.desk_seq === parseInt(btn.dataset.deskSeq, 10));
        if (desk) selectDesk(desk);
      });
    });
  }

  function selectDesk(desk) {
    const pretty = prettifyBoothName(desk.booth) || { primary: 'Counter ' + desk.desk_seq, secondary: null };
    state.selectedDesk = {
      desk_seq: desk.desk_seq,
      booth_raw: desk.booth,
      booth_pretty: pretty.primary,
      booth_note: pretty.secondary,
      details: desk.details,
      office_id: state.selectedOffice.office_id,
      office_name_en: state.selectedOffice.name_en,
      office_name_ko: state.selectedOffice.name_ko,
    };
    haptic('select');
    enterCalendar();
  }

  // ---------------------------------------------------------------------
  // SECTION: CALENDAR (real grid)
  // ---------------------------------------------------------------------

  async function enterCalendar() {
    const d = state.selectedDesk;
    $('calOfficeName').textContent = d.office_name_en;
    $('calBoothName').textContent = d.booth_pretty;
    $('calMonths').innerHTML = '<div class="hk-skeleton-cal"></div>';
    $('calMeta').innerHTML = '';
    showSection('calendar');
    await loadCalendarData();
  }

  async function loadCalendarData() {
    const d = state.selectedDesk;
    if (!d) return;
    if (state.calendarLoading) return;
    state.calendarLoading = true;
    try {
      const data = await api(`/desks/${d.desk_seq}/slots`);
      state.deskSlots = data;
      renderCalendar(data);
    } catch (e) {
      $('calMonths').innerHTML = `
        <div class="hk-list-empty">${esc(t('hk.err.slots', "Couldn't load this counter's calendar. Try again in a moment."))}</div>`;
    } finally {
      state.calendarLoading = false;
    }
  }

  // -- Pull-to-refresh on calendar --
  //
  // When the user is at the top of the calendar's scroll container and
  // drags downward, show a small indicator and fire loadCalendarData()
  // on release. Standard mobile gesture, no library.
  function setupPullToRefresh() {
    const container = document.querySelector('.hk-container');
    const indicator = $('pullIndicator');
    if (!container || !indicator) return;

    const THRESHOLD = 70;   // px drag distance that triggers a refresh
    const MAX_PULL  = 120;  // visual cap on how far the indicator moves

    let startY = 0;
    let pulling = false;
    let pulled  = 0;

    container.addEventListener('touchstart', (e) => {
      // Only engage on the calendar screen, at the very top of scroll.
      if ($('section-calendar').hidden) return;
      if (container.scrollTop > 0) return;
      startY = e.touches[0].clientY;
      pulling = true;
      pulled  = 0;
      indicator.classList.remove('refreshing', 'visible');
    }, { passive: true });

    container.addEventListener('touchmove', (e) => {
      if (!pulling) return;
      const dy = e.touches[0].clientY - startY;
      if (dy <= 0) {
        // Pulled back up — cancel
        pulled = 0;
        indicator.style.transform = `translateY(-100%)`;
        indicator.classList.remove('visible');
        return;
      }
      pulled = Math.min(dy * 0.6, MAX_PULL); // dampen by 0.6 for a natural feel
      indicator.classList.add('visible');
      indicator.style.transform = `translateY(${pulled - 40}px)`;
      indicator.classList.toggle('armed', pulled >= THRESHOLD);
    }, { passive: true });

    container.addEventListener('touchend', () => {
      if (!pulling) return;
      pulling = false;
      if (pulled >= THRESHOLD) {
        indicator.classList.add('refreshing');
        indicator.style.transform = `translateY(20px)`;
        haptic('light');
        loadCalendarData().finally(() => {
          // Small delay so the spin is visible even on fast networks
          setTimeout(() => {
            indicator.classList.remove('visible', 'refreshing', 'armed');
            indicator.style.transform = '';
          }, 400);
        });
      } else {
        // Snap back
        indicator.classList.remove('visible', 'armed');
        indicator.style.transform = '';
      }
    });
  }

  // ---------------------------------------------------------------------
  // CAPACITY HEURISTIC
  //
  // The /slots endpoint gives us `taken` per date but NOT per-date capacity.
  // Capacity varies by day-of-week (Mon ~36, Sat ~3, etc.). We approximate by
  // taking the max `taken` we've seen for each DoW in the visible window —
  // that's a lower bound on capacity. Lets us color cells by approximate
  // fullness without an extra HTTP round-trip per cell. The user always
  // gets the truth when they tap (live fetch).
  // ---------------------------------------------------------------------

  function computeMaxTakenByDow(dates) {
    const max = [0, 0, 0, 0, 0, 0, 0]; // index by Date.getDay() (Sun=0..Sat=6)
    for (const r of (dates || [])) {
      const dow = ymdToDate(r.visi_ymd).getDay();
      if (r.taken > max[dow]) max[dow] = r.taken;
    }
    return max;
  }

  function fillTier(taken, maxForDow) {
    // 3 honest tiers:
    //   empty:   taken == 0  -> definitely bookable, no one has booked yet
    //   partial: 0 < taken < max_for_dow -> bookings exist but slots remain
    //   full:    taken >= max_for_dow -> matches the busiest day-of-week
    //            we've observed; treated as "no slots available"
    if (taken === 0) return { name: 'empty', ratio: 0 };
    if (maxForDow <= 0) return { name: 'partial', ratio: 0.3 };
    const ratio = Math.min(taken / maxForDow, 1);
    if (ratio >= 1) return { name: 'full', ratio: 1 };
    return { name: 'partial', ratio };
  }

  // ---------------------------------------------------------------------
  // CALENDAR
  // ---------------------------------------------------------------------

  function renderCalendar(data) {
    // Meta chips
    const meta = $('calMeta');
    const chips = [];
    if (data.last_polled_at) {
      chips.push(`<span class="hk-meta-chip">🔄 ${esc(t('hk.cal.checked', 'Checked'))} ${esc(relativeTime(data.last_polled_at))}</span>`);
    }
    meta.innerHTML = chips.join('');

    // Build slot lookup. HiKorea's monthResvDataJSONList only contains
    // dates with at least one booking — so dates with zero bookings
    // (wide open) are missing. Fill those in from the schedule data
    // so the calendar reflects reality.
    const slotMap = {};
    (data.dates || []).forEach((row) => { slotMap[row.visi_ymd] = row; });

    const sched = data.schedule || null;
    if (sched && sched.bookable_min_ymd && sched.bookable_max_ymd) {
      const holidaySet = new Set(sched.holidays_ymd || []);
      const activeSet  = new Set(sched.active_weekdays || []);
      // Walk every day in [bookable_min, bookable_max] and mark as
      // wide-open (taken=0) unless we already have a real entry,
      // it's a holiday, or it's not an active weekday.
      const start = ymdToDate(sched.bookable_min_ymd);
      const end   = ymdToDate(sched.bookable_max_ymd);
      const cursor = new Date(start);
      while (cursor <= end) {
        const ymd = dateToYmd(cursor);
        if (!slotMap[ymd] && !holidaySet.has(ymd)) {
          // date.getDay(): 0=Sun..6=Sat. Our schedule uses 0=Mon..6=Sun.
          const jsDow = cursor.getDay();
          const schedDow = (jsDow + 6) % 7;
          if (activeSet.has(schedDow)) {
            slotMap[ymd] = { visi_ymd: ymd, taken: 0, inferred: true };
          }
        }
        cursor.setDate(cursor.getDate() + 1);
      }
    }

    // Per-DoW capacity heuristic for the visible window
    const maxByDow = computeMaxTakenByDow(Object.values(slotMap));

    // Summary banner
    renderSummaryBanner(Object.values(slotMap), maxByDow);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const months = [];
    for (let i = 0; i < 3; i++) {
      const d = new Date(today.getFullYear(), today.getMonth() + i, 1);
      months.push([d.getFullYear(), d.getMonth()]);
    }

    const container = $('calMonths');
    container.innerHTML = months
      .map(([y, m]) => renderOneMonth(y, m, slotMap, maxByDow, today))
      .join('');

    if (!Object.keys(slotMap).length) {
      const note = document.createElement('div');
      note.className = 'hk-cal-cta-note';
      note.innerHTML = `🌙 ${esc(t('hk.cal.allFullNote', "No dates visible right now. Set a watch and we'll ping you the moment one opens."))}`;
      container.appendChild(note);
    }

    $$('.hk-cal-cell-bookable', container).forEach((cell) => {
      cell.addEventListener('click', () => openDateSheet(cell.dataset.ymd));
    });
  }

  function renderSummaryBanner(dates, maxByDow) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const future = (dates || []).filter((r) => ymdToDate(r.visi_ymd) >= today);

    // "Bookable" = wide-open or partial (anything where taken < max_for_dow).
    const bookable = future.filter((r) => {
      const dow = ymdToDate(r.visi_ymd).getDay();
      return fillTier(r.taken, maxByDow[dow]).name !== 'full';
    });
    const earliest = bookable.length
      ? bookable.reduce((a, b) => (a.visi_ymd <= b.visi_ymd ? a : b))
      : null;

    const summary = $('calSummary');
    if (!future.length) {
      summary.hidden = true;
      return;
    }
    summary.hidden = false;

    if (earliest) {
      const d = ymdToDate(earliest.visi_ymd);
      summary.className = 'hk-cal-summary good';
      summary.innerHTML = `
        <div class="hk-summary-icon">⚡</div>
        <div class="hk-summary-body">
          <div class="hk-summary-headline">
            <span class="hk-summary-headline-label">${esc(t('hk.summary.earliestLabel', 'Earliest opening'))}</span>
            <span class="hk-summary-headline-value">
              ${esc(fmtDowFull(d))}, ${esc(fmtDayMonth(d))}
            </span>
          </div>
        </div>`;
    } else {
      summary.className = 'hk-cal-summary muted';
      summary.innerHTML = `
        <div class="hk-summary-icon">🌙</div>
        <div class="hk-summary-body">
          <div class="hk-summary-headline">
            <span class="hk-summary-headline-value">
              ${esc(t('hk.summary.allFull', 'Everything is fully booked'))}
            </span>
          </div>
          <div class="hk-summary-sub">
            ${esc(t('hk.summary.setWatch', "Set a watch — we'll ping you when a slot opens."))}
          </div>
        </div>`;
    }
  }

  function renderOneMonth(year, month0, slotMap, maxByDow, today) {
    // Day-of-week header labels. Use full i18n value (no slice) — the
    // i18n keys hold short native names (e.g. "Dush", "Sesh", "Chor") that
    // are readable without being cryptic two-letter abbreviations.
    const dowsShort = [];
    const weekOrder = [1, 2, 3, 4, 5, 6, 0];
    for (const dow of weekOrder) {
      const sample = new Date(2024, 0, dow === 0 ? 7 : dow);
      dowsShort.push(fmtDowShort(sample));
    }

    const firstOfMonth = new Date(year, month0, 1);
    const daysInMonth = new Date(year, month0 + 1, 0).getDate();
    const dow0 = firstOfMonth.getDay();
    const leading = (dow0 + 6) % 7;

    const cells = [];
    for (let i = 0; i < leading; i++) {
      cells.push(`<div class="hk-cal-cell empty"></div>`);
    }
    for (let day = 1; day <= daysInMonth; day++) {
      const d = new Date(year, month0, day);
      const ymd = dateToYmd(d);
      const isPast = d < today;
      const isToday = d.getTime() === today.getTime();
      const slot = slotMap[ymd];

      let cls = ['hk-cal-cell'];
      let fillBar = '';
      if (isToday) cls.push('today');

      if (isPast) {
        cls.push('past');
      } else if (slot) {
        cls.push('in-window', 'hk-cal-cell-bookable');
        const tier = fillTier(slot.taken, maxByDow[d.getDay()]);
        cls.push('tier-' + tier.name);
        if (tier.name !== 'empty') {
          const pct = Math.round(tier.ratio * 100);
          fillBar = `<span class="hk-cal-fill"><span style="width:${pct}%"></span></span>`;
        }
      } else {
        cls.push('closed');
      }

      cells.push(`
        <button type="button" class="${cls.join(' ')}"
                ${slot && !isPast ? `data-ymd="${ymd}"` : ''}
                ${isPast || !slot ? 'disabled' : ''}>
          <span class="hk-cal-day-num">${day}</span>
          ${fillBar}
        </button>`);
    }

    const total = leading + daysInMonth;
    const trailing = (7 - (total % 7)) % 7;
    for (let i = 0; i < trailing; i++) {
      cells.push(`<div class="hk-cal-cell empty"></div>`);
    }

    return `
      <div class="hk-cal-month">
        <div class="hk-cal-month-title">${esc(monthLabel(year, month0))}</div>
        <div class="hk-cal-dows">
          ${dowsShort.map((d) => `<div class="hk-cal-dow-label">${esc(d)}</div>`).join('')}
        </div>
        <div class="hk-cal-grid">${cells.join('')}</div>
      </div>`;
  }

  // ---------------------------------------------------------------------
  // BOTTOM SHEET (live per-date detail)
  // ---------------------------------------------------------------------

  async function openDateSheet(ymd) {
    const d = state.selectedDesk;

    $('sheetDay').textContent  = dowName(ymd);
    $('sheetDate').textContent = ymdToDate(ymd).toLocaleDateString(undefined, {
      month: 'long', day: 'numeric', year: 'numeric',
    });

    // Show loading state immediately — live HTTP can take 1–3s
    const stat = $('sheetStat');
    stat.className = 'hk-sheet-stat loading';
    stat.innerHTML = `
      <span class="hk-sheet-loading">
        <span class="hk-sheet-spinner"></span>
        ${esc(t('hk.sheet.loading', 'Checking HiKorea right now…'))}
      </span>`;
    $('sheetBookBtn').style.display = 'none';

    $('sheetBackdrop').hidden = false;
    $('dateSheet').hidden = false;
    state.sheetOpen = true;
    haptic('light');

    let detail;
    try {
      detail = await api(`/desks/${d.desk_seq}/dates/${ymd}`);
    } catch (e) {
      stat.className = 'hk-sheet-stat error';
      const msg = (e.status === 502 && e.data?.error === 'session_expired')
        ? t('hk.sheet.sessionExpired',
            "Our HiKorea login needs refreshing — the admin has been notified. Try again in a moment.")
        : t('hk.sheet.fetchFail',
            "Couldn't reach HiKorea just now. Try again in a moment.");
      stat.innerHTML = `<span class="hk-sheet-loading">⚠️ ${esc(msg)}</span>`;
      return;
    }

    renderSheetDetail(detail);
  }

  function renderSheetDetail(detail) {
    const stat = $('sheetStat');
    const totalCap   = detail.total_capacity   || 0;
    const totalTaken = detail.total_taken      || 0;
    const totalAvail = detail.total_available  || 0;
    const slots      = detail.time_slots       || [];

    let tier, pillText;
    if (totalCap === 0) {
      tier = 'full';
      pillText = t('hk.sheet.closed', 'Office closed this day');
    } else if (totalAvail <= 0) {
      tier = 'full';
      pillText = t('hk.sheet.fullyBooked', 'Fully booked');
    } else if (totalAvail / totalCap < 0.2) {
      tier = 'low';
      pillText = (totalAvail === 1
        ? t('hk.sheet.lastOne', 'Just 1 slot left — grab it!')
        : `${totalAvail} ${t('hk.sheet.fewLeft', 'slots left — hurry!')}`);
    } else if (totalAvail / totalCap < 0.5) {
      tier = 'med';
      pillText = `${totalAvail} ${t('hk.sheet.slotsLeft', 'slots left')}`;
    } else {
      tier = 'high';
      pillText = `${totalAvail} ${t('hk.sheet.slotsOpen', 'slots open')}`;
    }

    // Visual progress bar showing capacity utilization
    const fillPct = totalCap > 0 ? Math.round((totalTaken / totalCap) * 100) : 0;
    const progressHtml = totalCap > 0 ? `
      <div class="hk-sheet-progress">
        <div class="hk-sheet-progress-bar">
          <div class="hk-sheet-progress-fill ${tier}" style="width:${fillPct}%"></div>
        </div>
        <div class="hk-sheet-progress-meta">
          <span>${totalTaken} ${t('hk.sheet.booked', 'booked')}</span>
          <span>${totalAvail} ${t('hk.sheet.openLabel', 'open')}</span>
        </div>
      </div>` : '';

    // Group slots morning/afternoon for easier scanning
    const realSlots = slots.filter((s) => s.capacity > 0);
    const morning   = realSlots.filter((s) => parseInt(s.time.split(':')[0], 10) < 12);
    const afternoon = realSlots.filter((s) => parseInt(s.time.split(':')[0], 10) >= 12);

    function renderSlotGroup(label, list) {
      if (!list.length) return '';
      const openCount = list.filter((s) => s.available > 0).length;
      return `
        <div class="hk-sheet-time-group">
          <div class="hk-sheet-time-group-head">
            <span class="hk-sheet-time-group-label">${esc(label)}</span>
            <span class="hk-sheet-time-group-count">
              ${openCount > 0
                ? `${openCount} ${esc(t('hk.sheet.openOfTotal', 'open'))}`
                : esc(t('hk.sheet.allFull', 'all full'))}
            </span>
          </div>
          <div class="hk-sheet-times-grid">
            ${list.map((s) => {
              const slotClass = s.available <= 0 ? 'full' :
                                s.available === s.capacity ? 'open' : 'partial';
              // Plain-language label. Drops the X/Y ratio that was hard to
              // parse at a glance. "3 left" / "Full" reads instantly.
              const statHtml = s.available > 0
                ? `<span class="hk-sheet-time-avail">
                     <strong>${s.available}</strong>
                     <span class="hk-sheet-time-avail-suffix">
                       ${esc(s.available === 1
                          ? t('hk.sheet.leftOne', 'left')
                          : t('hk.sheet.leftMany', 'left'))}
                     </span>
                   </span>`
                : `<span class="hk-sheet-time-avail muted">
                     ${esc(t('hk.sheet.slotFull', 'Full'))}
                   </span>`;
              return `
                <div class="hk-sheet-time-row ${slotClass}">
                  <span class="hk-sheet-time-label">${esc(s.time)}</span>
                  ${statHtml}
                </div>`;
            }).join('')}
          </div>
        </div>`;
    }

    const slotsHtml = realSlots.length ? `
      <div class="hk-sheet-times">
        ${renderSlotGroup(t('hk.sheet.morning',   '🌅 Morning'),   morning)}
        ${renderSlotGroup(t('hk.sheet.afternoon', '🌇 Afternoon'), afternoon)}
      </div>` : '';

    stat.className = `hk-sheet-stat ${tier}`;
    stat.innerHTML = `
      <span class="pill-num">${esc(pillText)}</span>
      <span class="hk-sheet-stat-msg">
        ${esc(totalAvail > 0
          ? t('hk.sheet.bookCue', 'Book on HiKorea before someone else grabs it.')
          : t('hk.sheet.fullCue', "Set a watch and we'll ping you when a slot opens."))}
      </span>
      ${progressHtml}
      ${slotsHtml}
    `;

    $('sheetBookBtn').style.display = totalAvail > 0 ? '' : 'none';
  }

  function closeSheet() {
    $('sheetBackdrop').hidden = true;
    $('dateSheet').hidden = true;
    state.sheetOpen = false;
  }

  function bindSheet() {
    $('sheetBackdrop').addEventListener('click', closeSheet);
    $('sheetCloseBtn').addEventListener('click', closeSheet);
  }

  // ---------------------------------------------------------------------
  // SECTION: WATCH SETUP
  // ---------------------------------------------------------------------

  function enterWatchSetup() {
    const d = state.selectedDesk;
    $('watchOfficeName').textContent = d.office_name_en;
    $('watchBoothName').textContent  = d.booth_pretty;

    // Sensible default: next 14 days, starting tomorrow
    const tomorrow = addDays(new Date(), 1);
    const plus14   = addDays(new Date(), 14);
    $('watchStartDate').valueAsDate = tomorrow;
    $('watchEndDate').valueAsDate   = plus14;
    $('watchStartDate').min = dateToInputValue(new Date());
    $('watchEndDate').min   = dateToInputValue(new Date());

    setActivePreset('14');
    updateWatchPreview();
    showSection('watch');
  }

  function setActivePreset(preset) {
    $$('.hk-preset').forEach((btn) => {
      btn.classList.toggle('active', preset && btn.dataset.preset === preset);
    });
  }

  function updateWatchPreview() {
    const startStr = $('watchStartDate').value;
    const endStr   = $('watchEndDate').value;

    // Always update the date-trigger labels (always-visible, even when
    // the preview card is hidden).
    const startLabel = $('watchStartLabel');
    const endLabel   = $('watchEndLabel');
    const placeholder = t('hk.watch.tapPick', 'Tap to pick');
    if (startLabel) {
      startLabel.textContent = startStr
        ? fmtDayMonth(new Date(startStr))
        : placeholder;
    }
    if (endLabel) {
      endLabel.textContent = endStr
        ? fmtDayMonth(new Date(endStr))
        : placeholder;
    }

    if (!startStr || !endStr) {
      $('watchPreview').hidden = true;
      return;
    }
    const s = new Date(startStr), e = new Date(endStr);
    if (isNaN(s) || isNaN(e) || e < s) {
      $('watchPreview').hidden = true;
      return;
    }
    $('watchPreview').hidden = false;
    const days = Math.round((e - s) / 86400000) + 1;
    $('previewSummary').textContent =
      `${t('hk.preview.watching', 'Watching')} ${fmtDayMonth(s)} → ${fmtDayMonth(e)}`;
    $('previewDetail').textContent =
      days === 1
        ? t('hk.preview.oneDay', '1 day in your window')
        : `${days} ${t('hk.preview.days', 'days in your window')}`;
  }

  function bindWatchSetup() {
    $$('.hk-preset').forEach((btn) => {
      btn.addEventListener('click', () => {
        const days = parseInt(btn.dataset.preset, 10);
        $('watchStartDate').valueAsDate = addDays(new Date(), 1);
        $('watchEndDate').valueAsDate   = addDays(new Date(), days);
        setActivePreset(btn.dataset.preset);
        updateWatchPreview();
        haptic('light');
      });
    });
    ['watchStartDate', 'watchEndDate'].forEach((id) => {
      $(id).addEventListener('change', () => {
        setActivePreset(null);
        updateWatchPreview();
      });
    });
    // Tap the formatted date label -> open native picker
    $$('.hk-date-trigger').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const input = $(btn.dataset.target);
        if (!input) return;
        if (typeof input.showPicker === 'function') {
          try { input.showPicker(); return; } catch (_) {}
        }
        // Fallback: focus + click — opens on most mobile browsers.
        input.focus();
        input.click();
      });
    });
    $('submitWatchBtn').addEventListener('click', () => submitWatch());
    $('successOkBtn').addEventListener('click', () => {
      closeOverlay();
      state.navStack = ['home'];
      enterMyWatches();
    });
    $('testNotifBtn').addEventListener('click', sendTestNotification);
  }

  async function sendTestNotification() {
    if (!state.user) return;
    const btn = $('testNotifBtn');
    const original = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = `<span class="hk-spinner-small"></span> ${esc(t('hk.success.testSending', 'Sending…'))}`;
    try {
      await api('/test-notification', {
        method: 'POST',
        body: {
          telegram_user_id:  state.user.id,
          telegram_username: state.user.username,
        },
      });
      haptic('ok');
      btn.classList.add('sent');
      btn.innerHTML = `✓ ${esc(t('hk.success.testSent', 'Check your Telegram'))}`;
    } catch (e) {
      haptic('err');
      btn.innerHTML = original;
      btn.disabled = false;
      toast(t('hk.success.testFail', "Couldn't send. Try again."), 'error');
    }
  }

  async function submitWatch() {
    if (!state.user) {
      toast(t('hk.err.noUser', 'Open this page from the Telegram bot first.'), 'error');
      return;
    }
    const startStr = $('watchStartDate').value;
    const endStr   = $('watchEndDate').value;
    if (!startStr || !endStr) {
      toast(t('hk.err.pickDates', 'Pick a start and end date'), 'error');
      return;
    }
    const startYmd = startStr.replace(/-/g, '');
    const endYmd   = endStr.replace(/-/g, '');

    const btn = $('submitWatchBtn');
    btn.disabled = true;

    try {
      await api('/watches', {
        method: 'POST',
        body: {
          telegram_user_id:  state.user.id,
          telegram_username: state.user.username,
          desk_seq:          state.selectedDesk.desk_seq,
          start_ymd:         startYmd,
          end_ymd:           endYmd,
        },
      });
      haptic('ok');
      $('successOverlay').hidden = false;
      state.overlayOpen = true;
      refreshMyWatchesChip();
    } catch (e) {
      if (e.status === 409 && e.data?.error === 'duplicate_watch') {
        toast(t('hk.err.dup', "You've already set this watch"), 'error');
        haptic('err');
      } else if (e.status === 409 && e.data?.error === 'max_watches_reached') {
        toast(t('hk.err.max', "You've hit the limit (10). Cancel one first."), 'error');
        haptic('err');
      } else if (e.status === 400 && e.data?.fields) {
        const first = Object.values(e.data.fields)[0];
        toast(first || t('hk.err.input', 'Check your dates'), 'error');
        haptic('err');
      } else {
        toast(t('hk.err.create', "Couldn't create the watch — try again"), 'error');
        haptic('err');
      }
    } finally {
      btn.disabled = false;
    }
  }

  function closeOverlay() {
    $('successOverlay').hidden = true;
    state.overlayOpen = false;
  }

  // ---------------------------------------------------------------------
  // SECTION: MY WATCHES
  // ---------------------------------------------------------------------

  async function enterMyWatches() {
    showSection('watches');
    $('watchList').innerHTML = '<div class="hk-skeleton-row"></div><div class="hk-skeleton-row"></div>';
    $('watchesEmpty').hidden = true;

    if (!state.user) {
      $('watchList').innerHTML = '';
      $('watchesEmpty').hidden = false;
      $('watchesEmpty').querySelector('.hk-empty-title').textContent =
        t('hk.err.noUser', 'Open this page from the Telegram bot first.');
      $('watchesEmpty').querySelector('.hk-empty-sub').textContent = '';
      return;
    }

    try {
      const data = await api(
        `/watches?telegram_user_id=${encodeURIComponent(state.user.id)}&status=active`,
      );
      renderWatchList(data.watches || []);
    } catch (e) {
      $('watchList').innerHTML = `
        <div class="hk-list-empty">${esc(t('hk.err.watches', "Couldn't load your watches"))}</div>`;
    }
  }

  function renderWatchList(watches) {
    const list = $('watchList');
    if (!watches.length) {
      list.innerHTML = '';
      $('watchesEmpty').hidden = false;
      return;
    }
    $('watchesEmpty').hidden = true;

    list.innerHTML = watches.map((w) => {
      const pretty = prettifyBoothName(w.booth) || { primary: 'Counter ' + w.desk_seq };
      return `
        <div class="hk-watch-card status-${esc(w.status)}">
          <div class="hk-watch-head">
            <div>
              <div class="hk-watch-office">${esc(w.office_name_en || '?')}</div>
              <div class="hk-watch-booth">${esc(pretty.primary)}</div>
            </div>
            <span class="hk-watch-pill ${esc(w.status)}">${esc(t('hk.watches.status.' + w.status, w.status))}</span>
          </div>
          <div class="hk-watch-range">
            <span class="hk-watch-range-icon">📅</span>
            <span>
              <strong>${esc(fmtShortDate(w.start_ymd))}</strong>
              → <strong>${esc(fmtShortDate(w.end_ymd))}</strong>
            </span>
          </div>
          <div class="hk-watch-actions">
            <button class="hk-cancel-btn" data-watch-id="${w.id}">
              ${esc(t('hk.watches.cancel', 'Stop watching'))}
            </button>
          </div>
        </div>`;
    }).join('');

    $$('.hk-cancel-btn', list).forEach((btn) => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.watchId;
        btn.disabled = true;
        try {
          await api(
            `/watches/${id}?telegram_user_id=${encodeURIComponent(state.user.id)}`,
            { method: 'DELETE' },
          );
          haptic('ok');
          toast(t('hk.watches.stopped', 'Watch stopped'), 'success');
          enterMyWatches();
          refreshMyWatchesChip();
        } catch (e) {
          btn.disabled = false;
          toast(t('hk.err.cancel', "Couldn't stop the watch — try again"), 'error');
          haptic('err');
        }
      });
    });
  }

  // ---------------------------------------------------------------------
  // I18N application
  // ---------------------------------------------------------------------

  function applyTranslations() {
    $$('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      const v = t(key, null);
      if (v !== null) {
        if (v.includes('<') && v.includes('>')) el.innerHTML = v;
        else el.textContent = v;
      }
    });
    $$('[data-i18n-placeholder]').forEach((el) => {
      const key = el.getAttribute('data-i18n-placeholder');
      const v = t(key, null);
      if (v !== null) el.setAttribute('placeholder', v);
    });
    const titleKey = document.querySelector('title')?.getAttribute('data-i18n');
    if (titleKey) {
      const tr = t(titleKey, null);
      if (tr) document.title = tr;
    }
  }
  window.addEventListener('languageChanged', applyTranslations);

  // ---------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------

  document.addEventListener('DOMContentLoaded', () => {
    applyTranslations();
    bindSheet();
    bindWatchSetup();
    setupPullToRefresh();

    $('officeSearch').addEventListener('input', (e) => {
      renderOfficeList(e.target.value);
    });

    $('byAddressLink').addEventListener('click', async () => {
      haptic('light');
      await ensureOfficesLoaded();
      renderProvinces();
      showSection('by-address');
    });

    $('myWatchesChip').addEventListener('click', () => {
      haptic('light');
      enterMyWatches();
    });

    $('resolveBtn').addEventListener('click', doResolveOffice);
    $('addressInput').addEventListener('keypress', (e) => {
      if (e.key === 'Enter') doResolveOffice();
    });

    $('goToWatchBtn').addEventListener('click', () => {
      haptic('light');
      enterWatchSetup();
    });

    $$('[data-back]').forEach((el) => el.addEventListener('click', handleBack));

    showSection('home', { silent: true });
    renderHome();

    console.log('✅ HiKorea page (v2) loaded',
                state.user ? `user=${state.user.id}` : '(no tg user)');
  });

})();
