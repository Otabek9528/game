// =====================================================================
// hikorea.js — HiKorea Slot Watcher (Phase 3 frontend)
// State machine across 6 sections: entry → office → booth → calendar/alarm → my-alarms.
// Talks to /api/hikorea/* on vegukin-api.duckdns.org (see hikorea_api.py).
// =====================================================================

(function () {
  'use strict';

  // ---------------------------------------------------------------------
  // CONSTANTS & STATE
  // ---------------------------------------------------------------------

  const API_BASE = 'https://vegukin-api.duckdns.org/api/hikorea';

  const SECTIONS = [
    'entry', 'office', 'booth', 'calendar', 'alarm', 'my-alarms',
  ];

  const state = {
    mode: null,            // 'calendar' | 'alarm'  — set on entry
    offices: [],           // cached office catalog (loaded once)
    provinces: [],         // cached province list
    selectedOffice: null,  // {office_id, name_en, name_ko, desks: [...]}
    selectedDesk: null,    // {desk_seq, booth, details, office_*}
    user: null,            // tg user {id, username, first_name}
    navStack: ['entry'],   // back-button history
    overlayOpen: false,
  };

  // ---------------------------------------------------------------------
  // TELEGRAM WEBAPP INIT
  // ---------------------------------------------------------------------

  const tg = window.Telegram?.WebApp;
  if (tg) {
    try { tg.ready(); } catch (e) {}
    try { tg.expand(); } catch (e) {}
    try { tg.disableVerticalSwipes(); } catch (e) {}
  }

  // Capture user identity from Telegram WebApp init data.
  if (tg?.initDataUnsafe?.user) {
    const u = tg.initDataUnsafe.user;
    state.user = {
      id: u.id,
      username: u.username || null,
      first_name: u.first_name || null,
    };
  }

  // ---------------------------------------------------------------------
  // SMALL HELPERS
  // ---------------------------------------------------------------------

  function $(id) { return document.getElementById(id); }
  function $$(sel, root) { return Array.from((root || document).querySelectorAll(sel)); }

  function haptic(kind) {
    try {
      if (!tg?.HapticFeedback) return;
      if (kind === 'select')   tg.HapticFeedback.selectionChanged();
      else if (kind === 'ok')  tg.HapticFeedback.notificationOccurred('success');
      else if (kind === 'err') tg.HapticFeedback.notificationOccurred('error');
      else                     tg.HapticFeedback.impactOccurred(kind || 'light');
    } catch (e) {}
  }

  function escapeHtml(s) {
    if (s == null) return '';
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function t(key, fallback) {
    if (window.I18N) {
      const v = I18N.t(key);
      if (v && v !== key) return v;
    }
    return fallback;
  }

  function fmtYmd(ymd) {
    // "20260601" -> "2026-06-01"
    if (!ymd || ymd.length !== 8) return ymd || '';
    return ymd.slice(0, 4) + '-' + ymd.slice(4, 6) + '-' + ymd.slice(6, 8);
  }

  function fmtPrettyDate(ymd) {
    // "20260601" -> "Jun 1"
    if (!ymd || ymd.length !== 8) return ymd || '';
    const d = new Date(+ymd.slice(0, 4), +ymd.slice(4, 6) - 1, +ymd.slice(6, 8));
    return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  }

  function dowLabel(ymd) {
    const d = new Date(+ymd.slice(0, 4), +ymd.slice(4, 6) - 1, +ymd.slice(6, 8));
    return d.toLocaleDateString(undefined, { weekday: 'short' });
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

  function todayYmd() { return dateToYmd(new Date()); }

  function addDays(date, n) {
    const d = new Date(date);
    d.setDate(d.getDate() + n);
    return d;
  }

  function monthLabel(ymd) {
    const d = ymdToDate(ymd);
    return d.toLocaleDateString(undefined, { year: 'numeric', month: 'long' });
  }

  function availClass(avail, capacity) {
    if (avail == null || capacity == null) return 'full';
    if (avail <= 0) return 'full';
    const pct = avail / capacity;
    if (pct >= 0.5) return 'high';
    if (pct >= 0.2) return 'medium';
    return 'low';
  }

  // ---------------------------------------------------------------------
  // TOAST
  // ---------------------------------------------------------------------

  let toastTimer = null;
  function toast(message, kind) {
    const el = $('toast');
    el.textContent = message;
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
  // API CLIENT
  // ---------------------------------------------------------------------

  async function api(path, opts) {
    opts = opts || {};
    const url = API_BASE + path;
    const init = {
      method: opts.method || 'GET',
      headers: { 'Content-Type': 'application/json', ...(opts.headers || {}) },
    };
    if (opts.body) init.body = JSON.stringify(opts.body);

    let res, data;
    try {
      res = await fetch(url, init);
      data = await res.json().catch(() => ({}));
    } catch (e) {
      const err = new Error('network_error');
      err.status = 0;
      throw err;
    }
    if (!res.ok) {
      const err = new Error(data.error || `http_${res.status}`);
      err.status = res.status;
      err.data = data;
      throw err;
    }
    return data;
  }

  // ---------------------------------------------------------------------
  // NAVIGATION (in-page section switching)
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
    // Dismiss overlay first
    if (state.overlayOpen) {
      $('successOverlay').hidden = true;
      state.overlayOpen = false;
      return;
    }
    // Dismiss inline warning card if visible
    const warn = $('availableWarn');
    if (warn && !warn.hidden) {
      warn.hidden = true;
      return;
    }
    if (state.navStack.length > 1) {
      state.navStack.pop();
      showSection(state.navStack[state.navStack.length - 1], { silent: true });
      haptic('light');
    } else {
      window.location.href = '../../index.html';
    }
  }

  if (tg?.BackButton) {
    try {
      tg.BackButton.show();
      tg.BackButton.onClick(handleBack);
    } catch (e) {}
  }

  // ---------------------------------------------------------------------
  // STATUS PILL (watcher health)
  // ---------------------------------------------------------------------

  async function refreshStatusPill() {
    try {
      const data = await api('/status');
      const pill = $('statusPill');
      const dot = $('statusDot');
      const text = $('statusText');
      pill.hidden = false;

      if (data.session_alive === false) {
        dot.className = 'hk-status-dot error';
        text.textContent = t('hk.status.offline',
          'Watcher offline — admin notified');
        return;
      }
      if (data.desks_failing && data.desks_failing > 0) {
        dot.className = 'hk-status-dot warn';
        text.textContent = `${data.desks_failing} ${t('hk.status.deskIssues', 'desk(s) with issues')}`;
        return;
      }
      dot.className = 'hk-status-dot ok';
      if (data.last_successful_poll) {
        text.textContent = `${t('hk.status.updated', 'Updated')} ${relativeTime(data.last_successful_poll)}`;
      } else {
        text.textContent = t('hk.status.ready', 'Watcher online');
      }
    } catch (e) {
      // Quiet failure — pill stays hidden.
      console.warn('Status check failed:', e);
    }
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
      const d = Math.floor(h / 24);
      return `${d}d ${t('hk.time.ago', 'ago')}`;
    } catch (e) { return ''; }
  }

  // ---------------------------------------------------------------------
  // SECTION 1: ENTRY
  // ---------------------------------------------------------------------

  function bindEntry() {
    $$('.hk-action-card[data-action]').forEach((el) => {
      el.addEventListener('click', () => {
        const action = el.dataset.action;
        haptic('light');
        if (action === 'calendar' || action === 'alarm') {
          state.mode = action;
          enterOfficePicker();
        } else if (action === 'my-alarms') {
          enterMyAlarms();
        }
      });
    });
  }

  async function refreshMyAlarmsCount() {
    if (!state.user) return;
    try {
      const data = await api(
        `/watches?telegram_user_id=${encodeURIComponent(state.user.id)}&status=active`
      );
      const count = (data.watches || []).length;
      $('myAlarmsCount').textContent = String(count);
      $('myAlarmsEntry').hidden = count === 0;
    } catch (e) {
      $('myAlarmsEntry').hidden = true;
    }
  }

  // ---------------------------------------------------------------------
  // SECTION 2: OFFICE PICKER
  // ---------------------------------------------------------------------

  async function enterOfficePicker() {
    showSection('office');
    await ensureOfficesLoaded();
    renderOfficeList($('officeSearch').value || '');
    renderProvinces();
  }

  async function ensureOfficesLoaded() {
    if (state.offices.length > 0) return;
    try {
      const [officesRes, provRes] = await Promise.all([
        api('/offices'),
        api('/provinces'),
      ]);
      state.offices = officesRes.offices || [];
      state.provinces = provRes.provinces || [];
    } catch (e) {
      toast(t('hk.err.loadOffices', 'Could not load offices'), 'error');
      console.error(e);
    }
  }

  function bindOfficePickerTabs() {
    $$('.hk-tab').forEach((tab) => {
      tab.addEventListener('click', () => {
        const target = tab.dataset.tab;
        $$('.hk-tab').forEach((t2) => t2.classList.toggle('active', t2 === tab));
        $$('.hk-tab-panel').forEach((p) => {
          p.classList.toggle('active', p.id === 'tab-' + target);
        });
        haptic('light');
      });
    });
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
        <div class="hk-resolve-empty">${escapeHtml(t('hk.office.noMatch', 'No offices match your search.'))}</div>
      `;
      return;
    }

    container.innerHTML = rows.map((o) => {
      const deskCount = (o.desks || []).length;
      const deskLabel = deskCount === 1
        ? t('hk.office.boothOne', '1 booth')
        : `${deskCount} ${t('hk.office.boothMany', 'booths')}`;
      return `
        <button class="hk-list-item" data-office-id="${escapeHtml(o.office_id)}">
          <span class="hk-item-icon">🏢</span>
          <span class="hk-item-body">
            <span class="hk-item-title">${escapeHtml(o.name_en || o.name_ko)}</span>
            <span class="hk-item-sub">${escapeHtml(o.name_ko || '')} · ${escapeHtml(deskLabel)}</span>
          </span>
          <span class="hk-item-arrow">→</span>
        </button>
      `;
    }).join('');

    $$('.hk-list-item', container).forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.officeId;
        const office = state.offices.find((o) => o.office_id === id);
        if (office) selectOffice(office);
      });
    });
  }

  function renderProvinces() {
    const sel = $('provinceSelect');
    if (sel.options.length > 1) return;  // already populated
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
      toast(t('hk.office.provinceRequired', 'Please pick a province first.'), 'error');
      return;
    }
    if (!address) {
      toast(t('hk.office.addressRequired', 'Please enter your address.'), 'error');
      return;
    }

    try {
      const data = await api(
        `/resolve-office?province=${encodeURIComponent(province)}&address=${encodeURIComponent(address)}`
      );
      const matches = data.matches || [];
      resultsEl.hidden = false;

      if (matches.length === 0) {
        resultsEl.innerHTML = `
          <div class="hk-resolve-empty">
            ${escapeHtml(t('hk.office.noResolveMatch',
              "Couldn't match your address to an office. Try picking from the list instead."))}
          </div>
        `;
        return;
      }

      const hint = matches.length === 1
        ? t('hk.office.oneMatch', 'We found your office:')
        : t('hk.office.manyMatches', 'Multiple matches — pick one:');

      resultsEl.innerHTML = `
        <p class="hk-resolve-hint">${escapeHtml(hint)}</p>
        ${matches.map((m) => `
          <button class="hk-list-item" data-office-id="${escapeHtml(m.office_id)}">
            <span class="hk-item-icon">📍</span>
            <span class="hk-item-body">
              <span class="hk-item-title">${escapeHtml(m.name_en)}</span>
              <span class="hk-item-sub">${escapeHtml(m.name_ko || '')} · ${escapeHtml(m.matched_district || '')}</span>
            </span>
            <span class="hk-item-arrow">→</span>
          </button>
        `).join('')}
      `;
      $$('.hk-list-item', resultsEl).forEach((btn) => {
        btn.addEventListener('click', () => {
          const id = btn.dataset.officeId;
          const office = state.offices.find((o) => o.office_id === id);
          if (office) selectOffice(office);
        });
      });
    } catch (e) {
      toast(t('hk.err.resolve', 'Could not look up office'), 'error');
      console.error(e);
    }
  }

  function selectOffice(office) {
    state.selectedOffice = office;
    haptic('select');
    enterBoothPicker();
  }

  // ---------------------------------------------------------------------
  // SECTION 3: BOOTH PICKER
  // ---------------------------------------------------------------------

  function enterBoothPicker() {
    const o = state.selectedOffice;
    $('boothOfficeName').textContent = o.name_en;
    renderBoothList(o.desks || []);
    showSection('booth');
  }

  function renderBoothList(desks) {
    const container = $('boothList');
    if (!desks.length) {
      container.innerHTML = `
        <div class="hk-resolve-empty">${escapeHtml(t('hk.booth.none', 'No booths available for this office.'))}</div>
      `;
      return;
    }
    container.innerHTML = desks.map((d) => `
      <button class="hk-list-item" data-desk-seq="${d.desk_seq}">
        <span class="hk-item-icon">🎫</span>
        <span class="hk-item-body">
          <span class="hk-item-title">${escapeHtml(d.booth || ('Desk ' + d.desk_seq))}</span>
          ${d.details ? `<span class="hk-item-sub">${escapeHtml(d.details)}</span>` : ''}
        </span>
        <span class="hk-item-arrow">→</span>
      </button>
    `).join('');

    $$('.hk-list-item', container).forEach((btn) => {
      btn.addEventListener('click', () => {
        const seq = parseInt(btn.dataset.deskSeq, 10);
        const desk = desks.find((d) => d.desk_seq === seq);
        if (desk) selectDesk(desk);
      });
    });
  }

  function selectDesk(desk) {
    state.selectedDesk = {
      desk_seq: desk.desk_seq,
      booth: desk.booth,
      details: desk.details,
      office_id:      state.selectedOffice.office_id,
      office_name_en: state.selectedOffice.name_en,
      office_name_ko: state.selectedOffice.name_ko,
    };
    haptic('select');
    if (state.mode === 'calendar') enterCalendar();
    else                            enterAlarmSetup();
  }

  // ---------------------------------------------------------------------
  // SECTION 4: CALENDAR VIEW
  // ---------------------------------------------------------------------

  async function enterCalendar() {
    const d = state.selectedDesk;
    $('calOfficeName').textContent = d.office_name_en;
    $('calBoothName').textContent  = d.booth || ('Desk ' + d.desk_seq);
    $('calList').innerHTML = `
      <div class="hk-skeleton-row"></div>
      <div class="hk-skeleton-row"></div>
      <div class="hk-skeleton-row"></div>
    `;
    showSection('calendar');

    try {
      const data = await api(`/desks/${d.desk_seq}/slots`);
      renderCalendar(data);
    } catch (e) {
      $('calList').innerHTML = `
        <div class="hk-cal-empty">
          <div class="hk-cal-empty-icon">⚠️</div>
          <p class="hk-cal-empty-title">${escapeHtml(t('hk.err.slotsTitle', "Couldn't load slots"))}</p>
          <p class="hk-cal-empty-sub">${escapeHtml(t('hk.err.slotsSub', 'Try again in a moment.'))}</p>
        </div>
      `;
      console.error(e);
    }
  }

  function renderCalendar(data) {
    const meta = $('calMeta');
    const list = $('calList');

    const chips = [];
    if (data.capacity != null) {
      chips.push(`<span class="hk-meta-chip">📊 ${t('hk.cal.capacity', 'Capacity')}: ${data.capacity}</span>`);
    }
    if (data.last_polled_at) {
      chips.push(`<span class="hk-meta-chip">🕒 ${relativeTime(data.last_polled_at)}</span>`);
    }
    meta.innerHTML = chips.join('');

    const dates = data.dates || [];
    if (!dates.length) {
      list.innerHTML = `
        <div class="hk-cal-empty">
          <div class="hk-cal-empty-icon">📅</div>
          <p class="hk-cal-empty-title">${escapeHtml(t('hk.cal.emptyTitle', 'No open dates right now'))}</p>
          <p class="hk-cal-empty-sub">${escapeHtml(t('hk.cal.emptySub', 'All visible dates are fully booked. Set an alarm and we\'ll watch for openings.'))}</p>
        </div>
      `;
      return;
    }

    // Group rows by month label
    const out = [];
    let lastMonth = null;
    dates.forEach((row) => {
      const month = monthLabel(row.visi_ymd);
      if (month !== lastMonth) {
        out.push(`<div class="hk-cal-month">${escapeHtml(month)}</div>`);
        lastMonth = month;
      }
      const avail = row.available;
      const cap   = data.capacity;
      const klass = availClass(avail, cap);
      const badge = (avail != null && cap != null)
        ? `${avail} / ${cap}`
        : `${t('hk.cal.taken', 'taken')}: ${row.taken}`;
      out.push(`
        <div class="hk-cal-row">
          <div class="hk-cal-date">
            <span class="hk-cal-day">${escapeHtml(fmtPrettyDate(row.visi_ymd))}</span>
            <span class="hk-cal-dow">${escapeHtml(dowLabel(row.visi_ymd))}</span>
          </div>
          <span class="hk-avail-badge ${klass}">${escapeHtml(badge)}</span>
        </div>
      `);
    });
    list.innerHTML = out.join('');
  }

  function bindCalendar() {
    $('goToAlarmBtn').addEventListener('click', () => {
      haptic('light');
      state.mode = 'alarm';
      enterAlarmSetup();
    });
  }

  // ---------------------------------------------------------------------
  // SECTION 5: ALARM SETUP
  // ---------------------------------------------------------------------

  function enterAlarmSetup() {
    const d = state.selectedDesk;
    $('alOfficeName').textContent = d.office_name_en;
    $('alBoothName').textContent  = d.booth || ('Desk ' + d.desk_seq);

    // Default dates: tomorrow → +14 days
    const tomorrow = addDays(new Date(), 1);
    const inTwoWeeks = addDays(new Date(), 14);
    $('alStartDate').valueAsDate = tomorrow;
    $('alEndDate').valueAsDate   = inTwoWeeks;
    $('alStartDate').min = dateToIsoDateInput(new Date());
    $('alEndDate').min   = dateToIsoDateInput(new Date());

    $('availableWarn').hidden = true;
    updatePresetSelection();
    updatePreview();
    showSection('alarm');
  }

  function dateToIsoDateInput(d) {
    // YYYY-MM-DD for <input type="date">
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  function bindAlarmSetup() {
    $$('.hk-preset').forEach((btn) => {
      btn.addEventListener('click', () => {
        const preset = btn.dataset.preset;
        haptic('light');
        if (preset === 'custom') {
          updatePresetSelection('custom');
          return;
        }
        const days = parseInt(preset, 10);
        const start = addDays(new Date(), 1);
        const end   = addDays(new Date(), days);
        $('alStartDate').valueAsDate = start;
        $('alEndDate').valueAsDate   = end;
        updatePresetSelection(preset);
        updatePreview();
      });
    });

    ['alStartDate', 'alEndDate'].forEach((id) => {
      $(id).addEventListener('change', () => {
        updatePresetSelection('custom');
        updatePreview();
      });
    });

    $('submitAlarmBtn').addEventListener('click', () => submitAlarm(false));
    $('forceAlarmBtn').addEventListener('click', () => submitAlarm(true));

    $('successOk').addEventListener('click', () => {
      $('successOverlay').hidden = true;
      state.overlayOpen = false;
      // Reset the back-stack — pressing Back from "My Alarms" should land
      // on Entry, not walk back through the wizard.
      state.navStack = ['entry'];
      enterMyAlarms();
    });
  }

  function updatePresetSelection(preset) {
    $$('.hk-preset').forEach((btn) => {
      btn.classList.toggle('active', preset && btn.dataset.preset === preset);
    });
  }

  function updatePreview() {
    const startStr = $('alStartDate').value;
    const endStr   = $('alEndDate').value;
    if (!startStr || !endStr) {
      $('alarmPreview').hidden = true;
      return;
    }
    const start = new Date(startStr);
    const end   = new Date(endStr);
    if (isNaN(start) || isNaN(end) || end < start) {
      $('alarmPreview').hidden = true;
      return;
    }
    $('alarmPreview').hidden = false;
    const days = Math.round((end - start) / 86400000) + 1;
    $('previewRange').textContent = `${dateToIsoDateInput(start)} → ${dateToIsoDateInput(end)}`;
    $('previewDays').textContent = `${days} ${t('hk.alarm.daysWord', 'day(s)')}`;
  }

  function startEndYmds() {
    const start = $('alStartDate').value;  // "YYYY-MM-DD"
    const end   = $('alEndDate').value;
    if (!start || !end) return null;
    return {
      start_ymd: start.replace(/-/g, ''),
      end_ymd:   end.replace(/-/g, ''),
    };
  }

  async function submitAlarm(force) {
    if (!state.user) {
      toast(t('hk.err.noUser', 'Open this page via the Telegram bot first.'), 'error');
      return;
    }
    const ymds = startEndYmds();
    if (!ymds) {
      toast(t('hk.alarm.pickDates', 'Pick a start and end date.'), 'error');
      return;
    }

    const btn = $('submitAlarmBtn');
    btn.disabled = true;

    try {
      const body = {
        telegram_user_id:  state.user.id,
        telegram_username: state.user.username,
        desk_seq:          state.selectedDesk.desk_seq,
        start_ymd:         ymds.start_ymd,
        end_ymd:           ymds.end_ymd,
        force:             !!force,
      };
      await api('/watches', { method: 'POST', body });
      haptic('ok');
      $('availableWarn').hidden = true;
      $('successOverlay').hidden = false;
      state.overlayOpen = true;
      refreshMyAlarmsCount();
    } catch (e) {
      console.error(e);
      if (e.status === 409 && e.data && e.data.error === 'available_slots_in_range') {
        renderAvailableWarn(e.data.available_dates || []);
        haptic('warning');
      } else if (e.status === 409 && e.data && e.data.error === 'duplicate_watch') {
        toast(t('hk.alarm.dupErr', 'You already have an identical alarm.'), 'error');
        haptic('err');
      } else if (e.status === 409 && e.data && e.data.error === 'max_watches_reached') {
        toast(t('hk.alarm.maxErr', 'Maximum 10 alarms reached. Cancel one first.'), 'error');
        haptic('err');
      } else if (e.status === 400 && e.data && e.data.fields) {
        const first = Object.values(e.data.fields)[0];
        toast(first || t('hk.alarm.validation', 'Check your inputs.'), 'error');
        haptic('err');
      } else {
        toast(t('hk.alarm.submitErr', "Couldn't create alarm. Try again."), 'error');
        haptic('err');
      }
    } finally {
      btn.disabled = false;
    }
  }

  function renderAvailableWarn(availableDates) {
    const warn = $('availableWarn');
    const datesEl = $('availableWarnDates');
    datesEl.innerHTML = availableDates.map((d) => `
      <span class="hk-warn-date">${escapeHtml(fmtPrettyDate(d.visi_ymd))} — ${d.available}/${d.capacity}</span>
    `).join('');
    warn.hidden = false;
    warn.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }

  // ---------------------------------------------------------------------
  // SECTION 6: MY ALARMS
  // ---------------------------------------------------------------------

  async function enterMyAlarms() {
    showSection('my-alarms');
    $('myAlarmsList').innerHTML = `<div class="hk-skeleton-row"></div><div class="hk-skeleton-row"></div>`;
    $('myAlarmsEmpty').hidden = true;

    if (!state.user) {
      $('myAlarmsList').innerHTML = '';
      $('myAlarmsEmpty').hidden = false;
      $('myAlarmsEmpty').querySelector('.hk-empty-title').textContent =
        t('hk.err.noUser', 'Open this page via the Telegram bot first.');
      $('myAlarmsEmpty').querySelector('.hk-empty-sub').textContent = '';
      return;
    }

    try {
      const data = await api(
        `/watches?telegram_user_id=${encodeURIComponent(state.user.id)}&status=active`
      );
      renderMyAlarms(data.watches || []);
    } catch (e) {
      $('myAlarmsList').innerHTML = `
        <div class="hk-resolve-empty">${escapeHtml(t('hk.err.loadAlarms', 'Could not load your alarms'))}</div>
      `;
      console.error(e);
    }
  }

  function renderMyAlarms(watches) {
    const list = $('myAlarmsList');
    if (!watches.length) {
      list.innerHTML = '';
      $('myAlarmsEmpty').hidden = false;
      return;
    }
    $('myAlarmsEmpty').hidden = true;
    list.innerHTML = watches.map((w) => `
      <div class="hk-alarm-card status-${escapeHtml(w.status)}">
        <div class="hk-alarm-head">
          <div>
            <div class="hk-alarm-office">${escapeHtml(w.office_name_en || '?')}</div>
            <div class="hk-alarm-booth">${escapeHtml(w.booth || ('Desk ' + w.desk_seq))}</div>
          </div>
          <span class="hk-alarm-status ${escapeHtml(w.status)}">${escapeHtml(w.status)}</span>
        </div>
        <div class="hk-alarm-range">
          📅 ${escapeHtml(fmtPrettyDate(w.start_ymd))} → ${escapeHtml(fmtPrettyDate(w.end_ymd))}
        </div>
        <div class="hk-alarm-actions">
          <button class="hk-cancel-btn" data-watch-id="${w.id}">
            ${escapeHtml(t('hk.myAlarms.cancel', 'Cancel'))}
          </button>
        </div>
      </div>
    `).join('');

    $$('.hk-cancel-btn', list).forEach((btn) => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.watchId;
        btn.disabled = true;
        try {
          await api(`/watches/${id}?telegram_user_id=${encodeURIComponent(state.user.id)}`,
                    { method: 'DELETE' });
          haptic('ok');
          toast(t('hk.myAlarms.cancelled', 'Alarm cancelled'), 'success');
          enterMyAlarms();
          refreshMyAlarmsCount();
        } catch (e) {
          btn.disabled = false;
          toast(t('hk.err.cancel', "Couldn't cancel alarm"), 'error');
          haptic('err');
        }
      });
    });
  }

  // ---------------------------------------------------------------------
  // I18N — update labels after init
  // ---------------------------------------------------------------------

  function applyTranslations() {
    $$('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      const trans = t(key, null);
      if (trans !== null) {
        if (trans.includes('<') && trans.includes('>')) el.innerHTML = trans;
        else el.textContent = trans;
      }
    });
    $$('[data-i18n-placeholder]').forEach((el) => {
      const key = el.getAttribute('data-i18n-placeholder');
      const trans = t(key, null);
      if (trans !== null) el.setAttribute('placeholder', trans);
    });

    const titleKey = document.querySelector('title')?.getAttribute('data-i18n');
    if (titleKey) {
      const tr = t(titleKey, null);
      if (tr) document.title = tr;
    }
  }

  window.addEventListener('languageChanged', applyTranslations);

  // ---------------------------------------------------------------------
  // BACK-BUTTON BINDING (in-page "← Back" buttons)
  // ---------------------------------------------------------------------

  function bindInPageBackButtons() {
    $$('[data-back]').forEach((el) => {
      el.addEventListener('click', handleBack);
    });
  }

  // ---------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------

  document.addEventListener('DOMContentLoaded', () => {
    applyTranslations();
    bindEntry();
    bindOfficePickerTabs();
    bindCalendar();
    bindAlarmSetup();
    bindInPageBackButtons();

    $('officeSearch').addEventListener('input', (e) => {
      renderOfficeList(e.target.value);
    });
    $('resolveBtn').addEventListener('click', doResolveOffice);
    $('addressInput').addEventListener('keypress', (e) => {
      if (e.key === 'Enter') doResolveOffice();
    });

    showSection('entry', { silent: true });
    refreshStatusPill();
    refreshMyAlarmsCount();

    console.log('✅ HiKorea page loaded',
                state.user ? `user=${state.user.id}` : '(no telegram user)');
  });

})();
