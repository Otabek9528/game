// notifications.js — Notifications page.
// Lists the areas a user watches and the places on their watchlist, and
// creates/edits areas in a bottom sheet. The bot sends the messages; this
// page only manages what triggers them. Every word comes from places.text.js.
//
// Bot message buttons link here as notifications.html?stop=place:<id> or
// ?stop=area:<id>; that unsubscribes first, then shows the page. Messages
// sent before the page moved here link to pages/places/notifications.html,
// which forwards to this page.
//
// locationManager.js is loaded only when "My location" is used, so opening
// the page does not start a location fix.
(function () {
  'use strict';

  var T = PlacesText.t;
  var esc = PlacesText.esc;
  var tg = (window.Telegram && Telegram.WebApp) || null;
  var API = ((window.API_CONFIG && API_CONFIG.BASE_URL) || 'https://vegukin-api.duckdns.org/').replace(/\/+$/, '');

  var TYPES = ['mosque', 'restaurant', 'shop'];
  var RADII = [1, 3, 5, 10];
  var DEFAULT_RADIUS = 5;
  var EMOJI = { mosque: '🕌', restaurant: '🍽️', shop: '🏪' };
  // Signature problems: the only fix is reopening the page inside Telegram.
  var AUTH_CODES = ['no_init_data', 'bad_init_data', 'bad_signature', 'no_user', 'server_misconfigured'];

  var ICON = {
    crosshair: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.5" fill="currentColor" stroke="none"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/></svg>',
    pin: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>',
    more: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/></svg>',
    check: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m4.5 12.5 5 5 10-11"/></svg>',
    bell: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2.2a6.3 6.3 0 0 0-6.3 6.3c0 4.6-1.4 6.9-2.4 8a.9.9 0 0 0 .7 1.5h16a.9.9 0 0 0 .7-1.5c-1-1.1-2.4-3.4-2.4-8A6.3 6.3 0 0 0 12 2.2Z"/><path d="M9.6 19.8h4.8a2.4 2.4 0 0 1-4.8 0Z"/></svg>'
  };

  var state = { areas: [], watches: [], subscriber: null };
  var photoFound = {};   // placeId -> photo URL, or '' when it has none

  function $(id) { return document.getElementById(id); }
  function lang() { return PlacesText.lang(); }
  function initData() { return (tg && tg.initData) || ''; }

  function haptic(kind) {
    try {
      var h = tg && tg.HapticFeedback;
      if (!h) return;
      if (kind === 'success' || kind === 'error') h.notificationOccurred(kind);
      else h.impactOccurred('light');
    } catch (e) {}
  }

  // ============================================
  // TELEGRAM BACK BUTTON
  // ============================================
  // One handler at a time: the page goes home, an open sheet or menu closes.

  var backHandler = null;

  function setBack(fn) {
    if (!tg || !tg.BackButton) return;
    try {
      if (backHandler) tg.BackButton.offClick(backHandler);
      backHandler = fn;
      tg.BackButton.onClick(fn);
      tg.BackButton.show();
    } catch (e) {}
  }

  function goHome() { window.location.href = '../../index.html'; }

  function restoreBack() {
    if (isSheetOpen()) setBack(closeSheet);
    else if (menuArea) setBack(closeMenu);
    else setBack(goHome);
  }

  // ============================================
  // API
  // ============================================

  function api(method, path, body) {
    var opts = {
      method: method,
      // Signed initData — the server verifies it and takes the user from it.
      headers: { 'X-Init-Data': initData() }
    };
    if (body) {
      opts.headers['Content-Type'] = 'application/json';
      opts.body = JSON.stringify(body);
    }
    if (window.AbortSignal && AbortSignal.timeout) opts.signal = AbortSignal.timeout(20000);
    return fetch(API + path, opts).then(function (res) {
      return res.json().catch(function () { return {}; }).then(function (data) {
        if (!res.ok || data.success === false) {
          var err = new Error(data.error || ('HTTP ' + res.status));
          err.code = data.code || ('http_' + res.status);
          err.status = res.status;
          throw err;
        }
        return data;
      });
    });
  }

  function errorText(err) {
    if (!err) return T('common.error');
    if (err.name === 'TimeoutError' || err.name === 'AbortError') return T('common.timeout');
    if (!err.code && err instanceof TypeError) return T('common.network');
    if (AUTH_CODES.indexOf(err.code) !== -1) return T('common.telegramOnly');
    if (err.code && PlacesText.has('notifyErrors.' + err.code)) return T('notifyErrors.' + err.code);
    return T('common.error');
  }

  // The bot can only message people who let it. Telegram reports that in
  // initData; when it says no, ask (Telegram 6.9+) before a new area is
  // saved, so nobody subscribes and silently never hears anything. Telegram
  // answers yes at once, without a dialog, when the bot may already write.
  var writeOk = false;
  function ensureWriteAccess() {
    return new Promise(function (resolve) {
      var user = tg && tg.initDataUnsafe && tg.initDataUnsafe.user;
      if (writeOk || !user || user.allows_write_to_pm) { resolve(true); return; }
      try {
        if (tg.requestWriteAccess && tg.isVersionAtLeast && tg.isVersionAtLeast('6.9')) {
          tg.requestWriteAccess(function (granted) {
            writeOk = !!granted;
            resolve(!!granted);
          });
          return;
        }
      } catch (e) {}
      // Older Telegram cannot ask; the server finds out when it sends.
      resolve(true);
    });
  }

  // ============================================
  // TOAST
  // ============================================

  var toastTimer = null;

  function toast(text, actionLabel, onAction) {
    var el = $('ntToast');
    var btn = $('ntToastAction');
    $('ntToastText').textContent = text;
    btn.hidden = !actionLabel;
    btn.textContent = actionLabel || '';
    btn.onclick = actionLabel ? function () { hideToast(); onAction(); } : null;
    el.hidden = false;
    requestAnimationFrame(function () { el.classList.add('visible'); });
    clearTimeout(toastTimer);
    toastTimer = setTimeout(hideToast, actionLabel ? 5000 : 2600);
  }

  function hideToast() {
    var el = $('ntToast');
    clearTimeout(toastTimer);
    el.classList.remove('visible');
    toastTimer = setTimeout(function () { el.hidden = true; }, 260);
  }

  // ============================================
  // LOAD
  // ============================================

  function showState(which, message, canRetry) {
    $('ntLoading').hidden = which !== 'loading';
    $('ntError').hidden = which !== 'error';
    if (which === 'error') {
      $('ntErrorText').textContent = message;
      $('ntRetry').hidden = !canRetry;
    }
    if (which) {
      $('ntEmpty').hidden = true;
      $('ntLists').hidden = true;
      $('ntBlocked').hidden = true;
    }
  }

  function parseStop() {
    var raw = new URLSearchParams(window.location.search).get('stop') || '';
    var m = /^(place|area):(\d+)$/.exec(raw);
    return m ? { kind: m[1], id: Number(m[2]) } : null;
  }

  // "Stop" from a bot message. Already gone counts as stopped.
  function applyStop(stop) {
    var path = stop.kind === 'place' ? '/api/notify/watch/' + stop.id : '/api/notify/areas/' + stop.id;
    return api('DELETE', path, { lang: lang() })
      .catch(function (err) { if (err.code !== 'not_found') throw err; })
      .then(function () {
        // Off the URL, so a reload does not repeat it.
        try { history.replaceState(null, '', window.location.pathname); } catch (e) {}
        if (stop.kind === 'place') {
          toast(T('bot.stoppedPlace'), T('common.undo'), function () {
            api('POST', '/api/notify/watch/' + stop.id, { lang: lang() })
              .then(load, function (err) { toast(errorText(err)); });
          });
        } else {
          toast(T('bot.stoppedArea'));
        }
      });
  }

  function load() {
    if (!initData()) {
      showState('error', T('common.telegramOnly'), false);
      return;
    }
    showState('loading');
    var stop = parseStop();
    (stop ? applyStop(stop) : Promise.resolve())
      .then(function () { return api('GET', '/api/notify/me'); })
      .then(function (data) {
        state.areas = data.areas || [];
        state.watches = data.watches || [];
        state.subscriber = data.subscriber || null;
        showState(null);
        render();
      })
      .catch(function (err) {
        showState('error', AUTH_CODES.indexOf(err.code) !== -1 ? T('common.telegramOnly') : T('page.loadError'),
                  AUTH_CODES.indexOf(err.code) === -1);
      });
  }

  // ============================================
  // RENDER
  // ============================================

  function typeChips(types) {
    return types.map(function (t) {
      return '<span class="nt-chip"><span class="nt-chip-emoji" aria-hidden="true">' + EMOJI[t] + '</span>' +
        esc(T('types.' + t)) + '</span>';
    }).join('');
  }

  // Shortcuts into the three place lists, where watching starts.
  function typeLinks() {
    return TYPES.map(function (t) {
      return '<a class="nt-chip" href="../places/places.html?type=' + t + '"><span class="nt-chip-emoji" aria-hidden="true">' +
        EMOJI[t] + '</span>' + esc(T('types.' + t + 's')) + '</a>';
    }).join('');
  }

  // The sender switches a person off when Telegram refuses a message (they
  // blocked the bot, or never allowed it). Nothing reaches them until that
  // changes, so the page says so above everything else.
  function renderBlocked() {
    $('ntBlocked').hidden = !(state.subscriber && state.subscriber.active === false);
  }

  var helloBusy = false;
  function allowMessages() {
    if (helloBusy) return;
    helloBusy = true;
    $('ntAllow').disabled = true;
    ensureWriteAccess()
      .then(function (ok) {
        if (!ok) {
          haptic('error');
          toast(T('watch.needsWrite'));
          return;
        }
        // Switches the person back on and sends a test message; if the bot
        // still cannot reach them, the sender switches them off again.
        return api('POST', '/api/notify/hello', { lang: lang() }).then(function () {
          if (state.subscriber) state.subscriber.active = true;
          renderBlocked();
          haptic('success');
          toast(T('page.helloSent'));
        });
      })
      .catch(function (err) { toast(errorText(err)); })
      .then(function () {
        helloBusy = false;
        $('ntAllow').disabled = false;
      });
  }

  function render() {
    renderBlocked();
    var empty = !state.areas.length && !state.watches.length;
    $('ntEmpty').hidden = !empty;
    $('ntLists').hidden = empty;
    if (empty) {
      $('ntEmpty').querySelector('[data-type-links]').innerHTML = typeLinks();
      return;
    }
    renderAreas();
    renderWatches();
  }

  // Four rings for 1/3/5/10 km; the chosen one is solid.
  function radarSvg(km) {
    var out = '<svg viewBox="0 0 70 70" aria-hidden="true">';
    RADII.forEach(function (r, i) {
      out += '<circle cx="35" cy="31" r="' + (9 + i * 7.5) + '" class="nt-ring' + (r === km ? ' nt-ring--on' : '') + '"/>';
    });
    return out + '<circle cx="35" cy="31" r="3.2" class="nt-pin"/></svg>';
  }

  // A "location" area is a fixed point: where the user stood when saving it.
  function areaTitle(a) {
    if (a.source === 'location') return a.label || T('areas.currentLocation');
    return a.label || '';
  }

  function areaMeta(a) {
    var first = a.source === 'location' ? T('areas.fromLocation') : T('areas.radius', { km: a.radiusKm });
    return first + ' · ' + T('areas.inside', { n: a.insideCount || 0 });
  }

  function renderAreas() {
    $('ntAreasCount').textContent = state.areas.length ? String(state.areas.length) : '';
    var list = $('ntAreaList');
    if (!state.areas.length) {
      list.innerHTML =
        '<button type="button" class="nt-area-empty" data-add-area>' + ICON.crosshair +
        '<span>' + esc(T('empty.areaBody')) + '</span></button>';
      return;
    }
    list.innerHTML = state.areas.map(function (a) {
      return '<article class="nt-area" data-id="' + esc(a.id) + '">' +
        '<div class="nt-radar">' + radarSvg(a.radiusKm) +
          '<span class="nt-radar-km">' + esc(T('places.distanceKm', { n: a.radiusKm })) + '</span></div>' +
        '<div class="nt-area-body">' +
          '<p class="nt-area-title">' + (a.source === 'location' ? ICON.crosshair : ICON.pin) +
            '<span>' + esc(areaTitle(a)) + '</span></p>' +
          '<p class="nt-area-meta">' + esc(areaMeta(a)) + '</p>' +
          '<div class="nt-chips">' + typeChips(a.types || []) + '</div>' +
        '</div>' +
        '<button type="button" class="nt-more" data-menu="' + esc(a.id) + '" aria-haspopup="menu" aria-expanded="false" ' +
          'aria-label="' + esc(T('areas.menu')) + '">' + ICON.more + '</button>' +
      '</article>';
    }).join('');
  }

  // No photo: the type's emoji on a tinted tile, as on the home screen.
  function emojiThumb(img, type) {
    var tile = document.createElement('span');
    tile.className = 'nt-thumb nt-thumb--emoji';
    tile.setAttribute('aria-hidden', 'true');
    tile.textContent = EMOJI[type] || EMOJI.mosque;
    img.replaceWith(tile);
  }

  function renderWatches() {
    var n = state.watches.length;
    $('ntWatchCount').textContent = n ? String(n) : '';
    // The hint lives in the empty box when there is nothing to list.
    document.querySelector('.nt-tip').hidden = !n;
    var empty = $('ntWatchEmpty');
    if (!n) {
      $('ntPlaceList').innerHTML = '';
      if (!empty) {
        empty = document.createElement('div');
        empty.id = 'ntWatchEmpty';
        empty.className = 'nt-watch-empty';
        $('ntPlaceList').parentNode.appendChild(empty);
      }
      empty.innerHTML = esc(T('watchlist.hint')) + '<span class="nt-chips">' + typeLinks() + '</span>';
      return;
    }
    if (empty) empty.remove();

    $('ntPlaceList').innerHTML = state.watches.map(function (w) {
      var meta = [w.type ? T('types.' + w.type) : '', w.city || ''].filter(Boolean).join(' · ');
      return '<div class="nt-place" role="link" tabindex="0" data-place="' + esc(w.placeId) + '" data-type="' + esc(w.type || '') + '">' +
        '<img class="nt-thumb" alt="" loading="lazy" data-photo-try="0">' +
        '<div class="nt-place-text">' +
          '<p class="nt-place-name">' + esc(w.name || '') + '</p>' +
          '<p class="nt-place-meta">' + esc(meta) + '</p>' +
        '</div>' +
        '<button type="button" class="nt-bell" data-unwatch="' + esc(w.placeId) + '" aria-pressed="true" ' +
          'aria-label="' + esc(T('watchlist.stop')) + '">' + ICON.bell + '</button>' +
      '</div>';
    }).join('');

    // Small first photos from places.photos.js. The answer is remembered, so
    // a re-render does not look the same place up again.
    var rows = $('ntPlaceList').querySelectorAll('.nt-place');
    for (var i = 0; i < rows.length; i++) {
      (function (img, w) {
        function show(url) {
          photoFound[w.placeId] = url || '';
          if (!url) { emojiThumb(img, w.type); return; }
          img.addEventListener('error', function () {
            photoFound[w.placeId] = '';
            emojiThumb(img, w.type);
          });
          img.src = url;
        }
        var known = photoFound[w.placeId];
        if (known != null) { show(known); return; }
        PlacePhotos.thumb(w.photo).then(function (url) {
          if (img.isConnected) show(url);
        });
      })(rows[i].querySelector('img'), state.watches[i]);
    }
  }

  function openPlace(row) {
    var type = row.getAttribute('data-type') || 'mosque';
    window.location.href = '../places/places-detail.html?type=' + encodeURIComponent(type) +
      '&id=' + encodeURIComponent(row.getAttribute('data-place'));
  }

  function unwatch(placeId, row) {
    var idx = -1;
    state.watches.forEach(function (w, i) { if (String(w.placeId) === String(placeId)) idx = i; });
    if (idx === -1) return;
    var item = state.watches[idx];
    haptic('light');
    if (row) row.classList.add('is-leaving');
    api('DELETE', '/api/notify/watch/' + encodeURIComponent(placeId), { lang: lang() })
      .then(function () {
        state.watches = state.watches.filter(function (w) { return w !== item; });
        render();
        toast(T('watchlist.removed'), T('common.undo'), function () { rewatch(item, idx); });
      })
      .catch(function (err) {
        if (row) row.classList.remove('is-leaving');
        toast(errorText(err));
      });
  }

  function rewatch(item, idx) {
    api('POST', '/api/notify/watch/' + encodeURIComponent(item.placeId), { lang: lang() })
      .then(function () {
        if (state.watches.indexOf(item) === -1) state.watches.splice(Math.min(idx, state.watches.length), 0, item);
        render();
      })
      .catch(function (err) { toast(errorText(err)); });
  }

  // ============================================
  // AREA MENU (Edit / Delete)
  // ============================================

  var menuArea = null;
  var menuButton = null;

  function openMenu(btn) {
    var id = btn.getAttribute('data-menu');
    if (menuArea && String(menuArea.id) === id) { closeMenu(); return; }
    closeMenu();
    menuArea = findArea(id);
    if (!menuArea) return;
    menuButton = btn;
    btn.setAttribute('aria-expanded', 'true');
    var menu = $('ntMenu');
    menu.hidden = false;
    var r = btn.getBoundingClientRect();
    var w = menu.offsetWidth;
    var h = menu.offsetHeight;
    var top = r.bottom + 4;
    if (top + h > window.innerHeight - 8) top = Math.max(8, r.top - h - 4);
    menu.style.top = top + 'px';
    menu.style.left = Math.max(8, Math.min(r.right - w, window.innerWidth - w - 8)) + 'px';
    menu.querySelector('.nt-menu-item').focus({ preventScroll: true });
    setBack(closeMenu);
  }

  function closeMenu() {
    if (!menuArea) return;
    $('ntMenu').hidden = true;
    if (menuButton) menuButton.setAttribute('aria-expanded', 'false');
    menuArea = null;
    menuButton = null;
    restoreBack();
  }

  function findArea(id) {
    for (var i = 0; i < state.areas.length; i++) {
      if (String(state.areas[i].id) === String(id)) return state.areas[i];
    }
    return null;
  }

  function confirmBox(text) {
    return new Promise(function (resolve) {
      try {
        if (tg && tg.showConfirm && (!tg.isVersionAtLeast || tg.isVersionAtLeast('6.2'))) {
          tg.showConfirm(text, function (ok) { resolve(!!ok); });
          return;
        }
      } catch (e) {}
      resolve(window.confirm(text));
    });
  }

  function deleteArea(area) {
    confirmBox(T('areas.deleteConfirm')).then(function (ok) {
      if (!ok) return;
      api('DELETE', '/api/notify/areas/' + encodeURIComponent(area.id), { lang: lang() })
        .catch(function (err) { if (err.code !== 'not_found') throw err; })
        .then(function () {
          state.areas = state.areas.filter(function (a) { return a !== area; });
          render();
          haptic('success');
          toast(T('areas.deleted'));
        })
        .catch(function (err) { toast(errorText(err)); });
    });
  }

  // ============================================
  // ADD / EDIT AREA SHEET
  // ============================================

  var sheet = null;   // see openSheet()
  var seq = 0;        // drops answers to requests that were superseded

  function isSheetOpen() { return !!sheet; }

  function openSheet(area) {
    closeMenu();
    sheet = {
      editId: area ? area.id : null,
      source: area ? area.source : 'location',
      radius: area ? area.radiusKm : DEFAULT_RADIUS,
      types: area ? (area.types || []).slice() : TYPES.slice(),
      // A centre per source, so switching tabs back and forth keeps both.
      centers: { location: null, address: null },
      points: { location: null, address: null },
      addrResolved: '',      // the text the address centre was found from
      addrFailed: '',        // the last text the geocoder could not find
      addrError: '',
      locError: false,
      locating: false,
      finding: false,
      saving: false
    };
    var input = $('ntAddrInput');
    input.value = '';
    if (area) {
      var c = { lat: area.lat, lon: area.lon, label: area.label, fresh: false };
      sheet.centers[area.source] = c;
      if (area.source === 'address') {
        input.value = area.label || '';
        sheet.addrResolved = input.value.trim();
      }
      loadPoints(area.source, c);
    }

    $('ntSheetTitle').textContent = T(area ? 'areaSheet.editTitle' : 'areaSheet.addTitle');
    setSheetError('');
    loadLeaflet();
    renderSheet();

    var backdrop = $('ntSheetBackdrop');
    var el = $('ntSheet');
    el.style.transform = '';
    backdrop.hidden = false;
    // Next frame, so the transition has a start state to animate from.
    requestAnimationFrame(function () {
      backdrop.classList.add('visible');
      el.classList.add('visible');
    });
    haptic('light');
    setBack(closeSheet);

    if (sheet.source === 'location' && !sheet.centers.location) locate();
  }

  function closeSheet() {
    if (!sheet) return;
    sheet = null;
    seq++;
    var backdrop = $('ntSheetBackdrop');
    var el = $('ntSheet');
    backdrop.classList.remove('visible');
    el.classList.remove('visible');
    el.style.transform = '';
    setTimeout(function () { if (!sheet) backdrop.hidden = true; }, 280);
    var input = $('ntAddrInput');
    if (document.activeElement === input) input.blur();
    restoreBack();
  }

  function activeCenter() { return sheet ? sheet.centers[sheet.source] : null; }

  function setSource(source) {
    if (!sheet || sheet.source === source) return;
    sheet.source = source;
    setSheetError('');
    renderSheet();
    if (source === 'location' && !sheet.centers.location && !sheet.locating) locate();
    if (source === 'address' && !$('ntAddrInput').value) {
      setTimeout(function () { if (sheet && sheet.source === 'address') $('ntAddrInput').focus(); }, 60);
    }
  }

  var locationLoading = null;

  // locationManager.js, the first time a location is needed.
  function loadLocationManager() {
    if (window.LocationManager && LocationManager.request) return Promise.resolve();
    if (locationLoading) return locationLoading;
    locationLoading = new Promise(function (resolve, reject) {
      var js = document.createElement('script');
      js.src = '../../js/locationManager.js';
      js.onload = function () {
        if (window.LocationManager && LocationManager.request) resolve();
        else reject(new Error('no LocationManager'));
      };
      js.onerror = function () {
        locationLoading = null;   // a later tap may try again
        reject(new Error('locationManager.js failed to load'));
      };
      document.head.appendChild(js);
    });
    return locationLoading;
  }

  function locate() {
    if (!sheet) return;
    var s = sheet;
    s.locating = true;
    s.locError = false;
    renderSheet();
    loadLocationManager().then(function () {
      if (sheet === s) locateNow(s);
    }, function () {
      if (sheet !== s) return;
      s.locating = false;
      s.locError = true;
      renderSheet();
    });
  }

  function locateNow(s) {
    var req = LocationManager.request(true);
    // The fresh fix, not the saved one: the saved location ignores moves
    // under 3 km, which is too coarse for a 5 km circle.
    req.coords.then(function (coords) {
      if (sheet !== s) return;
      var c = { lat: coords.lat, lon: coords.lon, label: null, fresh: true };
      s.centers.location = c;
      s.locating = false;
      renderSheet();
      loadPoints('location', c);
      // The city name arrives a little later; it becomes the area's label.
      req.done.then(function (saved) {
        var city = saved && saved.city;
        if (city && city !== LocationManager.UNKNOWN_CITY && s.centers.location === c) {
          c.label = city;
          if (sheet === s) renderSheet();
        }
      }, function () {});
    }, function () {
      if (sheet !== s) return;
      s.locating = false;
      s.locError = true;
      renderSheet();
    });
  }

  function findAddress() {
    if (!sheet) return;
    var s = sheet;
    var text = $('ntAddrInput').value.trim();
    if (!text) { $('ntAddrInput').focus(); return; }
    if (s.centers.address && s.addrResolved === text) return;
    if (s.addrFailed === text && s.addrError) return;
    var my = ++seq;
    s.finding = true;
    s.addrError = '';
    renderSheet();
    api('GET', '/api/places/in-radius?address=' + encodeURIComponent(text))
      .then(function (data) {
        if (my !== seq || sheet !== s) return;
        s.centers.address = { lat: data.center.lat, lon: data.center.lon, label: data.center.label || text, fresh: true };
        s.points.address = data.points || [];
        s.addrResolved = text;
      })
      .catch(function (err) {
        if (my !== seq || sheet !== s) return;
        s.addrError = errorText(err);
        if (err.code === 'address_not_found' || err.code === 'address_not_exact') s.addrFailed = text;
      })
      .then(function () {
        if (sheet !== s) return;
        s.finding = false;
        renderSheet();
      });
  }

  // Places within 10 km of the centre; every radius is counted from this one list.
  function loadPoints(source, center) {
    var s = sheet;
    api('GET', '/api/places/in-radius?lat=' + encodeURIComponent(center.lat) + '&lon=' + encodeURIComponent(center.lon))
      .then(function (data) {
        if (sheet !== s || s.centers[source] !== center) return;
        s.points[source] = data.points || [];
        renderPreview();
      })
      .catch(function () {
        // The preview is a nicety; saving still works without it.
        if (sheet !== s || s.centers[source] !== center) return;
        s.points[source] = [];
        renderPreview();
      });
  }

  function setSheetError(text) {
    var el = $('ntSheetError');
    el.textContent = text || '';
    el.hidden = !text;
  }

  function renderSheet() {
    if (!sheet) return;
    var s = sheet;

    var segs = document.querySelectorAll('.nt-seg--2 .nt-seg-btn');
    for (var i = 0; i < segs.length; i++) {
      var on = segs[i].getAttribute('data-source') === s.source;
      segs[i].classList.toggle('is-on', on);
      segs[i].setAttribute('aria-selected', on ? 'true' : 'false');
    }
    $('ntLocPanel').hidden = s.source !== 'location';
    $('ntAddrPanel').hidden = s.source !== 'address';

    // Location panel
    var loc = $('ntLocPanel');
    var c = s.centers.location;
    loc.classList.toggle('is-busy', s.locating);
    loc.classList.toggle('is-error', !s.locating && s.locError && !c);
    if (s.locating) {
      $('ntLocMain').textContent = T('areaSheet.locating');
      $('ntLocSub').textContent = '';
    } else if (c) {
      $('ntLocMain').textContent = c.label || (c.lat.toFixed(4) + ', ' + c.lon.toFixed(4));
      $('ntLocSub').textContent = T(c.fresh ? 'areaSheet.located' : 'areaSheet.savedCenter');
    } else {
      $('ntLocMain').textContent = s.locError ? T('areaSheet.locationFailed') : T('areaSheet.locating');
      $('ntLocSub').textContent = '';
    }
    $('ntLocAgain').hidden = !!(s.locating || (!c && !s.locError) || (c && c.fresh));

    // Address panel
    var text = $('ntAddrInput').value.trim();
    var found = !!s.centers.address && s.addrResolved === text;
    $('ntAddrForm').classList.toggle('is-found', found);
    $('ntAddrForm').classList.toggle('is-error', !!s.addrError);
    // A word, not an icon: a tick before anything is found read as "done".
    var findBtn = $('ntAddrFind');
    findBtn.innerHTML = found ? ICON.check + '<span>' + esc(T('areaSheet.found')) + '</span>'
                              : '<span>' + esc(T('areaSheet.find')) + '</span>';
    findBtn.disabled = s.finding;
    var hint = $('ntAddrHint');
    hint.classList.toggle('is-error', !!s.addrError);
    if (s.addrError) hint.textContent = s.addrError;
    else if (s.finding) hint.textContent = T('areaSheet.finding');
    else if (found && s.centers.address.label && s.centers.address.label !== text) hint.textContent = s.centers.address.label;
    else hint.textContent = T('areaSheet.addressHint');

    // Radius
    var radios = $('ntRadius').querySelectorAll('.nt-seg-btn');
    for (var j = 0; j < radios.length; j++) {
      var km = Number(radios[j].getAttribute('data-km'));
      radios[j].textContent = T('places.distanceKm', { n: km });
      radios[j].classList.toggle('is-on', km === s.radius);
      radios[j].setAttribute('aria-checked', km === s.radius ? 'true' : 'false');
    }

    // Types
    var tiles = $('ntTypes').querySelectorAll('.nt-tile');
    for (var k = 0; k < tiles.length; k++) {
      tiles[k].setAttribute('aria-pressed', s.types.indexOf(tiles[k].getAttribute('data-type')) !== -1 ? 'true' : 'false');
    }
    $('ntPickOne').hidden = s.types.length > 0;

    renderPreview();
    updateSave();
  }

  function canSave() {
    if (!sheet || sheet.saving || !sheet.types.length) return false;
    if (sheet.source === 'location') return !!sheet.centers.location;
    // Not gated on the lookup: tapping Save blurs the field, which starts one,
    // and the server geocodes the address again anyway.
    var text = $('ntAddrInput').value.trim();
    return !!text && !(sheet.addrError && sheet.addrFailed === text);
  }

  function updateSave() {
    $('ntSheetSave').disabled = !canSave();
  }

  // --- Live preview: rings scale with the radius; dots are real places ---
  // A real map (Leaflet + OpenStreetMap tiles) when it can load; until then,
  // or when it cannot (offline, tiles blocked), a drawn schematic of the same
  // rings and dots stands in. Both use the same CSS classes for their shapes.

  var LEAFLET_BASE = '../../js/vendor/leaflet-1.9.4/';
  var leafletLoading = null;
  var map = null;          // { m, layer, fitKey } once created
  var mapFailed = false;

  // Loaded the first time the sheet opens, so the page itself stays light.
  function loadLeaflet() {
    if (leafletLoading) return leafletLoading;
    leafletLoading = new Promise(function (resolve, reject) {
      if (window.L && L.map) { resolve(); return; }
      var css = document.createElement('link');
      css.rel = 'stylesheet';
      css.href = LEAFLET_BASE + 'leaflet.css';
      document.head.appendChild(css);
      var js = document.createElement('script');
      js.src = LEAFLET_BASE + 'leaflet.js';
      js.onload = function () { if (window.L && L.map) resolve(); else reject(new Error('no L')); };
      js.onerror = function () { reject(new Error('leaflet failed to load')); };
      document.head.appendChild(js);
    });
    leafletLoading.then(renderPreview, function () { mapFailed = true; });
    return leafletLoading;
  }

  function ensureMap() {
    if (map) return map;
    // A preview, not a map to explore: no dragging or zooming, so it never
    // fights the sheet's own scrolling.
    var m = L.map('ntMap', {
      zoomControl: false, dragging: false, touchZoom: false, doubleClickZoom: false,
      scrollWheelZoom: false, boxZoom: false, keyboard: false, zoomSnap: 0.25
    });
    m.attributionControl.setPrefix(false);
    m.attributionControl.setPosition('topright');
    var tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a>'
    }).addTo(m);
    // Tiles that never arrive leave a grey box; the schematic says more.
    var loaded = 0;
    var failed = 0;
    tiles.on('tileload', function () { loaded++; });
    tiles.on('tileerror', function () {
      if (++failed >= 4 && loaded === 0 && !mapFailed) {
        mapFailed = true;
        renderPreview();
      }
    });
    map = { m: m, layer: L.layerGroup().addTo(m), fitKey: '' };
    return map;
  }

  var PIN_SVG = '<svg viewBox="-12 -31 24 32" width="24" height="32" aria-hidden="true">' +
    '<path class="nt-pin" d="M0 0C-2-6-10-10.5-10-18.5a10 10 0 1 1 20 0C10-10.5 2-6 0 0Z"/>' +
    '<circle class="nt-pin-hole" cx="0" cy="-18.5" r="3.8"/></svg>';

  function drawMap(c, pts, s) {
    var m = map.m;
    m.invalidateSize(false);
    map.layer.clearLayers();
    RADII.slice().reverse().forEach(function (r) {
      L.circle([c.lat, c.lon], {
        radius: r * 1000, interactive: false,
        className: 'nt-ring' + (r === s.radius ? ' nt-ring--on' : '')
      }).addTo(map.layer);
    });
    var dim = [];
    var lit = [];
    (pts || []).forEach(function (p) {
      var on = p.km <= s.radius && s.types.indexOf(p.type) !== -1;
      (on ? lit : dim).push(L.circleMarker([p.lat, p.lon], {
        radius: on ? 5 : 3.2, interactive: false, fillOpacity: 1,
        className: on ? 'nt-dot nt-dot--' + p.type : 'nt-dot--off'
      }));
    });
    dim.concat(lit).forEach(function (mk) { mk.addTo(map.layer); });
    L.marker([c.lat, c.lon], {
      interactive: false, keyboard: false,
      icon: L.divIcon({ className: 'nt-map-pin', html: PIN_SVG, iconSize: [24, 32], iconAnchor: [12, 32] })
    }).addTo(map.layer);

    // Fit the chosen ring, leaving room for the legend along the bottom.
    // Only when the centre or radius changed, so ticking a type keeps the view.
    var key = c.lat + ',' + c.lon + ',' + s.radius;
    if (key !== map.fitKey) {
      map.fitKey = key;
      m.fitBounds(L.latLng(c.lat, c.lon).toBounds(s.radius * 2000), {
        paddingTopLeft: [10, 10], paddingBottomRight: [10, 32], animate: false
      });
    }
  }

  var SVG_W = 340;
  var SVG_H = 168;

  function drawSchematic(c, pts, s) {
    var cx = SVG_W / 2;
    var cy = SVG_H / 2 - 8;
    var out = '';
    for (var gx = 17; gx < SVG_W; gx += 34) out += '<line class="nt-grid" x1="' + gx + '" y1="0" x2="' + gx + '" y2="' + SVG_H + '"/>';
    for (var gy = 16; gy < SVG_H; gy += 34) out += '<line class="nt-grid" x1="0" y1="' + gy + '" x2="' + SVG_W + '" y2="' + gy + '"/>';

    // The chosen ring always has the same size on screen; bigger rings run off the edge.
    var pxPerKm = 58 / s.radius;
    var kmPerLon = 111.32 * Math.cos(c.lat * Math.PI / 180);
    var kmPerLat = 110.57;
    RADII.slice().reverse().forEach(function (r) {
      out += '<circle class="nt-ring' + (r === s.radius ? ' nt-ring--on' : '') + '" cx="' + cx + '" cy="' + cy +
        '" r="' + (r * pxPerKm).toFixed(1) + '"/>';
    });
    var dim = '';
    var lit = '';
    (pts || []).forEach(function (p) {
      var x = cx + (p.lon - c.lon) * kmPerLon * pxPerKm;
      var y = cy - (p.lat - c.lat) * kmPerLat * pxPerKm;
      var on = p.km <= s.radius && s.types.indexOf(p.type) !== -1;
      if (x < -6 || x > SVG_W + 6 || y < -6 || y > SVG_H + 6) return;
      if (on) lit += '<circle class="nt-dot nt-dot--' + p.type + '" cx="' + x.toFixed(1) + '" cy="' + y.toFixed(1) + '" r="4.6"/>';
      else dim += '<circle class="nt-dot--off" cx="' + x.toFixed(1) + '" cy="' + y.toFixed(1) + '" r="3"/>';
    });
    out += dim + lit;
    out += '<g transform="translate(' + cx + ' ' + cy + ')">' +
      '<path class="nt-pin" d="M0 0C-2-6-10-10.5-10-18.5a10 10 0 1 1 20 0C10-10.5 2-6 0 0Z"/>' +
      '<circle class="nt-pin-hole" cx="0" cy="-18.5" r="3.8"/></g>';
    $('ntPreviewSvg').innerHTML = out;
  }

  function renderPreview() {
    if (!sheet) return;
    var s = sheet;
    var c = activeCenter();
    var pts = s.points[s.source];
    var busy = s.source === 'location' ? s.locating : s.finding;
    var emptyEl = $('ntPreviewEmpty');
    var legend = $('ntLegend');

    $('ntPreview').classList.toggle('is-busy', !!(busy || (c && !pts)));

    // The map is shown before it is created: Leaflet measures its box.
    var useMap = !!(c && window.L && L.map && !mapFailed);
    $('ntMap').hidden = !useMap;
    $('ntPreviewSvg').style.display = useMap ? 'none' : '';

    if (!c) {
      $('ntPreviewSvg').innerHTML = '';
      emptyEl.textContent = busy
        ? T(s.source === 'location' ? 'areaSheet.locating' : 'areaSheet.finding')
        : T('areaSheet.noCenter');
      legend.hidden = true;
      return;
    }
    emptyEl.textContent = '';

    if (useMap) {
      ensureMap();
      drawMap(c, pts, s);
    } else {
      drawSchematic(c, pts, s);
    }

    if (!pts) { legend.hidden = true; return; }
    var counts = { mosque: 0, restaurant: 0, shop: 0 };
    pts.forEach(function (p) {
      if (p.km <= s.radius && s.types.indexOf(p.type) !== -1) counts[p.type]++;
    });
    var items = s.types.filter(function (t) { return counts[t] > 0; }).map(function (t) {
      var key = 'areaSheet.count' + t.charAt(0).toUpperCase() + t.slice(1);
      return '<span class="nt-legend-item"><span class="nt-legend-dot nt-dot--' + t + '" style="background: var(--nt-' + t + ')"></span>' +
        esc(T(key, { n: counts[t] })) + '</span>';
    });
    legend.innerHTML = items.length ? items.join('') : '<span class="nt-legend-muted">' + esc(T('areaSheet.nothingInside')) + '</span>';
    legend.hidden = false;
  }

  function save() {
    if (!canSave()) return;
    var s = sheet;
    // A new area: first make sure the bot may message this person.
    if (s.editId == null && !s.writeChecked) {
      s.saving = true;
      updateSave();
      ensureWriteAccess().then(function (ok) {
        if (sheet !== s) return;
        s.saving = false;
        if (!ok) {
          updateSave();
          haptic('error');
          setSheetError(T('watch.needsWrite'));
          return;
        }
        s.writeChecked = true;
        save();
      });
      return;
    }
    var body = { radiusKm: s.radius, types: s.types.slice(), lang: lang() };
    if (s.source === 'location') {
      var c = s.centers.location;
      body.source = 'location';
      body.lat = c.lat;
      body.lon = c.lon;
      body.label = c.label || '';
    } else {
      body.source = 'address';
      body.address = $('ntAddrInput').value.trim();
    }
    s.saving = true;
    setSheetError('');
    updateSave();
    var editing = s.editId != null;
    var req = editing
      ? api('PUT', '/api/notify/areas/' + encodeURIComponent(s.editId), body)
      : api('POST', '/api/notify/areas', body);
    req.then(function (data) {
      var area = data.area;
      if (editing) {
        state.areas = state.areas.map(function (a) { return String(a.id) === String(area.id) ? area : a; });
      } else {
        state.areas.push(area);
      }
      if (sheet === s) closeSheet();
      render();
      haptic('success');
      toast(T(editing ? 'areas.updated' : 'areas.saved'));
    }).catch(function (err) {
      if (sheet !== s) return;
      s.saving = false;
      haptic('error');
      if ((err.code === 'address_not_found' || err.code === 'address_not_exact') && s.source === 'address') {
        s.addrError = errorText(err);
        s.centers.address = null;
      } else {
        setSheetError(errorText(err));
      }
      renderSheet();
    });
  }

  // Drag the grip or the header down to dismiss, like the detail-page sheet.
  function bindSheetDrag() {
    var el = $('ntSheet');
    var startY = 0;
    var dy = 0;
    var tracking = false;
    function onStart(e) {
      if (!sheet) return;
      tracking = true;
      dy = 0;
      startY = (e.touches ? e.touches[0] : e).clientY;
      el.style.transition = 'none';
    }
    function onMove(e) {
      if (!tracking) return;
      dy = Math.max(0, (e.touches ? e.touches[0] : e).clientY - startY);
      if (e.cancelable) e.preventDefault();
      el.style.transform = 'translateY(' + dy + 'px)';
    }
    function onEnd() {
      if (!tracking) return;
      tracking = false;
      el.style.transition = '';
      if (dy > 90) closeSheet();
      else el.style.transform = '';
    }
    [$('ntSheetGrip'), el.querySelector('.pd-sheet-head')].forEach(function (handle) {
      handle.addEventListener('touchstart', onStart, { passive: true });
      handle.addEventListener('touchmove', onMove, { passive: false });
      handle.addEventListener('touchend', onEnd);
      handle.addEventListener('touchcancel', onEnd);
      handle.addEventListener('mousedown', onStart);
    });
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onEnd);
  }

  // ============================================
  // EVENTS
  // ============================================

  function bind() {
    $('ntRetry').addEventListener('click', load);
    $('ntAllow').addEventListener('click', allowMessages);
    $('ntEmptyAddArea').addEventListener('click', function () { openSheet(null); });
    $('ntAddArea').addEventListener('click', function () { openSheet(null); });

    $('ntAreaList').addEventListener('click', function (e) {
      var more = e.target.closest('[data-menu]');
      if (more) { e.stopPropagation(); openMenu(more); return; }
      if (e.target.closest('[data-add-area]')) openSheet(null);
    });

    $('ntMenu').addEventListener('click', function (e) {
      var item = e.target.closest('[data-action]');
      if (!item || !menuArea) return;
      var area = menuArea;
      closeMenu();
      if (item.getAttribute('data-action') === 'edit') openSheet(area);
      else deleteArea(area);
    });

    document.addEventListener('click', function (e) {
      if (menuArea && !e.target.closest('#ntMenu') && !e.target.closest('[data-menu]')) closeMenu();
    });
    $('ntLists').parentNode.addEventListener('scroll', closeMenu, { passive: true });
    window.addEventListener('resize', closeMenu);

    var places = $('ntPlaceList');
    places.addEventListener('click', function (e) {
      var bell = e.target.closest('[data-unwatch]');
      if (bell) {
        e.stopPropagation();
        unwatch(bell.getAttribute('data-unwatch'), bell.closest('.nt-place'));
        return;
      }
      var row = e.target.closest('.nt-place');
      if (row && !row.classList.contains('is-leaving')) openPlace(row);
    });
    places.addEventListener('keydown', function (e) {
      if ((e.key === 'Enter' || e.key === ' ') && e.target.classList.contains('nt-place')) {
        e.preventDefault();
        openPlace(e.target);
      }
    });

    // Sheet
    $('ntSheetBackdrop').addEventListener('click', closeSheet);
    $('ntSheetCancel').addEventListener('click', closeSheet);
    $('ntSheetSave').addEventListener('click', save);
    $('ntLocAgain').addEventListener('click', locate);

    var segs = document.querySelectorAll('.nt-seg--2 .nt-seg-btn');
    for (var i = 0; i < segs.length; i++) {
      segs[i].addEventListener('click', function () { setSource(this.getAttribute('data-source')); });
    }

    $('ntRadius').addEventListener('click', function (e) {
      var btn = e.target.closest('[data-km]');
      if (!btn || !sheet) return;
      sheet.radius = Number(btn.getAttribute('data-km'));
      haptic('light');
      renderSheet();
    });

    $('ntTypes').addEventListener('click', function (e) {
      var tile = e.target.closest('[data-type]');
      if (!tile || !sheet) return;
      var t = tile.getAttribute('data-type');
      var at = sheet.types.indexOf(t);
      if (at === -1) sheet.types.push(t);
      else sheet.types.splice(at, 1);
      // Keep the canonical order, which is also how the server stores them.
      sheet.types = TYPES.filter(function (x) { return sheet.types.indexOf(x) !== -1; });
      haptic('light');
      renderSheet();
    });

    $('ntAddrForm').addEventListener('submit', function (e) {
      e.preventDefault();
      findAddress();
    });
    $('ntAddrInput').addEventListener('input', function () {
      if (!sheet) return;
      sheet.addrError = '';
      if (sheet.centers.address && sheet.addrResolved !== this.value.trim()) {
        sheet.centers.address = null;
        sheet.points.address = null;
      }
      renderSheet();
    });
    // Leaving the field looks the address up, so the preview is ready by Save.
    $('ntAddrInput').addEventListener('blur', function () {
      if (sheet && sheet.source === 'address' && this.value.trim()) findAddress();
    });

    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      if (menuArea) closeMenu();
      else if (sheet) closeSheet();
    });

    bindSheetDrag();

    window.addEventListener('languageChanged', function () {
      PlacesText.apply(document);
      document.title = T('page.title');
      render();
      if (sheet) {
        $('ntSheetTitle').textContent = T(sheet.editId != null ? 'areaSheet.editTitle' : 'areaSheet.addTitle');
        renderSheet();
      }
    });
  }

  // ============================================
  // START
  // ============================================

  if (tg) {
    try { tg.ready(); } catch (e) {}
    try { tg.expand(); } catch (e) {}
    try { if (tg.disableVerticalSwipes) tg.disableVerticalSwipes(); } catch (e) {}
  }
  document.title = T('page.title');
  PlacesText.apply(document);
  bind();
  setBack(goHome);
  load();
})();
