/* =========================================================
   HOUSING — housing.js

   Wired to the element IDs declared in Phase 3 and the API
   contract from Phase 1 (/api/housing).

   Two sort modes over one list: 'recent' (keyset cursor) and
   'distance' (offset cursor bound to a geocoded origin).
   Switching modes resets the list and the cursor.

   Nothing on a card is derived or parsed. Every value comes
   from the API response.
   ========================================================= */

(function () {
  'use strict';

  // =========================================================
  // Telegram + config
  // =========================================================

  var tg = (window.Telegram && window.Telegram.WebApp) ? window.Telegram.WebApp : null;

  var API_BASE = (function () {
    var base = (window.API_CONFIG && window.API_CONFIG.BASE_URL)
      || window.API_BASE
      || 'https://vegukin-api.duckdns.org';
    return String(base).replace(/\/+$/, '');
  })();

  var API = API_BASE + '/api/housing';
  var INIT_DATA = (tg && tg.initData) ? tg.initData : '';

  var LIMIT = 20;
  var BODY_MAX = 4000;
  var BODY_MIN = 20;

  // =========================================================
  // Elements
  // =========================================================

  function $(id) { return document.getElementById(id); }

  var el = {
    shell: $('hsShell'),
    pull: $('hsPull'),

    navBrowse: $('hsNavBrowse'),
    navMine: $('hsNavMine'),
    navAlerts: $('hsNavAlerts'),

    viewBrowse: $('hsViewBrowse'),
    viewMine: $('hsViewMine'),
    viewCompose: $('hsViewCompose'),
    viewAlerts: $('hsViewAlerts'),

    searchForm: $('hsSearchForm'),
    addressInput: $('hsAddressInput'),
    searchBtn: $('hsSearchBtn'),
    searchHint: $('hsSearchHint'),

    sortLabel: $('hsSortLabel'),
    boardCount: $('hsBoardCount'),
    modeChip: $('hsModeChip'),
    modeChipText: $('hsModeChipText'),
    modeChipClear: $('hsModeChipClear'),

    skeleton: $('hsSkeleton'),
    list: $('hsList'),
    more: $('hsMore'),
    loadMoreBtn: $('hsLoadMoreBtn'),
    listEnd: $('hsListEnd'),
    sentinel: $('hsSentinel'),
    empty: $('hsEmpty'),
    geoError: $('hsGeoError'),
    geoErrorRetry: $('hsGeoErrorRetry'),
    error: $('hsError'),
    errorRetry: $('hsErrorRetry'),

    mineCount: $('hsMineCount'),
    mineSkeleton: $('hsMineSkeleton'),
    mineList: $('hsMineList'),
    mineEmpty: $('hsMineEmpty'),
    mineError: $('hsMineError'),
    mineRetry: $('hsMineRetry'),

    composeTitle: $('hsComposeTitle'),
    composeForm: $('hsComposeForm'),
    composeAddress: $('hsComposeAddress'),
    composeAddressHint: $('hsComposeAddressHint'),
    composeAddressLock: $('hsComposeAddressLock'),
    composeContact: $('hsComposeContact'),
    composeBody: $('hsComposeBody'),
    composeBodyCount: $('hsComposeBodyCount'),
    composeError: $('hsComposeError'),
    composeSubmit: $('hsComposeSubmit'),
    tgRow: $('hsTgRow'),
    tgCheck: $('hsTgCheck'),
    tgField: $('hsTgField'),
    tgUsername: $('hsTgUsername'),
    tgHint: $('hsTgHint'),
    tgOwn: $('hsTgOwn'),

    tabbar: $('hsTabbar'),
    navCompose: $('hsNavCompose'),

    backdrop: $('hsSheetBackdrop'),
    sheet: $('hsSheet'),
    sheetLoading: $('hsSheetLoading'),
    sheetError: $('hsSheetError'),
    sheetErrorRetry: $('hsSheetErrorRetry'),
    sheetContent: $('hsSheetContent'),
    sheetRegion: $('hsSheetRegion'),
    sheetAddress: $('hsSheetAddress'),
    sheetTime: $('hsSheetTime'),
    sheetDistance: $('hsSheetDistance'),
    sheetBody: $('hsSheetBody'),
    sheetContactRow: $('hsSheetContactRow'),
    sheetPhoneRow: $('hsSheetPhoneRow'),
    sheetPhoneHint: $('hsSheetPhoneHint'),
    sheetCall: $('hsSheetCall'),
    sheetCallNum: $('hsSheetCallNum'),
    sheetCopy: $('hsSheetCopy'),
    sheetNoContact: $('hsSheetNoContact'),
    sheetTelegram: $('hsSheetTelegram'),
    sheetTelegramLabel: $('hsSheetTelegramLabel'),
    sheetOwner: $('hsSheetOwnerActions'),
    sheetEdit: $('hsSheetEdit'),
    sheetDelete: $('hsSheetDelete'),
    sheetClose: $('hsSheetClose'),

    alertCount: $('hsAlertCount'),
    alertForm: $('hsAlertForm'),
    alertAddress: $('hsAlertAddress'),
    alertRadius: $('hsAlertRadius'),
    alertRadiusInput: $('hsAlertRadiusInput'),
    alertSubmit: $('hsAlertSubmit'),
    alertError: $('hsAlertError'),
    alertSkeleton: $('hsAlertSkeleton'),
    alertList: $('hsAlertList'),
    alertEmpty: $('hsAlertEmpty'),
    alertsError: $('hsAlertsError'),
    alertsRetry: $('hsAlertsRetry'),
    alertTemplate: $('hsAlertTemplate'),

    toast: $('hsToast'),

    cardTemplate: $('hsCardTemplate'),
    mineCardTemplate: $('hsMineCardTemplate')
  };

  // =========================================================
  // State
  // =========================================================

  var state = {
    view: 'browse',
    sort: 'recent',
    cursor: null,
    origin: null,          // { lat, lon, label }
    loading: false,
    done: false,
    count: 0,
    sheetPostId: null,
    sheetPost: null,
    sheetDistance: null,
    lastDistances: {},     // post_id -> km, so the sheet can show it
    composeMode: 'create',
    composePostId: null,
    submitting: false,
    alertRadius: 10,
    alertSubmitting: false,
    myUsername: null,
    meLoaded: false,
    pendingRefresh: false,
    geocoding: false
  };

  // =========================================================
  // Small helpers
  // =========================================================

  function show(node) { if (node) node.hidden = false; }
  function hide(node) { if (node) node.hidden = true; }
  function setText(node, value) { if (node) node.textContent = value == null ? '' : String(value); }

  function haptic(type) {
    try {
      if (!tg || !tg.HapticFeedback) return;
      if (type === 'error' || type === 'success' || type === 'warning') {
        tg.HapticFeedback.notificationOccurred(type);
      } else {
        tg.HapticFeedback.impactOccurred(type || 'light');
      }
    } catch (e) { /* older clients */ }
  }

  var toastTimer = null;
  function toast(message, isError) {
    if (!el.toast) return;
    el.toast.innerHTML = '';
    var icon = document.createElement('span');
    icon.className = 'hs-toast__icon' + (isError ? ' hs-toast__icon--error' : '');
    icon.textContent = isError ? '!' : '\u2713';
    var text = document.createElement('span');
    text.className = 'hs-toast__text';
    text.textContent = message;
    el.toast.appendChild(icon);
    el.toast.appendChild(text);
    el.toast.classList.toggle('hs-toast--error', !!isError);
    show(el.toast);
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { hide(el.toast); }, 3200);
  }

  /* Korean addresses read outside-in. Peel the administrative
     prefix into the eyebrow and leave the line that actually
     identifies the place as the heading. Falls back to showing
     the whole string when the pattern does not match. */
  var ADMIN_TAIL = /(특별자치시|특별자치도|특별시|광역시|시|도|군|구)$/;

  // Kakao often returns provinces in their short form ("경기", "서울"),
  // which the suffix rule cannot catch.
  var SHORT_REGIONS = {
    '서울': 1, '부산': 1, '대구': 1, '인천': 1, '광주': 1, '대전': 1,
    '울산': 1, '세종': 1, '경기': 1, '강원': 1, '충북': 1, '충남': 1,
    '전북': 1, '전남': 1, '경북': 1, '경남': 1, '제주': 1
  };

  function splitAddress(full) {
    var text = String(full || '').trim();
    if (!text) return { region: '', rest: '' };
    var parts = text.split(/\s+/);
    if (parts.length < 3) return { region: '', rest: text };

    var region = [];
    for (var i = 0; i < parts.length - 1 && region.length < 3; i++) {
      if (ADMIN_TAIL.test(parts[i]) || (i === 0 && SHORT_REGIONS[parts[i]])) {
        region.push(parts[i]);
      } else break;
    }
    if (!region.length) return { region: '', rest: text };
    // "경기도 안산시 단원구" reads better as "경기도 · 안산시 단원구":
    // province, then the city/district pair it contains.
    var head = region[0];
    var tail = region.slice(1).join(' ');
    return {
      region: tail ? head + ' · ' + tail : head,
      rest: parts.slice(region.length).join(' ')
    };
  }

  /* 01012345678 -> 010-1234-5678. Leaves anything that is not a bare
     Korean number alone: KakaoTalk IDs, +82 forms, already-dashed input. */
  function formatPhone(value) {
    var raw = String(value || '').trim();
    if (!/^[\d\s-]+$/.test(raw)) return raw;
    var d = raw.replace(/\D/g, '');
    if (d.length === 11 && d.charAt(0) === '0') {
      return d.slice(0, 3) + '-' + d.slice(3, 7) + '-' + d.slice(7);
    }
    if (d.length === 10 && d.slice(0, 2) === '02') {
      return '02-' + d.slice(2, 6) + '-' + d.slice(6);
    }
    if (d.length === 10 && d.charAt(0) === '0') {
      return d.slice(0, 3) + '-' + d.slice(3, 6) + '-' + d.slice(6);
    }
    return raw;
  }

  /* Korean numbers group differently by prefix. 010 is always 3-4-4, so it
     never reflows mid-typing; Seoul 02 and the older 01x/area codes depend on
     the final length. */
  function phoneGroups(d) {
    if (d.slice(0, 2) === '02') return d.length <= 9 ? [2, 3, 4] : [2, 4, 4];
    if (d.slice(0, 3) === '010') return [3, 4, 4];
    return d.length <= 10 ? [3, 3, 4] : [3, 4, 4];
  }

  /* Partial-friendly: formats whatever digits exist so far, so the dash
     appears the moment you cross a boundary instead of at the end. */
  function formatPhoneProgressive(raw) {
    var d = String(raw || '').replace(/\D/g, '');
    if (!d) return '';
    // Longer than any Korean number — probably foreign; leave it alone.
    if (d.length > 11) return raw;

    var groups = phoneGroups(d);
    var out = [];
    var i = 0;
    for (var k = 0; k < groups.length && i < d.length; k++) {
      out.push(d.slice(i, i + groups[k]));
      i += groups[k];
    }
    if (i < d.length) out.push(d.slice(i));
    return out.join('-');
  }

  /* Live formatting while typing. Only touches digit-only input — KakaoTalk
     IDs and +82 forms pass through — and restores the caret by digit count,
     so editing in the middle of the number stays where you put it. */
  function bindPhoneFormatting(input) {
    if (!input) return;
    input.addEventListener('input', function () {
      var v = input.value;
      if (!/^[\d\s-]*$/.test(v)) return;

      var caret = input.selectionStart;
      var digitsBefore = (v.slice(0, caret).match(/\d/g) || []).length;

      var next = formatPhoneProgressive(v);
      if (next === v) return;
      input.value = next;

      var pos = 0;
      var seen = 0;
      while (pos < next.length && seen < digitsBefore) {
        if (/\d/.test(next.charAt(pos))) seen++;
        pos++;
      }
      try { input.setSelectionRange(pos, pos); } catch (e) {}
    });
  }

  function formatDistance(km) {
    var n = Number(km);
    if (!isFinite(n)) return '';
    if (n < 10) return n.toFixed(1);
    return String(Math.round(n));
  }

  function plural(n, word) { return n + ' ' + word; }

  function retryAfterText(seconds) {
    var s = Number(seconds) || 0;
    if (s <= 90) return plural(Math.max(1, Math.round(s)), 'soniya');
    return plural(Math.max(1, Math.round(s / 60)), 'daqiqa');
  }

  var ERRORS = {
    unauthorized: 'Buning uchun ilovani Telegram orqali oching.',
    forbidden: 'Bu e\u02bblon sizniki emas.',
    not_found: 'E\u02bblon topilmadi.',
    gone: 'E\u02bblon o\u02bbchirilgan yoki muddati tugagan.',
    address_immutable: 'Manzilni o\u02bbzgartirib bo\u02bblmaydi.',
    geocode_unavailable: 'Manzil xizmati javob bermayapti. Birozdan keyin urinib ko\u02bbring.',
    service_unavailable: 'Xizmat vaqtincha ishlamayapti.',
    cursor_invalid: 'Ro\u02bbyxatni yangilash kerak.',
    cursor_mode_mismatch: 'Ro\u02bbyxatni yangilash kerak.',
    cursor_origin_mismatch: 'Ro\u02bbyxatni yangilash kerak.',
    internal_error: 'Serverda xatolik yuz berdi.',
    bad_request: 'So\u02bbrovda xatolik.'
  };

  function errorText(err) {
    if (!err) return 'Xatolik yuz berdi.';
    if (err.code === 'rate_limited') {
      var after = err.data && err.data.retry_after;
      return after
        ? 'Juda ko\u02bbp urinish. ' + retryAfterText(after) + 'dan keyin qayta urining.'
        : 'Juda ko\u02bbp urinish. Birozdan keyin qayta urining.';
    }
    if (ERRORS[err.code]) return ERRORS[err.code];
    if (err.offline) return 'Serverga ulanib bo\u02bblmadi. Qayta urinib ko\u02bbring.';
    return 'Xatolik yuz berdi.';
  }

  // =========================================================
  // API
  // =========================================================

  function api(path, options) {
    var opts = options || {};
    var headers = {};
    if (opts.body) headers['Content-Type'] = 'application/json';
    if (opts.auth) headers['X-Init-Data'] = INIT_DATA;

    return fetch(API + path, {
      method: opts.method || 'GET',
      headers: headers,
      body: opts.body ? JSON.stringify(opts.body) : undefined
    }).then(function (res) {
      return res.text().then(function (raw) {
        var data = null;
        try { data = raw ? JSON.parse(raw) : null; } catch (e) { data = null; }
        if (!res.ok) {
          var err = new Error((data && data.error) || ('http_' + res.status));
          err.code = (data && data.error) || null;
          err.status = res.status;
          err.data = data;
          throw err;
        }
        return data;
      });
    }, function (cause) {
      // A CORS block and a dead network look identical here; the console
      // line is what tells them apart.
      try { console.error('housing: request failed', path, cause); } catch (e) {}
      var err = new Error('network');
      err.offline = true;
      return Promise.reject(err);
    });
  }

  /* The compose form shows the poster their own handle next to the opt-in, so
     they can see exactly what would be published. Fetched once per session. */
  function loadMe() {
    if (state.meLoaded || !INIT_DATA) return Promise.resolve();
    return api('/me', { auth: true })
      .then(function (data) {
        state.meLoaded = true;
        state.myUsername = data.username || null;
      })
      .catch(function () { state.meLoaded = true; });
  }

  var TG_USERNAME = /^[A-Za-z][A-Za-z0-9_]{4,31}$/;

  /* Accepts '@name', 'name', 't.me/name' and full URLs — people paste all
     four. Mirrors normalize_username() on the server. */
  function normalizeUsername(v) {
    var raw = String(v || '').trim();
    if (!raw) return '';
    raw = raw.replace(/^https?:\/\//i, '').replace(/^(www\.)?t\.me\//i, '');
    return raw.replace(/^@+/, '').trim();
  }

  /* The typed field is an override, not a replacement: it is prefilled with
     the poster's own handle, so the common case is still zero effort, while
     posting on someone's behalf or from a second account stays possible. */
  function syncTelegramOptIn(checked, override) {
    var own = state.myUsername || '';
    if (el.tgOwn) setText(el.tgOwn, own ? '@' + own : '—');
    if (el.tgHint) el.tgHint.hidden = !own;
    if (el.tgCheck) el.tgCheck.checked = !!checked;
    if (el.tgUsername) el.tgUsername.value = override || (checked ? own : '') || '';
    syncTelegramField();
  }

  function syncTelegramField() {
    var on = !!(el.tgCheck && el.tgCheck.checked);
    if (el.tgField) el.tgField.hidden = !on;
    if (el.tgHint) el.tgHint.hidden = !on || !state.myUsername;
    if (on && el.tgUsername && !el.tgUsername.value && state.myUsername) {
      el.tgUsername.value = state.myUsername;
    }
  }

  function telegramPayload() {
    var on = !!(el.tgCheck && el.tgCheck.checked);
    return {
      show_username: on,
      contact_username: on ? normalizeUsername(el.tgUsername && el.tgUsername.value) : ''
    };
  }

  function requireAuth() {
    if (INIT_DATA) return true;
    toast(ERRORS.unauthorized, true);
    return false;
  }

  // =========================================================
  // View switching
  // =========================================================

  var VIEWS = {
    browse: el.viewBrowse,
    mine: el.viewMine,
    compose: el.viewCompose,
    alerts: el.viewAlerts
  };

  var NAV = {
    browse: el.navBrowse,
    mine: el.navMine,
    alerts: el.navAlerts,
    compose: el.navCompose
  };

  var ACTIVE_TAB = 'hs-tab--active';

  /* ---------------------------------------------------------
     Routing

     Every screen change is a History entry, so the phone's own
     back gesture and Telegram's back arrow walk the same trail.
     The entry for the board itself is written with replaceState,
     which means back from the board leaves for index.html —
     the page the user arrived from.
     --------------------------------------------------------- */

  function routeDepth() {
    try {
      return (history.state && typeof history.state.d === 'number') ? history.state.d : 0;
    } catch (e) { return 0; }
  }

  function pushRoute(route) {
    route.d = routeDepth() + 1;
    try { history.pushState(route, ''); } catch (e) {}
  }

  function replaceRoute(route) {
    route.d = routeDepth();
    try { history.replaceState(route, ''); } catch (e) {}
  }

  function navigate(route) {
    pushRoute(route);
    applyRoute(route);
  }

  function applyRoute(route, fromPop) {
    var target = route || { v: 'browse', sheet: null };

    if (target.sheet) {
      if (state.sheetPostId !== target.sheet) openSheetUI(target.sheet);
    } else if (state.sheetPostId) {
      closeSheetUI();
    }

    if (state.view !== target.v) applyView(target.v);
    else { syncMainButton(); syncBackButton(); }
  }

  /* Some actions finish by unwinding one History entry rather than pushing a
     new one — submitting a form, deleting a post. Popping keeps the trail
     clean (no duplicate entries, no back press that appears to do nothing),
     but the data underneath needs refreshing once we land. */
  function backAndRefresh() {
    state.pendingRefresh = true;
    history.back();
  }

  function onPopState(ev) {
    var before = state.view;
    applyRoute(ev.state, true);
    if (!state.pendingRefresh) return;
    state.pendingRefresh = false;
    if (state.sheetPostId) return;               // the sheet refetches itself
    if (before !== state.view) return;           // applyView already reloaded
    if (state.view === 'browse') loadPosts(true);
    else if (state.view === 'mine') loadMine();
    else if (state.view === 'alerts') loadAlerts();
  }

  function applyView(name) {
    state.view = name;
    Object.keys(VIEWS).forEach(function (key) {
      if (VIEWS[key]) VIEWS[key].hidden = (key !== name);
    });
    Object.keys(NAV).forEach(function (key) {
      if (!NAV[key]) return;
      var active = (key === name);
      NAV[key].classList.toggle(ACTIVE_TAB, active);
      if (active) NAV[key].setAttribute('aria-current', 'page');
      else NAV[key].removeAttribute('aria-current');
    });
    // With submission living inside the form, the tab bar can stay put on
    // every screen — tapping another tab doubles as "cancel".
    if (el.tabbar) el.tabbar.hidden = false;
    if (el.shell) el.shell.scrollTop = 0;
    syncMainButton();
    syncBackButton();

    if (name === 'mine') loadMine();
    if (name === 'alerts') loadAlerts();
  }

  // =========================================================
  // Telegram chrome
  // =========================================================

  function mainButtonAvailable() {
    return !!(tg && tg.MainButton && typeof tg.MainButton.show === 'function'
      && tg.platform && tg.platform !== 'unknown');
  }

  /* Submission lives inside the form as a normal button, so Telegram's
     MainButton is retired entirely — one bottom bar, no competition. */
  function syncMainButton() {
    if (mainButtonAvailable()) {
      try { tg.MainButton.hide(); } catch (e) {}
    }
    if (el.composeSubmit) {
      el.composeSubmit.textContent = state.composeMode === 'edit'
        ? 'O\u02bbzgarishlarni saqlash'
        : 'E\u02bblonni joylash';
    }
  }

  /* Kept visible even at the board root. On Android, Telegram routes the
     hardware back gesture to BackButton only while it is shown — hide it and
     the phone's back closes the whole Mini App instead of returning to the
     home screen. */
  function syncBackButton() {
    if (!tg || !tg.BackButton) return;
    try { tg.BackButton.show(); } catch (e) {}
  }

  // Telegram's back arrow and the phone's back gesture both land here.
  function onBack() {
    // Depth 0 is the board itself. Going "back" from there means leaving the
    // feature — done explicitly rather than through history, so it also works
    // when the Mini App was launched straight into this page.
    if (routeDepth() > 0) history.back();
    else window.location.href = '../../index.html';
  }

  function applyViewportHeight() {
    var h = (tg && tg.viewportStableHeight) ? tg.viewportStableHeight : window.innerHeight;
    if (h && h > 0) {
      document.documentElement.style.setProperty('--hs-vh', h + 'px');
    }
  }

  function initTelegram() {
    if (!tg) return;
    try { tg.ready(); } catch (e) {}
    try { tg.expand(); } catch (e) {}

    // Seed night mode from the client theme on first visit; localStorage wins after.
    try {
      if (!localStorage.getItem('theme') && tg.colorScheme === 'dark') {
        localStorage.setItem('theme', 'night');
        document.documentElement.classList.add('night-mode');
      }
    } catch (e) {}

    // Swiping down from the top is Telegram's "close the Mini App" gesture.
    // Without this, pull-to-refresh would dismiss the app instead.
    try { if (typeof tg.disableVerticalSwipes === 'function') tg.disableVerticalSwipes(); } catch (e) {}

    applyViewportHeight();
    try { tg.onEvent('viewportChanged', applyViewportHeight); } catch (e) {}
    try { tg.BackButton.onClick(onBack); } catch (e) {}
    try { tg.MainButton.hide(); } catch (e) {}
  }

  // =========================================================
  // Browse — list rendering
  // =========================================================

  function clearListStates() {
    hide(el.empty);
    hide(el.geoError);
    hide(el.error);
    hide(el.listEnd);
    hide(el.more);
  }

  function buildCard(post) {
    var node = el.cardTemplate.content.firstElementChild.cloneNode(true);
    node.dataset.postId = post.id;

    var split = splitAddress(post.address_display);
    var regionEl = node.querySelector('[data-field="region"]');
    if (split.region) setText(regionEl, split.region);
    else hide(regionEl);
    setText(node.querySelector('[data-field="address"]'), split.rest || post.address_display);

    var distWrap = node.querySelector('[data-field="distance-wrap"]');
    if (post.distance_km != null) {
      node.classList.add('hs-card--distance');
      setText(node.querySelector('[data-field="distance"]'), formatDistance(post.distance_km));
      show(distWrap);
      state.lastDistances[post.id] = post.distance_km;
    } else {
      hide(distWrap);
    }

    setText(node.querySelector('[data-field="preview"]'), post.body_preview || '');
    setText(node.querySelector('[data-field="time"]'), post.posted_rel_uz || '');

    if (post.is_new) show(node.querySelector('[data-field="new-badge"]'));
    if (post.is_mine) show(node.querySelector('[data-field="mine-badge"]'));

    var cta = node.querySelector('[data-field="cta"]');
        if (cta) {
          // A post carries a phone, a Telegram handle, or both — the muted
          // fallback belongs only to the case where it somehow has neither.
          if (post.has_contact) {
            cta.textContent = 'Raqamni ko\u02bbrish';
          } else if (post.has_telegram) {
            cta.textContent = 'Telegram orqali bog\u02bblanish';
          } else {
            cta.classList.add('hs-card__cta--muted');
            cta.textContent = 'Aloqa ma\u02bblumoti yo\u02bbq';
          }
        }

    node.addEventListener('click', function () { openSheet(post.id); });
    node.addEventListener('keydown', function (ev) {
      if (ev.key === 'Enter' || ev.key === ' ') { ev.preventDefault(); openSheet(post.id); }
    });
    return node;
  }

  function renderPosts(posts, append) {
    if (!append) el.list.innerHTML = '';
    var frag = document.createDocumentFragment();
    posts.forEach(function (post) { frag.appendChild(buildCard(post)); });
    el.list.appendChild(frag);
  }

  function updateCount() {
    if (!el.boardCount) return;
    var rendered = el.list.children.length;
    setText(el.boardCount, rendered ? plural(rendered, 'ta') : '');
  }

  function loadPosts(reset) {
    if (state.loading) return;
    if (reset) {
      state.cursor = null;
      state.done = false;
      state.lastDistances = {};
    }
    if (state.done) return;

    state.loading = true;
    clearListStates();
    if (reset) {
      el.list.innerHTML = '';
      show(el.skeleton);
    }

    var query = ['limit=' + LIMIT, 'sort=' + state.sort];
    if (state.sort === 'distance' && state.origin) {
      query.push('lat=' + encodeURIComponent(state.origin.lat));
      query.push('lon=' + encodeURIComponent(state.origin.lon));
    }
    if (state.cursor) query.push('cursor=' + encodeURIComponent(state.cursor));

    var headers = INIT_DATA ? { auth: true } : {};

    return api('/posts?' + query.join('&'), headers)
      .then(function (data) {
        hide(el.skeleton);
        state.loading = false;
        state.cursor = data.next_cursor || null;
        state.done = !data.next_cursor;

        var posts = data.posts || [];
        renderPosts(posts, !reset);
        updateCount();

        if (!el.list.children.length) {
          show(el.empty);
        } else if (state.done) {
          show(el.listEnd);
        } else if (!('IntersectionObserver' in window)) {
          show(el.more);
        }
      })
      .catch(function (err) {
        hide(el.skeleton);
        state.loading = false;
        if (err.code && err.code.indexOf('cursor') === 0) {
          // Stale cursor: start the list over rather than showing an error.
          state.cursor = null;
          state.done = false;
          loadPosts(true);
          return;
        }
        if (!el.list.children.length) show(el.error);
        else { show(el.more); toast(errorText(err), true); }
      });
  }

  function setRecentMode(skipLoad) {
    state.sort = 'recent';
    state.origin = null;
    setText(el.sortLabel, 'Eng yangi e\u02bblonlar');
    hide(el.modeChip);
    if (el.addressInput) el.addressInput.value = '';
    if (!skipLoad) loadPosts(true);
  }

  function setDistanceMode(origin) {
    state.sort = 'distance';
    state.origin = origin;
    setText(el.sortLabel, 'Yaqinlik bo\u02bbyicha');
    setText(el.modeChipText, origin.label || origin.query);
    show(el.modeChip);
    loadPosts(true);
  }

  // =========================================================
  // Search / geocode
  // =========================================================

  function runSearch() {
    var value = (el.addressInput.value || '').trim();
    if (!value) { setRecentMode(); return; }
    if (!requireAuth()) return;

    clearListStates();
    el.list.innerHTML = '';
    show(el.skeleton);
    el.searchBtn.disabled = true;

    // Park pagination while the geocode is in flight. Without this, the
    // sentinel sits at the top of an emptied list and the observer can fire a
    // page load that wipes whichever state the search is about to show.
    state.geocoding = true;
    state.cursor = null;
    state.done = true;

    api('/geocode', { method: 'POST', auth: true, body: { address: value } })
      .then(function (data) {
        el.searchBtn.disabled = false;
        state.geocoding = false;
        setDistanceMode({
          lat: data.lat,
          lon: data.lon,
          label: data.display_name || value,
          query: value
        });
      })
      .catch(function (err) {
        el.searchBtn.disabled = false;
        state.geocoding = false;
        hide(el.skeleton);
        // state.done stays true: nothing should auto-load underneath the
        // message until the person changes the address or retries.
        if (err.code === 'geocode_failed' || err.code === 'validation_failed') {
          show(el.geoError);
        } else {
          show(el.error);
          toast(errorText(err), true);
        }
      });
  }

  // =========================================================
  // Detail sheet
  // =========================================================

  function fillSheet(post) {
    state.sheetPost = post;

    var split = splitAddress(post.address_display);
    if (split.region) { setText(el.sheetRegion, split.region); show(el.sheetRegion); }
    else hide(el.sheetRegion);
    setText(el.sheetAddress, split.rest || post.address_display);

    setText(el.sheetTime, post.posted_rel_uz || '');

    var km = state.lastDistances[post.id];
    if (km != null) {
      var num = el.sheetDistance.querySelector('.hs-dist__num');
      if (num) setText(num, formatDistance(km));
      show(el.sheetDistance);
    } else {
      hide(el.sheetDistance);
    }

    setText(el.sheetBody, post.body || '');

    /* Phone and Telegram are independent now — a post may carry either, both,
       or (defensively) neither. */
    var hasPhone = !!post.contact;
    var handle = post.telegram_username;

    if (hasPhone) {
      setText(el.sheetCallNum || el.sheetCall, formatPhone(post.contact));
      el.sheetCall.href = 'tel:' + String(post.contact).replace(/[^\d+]/g, '');
    }
    if (el.sheetPhoneRow) el.sheetPhoneRow.hidden = !hasPhone;
    if (el.sheetPhoneHint) el.sheetPhoneHint.hidden = !hasPhone;

    if (hasPhone || handle) {
      show(el.sheetContactRow);
      hide(el.sheetNoContact);
    } else {
      hide(el.sheetContactRow);
      show(el.sheetNoContact);
    }

    if (el.sheetTelegram) {
      if (handle) {
        // The chevron carries the affordance; the label is just the handle,
        // which keeps long usernames from ellipsizing.
        setText(el.sheetTelegramLabel, '@' + handle);
        el.sheetTelegram.dataset.username = handle;
        show(el.sheetTelegram);
      } else {
        hide(el.sheetTelegram);
        el.sheetTelegram.dataset.username = '';
      }
    }

    if (post.is_mine) show(el.sheetOwner);
    else hide(el.sheetOwner);

    show(el.sheetContent);
  }

  function openSheet(postId) {
    navigate({ v: state.view, sheet: postId });
  }

  function openSheetUI(postId) {
    state.sheetPostId = postId;
    el.sheet.dataset.postId = postId;

    show(el.backdrop);
    show(el.sheet);
    hide(el.sheetError);
    hide(el.sheetContent);
    show(el.sheetLoading);
    document.body.style.overflow = 'hidden';
    haptic('light');
    syncMainButton();
    syncBackButton();

    if (!INIT_DATA) {
      hide(el.sheetLoading);
      show(el.sheetError);
      return;
    }

    api('/posts/' + postId, { auth: true })
      .then(function (data) {
        if (state.sheetPostId !== postId) return;
        hide(el.sheetLoading);
        fillSheet(data.post);
      })
      .catch(function (err) {
        if (state.sheetPostId !== postId) return;
        hide(el.sheetLoading);
        show(el.sheetError);
        if (err.code !== 'gone' && err.code !== 'not_found') toast(errorText(err), true);
      });
  }

  function closeSheet() {
    // Unwind through History so the back trail stays consistent.
    if (state.sheetPostId) history.back();
  }

  function closeSheetUI() {
    state.sheetPostId = null;
    state.sheetPost = null;
    hide(el.sheet);
    hide(el.backdrop);
    document.body.style.overflow = '';
    syncMainButton();
    syncBackButton();
  }

  /* Pull the sheet down to close it — the gesture every bottom sheet on the
     phone already teaches. The drag only arms when the sheet's own scroll is
     at the top, so scrolling long post text still works normally. */
  function bindSheetSwipe() {
    if (!el.sheet) return;
    var startY = 0, delta = 0, armed = false, width720 = false;

    function baseTransform() {
      return width720 ? 'translateX(-50%) ' : '';
    }

    el.sheet.addEventListener('touchstart', function (ev) {
      if (!state.sheetPostId) return;
      if (el.sheet.scrollTop > 0) { armed = false; return; }
      armed = true;
      width720 = window.innerWidth >= 720;
      startY = ev.touches[0].clientY;
      delta = 0;
      el.sheet.style.transition = 'none';
    }, { passive: true });

    el.sheet.addEventListener('touchmove', function (ev) {
      if (!armed) return;
      delta = ev.touches[0].clientY - startY;
      if (delta <= 0) {
        el.sheet.style.transform = '';
        return;
      }
      el.sheet.style.transform = baseTransform() + 'translateY(' + delta + 'px)';
    }, { passive: true });

    el.sheet.addEventListener('touchend', function () {
      if (!armed) return;
      armed = false;
      el.sheet.style.transition = 'transform 200ms cubic-bezier(0.16, 1, 0.3, 1)';
      if (delta > 90) {
        el.sheet.style.transform = baseTransform() + 'translateY(100%)';
        setTimeout(function () {
          el.sheet.style.transition = '';
          el.sheet.style.transform = '';
          closeSheet();
        }, 190);
      } else {
        el.sheet.style.transform = '';
        setTimeout(function () { el.sheet.style.transition = ''; }, 210);
      }
      delta = 0;
    });
  }

  /* openTelegramLink keeps the chat inside Telegram. A plain <a href> would
     bounce out to the browser and trigger the "open this link?" prompt. */
  function openTelegramChat() {
    var handle = el.sheetTelegram && el.sheetTelegram.dataset.username;
    if (!handle) return;
    var url = 'https://t.me/' + handle;
    haptic('light');
    if (tg && typeof tg.openTelegramLink === 'function') {
      try { tg.openTelegramLink(url); return; } catch (e) {}
    }
    window.open(url, '_blank');
  }

  function copyContact() {
    var post = state.sheetPost;
    if (!post || !post.contact) return;
    var value = post.contact;

    function done() { toast('Raqam nusxalab olindi'); haptic('success'); }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(value).then(done, fallbackCopy);
    } else {
      fallbackCopy();
    }

    function fallbackCopy() {
      try {
        var ta = document.createElement('textarea');
        ta.value = value;
        ta.setAttribute('readonly', '');
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        done();
      } catch (e) {
        toast('Nusxalab bo\u02bblmadi.', true);
      }
    }
  }

  function confirmAction(message) {
    return new Promise(function (resolve) {
      if (tg && typeof tg.showConfirm === 'function') {
        try { tg.showConfirm(message, function (ok) { resolve(!!ok); }); return; }
        catch (e) { /* fall through */ }
      }
      resolve(window.confirm(message));
    });
  }

  function deletePost(postId, afterDelete) {
    if (!requireAuth()) return;
    confirmAction('E\u02bblon o\u02bbchirilsinmi? Buni qaytarib bo\u02bblmaydi.')
      .then(function (ok) {
        if (!ok) return;
        api('/posts/' + postId, { method: 'DELETE', auth: true })
          .then(function () {
            haptic('success');
            toast('E\u02bblon o\u02bbchirildi');
            if (afterDelete) afterDelete();
          })
          .catch(function (err) { haptic('error'); toast(errorText(err), true); });
      });
  }

  function extendPost(postId, afterExtend) {
    if (!requireAuth()) return;
    api('/posts/' + postId + '/extend', { method: 'POST', auth: true })
      .then(function (data) {
        haptic('success');
        toast('Muddat yana ' + plural(data.days_left || 30, 'kun') + 'ga uzaytirildi');
        if (afterExtend) afterExtend();
      })
      .catch(function (err) { haptic('error'); toast(errorText(err), true); });
  }

  // =========================================================
  // My posts
  // =========================================================

  function buildMineCard(post) {
    var node = el.mineCardTemplate.content.firstElementChild.cloneNode(true);
    node.dataset.postId = post.id;

    var split = splitAddress(post.address_display);
    var regionEl = node.querySelector('[data-field="region"]');
    if (split.region) setText(regionEl, split.region);
    else hide(regionEl);
    setText(node.querySelector('[data-field="address"]'), split.rest || post.address_display);

    var statusEl = node.querySelector('[data-field="status"]');
    if (post.status === 'expired') {
      setText(statusEl, 'Muddati tugagan');
      statusEl.classList.add('hs-badge--mine');
    } else {
      setText(statusEl, 'Faol');
      statusEl.classList.add('hs-badge--mine');
    }

    setText(node.querySelector('[data-field="preview"]'), post.body || '');

    var daysEl = node.querySelector('[data-field="days-left"]');
    if (post.status === 'expired') setText(daysEl, 'Ro\u02bbyxatda ko\u02bbrinmaydi');
    else setText(daysEl, plural(post.days_left || 0, 'kun') + ' qoldi');

    node.querySelector('[data-action="edit"]').addEventListener('click', function () {
      openCompose('edit', post);
    });
    node.querySelector('[data-action="extend"]').addEventListener('click', function () {
      extendPost(post.id, loadMine);
    });
    node.querySelector('[data-action="delete"]').addEventListener('click', function () {
      deletePost(post.id, loadMine);
    });

    return node;
  }

  function loadMine() {
    if (!INIT_DATA) {
      hide(el.mineSkeleton);
      el.mineList.innerHTML = '';
      show(el.mineEmpty);
      toast(ERRORS.unauthorized, true);
      return;
    }
    hide(el.mineEmpty);
    hide(el.mineError);
    el.mineList.innerHTML = '';
    show(el.mineSkeleton);

    return api('/me/posts', { auth: true })
      .then(function (data) {
        hide(el.mineSkeleton);
        var posts = data.posts || [];
        setText(el.mineCount, posts.length ? plural(posts.length, 'ta') : '');
        if (!posts.length) { show(el.mineEmpty); return; }
        var frag = document.createDocumentFragment();
        posts.forEach(function (post) { frag.appendChild(buildMineCard(post)); });
        el.mineList.appendChild(frag);
      })
      .catch(function (err) {
        hide(el.mineSkeleton);
        show(el.mineError);
        toast(errorText(err), true);
      });
  }

  // =========================================================
  // Compose
  // =========================================================

  function clearFieldErrors() {
    ['address', 'contact', 'body', 'contact_username'].forEach(function (name) {
      var node = el.composeForm.querySelector('[data-error-for="' + name + '"]');
      if (node) { setText(node, ''); hide(node); }
    });
    [el.composeAddress, el.composeContact, el.composeBody].forEach(function (input) {
      if (input) input.classList.remove('hs-input--invalid');
    });
    hide(el.composeError);
    setText(el.composeError, '');
  }

  function setFieldError(name, message) {
    var node = el.composeForm.querySelector('[data-error-for="' + name + '"]');
    if (node) { setText(node, message); show(node); }
    var input = { address: el.composeAddress, contact: el.composeContact,
                  body: el.composeBody, contact_username: el.tgUsername }[name];
    if (input) input.classList.add('hs-input--invalid');
  }

  var FIELD_MESSAGES = {
    contact_username: '5-32 belgi: harflar, raqamlar va pastki chiziq. Harf bilan boshlansin.',
    contact_required: 'Telefon raqami yoki Telegram \u2014 kamida bittasini ko\u02bbrsating.',
    address: 'Manzilni koreys tilida, to\u02bbliq yozing.',
    contact: 'Telefon raqamini to\u02bbg\u02bbri yozing.',
    body: 'Matn kamida ' + BODY_MIN + ' ta belgidan iborat bo\u02bblsin.'
  };

  function updateBodyCount() {
    var len = (el.composeBody.value || '').length;
    setText(el.composeBodyCount, len + ' / ' + BODY_MAX);
    el.composeBodyCount.classList.toggle('hs-field__count--over', len > BODY_MAX);
  }

  function openCompose(mode, post) {
    if (!requireAuth()) return;

    state.composeMode = mode;
    state.composePostId = post ? post.id : null;
    el.composeForm.dataset.mode = mode;
    el.composeForm.dataset.postId = post ? post.id : '';

    clearFieldErrors();

    var editing = (mode === 'edit' && post);
    loadMe().then(function () {
      syncTelegramOptIn(editing ? !!post.show_username : false,
                        editing ? (post.contact_username || '') : '');
    });

    if (mode === 'edit' && post) {
      setText(el.composeTitle, 'E\u02bblonni tahrirlash');
      el.composeAddress.value = post.address_display || post.address_input || '';
      el.composeAddress.disabled = true;
      hide(el.composeAddressHint);
      show(el.composeAddressLock);
      el.composeContact.value = post.contact || '';
      el.composeBody.value = post.body || '';
    } else {
      setText(el.composeTitle, 'Yangi e\u02bblon');
      el.composeAddress.value = '';
      el.composeAddress.disabled = false;
      show(el.composeAddressHint);
      hide(el.composeAddressLock);
      el.composeContact.value = '';
      el.composeBody.value = '';
    }

    updateBodyCount();
    // Pushed on top of whatever route we came from — including a sheet route,
    // so cancelling returns to the post the user was reading.
    navigate({ v: 'compose', sheet: null });
  }

  function validateCompose() {
    clearFieldErrors();
    var ok = true;

    var address = (el.composeAddress.value || '').trim();
    var contact = (el.composeContact.value || '').trim();
    var body = (el.composeBody.value || '').trim();

    if (state.composeMode === 'create') {
      if (address.length < 4 || address.length > 200 || !/[\uac00-\ud7a3]/.test(address)) {
        setFieldError('address', FIELD_MESSAGES.address);
        ok = false;
      }
    }
    if (contact && (contact.length < 5 || contact.length > 40 ||
                    (contact.match(/\d/g) || []).length < 5)) {
      setFieldError('contact', FIELD_MESSAGES.contact);
      ok = false;
    }
    if (body.length < BODY_MIN || body.length > BODY_MAX) {
      setFieldError('body', FIELD_MESSAGES.body);
      ok = false;
    }

    var tg = telegramPayload();
    if (!contact && !tg.show_username) {
      setFieldError('contact', FIELD_MESSAGES.contact_required);
      ok = false;
    }
    if (tg.show_username) {
      if (!tg.contact_username) {
        setFieldError('contact_username', 'Username yozing yoki belgini olib tashlang.');
        ok = false;
      } else if (!TG_USERNAME.test(tg.contact_username)) {
        setFieldError('contact_username', FIELD_MESSAGES.contact_username);
        ok = false;
      }
    }
    return ok ? { address: address, contact: contact, body: body, tg: tg } : null;
  }

  function setSubmitting(on) {
    state.submitting = on;
    if (!el.composeSubmit) return;
    el.composeSubmit.disabled = on;
    if (on) {
      el.composeSubmit.textContent = 'Yuborilmoqda\u2026';
    } else {
      syncMainButton();
    }
  }

  function handleSubmitError(err) {
    haptic('error');
    if (err.code === 'validation_failed' && err.data && err.data.fields) {
      Object.keys(err.data.fields).forEach(function (name) {
        setFieldError(name, FIELD_MESSAGES[name] || err.data.fields[name]);
      });
      return;
    }
    if (err.code === 'geocode_failed') {
      setFieldError('address', 'Manzil topilmadi. To\u02bbliqroq yozib ko\u02bbring.');
      return;
    }
    setText(el.composeError, errorText(err));
    show(el.composeError);
  }

  function submitCompose() {
    if (state.submitting) return;
    if (!requireAuth()) return;

    var values = validateCompose();
    if (!values) { haptic('error'); return; }

    setSubmitting(true);

    var request;
    if (state.composeMode === 'edit') {
      // Address is immutable — never send it in an edit.
      request = api('/posts/' + state.composePostId + '/edit', {
        method: 'POST',
        auth: true,
        body: {
          contact: values.contact,
          body: values.body,
          show_username: values.tg.show_username,
          contact_username: values.tg.contact_username
        }
      });
    } else {
      request = api('/posts', {
        method: 'POST',
        auth: true,
        body: {
          address: values.address,
          contact: values.contact,
          body: values.body,
          show_username: values.tg.show_username,
          contact_username: values.tg.contact_username
        }
      });
    }

    request
      .then(function () {
        setSubmitting(false);
        haptic('success');
        var wasEdit = state.composeMode === 'edit';
        toast(wasEdit ? 'O\u02bbzgarishlar saqlandi' : 'E\u02bbloningiz joylandi');
        state.composeMode = 'create';
        state.composePostId = null;
        // Pop the compose entry instead of replacing it, so back never
        // returns to a form that has already been submitted.
        if (!wasEdit) setRecentMode(true);
        backAndRefresh();
      })
      .catch(function (err) {
        setSubmitting(false);
        handleSubmitError(err);
      });
  }

  // =========================================================
  // Geo-alerts
  // =========================================================

  var RADIUS_MIN = 1;
  var RADIUS_MAX = 500;

  /* Presets are shortcuts, not the allowed set — any whole number in range is
     accepted. Typing a custom value clears the preset highlight; picking a
     preset writes back into the field, so the two never disagree. */
  function setAlertRadius(value, fromInput) {
    state.alertRadius = value;

    var buttons = el.alertRadius.querySelectorAll('[data-radius]');
    Array.prototype.forEach.call(buttons, function (btn) {
      var active = Number(btn.dataset.radius) === value;
      btn.classList.toggle('hs-radius__btn--active', active);
      btn.setAttribute('aria-checked', active ? 'true' : 'false');
    });

    if (!fromInput && el.alertRadiusInput) {
      el.alertRadiusInput.value = value;
      el.alertRadiusInput.classList.remove('hs-input--invalid');
    }
  }

  function readRadiusInput() {
    if (!el.alertRadiusInput) return state.alertRadius;
    var raw = (el.alertRadiusInput.value || '').trim();
    if (raw === '') return null;
    var n = parseInt(raw, 10);
    return isNaN(n) ? NaN : n;
  }

  function clearAlertErrors() {
    ['alert-address', 'alert-radius'].forEach(function (name) {
      var node = el.alertForm.querySelector('[data-error-for="' + name + '"]');
      if (node) { setText(node, ''); hide(node); }
    });
    if (el.alertAddress) el.alertAddress.classList.remove('hs-input--invalid');
    if (el.alertRadiusInput) el.alertRadiusInput.classList.remove('hs-input--invalid');
    setText(el.alertError, '');
    hide(el.alertError);
  }

  function setRadiusError(message) {
    var node = el.alertForm.querySelector('[data-error-for="alert-radius"]');
    if (node) { setText(node, message); show(node); }
    if (el.alertRadiusInput) el.alertRadiusInput.classList.add('hs-input--invalid');
  }

  function setAlertFieldError(message) {
    var node = el.alertForm.querySelector('[data-error-for="alert-address"]');
    if (node) { setText(node, message); show(node); }
    if (el.alertAddress) el.alertAddress.classList.add('hs-input--invalid');
  }

  function buildAlertCard(alert) {
    var node = el.alertTemplate.content.firstElementChild.cloneNode(true);
    node.dataset.alertId = alert.id;

    var split = splitAddress(alert.address_display);
    var regionEl = node.querySelector('[data-field="region"]');
    if (split.region) setText(regionEl, split.region);
    else hide(regionEl);
    setText(node.querySelector('[data-field="address"]'), split.rest || alert.address_display);
    setText(node.querySelector('[data-field="radius"]'), alert.radius_km);

    var statusEl = node.querySelector('[data-field="status"]');
    if (!alert.is_active) {
      node.classList.add('is-disabled');
      setText(statusEl, 'O\u02bbchirilgan — botni bloklagansiz');
    } else if (alert.match_count) {
      setText(statusEl, plural(alert.match_count, 'ta') + ' xabar yuborilgan');
    } else {
      setText(statusEl, 'Faol');
    }

    node.querySelector('[data-action="delete"]').addEventListener('click', function () {
      deleteAlert(alert.id);
    });
    return node;
  }

  function loadAlerts() {
    if (!INIT_DATA) {
      hide(el.alertSkeleton);
      el.alertList.innerHTML = '';
      show(el.alertEmpty);
      toast(ERRORS.unauthorized, true);
      return;
    }
    hide(el.alertEmpty);
    hide(el.alertsError);
    el.alertList.innerHTML = '';
    show(el.alertSkeleton);

    return api('/alerts', { auth: true })
      .then(function (data) {
        hide(el.alertSkeleton);
        var alerts = data.alerts || [];
        setText(el.alertCount, alerts.length ? plural(alerts.length, 'ta') : '');
        if (!alerts.length) { show(el.alertEmpty); return; }
        var frag = document.createDocumentFragment();
        alerts.forEach(function (alert) { frag.appendChild(buildAlertCard(alert)); });
        el.alertList.appendChild(frag);
      })
      .catch(function (err) {
        hide(el.alertSkeleton);
        show(el.alertsError);
        toast(errorText(err), true);
      });
  }

  function submitAlert() {
    if (state.alertSubmitting) return;
    if (!requireAuth()) return;

    clearAlertErrors();
    var address = (el.alertAddress.value || '').trim();
    if (address.length < 2 || address.length > 200 || !/[\uac00-\ud7a3]/.test(address)) {
      setAlertFieldError(FIELD_MESSAGES.address);
      haptic('error');
      return;
    }

    var radius = readRadiusInput();
    if (radius === null) radius = state.alertRadius;
    if (isNaN(radius) || radius < RADIUS_MIN || radius > RADIUS_MAX) {
      setRadiusError('Doira ' + RADIUS_MIN + ' km dan ' + RADIUS_MAX + ' km gacha bo\u02bblsin.');
      haptic('error');
      return;
    }
    setAlertRadius(radius);

    state.alertSubmitting = true;
    el.alertSubmit.disabled = true;

    api('/alerts', {
      method: 'POST',
      auth: true,
      body: { address: address, radius_km: radius }
    })
      .then(function () {
        state.alertSubmitting = false;
        el.alertSubmit.disabled = false;
        el.alertAddress.value = '';
        haptic('success');
        toast('Bildirishnoma qo\u02bbshildi');
        loadAlerts();
      })
      .catch(function (err) {
        state.alertSubmitting = false;
        el.alertSubmit.disabled = false;
        haptic('error');
        if (err.code === 'geocode_failed') {
          setAlertFieldError('Manzil topilmadi. To\u02bbliqroq yozib ko\u02bbring.');
          return;
        }
        if (err.code === 'validation_failed') {
          setAlertFieldError(FIELD_MESSAGES.address);
          return;
        }
        setText(el.alertError, errorText(err));
        show(el.alertError);
      });
  }

  function deleteAlert(alertId) {
    if (!requireAuth()) return;
    confirmAction('Bu bildirishnoma o\u02bbchirilsinmi?').then(function (ok) {
      if (!ok) return;
      api('/alerts/' + alertId, { method: 'DELETE', auth: true })
        .then(function () {
          haptic('success');
          toast('Bildirishnoma o\u02bbchirildi');
          loadAlerts();
        })
        .catch(function (err) { haptic('error'); toast(errorText(err), true); });
    });
  }

  // =========================================================
  // Pull to refresh
  // =========================================================

  var PULL_TRIGGER = 68;    // px of travel before the gesture arms
  var PULL_MAX = 96;        // px ceiling, so the sheet cannot be dragged away
  var PULL_RESIST = 0.45;   // finger travel -> visual travel

  function refreshActiveView() {
    if (state.view === 'mine') return loadMine();
    if (state.view === 'alerts') return loadAlerts();
    return loadPosts(true);
  }

  function pullRender(distance, armed) {
    var shown = Math.min(distance, PULL_MAX);
    var progress = Math.min(1, shown / PULL_TRIGGER);
    if (el.shell) el.shell.style.transform = 'translateY(' + shown + 'px)';
    if (!el.pull) return;
    el.pull.style.opacity = String(progress);
    el.pull.style.transform = 'translateY(' + (shown - 10) + 'px)';
    var icon = el.pull.querySelector('.hs-pull__icon');
    if (icon && !el.pull.classList.contains('hs-pull--busy')) {
      icon.style.transform = 'rotate(' + Math.round(progress * 270) + 'deg)';
    }
    el.pull.classList.toggle('hs-pull--armed', !!armed);
  }

  function pullReset(animated) {
    if (el.shell) {
      el.shell.classList.toggle('hs-shell--settling', !!animated);
      el.shell.style.transform = '';
    }
    if (el.pull) {
      el.pull.classList.toggle('hs-pull--settling', !!animated);
      el.pull.classList.remove('hs-pull--busy', 'hs-pull--armed');
      el.pull.style.opacity = '0';
      el.pull.style.transform = '';
      var icon = el.pull.querySelector('.hs-pull__icon');
      if (icon) icon.style.transform = '';
    }
    if (animated) {
      setTimeout(function () {
        if (el.shell) el.shell.classList.remove('hs-shell--settling');
        if (el.pull) el.pull.classList.remove('hs-pull--settling');
      }, 300);
    }
  }

  /* Arms only when the list is already scrolled to the very top and nothing
     is layered over it. The compose form is excluded — refreshing under a
     half-filled form would be hostile. */
  function bindPullToRefresh() {
    if (!el.shell) return;
    var startY = 0;
    var distance = 0;
    var tracking = false;
    var busy = false;

    function eligible() {
      return !busy
        && !state.sheetPostId
        && state.view !== 'compose'
        && el.shell.scrollTop <= 0;
    }

    el.shell.addEventListener('touchstart', function (ev) {
      if (ev.touches.length !== 1 || !eligible()) { tracking = false; return; }
      tracking = true;
      startY = ev.touches[0].clientY;
      distance = 0;
      el.shell.classList.remove('hs-shell--settling');
      if (el.pull) el.pull.classList.remove('hs-pull--settling');
    }, { passive: true });

    el.shell.addEventListener('touchmove', function (ev) {
      if (!tracking) return;
      // The list scrolled under the finger — hand the gesture back.
      if (el.shell.scrollTop > 0) { tracking = false; pullReset(false); return; }
      var raw = ev.touches[0].clientY - startY;
      if (raw <= 0) { distance = 0; pullRender(0, false); return; }
      distance = raw * PULL_RESIST;
      pullRender(distance, distance >= PULL_TRIGGER);
    }, { passive: true });

    function release() {
      if (!tracking) return;
      tracking = false;
      if (distance < PULL_TRIGGER) { pullReset(true); return; }

      busy = true;
      haptic('light');
      if (el.pull) el.pull.classList.add('hs-pull--busy');
      // Hold the indicator at the trigger point while the request runs.
      if (el.shell) {
        el.shell.classList.add('hs-shell--settling');
        el.shell.style.transform = 'translateY(' + PULL_TRIGGER + 'px)';
      }

      var started = Date.now();
      Promise.resolve(refreshActiveView())
        .catch(function () { /* the view renders its own error state */ })
        .then(function () {
          // A refresh that finishes in 40ms reads as "nothing happened".
          var wait = Math.max(0, 400 - (Date.now() - started));
          setTimeout(function () { busy = false; pullReset(true); }, wait);
        });
    }

    el.shell.addEventListener('touchend', release);
    el.shell.addEventListener('touchcancel', function () {
      if (!tracking) return;
      tracking = false;
      pullReset(true);
    });
  }

  // =========================================================
  // Infinite scroll
  // =========================================================

  function initObserver() {
    if (!('IntersectionObserver' in window) || !el.sentinel) return;
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        if (state.view !== 'browse') return;
        if (state.geocoding) return;
        if (state.loading || state.done || !state.cursor) return;
        loadPosts(false);
      });
    }, { rootMargin: '300px 0px' });
    observer.observe(el.sentinel);
  }

  // =========================================================
  // Events
  // =========================================================

  function bind() {
    el.navBrowse.addEventListener('click', function () {
      navigate({ v: 'browse', sheet: null });
    });
    el.navMine.addEventListener('click', function () {
      navigate({ v: 'mine', sheet: null });
    });
    if (el.navAlerts) {
      el.navAlerts.addEventListener('click', function () {
        navigate({ v: 'alerts', sheet: null });
      });
    }
    if (el.navCompose) {
      el.navCompose.addEventListener('click', function () {
        haptic('light');
        openCompose('create');
      });
    }

    el.searchForm.addEventListener('submit', function (ev) {
      ev.preventDefault();
      if (el.addressInput) el.addressInput.blur();
      runSearch();
    });

    el.modeChip.addEventListener('click', function (ev) {
      ev.preventDefault();
      setRecentMode();
    });

    el.loadMoreBtn.addEventListener('click', function () { loadPosts(false); });
    el.errorRetry.addEventListener('click', function () { loadPosts(true); });
    el.geoErrorRetry.addEventListener('click', function () {
      hide(el.geoError);
      setRecentMode();
      if (el.addressInput) el.addressInput.focus();
    });
    el.mineRetry.addEventListener('click', loadMine);
    el.alertsRetry.addEventListener('click', loadAlerts);

    el.alertForm.addEventListener('submit', function (ev) {
      ev.preventDefault();
      if (el.alertAddress) el.alertAddress.blur();
      submitAlert();
    });
    el.alertRadius.addEventListener('click', function (ev) {
      var btn = ev.target.closest ? ev.target.closest('[data-radius]') : null;
      if (!btn) return;
      setAlertRadius(Number(btn.dataset.radius));
      haptic('light');
    });

    if (el.alertRadiusInput) {
      el.alertRadiusInput.addEventListener('input', function () {
        var n = readRadiusInput();
        if (n === null || isNaN(n)) return;
        setAlertRadius(n, true);
      });
      el.alertRadiusInput.addEventListener('blur', function () {
        var n = readRadiusInput();
        if (n === null) { setAlertRadius(state.alertRadius); return; }
        if (isNaN(n)) return;
        setAlertRadius(Math.min(RADIUS_MAX, Math.max(RADIUS_MIN, n)));
      });
    }

    el.backdrop.addEventListener('click', closeSheet);
    el.sheetClose.addEventListener('click', closeSheet);
    el.sheetCopy.addEventListener('click', copyContact);
    el.sheetErrorRetry.addEventListener('click', function () {
      // Already on the sheet route — refetch without pushing another entry.
      if (state.sheetPostId) openSheetUI(state.sheetPostId);
    });
    el.sheetEdit.addEventListener('click', function () {
      if (state.sheetPost) openCompose('edit', state.sheetPost);
    });
    el.sheetDelete.addEventListener('click', function () {
      var id = state.sheetPostId;
      if (!id) return;
      deletePost(id, function () {
        // Pop the sheet entry — back must not reopen a deleted post.
        backAndRefresh();
      });
    });

    el.composeForm.addEventListener('submit', function (ev) {
      ev.preventDefault();
      submitCompose();
    });
    el.composeBody.addEventListener('input', updateBodyCount);
    if (el.sheetTelegram) el.sheetTelegram.addEventListener('click', openTelegramChat);
    if (el.tgCheck) el.tgCheck.addEventListener('change', syncTelegramField);
    if (el.tgUsername) {
      el.tgUsername.addEventListener('blur', function () {
        el.tgUsername.value = normalizeUsername(el.tgUsername.value);
      });
    }
    bindPhoneFormatting(el.composeContact);

    bindSheetSwipe();
    bindPullToRefresh();

    document.addEventListener('keydown', function (ev) {
      if (ev.key === 'Escape' && state.sheetPostId) closeSheet();
    });

    window.addEventListener('resize', applyViewportHeight);
    window.addEventListener('popstate', onPopState);
  }

  // =========================================================
  // Boot
  // =========================================================

  function init() {
    initTelegram();
    bind();
    initObserver();
    setAlertRadius(state.alertRadius);
    loadMe();

    // replaceState, not pushState: the entry behind this one is index.html,
    // so back from the board leaves the feature the way the user came in.
    replaceRoute({ v: 'browse', sheet: null });
    applyView('browse');
    setRecentMode();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

/* =========================================================
   HOUSING — UI layer (Phase 3.1 redesign)

   Appended, self-contained, and deliberately outside the
   module above: it touches presentation only and holds no
   application state. Removing this block degrades the page
   to the previous behaviour, it does not break it.
   ========================================================= */

(function () {
  'use strict';

  function $(id) { return document.getElementById(id); }

  var shell = $('hsShell');
  var searchBar = $('hsSearchBar');
  var navCompose = $('hsNavCompose');
  var composeView = $('hsViewCompose');
  var body = $('hsComposeBody');

  /* A sticky bar with no edge reads as a rendering glitch. Give it one
     only once it is actually detached from the top of the list. */
  if (shell && searchBar) {
    var stuck = false;
    shell.addEventListener('scroll', function () {
      var next = shell.scrollTop > 4;
      if (next === stuck) return;
      stuck = next;
      searchBar.classList.toggle('is-stuck', stuck);
    }, { passive: true });
  }

  /* Empty states now end in the action they describe. Both routes go
     through the tab button so the History entry is written exactly the
     way openCompose() expects. */
  function toCompose() { if (navCompose) navCompose.click(); }

  var emptyCta = $('hsEmptyCta');
  var mineEmptyCta = $('hsMineEmptyCta');
  if (emptyCta) emptyCta.addEventListener('click', toCompose);
  if (mineEmptyCta) mineEmptyCta.addEventListener('click', toCompose);

  var alertEmptyCta = $('hsAlertEmptyCta');
  var alertAddress = $('hsAlertAddress');
  if (alertEmptyCta && alertAddress) {
    alertEmptyCta.addEventListener('click', function () {
      try { alertAddress.scrollIntoView({ behavior: 'smooth', block: 'center' }); } catch (e) {}
      alertAddress.focus();
    });
  }

  /* The post body is the field people write the most in. Growing it to fit
     beats a fixed box with an inner scrollbar on a phone. */
  function growBody() {
    if (!body) return;
    var max = Math.round((window.innerHeight || 640) * 0.55);
    body.style.height = 'auto';
    body.style.height = Math.min(body.scrollHeight + 2, max) + 'px';
    body.style.overflowY = (body.scrollHeight + 2 > max) ? 'auto' : 'hidden';
  }

  if (body) {
    body.addEventListener('input', growBody);
    // openCompose() writes .value directly, which fires no input event —
    // catch the view becoming visible instead.
    if (composeView && 'MutationObserver' in window) {
      new MutationObserver(function () {
        if (!composeView.hidden) setTimeout(growBody, 0);
      }).observe(composeView, { attributes: true, attributeFilter: ['hidden'] });
    }
    growBody();
  }
})();
