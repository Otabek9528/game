// business.js - Biznes Katalogi
//
// One screen. The feed is the landing: businesses are on screen the moment the
// page opens, and the category picker narrows to one in place. Nothing
// navigates except the sheets, so a business is always one tap away.
//
// Ranking is strictly per category. The feed groups by category and orders
// inside each group; there is no cross-category ordering anywhere, because a
// bid in Sug'urta and a bid in Pishiriqlar are not competing for the same
// thing.
//
// Nothing owner-supplied reaches innerHTML. Names and descriptions go in as
// text nodes; links are typed (kind, value) pairs rendered as buttons we
// build, so a listing can never inject markup into a page carrying the
// visitor's Telegram session.

(function () {
  'use strict';

  var tg = window.Telegram.WebApp;
  tg.ready();
  try { tg.expand(); } catch (e) {}
  try { tg.disableVerticalSwipes(); } catch (e) {}

  var API = (window.API_CONFIG ? window.API_CONFIG.BASE_URL : 'https://vegukin-api.duckdns.org/')
              .replace(/\/+$/, '');
  var TIMEOUT = 30000;
  var ADMIN = 'https://t.me/otabeksattarov';

  // How many of a category's businesses the feed shows before deferring to
  // the category view. Enough to be useful, few enough to keep scrolling.
  var FEED_PER_CATEGORY = 4;

  var state = {
    mode: 'feed',        // 'feed' | 'category'
    categoryId: null,
    categoryName: '',
    categoryIcon: '',
    query: '',
    categories: [],
    pricing: null
  };

  function $(id) { return document.getElementById(id); }

  function haptic(kind) {
    try { tg.HapticFeedback.impactOccurred(kind || 'light'); } catch (e) {}
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

  function postJSON(path, body) {
    return fetch(API + path, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Init-Data': (tg && tg.initData) ? tg.initData : ''
      },
      body: JSON.stringify(body || {}),
      signal: AbortSignal.timeout(TIMEOUT)
    }).then(function (r) {
      return r.json().then(function (data) {
        if (!r.ok || !data.success) {
          var err = new Error(data.error || 'http_' + r.status);
          err.code = data.error;
          throw err;
        }
        return data;
      });
    });
  }

  // ============================================
  // ICONS
  // ============================================
  // One stroke weight throughout. No emoji anywhere on this page: the
  // categories are set in type, which is what keeps the feed looking like a
  // directory rather than a sticker sheet.

  var ICONS = {
    heart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 20.3 4.3 12.6a4.9 4.9 0 0 1 6.9-6.9l.8.8.8-.8a4.9 4.9 0 1 1 6.9 6.9Z"/></svg>',
    eye: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.6-6.4 10-6.4S22 12 22 12s-3.6 6.4-10 6.4S2 12 2 12Z"/><circle cx="12" cy="12" r="2.5"/></svg>',
    arrow: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6"/></svg>',
    globe: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18"/></svg>',
    phone: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.13.96.36 1.9.7 2.8a2 2 0 0 1-.45 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.25a2 2 0 0 1 2.1-.45c.9.34 1.84.57 2.8.7A2 2 0 0 1 22 16.9z"/></svg>',
    telegram: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M9.78 18.65l.28-4.23 7.68-6.92c.34-.31-.07-.46-.52-.19L7.74 13.3 3.64 12c-.88-.25-.89-.86.2-1.3l15.97-6.16c.73-.33 1.43.18 1.15 1.3l-2.72 12.81c-.19.91-.74 1.13-1.5.71L12.6 16.3l-2.01 1.95c-.23.23-.42.42-.81.42z"/></svg>',
    instagram: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5.2"/><circle cx="12" cy="12" r="4.1"/><circle cx="17.3" cy="6.7" r="1.2" fill="currentColor" stroke="none"/></svg>',
    tiktok: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.6 2h-3.2v13.2a2.9 2.9 0 1 1-2.4-2.85V9.1a6.1 6.1 0 1 0 5.6 6.08V8.9a7.3 7.3 0 0 0 4.3 1.38V7.06A4.4 4.4 0 0 1 16.6 2z"/></svg>',
    appstore: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.4 12.7c0-2.2 1.8-3.3 1.9-3.3-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.7.8-3.3.8-.7 0-1.7-.8-2.8-.8-1.5 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.4 1.1 8.5.7 1 1.5 2.2 2.6 2.1 1.1 0 1.5-.7 2.8-.7s1.6.7 2.8.7c1.2 0 1.9-1 2.6-2.1.8-1.2 1.2-2.3 1.2-2.4-.1 0-2.2-.9-2.2-3.2zM14.2 5.9c.6-.7 1-1.7.9-2.7-.9 0-2 .6-2.6 1.3-.6.6-1.1 1.6-.9 2.6 1 .1 2-.5 2.6-1.2z"/></svg>',
    playstore: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3.6 2.4a1 1 0 0 0-.4.8v17.6a1 1 0 0 0 .4.8l9.3-9.6zM14.3 10.3 5.6 1.7l10.9 6.2zM14.3 13.7l2.2 2.4-10.9 6.2zM17.9 9l3 1.7a1.3 1.3 0 0 1 0 2.6l-3 1.7-2.5-3z"/></svg>',
    kakao: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 3C6.9 3 2.8 6.3 2.8 10.3c0 2.6 1.7 4.9 4.3 6.2l-1.1 4c-.1.3.3.6.6.4l4.7-3.1c.2 0 .5.1.7.1 5.1 0 9.2-3.3 9.2-7.6S17.1 3 12 3z"/></svg>',
    thumbUp: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7 22V10l5-8a2.4 2.4 0 0 1 2.3 3.1L13.4 9H19a2.2 2.2 0 0 1 2.1 2.8l-2 8A2.2 2.2 0 0 1 17 22Z"/><path d="M7 10H4.5A1.5 1.5 0 0 0 3 11.5v9A1.5 1.5 0 0 0 4.5 22H7"/></svg>',
    thumbDown: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 2v12l-5 8a2.4 2.4 0 0 1-2.3-3.1L10.6 15H5a2.2 2.2 0 0 1-2.1-2.8l2-8A2.2 2.2 0 0 1 7 2Z"/><path d="M17 14h2.5A1.5 1.5 0 0 0 21 12.5v-9A1.5 1.5 0 0 0 19.5 2H17"/></svg>',
    plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"/></svg>',
    check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m4 12.5 5 5L20 6.5"/></svg>',
    clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
    copy: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="12" height="12" rx="2.4"/><path d="M5.5 15H4.6A1.6 1.6 0 0 1 3 13.4V4.6A1.6 1.6 0 0 1 4.6 3h8.8A1.6 1.6 0 0 1 15 4.6v.9"/></svg>'
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
  // DOM HELPERS
  // ============================================

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function iconSpan(className, svg) {
    var s = el('span', className);
    s.innerHTML = svg;          // trusted constant, never listing-supplied
    return s;
  }

  function initials(name) {
    return (name || '?')
      .split(/\s+/).filter(Boolean).slice(0, 2)
      .map(function (w) { return w.charAt(0).toUpperCase(); })
      .join('');
  }

  // A business without a logo still gets a colour of its own, derived from
  // the name so it never changes between loads. Keeps the feed from looking
  // like a column of grey squares without resorting to emoji.
  function hueOf(name) {
    var h = 0;
    for (var i = 0; i < (name || '').length; i++) {
      h = (h * 31 + name.charCodeAt(i)) % 360;
    }
    return h;
  }

  // A glyph per category, from the database. Used only where a category is
  // being named — the section heads, the picker, the filter control — so it
  // reads as that category's mark rather than as scattered decoration. The
  // business rows below stay clean.
  function glyphNode(icon, className) {
    var box = el('span', className || 'bz-glyph');
    box.textContent = icon || '\u2022';
    return box;
  }

  function formatKRW(n) {
    return Number(n || 0).toLocaleString('en-US') + ' KRW';
  }

  var toastTimer = null;
  function showToast(message) {
    var t = $('bzToast');
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
  // BACK BUTTON
  // ============================================
  // One handler at a time, swapped as depth changes: sheet, category, home.

  var backHandler = null;

  function setBack(fn) {
    if (!tg.BackButton) return;
    if (backHandler) tg.BackButton.offClick(backHandler);
    backHandler = fn;
    if (fn) { tg.BackButton.onClick(fn); tg.BackButton.show(); }
    else { tg.BackButton.hide(); }
  }

  function goHome() { window.location.href = '../../index.html'; }

  function currentBack() {
    return state.mode === 'category' ? backToFeed : goHome;
  }

  // ============================================
  // SHARED PIECES
  // ============================================

  function logoNode(business, size) {
    var box = el('div', 'bz-logo' + (size ? ' bz-logo--' + size : ''));
    if (business.logo) {
      var img = document.createElement('img');
      img.src = API + '/' + String(business.logo).replace(/^\/+/, '');
      img.alt = '';
      img.loading = 'lazy';
      img.addEventListener('error', function () { monogram(box, business.name); });
      box.appendChild(img);
    } else {
      monogram(box, business.name);
    }
    return box;
  }

  function monogram(box, name) {
    box.textContent = initials(name);
    box.classList.add('bz-logo--mono');
    box.style.setProperty('--h', hueOf(name));
  }

  function metaNode(business, categoryName) {
    var meta = el('div', 'bz-meta');

    if (categoryName) {
      meta.appendChild(el('span', 'bz-catchip', categoryName));
    }

    var likes = el('span', 'bz-stat');
    likes.appendChild(iconSpan('bz-stat-icon', ICONS.heart));
    likes.appendChild(el('span', null, String(business.likes)));
    meta.appendChild(likes);

    var taps = el('span', 'bz-stat');
    taps.appendChild(iconSpan('bz-stat-icon', ICONS.eye));
    taps.appendChild(el('span', null, String(business.taps)));
    meta.appendChild(taps);

    return meta;
  }

  // rank is passed only for businesses actually holding a paid position, so
  // the gold rail always means paid and never means popular.
  function businessRow(business, opts) {
    opts = opts || {};
    var row = el('button', 'bz-row');
    row.type = 'button';

    // A held position gets a standing badge at the head of the row rather
    // than a chip buried in the meta line. Rank is the first thing to read
    // on these rows, so it goes where the eye lands first.
    if (opts.rank) {
      row.classList.add('bz-row--paid', 'bz-row--r' + opts.rank);
      row.appendChild(el('span', 'bz-badge', '#' + opts.rank));
    }

    row.appendChild(logoNode(business));

    var body = el('div', 'bz-row-body');
    body.appendChild(el('div', 'bz-rowname', business.name));
    if (opts.showDescription && business.description) {
      body.appendChild(el('div', 'bz-rowdesc', business.description));
    }
    body.appendChild(metaNode(business, opts.categoryName));
    row.appendChild(body);

    row.addEventListener('click', function () { openSheet(business.id); });
    return row;
  }

  function sectionHeader(title, count, onMore, icon) {
    var head = el('div', 'bz-sechead');
    head.appendChild(glyphNode(icon, 'bz-glyph bz-glyph--sec'));

    var text = el('span', 'bz-sectext');
    text.appendChild(el('span', 'bz-sectitle', title));
    if (count != null) text.appendChild(el('span', 'bz-seccount', count + ' ta'));
    head.appendChild(text);

    if (onMore) {
      var more = el('button', 'bz-secmore');
      more.type = 'button';
      more.appendChild(el('span', null, 'Barchasi'));
      more.appendChild(iconSpan('bz-secmore-icon', ICONS.arrow));
      more.addEventListener('click', function (e) { e.stopPropagation(); onMore(); });
      head.appendChild(more);
    }
    return head;
  }

  // ============================================
  // VIEW STATE
  // ============================================

  function setView(which) {
    $('bzLoading').hidden = which !== 'loading';
    $('bzEmpty').hidden = which !== 'empty';
    $('bzError').hidden = which !== 'error';
    if (which !== 'ready') $('bzBody').textContent = '';
  }

  // ============================================
  // FEED
  // ============================================

  function loadFeed() {
    setView('loading');
    var path = '/api/business/feed' +
      (state.query ? '?q=' + encodeURIComponent(state.query) : '');

    getJSON(path)
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        if (data.categories) state.categories = data.categories;
        syncFilter();
        renderFeed(data);
      })
      .catch(function () { setView('error'); });
  }

  function renderFeed(data) {
    var groups = data.groups || [];
    $('bzCount').textContent = data.total ? data.total + ' ta biznes' : '';

    setView('ready');
    var host = $('bzBody');
    host.textContent = '';

    // An empty catalogue is the moment an owner is most useful to us, so the
    // invitation goes here rather than a dead end. A fruitless search is a
    // different thing and gets no pitch.
    if (!groups.length) {
      if (state.query) {
        host.appendChild(emptyBlock(
          'Hech narsa topilmadi',
          '"' + state.query + '" bo‘yicha biznes yo‘q. Boshqa so‘z bilan qidirib ko‘ring.'));
        return;
      }
      host.appendChild(emptyBlock(
        'Katalog hozircha bo‘sh',
        'Bu yerda Koreyadagi o‘zbek bizneslari to‘planadi. ' +
        'Birinchi bo‘lib qo‘shilsangiz, yo‘nalishingizda uzoq vaqt yolg‘iz turasiz.'));
      host.appendChild(ownerCard());
      return;
    }

    groups.forEach(function (group) {
      var section = el('section', 'bz-section');
      var cat = group.category;
      var shown = 0;

      var podium = group.podium || [];
      var rest = group.businesses || [];
      var all = podium.concat(rest);
      var visible = all.slice(0, FEED_PER_CATEGORY);

      section.appendChild(sectionHeader(
        cat.name,
        group.total,
        group.total > visible.length
          ? function () { openCategory(cat.id, cat.name, cat.icon); } : null,
        cat.icon
      ));

      visible.forEach(function (business, i) {
        var rank = i < podium.length ? i + 1 : null;
        section.appendChild(businessRow(business, { rank: rank }));
        shown++;
      });

      host.appendChild(section);
    });

    host.appendChild(ownerCard());
  }

  // ============================================
  // CATEGORY VIEW
  // ============================================

  function openCategory(categoryId, categoryName, categoryIcon) {
    haptic('light');
    state.mode = 'category';
    state.categoryId = categoryId;
    state.categoryName = categoryName;
    state.categoryIcon = categoryIcon || '';
    syncFilter();
    setBack(backToFeed);
    $('bzScroll').scrollTop = 0;
    loadCategory();
  }

  function backToFeed() {
    state.mode = 'feed';
    state.categoryId = null;
    state.categoryName = '';
    state.categoryIcon = '';
    state.pricing = null;
    syncFilter();
    setBack(goHome);
    $('bzScroll').scrollTop = 0;
    loadFeed();
  }

  function loadCategory() {
    setView('loading');
    getJSON('/api/business/list?category_id=' + encodeURIComponent(state.categoryId))
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        state.pricing = data.pricing;
        renderCategory(data);
      })
      .catch(function () { setView('error'); });
  }

  function renderCategory(data) {
    var podium = data.podium || [];
    var rest = data.businesses || [];
    var pricing = data.pricing || {};

    $('bzCount').textContent = data.total ? data.total + ' ta biznes' : '';

    setView('ready');
    var host = $('bzBody');
    host.textContent = '';

    // An empty category is a real destination now, reachable from the picker,
    // so it explains itself and offers the one action that makes sense here.
    if (!podium.length && !rest.length) {
      host.appendChild(emptyBlock(
        state.categoryName + ' bo‘yicha hali biznes yo‘q',
        'Bu yo‘nalish ochiq. Birinchi qo‘shilgan biznes uzoq vaqt yagona ' +
        'bo‘lib turadi va yuqori o‘rin uchun hech kim bilan tanlashmaydi.',
        state.categoryIcon));
      host.appendChild(ownerCard());
      return;
    }

    // The podium only appears where positions are actually contested.
    if (pricing.showBidding) {
      var top = el('section', 'bz-section');
      top.appendChild(sectionHeader('Top o‘rinlar', null, null, '\u2605'));

      podium.forEach(function (business, i) {
        top.appendChild(businessRow(business, { rank: i + 1, showDescription: true }));
      });

      var size = pricing.podiumSize || 3;
      for (var pos = podium.length + 1; pos <= size; pos++) {
        top.appendChild(emptySlot(pos));
      }
      host.appendChild(top);
    }

    if (rest.length) {
      var all = el('section', 'bz-section' + (pricing.showBidding ? ' bz-section--tight' : ''));

      // "Barcha bizneslar" read as every business in the directory, which is
      // the opposite of what it labelled. A marker closing the contested
      // three says the same thing without naming the group at all, and
      // closes the gap the second heading opened.
      if (pricing.showBidding) {
        var line = el('div', 'bz-topline');
        line.appendChild(el('span', 'bz-topline-tag', 'TOP 3'));
        all.appendChild(line);
      }

      rest.forEach(function (business) {
        all.appendChild(businessRow(business, { showDescription: !pricing.showBidding }));
      });
      host.appendChild(all);
    }

    host.appendChild(ownerCard());
  }

  // Deliberately carries no number. What a position costs is an owner's
  // business, not something to put in front of someone browsing for a bakery;
  // the figures live behind this tap, in the owner sheet.
  function emptySlot(position) {
    var slot = el('button', 'bz-slot');
    slot.type = 'button';
    slot.appendChild(el('span', 'bz-badge bz-badge--ghost', '#' + position));
    slot.appendChild(el('span', 'bz-slot-text', 'Bu o‘rin bo‘sh'));
    slot.appendChild(iconSpan('bz-slot-arrow', ICONS.arrow));
    slot.addEventListener('click', function () {
      haptic('light');
      openOwnerSheet(position);
    });
    return slot;
  }

  // ============================================
  // OWNER ENTRY
  // ============================================
  // The only route to the money. Someone looking for a bakery never sees a
  // price; an owner gets a standing invitation at the end of every list and
  // the whole mechanism one tap behind it.

  function emptyBlock(title, body, icon) {
    var box = el('div', 'bz-blank');
    box.appendChild(glyphNode(icon || '\u25C6', 'bz-glyph bz-blank-glyph'));
    box.appendChild(el('h3', 'bz-blank-title', title));
    box.appendChild(el('p', 'bz-blank-body', body));
    return box;
  }

  function ownerCard() {
    var card = el('button', 'bz-owner');
    card.type = 'button';

    var text = el('span', 'bz-owner-text');
    text.appendChild(el('span', 'bz-owner-title', 'Biznesingiz bormi?'));
    text.appendChild(el('span', 'bz-owner-sub',
      'Katalogga qo‘shiling va yo‘nalishingizda yuqori o‘rinni egallang'));
    card.appendChild(text);
    card.appendChild(iconSpan('bz-owner-arrow', ICONS.arrow));

    card.addEventListener('click', function () {
      haptic('light');
      openOwnerSheet(null);
    });
    return card;
  }

  // Prices need a category to be about, so from the unfiltered feed this
  // explains the mechanism and hands off to the picker; inside a category it
  // shows that category's ladder.
  function openOwnerSheet(targetPosition) {
    var pricing = state.pricing || {};
    var prices = pricing.prices || {};
    var inCategory = state.mode === 'category';

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('p', 'bz-sheet-eyebrow',
      inCategory ? state.categoryName : 'Biznes egalari uchun'));
    wrap.appendChild(el('h2', 'bz-sheet-name', 'Katalogga qo‘shilish'));

    var steps = el('div', 'bz-steps');
    steps.appendChild(stepRow('1', 'Ro‘yxatdan o‘tish',
      'Bir martalik ' + formatKRW(pricing.listingFee || 5000) +
      '. Biznesingiz katalogda doimiy qoladi.'));
    steps.appendChild(stepRow('2', 'Yuqori o‘rin — ixtiyoriy',
      'Har bir yo‘nalishda birinchi uchta o‘rin ochiq tanlovda. ' +
      'Bu ro‘yxatga kirish to‘lovidan alohida.'));
    steps.appendChild(stepRow('3', 'O‘rinni egallash',
      'Hozirgi egasidan kamida ' + formatKRW(pricing.bidStep || 5000) +
      ' ko‘proq taklif qiling. Oldin taklif qilgan bo‘lsangiz, faqat farqini to‘laysiz.'));
    wrap.appendChild(steps);

    if (inCategory && pricing.showBidding && prices['1']) {
      wrap.appendChild(el('p', 'bz-sheet-sublabel',
        state.categoryName + ' — hozirgi narxlar'));

      var table = el('div', 'bz-prices');
      [1, 2, 3].forEach(function (pos) {
        if (!prices[String(pos)]) return;
        var row = el('div', 'bz-prices-row' + (pos === targetPosition ? ' is-target' : ''));
        row.appendChild(el('span', 'bz-badge bz-badge--sm', '#' + pos));
        row.appendChild(el('span', 'bz-prices-val', formatKRW(prices[String(pos)])));
        row.appendChild(el('span', 'bz-prices-note', 'dan'));
        table.appendChild(row);
      });
      wrap.appendChild(table);
      wrap.appendChild(el('p', 'bz-sheet-fine',
        'Ko‘rsatilgan summa yoki undan yuqorisi shu o‘rinni yoki undan ' +
        'balandrog‘ini beradi. To‘lov admin bilan qo‘lda amalga oshiriladi ' +
        'va tasdiqlangandan keyin o‘rin o‘zgaradi. To‘lov qaytarilmaydi.'));
    } else if (!inCategory) {
      var pick = el('button', 'bz-btn bz-btn--ghost');
      pick.type = 'button';
      pick.textContent = 'Yo‘nalish narxlarini ko‘rish';
      pick.addEventListener('click', function () { openPicker(); });
      wrap.appendChild(pick);
    }

    var submit = el('button', 'bz-btn bz-btn--block');
    submit.type = 'button';
    submit.textContent = 'Biznesimni qo‘shish';
    submit.addEventListener('click', function () { openSubmitForm(); });
    wrap.appendChild(submit);

    var mineBtn = el('button', 'bz-btn bz-btn--ghost bz-btn--last');
    mineBtn.type = 'button';
    mineBtn.textContent = 'Mening bizneslarim';
    mineBtn.addEventListener('click', openMine);
    wrap.appendChild(mineBtn);

    mountSheet(wrap);
  }

  // ============================================
  // SUBMISSION
  // ============================================

  var LINK_FIELDS = [
    { kind: 'phone',     label: 'Telefon',   placeholder: '010-1234-5678', mode: 'tel' },
    { kind: 'telegram',  label: 'Telegram',  placeholder: '@username' },
    { kind: 'instagram', label: 'Instagram', placeholder: '@username' },
    { kind: 'website',   label: 'Veb-sayt',  placeholder: 'example.uz', mode: 'url' }
  ];

  var SUBMIT_ERRORS = {
    bad_name: 'Nomni tekshiring (2–80 harf).',
    bad_category: 'Yo‘nalishni tanlang.',
    description_too_long: 'Tavsif juda uzun.',
    no_contact: 'Kamida bitta bog‘lanish usulini kiriting.',
    invalid_phone: 'Telefon raqami noto‘g‘ri.',
    invalid_handle: 'Username noto‘g‘ri. Faqat harf, raqam, nuqta va pastki chiziq.',
    invalid_url: 'Havola noto‘g‘ri.',
    wrong_host: 'Havola boshqa saytga tegishli.',
    link_too_long: 'Havola juda uzun.',
    duplicate: 'Bu nomdagi biznesingiz allaqachon yuborilgan.',
    rate_limited: 'Bugungi limitga yetdingiz. Ertaga urinib ko‘ring.',
    no_init_data: 'Iltimos, sahifani Telegram ichida oching.',
    bad_signature: 'Telegram hisobingizni tasdiqlab bo‘lmadi.'
  };

  // Draft survives a trip to the category picker and back, so choosing a
  // category never costs the owner what they already typed.
  var draft = { name: '', description: '', links: {}, category: null,
                logoBlob: null, logoUrl: null };

  function clearDraft() {
    setDraftLogo(null);
    draft = { name: '', description: '', links: {}, category: null,
              logoBlob: null, logoUrl: null };
  }

  // One form for both jobs. In edit mode it opens on what is already stored
  // and sends only what the owner actually changed.
  function openSubmitForm(existing) {
    var editing = !!existing;
    if (editing && draft.id !== existing.id) {
      draft = {
        id: existing.id,
        name: existing.name,
        description: existing.description || '',
        links: {},
        category: { id: existing.categoryId, name: existing.categoryName,
                    icon: existing.categoryIcon },
        logo: existing.logo || null
      };
      (existing.links || []).forEach(function (l) {
        draft.links[l.kind] = displayValue(l);
      });
    }
    if (!editing && draft.id) clearDraft();
    if (!draft.category && state.mode === 'category') {
      draft.category = {
        id: state.categoryId, name: state.categoryName, icon: state.categoryIcon
      };
    }

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('p', 'bz-sheet-eyebrow',
      editing ? draft.category.name : 'Yangi biznes'));
    wrap.appendChild(el('h2', 'bz-sheet-name',
      editing ? 'Tahrirlash' : 'Katalogga qo‘shish'));

    wrap.appendChild(logoPicker(editing
      ? existing
      : { name: draft.name || 'Yangi biznes', logo: null }));

    var form = el('div', 'bz-form');

    var nameField = field('Biznes nomi', 'majburiy');
    var nameInput = el('input', 'bz-input');
    nameInput.type = 'text';
    nameInput.maxLength = 80;
    nameInput.placeholder = 'Samarqand Non';
    nameInput.value = draft.name;
    nameInput.addEventListener('input', function () { draft.name = nameInput.value; });
    nameField.appendChild(nameInput);
    form.appendChild(nameField);

    var catField = field('Yo‘nalish', 'majburiy');
    var catBtn = el('button', 'bz-select');
    catBtn.type = 'button';
    var catGlyph = glyphNode(draft.category ? draft.category.icon : '◆',
                             'bz-glyph bz-glyph--pick');
    var catLabel = el('span', 'bz-select-label',
                      draft.category ? draft.category.name : 'Tanlang');
    if (!draft.category) catLabel.classList.add('is-placeholder');
    catBtn.appendChild(catGlyph);
    catBtn.appendChild(catLabel);
    catBtn.appendChild(iconSpan('bz-select-caret', ICONS.arrow));
    catBtn.addEventListener('click', function () {
      openPicker(function (cat) {
        draft.category = cat;
        openSubmitForm(existing);
      });
    });
    catField.appendChild(catBtn);
    form.appendChild(catField);

    var descField = field('Tavsif', 'ixtiyoriy');
    var descInput = el('textarea', 'bz-input bz-textarea');
    descInput.rows = 4;
    descInput.maxLength = 500;
    descInput.placeholder = 'Nima taklif qilasiz, ish vaqti, yetkazib berish…';
    descInput.value = draft.description;
    var counter = el('span', 'bz-counter', draft.description.length + ' / 500');
    descInput.addEventListener('input', function () {
      draft.description = descInput.value;
      counter.textContent = descInput.value.length + ' / 500';
    });
    descField.appendChild(descInput);
    descField.appendChild(counter);
    form.appendChild(descField);

    var linkField = field('Bog‘lanish', 'kamida bittasi');
    var inputs = {};
    LINK_FIELDS.forEach(function (spec) {
      var row = el('div', 'bz-linkrow');
      row.appendChild(iconSpan('bz-linkrow-icon', LINK_META[spec.kind].icon));
      var input = el('input', 'bz-input bz-input--flat');
      input.type = 'text';
      input.maxLength = 200;
      input.placeholder = spec.placeholder;
      input.autocapitalize = 'none';
      input.spellcheck = false;
      if (spec.mode) input.inputMode = spec.mode;
      input.value = draft.links[spec.kind] || '';
      input.addEventListener('input', function () {
        draft.links[spec.kind] = input.value;
      });
      inputs[spec.kind] = input;
      row.appendChild(input);
      linkField.appendChild(row);
    });
    form.appendChild(linkField);

    wrap.appendChild(form);

    wrap.appendChild(el('p', 'bz-sheet-fine', editing
      ? 'O‘zgarishlar darhol saqlanadi. Admin xabardor qilinadi.'
      : 'Yuborilgandan keyin admin ko‘rib chiqadi. Ro‘yxatga kirish to‘lovi ' +
        formatKRW((state.pricing || {}).listingFee || 5000) +
        ' — admin bilan qo‘lda hal qilinadi.'));

    var error = el('p', 'bz-formerror');
    error.hidden = true;
    wrap.appendChild(error);

    var send = el('button', 'bz-btn bz-btn--block');
    send.type = 'button';
    send.textContent = editing ? 'Saqlash' : 'Yuborish';
    wrap.appendChild(send);

    function readLinks() {
      return LINK_FIELDS.map(function (spec) {
        return { kind: spec.kind, value: inputs[spec.kind].value.trim() };
      }).filter(function (l) { return l.value; });
    }

    function fail(code) {
      error.textContent = SUBMIT_ERRORS[code] ||
        'Xatolik yuz berdi. Qaytadan urinib ko‘ring.';
      error.hidden = false;
      try { tg.HapticFeedback.notificationOccurred('error'); } catch (e) {}
    }

    var sending = false;
    send.addEventListener('click', function () {
      if (sending) return;
      error.hidden = true;

      var links = readLinks();
      if (nameInput.value.trim().length < 2) return fail('bad_name');
      if (!draft.category) return fail('bad_category');
      if (!links.length) return fail('no_contact');

      sending = true;
      send.disabled = true;
      send.textContent = editing ? 'Saqlanmoqda…' : 'Yuborilmoqda…';
      nameInput.blur();

      var body = {
        name: nameInput.value.trim(),
        category_id: draft.category.id,
        description: descInput.value.trim(),
        links: links
      };
      var path = editing
        ? '/api/business/' + existing.id + '/edit'
        : '/api/business/submit';

      postJSON(path, body)
        .then(function (data) {
          try { tg.HapticFeedback.notificationOccurred('success'); } catch (e) {}
          if (editing) {
            clearDraft();
            showToast('Saqlandi');
            openMine();
            refreshCurrentView();
            return;
          }
          // The listing is in either way. A logo that fails to follow it is
          // worth a word, not a failed submission.
          var held = draft.logoBlob;
          if (!held) {
            clearDraft();
            showSubmitted();
            return;
          }
          send.textContent = 'Logo yuborilmoqda…';
          return uploadLogo(data.id, held)
            .then(function () { clearDraft(); showSubmitted(); })
            .catch(function () {
              clearDraft();
              showSubmitted('Biznes yuborildi, lekin logoni yuklab bo‘lmadi. ' +
                            'Uni keyinroq "Mening bizneslarim" bo‘limida qo‘shishingiz mumkin.');
            });
        })
        .catch(function (err) {
          sending = false;
          send.disabled = false;
          send.textContent = editing ? 'Saqlash' : 'Yuborish';
          fail(err.code);
        });
    });

    mountSheet(wrap);
  }

  // ============================================
  // LOGO
  // ============================================
  // Downscaled in the page before it goes anywhere, so a 4MB phone photo does
  // not have to cross a Korean mobile connection at full size. The server
  // re-encodes regardless — this is for speed, not for safety.

  var LOGO_EDGE = 512;

  // Two modes. With a business id the file goes straight up. Without one —
  // during submission — it is held on the draft and sent the moment the
  // listing has an id, so an owner picks their logo where they expect to
  // rather than being sent back for it afterwards.
  function logoPicker(business) {
    var deferred = !business.id;
    var box = el('div', 'bz-logopick');

    var preview = el('div', 'bz-logopreview');
    paintPreview(preview, business);
    box.appendChild(preview);

    var side = el('div', 'bz-logoside');
    side.appendChild(el('span', 'bz-fieldlabel', 'Logo'));
    var hint = el('span', 'bz-logohint',
      deferred ? 'Ixtiyoriy. PNG yoki JPG' : 'PNG yoki JPG, kvadrat eng yaxshi');
    side.appendChild(hint);

    var pick = el('button', 'bz-logobtn');
    pick.type = 'button';
    pick.textContent = (business.logo || draft.logoBlob) ? 'Almashtirish' : 'Yuklash';
    side.appendChild(pick);
    box.appendChild(side);

    var input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/png,image/jpeg,image/webp';
    input.hidden = true;
    box.appendChild(input);

    pick.addEventListener('click', function () { input.click(); });

    input.addEventListener('change', function () {
      var file = input.files && input.files[0];
      input.value = '';
      if (!file) return;

      hint.textContent = deferred ? 'Tayyorlanmoqda…' : 'Yuklanmoqda…';
      pick.disabled = true;

      shrink(file)
        .then(function (blob) {
          if (deferred) {
            // Held until the listing exists. Nothing has been sent yet, so
            // the preview is of the local file.
            setDraftLogo(blob);
            showLocalPreview(preview, blob);
            hint.textContent = 'Tanlandi';
            pick.textContent = 'Almashtirish';
            try { tg.HapticFeedback.impactOccurred('light'); } catch (e) {}
            return null;
          }
          return uploadLogo(business.id, blob).then(function (data) {
            business.logo = data.logo;
            paintPreview(preview, business, data.version);
            hint.textContent = 'Saqlandi';
            pick.textContent = 'Almashtirish';
            try { tg.HapticFeedback.notificationOccurred('success'); } catch (e) {}
            refreshCurrentView();
          });
        })
        .catch(function (err) {
          hint.textContent = LOGO_ERRORS[err && err.code] ||
            'Yuklab bo‘lmadi. Boshqa rasm sinab ko‘ring.';
          try { tg.HapticFeedback.notificationOccurred('error'); } catch (e) {}
        })
        .then(function () { pick.disabled = false; });
    });

    return box;
  }

  var LOGO_ERRORS = {
    too_large: 'Rasm juda katta (6 MB gacha).',
    not_an_image: 'Bu rasm emas.',
    bad_format: 'Bu format qo‘llab-quvvatlanmaydi.',
    no_file: 'Rasm tanlanmadi.',
    server_misconfigured: 'Rasm yuklash vaqtincha ishlamayapti.'
  };

  // One object URL at a time; the previous is released so a few retries do
  // not leak the files behind them.
  function setDraftLogo(blob) {
    if (draft.logoUrl) { try { URL.revokeObjectURL(draft.logoUrl); } catch (e) {} }
    draft.logoBlob = blob;
    draft.logoUrl = blob ? URL.createObjectURL(blob) : null;
  }

  function showLocalPreview(node, blob) {
    node.textContent = '';
    node.className = 'bz-logopreview';
    node.style.removeProperty('--h');
    var img = document.createElement('img');
    img.src = draft.logoUrl || URL.createObjectURL(blob);
    img.alt = '';
    node.appendChild(img);
  }

  function paintPreview(node, business, version) {
    node.textContent = '';
    node.className = 'bz-logopreview';
    node.style.removeProperty('--h');
    if (business.logo) {
      var img = document.createElement('img');
      img.src = API + '/' + String(business.logo).replace(/^\/+/, '') +
                (version ? '?v=' + version : '');
      img.alt = '';
      node.appendChild(img);
    } else if (draft.logoUrl && !business.id) {
      var held = document.createElement('img');
      held.src = draft.logoUrl;
      held.alt = '';
      node.appendChild(held);
    } else {
      node.textContent = initials(business.name);
      node.classList.add('bz-logopreview--mono');
      node.style.setProperty('--h', hueOf(business.name));
    }
  }

  function shrink(file) {
    return new Promise(function (resolve, reject) {
      var url = URL.createObjectURL(file);
      var img = new Image();
      img.onload = function () {
        URL.revokeObjectURL(url);
        var scale = Math.min(1, LOGO_EDGE / Math.max(img.width, img.height));
        var w = Math.max(1, Math.round(img.width * scale));
        var h = Math.max(1, Math.round(img.height * scale));

        var canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        canvas.getContext('2d').drawImage(img, 0, 0, w, h);
        canvas.toBlob(function (blob) {
          // If the canvas refuses, send the original and let the server deal
          // with it rather than failing in the page.
          resolve(blob || file);
        }, 'image/webp', 0.9);
      };
      img.onerror = function () {
        URL.revokeObjectURL(url);
        var e = new Error('not_an_image');
        e.code = 'not_an_image';
        reject(e);
      };
      img.src = url;
    });
  }

  function uploadLogo(businessId, blob) {
    var form = new FormData();
    form.append('file', blob, 'logo.webp');
    return fetch(API + '/api/business/' + businessId + '/logo', {
      method: 'POST',
      headers: { 'X-Init-Data': (tg && tg.initData) ? tg.initData : '' },
      body: form,
      signal: AbortSignal.timeout(TIMEOUT)
    }).then(function (r) {
      return r.json().then(function (data) {
        if (!r.ok || !data.success) {
          var e = new Error(data.error || 'http_' + r.status);
          e.code = data.error;
          throw e;
        }
        return data;
      });
    });
  }

  // A change made in a sheet should be true of the list behind it too.
  function refreshCurrentView() {
    if (state.mode === 'category') loadCategory();
    else loadFeed();
  }

  function field(label, hint) {
    var box = el('div', 'bz-field');
    var head = el('div', 'bz-fieldhead');
    head.appendChild(el('span', 'bz-fieldlabel', label));
    if (hint) head.appendChild(el('span', 'bz-fieldhint', hint));
    box.appendChild(head);
    return box;
  }

  function showSubmitted(caveat) {
    var wrap = el('div', 'bz-sheet-body bz-done');
    wrap.appendChild(iconSpan('bz-done-icon', ICONS.check));
    wrap.appendChild(el('h2', 'bz-sheet-name', 'Yuborildi'));
    wrap.appendChild(el('p', 'bz-sheet-desc',
      'Admin ko‘rib chiqadi va tasdiqlangach biznesingiz katalogda ko‘rinadi. ' +
      'To‘lov bo‘yicha admin siz bilan bog‘lanadi.'));
    if (caveat) wrap.appendChild(el('p', 'bz-formerror', caveat));

    var cta = el('button', 'bz-btn bz-btn--block');
    cta.type = 'button';
    cta.textContent = 'Admin bilan bog‘lanish';
    cta.addEventListener('click', openAdmin);
    wrap.appendChild(cta);
    mountSheet(wrap);
  }

  // ============================================
  // MY BUSINESSES
  // ============================================

  var STATUS_TEXT = {
    pending_review: ['Ko‘rib chiqilmoqda', 'pending'],
    unpaid: ['To‘lov kutilmoqda', 'unpaid'],
    active: ['Katalogda', 'active'],
    rejected: ['Qabul qilinmadi', 'off'],
    suspended: ['To‘xtatilgan', 'off']
  };

  function openMine() {
    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('h2', 'bz-sheet-name', 'Mening bizneslarim'));
    var slot = el('div');
    slot.appendChild(el('div', 'bz-spinner'));
    wrap.appendChild(slot);
    mountSheet(wrap);

    fetch(API + '/api/business/mine', {
      headers: { 'X-Init-Data': (tg && tg.initData) ? tg.initData : '' },
      signal: AbortSignal.timeout(TIMEOUT)
    })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        slot.textContent = '';
        var items = (data && data.businesses) || [];
        if (!items.length) {
          slot.appendChild(el('p', 'bz-sheet-desc', 'Hali biznes qo‘shmagansiz.'));
        } else {
          var list = el('div', 'bz-minelist');
          items.forEach(function (b) { list.appendChild(mineRow(b)); });
          slot.appendChild(list);
        }
        var add = el('button', 'bz-btn bz-btn--block');
        add.type = 'button';
        add.textContent = 'Yangi biznes qo‘shish';
        add.addEventListener('click', function () { openSubmitForm(); });
        slot.appendChild(add);
      })
      .catch(function () {
        slot.textContent = '';
        slot.appendChild(el('p', 'bz-sheet-desc', 'Yuklab bo‘lmadi.'));
      });
  }

  function mineRow(business) {
    var row = el('div', 'bz-mine');
    row.appendChild(glyphNode(business.categoryIcon, 'bz-glyph bz-glyph--pick'));

    var body = el('div', 'bz-mine-body');
    body.appendChild(el('span', 'bz-mine-name', business.name));

    var meta = el('span', 'bz-mine-meta');
    var st = STATUS_TEXT[business.status] || [business.status, 'off'];
    meta.appendChild(el('span', 'bz-status bz-status--' + st[1], st[0]));
    if (business.status === 'active') {
      if (business.position) meta.appendChild(el('span', null, '#' + business.position));
      meta.appendChild(el('span', null, '♡ ' + business.likes));
      meta.appendChild(el('span', null, business.taps + ' ochilgan'));
    }
    body.appendChild(meta);
    row.appendChild(body);

    // Rejected listings are not the owner's to fix; everything else is.
    if (business.status !== 'rejected') {
      var edit = el('button', 'bz-mine-edit');
      edit.type = 'button';
      edit.textContent = 'Tahrirlash';
      edit.addEventListener('click', function () {
        haptic('light');
        openSubmitForm(business);
      });
      row.appendChild(edit);
    }
    return row;
  }

  function stepRow(n, title, body) {
    var row = el('div', 'bz-step');
    row.appendChild(el('span', 'bz-step-n', n));
    var text = el('span', 'bz-step-text');
    text.appendChild(el('span', 'bz-step-title', title));
    text.appendChild(el('span', 'bz-step-body', body));
    row.appendChild(text);
    return row;
  }

  // ============================================
  // CATEGORY PICKER
  // ============================================
  // Every category in one list, alphabetical, identical rows. A horizontal
  // rail hid whatever did not fit and made the first chip look like the most
  // important one; there was never a defensible basis for that order.
  // Alphabetical asserts no precedence and, unlike ordering by size, does not
  // reshuffle when a business is added somewhere else.

  function openPicker(onChoose) {
    haptic('light');

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('h2', 'bz-sheet-name',
      onChoose ? 'Yo‘nalishni tanlang' : 'Yo‘nalishlar'));

    var list = el('div', 'bz-picker');

    var all = el('button', 'bz-pick' + (state.mode === 'feed' ? ' is-on' : ''));
    all.type = 'button';
    all.appendChild(glyphNode('\u25C6', 'bz-glyph bz-glyph--pick'));
    all.appendChild(el('span', 'bz-pick-name', 'Barcha yo‘nalishlar'));
    all.appendChild(el('span', 'bz-pick-n', String(totalCount())));
    all.addEventListener('click', function () {
      closeSheet();
      if (state.mode !== 'feed') backToFeed();
    });
    if (!onChoose) list.appendChild(all);

    state.categories.forEach(function (cat) {
      var row = el('button', 'bz-pick');
      row.type = 'button';
      if (!cat.count) row.classList.add('is-quiet');
      if (state.mode === 'category' && state.categoryId === cat.id) {
        row.classList.add('is-on');
      }
      row.appendChild(glyphNode(cat.icon, 'bz-glyph bz-glyph--pick'));
      row.appendChild(el('span', 'bz-pick-name', cat.name));
      row.appendChild(el('span', 'bz-pick-n', cat.count ? String(cat.count) : '—'));

      // An empty category is shown so the set stays complete and an owner can
      // see their trade is listed, but there is nothing behind it to open.
      // Choosing for the form is a different job from filtering the list, and
      // an empty category is a perfectly good thing to be the first business in.
      if (onChoose) {
        row.disabled = false;
        row.classList.remove('is-on');
        row.addEventListener('click', function () { onChoose(cat); });
      } else {
        // Every category opens, empty or not. Landing on an empty one is how
        // an owner finds out their trade has a free field in it.
        row.addEventListener('click', function () {
          closeSheet();
          openCategory(cat.id, cat.name, cat.icon);
        });
      }
      list.appendChild(row);
    });

    wrap.appendChild(list);
    mountSheet(wrap);
  }

  function totalCount() {
    return state.categories.reduce(function (n, c) { return n + c.count; }, 0);
  }

  function syncFilter() {
    var filtered = state.mode === 'category';
    $('bzFilterLabel').textContent = filtered ? state.categoryName : 'Barcha yo‘nalishlar';
    $('bzFilterGlyph').textContent = filtered ? (state.categoryIcon || '\u25C6') : '\u25C6';
    $('bzFilter').classList.toggle('is-on', filtered);
    $('bzFilterClear').hidden = !filtered;
  }

  // ============================================
  // DETAIL SHEET
  // ============================================

  function openSheet(businessId) {
    haptic('light');

    var loading = el('div', 'bz-sheet-body');
    loading.appendChild(el('div', 'bz-spinner'));
    mountSheet(loading);

    getJSON('/api/business/' + encodeURIComponent(businessId))
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        mountSheet(detailBody(data.business));
        countTap(businessId);
      })
      .catch(function () {
        var err = el('div', 'bz-sheet-body');
        err.appendChild(el('p', 'bz-state-hint', 'Ma’lumotni yuklab bo‘lmadi.'));
        mountSheet(err);
      });
  }

  function detailBody(business) {
    var wrap = el('div', 'bz-sheet-body');

    var head = el('div', 'bz-sheet-head');
    head.appendChild(logoNode(business, 'xl'));

    var text = el('div', 'bz-sheet-headtext');
    text.appendChild(el('p', 'bz-sheet-eyebrow', business.categoryName || ''));
    var h = el('h2', 'bz-sheet-name', business.name);
    h.id = 'sheetName';
    text.appendChild(h);
    text.appendChild(metaNode(business));
    head.appendChild(text);
    wrap.appendChild(head);

    if (business.description) {
      // Line breaks survive via white-space: pre-line rather than by turning
      // newlines into <br>, so owner text never becomes markup.
      wrap.appendChild(el('p', 'bz-sheet-desc', business.description));
    }

    var links = business.links || [];
    if (links.length) {
      var grid = el('div', 'bz-links');
      links.forEach(function (link) {
        var node = linkNode(link);
        if (node) grid.appendChild(node);
      });
      if (grid.childNodes.length) wrap.appendChild(grid);
    }

    wrap.appendChild(reactionBar(business));
    return wrap;
  }

  // Tapping the side you already hold clears it, so one control both sets and
  // unsets. Counts come back from the server rather than being adjusted here,
  // so a second device never drifts out of step.
  function reactionBar(business) {
    var bar = el('div', 'bz-react');
    var mine = business.myReaction || 0;

    var up = reactionBtn(ICONS.thumbUp, business.likes, mine === 1);
    var down = reactionBtn(ICONS.thumbDown, business.dislikes, mine === -1);
    var busy = false;

    function send(value) {
      if (busy) return;
      busy = true;
      haptic('light');
      postJSON('/api/business/' + business.id + '/reaction',
               { value: mine === value ? 0 : value })
        .then(function (data) {
          mine = data.myReaction;
          business.myReaction = data.myReaction;
          business.likes = data.likes;
          business.dislikes = data.dislikes;
          paint(up, data.likes, mine === 1);
          paint(down, data.dislikes, mine === -1);
        })
        .catch(function (err) {
          showToast(err.code === 'no_init_data' || err.code === 'bad_signature'
            ? 'Iltimos, sahifani Telegram ichida oching'
            : 'Saqlab bo‘lmadi');
        })
        .then(function () { busy = false; });
    }

    up.addEventListener('click', function () { send(1); });
    down.addEventListener('click', function () { send(-1); });

    bar.appendChild(up);
    bar.appendChild(down);
    return bar;
  }

  function reactionBtn(icon, count, on) {
    var btn = el('button', 'bz-reactbtn');
    btn.type = 'button';
    btn.appendChild(iconSpan('bz-reactbtn-icon', icon));
    btn.appendChild(el('span', 'bz-reactbtn-n', String(count || 0)));
    if (on) btn.classList.add('is-on');
    return btn;
  }

  function paint(btn, count, on) {
    btn.querySelector('.bz-reactbtn-n').textContent = String(count || 0);
    btn.classList.toggle('is-on', on);
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
      node.appendChild(iconSpan('bz-link-tail', ICONS.arrow));
      node.addEventListener('click', function () { openExternal(link); });
    }
    return node;
  }

  function displayValue(link) {
    if (link.kind === 'phone') return link.value;
    try {
      var u = new URL(link.value);
      if (link.kind === 'website') return u.hostname.replace(/^www\./, '');
      var segs = u.pathname.split('/').filter(Boolean);
      return segs.length ? '@' + segs[0].replace(/^@/, '') : u.hostname;
    } catch (e) {
      return link.value;
    }
  }

  // Android opens the dialer. On iOS a tel: link inside the Mini App webview
  // has caused trouble before, so there the number is copied instead.
  function handlePhone(number) {
    if ((tg.platform || '').toLowerCase() === 'android') {
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
      return navigator.clipboard.writeText(text)
        .then(function () { return true; })
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
    if (!/^https?:\/\//i.test(link.value)) return;   // never pass on another scheme
    haptic('light');
    try {
      if (link.kind === 'telegram') tg.openTelegramLink(link.value);
      else tg.openLink(link.value, { try_instant_view: false });
    } catch (e) {
      window.open(link.value, '_blank', 'noopener');
    }
  }

  function openAdmin() {
    haptic('light');
    try { tg.openTelegramLink(ADMIN); }
    catch (e) { window.open(ADMIN, '_blank', 'noopener'); }
  }

  // Fire and forget: a failed tap log must never hold up the sheet.
  function countTap(businessId) {
    fetch(API + '/api/business/' + encodeURIComponent(businessId) + '/tap', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Init-Data': (tg && tg.initData) ? tg.initData : ''
      },
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
    scroll.scrollTop = 0;
    showSheet();
  }

  function showSheet() {
    var backdrop = $('sheetBackdrop');
    if (!backdrop.hidden) return;
    backdrop.hidden = false;
    requestAnimationFrame(function () {
      backdrop.classList.add('visible');
      $('sheet').classList.add('visible');
    });
    setBack(closeSheet);
  }

  function closeSheet() {
    var backdrop = $('sheetBackdrop');
    var sheet = $('sheet');
    if (backdrop.hidden) return;

    // A drag leaves an inline transform behind; clearing it lets the class
    // transition run the sheet out instead of it vanishing from where it sat.
    sheet.style.transition = '';
    sheet.style.transform = '';

    backdrop.classList.remove('visible');
    sheet.classList.remove('visible');
    setTimeout(function () {
      backdrop.hidden = true;
      $('sheetScroll').textContent = '';
    }, 260);
    setBack(currentBack());
  }

  // ============================================
  // SWIPE TO DISMISS
  // ============================================
  // A sheet that only closes with the system back button reads as a page.
  // Dragging starts from the grip, or from the body when it is already
  // scrolled to the top, so the gesture never fights the sheet's own scroll.

  var DISMISS_PX = 96;          // far enough to be deliberate
  var DISMISS_VELOCITY = 0.6;   // px per ms, so a quick flick also closes

  function initSheetDrag() {
    var sheet = $('sheet');
    var scroll = $('sheetScroll');
    var startY = 0, startT = 0, dy = 0;
    var armed = false, active = false, fromGrip = false, pointer = null;

    var SLOP = 6;   // below this it is a tap, not a drag

    // The gesture is tracked on the window rather than through pointer
    // capture. Capture retargets the click that follows an ordinary tap, so
    // nothing inside the sheet would be pressable; and once a capture has
    // been taken and released, the next pointerdown on a freshly opened sheet
    // arrives already cancelled. Window listeners survive both, and survive
    // the sheet sliding out from under the cursor.
    function bind() {
      window.addEventListener('pointermove', onMove, { passive: false });
      window.addEventListener('pointerup', onUp);
      window.addEventListener('pointercancel', onCancel);
      document.addEventListener('selectstart', noSelect);
    }

    function unbind() {
      window.removeEventListener('pointermove', onMove, { passive: false });
      window.removeEventListener('pointerup', onUp);
      window.removeEventListener('pointercancel', onCancel);
      document.removeEventListener('selectstart', noSelect);
    }

    // A drag across text selects it, and the next press over that selection
    // starts a native drag-and-drop — which the browser announces by
    // cancelling our gesture before it has moved. Suppressing the selection
    // is what keeps the second swipe working.
    function noSelect(e) { e.preventDefault(); }

    function clearSelection() {
      try {
        var sel = window.getSelection();
        if (sel && !sel.isCollapsed) sel.removeAllRanges();
      } catch (e) {}
    }

    function stop(close) {
      if (!armed) return;
      unbind();
      if (active) clearSelection();
      armed = false;
      active = false;
      pointer = null;
      sheet.classList.remove('is-dragging');
      sheet.style.transition = '';
      if (close) {
        closeSheet();
      } else {
        sheet.style.transform = '';
      }
      dy = 0;
    }

    function onMove(e) {
      if (!armed || e.pointerId !== pointer) return;

      dy = e.clientY - startY;

      // Pulling up is the scroll's job.
      if (dy <= 0) {
        if (active) sheet.style.transform = '';
        dy = 0;
        return;
      }
      // The body may have scrolled out from under a slow drag.
      if (!fromGrip && scroll.scrollTop > 0) {
        stop(false);
        return;
      }

      if (!active) {
        if (dy < SLOP) return;
        active = true;
        sheet.classList.add('is-dragging');
        sheet.style.transition = 'none';
      }

      if (e.cancelable) e.preventDefault();
      sheet.style.transform = 'translateY(' + dy + 'px)';
    }

    function onUp(e) {
      if (!armed || e.pointerId !== pointer) return;
      if (!active) { stop(false); return; }   // a tap; leave it alone
      var elapsed = Math.max(1, e.timeStamp - startT);
      var far = dy > DISMISS_PX;
      var flick = dy > 28 && (dy / elapsed) > DISMISS_VELOCITY;
      stop(far || flick);
    }

    // A platform can take a gesture back mid-drag. Honour where it got to
    // rather than snapping back, which reads as the swipe not working.
    function onCancel(e) {
      if (!armed || e.pointerId !== pointer) return;
      stop(active && dy > DISMISS_PX);
    }

    sheet.addEventListener('pointerdown', function (e) {
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      if (armed) stop(false);

      fromGrip = !!(e.target.closest && e.target.closest('.bz-sheet-grip'));
      // From the body, only when there is nothing left to scroll up into, so
      // the gesture never fights the sheet's own scrolling.
      if (!fromGrip && scroll.scrollTop > 0) return;

      armed = true;
      active = false;
      pointer = e.pointerId;
      startY = e.clientY;
      startT = e.timeStamp;
      dy = 0;
      bind();
    });
  }

  // ============================================
  // SEARCH
  // ============================================

  var searchTimer = null;

  function onSearchInput() {
    var value = $('bzSearch').value.trim();
    $('bzSearchClear').hidden = !value;

    clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      if (value === state.query) return;
      state.query = value;

      // Searching always looks across everything: a name you half remember is
      // no use if it only matches inside the category you happen to be in.
      if (state.mode === 'category') {
        state.mode = 'feed';
        state.categoryId = null;
            syncFilter();
        setBack(goHome);
      }
      loadFeed();
    }, 280);
  }

  // ============================================
  // INIT
  // ============================================

  function init() {
    setBack(goHome);

    $('bzSearch').addEventListener('input', onSearchInput);
    $('bzSearchClear').addEventListener('click', function () {
      $('bzSearch').value = '';
      $('bzSearchClear').hidden = true;
      if (state.query) { state.query = ''; loadFeed(); }
      $('bzSearch').focus();
    });

    // Passing openPicker directly would hand it the MouseEvent as its
    // onChoose callback, putting the filter into chooser mode.
    $('bzFilter').addEventListener('click', function () { openPicker(); });
    $('bzFilterClear').addEventListener('click', function () {
      haptic('light');
      backToFeed();
    });

    $('bzRetry').addEventListener('click', function () {
      state.mode === 'category' ? loadCategory() : loadFeed();
    });

    $('sheetBackdrop').addEventListener('click', function (e) {
      if (e.target === $('sheetBackdrop')) closeSheet();
    });
    $('sheet').addEventListener('click', function (e) { e.stopPropagation(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeSheet();
    });

    initSheetDrag();
    loadFeed();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
