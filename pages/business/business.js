// business.js - Biznes Katalogi (Phase 1: browse, detail, taps)
//
// Two views in one page: a category grid and a business list. Tapping a
// business opens a bottom sheet. Uzbek only, by design.
//
// Nothing owner-supplied ever reaches innerHTML. Names and descriptions go in
// through textContent; links are typed (kind, value) rows rendered as buttons
// we build ourselves, so a business can never inject markup into a page that
// carries the visitor's Telegram session.

(function () {
  'use strict';

  var tg = window.Telegram.WebApp;
  tg.ready();
  try { tg.expand(); } catch (e) {}
  try { tg.disableVerticalSwipes(); } catch (e) {}

  var API = (window.API_CONFIG ? window.API_CONFIG.BASE_URL : 'https://vegukin-api.duckdns.org/')
              .replace(/\/+$/, '');
  var TIMEOUT = 30000;

  var state = { view: 'categories', category: null, pricing: null, business: null };

  function $(id) { return document.getElementById(id); }

  function haptic(kind) {
    try { tg.HapticFeedback.impactOccurred(kind || 'light'); } catch (e) {}
  }

  function initDataHeader() {
    return { 'X-Init-Data': (tg && tg.initData) ? tg.initData : '' };
  }

  function getJSON(path) {
    return fetch(API + path, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(TIMEOUT)
    }).then(function (r) {
      if (!r.ok) throw new Error('http_' + r.status);
      return r.json();
    });
  }

  // ============================================
  // ICONS
  // ============================================

  var ICONS = {
    heart: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 20.7 3.9 12.6a5.1 5.1 0 0 1 7.2-7.2l.9.9.9-.9a5.1 5.1 0 1 1 7.2 7.2Z"/></svg>',
    eye: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.6-6.5 10-6.5S22 12 22 12s-3.6 6.5-10 6.5S2 12 2 12Z"/><circle cx="12" cy="12" r="2.6"/></svg>',
    globe: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18"/></svg>',
    phone: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.13.96.36 1.9.7 2.8a2 2 0 0 1-.45 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.25a2 2 0 0 1 2.1-.45c.9.34 1.84.57 2.8.7A2 2 0 0 1 22 16.9z"/></svg>',
    telegram: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M9.78 18.65l.28-4.23 7.68-6.92c.34-.31-.07-.46-.52-.19L7.74 13.3 3.64 12c-.88-.25-.89-.86.2-1.3l15.97-6.16c.73-.33 1.43.18 1.15 1.3l-2.72 12.81c-.19.91-.74 1.13-1.5.71L12.6 16.3l-2.01 1.95c-.23.23-.42.42-.81.42z"/></svg>',
    instagram: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5.2"/><circle cx="12" cy="12" r="4.1"/><circle cx="17.3" cy="6.7" r="1.25" fill="currentColor" stroke="none"/></svg>',
    tiktok: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.6 2h-3.2v13.2a2.9 2.9 0 1 1-2.4-2.85V9.1a6.1 6.1 0 1 0 5.6 6.08V8.9a7.3 7.3 0 0 0 4.3 1.38V7.06A4.4 4.4 0 0 1 16.6 2z"/></svg>',
    appstore: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.4 12.7c0-2.2 1.8-3.3 1.9-3.3-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.7.8-3.3.8-.7 0-1.7-.8-2.8-.8-1.5 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.4 1.1 8.5.7 1 1.5 2.2 2.6 2.1 1.1 0 1.5-.7 2.8-.7s1.6.7 2.8.7c1.2 0 1.9-1 2.6-2.1.8-1.2 1.2-2.3 1.2-2.4-.1 0-2.2-.9-2.2-3.2zM14.2 5.9c.6-.7 1-1.7.9-2.7-.9 0-2 .6-2.6 1.3-.6.6-1.1 1.6-.9 2.6 1 .1 2-.5 2.6-1.2z"/></svg>',
    playstore: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3.6 2.4a1 1 0 0 0-.4.8v17.6a1 1 0 0 0 .4.8l9.3-9.6zM14.3 10.3 5.6 1.7l10.9 6.2zM14.3 13.7l2.2 2.4-10.9 6.2zM17.9 9l3 1.7a1.3 1.3 0 0 1 0 2.6l-3 1.7-2.5-3z"/></svg>',
    kakao: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 3C6.9 3 2.8 6.3 2.8 10.3c0 2.6 1.7 4.9 4.3 6.2l-1.1 4c-.1.3.3.6.6.4l4.7-3.1c.2 0 .5.1.7.1 5.1 0 9.2-3.3 9.2-7.6S17.1 3 12 3z"/></svg>',
    copy: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="12" height="12" rx="2.4"/><path d="M5.5 15H4.6A1.6 1.6 0 0 1 3 13.4V4.6A1.6 1.6 0 0 1 4.6 3h8.8A1.6 1.6 0 0 1 15 4.6v.9"/></svg>'
  };

  var LINK_META = {
    website:   { icon: ICONS.globe,     label: 'Veb-sayt' },
    phone:     { icon: ICONS.phone,     label: 'Telefon' },
    telegram:  { icon: ICONS.telegram,  label: 'Telegram' },
    instagram: { icon: ICONS.instagram, label: 'Instagram' },
    tiktok:    { icon: ICONS.tiktok,    label: 'TikTok' },
    appstore:  { icon: ICONS.appstore,  label: 'App Store' },
    playstore: { icon: ICONS.playstore, label: 'Google Play' },
    kakao:     { icon: ICONS.kakao,     label: 'KakaoTalk' }
  };

  // ============================================
  // SMALL DOM HELPERS
  // ============================================

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function iconSpan(className, svg) {
    var s = el('span', className);
    s.innerHTML = svg;          // trusted constant, never business-supplied
    return s;
  }

  function initials(name) {
    return (name || '?')
      .split(/\s+/).filter(Boolean).slice(0, 2)
      .map(function (w) { return w.charAt(0).toUpperCase(); })
      .join('');
  }

  function formatKRW(n) {
    return Number(n || 0).toLocaleString('en-US') + ' KRW';
  }

  var toastTimer = null;
  function showToast(message) {
    var t = $('bzToast');
    if (!t) return;
    t.textContent = message;
    t.hidden = false;
    requestAnimationFrame(function () { t.classList.add('visible'); });
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      t.classList.remove('visible');
      setTimeout(function () { t.hidden = true; }, 250);
    }, 2600);
  }

  // ============================================
  // TELEGRAM BACK BUTTON
  // ============================================
  // One handler at a time, swapped as depth changes: sheet -> list -> home.

  var backHandler = null;

  function setBack(fn) {
    if (!tg.BackButton) return;
    if (backHandler) tg.BackButton.offClick(backHandler);
    backHandler = fn;
    if (fn) {
      tg.BackButton.onClick(fn);
      tg.BackButton.show();
    } else {
      tg.BackButton.hide();
    }
  }

  function goHome() { window.location.href = '../../index.html'; }

  // ============================================
  // LOGO
  // ============================================

  function logoNode(business, className) {
    var box = el('div', className || 'bz-logo');
    if (business.logo) {
      var img = document.createElement('img');
      img.src = API + '/' + String(business.logo).replace(/^\/+/, '');
      img.alt = '';
      img.loading = 'lazy';
      img.addEventListener('error', function () {
        box.textContent = initials(business.name);
        box.classList.add('bz-logo--fallback');
      });
      box.appendChild(img);
    } else {
      box.textContent = initials(business.name);
      box.classList.add('bz-logo--fallback');
    }
    return box;
  }

  function statsNode(business) {
    var wrap = el('div', 'bz-stats');
    var likes = el('span', 'bz-stat');
    likes.appendChild(iconSpan('bz-stat-icon bz-stat-icon--heart', ICONS.heart));
    likes.appendChild(el('span', null, String(business.likes)));
    wrap.appendChild(likes);

    var taps = el('span', 'bz-stat');
    taps.appendChild(iconSpan('bz-stat-icon', ICONS.eye));
    taps.appendChild(el('span', null, String(business.taps)));
    wrap.appendChild(taps);
    return wrap;
  }

  // ============================================
  // VIEW A - CATEGORIES
  // ============================================

  function loadCategories() {
    $('catSkeleton').hidden = false;
    getJSON('/api/business/categories')
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        renderCategories(data.categories || []);
      })
      .catch(function () {
        $('catSkeleton').hidden = true;
        var grid = $('catGrid');
        grid.textContent = '';
        var err = el('p', 'bz-inline-error', "Yo'nalishlarni yuklab bo'lmadi. Qaytadan urinib ko'ring.");
        grid.appendChild(err);
      });
  }

  function renderCategories(categories) {
    $('catSkeleton').hidden = true;
    var grid = $('catGrid');
    grid.textContent = '';

    categories.forEach(function (cat) {
      var tile = el('button', 'bz-cat');
      tile.type = 'button';

      tile.appendChild(el('span', 'bz-cat-icon', cat.icon));
      tile.appendChild(el('span', 'bz-cat-name', cat.name));
      tile.appendChild(el('span', 'bz-cat-count',
        cat.count === 0 ? "hali bo'sh" : cat.count + ' ta'));

      if (cat.count === 0) tile.classList.add('is-empty');

      tile.addEventListener('click', function () {
        haptic('light');
        openCategory(cat);
      });
      grid.appendChild(tile);
    });
  }

  // ============================================
  // VIEW B - BUSINESS LIST
  // ============================================

  function openCategory(cat) {
    state.view = 'list';
    state.category = cat;

    $('viewCategories').hidden = true;
    $('viewList').hidden = false;
    $('listTitle').textContent = (cat.icon ? cat.icon + '  ' : '') + cat.name;
    window.scrollTo(0, 0);

    setBack(backToCategories);
    loadList(cat.id);
  }

  function backToCategories() {
    state.view = 'categories';
    state.category = null;
    $('viewList').hidden = true;
    $('viewCategories').hidden = false;
    window.scrollTo(0, 0);
    setBack(goHome);
  }

  function setListState(which) {
    $('listLoading').hidden = which !== 'loading';
    $('listError').hidden = which !== 'error';
    $('listEmpty').hidden = which !== 'empty';
    if (which !== 'ready') {
      $('podium').hidden = true;
      $('listDivider').hidden = true;
      $('promoteStrip').hidden = true;
      $('listRows').textContent = '';
    }
  }

  function loadList(categoryId) {
    setListState('loading');
    getJSON('/api/business/list?category_id=' + encodeURIComponent(categoryId))
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        state.pricing = data.pricing;
        renderList(data);
      })
      .catch(function () { setListState('error'); });
  }

  function renderList(data) {
    var podium = data.podium || [];
    var rest = data.businesses || [];
    var pricing = data.pricing || {};

    if (!podium.length && !rest.length) {
      setListState('empty');
      return;
    }
    setListState('ready');

    renderPodium(podium, pricing);
    renderRows(rest);

    // The divider only earns its space when there is something on both sides.
    var podiumVisible = !$('podium').hidden;
    $('listDivider').hidden = !(podiumVisible && rest.length);

    renderPromote(pricing);
  }

  function renderPodium(podium, pricing) {
    var host = $('podiumSlots');
    host.textContent = '';

    // Below the threshold there is nothing worth competing for, so the whole
    // zone disappears and every business uses the plain row treatment.
    if (!pricing.showBidding) {
      $('podium').hidden = true;
      return;
    }
    $('podium').hidden = false;

    var size = pricing.podiumSize || 3;

    podium.forEach(function (business, i) {
      host.appendChild(podiumCard(business, i + 1));
    });

    // Empty positions are advertised, not hidden: a category with one bidder
    // still shows #2 and #3 going spare. This is the conversion surface.
    for (var pos = podium.length + 1; pos <= size; pos++) {
      host.appendChild(emptySlot(pos, pricing.prices ? pricing.prices[String(pos)] : null));
    }
  }

  function podiumCard(business, position) {
    var card = el('button', 'bz-card bz-card--r' + position);
    card.type = 'button';

    card.appendChild(el('div', 'bz-rank', String(position)));
    card.appendChild(logoNode(business, 'bz-logo bz-logo--lg'));

    var body = el('div', 'bz-card-body');
    body.appendChild(el('div', 'bz-name', business.name));
    if (business.description) {
      body.appendChild(el('div', 'bz-desc', business.description));
    }
    body.appendChild(statsNode(business));
    card.appendChild(body);

    card.addEventListener('click', function () { openSheet(business.id); });
    return card;
  }

  function emptySlot(position, price) {
    var slot = el('div', 'bz-slot-empty');
    slot.appendChild(el('div', 'bz-rank', String(position)));
    slot.appendChild(el('div', 'bz-slot-text', "Bu o'rin bo'sh"));
    if (price) {
      var tag = el('div', 'bz-slot-price', formatKRW(price) + '  →');
      slot.appendChild(tag);
    }
    slot.addEventListener('click', function () {
      haptic('light');
      openBiddingInfo(position, price);
    });
    return slot;
  }

  function renderRows(businesses) {
    var host = $('listRows');
    host.textContent = '';

    businesses.forEach(function (business) {
      var row = el('button', 'bz-row');
      row.type = 'button';
      row.appendChild(logoNode(business, 'bz-logo'));

      var body = el('div', 'bz-row-body');
      body.appendChild(el('div', 'bz-name', business.name));
      body.appendChild(statsNode(business));
      row.appendChild(body);

      row.addEventListener('click', function () { openSheet(business.id); });
      host.appendChild(row);
    });
  }

  function renderPromote(pricing) {
    var strip = $('promoteStrip');
    if (!pricing.showBidding || !pricing.prices) {
      strip.hidden = true;
      return;
    }
    strip.hidden = false;
    $('promotePrice').textContent = '#1 — ' + formatKRW(pricing.prices['1']);
  }

  // ============================================
  // BIDDING INFO
  // ============================================
  // Phase 1 explains the mechanism and hands off to the admin, since payment
  // is manual anyway. Phase 4 replaces this with the real bid submission.

  function openBiddingInfo(position, price) {
    var pricing = state.pricing || {};
    var prices = pricing.prices || {};

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('h2', 'bz-sheet-title', 'Yuqori o‘rin uchun'));
    wrap.appendChild(el('p', 'bz-sheet-lede',
      'Har bir yo‘nalishda birinchi uchta o‘rin ochiq tanlovda. ' +
      'Yuqoriroq turish uchun hozirgi egasidan kamida ' +
      formatKRW(pricing.bidStep || 5000) + ' ko‘proq taklif qilinadi.'));

    var table = el('div', 'bz-price-table');
    [1, 2, 3].forEach(function (pos) {
      if (!prices[String(pos)]) return;
      var row = el('div', 'bz-price-row' + (pos === position ? ' is-target' : ''));
      row.appendChild(el('span', 'bz-price-pos', '#' + pos));
      row.appendChild(el('span', 'bz-price-val', formatKRW(prices[String(pos)])));
      row.appendChild(el('span', 'bz-price-note', 'yoki undan yuqori'));
      table.appendChild(row);
    });
    wrap.appendChild(table);

    var notes = el('ul', 'bz-note-list');
    [
      'Ro‘yxatga kirish to‘lovi ' + formatKRW(pricing.listingFee || 5000) +
        ' — bu o‘rin uchun to‘lovdan alohida.',
      'To‘lov admin bilan qo‘lda amalga oshiriladi.',
      'To‘lov tasdiqlangandan keyin o‘rin o‘zgaradi.',
      'Oldin taklif qilgan bo‘lsangiz, faqat farqini to‘laysiz.',
      'To‘lov qaytarilmaydi.'
    ].forEach(function (text) { notes.appendChild(el('li', null, text)); });
    wrap.appendChild(notes);

    var cta = el('a', 'bz-sheet-cta', 'Admin bilan bog‘lanish');
    cta.href = 'https://t.me/otabeksattarov';
    cta.addEventListener('click', function (e) {
      e.preventDefault();
      try { tg.openTelegramLink('https://t.me/otabeksattarov'); }
      catch (err) { window.open('https://t.me/otabeksattarov', '_blank'); }
    });
    wrap.appendChild(cta);

    mountSheet(wrap);
  }

  // ============================================
  // DETAIL BOTTOM SHEET
  // ============================================

  function openSheet(businessId) {
    haptic('light');

    var loading = el('div', 'bz-sheet-body');
    var spinner = el('div', 'bz-spinner');
    loading.appendChild(spinner);
    mountSheet(loading);

    getJSON('/api/business/' + encodeURIComponent(businessId))
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        state.business = data.business;
        mountSheet(detailBody(data.business));
        countTap(businessId);
      })
      .catch(function () {
        var err = el('div', 'bz-sheet-body');
        err.appendChild(el('p', 'bz-inline-error', "Ma'lumotni yuklab bo'lmadi."));
        mountSheet(err);
      });
  }

  function detailBody(business) {
    var wrap = el('div', 'bz-sheet-body');

    var head = el('div', 'bz-sheet-head');
    head.appendChild(logoNode(business, 'bz-logo bz-logo--xl'));

    var headText = el('div');
    headText.appendChild(el('p', 'bz-sheet-eyebrow', business.categoryName || ''));
    var h = el('h2', 'bz-sheet-name', business.name);
    h.id = 'sheetName';
    headText.appendChild(h);
    headText.appendChild(statsNode(business));
    head.appendChild(headText);
    wrap.appendChild(head);

    if (business.description) {
      // Newlines survive through white-space: pre-line in the CSS rather than
      // by turning them into <br>, so the text never becomes markup.
      wrap.appendChild(el('p', 'bz-sheet-desc', business.description));
    }

    var links = business.links || [];
    if (links.length) {
      var grid = el('div', 'bz-link-grid');
      links.forEach(function (link) {
        var node = linkNode(link);
        if (node) grid.appendChild(node);
      });
      if (grid.childNodes.length) wrap.appendChild(grid);
    }

    return wrap;
  }

  function linkNode(link) {
    var meta = LINK_META[link.kind];
    if (!meta || !link.value) return null;

    var node = el('button', 'bz-link');
    node.type = 'button';
    node.appendChild(iconSpan('bz-link-icon', meta.icon));

    var body = el('span', 'bz-link-body');
    body.appendChild(el('span', 'bz-link-label', meta.label));
    body.appendChild(el('span', 'bz-link-value', displayValue(link)));
    node.appendChild(body);

    if (link.kind === 'phone') {
      node.appendChild(iconSpan('bz-link-tail', ICONS.copy));
      node.addEventListener('click', function () { handlePhone(link.value); });
    } else {
      node.addEventListener('click', function () { openExternal(link); });
    }
    return node;
  }

  function displayValue(link) {
    if (link.kind === 'phone') return link.value;
    try {
      var u = new URL(link.value);
      var segs = u.pathname.split('/').filter(Boolean);
      if (link.kind === 'website') return u.hostname.replace(/^www\./, '');
      if (segs.length) return '@' + segs[0].replace(/^@/, '');
      return u.hostname;
    } catch (e) {
      return link.value;
    }
  }

  // Android opens the dialer. On iOS a tel: link inside the Mini App webview
  // has caused trouble before, so there the number is copied instead.
  function handlePhone(number) {
    var platform = (tg.platform || '').toLowerCase();
    if (platform === 'android') {
      haptic('light');
      window.location.href = 'tel:' + number;
      return;
    }
    copyText(number).then(function (ok) {
      if (ok) {
        try { tg.HapticFeedback.notificationOccurred('success'); } catch (e) {}
        showToast('Raqam nusxalandi: ' + number);
      } else {
        showToast(number);
      }
    });
  }

  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).then(function () { return true; })
        .catch(function () { return legacyCopy(text); });
    }
    return Promise.resolve(legacyCopy(text));
  }

  function legacyCopy(text) {
    try {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      var ok = document.execCommand('copy');
      document.body.removeChild(ta);
      return ok;
    } catch (e) {
      return false;
    }
  }

  function openExternal(link) {
    var url = link.value;
    if (!/^https?:\/\//i.test(url)) return;   // never hand a non-http scheme on
    haptic('light');
    try {
      if (link.kind === 'telegram') tg.openTelegramLink(url);
      else tg.openLink(url, { try_instant_view: false });
    } catch (e) {
      window.open(url, '_blank', 'noopener');
    }
  }

  // Fire and forget: a failed tap log must never block the sheet.
  function countTap(businessId) {
    fetch(API + '/api/business/' + encodeURIComponent(businessId) + '/tap', {
      method: 'POST',
      headers: Object.assign({ 'Content-Type': 'application/json' }, initDataHeader()),
      keepalive: true
    }).catch(function () {});
  }

  // ============================================
  // SHEET MECHANICS
  // ============================================

  function mountSheet(content) {
    var scroll = $('sheetScroll');
    scroll.textContent = '';
    scroll.appendChild(content);
    showSheet();
  }

  function showSheet() {
    var backdrop = $('sheetBackdrop');
    var sheet = $('sheet');
    if (!backdrop.hidden) return;

    backdrop.hidden = false;
    requestAnimationFrame(function () {
      backdrop.classList.add('visible');
      sheet.classList.add('visible');
    });
    setBack(closeSheet);
  }

  function closeSheet() {
    var backdrop = $('sheetBackdrop');
    var sheet = $('sheet');
    if (backdrop.hidden) return;

    backdrop.classList.remove('visible');
    sheet.classList.remove('visible');
    setTimeout(function () {
      backdrop.hidden = true;
      $('sheetScroll').textContent = '';
    }, 260);

    state.business = null;
    setBack(state.view === 'list' ? backToCategories : goHome);
  }

  // ============================================
  // INIT
  // ============================================

  function init() {
    setBack(goHome);

    $('sheetBackdrop').addEventListener('click', function (e) {
      if (e.target === $('sheetBackdrop')) closeSheet();
    });
    $('sheet').addEventListener('click', function (e) { e.stopPropagation(); });
    $('listBackBtn').addEventListener('click', function () {
      haptic('light');
      backToCategories();
    });
    $('listRetryBtn').addEventListener('click', function () {
      if (state.category) loadList(state.category.id);
    });
    $('promoteBtn').addEventListener('click', function () {
      var prices = (state.pricing || {}).prices || {};
      openBiddingInfo(1, prices['1']);
    });
    $('ownerContactBtn').addEventListener('click', function (e) {
      e.preventDefault();
      try { tg.openTelegramLink('https://t.me/otabeksattarov'); }
      catch (err) { window.open('https://t.me/otabeksattarov', '_blank'); }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeSheet();
    });

    loadCategories();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
