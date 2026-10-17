// ============================================
// store-form.js — Submission form module
// Depends on: window.Camera, window.StoreUI
// Exposes: window.StoreForm
// ============================================

window.StoreForm = (() => {

  // --- state ---
  let category = null;
  let flags = {
    pork: false, alcohol: false, meat: false,
    seafood: false, factory: false, allhalal: false
  };
  let photoBlob = null;      // new photo taken in this session
  let photoPath = null;      // reused path from another store (cross-store)
  let photoObjectUrl = null; // for preview cleanup

  // --- config ---
  let barcode = '';
  let targetStore = '';
  let onSubmit = null;  // callback(payload)
  let onCancel = null;

  // ============================================
  // INIT
  // ============================================
  function init(opts) {
    opts = opts || {};
    onSubmit = opts.onSubmit || (() => {});
    onCancel = opts.onCancel || (() => {});

    _bindCategory();
    _bindFlags();
    _bindPhoto();
    _bindFooter();
  }

  // ============================================
  // OPEN / RESET
  // ============================================
  function openBlank(_barcode, _store) {
    _reset();
    barcode = _barcode;
    targetStore = _store;
    StoreUI.setFormBarcode(barcode);
    StoreUI.setSelectedStoreLabels(targetStore);
    StoreUI.showPrefillBanner(false);
    StoreUI.showPhotoEmpty();
    StoreUI.showState('stateForm');
    _updateSubmitEnabled();
  }

  function openPrefilled(_barcode, _store, sourceProduct) {
    _reset();
    barcode = _barcode;
    targetStore = _store;
    StoreUI.setFormBarcode(barcode);
    StoreUI.setSelectedStoreLabels(targetStore);
    StoreUI.showPrefillBanner(true);

    // Category
    if (sourceProduct.category) {
      category = sourceProduct.category;
      StoreUI.setCategoryActive(category);
    }

    // Flags — translate product schema → internal state
    flags.pork     = !!sourceProduct.pork;
    flags.alcohol  = !!sourceProduct.alcohol;
    flags.meat     = !!sourceProduct.meat;
    flags.seafood  = !!sourceProduct.seafood;
    flags.factory  = !!sourceProduct.sameFactory;
    flags.allhalal = !!sourceProduct.allHalal;
    _redrawAllFlagVisuals();

    // Photo — reuse path
    if (sourceProduct.photo) {
      photoPath = sourceProduct.photo;
      const apiBase = window._SC_API_BASE || '';
      let src = sourceProduct.image || '';
      if (src.startsWith('/api/')) src = apiBase + src;
      StoreUI.showPhotoPreview(src, true);
    } else {
      StoreUI.showPhotoEmpty();
    }

    StoreUI.showState('stateForm');
    _updateSubmitEnabled();
  }

  function _reset() {
    category = null;
    flags = { pork: false, alcohol: false, meat: false, seafood: false, factory: false, allhalal: false };
    photoBlob = null;
    photoPath = null;
    if (photoObjectUrl) { URL.revokeObjectURL(photoObjectUrl); photoObjectUrl = null; }
    StoreUI.clearCategoryActive();
    StoreUI.resetAllFlagVisuals();
  }

  // ============================================
  // AUTO-SCROLL
  // ============================================
  // Target offset from the top of the viewport so the next section isn't
  // hidden behind the sticky tab bar (approx 56px).
  const SCROLL_OFFSET_TOP = 72;

  function _scrollToSection(index) {
    // 0 = category, 1 = flags, 2 = photo, 3 = submit footer
    const stateForm = document.getElementById('stateForm');
    if (!stateForm || stateForm.style.display === 'none') return;
    const sections = stateForm.querySelectorAll('.form-section');
    let el = null;
    if (index < sections.length) {
      el = sections[index];
    } else {
      // Submit is in the sticky footer
      el = document.querySelector('#stateForm .form-footer');
    }
    if (!el) return;
    const y = el.getBoundingClientRect().top + window.pageYOffset - SCROLL_OFFSET_TOP;
    window.scrollTo({ top: Math.max(0, y), behavior: 'smooth' });
  }

  // Debounce so rapid taps don't chain-scroll
  let _scrollTimer = null;
  function _scheduleScroll(index, delay) {
    if (_scrollTimer) clearTimeout(_scrollTimer);
    _scrollTimer = setTimeout(() => _scrollToSection(index), delay || 180);
  }

  // ============================================
  // CATEGORY
  // ============================================
  function _bindCategory() {
    const grid = StoreUI.els().categoryGrid;
    if (!grid) return;
    grid.addEventListener('click', (ev) => {
      const chip = ev.target.closest('.cat-chip');
      if (!chip) return;
      const prev = category;
      category = chip.getAttribute('data-cat');
      StoreUI.setCategoryActive(category);
      _updateSubmitEnabled();
      // Only advance on a fresh pick, not when user taps the same chip again
      if (category && category !== prev) _scheduleScroll(1);
    });
  }

  // ============================================
  // FLAGS
  // ============================================
  function _bindFlags() {
    document.querySelectorAll('.flag-toggle[data-flag]').forEach(el => {
      el.addEventListener('click', () => {
        const name = el.getAttribute('data-flag');
        const wasAny = _anyFlagSelected();
        _toggleFlag(name);
        // Advance to photo only when flags transition empty→any,
        // so repeatedly toggling doesn't jump the page.
        if (!wasAny && _anyFlagSelected()) _scheduleScroll(2);
      });
    });
  }

  function _toggleFlag(name) {
    if (name === 'allhalal') {
      const wasOn = flags.allhalal;
      flags = { pork: false, alcohol: false, meat: false, seafood: false, factory: false, allhalal: !wasOn };
      _redrawAllFlagVisuals();
      _updateSubmitEnabled();
      return;
    }
    // Any non-allhalal toggle cancels allhalal
    if (flags.allhalal) flags.allhalal = false;
    flags[name] = !flags[name];
    _redrawAllFlagVisuals();
    _updateSubmitEnabled();
  }

  function _redrawAllFlagVisuals() {
    StoreUI.setFlagVisual('allhalal', flags.allhalal, true);
    StoreUI.setFlagVisual('pork',     flags.pork,     false);
    StoreUI.setFlagVisual('alcohol',  flags.alcohol,  false);
    StoreUI.setFlagVisual('meat',     flags.meat,     false);
    StoreUI.setFlagVisual('seafood',  flags.seafood,  false);
    StoreUI.setFlagVisual('factory',  flags.factory,  false);
  }

  function _anyFlagSelected() {
    return flags.pork || flags.alcohol || flags.meat ||
           flags.seafood || flags.factory || flags.allhalal;
  }

  function _hasPhoto() {
    return !!(photoBlob || photoPath);
  }

  // ============================================
  // SUBMIT GATE
  // ============================================
  function _updateSubmitEnabled() {
    const ok = !!category && _anyFlagSelected() && _hasPhoto();
    StoreUI.setSubmitEnabled(ok);
  }

  // ============================================
  // PHOTO CAPTURE
  // ============================================
  function _bindPhoto() {
    const ui = StoreUI.els();
    if (ui.openPhotoBtn)    ui.openPhotoBtn.addEventListener('click', _openCapture);
    if (ui.shutterBtn)      ui.shutterBtn.addEventListener('click', _takePhoto);
    if (ui.cancelPhotoBtn)  ui.cancelPhotoBtn.addEventListener('click', _cancelCapture);
    if (ui.retakePhotoBtn)  ui.retakePhotoBtn.addEventListener('click', _retake);
    if (ui.removePhotoBtn)  ui.removePhotoBtn.addEventListener('click', _removePhoto);
  }

  async function _openCapture() {
    try {
      StoreUI.showPhotoCapture();
      await Camera.openForCapture(StoreUI.els().captureVideo);
    } catch (e) {
      console.error('openForCapture failed:', e);
      StoreUI.toast('Kamerani ochib bo\'lmadi', 'error');
      StoreUI.showPhotoEmpty();
    }
  }

  async function _takePhoto() {
    try {
      const video = StoreUI.els().captureVideo;
      const blob = await Camera.grabPhoto(video);
      Camera.detach(video);

      photoBlob = blob;
      photoPath = null;  // new photo overrides any reused path
      if (photoObjectUrl) URL.revokeObjectURL(photoObjectUrl);
      photoObjectUrl = URL.createObjectURL(blob);
      StoreUI.showPhotoPreview(photoObjectUrl, false);
      _updateSubmitEnabled();
      _scheduleScroll(3, 260);
    } catch (e) {
      console.error('grabPhoto failed:', e);
      StoreUI.toast('Suratga olib bo\'lmadi', 'error');
    }
  }

  function _cancelCapture() {
    Camera.detach(StoreUI.els().captureVideo);
    if (photoBlob || photoPath) {
      const src = photoObjectUrl || (photoPath ? _resolvePhotoUrl(photoPath) : '');
      StoreUI.showPhotoPreview(src, !!photoPath && !photoBlob);
    } else {
      StoreUI.showPhotoEmpty();
    }
  }

  function _retake() { _openCapture(); }

  function _removePhoto() {
    photoBlob = null;
    photoPath = null;
    if (photoObjectUrl) { URL.revokeObjectURL(photoObjectUrl); photoObjectUrl = null; }
    StoreUI.showPhotoEmpty();
    _updateSubmitEnabled();
  }

  function _resolvePhotoUrl(relPath) {
    if (!relPath) return '';
    const apiBase = window._SC_API_BASE || '';
    return apiBase + '/api/store/photo/' + relPath;
  }

  // ============================================
  // FOOTER (submit / cancel)
  // ============================================
  function _bindFooter() {
    const ui = StoreUI.els();
    if (ui.formSubmitBtn) ui.formSubmitBtn.addEventListener('click', _submit);
    if (ui.formCancelBtn) ui.formCancelBtn.addEventListener('click', () => {
      Camera.detach(StoreUI.els().captureVideo);
      onCancel();
    });
  }

  async function _submit() {
    if (!category || !_anyFlagSelected()) return;

    const payload = {
      barcode: barcode,
      store: targetStore,
      category: category,
      pork: flags.pork,
      alcohol: flags.alcohol,
      meat: flags.meat,
      seafood: flags.seafood,
      sameFactory: flags.factory,
      allHalal: flags.allhalal,
    };

    // Photo: new upload vs reuse path vs none
    if (photoBlob) {
      const compressed = (window.StoreUtils && StoreUtils.compressImage)
        ? await StoreUtils.compressImage(photoBlob)
        : photoBlob;
      payload.photo = await _blobToBase64(compressed);
    } else if (photoPath) {
      payload.photoPath = photoPath;
    }

    onSubmit(payload);
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
  return {
    init,
    openBlank,
    openPrefilled,
    reset: _reset,
    getState: () => ({
      barcode, targetStore, category, flags: {...flags},
      hasPhoto: !!(photoBlob || photoPath)
    }),
  };
})();
