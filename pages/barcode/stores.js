// stores.js — Landing page store cards module
// Fetches /api/v2/stores and renders a grid of store cards.
// Stores with count < 10 get grayed out. Tapping navigates to store detail page.
// Exposes: window.Stores
// ============================================

window.Stores = (() => {

  const LOW_COUNT_THRESHOLD = 10;

  // Filename map (exact filenames you provided)
  const EMBLEM_FILES = {
    'No Brand':  'nobrand.png',
    'Emart24':   'emart24.png',
    '7-Eleven':  '7_11.png',
    'GS25':      'gs25.png',
    'CU':        'cu.png',
    'Daiso':     'daiso.png'
  };

  function _t(key, fallback) {
    try {
      if (window.I18N && typeof window.I18N.t === 'function') {
        const v = window.I18N.t(key);
        if (v && v !== key) return v;
      }
    } catch (e) {}
    return fallback;
  }

  function _emblemSrc(store) {
    const file = EMBLEM_FILES[store] || '';
    return `../../assets/stores/${file}`;
  }

  function _escHtml(s) {
    const d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
  }

  // ============================================
  // FETCH & RENDER
  // ============================================

  async function load() {
    const grid = document.getElementById('storesGrid');
    if (!grid) return;

    grid.innerHTML = _skeletonHtml();

    try {
      const apiBase = window._API_BASE || '';
      const resp = await fetch(`${apiBase}/api/v2/stores`);
      const data = await resp.json();
      const stores = Array.isArray(data.stores) ? data.stores : [];
      _render(grid, stores);
    } catch (err) {
      console.error('Stores fetch failed:', err);
      grid.innerHTML = `<p class="stores__error">${_escHtml(_t('bc.stores.loadError', 'Do\'konlar yuklanmadi'))}</p>`;
    }
  }

  function _skeletonHtml() {
    let out = '';
    for (let i = 0; i < 6; i++) {
      out += `<div class="store-card store-card--skeleton" aria-hidden="true">
        <div class="store-card__emblem-wrap"></div>
        <div class="store-card__body">
          <div class="store-card__name-skel"></div>
          <div class="store-card__count-skel"></div>
        </div>
      </div>`;
    }
    return out;
  }

  function _render(grid, stores) {
    if (!stores.length) {
      grid.innerHTML = `<p class="stores__empty">${_escHtml(_t('bc.stores.empty', 'Hozircha do\'konlar mavjud emas'))}</p>`;
      return;
    }

    const productLabel = _t('bc.stores.products', 'ta mahsulot');
    const soonLabel    = _t('bc.stores.soon', 'Yaqinda');

    grid.innerHTML = stores.map(s => {
      const isLow = s.count < LOW_COUNT_THRESHOLD;
      const classes = ['store-card'];
      if (isLow) classes.push('store-card--low');

      const soonBadge = isLow
        ? `<span class="store-card__soon">${_escHtml(soonLabel)}</span>`
        : '';

      return `
        <button class="${classes.join(' ')}" data-store="${_escHtml(s.store)}" type="button">
          <div class="store-card__emblem-wrap">
            <img class="store-card__emblem"
                 src="${_emblemSrc(s.store)}"
                 alt="${_escHtml(s.store)}"
                 loading="lazy"
                 onerror="this.style.display='none'" />
          </div>
          <div class="store-card__body">
            <span class="store-card__name">${_escHtml(s.store)}</span>
            <span class="store-card__count">
              <strong>${s.count}</strong> ${_escHtml(productLabel)}
            </span>
          </div>
          ${soonBadge}
        </button>
      `;
    }).join('');

    // Bind taps
    grid.querySelectorAll('.store-card').forEach(btn => {
      btn.addEventListener('click', () => {
        const store = btn.getAttribute('data-store');
        _navigateToStore(store);
      });
    });
  }

  // Hardcoded to mirror logger.js — avoids race with app.js setting window._API_BASE.
  const LOG_ENDPOINT = 'https://vegukin-api.duckdns.org/api/log-interaction';

  function _logStoreOpen(store) {
    try {
      const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
      if (!tgUser) return;
      const payload = JSON.stringify({
        user_id: tgUser.id,
        username: tgUser.username || tgUser.first_name || 'unknown',
        action: `store_opened:${store}`
      });
      // Use keepalive fetch only — preserves Content-Type: application/json,
      // which Flask's request.get_json() requires. sendBeacon sends text/plain
      // by default and Flask returns None from get_json(), causing a 500.
      fetch(LOG_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: payload,
        keepalive: true
      }).catch(() => {});
    } catch (e) {}
  }

  function _navigateToStore(store) {
    if (!store) return;
    _logStoreOpen(store);
    // Guard so logger.js autoLog() won't re-log 'barcode' when user returns
    // from store.html -> barcode.html. autoLog() consumes the key once.
    try { sessionStorage.setItem('logged_barcode', '1'); } catch (e) {}
    const url = `store.html?id=${encodeURIComponent(store)}`;
    window.location.href = url;
  }

  return { load };
})();
