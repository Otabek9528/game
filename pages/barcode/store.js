// store.js — Store detail page controller (M3)
// Loads store metadata, renders verdict tabs + category chips + product grid.
// Paginated. Reuses the product modal from barcode.html.
// Launches scanner in store-scoped mode via store.html?id=X → barcode.html?store=X
// ============================================

(function () {

  // --- Telegram ---
  const tg = (window.Telegram && window.Telegram.WebApp) || null;
  try { tg && tg.ready(); } catch (e) {}
  try { tg && tg.expand(); } catch (e) {}
  try { tg && tg.disableVerticalSwipes && tg.disableVerticalSwipes(); } catch (e) {}
  try {
    if (tg && tg.BackButton) {
      tg.BackButton.show();
      tg.BackButton.onClick(() => _handleBack());
    }
  } catch (e) {}

  // --- API base ---
  const API_BASE = window.location.hostname === 'localhost'
    ? 'http://localhost:5001'
    : 'https://vegukin-api.duckdns.org';
  window._API_BASE = API_BASE;

  // --- Emblem filenames ---
  const EMBLEM_FILES = {
    'No Brand':  'nobrand.png',
    'Emart24':   'emart24.png',
    '7-Eleven':  '7_11.png',
    'GS25':      'gs25.png',
    'CU':        'cu.png',
    'Daiso':     'daiso.png'
  };

  const PAGE_LIMIT = 20;

  // --- i18n helper ---
  function t(key, fallback) {
    try {
      if (window.I18N && typeof window.I18N.t === 'function') {
        const v = window.I18N.t(key);
        if (v && v !== key) return v;
      }
    } catch (e) {}
    return fallback != null ? fallback : key;
  }

  function esc(s) {
    const d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
  }

  // =============================================================
  // STATE
  // =============================================================
  const state = {
    store:    null,            // "GS25" etc.
    verdict:  'joiz',          // active verdict tab
    category: '',              // active category chip ("" = all)
    meta:     null,            // /api/v2/store/<store> response
    offset:   0,
    total:    0,
    products: [],              // accumulated products for current filter
    loading:  false,
  };

  // =============================================================
  // INIT
  // =============================================================
  document.addEventListener('DOMContentLoaded', async () => {
    if (window.I18N) window.I18N.init();
    _applyI18n();

    const params = new URLSearchParams(window.location.search);
    state.store = params.get('id') || '';
    if (!state.store) {
      window.location.href = 'barcode.html';
      return;
    }
    // Optional deep-link params
    const v = (params.get('verdict') || '').toLowerCase();
    if (['joiz', 'shubhali', 'nojoiz'].includes(v)) state.verdict = v;
    const c = params.get('category') || '';
    if (c) state.category = c;

    _renderHero();
    _bindVerdictTabs();
    _bindCatPanelToggle();
    _bindLoadMore();
    _bindModalClose();
    _bindFullscreen();
    _bindBackHistory();

    await _loadMeta();
    await _loadProducts(true);

    window.addEventListener('languageChanged', () => {
      _applyI18n();
      _renderChips();   // labels depend on i18n
      _renderGrid();    // empty-state labels etc.
    });
  });

  // =============================================================
  // HERO
  // =============================================================
  function _renderHero() {
    const file = EMBLEM_FILES[state.store];
    const emblem = document.getElementById('storeHeroEmblem');
    if (file) {
      emblem.src = `../../assets/stores/${file}`;
      emblem.alt = state.store;
    } else {
      emblem.style.display = 'none';
    }
    emblem.onerror = () => { emblem.style.display = 'none'; };
    document.getElementById('storeHeroName').textContent = state.store;
  }

  // =============================================================
  // META (counts for tabs + chips)
  // =============================================================
  async function _loadMeta() {
    try {
      const url = `${API_BASE}/api/v2/store/${encodeURIComponent(state.store)}`;
      const resp = await fetch(url);
      const data = await resp.json();
      state.meta = data;

      document.getElementById('storeHeroCount').textContent = data.total || 0;

      const v = data.byVerdict || {};
      document.getElementById('tabCountJoiz').textContent     = v.joiz     || 0;
      document.getElementById('tabCountShubhali').textContent = v.shubhali || 0;
      document.getElementById('tabCountNojoiz').textContent   = v.nojoiz   || 0;

      _renderChips();
      _syncVerdictTabsActive();
    } catch (err) {
      console.error('Meta fetch failed:', err);
      document.getElementById('storeHeroCount').textContent = '—';
    }
  }

  // =============================================================
  // CATEGORY PANEL (M9) — grid + collapsible
  // =============================================================
  const CAT_ICONS = {
    'Drinks':            '🥤',
    'Snacks':            '🍿',
    'Sweets':            '🍬',
    'Ice Cream':         '🍦',
    'Baked Goods':       '🥐',
    'Cup Noodles/Ramen': '🍜',
    'Lunchbox/Dosirak':  '🍩',
    'Dairy':             '🥛',
    'Canned Food':       '🥫',
    'Frozen Food':       '🧊',
    'Condiments/Sauces': '🧂',
    'Fruits/Vegetables': '🥗',
    'Dried Food':        '🌾',
  };

  function _renderChips() {
    const grid = document.getElementById('catPanelGrid');
    const activeLabel = document.getElementById('catPanelActiveLabel');
    if (!grid) return;
    const meta = state.meta || { byCategory: [] };

    const v = meta.byVerdict || {};
    const allCount = v[state.verdict] || 0;

    const items = [
      { category: '', icon: '🗂', label: t('bc.store.allCats', 'Hammasi'), count: allCount, active: !state.category },
      ...(meta.byCategory || [])
        .map(cat => {
          const count = (cat.byVerdict || {})[state.verdict] || 0;
          return {
            category: cat.category,
            icon:     CAT_ICONS[cat.category] || '📦',
            label:    t('bc.cat.' + cat.category, cat.category),
            count,
            active:   cat.category === state.category,
          };
        })
        .filter(it => it.count > 0),
    ];

    grid.innerHTML = items.map(it => `
      <button class="cat-tile ${it.active ? 'is-active' : ''}"
              data-category="${esc(it.category)}" type="button">
        <span class="cat-tile__icon">${it.icon}</span>
        <span class="cat-tile__label">${esc(it.label)}</span>
        <span class="cat-tile__count">${it.count}</span>
      </button>
    `).join('');

    // Update toggle label to reflect active filter
    const activeItem = items.find(it => it.active);
    if (activeLabel && activeItem) {
      activeLabel.textContent = activeItem.label;
    }

    grid.querySelectorAll('.cat-tile').forEach(tile => {
      tile.addEventListener('click', () => {
        const cat = tile.getAttribute('data-category') || '';
        if (cat === state.category) return;
        state.category = cat;
        grid.querySelectorAll('.cat-tile').forEach(c => c.classList.remove('is-active'));
        tile.classList.add('is-active');
        if (activeLabel) {
          const t2 = tile.querySelector('.cat-tile__label');
          if (t2) activeLabel.textContent = t2.textContent;
        }
        // Auto-collapse after a selection (clean UX)
        _setCatPanelOpen(false);
        _resetAndReload();
      });
    });
  }

  function _setCatPanelOpen(open) {
    const grid = document.getElementById('catPanelGrid');
    const toggle = document.getElementById('catPanelToggle');
    const chev = document.getElementById('catPanelChev');
    if (!grid || !toggle) return;
    if (open) {
      grid.hidden = false;
      grid.classList.add('is-open');
      toggle.setAttribute('aria-expanded', 'true');
      if (chev) chev.textContent = '▴';
    } else {
      grid.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
      if (chev) chev.textContent = '▾';
      // Wait for transition before hidden
      setTimeout(() => {
        if (toggle.getAttribute('aria-expanded') === 'false') grid.hidden = true;
      }, 220);
    }
  }

  function _bindCatPanelToggle() {
    const toggle = document.getElementById('catPanelToggle');
    if (!toggle) return;
    toggle.addEventListener('click', () => {
      const open = toggle.getAttribute('aria-expanded') === 'true';
      _setCatPanelOpen(!open);
    });
  }

  // =============================================================
  // VERDICT TABS
  // =============================================================
  function _bindVerdictTabs() {
    document.querySelectorAll('.verdict-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        const v = tab.getAttribute('data-verdict');
        if (!v || v === state.verdict) return;
        state.verdict = v;
        state.category = ''; // reset category when switching verdict (chip counts differ)
        _syncVerdictTabsActive();
        _renderChips();
        _resetAndReload();
      });
    });
  }

  function _syncVerdictTabsActive() {
    document.querySelectorAll('.verdict-tab').forEach(tab => {
      const isActive = tab.getAttribute('data-verdict') === state.verdict;
      tab.classList.toggle('is-active', isActive);
      tab.setAttribute('aria-selected', isActive ? 'true' : 'false');
    });
  }

  // =============================================================
  // PRODUCT GRID + PAGINATION
  // =============================================================
  async function _resetAndReload() {
    state.offset = 0;
    state.products = [];
    state.total = 0;
    document.getElementById('storeGrid').innerHTML = _skeletonCards(6);
    document.getElementById('storeEmpty').style.display = 'none';
    document.getElementById('storeLoadMore').style.display = 'none';
    await _loadProducts(true);
  }

  async function _loadProducts(firstPage) {
    if (state.loading) return;
    state.loading = true;

    const qs = new URLSearchParams({
      verdict: state.verdict,
      offset:  String(state.offset),
      limit:   String(PAGE_LIMIT),
    });
    if (state.category) qs.set('category', state.category);

    const url = `${API_BASE}/api/v2/store/${encodeURIComponent(state.store)}/products?${qs}`;

    try {
      if (firstPage) {
        document.getElementById('storeGrid').innerHTML = _skeletonCards(6);
      }

      const resp = await fetch(url);
      const data = await resp.json();

      state.total = data.total || 0;
      const batch = Array.isArray(data.products) ? data.products : [];
      state.products = firstPage ? batch : state.products.concat(batch);
      state.offset = state.offset + batch.length;

      _renderGrid();

      const hasMore = data.hasMore && batch.length > 0;
      document.getElementById('storeLoadMore').style.display = hasMore ? 'block' : 'none';
    } catch (err) {
      console.error('Products fetch failed:', err);
      document.getElementById('storeGrid').innerHTML =
        `<p class="store-empty__title" style="grid-column:1/-1;text-align:center;padding:24px;color:var(--gray-400);">
          ${esc(t('bc.stores.loadError', "Mahsulotlar yuklanmadi"))}
        </p>`;
    } finally {
      state.loading = false;
    }
  }

  function _renderGrid() {
    const grid = document.getElementById('storeGrid');
    const empty = document.getElementById('storeEmpty');

    if (!state.products.length) {
      grid.innerHTML = '';
      empty.style.display = 'block';
      return;
    }
    empty.style.display = 'none';

    grid.innerHTML = state.products.map(p => _cardHtml(p)).join('');

    grid.querySelectorAll('.prod-card').forEach((card, i) => {
      card.addEventListener('click', () => _openProductModal(state.products[i]));
    });
  }

  function _cardHtml(p) {
    const v = (p.verdict || '').toLowerCase();
    const verdictClass = v === 'joiz' ? 'joiz' : v === 'nojoiz' ? 'nojoiz' : 'shubhali';
    const verdictEmoji = v === 'joiz' ? '✅' : v === 'nojoiz' ? '⛔' : '⚠️';

    let img = p.image || '';
    if (img && img.startsWith('/api/')) img = API_BASE + img;

    const name = p.name || p.nameEnglish || p.barcode || '—';
    const category = p.category ? esc(t('bc.cat.' + p.category, p.category)) : '';

    return `
      <div class="prod-card prod-card--${verdictClass}" data-barcode="${esc(p.barcode)}">
        <div class="prod-card__img-wrap">
          ${img
            ? `<img class="prod-card__img" src="${esc(img)}" alt="" loading="lazy"
                     onerror="this.parentNode.innerHTML='<div class=&quot;prod-card__noimg&quot;>📦</div>';" />`
            : `<div class="prod-card__noimg">📦</div>`
          }
          <span class="prod-card__verdict">${verdictEmoji}</span>
        </div>
        <div class="prod-card__body">
          ${category ? `<span class="prod-card__cat">${category}</span>` : ''}
          <p class="prod-card__name">${esc(name)}</p>
        </div>
      </div>
    `;
  }

  function _skeletonCards(n) {
    let out = '';
    for (let i = 0; i < n; i++) {
      out += `
        <div class="prod-card prod-card--skel" aria-hidden="true">
          <div class="prod-card__img-wrap prod-card__img-wrap--skel"></div>
          <div class="prod-card__body">
            <div class="prod-card__cat-skel"></div>
            <div class="prod-card__name-skel"></div>
          </div>
        </div>`;
    }
    return out;
  }

  function _bindLoadMore() {
    document.getElementById('loadMoreBtn').addEventListener('click', () => _loadProducts(false));
  }

  // =============================================================
  // PRODUCT MODAL — reused from barcode.html markup
  // =============================================================
  function _openProductModal(p) {
    const modal = document.getElementById('productModal');
    const v = (p.verdict || '').toLowerCase();
    const verdictConf = {
      joiz:     { emoji: '✅', cls: 'joiz',        labelKey: 'bc.verdictJoiz',        labelFb: 'Joiz' },
      shubhali: { emoji: '⚠️', cls: 'shubhali',    labelKey: 'bc.verdictShubhali',    labelFb: 'Shubhali' },
      nojoiz:   { emoji: '⛔', cls: 'taqiqlangan', labelKey: 'bc.verdictTaqiqlangan', labelFb: "Ta'qiqlangan" }
    }[v] || { emoji: '✅', cls: 'joiz', labelKey: 'bc.verdictJoiz', labelFb: 'Joiz' };

    const verdictEl = document.getElementById('modalVerdict');
    verdictEl.className = `modal-verdict modal-verdict--${verdictConf.cls}`;
    document.getElementById('modalVerdictEmoji').textContent = verdictConf.emoji;
    document.getElementById('modalVerdictLabel').textContent = t(verdictConf.labelKey, verdictConf.labelFb);

    let img = p.image || '';
    if (img && img.startsWith('/api/')) img = API_BASE + img;
    const imgWrap = document.getElementById('modalImgWrap');
    const modalImg = document.getElementById('modalImg');
    if (img) { modalImg.src = img; imgWrap.style.display = 'block'; }
    else { imgWrap.style.display = 'none'; }

    document.getElementById('modalName').textContent = p.name || p.nameEnglish || '—';
    document.getElementById('modalBarcode').textContent = p.barcode || '—';

    _renderModalHalalGrid(p);
    _renderModalFactory(p);

    const ingrBox = document.getElementById('modalIngredients');
    if (p.ingredients) {
      document.getElementById('modalIngredientsText').textContent = p.ingredients;
      ingrBox.style.display = 'block';
    } else {
      ingrBox.style.display = 'none';
    }

    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
    _pushState('modal');
  }

  function _renderModalHalalGrid(data) {
    const grid = document.getElementById('modalHalalGrid');
    const checks = [
      { icon: '🐖', labelKey: 'bc.flag.pork',    fb: "Choʻchqa",          bad: !!data.pork },
      { icon: '🍷', labelKey: 'bc.flag.alcohol', fb: 'Alkogol',           bad: !!data.alcohol },
      { icon: '🍗', labelKey: 'bc.grid.meat',    fb: "Goʻsht",            bad: !!data.meat },
      { icon: '🦐', labelKey: 'bc.grid.seafood', fb: 'Dengiz mahsulotlari', bad: !!data.seafood }
    ];
    grid.innerHTML = '';
    checks.forEach(c => {
      const ok = !c.bad;
      const el = document.createElement('div');
      el.className = `halal-cell ${ok ? 'halal-cell--ok' : 'halal-cell--bad'}`;
      el.innerHTML = `
        <span class="halal-cell__icon">${c.icon}</span>
        <div class="halal-cell__info">
          <span class="halal-cell__name">${esc(t(c.labelKey, c.fb))}</span>
          <span class="halal-cell__tag">${ok ? '✅ ' + esc(t('bc.absent', 'yoʻq')) : '❌ ' + esc(t('bc.present', 'bor'))}</span>
        </div>`;
      grid.appendChild(el);
    });
  }

  function _renderModalFactory(data) {
    const box = document.getElementById('modalFactory');
    if (data.sameFactory === undefined || data.sameFactory === null) {
      box.style.display = 'none';
      return;
    }
    box.className = `modal-factory ${data.sameFactory ? 'modal-factory--warn' : 'modal-factory--ok'}`;
    document.getElementById('modalFactoryIcon').textContent = data.sameFactory ? '🏭' : '✅';
    document.getElementById('modalFactoryText').textContent = data.sameFactory
      ? t('bc.factoryWarn',  'Harom mahsulotlar bilan bir zavodda ishlab chiqarilgan')
      : t('bc.factoryOk',    'Alohida zavodda ishlab chiqarilgan');
    box.style.display = 'flex';
  }

  function _hideProductModal() {
    document.getElementById('productModal').style.display = 'none';
    document.body.style.overflow = '';
  }

  function _bindModalClose() {
    document.getElementById('modalCloseBtn').addEventListener('click', _hideProductModal);
    document.getElementById('modalBackdrop').addEventListener('click', _hideProductModal);
  }

  // =============================================================
  // FULLSCREEN IMAGE (tap modal image to expand)
  // =============================================================
  function _bindFullscreen() {
    const viewer = document.getElementById('fullscreenViewer');
    const viewerImg = document.getElementById('fullscreenImg');
    const closeBtn = document.getElementById('fullscreenClose');

    document.getElementById('modalImg').addEventListener('click', () => {
      const src = document.getElementById('modalImg').src;
      if (!src) return;
      viewerImg.src = src;
      viewer.classList.add('active');
      document.body.style.overflow = 'hidden';
    });

    function close() {
      viewer.classList.remove('active');
      viewerImg.src = '';
      const modal = document.getElementById('productModal');
      if (!modal || modal.style.display === 'none') {
        document.body.style.overflow = '';
      }
    }
    closeBtn.addEventListener('click', close);
    viewer.addEventListener('click', (e) => {
      if (e.target === viewer) close();
    });
  }

  // =============================================================
  // BACK NAVIGATION
  // =============================================================
  function _bindBackHistory() {
    _pushState('store');
    window.addEventListener('popstate', () => {
      _pushState('back');
      _handleBack();
    });
  }

  function _pushState(label) {
    try { history.pushState({ page: label }, '', ''); } catch (e) {}
  }

  function _handleBack() {
    const modal = document.getElementById('productModal');
    if (modal && modal.style.display !== 'none') {
      _hideProductModal();
      return;
    }
    const viewer = document.getElementById('fullscreenViewer');
    if (viewer && viewer.classList.contains('active')) {
      viewer.classList.remove('active');
      return;
    }
    window.location.href = 'barcode.html';
  }

  // =============================================================
  // i18n apply
  // =============================================================
  function _applyI18n() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const val = t(key, null);
      if (val && val !== key) {
        if (el.tagName === 'TITLE') document.title = val;
        else el.textContent = val;
      }
    });
  }

})();