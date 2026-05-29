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
    return ymdToDate(ymd).toLocaleDateString(undefined, {
      weekday: 'long', month: 'long', day: 'numeric', year: 'numeric',
    });
  }

  function fmtShortDate(ymd) {
    return ymdToDate(ymd).toLocaleDateString(undefined, {
      month: 'short', day: 'numeric',
    });
  }

  function dowName(ymd) {
    return ymdToDate(ymd).toLocaleDateString(undefined, { weekday: 'long' });
  }

  function monthLabel(y, m /* 0-indexed */) {
    return new Date(y, m, 1).toLocaleDateString(undefined, {
      month: 'long', year: 'numeric',
    });
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

  function availTier(available, capacity) {
    if (available == null || capacity == null || available <= 0) return 'full';
    const pct = available / capacity;
    if (pct >= 0.5) return 'high';
    if (pct >= 0.2) return 'med';
    return 'low';
  }

  function availPhrase(available, capacity) {
    // Plain language for the bottom sheet
    if (available == null) return { tier: 'full', text: t('hk.phrase.unknown', "No info — check HiKorea") };
    if (available <= 0)    return { tier: 'full', text: t('hk.phrase.full', 'Fully booked') };
    if (capacity && available / capacity < 0.2) return {
      tier: 'low',
      text: available === 1
        ? t('hk.phrase.lastOne', 'Just 1 spot left — grab it!')
        : `${available} ${t('hk.phrase.spotsLeftHurry', 'spots left — hurry!')}`,
    };
    if (capacity && available / capacity < 0.5) return {
      tier: 'med',
      text: `${available} ${t('hk.phrase.spotsLeft', 'spots left')}`,
    };
    return {
      tier: 'high',
      text: `${available} ${t('hk.phrase.spotsOpen', 'spots open')}`,
    };
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
    window.scrollTo({ top: 0, behavior: 'instant' in window ? 'instant' : 'auto' });
  }

  function handleBack() {
    if (state.sheetOpen)   { closeSheet(); return; }
    if (state.overlayOpen) { closeOverlay(); return; }
    const warn = $('availableWarn');
    if (warn && !warn.hidden) { warn.hidden = true; return; }
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

    try {
      const data = await api(`/desks/${d.desk_seq}/slots`);
      state.deskSlots = data;
      renderCalendar(data);
    } catch (e) {
      $('calMonths').innerHTML = `
        <div class="hk-list-empty">${esc(t('hk.err.slots', "Couldn't load this counter's calendar. Try again in a moment."))}</div>`;
    }
  }

  function renderCalendar(data) {
    // Meta chips
    const meta = $('calMeta');
    const chips = [];
    if (data.capacity != null) {
      chips.push(`<span class="hk-meta-chip">${t('hk.cal.maxPerDay', 'Max/day')}: ${data.capacity}</span>`);
    }
    if (data.last_polled_at) {
      chips.push(`<span class="hk-meta-chip">🔄 ${esc(t('hk.cal.checked', 'Checked'))} ${esc(relativeTime(data.last_polled_at))}</span>`);
    }
    meta.innerHTML = chips.join('');

    // Build a lookup: ymd -> {taken, available}
    const slotMap = {};
    (data.dates || []).forEach((row) => {
      slotMap[row.visi_ymd] = row;
    });

    // Determine which months to show:
    //  - current month
    //  - any month with at least one row in the response
    //  - cap at 3 months total
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const monthsSet = new Set();
    monthsSet.add(`${today.getFullYear()}-${today.getMonth()}`);
    Object.keys(slotMap).forEach((ymd) => {
      const d = ymdToDate(ymd);
      monthsSet.add(`${d.getFullYear()}-${d.getMonth()}`);
    });
    const months = Array.from(monthsSet)
      .map((k) => k.split('-').map(Number))
      .sort((a, b) => a[0] - b[0] || a[1] - b[1])
      .slice(0, 3);

    if (months.length === 0) {
      months.push([today.getFullYear(), today.getMonth()]);
    }

    const container = $('calMonths');
    container.innerHTML = months
      .map(([y, m]) => renderOneMonth(y, m, slotMap, data.capacity, today))
      .join('');

    // Empty-state message if literally no available slots anywhere
    const anyAvailable = (data.dates || []).some((r) => (r.available || 0) > 0);
    if (!anyAvailable) {
      const note = document.createElement('div');
      note.className = 'hk-cal-cta-note';
      note.innerHTML = `🌙 ${esc(t('hk.cal.allFullNote', "Looks like every visible date is full right now. That's exactly when a watch helps — we'll ping you the moment something opens."))}`;
      container.appendChild(note);
    }

    // Wire cell taps
    $$('.hk-cal-cell-bookable', container).forEach((cell) => {
      cell.addEventListener('click', () => openDateSheet(cell.dataset.ymd, slotMap, data.capacity));
    });
  }

  function renderOneMonth(year, month0, slotMap, capacity, today) {
    const dowsShort = [];
    // Week starts Monday for the Korean context.
    const weekOrder = [1, 2, 3, 4, 5, 6, 0]; // Mon..Sun
    for (const dow of weekOrder) {
      const sample = new Date(2024, 0, dow === 0 ? 7 : dow); // 2024-01-01 was Mon
      dowsShort.push(sample.toLocaleDateString(undefined, { weekday: 'short' }).slice(0, 2));
    }

    const firstOfMonth = new Date(year, month0, 1);
    const daysInMonth = new Date(year, month0 + 1, 0).getDate();

    // Leading blanks: number of cells before day 1 (Mon-first week).
    const dow0 = firstOfMonth.getDay(); // 0..6 (Sun..Sat)
    const leading = (dow0 + 6) % 7;     // Mon=0, Sun=6

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
      let mark = '';

      if (isToday) cls.push('today');

      if (isPast) {
        cls.push('past');
      } else if (slot) {
        cls.push('has-slots', availTier(slot.available, capacity));
        cls.push('hk-cal-cell-bookable');
        if (slot.available != null) mark = `${slot.available}`;
      } else {
        cls.push('full');
      }

      cells.push(`
        <button type="button" class="${cls.join(' ')}"
                ${slot && !isPast ? `data-ymd="${ymd}"` : ''}
                ${isPast ? 'disabled' : ''}>
          <span class="hk-cal-day-num">${day}</span>
          ${mark ? `<span class="hk-cal-day-mark">${mark}</span>` : ''}
        </button>`);
    }

    // Trailing to fill the last row (optional, helps grid alignment)
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
  // BOTTOM SHEET (date detail)
  // ---------------------------------------------------------------------

  function openDateSheet(ymd, slotMap, capacity) {
    const slot = slotMap[ymd];
    if (!slot) return;

    const phrase = availPhrase(slot.available, capacity);

    $('sheetDay').textContent  = dowName(ymd);
    $('sheetDate').textContent = ymdToDate(ymd).toLocaleDateString(undefined, {
      month: 'long', day: 'numeric', year: 'numeric',
    });

    const stat = $('sheetStat');
    stat.className = `hk-sheet-stat ${phrase.tier}`;
    stat.innerHTML = `
      <span class="pill-num">${esc(phrase.text)}</span>
      <span class="hk-sheet-stat-msg">
        ${esc(slot.available > 0
          ? t('hk.sheet.bookCue', 'Book on HiKorea before someone else grabs it.')
          : t('hk.sheet.fullCue', 'No spots right now — set a watch and we\'ll tell you when one opens.'))}
      </span>`;

    $('sheetBookBtn').style.display = slot.available > 0 ? '' : 'none';

    $('sheetBackdrop').hidden = false;
    $('dateSheet').hidden = false;
    state.sheetOpen = true;
    haptic('light');
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
    $('availableWarn').hidden = true;

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
    const sLabel = s.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    const eLabel = e.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    $('previewSummary').textContent =
      `${t('hk.preview.watching', 'Watching')} ${sLabel} → ${eLabel}`;
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
    $('submitWatchBtn').addEventListener('click', () => submitWatch(false));
    $('forceWatchBtn').addEventListener('click', () => submitWatch(true));
    $('successOkBtn').addEventListener('click', () => {
      closeOverlay();
      state.navStack = ['home'];
      enterMyWatches();
    });
  }

  async function submitWatch(force) {
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
          force:             !!force,
        },
      });
      haptic('ok');
      $('availableWarn').hidden = true;
      $('successOverlay').hidden = false;
      state.overlayOpen = true;
      refreshMyWatchesChip();
    } catch (e) {
      if (e.status === 409 && e.data?.error === 'available_slots_in_range') {
        renderWarn(e.data.available_dates || []);
        haptic('warning');
      } else if (e.status === 409 && e.data?.error === 'duplicate_watch') {
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

  function renderWarn(availableDates) {
    const warn = $('availableWarn');
    const dates = $('availableWarnDates');
    dates.innerHTML = availableDates.map((d) => {
      const txt = `${ymdToDate(d.visi_ymd).toLocaleDateString(undefined, {
        month: 'short', day: 'numeric',
      })} — ${d.available} ${t('hk.phrase.open', 'open')}`;
      return `<span class="hk-warn-date">${esc(txt)}</span>`;
    }).join('');
    warn.hidden = false;
    warn.scrollIntoView({ behavior: 'smooth', block: 'center' });
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
            <span class="hk-watch-pill ${esc(w.status)}">${esc(w.status)}</span>
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
