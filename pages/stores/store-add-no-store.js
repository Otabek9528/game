// ============================================
// store-add-no-store.js — No-store add flow (writes to main products table)
//
// SELF-CONTAINED MODULE — does not touch StoreApp, StoreForm, or StoreSubmissions.
// Owns its own state machine, its own DOM section, its own submit endpoint.
//
// Triggered by: a single button in the store picker (data-store="__NOSTORE__")
// Endpoint:     POST /api/scanner/product/add
//
// States (under <div id="paneNoStore">):
//   nsPermission → nsScanner → nsForm → nsSubmitting → nsSuccess | nsError | nsDuplicate
//
// Depends on the global window.Camera + window.Scanner already loaded by the main app.
// Depends on window.StoreUtils for compression + fetchJson if present.
//
// Exposes: window.StoreNoStore
// ============================================

window.StoreNoStore = (() => {

  // ----- state -----
  let _initialized = false;
  let _active = false;            // true while our flow owns the screen
  let _barcode = '';
  let _category = null;
  let _flags = {
    pork: false, alcohol: false, meat: false,
    seafood: false, factory: false, allhalal: false, ambiguous: false
  };
  let _photoBlob = null;
  let _photoObjectUrl = null;
  let _scanning = false;

  // Hooks to restore the host page when we close.
  let _onClose = null;

  const API_BASE = () => window._SC_API_BASE || window._API_BASE || '';
  const USER_ID  = () =>
    (window.StoreAppActions && StoreAppActions.getUserId && StoreAppActions.getUserId()) ||
    _readTelegramUserId() || '';

  function _readTelegramUserId() {
    try {
      const u = window.Telegram && window.Telegram.WebApp
                && window.Telegram.WebApp.initDataUnsafe
                && window.Telegram.WebApp.initDataUnsafe.user;
      return u ? String(u.id) : '';
    } catch (e) { return ''; }
  }

  // ============================================
  // INIT
  // ============================================
  function init(opts) {
    if (_initialized) return;
    opts = opts || {};
    _onClose = opts.onClose || _defaultClose;

    _bindGlobalControls();
    _bindForm();
    _initialized = true;
  }

  function _defaultClose() {
    // Default: return to the store picker on the existing pane
    const pane = document.getElementById('paneNoStore');
    if (pane) pane.style.display = 'none';
    if (window.StoreUI && StoreUI.showState) StoreUI.showState('stateStorePicker');
  }

  // ============================================
  // PUBLIC ENTRY
  // ============================================
  function open() {
    if (!_initialized) return;
    _active = true;
    _reset();
    _showPane();
    _showState('nsPermission');
  }

  function _showPane() {
    // Hide the host's collect-flow states by hiding paneCollect, show our pane.
    const paneCollect = document.getElementById('paneCollect');
    const paneNs      = document.getElementById('paneNoStore');
    if (paneCollect) paneCollect.style.display = 'none';
    if (paneNs)      paneNs.style.display = 'block';
  }

  function _hidePane() {
    _active = false;
    const paneNs      = document.getElementById('paneNoStore');
    const paneCollect = document.getElementById('paneCollect');
    if (paneNs)      paneNs.style.display = 'none';
    if (paneCollect) paneCollect.style.display = 'block';
  }

  // ============================================
  // STATE MACHINE
  // ============================================
  const STATES = ['nsPermission','nsScanner','nsForm','nsSubmitting','nsSuccess','nsError','nsDuplicate'];

  function _showState(id) {
    STATES.forEach(s => {
      const el = document.getElementById(s);
      if (el) el.style.display = (s === id) ? 'block' : 'none';
    });
  }

  // ============================================
  // GLOBAL CONTROLS (header / scanner toolbar / footers / close)
  // ============================================
  function _bindGlobalControls() {
    // Permission CTA
    _on('nsAllowCameraBtn', 'click', _startScanning);
    _on('nsCloseFromPermBtn', 'click', _close);

    // Scanner toolbar
    _on('nsTorchBtn',  'click', async () => {
      try { await Camera.toggleTorch(); } catch (e) {}
    });
    _on('nsCloseFromScanBtn', 'click', _close);

    // Manual barcode entry (fallback)
    _on('nsManualBtn', 'click', () => {
      const bc = prompt("Shtrix-kodni qo'lda kiriting:");
      if (bc && /^[A-Za-z0-9_-]+$/.test(bc.trim())) {
        _stopScanning();
        _onBarcodeFound(bc.trim());
      } else if (bc) {
        _toast("Noto'g'ri shtrix-kod formati", 'error');
      }
    });

    // Form footer
    _on('nsFormCancelBtn', 'click', _close);
    _on('nsFormSubmitBtn', 'click', _submit);

    // Success/Error/Duplicate footers
    _on('nsSuccessAnotherBtn',   'click', () => { _reset(); _showState('nsPermission'); });
    _on('nsSuccessCloseBtn',     'click', _close);
    _on('nsErrorRetryBtn',       'click', _submit);
    _on('nsErrorBackBtn',        'click', () => _showState('nsForm'));
    _on('nsDuplicateAnotherBtn', 'click', () => { _reset(); _showState('nsPermission'); });
    _on('nsDuplicateCloseBtn',   'click', _close);
  }

  function _on(id, ev, fn) {
    const el = document.getElementById(id);
    if (el) el.addEventListener(ev, fn);
  }

  // ============================================
  // SCANNING
  // ============================================
  async function _startScanning() {
    _showState('nsScanner');
    _updateStatus("Kamera ochilmoqda…");

    try {
      const video = document.getElementById('nsVideo');
      const info = await Camera.open(video);
      _toggleTorchBtn(info.hasTorch);

      if (Scanner.init) { try { await Scanner.init(); } catch (e) {} }
      _updateStatus("Shtrix-kod qidirilmoqda…");
      _scanning = true;
      Scanner.start(video, _onBarcodeFound);
    } catch (e) {
      console.error('Camera open failed (no-store):', e);
      _showError("Kameraga kirish rad etildi",
                 "Sozlamalardan kameraga ruxsat berib, qaytadan urinib ko'ring.");
    }
  }

  function _stopScanning() {
    if (_scanning) {
      try { Scanner.stop(); Scanner.resetLastScanned && Scanner.resetLastScanned(); } catch (e) {}
      _scanning = false;
    }
  }

  function _onBarcodeFound(code /*, format */) {
    _stopScanning();
    _barcode = String(code).trim();
    _openForm();
  }

  function _updateStatus(text) {
    const el = document.getElementById('nsScanStatus');
    if (el) el.textContent = text;
  }

  function _toggleTorchBtn(visible) {
    const el = document.getElementById('nsTorchBtn');
    if (el) el.style.display = visible ? 'inline-flex' : 'none';
  }

  // ============================================
  // FORM
  // ============================================
  function _openForm() {
    const bcEl = document.getElementById('nsBarcodeShow');
    if (bcEl) bcEl.textContent = _barcode;

    _redrawAllFlagVisuals();
    _clearCategoryVisual();
    _showPhotoEmpty();
    _updateSubmitEnabled();
    _showState('nsForm');
  }

  function _bindForm() {
    // Category grid (delegation)
    const grid = document.getElementById('nsCategoryGrid');
    if (grid) {
      grid.addEventListener('click', (ev) => {
        const chip = ev.target.closest('.cat-chip');
        if (!chip) return;
        _category = chip.getAttribute('data-cat');
        _setCategoryVisual(_category);
        _updateSubmitEnabled();
      });
    }

    // Flag toggles
    document.querySelectorAll('#nsForm .flag-toggle[data-flag]').forEach(el => {
      el.addEventListener('click', () => {
        const name = el.getAttribute('data-flag');
        _toggleFlag(name);
      });
    });

    // Photo controls
    _on('nsOpenPhotoBtn',   'click', _openPhotoCapture);
    _on('nsShutterBtn',     'click', _takePhoto);
    _on('nsCancelPhotoBtn', 'click', _cancelPhotoCapture);
    _on('nsRetakeBtn',      'click', _openPhotoCapture);
    _on('nsRemovePhotoBtn', 'click', _removePhoto);
  }

  function _toggleFlag(name) {
    if (name === 'allhalal') {
      const wasOn = _flags.allhalal;
      _flags = { pork: false, alcohol: false, meat: false, seafood: false, factory: false, allhalal: !wasOn, ambiguous: false };
      _redrawAllFlagVisuals();
      _updateSubmitEnabled();
      return;
    }
    if (_flags.allhalal) _flags.allhalal = false;
    _flags[name] = !_flags[name];
    _redrawAllFlagVisuals();
    _updateSubmitEnabled();
  }

  function _anyFlagSelected() {
    return _flags.pork || _flags.alcohol || _flags.meat ||
           _flags.seafood || _flags.factory || _flags.allhalal || _flags.ambiguous;
  }

  function _redrawAllFlagVisuals() {
    _setFlagVisual('allhalal',  _flags.allhalal,  true);
    _setFlagVisual('pork',      _flags.pork,      false);
    _setFlagVisual('alcohol',   _flags.alcohol,   false);
    _setFlagVisual('meat',      _flags.meat,      false);
    _setFlagVisual('seafood',   _flags.seafood,   false);
    _setFlagVisual('factory',   _flags.factory,   false);
    _setFlagVisual('ambiguous', _flags.ambiguous, false);
  }

  function _setFlagVisual(flag, on, safe) {
    const el = document.querySelector(`#nsForm .flag-toggle[data-flag="${flag}"]`);
    if (!el) return;
    el.classList.remove('flag-toggle--active', 'flag-toggle--active-safe');
    const check = el.querySelector('.flag-toggle__check');
    if (on) {
      el.classList.add(safe ? 'flag-toggle--active-safe' : 'flag-toggle--active');
      if (check) check.textContent = '✓';
    } else if (check) {
      check.textContent = '';
    }
  }

  function _setCategoryVisual(cat) {
    document.querySelectorAll('#nsCategoryGrid .cat-chip').forEach(c => {
      c.classList.toggle('cat-chip--active', c.getAttribute('data-cat') === cat);
    });
  }
  function _clearCategoryVisual() {
    document.querySelectorAll('#nsCategoryGrid .cat-chip').forEach(c =>
      c.classList.remove('cat-chip--active'));
    _category = null;
  }

  function _updateSubmitEnabled() {
    const ok = !!_category && _anyFlagSelected() && !!_photoBlob;
    const btn = document.getElementById('nsFormSubmitBtn');
    if (btn) btn.disabled = !ok;
  }

  // ============================================
  // PHOTO
  // ============================================
  async function _openPhotoCapture() {
    _showSubState('nsPhotoCapture');
    try {
      const video = document.getElementById('nsCaptureVideo');
      await Camera.openForCapture(video);
    } catch (e) {
      console.error('photo capture failed:', e);
      _toast("Kamerani ochib bo'lmadi", 'error');
      _showPhotoEmpty();
    }
  }

  async function _takePhoto() {
    try {
      const video = document.getElementById('nsCaptureVideo');
      const blob = await Camera.grabPhoto(video);
      Camera.detach(video);
      _photoBlob = blob;
      if (_photoObjectUrl) URL.revokeObjectURL(_photoObjectUrl);
      _photoObjectUrl = URL.createObjectURL(blob);
      _showPhotoPreview(_photoObjectUrl);
      _updateSubmitEnabled();
    } catch (e) {
      console.error('grabPhoto failed:', e);
      _toast("Suratga olib bo'lmadi", 'error');
    }
  }

  function _cancelPhotoCapture() {
    Camera.detach(document.getElementById('nsCaptureVideo'));
    if (_photoBlob) _showPhotoPreview(_photoObjectUrl);
    else _showPhotoEmpty();
  }

  function _removePhoto() {
    _photoBlob = null;
    if (_photoObjectUrl) { URL.revokeObjectURL(_photoObjectUrl); _photoObjectUrl = null; }
    _showPhotoEmpty();
    _updateSubmitEnabled();
  }

  function _showSubState(id) {
    ['nsPhotoEmpty','nsPhotoCapture','nsPhotoPreview'].forEach(s => {
      const el = document.getElementById(s);
      if (el) el.style.display = (s === id) ? 'block' : 'none';
    });
  }
  function _showPhotoEmpty()   { _showSubState('nsPhotoEmpty'); }
  function _showPhotoPreview(src) {
    const img = document.getElementById('nsPreviewImg');
    if (img) img.src = src;
    _showSubState('nsPhotoPreview');
  }

  // ============================================
  // SUBMIT
  // ============================================
  async function _submit() {
    if (!_category || !_anyFlagSelected() || !_photoBlob) return;

    _showState('nsSubmitting');

    // Compress + base64
    let photoB64 = null;
    try {
      const compressed = (window.StoreUtils && StoreUtils.compressImage)
        ? await StoreUtils.compressImage(_photoBlob)
        : _photoBlob;
      photoB64 = await _blobToBase64(compressed);
    } catch (e) {
      _showError("Suratni qayta ishlab bo'lmadi", String(e && e.message || e));
      return;
    }

    const payload = {
      barcode: _barcode,
      category: _category,
      pork: _flags.pork,
      alcohol: _flags.alcohol,
      meat: _flags.meat,
      seafood: _flags.seafood,
      sameFactory: _flags.factory,
      ambiguousIngredient: _flags.ambiguous,
      photo: photoB64,
      userId: USER_ID(),
    };
    // allhalal is conceptual — it means "all flags false". We already cleared the rest.

    try {
      const resp = await fetch(`${API_BASE()}/api/scanner/product/add`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      let data = {};
      try { data = await resp.json(); } catch (e) {}

      if (resp.status === 201 && data.success) {
        _renderSuccess(data.product);
        _showState('nsSuccess');
        return;
      }

      if (resp.status === 409) {
        _renderDuplicate(data);
        _showState('nsDuplicate');
        return;
      }

      _showError("Yuborib bo'lmadi", data.error || `HTTP ${resp.status}`);
    } catch (e) {
      console.error('no-store submit failed:', e);
      _showError("Ulanish xatoligi", "Internetni tekshirib qaytadan urinib ko'ring.");
    }
  }

  function _renderSuccess(product) {
    const el = document.getElementById('nsSuccessPreview');
    if (!el) return;
    const v = product.verdict || 'halol';
    const VL = { halol:'☪ Halol', shubhali:'⚠ Shubhali', harom:'⛔ Harom' };
    const apiBase = API_BASE();
    let imgSrc = product.image || '';
    if (imgSrc && imgSrc.startsWith('/api/')) imgSrc = apiBase + imgSrc;
    el.innerHTML = `
      <div class="ns-preview ns-preview--${v}">
        <div class="ns-preview__img">${imgSrc ? `<img src="${_esc(imgSrc)}" alt="">` : '📦'}</div>
        <div class="ns-preview__body">
          <span class="ns-preview__verdict ns-preview__verdict--${v}">${VL[v] || v}</span>
          <code class="ns-preview__bc">${_esc(product.barcode)}</code>
          <p class="ns-preview__cat">${_esc(product.category || '')}</p>
        </div>
      </div>`;
  }

  function _renderDuplicate(data) {
    const el = document.getElementById('nsDuplicatePreview');
    if (!el) return;
    let where = '';
    if (data.existsInStore) {
      where = "Bu mahsulot do'kon ma'lumotlar bazasida mavjud.";
    } else if (data.existsInMain) {
      where = "Bu mahsulot asosiy ma'lumotlar bazasida allaqachon mavjud.";
    } else {
      where = "Mahsulot allaqachon ro'yxatda.";
    }

    let existingHtml = '';
    if (data.existingProduct) {
      const p = data.existingProduct;
      const v = p.verdict || 'halol';
      const VL = { halol:'☪ Halol', shubhali:'⚠ Shubhali', harom:'⛔ Harom' };
      const apiBase = API_BASE();
      let imgSrc = p.image || '';
      if (imgSrc && imgSrc.startsWith('/api/')) imgSrc = apiBase + imgSrc;
      existingHtml = `
        <div class="ns-preview ns-preview--${v}">
          <div class="ns-preview__img">${imgSrc ? `<img src="${_esc(imgSrc)}" alt="">` : '📦'}</div>
          <div class="ns-preview__body">
            <span class="ns-preview__verdict ns-preview__verdict--${v}">${VL[v] || v}</span>
            <code class="ns-preview__bc">${_esc(p.barcode)}</code>
            <p class="ns-preview__cat">${_esc(p.name || p.category || '')}</p>
          </div>
        </div>`;
    }

    el.innerHTML = `<p class="ns-state__msg">${_esc(where)}</p>${existingHtml}`;
  }

  function _showError(title, body) {
    const t = document.getElementById('nsErrorTitle');
    const b = document.getElementById('nsErrorBody');
    if (t) t.textContent = title;
    if (b) b.textContent = body;
    _showState('nsError');
  }

  // ============================================
  // CLOSE / RESET
  // ============================================
  function _close() {
    _stopScanning();
    try { Camera.detach(document.getElementById('nsVideo')); } catch (e) {}
    try { Camera.detach(document.getElementById('nsCaptureVideo')); } catch (e) {}
    _reset();
    _hidePane();
    if (_onClose) _onClose();
  }

  function _reset() {
    _barcode = '';
    _category = null;
    _flags = { pork:false, alcohol:false, meat:false, seafood:false, factory:false, allhalal:false, ambiguous:false };
    _photoBlob = null;
    if (_photoObjectUrl) { URL.revokeObjectURL(_photoObjectUrl); _photoObjectUrl = null; }
    _clearCategoryVisual();
    _redrawAllFlagVisuals();
    _showPhotoEmpty();
    _updateSubmitEnabled();
  }

  // ============================================
  // UTILITIES
  // ============================================
  function _toast(msg, kind) {
    if (window.StoreUI && StoreUI.toast) { StoreUI.toast(msg, kind); return; }
    console.log('[toast]', kind, msg);
  }

  function _esc(s) {
    const d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
  }

  function _blobToBase64(blob) {
    return new Promise((resolve, reject) => {
      const r = new FileReader();
      r.onloadend = () => resolve(r.result);
      r.onerror = reject;
      r.readAsDataURL(blob);
    });
  }

  // ============================================
  // EXPORT
  // ============================================
  return { init, open, close: _close };
})();

// Auto-wire: bind the "no-store" button on the existing store picker
document.addEventListener('DOMContentLoaded', () => {
  // Init module
  if (window.StoreNoStore && StoreNoStore.init) StoreNoStore.init();

  // Bind the new button in the existing store grid
  const trigger = document.querySelector('.store-card[data-store="__NOSTORE__"]');
  if (trigger) {
    trigger.addEventListener('click', (ev) => {
      ev.preventDefault();
      ev.stopPropagation();   // do NOT trigger the host's per-store click handler
      if (window.StoreNoStore) StoreNoStore.open();
    }, true);  // capture phase → fires before any later listeners
  }
});
