// business.js — Biznes katalogi
//
// Designed for the person looking for a business, not the person who owns
// one. The directory is the landing; a category is one tap; a business opens
// as a centred card that leads with who it is and how to reach it. Owner
// concerns — listing, positions, prices — live behind one quiet entry at the
// end of each list and never in the way of reading.
//
// Every visible word lives in business.text.js, so the Uzbek can be revised
// without opening this file.
//
// Nothing owner-supplied reaches innerHTML. Names and descriptions go in as
// text nodes; links are typed (kind, value) pairs rendered as buttons we
// build, so a listing can never inject markup into a page carrying the
// visitor's Telegram session.

(function () {
  'use strict';

  // The page must survive the Telegram script failing to load (desktop
  // browser preview, blocked CDN): a no-op stand-in keeps every call safe.
  var tg = (window.Telegram && window.Telegram.WebApp) || {
    ready: function () {}, expand: function () {}, disableVerticalSwipes: function () {},
    initData: '', platform: '', BackButton: null, HapticFeedback: null,
    openLink: function (u) { window.open(u, '_blank', 'noopener'); },
    openTelegramLink: function (u) { window.open(u, '_blank', 'noopener'); }
  };
  tg.ready();
  try { tg.expand(); } catch (e) {}
  try { tg.disableVerticalSwipes(); } catch (e) {}

  // ============================================
  // TEXT
  // ============================================
  // business.text.js owns every word this page shows. t() takes a dotted path
  // into it and fills {placeholders}. A path that is missing renders as
  // itself rather than as "undefined", so a typo shows up on screen instead
  // of silently blanking a button.

  var TEXT = window.BUSINESS_TEXT || {};

  function t(path, vars) {
    var node = TEXT, parts = path.split('.');
    for (var i = 0; i < parts.length && node != null; i++) node = node[parts[i]];
    if (typeof node !== 'string') return path;
    if (!vars) return node;
    return node.replace(/\{(\w+)\}/g, function (whole, key) {
      return Object.prototype.hasOwnProperty.call(vars, key) ? vars[key] : whole;
    });
  }

  // Optional by design: a category the file says nothing about shows no line
  // at all rather than its own key.
  function categoryAbout(slug) {
    var about = (TEXT.categoryAbout || {})[slug];
    return typeof about === 'string' ? about : '';
  }

  // Error codes come from the server; the file maps each to a sentence, and
  // anything unmapped falls back to the general apology.
  function errorText(group, code) {
    var text = (TEXT[group] || {})[code];
    return typeof text === 'string' ? text : t('common.error');
  }

  var API = (window.API_CONFIG ? window.API_CONFIG.BASE_URL : 'https://vegukin-api.duckdns.org/')
              .replace(/\/+$/, '');
  var TIMEOUT = 30000;
  var ADMIN = 'https://t.me/otabeksattarov';

  // ============================================
  // CATEGORY ORDER
  // ============================================
  // A fixed editorial ranking keyed by slug: what a family needs weekly, then
  // what the paperwork of living here demands, then the once-or-twice-a-year
  // things, then the discretionary. Server order stays alphabetical; this is
  // a display decision only.
  var CATEGORY_RANK = {
    'halal-market': 1, 'pishiriqlar': 2, 'tarjima': 3, 'pochta': 4,
    'aviakassa': 5, 'sim-telefon': 6, 'sugurta': 7, 'consulting': 8,
    'repetitor': 9, 'kosmetika': 10
  };

  function rankOf(category) { return CATEGORY_RANK[category.slug] || 99; }

  // Empty categories sink as a group; inside each group the editorial order
  // holds. Sorting by count itself would reshuffle the grid on every approval.
  function byCategoryOrder(a, b) {
    var aEmpty = !a.count, bEmpty = !b.count;
    if (aEmpty !== bEmpty) return aEmpty ? 1 : -1;
    var ra = rankOf(a), rb = rankOf(b);
    if (ra !== rb) return ra - rb;
    return (a.name || '').localeCompare(b.name || '', 'uz');
  }

  var state = {
    mode: 'categories',     // 'categories' | 'category' | 'search'
    categoryId: null,
    categoryName: '',
    categoryIcon: '',
    query: '',
    categories: [],
    pricing: null,
    // Where a search was started from, so clearing it lands the reader back
    // in the category they were reading rather than on the front page.
    returnTo: null
  };

  // ============================================
  // SMALL HELPERS
  // ============================================

  function $(id) { return document.getElementById(id); }

  function haptic(kind) {
    try { tg.HapticFeedback.impactOccurred(kind || 'light'); } catch (e) {}
  }
  function buzz(kind) {
    try { tg.HapticFeedback.notificationOccurred(kind); } catch (e) {}
  }

  function authHeaders(json) {
    var h = { 'X-Init-Data': tg.initData || '' };
    if (json) h['Content-Type'] = 'application/json';
    return h;
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
      headers: authHeaders(true),
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

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function button(className, text) {
    var b = el('button', className, text);
    b.type = 'button';
    return b;
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
  // the name so it never changes between loads.
  function hueOf(name) {
    var h = 0;
    for (var i = 0; i < (name || '').length; i++) {
      h = (h * 31 + name.charCodeAt(i)) % 360;
    }
    return h;
  }

  function glyphNode(icon, className) {
    var box = el('span', className || 'bz-glyph');
    box.textContent = icon || '•';
    box.setAttribute('aria-hidden', 'true');
    return box;
  }

  // The digits are grouped here; the unit and its placement are the text
  // file's business.
  function formatKRW(n) {
    return t('common.currency', { amount: Number(n || 0).toLocaleString('en-US') });
  }

  function logoSrc(business, version) {
    return API + '/' + String(business.logo).replace(/^\/+/, '') +
           (version ? '?v=' + version : '');
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
    }, 2800);
  }

  // ============================================
  // ICONS
  // ============================================
  // One stroke weight throughout. Category marks come from the database; the
  // rest of the page is set in type and line icons.

  var ICONS = {
    heart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 20.3 4.3 12.6a4.9 4.9 0 0 1 6.9-6.9l.8.8.8-.8a4.9 4.9 0 1 1 6.9 6.9Z"/></svg>',
    arrow: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6"/></svg>',
    chevron: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 6 6 6-6 6"/></svg>',
    caret: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>',
    info: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/></svg>',
    pin: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0c0 5.4-6.5 11-6.5 11Z"/><circle cx="12" cy="10" r="2.4"/></svg>',
    clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
    tag: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12.5V4h8.5l9 9-8.5 8.5Z"/><circle cx="7.5" cy="8.5" r="1.2" fill="currentColor" stroke="none"/></svg>',
    globe: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18"/></svg>',
    phone: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.13.96.36 1.9.7 2.8a2 2 0 0 1-.45 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.25a2 2 0 0 1 2.1-.45c.9.34 1.84.57 2.8.7A2 2 0 0 1 22 16.9z"/></svg>',
    telegram: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M9.78 18.65l.28-4.23 7.68-6.92c.34-.31-.07-.46-.52-.19L7.74 13.3 3.64 12c-.88-.25-.89-.86.2-1.3l15.97-6.16c.73-.33 1.43.18 1.15 1.3l-2.72 12.81c-.19.91-.74 1.13-1.5.71L12.6 16.3l-2.01 1.95c-.23.23-.42.42-.81.42z"/></svg>',
    instagram: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5.2"/><circle cx="12" cy="12" r="4.1"/><circle cx="17.3" cy="6.7" r="1.2" fill="currentColor" stroke="none"/></svg>',
    tiktok: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.6 2h-3.2v13.2a2.9 2.9 0 1 1-2.4-2.85V9.1a6.1 6.1 0 1 0 5.6 6.08V8.9a7.3 7.3 0 0 0 4.3 1.38V7.06A4.4 4.4 0 0 1 16.6 2z"/></svg>',
    appstore: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.4 12.7c0-2.2 1.8-3.3 1.9-3.3-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.7.8-3.3.8-.7 0-1.7-.8-2.8-.8-1.5 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.4 1.1 8.5.7 1 1.5 2.2 2.6 2.1 1.1 0 1.5-.7 2.8-.7s1.6.7 2.8.7c1.2 0 1.9-1 2.6-2.1.8-1.2 1.2-2.3 1.2-2.4-.1 0-2.2-.9-2.2-3.2zM14.2 5.9c.6-.7 1-1.7.9-2.7-.9 0-2 .6-2.6 1.3-.6.6-1.1 1.6-.9 2.6 1 .1 2-.5 2.6-1.2z"/></svg>',
    playstore: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3.6 2.4a1 1 0 0 0-.4.8v17.6a1 1 0 0 0 .4.8l9.3-9.6zM14.3 10.3 5.6 1.7l10.9 6.2zM14.3 13.7l2.2 2.4-10.9 6.2zM17.9 9l3 1.7a1.3 1.3 0 0 1 0 2.6l-3 1.7-2.5-3z"/></svg>',
    kakao: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 3C6.9 3 2.8 6.3 2.8 10.3c0 2.6 1.7 4.9 4.3 6.2l-1.1 4c-.1.3.3.6.6.4l4.7-3.1c.2 0 .5.1.7.1 5.1 0 9.2-3.3 9.2-7.6S17.1 3 12 3z"/></svg>',
    thumbUp: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7 22V10l5-8a2.4 2.4 0 0 1 2.3 3.1L13.4 9H19a2.2 2.2 0 0 1 2.1 2.8l-2 8A2.2 2.2 0 0 1 17 22Z"/><path d="M7 10H4.5A1.5 1.5 0 0 0 3 11.5v9A1.5 1.5 0 0 0 4.5 22H7"/></svg>',
    thumbDown: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 2v12l-5 8a2.4 2.4 0 0 1-2.3-3.1L10.6 15H5a2.2 2.2 0 0 1-2.1-2.8l2-8A2.2 2.2 0 0 1 7 2Z"/><path d="M17 14h2.5A1.5 1.5 0 0 0 21 12.5v-9A1.5 1.5 0 0 0 19.5 2H17"/></svg>',
    check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m4 12.5 5 5L20 6.5"/></svg>',
    external: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 5h6v6M19 5l-8 8M18 14v4.5A1.5 1.5 0 0 1 16.5 20h-11A1.5 1.5 0 0 1 4 18.5v-11A1.5 1.5 0 0 1 5.5 6H10"/></svg>',
    expand: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/></svg>',
    copy: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="12" height="12" rx="2.4"/><path d="M5.5 15H4.6A1.6 1.6 0 0 1 3 13.4V4.6A1.6 1.6 0 0 1 4.6 3h8.8A1.6 1.6 0 0 1 15 4.6v.9"/></svg>',
    flag: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 21V4.5M5 4.5c4-2.4 8 2.4 14 0v10c-6 2.4-10-2.4-14 0"/></svg>',
    store: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 10.5V20h16v-9.5M3 8l1.5-4h15L21 8a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0Z"/><path d="M10 20v-5h4v5"/></svg>'
  };

  // Icons only. Each channel's name is text, so it lives in the text file
  // under "channels" and is read with t('channels.' + kind).
  var LINK_ICON = {
    phone:     ICONS.phone,
    telegram:  ICONS.telegram,
    kakao:     ICONS.kakao,
    website:   ICONS.globe,
    instagram: ICONS.instagram,
    tiktok:    ICONS.tiktok,
    appstore:  ICONS.appstore,
    playstore: ICONS.playstore
  };

  // ============================================
  // BACK BUTTON
  // ============================================
  // One handler at a time, swapped as depth changes: viewer, dialog, then
  // whatever the current view's "up" is.

  var backHandler = null;

  function setBack(fn) {
    if (!tg.BackButton) return;
    if (backHandler) { try { tg.BackButton.offClick(backHandler); } catch (e) {} }
    backHandler = fn;
    if (fn) { tg.BackButton.onClick(fn); tg.BackButton.show(); }
    else { tg.BackButton.hide(); }
  }

  function goHome() { window.location.href = '../../index.html'; }

  function currentBack() {
    if (state.mode === 'search') return leaveSearch;
    if (state.mode === 'category') return backToCategories;
    return goHome;
  }

  // ============================================
  // SHARED PIECES
  // ============================================

  function logoNode(business) {
    var box = el('div', 'bz-logo');
    box.setAttribute('aria-hidden', 'true');
    if (business.logo) {
      var img = document.createElement('img');
      img.src = logoSrc(business);
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

  // A held position is marked, not shouted: a small numbered disc on the
  // logo's corner. Gold, silver and bronze still say the order, but the row
  // stays the same object as every other row — a reader is choosing a
  // business, not judging a podium.
  function rankBadge(rank) {
    var b = el('span', 'bz-rank bz-rank--' + rank, String(rank));
    b.setAttribute('aria-label', t('category.rankLabel', { n: rank }));
    return b;
  }

  // ============================================
  // REACTIONS
  // ============================================
  // The server answers a reaction with the new totals, and those totals are
  // true of every place the business appears — the card in front of the
  // person and the row in the list behind it. Holding them here is what stops
  // the two from disagreeing until the page is reloaded.
  //
  // Superseded naturally: any later list fetch returns the server's own
  // numbers, which are at least as fresh as these.

  var reactions = {};        // business id -> { likes, dislikes, myReaction }

  function applyReaction(business) {
    var known = business && reactions[business.id];
    if (known) {
      business.likes = known.likes;
      business.dislikes = known.dislikes;
      business.myReaction = known.myReaction;
    }
    return business;
  }

  function rememberReaction(id, data) {
    reactions[id] = {
      likes: data.likes, dislikes: data.dislikes, myReaction: data.myReaction
    };
    repaintRows(id);
  }

  // Every row for this business that is on screen right now. The meta line is
  // rebuilt rather than edited: a business going from zero likes to one has no
  // line to edit yet.
  function repaintRows(id) {
    var rows = $('bzBody').querySelectorAll('.bz-row');
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i];
      if (!row.bzBusiness || String(row.bzBusiness.id) !== String(id)) continue;
      applyReaction(row.bzBusiness);
      var body = row.querySelector('.bz-row-body');
      var old = body.querySelector('.bz-meta');
      var next = metaLine(row.bzBusiness, row.bzCategoryName);
      if (old && next) body.replaceChild(next, old);
      else if (old) body.removeChild(old);
      else if (next) body.appendChild(next);
    }
  }

  function businessRow(business, opts) {
    opts = opts || {};
    applyReaction(business);
    var row = button('bz-row');
    row.bzBusiness = business;
    row.bzCategoryName = opts.categoryName;
    row.setAttribute('aria-label', business.name +
      (opts.rank ? ', ' + t('category.rankLabel', { n: opts.rank }) : ''));

    var lead = el('span', 'bz-row-lead');
    lead.appendChild(logoNode(business));
    if (opts.rank) lead.appendChild(rankBadge(opts.rank));
    row.appendChild(lead);

    var body = el('span', 'bz-row-body');
    body.appendChild(el('span', 'bz-row-name', business.name));
    if (business.description) {
      body.appendChild(el('span', 'bz-row-desc', firstLine(business.description)));
    }
    var meta = metaLine(business, opts.categoryName);
    if (meta) body.appendChild(meta);
    row.appendChild(body);

    row.appendChild(iconSpan('bz-row-chev', ICONS.chevron));
    row.addEventListener('click', function () { openBusiness(business.id, business); });
    return row;
  }

  // A row gets the first meaningful sentence of the description, with any
  // "Label: value" lines collapsed to their values so the preview reads as
  // prose rather than a form.
  function firstLine(text) {
    var parsed = parseDescription(text);
    var lead = parsed.text || parsed.facts.map(function (f) { return f.value; }).join(' · ');
    // A raw address in a two-line preview is noise: the reader cannot tap it
    // here, and it crowds out the words that would help them choose.
    return lead.replace(URL_RE, '').replace(/\s+/g, ' ').trim();
  }

  // Likes are the one public signal a visitor can use; zeros are noise, so
  // the line only appears once there is something to say.
  function metaLine(business, categoryName) {
    var parts = [];
    if (categoryName) parts.push(el('span', 'bz-meta-cat', categoryName));
    if (business.likes > 0) {
      var likes = el('span', 'bz-meta-likes');
      likes.appendChild(iconSpan('bz-meta-icon', ICONS.heart));
      likes.appendChild(document.createTextNode(String(business.likes)));
      likes.setAttribute('aria-label', t('business.likes', { n: business.likes }));
      parts.push(likes);
    }
    if (!parts.length) return null;
    var meta = el('span', 'bz-meta');
    parts.forEach(function (p) { meta.appendChild(p); });
    return meta;
  }

  function sectionHeader(title, opts) {
    opts = opts || {};
    var head = el('div', 'bz-sechead');
    if (opts.icon) head.appendChild(glyphNode(opts.icon, 'bz-glyph bz-glyph--sec'));

    var text = el('div', 'bz-sectext');
    var h = el('h3', 'bz-sectitle', title);
    text.appendChild(h);
    if (opts.count != null) text.appendChild(el('span', 'bz-seccount', opts.count + ' ta'));
    head.appendChild(text);

    if (opts.hint) {
      var info = button('bz-secinfo');
      info.setAttribute('aria-label', t('category.infoLabel'));
      info.appendChild(iconSpan(null, ICONS.info));
      info.addEventListener('click', function (e) {
        e.stopPropagation();
        showToast(opts.hint);
      });
      head.appendChild(info);
    }

    if (opts.onMore) {
      var more = button('bz-secmore');
      more.appendChild(el('span', null, t('search.seeAll')));
      more.appendChild(iconSpan('bz-secmore-icon', ICONS.arrow));
      more.addEventListener('click', function (e) { e.stopPropagation(); opts.onMore(); });
      head.appendChild(more);
    }
    return head;
  }

  function emptyBlock(title, body, icon) {
    var box = el('div', 'bz-blank');
    box.setAttribute('role', 'status');
    box.appendChild(glyphNode(icon || '◆', 'bz-glyph bz-blank-glyph'));
    box.appendChild(el('h3', 'bz-blank-title', title));
    if (body) box.appendChild(el('p', 'bz-blank-body', body));
    return box;
  }

  // The one owner-facing element in the public views. Quiet, last, and
  // carrying only what an owner needs to decide to tap: whether their trade
  // is listed here and, inside a category, whether a top position is open.
  function ownerCard(opts) {
    opts = opts || {};
    var card = button('bz-owner');
    card.appendChild(iconSpan('bz-owner-icon', ICONS.store));

    var text = el('span', 'bz-owner-text');
    text.appendChild(el('span', 'bz-owner-title', t('owner.cardTitle')));
    var sub;
    if (opts.emptyCategory) {
      sub = t('owner.cardBodyEmpty');
    } else if (opts.openSlots) {
      sub = t('owner.cardBodySlots', { n: opts.openSlots });
    } else {
      sub = t('owner.cardBody');
    }
    text.appendChild(el('span', 'bz-owner-sub', sub));
    card.appendChild(text);
    card.appendChild(iconSpan('bz-owner-arrow', ICONS.chevron));

    card.addEventListener('click', function () {
      haptic('light');
      openOwnerSheet(opts.openSlots ? (state.pricing && state.pricing.podiumSize || 3) - opts.openSlots + 1 : null);
    });
    return card;
  }

  // ============================================
  // VIEW STATE
  // ============================================

  function setView(which) {
    $('bzError').hidden = which !== 'error';
    if (which === 'loading') renderSkeleton();
    else if (which !== 'ready') $('bzBody').textContent = '';
  }

  // Shaped like the answer that is coming, so nothing jumps when it lands.
  function renderSkeleton() {
    var host = $('bzBody');
    host.textContent = '';
    host.setAttribute('aria-busy', 'true');

    if (state.mode === 'categories') {
      var grid = el('div', 'bz-grid');
      grid.setAttribute('aria-hidden', 'true');
      for (var c = 0; c < 6; c++) {
        var tile = el('div', 'bz-tile bz-tile--skel');
        tile.appendChild(el('span', 'bz-skel bz-skel--glyph'));
        tile.appendChild(el('span', 'bz-skel bz-skel--name'));
        tile.appendChild(el('span', 'bz-skel bz-skel--desc'));
        grid.appendChild(tile);
      }
      host.appendChild(grid);
      return;
    }

    var groups = state.mode === 'category' ? 1 : 2;
    var rows = state.mode === 'category' ? 5 : 3;
    for (var g = 0; g < groups; g++) {
      var section = el('div', 'bz-section');
      section.setAttribute('aria-hidden', 'true');
      if (state.mode === 'search') {
        var head = el('div', 'bz-sechead');
        head.appendChild(el('span', 'bz-skel bz-skel--title'));
        section.appendChild(head);
      }
      for (var r = 0; r < rows; r++) {
        var row = el('div', 'bz-row bz-row--skel');
        row.appendChild(el('span', 'bz-skel bz-skel--logo'));
        var lines = el('span', 'bz-skel-lines');
        lines.appendChild(el('span', 'bz-skel bz-skel--name'));
        lines.appendChild(el('span', 'bz-skel bz-skel--desc'));
        row.appendChild(lines);
        section.appendChild(row);
      }
      host.appendChild(section);
    }
  }

  function ready() {
    setView('ready');
    var host = $('bzBody');
    host.textContent = '';
    host.removeAttribute('aria-busy');
    return host;
  }

  // ============================================
  // DIRECTORY — the landing
  // ============================================
  // Every business type on one screen, as tiles. A reader arriving cold gets
  // the shape of the whole catalogue before choosing; a reader who knows
  // what they want gets the search field above it.

  function loadCategories(opts) {
    if (!(opts && opts.quiet)) setView('loading');
    getJSON('/api/business/categories')
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        state.categories = (data.categories || []).slice().sort(byCategoryOrder);
        syncChrome();
        renderCategories();
      })
      .catch(function () { if (!(opts && opts.quiet)) setView('error'); });
  }

  function renderCategories() {
    var total = totalCount();
    $('bzCount').textContent = total ? t('header.countAll', { n: total }) : '';
    var host = ready();

    if (!state.categories.length) {
      host.appendChild(emptyBlock(t('directory.emptyTitle'), t('directory.emptyBody')));
      host.appendChild(ownerCard());
      return;
    }

    var grid = el('div', 'bz-grid');
    state.categories.forEach(function (cat) { grid.appendChild(categoryTile(cat)); });
    host.appendChild(grid);
    host.appendChild(ownerCard());
  }

  function categoryTile(cat) {
    var tile = button('bz-tile' + (cat.count ? '' : ' is-quiet'));
    tile.appendChild(glyphNode(cat.icon, 'bz-glyph bz-glyph--tile'));
    tile.appendChild(el('span', 'bz-tile-name', cat.name));
    var about = categoryAbout(cat.slug);
    if (about) tile.appendChild(el('span', 'bz-tile-about', about));
    tile.appendChild(el('span', 'bz-tile-n', cat.count
      ? t('directory.tileCount', { n: cat.count })
      : t('directory.tileEmpty')));
    tile.addEventListener('click', function () { openCategory(cat); });
    return tile;
  }

  function totalCount() {
    return state.categories.reduce(function (n, c) { return n + (c.count || 0); }, 0);
  }

  // ============================================
  // CATEGORY
  // ============================================

  function openCategory(cat) {
    haptic('light');
    state.mode = 'category';
    state.categoryId = cat.id;
    state.categoryName = cat.name;
    state.categoryIcon = cat.icon || '';
    state.query = '';
    state.returnTo = null;
    $('bzSearch').value = '';
    $('bzSearchClear').hidden = true;
    syncChrome();
    setBack(backToCategories);
    $('bzScroll').scrollTop = 0;
    loadCategory();
  }

  function backToCategories() {
    state.mode = 'categories';
    state.categoryId = null;
    state.categoryName = '';
    state.categoryIcon = '';
    state.pricing = null;
    state.query = '';
    state.returnTo = null;
    $('bzSearch').value = '';
    $('bzSearchClear').hidden = true;
    syncChrome();
    setBack(goHome);
    $('bzScroll').scrollTop = 0;
    loadCategories();
  }

  function loadCategory(opts) {
    if (!(opts && opts.quiet)) setView('loading');
    getJSON('/api/business/list?category_id=' + encodeURIComponent(state.categoryId))
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        state.pricing = data.pricing || null;
        renderCategory(data);
      })
      .catch(function () { if (!(opts && opts.quiet)) setView('error'); });
  }

  function renderCategory(data) {
    var podium = data.podium || [];
    var rest = data.businesses || [];
    var pricing = data.pricing || {};
    var contested = !!pricing.showBidding;

    // Short form here: inside a category the title bar also carries the
    // switcher, and "N ta biznes" pushed the category's own name into an
    // ellipsis on a 390px screen.
    $('bzCount').textContent = data.total ? t('header.countInCategory', { n: data.total }) : '';
    var host = ready();

    if (!podium.length && !rest.length) {
      host.appendChild(emptyBlock(t('category.emptyTitle'), t('category.emptyBody'),
                                  state.categoryIcon));
      host.appendChild(ownerCard({ emptyCategory: true }));
      return;
    }

    // Held positions lead, as bought. They are named honestly — a small
    // label and a one-line explanation behind the info mark — and drawn as
    // ordinary rows with a rank badge, so the list still reads as a list.
    if (contested && podium.length) {
      var top = el('section', 'bz-section');
      top.appendChild(sectionHeader(t('category.podiumTitle'),
                                    { hint: t('category.podiumHint') }));
      podium.forEach(function (business, i) {
        top.appendChild(businessRow(business, { rank: i + 1 }));
      });
      host.appendChild(top);
    } else {
      // No contest here: the server's podium is just the head of the list.
      rest = podium.concat(rest);
    }

    if (rest.length) {
      var all = el('section', 'bz-section');
      if (contested && podium.length) all.appendChild(sectionHeader(t('category.restTitle')));
      rest.forEach(function (business) { all.appendChild(businessRow(business)); });
      host.appendChild(all);
    }

    var openSlots = contested ? Math.max(0, (pricing.podiumSize || 3) - podium.length) : 0;
    host.appendChild(ownerCard({ openSlots: openSlots }));
  }

  // ============================================
  // SEARCH
  // ============================================
  // Always global. Results are grouped by category, because knowing a match
  // is a bakery rather than an insurance broker is most of what makes it
  // useful. Clearing the search returns to wherever it was started.

  function startSearch(value) {
    if (state.mode !== 'search') {
      state.returnTo = state.mode === 'category'
        ? { id: state.categoryId, name: state.categoryName, icon: state.categoryIcon }
        : null;
      state.mode = 'search';
    }
    state.query = value;
    syncChrome();
    setBack(leaveSearch);
    loadSearch();
  }

  function leaveSearch() {
    var back = state.returnTo;
    $('bzSearch').value = '';
    $('bzSearchClear').hidden = true;
    state.query = '';
    if (back) openCategory(back);
    else backToCategories();
  }

  function loadSearch(opts) {
    if (!(opts && opts.quiet)) setView('loading');
    var q = state.query;
    getJSON('/api/business/feed?q=' + encodeURIComponent(q))
      .then(function (data) {
        if (q !== state.query) return;          // a newer keystroke won
        if (!data.success) throw new Error('bad_response');
        if (data.categories) {
          state.categories = data.categories.slice().sort(byCategoryOrder);
        }
        renderResults(data);
      })
      .catch(function () {
        if (q === state.query && !(opts && opts.quiet)) setView('error');
      });
  }

  function renderResults(data) {
    var groups = (data.groups || []).slice().sort(function (a, b) {
      return byCategoryOrder(
        { slug: a.category.slug, name: a.category.name, count: a.total },
        { slug: b.category.slug, name: b.category.name, count: b.total });
    });

    $('bzCount').textContent = data.total ? t('header.countFound', { n: data.total }) : '';
    var host = ready();

    if (!groups.length) {
      host.appendChild(emptyBlock(t('search.emptyTitle'),
                                  t('search.emptyBody', { query: state.query })));
      return;
    }

    groups.forEach(function (group) {
      var section = el('section', 'bz-section');
      var cat = group.category;
      var all = (group.podium || []).concat(group.businesses || []);
      var podiumLen = (group.podium || []).length;

      section.appendChild(sectionHeader(cat.name, {
        icon: cat.icon, count: group.total,
        onMore: function () { openCategory(cat); }
      }));
      all.forEach(function (business, i) {
        section.appendChild(businessRow(business, { rank: i < podiumLen ? i + 1 : null }));
      });
      host.appendChild(section);
    });
  }

  var searchTimer = null;

  function onSearchInput() {
    var value = $('bzSearch').value.trim();
    $('bzSearchClear').hidden = !value;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      if (value === state.query) return;
      if (!value) { leaveSearch(); return; }
      startSearch(value);
    }, 280);
  }

  // ============================================
  // CHROME
  // ============================================
  // Title, back affordance and count, kept in step with the view. Inside a
  // category the title is itself the switcher: tapping it opens the full
  // list of categories, which is one control doing the job the old wrapping
  // rail did in three rows of chips.

  function syncChrome() {
    var title = $('bzTitle');
    var back = $('bzBack');
    title.textContent = '';
    title.classList.remove('bz-title--switch');
    back.hidden = state.mode === 'categories';

    if (state.mode === 'category') {
      var sw = button('bz-switch');
      sw.setAttribute('aria-haspopup', 'dialog');
      sw.setAttribute('aria-label', t('header.switchLabel', { name: state.categoryName }));
      sw.appendChild(glyphNode(state.categoryIcon, 'bz-glyph bz-glyph--title'));
      sw.appendChild(el('span', 'bz-switch-name', state.categoryName));
      sw.appendChild(iconSpan('bz-switch-caret', ICONS.caret));
      sw.addEventListener('click', function () { openPicker(); });
      title.appendChild(sw);
      title.classList.add('bz-title--switch');
    } else if (state.mode === 'search') {
      title.textContent = t('header.searchTitle');
    } else {
      title.textContent = t('header.pageTitle');
    }
  }

  // ============================================
  // DIALOG
  // ============================================
  // One overlay, two shapes. A business opens as a centred card: it is the
  // object of the page and gets read as one thing — mark, name, the ways to
  // reach it — rather than as a strip peeking up from the bottom. Tasks
  // (forms, lists, prices) open as a bottom sheet, which is where a keyboard
  // expects them. Wide screens centre both.

  var lastFocus = null;

  function mountSheet(content, opts) {
    opts = opts || {};
    var dialog = $('sheet');
    var scroll = $('sheetScroll');

    scroll.textContent = '';
    scroll.appendChild(content);
    dialog.classList.toggle('bz-dialog--card', opts.kind === 'card');
    dialog.classList.toggle('bz-dialog--sheet', opts.kind !== 'card');

    // The dialog is named by whatever heading its content leads with.
    var heading = content.querySelector('h2');
    if (heading) heading.id = 'sheetTitle';

    // Cleared for every mount, then restored from the content itself, so a
    // business's colour can never be left sitting behind a form.
    var tinted = content.querySelector && content.querySelector('[data-tint]');
    tintSheet(tinted ? tinted.dataset.tint : null);

    scroll.scrollTop = 0;
    showSheet();
  }

  function showSheet() {
    var backdrop = $('sheetBackdrop');
    if (!backdrop.hidden) return;
    lastFocus = document.activeElement;
    backdrop.hidden = false;
    requestAnimationFrame(function () {
      backdrop.classList.add('visible');
      $('sheet').classList.add('visible');
    });
    setBack(closeSheet);
    // Keyboard and screen-reader users land inside the dialog, on its close
    // control, once it has finished arriving.
    setTimeout(function () { try { $('sheetClose').focus({ preventScroll: true }); } catch (e) {} }, 260);
  }

  function closeSheet() {
    var backdrop = $('sheetBackdrop');
    var sheet = $('sheet');
    if (backdrop.hidden) return;

    sheet.style.transition = '';
    sheet.style.transform = '';
    backdrop.classList.remove('visible');
    sheet.classList.remove('visible');
    setTimeout(function () {
      backdrop.hidden = true;
      $('sheetScroll').textContent = '';
      tintSheet(null);
    }, 260);
    setBack(currentBack());
    if (lastFocus && lastFocus.focus) { try { lastFocus.focus({ preventScroll: true }); } catch (e) {} }
    lastFocus = null;
    refreshAfterDialog();
  }

  function tintSheet(rgb) {
    var sheet = $('sheet');
    if (!sheet) return;
    if (rgb) {
      sheet.style.setProperty('--tint-rgb', rgb);
      sheet.classList.add('has-tint');
    } else {
      sheet.classList.remove('has-tint');
      sheet.style.removeProperty('--tint-rgb');
    }
  }

  // Swipe down to dismiss. From the grip always; from the body only when it
  // is scrolled to the top, so the gesture never fights the dialog's own
  // scroll. Tracked on the window rather than through pointer capture, which
  // would retarget the click that follows an ordinary tap.
  var DISMISS_PX = 96;
  var DISMISS_VELOCITY = 0.6;

  function initSheetDrag() {
    var sheet = $('sheet');
    var scroll = $('sheetScroll');
    var startY = 0, startT = 0, dy = 0;
    var armed = false, active = false, fromGrip = false, pointer = null;
    var SLOP = 6;

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
      armed = false; active = false; pointer = null;
      sheet.classList.remove('is-dragging');
      sheet.style.transition = '';
      if (close) closeSheet();
      else sheet.style.transform = '';
      dy = 0;
    }

    function onMove(e) {
      if (!armed || e.pointerId !== pointer) return;
      dy = e.clientY - startY;
      if (dy <= 0) {
        if (active) sheet.style.transform = '';
        dy = 0;
        return;
      }
      if (!fromGrip && scroll.scrollTop > 0) { stop(false); return; }
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
      if (!active) { stop(false); return; }
      var elapsed = Math.max(1, e.timeStamp - startT);
      var far = dy > DISMISS_PX;
      var flick = dy > 28 && (dy / elapsed) > DISMISS_VELOCITY;
      stop(far || flick);
    }

    function onCancel(e) {
      if (!armed || e.pointerId !== pointer) return;
      stop(active && dy > DISMISS_PX);
    }

    sheet.addEventListener('pointerdown', function (e) {
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      if (armed) stop(false);
      // Text fields own their own drag (selection, cursor placement).
      if (e.target.closest && e.target.closest('input, textarea, select')) return;
      fromGrip = !!(e.target.closest && e.target.closest('.bz-dialog-grip'));
      if (!fromGrip && scroll.scrollTop > 0) return;
      armed = true; active = false;
      pointer = e.pointerId;
      startY = e.clientY;
      startT = e.timeStamp;
      dy = 0;
      bind();
    });
  }

  // ============================================
  // BUSINESS CARD
  // ============================================
  // The core screen. Opens instantly on what the list already knows (mark,
  // name, first line) and fills in the rest when the detail arrives, so the
  // card never opens onto a spinner.

  function openBusiness(businessId, seed) {
    haptic('light');
    var wrap = el('div', 'bz-detail');
    var fill = el('div', 'bz-detail-fill');

    if (seed) {
      wrap.appendChild(identityBlock({
        name: seed.name, logo: seed.logo, likes: seed.likes,
        categoryName: seed.categoryName || state.categoryName
      }));
    }
    fill.appendChild(detailSkeleton(!seed));
    wrap.appendChild(fill);
    mountSheet(wrap, { kind: 'card' });

    getJSON('/api/business/' + encodeURIComponent(businessId))
      .then(function (data) {
        if (!data.success) throw new Error('bad_response');
        if (!$('sheetScroll').contains(wrap)) return;   // closed meanwhile
        var full = detailBody(applyReaction(data.business));
        $('sheetScroll').textContent = '';
        $('sheetScroll').appendChild(full);
        var heading = full.querySelector('h2');
        if (heading) heading.id = 'sheetTitle';
        settleDescription(full);
        countTap(businessId);
      })
      .catch(function () {
        if (!$('sheetScroll').contains(wrap)) return;
        fill.textContent = '';
        var err = el('div', 'bz-detail-error');
        err.appendChild(el('p', 'bz-state-hint', t('business.loadFailed')));
        var retry = button('bz-btn', t('common.retry'));
        retry.addEventListener('click', function () { openBusiness(businessId, seed); });
        err.appendChild(retry);
        fill.appendChild(err);
      });
  }

  function detailSkeleton(withIdentity) {
    var box = el('div', 'bz-detail-skel');
    box.setAttribute('aria-hidden', 'true');
    if (withIdentity) {
      box.appendChild(el('span', 'bz-skel bz-skel--mark'));
      box.appendChild(el('span', 'bz-skel bz-skel--eyebrow'));
      box.appendChild(el('span', 'bz-skel bz-skel--lead'));
    }
    var cta = el('div', 'bz-cta');
    cta.appendChild(el('span', 'bz-skel bz-skel--cta'));
    cta.appendChild(el('span', 'bz-skel bz-skel--cta'));
    box.appendChild(cta);
    box.appendChild(el('span', 'bz-skel bz-skel--line'));
    box.appendChild(el('span', 'bz-skel bz-skel--line'));
    box.appendChild(el('span', 'bz-skel bz-skel--line is-short'));
    return box;
  }

  function detailBody(business) {
    var wrap = el('div', 'bz-detail');
    wrap.appendChild(identityBlock(business));

    // Reaching the business comes first: most people open a listing for the
    // number. Then where and when, then the owner's own words.
    var links = (business.links || []).filter(function (l) {
      return LINK_ICON[l.kind] && l.value;
    }).sort(function (a, b) {
      return (CONTACT_RANK[a.kind] || 99) - (CONTACT_RANK[b.kind] || 99);
    });

    var parsed = parseDescription(business.description || '');
    // A number stated as an action button and again as a fact row is the same
    // number twice. The buttons keep it; the list drops it.
    var facts = parsed.facts.filter(function (f) { return !coveredByLink(f, links); });

    wrap.appendChild(ctaBlock(links));

    // Address and hours before the social handles: they are what decides
    // whether someone can use this business today. A block labelled "key
    // information" sitting under one labelled "other links" was the label
    // and the layout saying opposite things.
    if (facts.length) wrap.appendChild(factsBlock(facts));
    if (parsed.text) wrap.appendChild(aboutBlock(parsed.text));

    var secondary = links.slice(PRIMARY_SLOTS);
    if (secondary.length) wrap.appendChild(linksBlock(secondary));

    if (!links.length && !facts.length && !parsed.text) {
      wrap.appendChild(el('p', 'bz-detail-none', t('business.noInfo')));
    }

    var foot = el('div', 'bz-detail-foot');
    foot.appendChild(reactionBar(business));
    foot.appendChild(reportLink());
    wrap.appendChild(foot);
    return wrap;
  }

  // True when a link button already carries this fact, so printing it again
  // as a row would just be the same value twice on one screen.
  function coveredByLink(fact, links) {
    if (fact.kind !== 'phone' && fact.kind !== 'telegram') return false;
    var mine = String(fact.value).toLowerCase().replace(/[^a-z0-9]/g, '');
    if (!mine) return false;
    return links.some(function (l) {
      if (l.kind !== fact.kind) return false;
      var theirs = String(l.value).toLowerCase().replace(/[^a-z0-9]/g, '');
      return theirs.indexOf(mine) !== -1 || mine.indexOf(theirs) !== -1;
    });
  }

  // ---------- identity ----------

  function identityBlock(business) {
    var block = el('div', 'bz-ident');
    var mark = markNode(business);
    block.appendChild(mark);

    if (business.categoryName) {
      block.appendChild(el('p', 'bz-ident-cat', business.categoryName));
    }
    block.appendChild(el('h2', 'bz-ident-name', business.name));

    if (business.likes > 0) {
      var proof = el('p', 'bz-ident-proof');
      proof.appendChild(iconSpan('bz-ident-proof-icon', ICONS.heart));
      proof.appendChild(document.createTextNode(t('business.likes', { n: business.likes })));
      block.appendChild(proof);
    }

    if (business.logo) {
      // The wash behind the mark is mixed from the picture's own colour, once
      // it has been read. Until then there is no wash: a colour guessed from
      // the name can land a pink logo on a mint field.
      var src = logoSrc(business);
      analyseImage(src, function (facts) {
        if (!facts || !mark.isConnected) return;
        tintSheet(rgbStr(facts.tint));
        mark.classList.remove('bz-mark--auto');
        mark.classList.add('bz-mark--' + facts.kind);
        if (facts.kind === 'plate') {
          mark.style.setProperty('--plate', 'rgb(' + rgbStr(facts.plate) + ')');
        }
      });
    } else {
      // Read back by mountSheet, since this runs while still an argument to it.
      block.dataset.tint = hueTintOf(business.name);
    }
    return block;
  }

  function markNode(business) {
    if (!business.logo) {
      var mono = el('div', 'bz-mark bz-mark--mono');
      mono.textContent = initials(business.name);
      mono.style.setProperty('--h', hueOf(business.name));
      mono.setAttribute('aria-hidden', 'true');
      return mono;
    }
    var src = logoSrc(business);
    var mark = button('bz-mark bz-mark--auto');
    mark.setAttribute('aria-label', t('business.zoomLabel', { name: business.name }));

    var img = document.createElement('img');
    img.className = 'bz-mark-img';
    img.src = src;
    img.alt = '';
    mark.appendChild(img);
    mark.appendChild(iconSpan('bz-mark-zoom', ICONS.expand));

    img.addEventListener('error', function () {
      mark.replaceWith(markNode({ name: business.name, logo: null }));
    });
    mark.addEventListener('click', function () {
      haptic('light');
      openViewer(src, business.name);
    });
    return mark;
  }

  // ---------- contact ----------
  // Two tiers. The two ways you would actually reach this business are large
  // buttons carrying the value, because a phone number is something you read
  // and copy. Everywhere else it exists is a chip: nobody needs to read a
  // Play Store URL, only to know it is there.

  var CONTACT_RANK = {
    phone: 1, telegram: 2, kakao: 3, website: 4,
    instagram: 5, tiktok: 6, playstore: 7, appstore: 8
  };
  var PRIMARY_SLOTS = 2;

  function isAndroid() { return (tg.platform || '').toLowerCase() === 'android'; }

  function actionVerb(kind) {
    if (kind === 'phone') return t(isAndroid() ? 'actions.phoneCall' : 'actions.phoneCopy');
    var named = (TEXT.actions || {})[kind];
    return typeof named === 'string' ? named : t('actions.open');
  }

  function ctaBlock(links) {
    var primary = links.slice(0, PRIMARY_SLOTS);
    var box = el('div', 'bz-cta' + (primary.length === 1 ? ' bz-cta--solo' : ''));

    if (!primary.length) {
      var none = el('div', 'bz-cta-none');
      none.appendChild(el('span', 'bz-cta-none-text', t('business.noContact')));
      var ask = button('bz-linkbtn', t('business.noContactAsk'));
      ask.addEventListener('click', openAdmin);
      none.appendChild(ask);
      box.appendChild(none);
    }

    primary.forEach(function (link, i) {
      box.appendChild(ctaButton(link, i === 0));
    });

    return box;
  }

  function ctaButton(link, primary) {
    var node = button('bz-cta-btn' + (primary ? ' is-primary' : ''));
    node.appendChild(iconSpan('bz-cta-icon', LINK_ICON[link.kind]));
    var text = el('span', 'bz-cta-text');
    text.appendChild(el('span', 'bz-cta-verb', actionVerb(link.kind)));
    text.appendChild(el('span', 'bz-cta-val', displayValue(link)));
    node.appendChild(text);
    node.addEventListener('click', function () { activate(link); });
    return node;
  }

  function linksBlock(links) {
    var box = el('div', 'bz-links');
    box.appendChild(el('p', 'bz-seclabel', t('business.linksTitle')));
    var chips = el('div', 'bz-chips');
    links.forEach(function (link) {
      var chip = button('bz-chip');
      chip.appendChild(iconSpan('bz-chip-icon', LINK_ICON[link.kind]));
      chip.appendChild(el('span', 'bz-chip-text',
        link.kind === 'website' ? displayValue(link) : t('channels.' + link.kind)));
      chip.appendChild(iconSpan('bz-chip-tail', ICONS.external));
      chip.addEventListener('click', function () { activate(link); });
      chips.appendChild(chip);
    });
    box.appendChild(chips);
    return box;
  }

  function activate(link) {
    if (link.kind === 'phone') handlePhone(link.value);
    else openExternal(link);
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

  // ---------- facts and description ----------
  // Owners write free text, and most of what a visitor wants from it is
  // structured: an address, hours, a price. Any line shaped "Label: value"
  // is lifted into a fact row the eye can scan; the rest stays prose.

  var FACT_RE = /^\s*([^:\n]{2,28}?)\s*:\s*(.{1,200}?)\s*$/;
  var FACT_LABEL_OK = /[A-Za-zÀ-ɏЀ-ӿㄱ-힝]/;
  var ADDRESS_RE = /manzil|adres|address|joylash|lokatsiya|location|주소/i;
  var HOURS_RE = /ish vaqti|ish kun|vaqt|soat|hours|영업/i;
  var PRICE_RE = /narx|price|가격/i;
  var PHONE_RE = /^\+?\d[\d\s\-().]{7,}$/;
  var HANDLE_RE = /^@?[A-Za-z0-9_.]{3,32}$/;

  function parseDescription(text) {
    var facts = [], rest = [];
    String(text || '').split(/\r?\n/).forEach(function (line) {
      var m = line.match(FACT_RE);
      var label = m && m[1], value = m && m[2];
      if (m && FACT_LABEL_OK.test(label) && !/\d$/.test(label) &&
          value.charAt(0) !== '/' && !/^https?$/i.test(label)) {
        var kind = ADDRESS_RE.test(label) ? 'address'
                 : HOURS_RE.test(label) ? 'hours'
                 : PRICE_RE.test(label) ? 'price'
                 : /telegram/i.test(label) && HANDLE_RE.test(value) ? 'telegram'
                 : PHONE_RE.test(value) ? 'phone'
                 : 'text';
        facts.push({
          label: label.charAt(0).toUpperCase() + label.slice(1),
          value: value, kind: kind
        });
      } else {
        rest.push(line);
      }
    });
    return {
      facts: facts,
      text: rest.join('\n').replace(/\n{3,}/g, '\n\n').trim()
    };
  }

  var FACT_ICON = { address: ICONS.pin, hours: ICONS.clock, price: ICONS.tag,
                    phone: ICONS.phone, telegram: ICONS.telegram, text: ICONS.info };

  function factsBlock(facts) {
    var box = el('div', 'bz-facts');
    box.appendChild(el('p', 'bz-seclabel', t('business.factsTitle')));
    var list = el('dl', 'bz-factlist');
    facts.forEach(function (f) {
      var row = el('div', 'bz-fact');
      row.appendChild(iconSpan('bz-fact-icon', FACT_ICON[f.kind] || ICONS.info));
      var text = el('div', 'bz-fact-text');
      text.appendChild(el('dt', 'bz-fact-k', f.label));
      var v = el('dd', 'bz-fact-v');
      appendLinked(v, f.value);
      text.appendChild(v);
      row.appendChild(text);

      var act = factAction(f);
      if (act) row.appendChild(act);
      list.appendChild(row);
    });
    box.appendChild(list);
    return box;
  }

  function factAction(f) {
    var b;
    if (f.kind === 'address') {
      b = button('bz-fact-act');
      b.setAttribute('aria-label', t('actions.map'));
      b.appendChild(iconSpan(null, ICONS.pin));
      b.addEventListener('click', function () { openMap(f.value); });
    } else if (f.kind === 'phone') {
      b = button('bz-fact-act');
      b.setAttribute('aria-label', t(isAndroid() ? 'actions.phoneCall' : 'actions.phoneCopy'));
      b.appendChild(iconSpan(null, isAndroid() ? ICONS.phone : ICONS.copy));
      b.addEventListener('click', function () { handlePhone(f.value.replace(/[^\d+]/g, '')); });
    } else if (f.kind === 'telegram') {
      b = button('bz-fact-act');
      b.setAttribute('aria-label', t('actions.telegram'));
      b.appendChild(iconSpan(null, ICONS.telegram));
      b.addEventListener('click', function () {
        openExternal({ kind: 'telegram', value: 'https://t.me/' + f.value.replace(/^@/, '') });
      });
    }
    return b || null;
  }

  function aboutBlock(text) {
    var box = el('div', 'bz-about');
    box.appendChild(el('p', 'bz-seclabel', t('business.aboutTitle')));
    var body = el('p', 'bz-about-text is-clamped');
    appendLinked(body, text);
    box.appendChild(body);
    return box;
  }

  // Whether the description overflows its clamp is only knowable once it is
  // laid out, so the "more" control is attached after the card is on screen.
  function settleDescription(root) {
    var body = root.querySelector('.bz-about-text');
    if (!body) return;
    requestAnimationFrame(function () {
      if (body.scrollHeight - body.clientHeight < 4) {
        body.classList.remove('is-clamped');
        return;
      }
      var toggle = button('bz-more', t('business.readMore'));
      toggle.setAttribute('aria-expanded', 'false');
      toggle.addEventListener('click', function () {
        var clamped = body.classList.toggle('is-clamped');
        toggle.textContent = t(clamped ? 'business.readMore' : 'business.readLess');
        toggle.setAttribute('aria-expanded', clamped ? 'false' : 'true');
        haptic('light');
      });
      body.parentNode.appendChild(toggle);
    });
  }

  // Text with any URLs turned into real buttons. Built from text nodes, never
  // innerHTML: nothing owner-supplied is parsed as markup.
  var URL_RE = /(https?:\/\/[^\s<>"']+|www\.[^\s<>"']+)/gi;
  var TRAILING = /[.,;:!?)\]]+$/;

  function appendLinked(node, text) {
    var last = 0, m;
    URL_RE.lastIndex = 0;
    while ((m = URL_RE.exec(text)) !== null) {
      var raw = m[0];
      var trail = (raw.match(TRAILING) || [''])[0];
      if (trail) raw = raw.slice(0, raw.length - trail.length);
      if (!raw) continue;
      if (m.index > last) node.appendChild(document.createTextNode(text.slice(last, m.index)));
      node.appendChild(inlineLinkNode(raw));
      if (trail) node.appendChild(document.createTextNode(trail));
      last = m.index + m[0].length;
    }
    if (last < text.length) node.appendChild(document.createTextNode(text.slice(last)));
  }

  function inlineLinkNode(raw) {
    var href = /^https?:\/\//i.test(raw) ? raw : 'https://' + raw;
    var node = button('bz-inlink');
    node.appendChild(el('span', null, prettyUrl(href)));
    node.appendChild(iconSpan('bz-inlink-icon', ICONS.external));
    node.addEventListener('click', function () {
      openExternal({ kind: hostKind(href), value: href });
    });
    return node;
  }

  // What a link pasted into a description is called, and which app should
  // open it. A plain brand name is the same word in every language and stays
  // here; anything carrying an Uzbek word is a path into the text file.
  //
  // Order matters: the map hosts have to be tested before the generic
  // messenger and search hosts they sit underneath, or a Kakao map link ends
  // up labelled as the messenger.
  var HOST_LABEL = [
    [/(^|\.)play\.google\.com$/, 'Google Play', 'playstore'],
    [/(^|\.)apps\.apple\.com$/, 'App Store', 'appstore'],
    [/(^|\.)itunes\.apple\.com$/, 'App Store', 'appstore'],
    [/(^|\.)instagram\.com$/, 'Instagram', 'instagram'],
    [/(^|\.)tiktok\.com$/, 'TikTok', 'tiktok'],
    [/(^|\.)(t|telegram)\.me$/, 'Telegram', 'telegram'],
    [/^map\.naver\.com$|(^|\.)naver\.me$/, 'hosts.naverMap', 'website'],
    [/^map\.kakao\.com$/, 'hosts.kakaoMap', 'website'],
    [/^maps\.google\.|^maps\.app\.goo\.gl$|^goo\.gl$/, 'hosts.googleMap', 'website'],
    [/(^|\.)kakao\.com$/, 'KakaoTalk', 'kakao'],
    [/(^|\.)youtube\.com$/, 'YouTube', 'website'],
    [/(^|\.)youtu\.be$/, 'YouTube', 'website']
  ];

  // A label written as a text-file path is resolved when it is used.
  function hostLabel(label) {
    return label.indexOf('hosts.') === 0 ? t(label) : label;
  }

  function hostOf(url) {
    try { return new URL(url).hostname.toLowerCase().replace(/^www\./, ''); }
    catch (e) { return ''; }
  }
  function prettyUrl(url) {
    var host = hostOf(url);
    for (var i = 0; i < HOST_LABEL.length; i++) {
      if (HOST_LABEL[i][0].test(host)) return hostLabel(HOST_LABEL[i][1]);
    }
    return host || url;
  }
  function hostKind(url) {
    var host = hostOf(url);
    for (var i = 0; i < HOST_LABEL.length; i++) {
      if (HOST_LABEL[i][0].test(host)) return HOST_LABEL[i][2];
    }
    return 'website';
  }

  // ---------- reactions and report ----------

  function reactionBar(business) {
    applyReaction(business);

    var bar = el('div', 'bz-react');
    bar.appendChild(el('span', 'bz-react-label', t('business.reactLabel')));

    // What the server last confirmed. A failed request falls back to this
    // rather than leaving the count wherever the optimistic guess put it.
    var settled = {
      mine: business.myReaction || 0,
      likes: business.likes || 0,
      dislikes: business.dislikes || 0
    };
    var shown = { mine: settled.mine, likes: settled.likes, dislikes: settled.dislikes };

    var up = reactionBtn(ICONS.thumbUp, shown.likes, shown.mine === 1, t('business.reactUp'));
    var down = reactionBtn(ICONS.thumbDown, shown.dislikes, shown.mine === -1, t('business.reactDown'));

    var desired = shown.mine;   // what the person has asked for
    var sent = shown.mine;      // what the server has been told
    var sending = false;

    function paintBoth() {
      paintReaction(up, shown.likes, shown.mine === 1);
      paintReaction(down, shown.dislikes, shown.mine === -1);
    }

    // The counts move on the tap, not on the reply. A button that waits for a
    // mobile round trip before changing reads as a button that did nothing,
    // which is exactly how a second, cancelling tap gets provoked.
    function tap(value) {
      desired = (desired === value) ? 0 : value;

      var likes = settled.likes, dislikes = settled.dislikes;
      if (settled.mine === 1) likes--;
      if (settled.mine === -1) dislikes--;
      if (desired === 1) likes++;
      if (desired === -1) dislikes++;

      shown = { mine: desired, likes: likes, dislikes: dislikes };
      paintBoth();
      haptic('light');
      pump();
    }

    // One request at a time. Taps made while one is in flight are not dropped
    // — they move `desired`, and the difference is sent as soon as the
    // current reply lands, so a quick like-then-unlike ends where the person
    // left it instead of stopping at the first tap.
    function pump() {
      if (sending || desired === sent) return;
      sending = true;
      var value = desired;

      postJSON('/api/business/' + business.id + '/reaction', { value: value })
        .then(function (data) {
          sending = false;
          sent = data.myReaction;
          settled = {
            mine: data.myReaction, likes: data.likes, dislikes: data.dislikes
          };
          business.myReaction = data.myReaction;
          business.likes = data.likes;
          business.dislikes = data.dislikes;
          rememberReaction(business.id, data);

          // Only take the server's numbers onto the screen once nothing newer
          // is waiting; otherwise the count would flick back to an
          // intermediate value between two quick taps.
          if (desired === sent) {
            shown = { mine: settled.mine, likes: settled.likes, dislikes: settled.dislikes };
            paintBoth();
          }
          pump();
        })
        .catch(function (err) {
          sending = false;
          desired = sent = settled.mine;
          shown = { mine: settled.mine, likes: settled.likes, dislikes: settled.dislikes };
          paintBoth();
          showToast(t(err.code === 'no_init_data' || err.code === 'bad_signature'
            ? 'common.telegramOnly' : 'common.saveFailed'));
        });
    }

    up.addEventListener('click', function () { tap(1); });
    down.addEventListener('click', function () { tap(-1); });

    var pair = el('span', 'bz-react-pair');
    pair.appendChild(up);
    pair.appendChild(down);
    bar.appendChild(pair);
    return bar;
  }

  function reactionBtn(icon, count, on, label) {
    var btn = button('bz-reactbtn');
    btn.setAttribute('aria-label', label);
    btn.appendChild(iconSpan('bz-reactbtn-icon', icon));
    btn.appendChild(el('span', 'bz-reactbtn-n', String(count || 0)));
    btn.classList.toggle('is-on', !!on);
    btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    return btn;
  }

  function paintReaction(btn, count, on) {
    btn.querySelector('.bz-reactbtn-n').textContent = String(count || 0);
    btn.classList.toggle('is-on', on);
    btn.setAttribute('aria-pressed', on ? 'true' : 'false');
  }

  // A wrong number or a closed shop is the visitor's problem first. One quiet
  // line gives them somewhere to say so.
  function reportLink() {
    var b = button('bz-report');
    b.appendChild(iconSpan('bz-report-icon', ICONS.flag));
    b.appendChild(el('span', null, t('business.report')));
    b.addEventListener('click', openAdmin);
    return b;
  }

  // ---------- opening things ----------

  // Android opens the dialer. On iOS a tel: link inside the Mini App webview
  // has misbehaved before, so there the number is copied instead — and the
  // button says so before it is pressed.
  function handlePhone(number) {
    if (isAndroid()) {
      haptic('light');
      window.location.href = 'tel:' + number;
      return;
    }
    copyText(number).then(function (ok) {
      if (ok) { buzz('success'); showToast(t('actions.phoneCopied', { number: number })); }
      else showToast(number);
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
    } catch (e) { return false; }
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

  function openMap(query) {
    openExternal({ kind: 'website',
      value: 'https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(query) });
  }

  function openAdmin() {
    haptic('light');
    try { tg.openTelegramLink(ADMIN); }
    catch (e) { window.open(ADMIN, '_blank', 'noopener'); }
  }

  // Fire and forget: a failed tap log must never hold up the card.
  function countTap(businessId) {
    fetch(API + '/api/business/' + encodeURIComponent(businessId) + '/tap', {
      method: 'POST', headers: authHeaders(true), keepalive: true
    }).catch(function () {});
  }

  // ============================================
  // OWNER FLOWS
  // ============================================
  // Everything about listing, positions and prices lives here, one tap
  // behind the owner card. A visitor browsing for a bakery never meets a
  // price; an owner gets the whole mechanism in one sheet.

  function openOwnerSheet(targetPosition) {
    var pricing = state.pricing || {};
    var prices = pricing.prices || {};
    var inCategory = state.mode === 'category';

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('p', 'bz-eyebrow', inCategory ? state.categoryName : t('owner.eyebrow')));
    wrap.appendChild(el('h2', 'bz-sheet-title', t('owner.title')));

    var steps = el('ol', 'bz-steps');
    steps.appendChild(stepRow('1', t('owner.step1Title'),
      t('owner.step1Body', { amount: formatKRW(pricing.listingFee || 5000) })));
    steps.appendChild(stepRow('2', t('owner.step2Title'), t('owner.step2Body')));
    steps.appendChild(stepRow('3', t('owner.step3Title'),
      t('owner.step3Body', { amount: formatKRW(pricing.bidStep || 5000) })));
    wrap.appendChild(steps);

    if (inCategory && pricing.showBidding && prices['1']) {
      wrap.appendChild(el('p', 'bz-seclabel',
        t('owner.pricesLabel', { category: state.categoryName })));
      var table = el('div', 'bz-prices');
      [1, 2, 3].forEach(function (pos) {
        if (!prices[String(pos)]) return;
        var row = el('div', 'bz-prices-row' + (pos === targetPosition ? ' is-target' : ''));
        row.appendChild(rankBadge(pos));
        row.appendChild(el('span', 'bz-prices-val', formatKRW(prices[String(pos)])));
        row.appendChild(el('span', 'bz-prices-note', t('owner.pricesFrom')));
        table.appendChild(row);
      });
      wrap.appendChild(table);
      wrap.appendChild(el('p', 'bz-fine', t('owner.pricesFine')));
    } else if (!inCategory) {
      var pick = button('bz-btn bz-btn--ghost', t('owner.pricesPick'));
      pick.addEventListener('click', function () { openPicker(); });
      wrap.appendChild(pick);
    }

    var submit = button('bz-btn bz-btn--block', t('owner.submit'));
    submit.addEventListener('click', function () { openSubmitForm(); });
    wrap.appendChild(submit);

    var mineBtn = button('bz-btn bz-btn--text', t('owner.mine'));
    mineBtn.addEventListener('click', openMine);
    wrap.appendChild(mineBtn);

    mountSheet(wrap, { kind: 'sheet' });
  }

  function stepRow(n, title, body) {
    var row = el('li', 'bz-step');
    row.appendChild(el('span', 'bz-step-n', n));
    var text = el('span', 'bz-step-text');
    text.appendChild(el('span', 'bz-step-title', title));
    text.appendChild(el('span', 'bz-step-body', body));
    row.appendChild(text);
    return row;
  }

  // ---------- submission ----------

  // Each field's label is the channel's name from the text file; the
  // placeholders are examples of a format, not language, so they stay here.
  var LINK_FIELDS = [
    { kind: 'phone',     placeholder: '010-1234-5678', mode: 'tel' },
    { kind: 'telegram',  placeholder: '@username' },
    { kind: 'instagram', placeholder: '@username' },
    { kind: 'website',   placeholder: 'example.uz', mode: 'url' }
  ];

  var DESC_MAX = 500;

  // Draft survives a trip to the category picker and back.
  var draft = { name: '', description: '', links: {}, category: null,
                logoBlob: null, logoUrl: null };

  function clearDraft() {
    setDraftLogo(null);
    draft = { name: '', description: '', links: {}, category: null,
              logoBlob: null, logoUrl: null };
  }

  // One form for both jobs. In edit mode it opens on what is already stored.
  function openSubmitForm(existing) {
    var editing = !!existing;
    if (editing && draft.id !== existing.id) {
      draft = {
        id: existing.id,
        name: existing.name,
        description: existing.description || '',
        links: {},
        category: { id: existing.categoryId, name: existing.categoryName, icon: existing.categoryIcon },
        logo: existing.logo || null
      };
      (existing.links || []).forEach(function (l) { draft.links[l.kind] = displayValue(l); });
    }
    if (!editing && draft.id) clearDraft();
    if (!draft.category && state.mode === 'category') {
      draft.category = { id: state.categoryId, name: state.categoryName, icon: state.categoryIcon };
    }

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('p', 'bz-eyebrow', editing ? draft.category.name : t('form.eyebrowNew')));
    wrap.appendChild(el('h2', 'bz-sheet-title', t(editing ? 'form.titleEdit' : 'form.titleNew')));

    wrap.appendChild(logoPicker(editing
      ? existing
      : { name: draft.name || t('form.eyebrowNew'), logo: null }));

    var form = el('div', 'bz-form');

    var nameField = field(t('form.nameLabel'), t('form.required'));
    var nameInput = el('input', 'bz-input');
    nameInput.type = 'text';
    nameInput.maxLength = 80;
    nameInput.placeholder = t('form.namePlaceholder');
    nameInput.value = draft.name;
    nameInput.addEventListener('input', function () { draft.name = nameInput.value; });
    nameField.appendChild(nameInput);
    form.appendChild(nameField);

    var catField = field(t('form.categoryLabel'), t('form.required'));
    var catBtn = button('bz-select');
    catBtn.setAttribute('aria-haspopup', 'dialog');
    catBtn.appendChild(glyphNode(draft.category ? draft.category.icon : '◆', 'bz-glyph bz-glyph--pick'));
    var catLabel = el('span', 'bz-select-label',
                      draft.category ? draft.category.name : t('form.categoryPick'));
    if (!draft.category) catLabel.classList.add('is-placeholder');
    catBtn.appendChild(catLabel);
    catBtn.appendChild(iconSpan('bz-select-caret', ICONS.caret));
    catBtn.addEventListener('click', function () {
      openPicker(function (cat) {
        draft.category = cat;
        openSubmitForm(existing);
      });
    });
    catField.appendChild(catBtn);
    form.appendChild(catField);

    // The card lifts "Label: value" lines into fact rows, so the form shows
    // owners that shape rather than describing it.
    var descField = field(t('form.descLabel'), t('form.optional'));
    var descInput = el('textarea', 'bz-input bz-textarea');
    descInput.rows = 5;
    descInput.maxLength = DESC_MAX;
    descInput.placeholder = t('form.descPlaceholder');
    descInput.value = draft.description;
    var counter = el('span', 'bz-counter',
                     t('form.counter', { n: draft.description.length, max: DESC_MAX }));
    descInput.addEventListener('input', function () {
      draft.description = descInput.value;
      counter.textContent = t('form.counter', { n: descInput.value.length, max: DESC_MAX });
    });
    descField.appendChild(descInput);
    descField.appendChild(el('span', 'bz-fieldnote', t('form.descNote')));
    descField.appendChild(counter);
    form.appendChild(descField);

    var linkField = field(t('form.linksLabel'), t('form.atLeastOne'));
    var inputs = {};
    LINK_FIELDS.forEach(function (spec) {
      var row = el('label', 'bz-linkrow');
      row.appendChild(iconSpan('bz-linkrow-icon', LINK_ICON[spec.kind]));
      var input = el('input', 'bz-input bz-input--flat');
      input.type = 'text';
      input.maxLength = 200;
      input.placeholder = spec.placeholder;
      input.setAttribute('aria-label', t('channels.' + spec.kind));
      input.autocapitalize = 'none';
      input.spellcheck = false;
      if (spec.mode) input.inputMode = spec.mode;
      input.value = draft.links[spec.kind] || '';
      input.addEventListener('input', function () { draft.links[spec.kind] = input.value; });
      inputs[spec.kind] = input;
      row.appendChild(input);
      linkField.appendChild(row);
    });
    form.appendChild(linkField);
    wrap.appendChild(form);

    wrap.appendChild(el('p', 'bz-fine', editing
      ? t('form.fineEdit')
      : t('form.fineNew',
          { amount: formatKRW((state.pricing || {}).listingFee || 5000) })));

    var error = el('p', 'bz-formerror');
    error.setAttribute('role', 'alert');
    error.hidden = true;
    wrap.appendChild(error);

    var send = button('bz-btn bz-btn--block', t(editing ? 'form.save' : 'form.send'));
    wrap.appendChild(send);

    function readLinks() {
      return LINK_FIELDS.map(function (spec) {
        return { kind: spec.kind, value: inputs[spec.kind].value.trim() };
      }).filter(function (l) { return l.value; });
    }

    function fail(code) {
      error.textContent = errorText('submitErrors', code);
      error.hidden = false;
      buzz('error');
    }

    var sending = false;
    send.addEventListener('click', function () {
      if (sending) return;
      error.hidden = true;

      var links = readLinks();
      if (nameInput.value.trim().length < 2) { nameInput.focus(); return fail('bad_name'); }
      if (!draft.category) return fail('bad_category');
      if (!links.length) { inputs.phone.focus(); return fail('no_contact'); }

      sending = true;
      send.disabled = true;
      send.textContent = t(editing ? 'form.saving' : 'form.sending');
      nameInput.blur();

      var body = {
        name: nameInput.value.trim(),
        category_id: draft.category.id,
        description: descInput.value.trim(),
        links: links
      };
      var path = editing ? '/api/business/' + existing.id + '/edit' : '/api/business/submit';

      postJSON(path, body)
        .then(function (data) {
          buzz('success');
          if (editing) {
            clearDraft();
            showToast(t('common.saved'));
            openMine();
            refreshCurrentView();
            return;
          }
          var held = draft.logoBlob;
          if (!held) { clearDraft(); showSubmitted(); return; }
          send.textContent = t('form.sendingLogo');
          return uploadLogo(data.id, held)
            .then(function () { clearDraft(); showSubmitted(); })
            .catch(function () {
              clearDraft();
              showSubmitted(t('submitted.logoFailed'));
            });
        })
        .catch(function (err) {
          sending = false;
          send.disabled = false;
          send.textContent = t(editing ? 'form.save' : 'form.send');
          fail(err.code);
        });
    });

    mountSheet(wrap, { kind: 'sheet' });
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
    wrap.appendChild(el('h2', 'bz-sheet-title', t('submitted.title')));
    wrap.appendChild(el('p', 'bz-done-text', t('submitted.body')));
    if (caveat) wrap.appendChild(el('p', 'bz-formerror', caveat));

    var cta = button('bz-btn bz-btn--block', t('common.adminContact'));
    cta.addEventListener('click', openAdmin);
    wrap.appendChild(cta);
    var mine = button('bz-btn bz-btn--text', t('owner.mine'));
    mine.addEventListener('click', openMine);
    wrap.appendChild(mine);
    mountSheet(wrap, { kind: 'card' });
  }

  // ---------- logo ----------
  // Downscaled in the page before it goes anywhere, so a 4MB phone photo does
  // not cross a mobile connection at full size. The server re-encodes anyway.

  var LOGO_EDGE = 512;

  // With a business id the file goes straight up. Without one — during
  // submission — it is held on the draft and sent once the listing has an id.
  function logoPicker(business) {
    var deferred = !business.id;
    var box = el('div', 'bz-logopick');

    var preview = el('div', 'bz-logopreview');
    preview.setAttribute('aria-hidden', 'true');
    paintPreview(preview, business);
    box.appendChild(preview);

    var side = el('div', 'bz-logoside');
    side.appendChild(el('span', 'bz-fieldlabel', t('form.logoLabel')));
    var hint = el('span', 'bz-logohint', t(deferred ? 'form.logoHintNew' : 'form.logoHint'));
    side.appendChild(hint);

    var pick = button('bz-logobtn',
      t((business.logo || draft.logoBlob) ? 'form.logoReplace' : 'form.logoPick'));
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
      hint.textContent = t(deferred ? 'form.logoPreparing' : 'form.logoUploading');
      pick.disabled = true;

      shrink(file)
        .then(function (blob) {
          if (deferred) {
            setDraftLogo(blob);
            showLocalPreview(preview, blob);
            hint.textContent = t('form.logoChosen');
            pick.textContent = t('form.logoReplace');
            haptic('light');
            return null;
          }
          return uploadLogo(business.id, blob).then(function (data) {
            business.logo = data.logo;
            paintPreview(preview, business, data.version);
            hint.textContent = t('form.logoSaved');
            pick.textContent = t('form.logoReplace');
            buzz('success');
            refreshCurrentView();
          });
        })
        .catch(function (err) {
          hint.textContent = errorText('logoErrors', (err && err.code) || 'generic');
          buzz('error');
        })
        .then(function () { pick.disabled = false; });
    });
    return box;
  }

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
      img.src = logoSrc(business, version);
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
        canvas.toBlob(function (blob) { resolve(blob || file); }, 'image/webp', 0.9);
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
      headers: authHeaders(false),
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
  // opts.quiet keeps the current content on screen while the request runs and
  // swallows a failure, so a refresh nobody asked for can never replace what
  // somebody is reading with a spinner or an error card.
  function refreshCurrentView(opts) {
    if (state.mode === 'category') loadCategory(opts);
    else if (state.mode === 'search') loadSearch(opts);
    else loadCategories(opts);
  }

  // ---------- my businesses ----------

  // Colour only; the words are in the text file under "status".
  var STATUS_TONE = {
    pending_review: 'pending',
    unpaid:         'unpaid',
    active:         'active',
    rejected:       'off',
    suspended:      'off'
  };

  function openMine() {
    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('p', 'bz-eyebrow', t('owner.eyebrow')));
    wrap.appendChild(el('h2', 'bz-sheet-title', t('mine.title')));
    var slot = el('div');
    slot.appendChild(el('div', 'bz-spinner'));
    wrap.appendChild(slot);
    mountSheet(wrap, { kind: 'sheet' });

    fetch(API + '/api/business/mine', {
      headers: authHeaders(false),
      signal: AbortSignal.timeout(TIMEOUT)
    })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        slot.textContent = '';
        var items = (data && data.businesses) || [];
        if (!items.length) {
          slot.appendChild(el('p', 'bz-sheet-text', t('mine.empty')));
        } else {
          var list = el('div', 'bz-minelist');
          items.forEach(function (b) { list.appendChild(mineRow(b)); });
          slot.appendChild(list);
        }
        var add = button('bz-btn bz-btn--block', t('mine.add'));
        add.addEventListener('click', function () { openSubmitForm(); });
        slot.appendChild(add);
      })
      .catch(function () {
        slot.textContent = '';
        slot.appendChild(el('p', 'bz-sheet-text', t('mine.loadFailed')));
      });
  }

  function mineRow(business) {
    var row = el('div', 'bz-mine');
    var head = el('div', 'bz-mine-head');
    head.appendChild(logoNode(business));

    var body = el('div', 'bz-mine-body');
    body.appendChild(el('span', 'bz-mine-name', business.name));
    body.appendChild(el('span', 'bz-mine-cat', business.categoryName || ''));

    var meta = el('span', 'bz-mine-meta');
    var tone = STATUS_TONE[business.status] || 'off';
    var label = (TEXT.status || {})[business.status] || business.status;
    meta.appendChild(el('span', 'bz-status bz-status--' + tone, label));
    if (business.status === 'active') {
      if (business.position) {
        meta.appendChild(el('span', 'bz-mine-stat', t('mine.position', { n: business.position })));
      }
      meta.appendChild(el('span', 'bz-mine-stat', t('mine.likes', { n: business.likes || 0 })));
      meta.appendChild(el('span', 'bz-mine-stat', t('mine.taps', { n: business.taps || 0 })));
    }
    if (business.pendingBid) {
      meta.appendChild(el('span', 'bz-status bz-status--pending',
        t('mine.pendingBid', { amount: formatKRW(business.pendingBid.amount) })));
    }
    body.appendChild(meta);
    head.appendChild(body);
    row.appendChild(head);

    // Rejected listings are not the owner's to fix; everything else is.
    if (business.status !== 'rejected') {
      var actions = el('div', 'bz-mine-acts');
      var edit = button('bz-mine-act', t('mine.edit'));
      edit.addEventListener('click', function () { haptic('light'); openSubmitForm(business); });
      actions.appendChild(edit);

      var pricing = business.pricing || {};
      if (business.status === 'active' && pricing.showBidding) {
        var bid = button('bz-mine-act bz-mine-act--bid',
          t(business.pendingBid ? 'mine.cancelBid' : 'mine.bid'));
        bid.addEventListener('click', function () {
          haptic('light');
          if (business.pendingBid) cancelBid(business);
          else openBidForm(business);
        });
        actions.appendChild(bid);
      }
      row.appendChild(actions);
    }
    return row;
  }

  // ---------- bidding ----------

  function openBidForm(business) {
    var pricing = business.pricing || {};
    var prices = pricing.prices || {};
    var held = business.bidAmount || 0;

    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('p', 'bz-eyebrow', business.categoryName || ''));
    wrap.appendChild(el('h2', 'bz-sheet-title', t('bid.title')));

    var now = el('div', 'bz-bidnow');
    now.appendChild(bidStat(t('bid.nowPosition'), business.position
      ? t('mine.position', { n: business.position }) : t('common.empty')));
    now.appendChild(bidStat(t('bid.nowBid'), held ? formatKRW(held) : t('common.empty')));
    wrap.appendChild(now);

    wrap.appendChild(el('p', 'bz-sheet-text', t('bid.lead')));

    var chosen = null;
    var options = el('div', 'bz-bidopts');
    var error = el('p', 'bz-formerror');
    error.setAttribute('role', 'alert');
    error.hidden = true;
    var send = button('bz-btn bz-btn--block', t('bid.pickFirst'));
    send.disabled = true;

    [1, 2, 3].forEach(function (pos) {
      var price = prices[String(pos)];
      if (!price) return;
      var opt = button('bz-bidopt');
      opt.setAttribute('aria-pressed', 'false');
      opt.appendChild(rankBadge(pos));
      var body = el('span', 'bz-bidopt-body');
      body.appendChild(el('span', 'bz-bidopt-amount', formatKRW(price)));
      var due = Math.max(0, price - held);
      body.appendChild(el('span', 'bz-bidopt-due', held
        ? t('bid.optionDue', { amount: formatKRW(due) })
        : t('bid.optionMin')));
      opt.appendChild(body);

      if (price <= held) {
        opt.disabled = true;
        opt.classList.add('is-held');
      } else {
        opt.addEventListener('click', function () {
          chosen = price;
          var all = options.querySelectorAll('.bz-bidopt');
          for (var i = 0; i < all.length; i++) {
            all[i].classList.remove('is-on');
            all[i].setAttribute('aria-pressed', 'false');
          }
          opt.classList.add('is-on');
          opt.setAttribute('aria-pressed', 'true');
          error.hidden = true;
          send.disabled = false;
          send.textContent = t('bid.sendWith', { amount: formatKRW(Math.max(0, price - held)) });
        });
      }
      options.appendChild(opt);
    });
    wrap.appendChild(options);
    wrap.appendChild(error);
    wrap.appendChild(send);
    wrap.appendChild(el('p', 'bz-fine', t('bid.fine')));

    var sending = false;
    send.addEventListener('click', function () {
      if (sending || !chosen) return;
      sending = true;
      send.disabled = true;
      send.textContent = t('bid.sending');
      postJSON('/api/business/' + business.id + '/bid', { amount: chosen })
        .then(function () { buzz('success'); showBidSent(); })
        .catch(function (err) {
          sending = false;
          send.disabled = false;
          send.textContent = t('bid.send');
          error.textContent = errorText('bidErrors', err.code);
          error.hidden = false;
          buzz('error');
        });
    });

    mountSheet(wrap, { kind: 'sheet' });
  }

  function bidStat(label, value) {
    var box = el('div', 'bz-bidstat');
    box.appendChild(el('span', 'bz-bidstat-k', label));
    box.appendChild(el('span', 'bz-bidstat-v', value));
    return box;
  }

  function showBidSent() {
    var wrap = el('div', 'bz-sheet-body bz-done');
    wrap.appendChild(iconSpan('bz-done-icon', ICONS.clock));
    wrap.appendChild(el('h2', 'bz-sheet-title', t('bid.sentTitle')));
    wrap.appendChild(el('p', 'bz-done-text', t('bid.sentBody')));
    var cta = button('bz-btn bz-btn--block', t('common.adminContact'));
    cta.addEventListener('click', openAdmin);
    wrap.appendChild(cta);
    var back = button('bz-btn bz-btn--text', t('owner.mine'));
    back.addEventListener('click', openMine);
    wrap.appendChild(back);
    mountSheet(wrap, { kind: 'card' });
  }

  function cancelBid(business) {
    fetch(API + '/api/business/' + business.id + '/bid', {
      method: 'DELETE', headers: authHeaders(false)
    })
      .then(function () { showToast(t('mine.bidCancelled')); openMine(); })
      .catch(function () { showToast(t('mine.bidCancelFailed')); });
  }

  // ---------- category picker ----------
  // Every category in one list, identical rows, the whole set visible in one
  // scroll. Used both to switch category and to choose one for the form.

  function openPicker(onChoose) {
    haptic('light');
    var wrap = el('div', 'bz-sheet-body');
    wrap.appendChild(el('h2', 'bz-sheet-title', t(onChoose ? 'picker.titleChoose' : 'picker.title')));

    var list = el('div', 'bz-picker');
    list.setAttribute('role', 'list');

    if (!onChoose) {
      var all = button('bz-pick' + (state.mode === 'categories' ? ' is-on' : ''));
      all.appendChild(glyphNode('◆', 'bz-glyph bz-glyph--pick'));
      all.appendChild(el('span', 'bz-pick-name', t('picker.all')));
      all.appendChild(el('span', 'bz-pick-n', String(totalCount())));
      all.addEventListener('click', function () {
        closeSheet();
        if (state.mode !== 'categories') backToCategories();
      });
      list.appendChild(all);
    }

    state.categories.forEach(function (cat) {
      var row = button('bz-pick');
      if (!cat.count) row.classList.add('is-quiet');
      if (!onChoose && state.mode === 'category' && state.categoryId === cat.id) {
        row.classList.add('is-on');
        row.setAttribute('aria-current', 'true');
      }
      row.appendChild(glyphNode(cat.icon, 'bz-glyph bz-glyph--pick'));
      var text = el('span', 'bz-pick-text');
      text.appendChild(el('span', 'bz-pick-name', cat.name));
      var about = categoryAbout(cat.slug);
      if (about) text.appendChild(el('span', 'bz-pick-about', about));
      row.appendChild(text);
      row.appendChild(el('span', 'bz-pick-n', cat.count ? String(cat.count) : t('common.empty')));

      if (onChoose) {
        row.addEventListener('click', function () { onChoose(cat); });
      } else {
        row.addEventListener('click', function () {
          closeSheet();
          if (state.categoryId !== cat.id) openCategory(cat);
        });
      }
      list.appendChild(row);
    });

    wrap.appendChild(list);
    mountSheet(wrap, { kind: 'sheet' });
  }

  // ============================================
  // IMAGE ANALYSIS
  // ============================================
  // What makes a logo look pasted in is the seam where its own background
  // meets the container we put it in. So the picture's edge pixels are read
  // and the picture decides its own treatment: a cut-out mark gets no plate,
  // a solid-ground logo gets a plate in its own colour, a photograph gets a
  // frame. Sampling runs on a separate CORS probe so the visible image never
  // depends on the host sending the header.

  var EDGE_UNIFORM = 20;
  var ALPHA_CLEAR = 32;
  var imageFacts = {};

  function analyseImage(src, done) {
    if (imageFacts[src] !== undefined) {
      var cached = imageFacts[src];
      setTimeout(function () { done(cached); }, 0);
      return;
    }
    var probe = new Image();
    probe.crossOrigin = 'anonymous';
    probe.onload = function () {
      var facts = null;
      try {
        var n = 32;
        var canvas = document.createElement('canvas');
        canvas.width = n; canvas.height = n;
        var ctx = canvas.getContext('2d', { willReadFrequently: true });
        ctx.drawImage(probe, 0, 0, n, n);
        facts = readPixels(ctx.getImageData(0, 0, n, n).data, n);
      } catch (e) { facts = null; }
      imageFacts[src] = facts;
      done(facts);
    };
    probe.onerror = function () { imageFacts[src] = null; done(null); };
    probe.src = src;
  }

  function readPixels(data, n) {
    var edge = [], clear = 0, edgeCount = 0;
    var sumR = 0, sumG = 0, sumB = 0, opaque = 0;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        var i = (y * n + x) * 4;
        var a = data[i + 3];
        var onEdge = x < 2 || y < 2 || x >= n - 2 || y >= n - 2;
        if (onEdge) {
          edgeCount++;
          if (a < ALPHA_CLEAR) clear++;
          else edge.push([data[i], data[i + 1], data[i + 2]]);
        }
        if (a >= ALPHA_CLEAR) { sumR += data[i]; sumG += data[i + 1]; sumB += data[i + 2]; opaque++; }
      }
    }
    if (!opaque) return null;
    var tint = [Math.round(sumR / opaque), Math.round(sumG / opaque), Math.round(sumB / opaque)];
    if (clear / edgeCount > 0.45) return { kind: 'plain', tint: softenTint(tint) };

    var mean = [0, 0, 0], k;
    for (k = 0; k < edge.length; k++) { mean[0] += edge[k][0]; mean[1] += edge[k][1]; mean[2] += edge[k][2]; }
    mean = mean.map(function (v) { return v / edge.length; });
    var spread = [0, 0, 0];
    for (k = 0; k < edge.length; k++) {
      spread[0] += Math.pow(edge[k][0] - mean[0], 2);
      spread[1] += Math.pow(edge[k][1] - mean[1], 2);
      spread[2] += Math.pow(edge[k][2] - mean[2], 2);
    }
    spread = spread.map(function (v) { return Math.sqrt(v / edge.length); });
    if (Math.max(spread[0], spread[1], spread[2]) < EDGE_UNIFORM) {
      return { kind: 'plate', plate: mean.map(Math.round), tint: mean.map(Math.round) };
    }
    return { kind: 'photo', tint: softenTint(tint) };
  }

  function rgbStr(c) { return c[0] + ', ' + c[1] + ', ' + c[2]; }

  function rgbToHsl(r, g, b) {
    r /= 255; g /= 255; b /= 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var l = (max + min) / 2, h = 0, s = 0;
    if (max !== min) {
      var d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
      else if (max === g) h = (b - r) / d + 2;
      else h = (r - g) / d + 4;
      h /= 6;
    }
    return [h, s, l];
  }

  function hslToRgb(h, s, l) {
    var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    var p = 2 * l - q;
    function ch(t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }
    return (s === 0 ? [l, l, l] : [ch(h + 1 / 3), ch(h), ch(h - 1 / 3)])
      .map(function (v) { return Math.round(v * 255); });
  }

  // Hue is kept; saturation is capped and lightness pulled to the middle so
  // a saturated mark does not paint the whole card in its brand colour.
  function softenTint(rgb) {
    var hsl = rgbToHsl(rgb[0], rgb[1], rgb[2]);
    return hslToRgb(hsl[0], Math.min(hsl[1], 0.40), Math.max(0.45, Math.min(0.74, hsl[2])));
  }

  function hueTintOf(name) {
    return rgbStr(hslToRgb(hueOf(name) / 360, 0.38, 0.58));
  }

  // ============================================
  // FULL-SCREEN IMAGE VIEWER
  // ============================================
  // Pinch, double-tap, pan, and a pull-down to dismiss, on a plain <img>.
  // One transform on the stage carries zoom and pan together.

  var MAX_SCALE = 5;
  var DOUBLE_TAP_SCALE = 2.5;
  var TAP_SLOP = 24;
  var TAP_GAP = 300;
  var VIEWER_DISMISS = 110;

  var viewer = {
    open: false, scale: 1, tx: 0, ty: 0,
    pointers: null, start: null, lastTap: 0, lastTapX: 0, lastTapY: 0, backAfter: null
  };

  function openViewer(src, label) {
    var node = $('bzViewer');
    var img = $('bzViewerImg');
    if (!node || !img) return;
    img.src = src;
    img.alt = label || '';
    viewer.open = true;
    viewer.scale = 1; viewer.tx = 0; viewer.ty = 0;
    applyViewer(false);
    node.hidden = false;
    requestAnimationFrame(function () { node.classList.add('visible'); });
    viewer.backAfter = backHandler;
    setBack(closeViewer);
  }

  function closeViewer() {
    if (!viewer.open) return;
    var node = $('bzViewer');
    viewer.open = false;
    node.classList.remove('visible');
    node.style.removeProperty('--fade');
    setTimeout(function () {
      node.hidden = true;
      $('bzViewerImg').removeAttribute('src');
    }, 220);
    setBack(viewer.backAfter || currentBack());
    viewer.backAfter = null;
  }

  function applyViewer(animate) {
    var stage = $('bzViewerStage');
    stage.style.transition = animate ? 'transform 260ms var(--ease-out, ease-out)' : 'none';
    stage.style.transform = 'translate(' + viewer.tx + 'px,' + viewer.ty + 'px) scale(' + viewer.scale + ')';
  }

  function viewerBounds() {
    var img = $('bzViewerImg');
    var w = img.clientWidth * viewer.scale;
    var h = img.clientHeight * viewer.scale;
    return { x: Math.max(0, (w - window.innerWidth) / 2), y: Math.max(0, (h - window.innerHeight) / 2) };
  }

  function clampViewer() {
    var b = viewerBounds();
    viewer.tx = Math.max(-b.x, Math.min(b.x, viewer.tx));
    viewer.ty = Math.max(-b.y, Math.min(b.y, viewer.ty));
  }

  function zoomAbout(next, cx, cy) {
    next = Math.max(1, Math.min(MAX_SCALE, next));
    var k = next / viewer.scale;
    var ox = cx - window.innerWidth / 2;
    var oy = cy - window.innerHeight / 2;
    viewer.tx = ox - (ox - viewer.tx) * k;
    viewer.ty = oy - (oy - viewer.ty) * k;
    viewer.scale = next;
  }

  function initViewer() {
    var node = $('bzViewer');
    if (!node) return;
    var stage = $('bzViewerStage');
    viewer.pointers = new Map();

    $('bzViewerClose').addEventListener('click', function () { haptic('light'); closeViewer(); });

    function centreOf() {
      var pts = Array.from(viewer.pointers.values());
      var sx = 0, sy = 0;
      pts.forEach(function (p) { sx += p.x; sy += p.y; });
      return { x: sx / pts.length, y: sy / pts.length };
    }
    function spanOf() {
      var pts = Array.from(viewer.pointers.values());
      return Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
    }
    function begin() {
      var c = centreOf();
      viewer.start = {
        x: c.x, y: c.y, tx: viewer.tx, ty: viewer.ty, scale: viewer.scale,
        span: viewer.pointers.size > 1 ? spanOf() : 0,
        n: viewer.pointers.size, moved: false, t: Date.now()
      };
    }

    node.addEventListener('pointerdown', function (e) {
      if (!viewer.open) return;
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      viewer.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
      begin();
      if (viewer.pointers.size === 1) {
        window.addEventListener('pointermove', onMove, { passive: false });
        window.addEventListener('pointerup', onUp);
        window.addEventListener('pointercancel', onUp);
      }
    });

    function onMove(e) {
      if (!viewer.pointers.has(e.pointerId) || !viewer.start) return;
      viewer.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
      if (e.cancelable) e.preventDefault();
      var c = centreOf();
      var dx = c.x - viewer.start.x;
      var dy = c.y - viewer.start.y;
      if (Math.hypot(dx, dy) > 4) viewer.start.moved = true;

      if (viewer.pointers.size > 1 && viewer.start.span > 0) {
        var ratio = spanOf() / viewer.start.span;
        var s1 = Math.max(0.6, Math.min(MAX_SCALE, viewer.start.scale * ratio));
        var ox = window.innerWidth / 2, oy = window.innerHeight / 2;
        var k = s1 / viewer.start.scale;
        viewer.scale = s1;
        viewer.tx = c.x - ox - k * (viewer.start.x - ox - viewer.start.tx);
        viewer.ty = c.y - oy - k * (viewer.start.y - oy - viewer.start.ty);
        if (viewer.scale >= 1) clampViewer();
        applyViewer(false);
        return;
      }
      if (viewer.scale > 1) {
        viewer.tx = viewer.start.tx + dx;
        viewer.ty = viewer.start.ty + dy;
        clampViewer();
        applyViewer(false);
        return;
      }
      viewer.tx = viewer.start.tx + dx * 0.4;
      viewer.ty = viewer.start.ty + dy;
      applyViewer(false);
      node.style.setProperty('--fade', String(Math.max(0.25, 1 - Math.abs(dy) / (window.innerHeight * 0.7))));
    }

    function onUp(e) {
      if (!viewer.start) return;
      viewer.pointers.delete(e.pointerId);
      if (viewer.pointers.size > 0) { begin(); return; }
      window.removeEventListener('pointermove', onMove, { passive: false });
      window.removeEventListener('pointerup', onUp);
      window.removeEventListener('pointercancel', onUp);

      var wasSingle = viewer.start.n === 1;
      var moved = viewer.start.moved;
      var dy = viewer.ty - (viewer.start.ty || 0);
      viewer.start = null;

      if (viewer.scale < 1) {
        viewer.scale = 1; viewer.tx = 0; viewer.ty = 0;
        node.style.removeProperty('--fade');
        applyViewer(true);
        return;
      }
      if (!moved && wasSingle) {
        var now = Date.now();
        var isDouble = (now - viewer.lastTap) < TAP_GAP &&
                       Math.hypot(e.clientX - viewer.lastTapX, e.clientY - viewer.lastTapY) < TAP_SLOP;
        if (isDouble) {
          viewer.lastTap = 0;
          haptic('light');
          if (viewer.scale > 1.01) { viewer.scale = 1; viewer.tx = 0; viewer.ty = 0; }
          else { zoomAbout(DOUBLE_TAP_SCALE, e.clientX, e.clientY); clampViewer(); }
          applyViewer(true);
          return;
        }
        viewer.lastTap = now; viewer.lastTapX = e.clientX; viewer.lastTapY = e.clientY;
        if (viewer.scale <= 1.01) {
          setTimeout(function () { if (viewer.open && viewer.lastTap === now) closeViewer(); }, TAP_GAP);
        }
        return;
      }
      if (viewer.scale <= 1.01 && Math.abs(dy) > VIEWER_DISMISS) { closeViewer(); return; }
      node.style.removeProperty('--fade');
      if (viewer.scale <= 1.01) { viewer.tx = 0; viewer.ty = 0; }
      else clampViewer();
      applyViewer(true);
    }

    node.addEventListener('wheel', function (e) {
      if (!viewer.open) return;
      e.preventDefault();
      zoomAbout(viewer.scale * (e.deltaY < 0 ? 1.12 : 1 / 1.12), e.clientX, e.clientY);
      if (viewer.scale <= 1.01) { viewer.scale = 1; viewer.tx = 0; viewer.ty = 0; }
      else clampViewer();
      applyViewer(false);
    }, { passive: false });

    window.addEventListener('resize', function () {
      if (!viewer.open) return;
      if (viewer.scale <= 1.01) { viewer.tx = 0; viewer.ty = 0; }
      else clampViewer();
      applyViewer(false);
    });

    stage.addEventListener('dragstart', function (e) { e.preventDefault(); });
  }

  // ============================================
  // KEEPING THE PAGE CURRENT
  // ============================================
  // A Mini App is not a page load — it can sit open in the background for
  // hours and come back showing whatever the catalogue looked like when it
  // was opened. Two answers, in this order:
  //
  //   the app refreshes itself on return, because it knows it went away
  //   the person can pull the list down, because sometimes they just want to
  //
  // The first is the one that matters; the second is the escape hatch, and
  // exists because people reach for it whether or not it is needed.

  var STALE_AFTER = 60000;      // ms in the background before it is worth a refetch
  var hiddenAt = 0;
  var refreshPending = false;   // went stale behind an open dialog

  function initFreshness() {
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) { hiddenAt = Date.now(); return; }
      if (!hiddenAt || Date.now() - hiddenAt < STALE_AFTER) return;
      hiddenAt = 0;
      // Never pull content out from under an open dialog; do it on close.
      if (!$('sheetBackdrop').hidden) { refreshPending = true; return; }
      refreshCurrentView({ quiet: true });
    });
  }

  function refreshAfterDialog() {
    if (!refreshPending) return;
    refreshPending = false;
    refreshCurrentView({ quiet: true });
  }

  // Pull to refresh. Only from the very top of the list, so it never competes
  // with the scroll; the indicator follows the finger and commits past the
  // threshold, so the gesture shows its own outcome before it completes.
  var PULL_TRIGGER = 72;        // px held at rest to commit
  var PULL_MAX = 110;           // px the indicator travels
  var PULL_SLOP = 8;

  function initPullRefresh() {
    var scroll = $('bzScroll');
    var pill = $('bzRefresh');
    if (!scroll || !pill) return;

    var startY = 0, dy = 0, pointer = null;
    var armed = false, active = false, running = false;

    // The indicator is fixed to the viewport, so it has to be told where to
    // sit. It hangs off the bottom edge of the sticky header — measured, not
    // assumed, because that header is a different height in a category than
    // on the front page — and rides down from behind it as the list is
    // pulled. Anchored to the scroll container instead it would ride down
    // over the title.
    function anchor() {
      var head = $('bzSticky');
      var edge = head ? head.getBoundingClientRect().bottom
                      : scroll.getBoundingClientRect().top;
      pill.style.setProperty('--anchor', Math.round(edge) + 'px');
    }
    anchor();
    window.addEventListener('resize', anchor);

    function place(distance) {
      var travel = Math.min(PULL_MAX, distance);
      pill.style.setProperty('--pull', travel + 'px');
      pill.style.setProperty('--pull-in', String(Math.min(1, distance / PULL_TRIGGER)));
      pill.classList.toggle('is-ready', distance >= PULL_TRIGGER);
    }

    function reset() {
      pill.classList.remove('is-visible', 'is-ready', 'is-running');
      pill.style.removeProperty('--pull');
      pill.style.removeProperty('--pull-in');
    }

    function run() {
      running = true;
      pill.classList.add('is-running');
      pill.classList.remove('is-ready');
      pill.style.setProperty('--pull', PULL_TRIGGER + 'px');
      pill.style.setProperty('--pull-in', '1');
      buzz('success');

      var done = false;
      function finish() {
        if (done) return;
        done = true;
        running = false;
        reset();
      }
      // The loaders do not report back, so the indicator is held for long
      // enough to read as a refresh and then released. Content swaps under it
      // the moment the answer lands.
      refreshCurrentView({ quiet: true });
      setTimeout(finish, 700);
    }

    function stop() {
      if (!armed) return;
      window.removeEventListener('pointermove', onMove, { passive: false });
      window.removeEventListener('pointerup', onUp);
      window.removeEventListener('pointercancel', onUp);
      armed = false;
      active = false;
      pointer = null;
      dy = 0;
    }

    function onMove(e) {
      if (!armed || e.pointerId !== pointer) return;
      dy = e.clientY - startY;
      if (dy <= 0) {
        if (active) { active = false; reset(); }
        return;
      }
      if (scroll.scrollTop > 0) { stop(); reset(); return; }
      if (!active) {
        if (dy < PULL_SLOP) return;
        active = true;
        pill.classList.add('is-visible');
      }
      if (e.cancelable) e.preventDefault();
      // Resistance, so the pull feels like it is pulling against something.
      place(Math.pow(dy, 0.85));
    }

    function onUp(e) {
      if (!armed || e.pointerId !== pointer) return;
      var committed = active && Math.pow(dy, 0.85) >= PULL_TRIGGER;
      stop();
      if (committed) run();
      else reset();
    }

    scroll.addEventListener('pointerdown', function (e) {
      if (running || armed) return;
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      if (scroll.scrollTop > 0) return;
      if (e.target.closest && e.target.closest('input, textarea')) return;
      anchor();
      armed = true;
      active = false;
      pointer = e.pointerId;
      startY = e.clientY;
      dy = 0;
      window.addEventListener('pointermove', onMove, { passive: false });
      window.addEventListener('pointerup', onUp);
      window.addEventListener('pointercancel', onUp);
    });
  }

  // ============================================
  // STICKY HEADER
  // ============================================
  // The header only draws its edge once something has scrolled under it.

  function initStickyState() {
    var scroll = $('bzScroll');
    var sticky = $('bzSticky');
    var stuck = false, queued = false;
    function measure() {
      queued = false;
      var next = scroll.scrollTop > 4;
      if (next === stuck) return;
      stuck = next;
      sticky.classList.toggle('is-stuck', stuck);
    }
    scroll.addEventListener('scroll', function () {
      if (queued) return;
      queued = true;
      requestAnimationFrame(measure);
    }, { passive: true });
  }

  // ============================================
  // INIT
  // ============================================

  // The markup ships with no Uzbek in it: the few static strings are written
  // in from the text file here, so there is exactly one place to edit.
  function applyStaticText() {
    document.title = t('header.pageTitle');
    $('bzTitle').textContent = t('header.pageTitle');
    $('bzBack').setAttribute('aria-label', t('common.back'));

    var search = $('bzSearch');
    search.placeholder = t('header.searchPlaceholder');
    search.setAttribute('aria-label', t('header.searchLabel'));
    $('bzSearchClear').setAttribute('aria-label', t('header.searchClear'));

    $('bzErrorTitle').textContent = t('pageError.title');
    $('bzErrorBody').textContent = t('pageError.body');
    $('bzRetry').textContent = t('common.retry');

    $('sheetClose').setAttribute('aria-label', t('common.close'));
    $('bzViewer').setAttribute('aria-label', t('viewer.label'));
    $('bzViewerClose').setAttribute('aria-label', t('common.close'));
  }

  function init() {
    applyStaticText();
    setBack(goHome);

    $('bzSearch').addEventListener('input', onSearchInput);
    $('bzSearch').addEventListener('keydown', function (e) {
      if (e.key === 'Enter') $('bzSearch').blur();
    });
    $('bzSearchClear').addEventListener('click', function () {
      clearTimeout(searchTimer);
      if (state.mode === 'search') leaveSearch();
      else { $('bzSearch').value = ''; $('bzSearchClear').hidden = true; }
      $('bzSearch').focus();
    });

    $('bzBack').addEventListener('click', function () { haptic('light'); currentBack()(); });
    $('bzRetry').addEventListener('click', refreshCurrentView);

    $('sheetBackdrop').addEventListener('click', function (e) {
      if (e.target === $('sheetBackdrop')) closeSheet();
    });
    $('sheetClose').addEventListener('click', function () { haptic('light'); closeSheet(); });
    $('sheet').addEventListener('click', function (e) { e.stopPropagation(); });
    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      if (viewer.open) closeViewer();
      else closeSheet();
    });

    initSheetDrag();
    initViewer();
    initStickyState();
    initFreshness();
    initPullRefresh();
    syncChrome();
    loadCategories();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
