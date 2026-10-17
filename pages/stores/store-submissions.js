// ============================================
// store-submissions.js — "My Submissions" tab
// Fetches user's submissions, renders list, filters by verdict,
// handles delete (with confirm modal). Edit is triggered here but
// handled by a future edit module (M7).
//
// Depends on: window.StoreUI, window.StoreAppActions
// Exposes:    window.StoreSubmissions
// ============================================

window.StoreSubmissions = (() => {

  // ----- state -----
  let _submissions = [];
  let _filter = 'all';  // 'all' | 'halol' | 'shubhali' | 'harom'
  let _inflight = false;
  let _deleteTarget = null;   // product currently in delete confirm modal
  let _onEditRequest = null;  // set via init(); M7 wires a real handler

  const API_BASE = () => window._SC_API_BASE || '';
  const USER_ID  = () => (window.StoreAppActions && StoreAppActions.getUserId()) || '';

  // ============================================
  // INIT
  // ============================================
  function init(opts) {
    opts = opts || {};
    _onEditRequest = opts.onEditRequest || (() => {});

    // Filter chips
    const filters = document.getElementById('mineFilters');
    if (filters) {
      filters.addEventListener('click', (ev) => {
        const btn = ev.target.closest('.mine-filter');
        if (!btn) return;
        const f = btn.getAttribute('data-filter') || 'all';
        _setFilter(f);
      });
    }

    // Empty-state CTA → go to collect tab
    const cta = document.getElementById('mineEmptyCtaBtn');
    if (cta) {
      cta.addEventListener('click', () => {
        if (window.StoreUI) StoreUI.showTab('collect');
      });
    }

    // Delete modal buttons
    const del = _deleteModalEls();
    if (del.backdrop) del.backdrop.addEventListener('click', _closeDeleteModal);
    if (del.cancel)   del.cancel.addEventListener('click',   _closeDeleteModal);
    if (del.confirm)  del.confirm.addEventListener('click',  _performDelete);

    // List event delegation (edit/delete per row)
    const list = document.getElementById('mineList');
    if (list) {
      list.addEventListener('click', (ev) => {
        const actionBtn = ev.target.closest('.mine-card__action');
        if (!actionBtn) return;
        const pid = actionBtn.getAttribute('data-pid');
        const act = actionBtn.getAttribute('data-act');
        const row = _submissions.find(p => p.publicId === pid);
        if (!row) return;
        if (act === 'edit')   _requestEdit(row);
        if (act === 'delete') _openDeleteModal(row);
      });
    }
  }

  // ============================================
  // REFRESH (public)
  // ============================================
  async function refresh() {
    if (_inflight) return;
    _inflight = true;

    _showLoading();

    const uid = USER_ID();
    if (!uid) {
      _submissions = [];
      _render();
      _inflight = false;
      StoreUI.toast("Foydalanuvchi aniqlanmadi", 'error');
      return;
    }

    try {
      // Fetch BOTH sources in parallel — store_products and main products.
      // Each Promise resolves to its `products` array (or empty on individual failure).
      const [storeArr, mainArr] = await Promise.all([
        fetch(`${API_BASE()}/api/store/mine?userId=${encodeURIComponent(uid)}`)
          .then(r => r.ok ? r.json() : { products: [] })
          .then(d => Array.isArray(d.products) ? d.products.map(p => ({ ...p, source: p.source || 'store' })) : [])
          .catch(() => []),
        fetch(`${API_BASE()}/api/scanner/mine?userId=${encodeURIComponent(uid)}`)
          .then(r => r.ok ? r.json() : { products: [] })
          .then(d => Array.isArray(d.products) ? d.products.map(p => ({ ...p, source: 'main' })) : [])
          .catch(() => []),
      ]);
      // Merge and sort by createdAt desc; nulls last.
      _submissions = [].concat(storeArr, mainArr).sort((a, b) => {
        const ta = a.createdAt ? Date.parse(a.createdAt) : 0;
        const tb = b.createdAt ? Date.parse(b.createdAt) : 0;
        return tb - ta;
      });
    } catch (e) {
      console.error('mine fetch failed:', e);
      _submissions = [];
      StoreUI.toast("Ro'yxatni yuklab bo'lmadi", 'error');
    }

    _render();
    _inflight = false;
  }

  // ============================================
  // RENDER
  // ============================================
  function _render() {
    const listEl    = document.getElementById('mineList');
    const emptyEl   = document.getElementById('mineEmpty');
    const loadingEl = document.getElementById('mineLoading');
    const countEl   = document.getElementById('mineCountText');

    if (loadingEl) loadingEl.style.display = 'none';

    const filtered = _applyFilter(_submissions, _filter);

    // Badge = total submissions (not filtered count)
    if (window.StoreUI) StoreUI.setMineBadge(_submissions.length);

    // Count text reflects what's visible
    if (countEl) {
      countEl.textContent = _submissions.length === 0
        ? '0 ta yozuv'
        : (filtered.length === _submissions.length
            ? `${_submissions.length} ta yozuv`
            : `${filtered.length} / ${_submissions.length} ta yozuv`);
    }

    if (_submissions.length === 0) {
      if (listEl)  listEl.innerHTML = '';
      if (emptyEl) emptyEl.style.display = 'block';
      return;
    }

    if (emptyEl) emptyEl.style.display = 'none';
    if (!listEl) return;

    if (filtered.length === 0) {
      listEl.innerHTML = `
        <div class="mine-filter-empty">
          <span>🔎</span>
          <p>Tanlangan filtr bo'yicha yozuv topilmadi.</p>
        </div>`;
      return;
    }

    listEl.innerHTML = filtered.map(_renderCard).join('');
  }

  function _renderCard(p) {
    const v = (StoreUI.VERDICT_LABELS && StoreUI.VERDICT_LABELS[p.verdict]) || { txt: p.verdict || '—', cls: 'joiz' };
    const cat = (StoreUI.CAT_LABELS && StoreUI.CAT_LABELS[p.category]) || p.category || '';
    const apiBase = API_BASE();
    let imgSrc = p.image || '';
    if (imgSrc && imgSrc.startsWith('/api/')) imgSrc = apiBase + imgSrc;

    const imgHtml = imgSrc
      ? `<img src="${_esc(imgSrc)}" alt="" loading="lazy" />`
      : '📦';

    return `
      <article class="mine-card mine-card--${v.cls}">
        <div class="mine-card__img">${imgHtml}</div>
        <div class="mine-card__body">
          <div class="mine-card__top">
            <span class="mine-card__store${p.source === 'main' ? ' mine-card__store--main' : ''}">${_esc(p.store)}</span>
            <span class="mine-card__verdict mine-card__verdict--${v.cls}">${v.txt}</span>
          </div>
          <p class="mine-card__cat">${_esc(cat)}</p>
          <code class="mine-card__barcode">${_esc(p.barcode)}</code>
          <span class="mine-card__date">${_esc(_formatDate(p.createdAt))}</span>
        </div>
        <div class="mine-card__actions">
          <button class="mine-card__action" data-act="edit" data-pid="${_esc(p.publicId)}" title="Tahrirlash">✏️</button>
          <button class="mine-card__action mine-card__action--delete" data-act="delete" data-pid="${_esc(p.publicId)}" title="O'chirish">🗑️</button>
        </div>
      </article>
    `;
  }

  function _showLoading() {
    const listEl    = document.getElementById('mineList');
    const emptyEl   = document.getElementById('mineEmpty');
    const loadingEl = document.getElementById('mineLoading');
    if (listEl)    listEl.innerHTML = '';
    if (emptyEl)   emptyEl.style.display = 'none';
    if (loadingEl) loadingEl.style.display = 'block';
  }

  // ============================================
  // FILTER
  // ============================================
  function _setFilter(f) {
    _filter = f;
    document.querySelectorAll('.mine-filter').forEach(b => {
      b.classList.toggle('mine-filter--active', b.getAttribute('data-filter') === f);
    });
    _render();
  }

  function _applyFilter(arr, f) {
    if (!f || f === 'all') return arr;
    return arr.filter(p => p.verdict === f);
  }

  // ============================================
  // EDIT (request → delegate to M7 handler)
  // ============================================
  function _requestEdit(product) {
    // Main-DB rows don't have an edit UI in the user app — only the admin
    // panel can edit them. Toast and bail.
    if (product && product.source === 'main') {
      StoreUI.toast("Asosiy bazadagi yozuvlarni faqat admin tahrirlay oladi", 'info');
      return;
    }
    if (typeof _onEditRequest === 'function') {
      _onEditRequest(product);
    } else {
      StoreUI.toast("Tahrirlash M7-bosqichda ulanadi", 'info');
    }
  }

  // ============================================
  // DELETE FLOW
  // ============================================
  function _deleteModalEls() {
    return {
      root:     document.getElementById('deleteModal'),
      backdrop: document.getElementById('deleteBackdrop'),
      preview:  document.getElementById('deletePreview'),
      cancel:   document.getElementById('deleteCancelBtn'),
      confirm:  document.getElementById('deleteConfirmBtn'),
    };
  }

  function _openDeleteModal(product) {
    _deleteTarget = product;
    const el = _deleteModalEls();
    if (el.preview && window.StoreUI) {
      el.preview.innerHTML = StoreUI.buildProductPreview(product, { compact: true });
    }
    if (el.root) el.root.style.display = 'flex';
    if (el.confirm) el.confirm.disabled = false;
  }

  function _closeDeleteModal() {
    _deleteTarget = null;
    const el = _deleteModalEls();
    if (el.root) el.root.style.display = 'none';
  }

  async function _performDelete() {
    if (!_deleteTarget) return;
    const pid = _deleteTarget.publicId;
    const uid = USER_ID();

    const el = _deleteModalEls();
    if (el.confirm) el.confirm.disabled = true;

    try {
      const isMain = _deleteTarget.source === 'main';
      const url = isMain
        ? `${API_BASE()}/api/scanner/product/${encodeURIComponent(pid)}?userId=${encodeURIComponent(uid)}`
        : `${API_BASE()}/api/store/product/${encodeURIComponent(pid)}?userId=${encodeURIComponent(uid)}`;
      const resp = await fetch(url, { method: 'DELETE' });
      const data = await resp.json().catch(() => ({}));

      if (resp.ok && data.success) {
        // Optimistic local removal
        _submissions = _submissions.filter(p => p.publicId !== pid);
        _closeDeleteModal();
        _render();
        StoreUI.toast("Yozuv o'chirildi", 'success');
        return;
      }

      let msg = data.error || "O'chirib bo'lmadi";
      if (resp.status === 403) msg = "Bu yozuvni faqat uni qo'shgan foydalanuvchi o'chira oladi.";
      if (resp.status === 404) msg = "Yozuv topilmadi. U allaqachon o'chirilgan bo'lishi mumkin.";
      StoreUI.toast(msg, 'error');

      // 404 → remove from local list anyway
      if (resp.status === 404) {
        _submissions = _submissions.filter(p => p.publicId !== pid);
        _render();
      }
      _closeDeleteModal();
    } catch (e) {
      console.error('delete failed:', e);
      StoreUI.toast("Ulanish xatoligi", 'error');
      if (el.confirm) el.confirm.disabled = false;
    }
  }

  // ============================================
  // LOCAL CACHE HOOKS (used by M7 after edits, and by app after add)
  // ============================================
  function addLocal(product) {
    if (!product || !product.publicId) return;
    _submissions = [product].concat(_submissions.filter(p => p.publicId !== product.publicId));
    if (window.StoreUI) StoreUI.setMineBadge(_submissions.length);
  }

  function updateLocal(product) {
    if (!product || !product.publicId) return;
    const i = _submissions.findIndex(p => p.publicId === product.publicId);
    if (i >= 0) _submissions[i] = product;
    else _submissions.unshift(product);
    if (_isPaneVisible()) _render();
  }

  function _isPaneVisible() {
    const pane = document.getElementById('paneMine');
    return pane && pane.style.display !== 'none';
  }

  // ============================================
  // HELPERS
  // ============================================
  function _esc(s) {
    const d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
  }

  function _formatDate(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '';
    const now = new Date();
    const diffMs = now - d;
    const min = Math.floor(diffMs / 60000);
    if (min < 1)  return 'hozirgina';
    if (min < 60) return `${min} daqiqa oldin`;
    const hr = Math.floor(min / 60);
    if (hr < 24)  return `${hr} soat oldin`;
    const day = Math.floor(hr / 24);
    if (day < 7)  return `${day} kun oldin`;
    // Older: dd.mm.yyyy
    const dd = String(d.getDate()).padStart(2, '0');
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    return `${dd}.${mm}.${d.getFullYear()}`;
  }

  // ============================================
  // EXPORT
  // ============================================
  return {
    init,
    refresh,
    addLocal,
    updateLocal,
    getAll: () => _submissions.slice(),
  };
})();
