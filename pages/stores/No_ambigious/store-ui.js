// ============================================
// store-ui.js — UI state machine + DOM helpers
// Exposes: window.StoreUI
// ============================================

window.StoreUI = (() => {

  const STATES = [
    'stateStorePicker',
    'statePermission',
    'stateScanner',
    'stateAlreadyAdded',
    'stateCrossStore',
    'stateForm',
    'stateSubmitting',
    'stateSuccess',
    'stateError',
  ];

  let _els = null;

  function els() {
    if (_els) return _els;
    _els = {
      // Panes
      paneCollect:          document.getElementById('paneCollect'),
      paneMine:             document.getElementById('paneMine'),
      tabCollect:           document.getElementById('tabCollect'),
      tabMine:              document.getElementById('tabMine'),
      mineBadge:            document.getElementById('mineBadge'),

      // States (by id)
      states: STATES.reduce((acc, id) => (acc[id] = document.getElementById(id), acc), {}),

      // Store picker
      storeGrid:            document.getElementById('storeGrid'),

      // Permission
      permStoreName:        document.getElementById('permStoreName'),
      changeStoreBtnPerm:   document.getElementById('changeStoreBtnPerm'),
      startScanBtn:         document.getElementById('startScanBtn'),

      // Scanner
      scanStoreName:        document.getElementById('scanStoreName'),
      changeStoreBtnScan:   document.getElementById('changeStoreBtnScan'),
      videoElement:         document.getElementById('videoElement'),
      scanBeam:             document.getElementById('scanBeam'),
      torchBtn:             document.getElementById('torchBtn'),
      switchCamBtn:         document.getElementById('switchCamBtn'),
      statusPill:           document.getElementById('statusPill'),
      statusText:           document.getElementById('statusText'),

      // Already added
      alreadyAddedPreview:  document.getElementById('alreadyAddedPreview'),
      scanNextBtnAlready:   document.getElementById('scanNextBtnAlready'),

      // Cross store
      crossTargetStore:     document.getElementById('crossTargetStore'),
      crossPreview:         document.getElementById('crossPreview'),
      crossStoreList:       document.getElementById('crossStoreList'),
      crossRejectBtn:       document.getElementById('crossRejectBtn'),
      crossAcceptBtn:       document.getElementById('crossAcceptBtn'),

      // Form
      formStoreName:        document.getElementById('formStoreName'),
      formBarcode:          document.getElementById('formBarcode'),
      formPrefillBanner:    document.getElementById('formPrefillBanner'),
      categoryGrid:         document.getElementById('categoryGrid'),
      flagList:             document.getElementById('flagList'),
      photoBox:             document.getElementById('photoBox'),
      photoEmpty:           document.getElementById('photoEmpty'),
      photoCapture:         document.getElementById('photoCapture'),
      photoPreview:         document.getElementById('photoPreview'),
      photoPreviewImg:      document.getElementById('photoPreviewImg'),
      photoSourceTag:       document.getElementById('photoSourceTag'),
      captureVideo:         document.getElementById('captureVideo'),
      openPhotoBtn:         document.getElementById('openPhotoBtn'),
      shutterBtn:           document.getElementById('shutterBtn'),
      cancelPhotoBtn:       document.getElementById('cancelPhotoBtn'),
      retakePhotoBtn:       document.getElementById('retakePhotoBtn'),
      removePhotoBtn:       document.getElementById('removePhotoBtn'),
      formSubmitBtn:        document.getElementById('formSubmitBtn'),
      formCancelBtn:        document.getElementById('formCancelBtn'),

      // Success
      successStoreName:     document.getElementById('successStoreName'),
      successPreview:       document.getElementById('successPreview'),
      successGotoMineBtn:   document.getElementById('successGotoMineBtn'),
      successScanNextBtn:   document.getElementById('successScanNextBtn'),

      // Error
      errorTitle:           document.getElementById('errorTitle'),
      errorMessage:         document.getElementById('errorMessage'),
      errorRetryBtn:        document.getElementById('errorRetryBtn'),

      // Mine
      mineList:             document.getElementById('mineList'),
      mineEmpty:            document.getElementById('mineEmpty'),
      mineLoading:          document.getElementById('mineLoading'),
      mineCountText:        document.getElementById('mineCountText'),
      mineFilters:          document.getElementById('mineFilters'),

      // Toast
      toast:                document.getElementById('toast'),
      toastIcon:            document.getElementById('toastIcon'),
      toastText:            document.getElementById('toastText'),
    };
    return _els;
  }

  // ============================================
  // TAB SWITCHING
  // ============================================
  function showTab(tab) {
    const e = els();
    if (tab === 'mine') {
      e.paneCollect.style.display = 'none';
      e.paneMine.style.display = 'block';
      e.tabCollect.classList.remove('sc-tab--active');
      e.tabMine.classList.add('sc-tab--active');
    } else {
      e.paneCollect.style.display = 'block';
      e.paneMine.style.display = 'none';
      e.tabMine.classList.remove('sc-tab--active');
      e.tabCollect.classList.add('sc-tab--active');
    }
  }

  // ============================================
  // STATE MACHINE
  // ============================================
  function showState(stateId) {
    const e = els();
    STATES.forEach(id => {
      const el = e.states[id];
      if (el) el.style.display = 'none';
    });
    const target = e.states[stateId];
    if (target) target.style.display = 'block';
  }

  // ============================================
  // STORE PICKER
  // ============================================
  function setSelectedStoreCard(storeName) {
    const e = els();
    e.storeGrid.querySelectorAll('.store-card').forEach(c => {
      c.classList.toggle('store-card--selected', c.getAttribute('data-store') === storeName);
    });
  }

  function setSelectedStoreLabels(storeName) {
    const e = els();
    if (e.permStoreName) e.permStoreName.textContent = storeName || '—';
    if (e.scanStoreName) e.scanStoreName.textContent = storeName || '—';
    if (e.formStoreName) e.formStoreName.textContent = storeName || '—';
    if (e.successStoreName) e.successStoreName.textContent = storeName || '—';
  }

  // ============================================
  // SCANNER STATUS
  // ============================================
  function updateStatus(text, kind) {
    const e = els();
    if (e.statusText) e.statusText.textContent = text;
    if (e.statusPill) {
      e.statusPill.classList.remove('status-pill--found', 'status-pill--error');
      if (kind === 'found') e.statusPill.classList.add('status-pill--found');
      if (kind === 'error') e.statusPill.classList.add('status-pill--error');
    }
  }

  function showScanBeam(visible) {
    const e = els();
    if (e.scanBeam) e.scanBeam.style.display = visible ? 'block' : 'none';
  }

  function showTorch(hasTorch) {
    const e = els();
    if (e.torchBtn) e.torchBtn.style.display = hasTorch ? 'inline-flex' : 'none';
  }

  function showSwitchCam(hasMultiple) {
    const e = els();
    if (e.switchCamBtn) e.switchCamBtn.style.display = hasMultiple ? 'inline-flex' : 'none';
  }

  function setTorchActive(on) {
    const e = els();
    if (!e.torchBtn) return;
    e.torchBtn.style.background = on ? 'rgba(255,220,100,0.22)' : '';
  }

  // ============================================
  // PRODUCT PREVIEW CARDS
  // Used in: already-added, cross-store, success, delete modal, edit target
  // ============================================
  const CAT_LABELS = {
    'Drinks':            'Ichimliklar',
    'Snacks':            'Gazaklar',
    'Sweets':            'Shirinliklar',
    'Ice Cream':         'Muzqaymoq',
    'Baked Goods':       'Non mahsulotlari',
    'Cup Noodles/Ramen': "Lag'mon / Ramen",
    'Lunchbox/Dosirak':  'Pechenya/Pishiriqlar',
    'Dairy':             'Sut mahsulotlari',
    'Canned Food':       'Konserva',
    'Frozen Food':       'Muzlatilgan',
    'Condiments/Sauces': 'Sous va ziravorlar',
    'Fruits/Vegetables': 'Meva va sabzavot',
    'Dried Food':        'Quruq mahsulot',
  };

  const VERDICT_LABELS = {
    joiz:    { txt: '✅ Joiz',    cls: 'joiz' },
    shubhali: { txt: '⚠️ Shubhali', cls: 'shubhali' },
    nojoiz:    { txt: '⛔ Nojoiz',    cls: 'nojoiz' },
  };

  const FLAG_DEFS = [
    { key: 'allHalal',    label: 'Barchasi halol',   icon: '☪️', safe: true },
    { key: 'pork',        label: "Cho'chqa",         icon: '🐖' },
    { key: 'alcohol',     label: 'Alkogol',          icon: '🍷' },
    { key: 'meat',        label: "Boshqa go'sht",    icon: '🍗' },
    { key: 'seafood',     label: 'Dengiz mahs.',     icon: '🦐' },
    { key: 'sameFactory', label: 'Bir xil zavod',    icon: '🏭' },
  ];

  function _escHtml(s) {
    const d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
  }

  function _flagsHtml(p) {
    const parts = [];
    FLAG_DEFS.forEach(f => {
      if (p[f.key]) {
        parts.push(`<span class="product-preview__flag">${f.icon} ${_escHtml(f.label)}</span>`);
      }
    });
    return parts.join('');
  }

  function buildProductPreview(p, opts) {
    if (!p) return '';
    opts = opts || {};
    const v = VERDICT_LABELS[p.verdict] || VERDICT_LABELS.halol;
    const cat = CAT_LABELS[p.category] || p.category || '';
    const apiBase = window._SC_API_BASE || '';
    let imgSrc = p.image || '';
    if (imgSrc && imgSrc.startsWith('/api/')) imgSrc = apiBase + imgSrc;
    const imgHtml = imgSrc
      ? `<img src="${_escHtml(imgSrc)}" alt="" loading="lazy" />`
      : '📦';
    const flags = _flagsHtml(p);
    return `
      <div class="product-preview${opts.compact ? ' product-preview--compact' : ''}">
        <div class="product-preview__img">${imgHtml}</div>
        <div class="product-preview__body">
          <div class="product-preview__row">
            <span class="product-preview__store">${_escHtml(p.store)}</span>
            <span class="product-preview__verdict product-preview__verdict--${v.cls}">${v.txt}</span>
          </div>
          <div class="product-preview__category">${_escHtml(cat)}</div>
          <code class="product-preview__barcode">${_escHtml(p.barcode)}</code>
          ${flags ? `<div class="product-preview__flags">${flags}</div>` : ''}
        </div>
      </div>`;
  }

  function renderAlreadyAdded(product) {
    els().alreadyAddedPreview.innerHTML = buildProductPreview(product);
  }

  /**
   * Renders cross-store prompt. Supports multi-source selection:
   * if >1 other stores exist, user can tap a chip to choose which
   * entry becomes the prefill source. Active chip = selected source.
   *
   * @param {string} targetStore - the store the user is adding to
   * @param {Array}  others - other_stores from /check/
   * @param {number} activeIndex - which entry is currently shown/selected
   * @param {(i:number)=>void} onPickSource - called when user taps a chip
   */
  function renderCrossStore(targetStore, others, activeIndex, onPickSource) {
    const e = els();
    e.crossTargetStore.textContent = targetStore;

    if (!others || others.length === 0) {
      e.crossPreview.innerHTML = '';
      e.crossStoreList.innerHTML = '';
      return;
    }

    const idx = Math.max(0, Math.min(activeIndex || 0, others.length - 1));
    e.crossPreview.innerHTML = buildProductPreview(others[idx]);

    if (others.length === 1) {
      e.crossStoreList.innerHTML = '';
      return;
    }

    // Multi-source: show selectable chips
    e.crossStoreList.innerHTML =
      `<span class="cross-store-list__label">Qaysi do'kondagi ma'lumotdan nusxa olamiz?</span>` +
      others.map((o, i) => {
        const active = i === idx ? ' cross-store-chip--active' : '';
        return `<button class="cross-store-chip cross-store-chip--btn${active}" data-idx="${i}" type="button">${_escHtml(o.store)}</button>`;
      }).join('');

    // Rebind chip click handlers (fresh every render is fine — cheap DOM)
    e.crossStoreList.querySelectorAll('.cross-store-chip--btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const i = parseInt(btn.getAttribute('data-idx'), 10);
        if (typeof onPickSource === 'function') onPickSource(i);
      });
    });
  }

  function renderSuccess(product) {
    els().successPreview.innerHTML = buildProductPreview(product);
  }

  // ============================================
  // FORM: category & flag controls
  // ============================================
  function setCategoryActive(cat) {
    els().categoryGrid.querySelectorAll('.cat-chip').forEach(c => {
      c.classList.toggle('cat-chip--active', c.getAttribute('data-cat') === cat);
    });
  }

  function clearCategoryActive() {
    els().categoryGrid.querySelectorAll('.cat-chip').forEach(c => {
      c.classList.remove('cat-chip--active');
    });
  }

  function setFlagVisual(flagName, active, safe) {
    // flagName is the data-flag attr: pork/alcohol/meat/seafood/factory/allhalal
    const el = document.querySelector(`.flag-toggle[data-flag="${flagName}"]`);
    if (!el) return;
    el.classList.remove('flag-toggle--active', 'flag-toggle--active-safe');
    const check = el.querySelector('.flag-toggle__check');
    if (active) {
      el.classList.add(safe ? 'flag-toggle--active-safe' : 'flag-toggle--active');
      if (check) check.textContent = '✓';
    } else {
      if (check) check.textContent = '';
    }
  }

  function resetAllFlagVisuals() {
    document.querySelectorAll('.flag-toggle').forEach(el => {
      el.classList.remove('flag-toggle--active', 'flag-toggle--active-safe');
      const c = el.querySelector('.flag-toggle__check');
      if (c) c.textContent = '';
    });
  }

  function setSubmitEnabled(enabled) {
    const e = els();
    if (e.formSubmitBtn) e.formSubmitBtn.disabled = !enabled;
  }

  function setFormBarcode(barcode) {
    const e = els();
    if (e.formBarcode) e.formBarcode.textContent = barcode || '—';
  }

  function showPrefillBanner(visible) {
    const e = els();
    if (e.formPrefillBanner) e.formPrefillBanner.style.display = visible ? 'flex' : 'none';
  }

  // ============================================
  // PHOTO BOX substates
  // ============================================
  function showPhotoEmpty() {
    const e = els();
    e.photoEmpty.style.display = 'flex';
    e.photoCapture.style.display = 'none';
    e.photoPreview.style.display = 'none';
  }

  function showPhotoCapture() {
    const e = els();
    e.photoEmpty.style.display = 'none';
    e.photoCapture.style.display = 'block';
    e.photoPreview.style.display = 'none';
  }

  function showPhotoPreview(srcUrl, fromOtherStore) {
    const e = els();
    e.photoEmpty.style.display = 'none';
    e.photoCapture.style.display = 'none';
    e.photoPreview.style.display = 'block';
    if (srcUrl) e.photoPreviewImg.src = srcUrl;
    if (e.photoSourceTag) {
      e.photoSourceTag.style.display = fromOtherStore ? 'inline-block' : 'none';
    }
  }

  // ============================================
  // ERROR CARD
  // ============================================
  function showError(title, msg) {
    const e = els();
    if (e.errorTitle)   e.errorTitle.textContent   = title || 'Xatolik yuz berdi';
    if (e.errorMessage) e.errorMessage.textContent = msg   || 'Iltimos, qaytadan urinib ko\'ring.';
    showState('stateError');
  }

  // ============================================
  // TOAST
  // ============================================
  let _toastTimer = null;
  function toast(msg, kind) {
    const e = els();
    if (!e.toast) return;
    e.toast.classList.remove('sc-toast--success', 'sc-toast--error');
    if (kind === 'success') e.toast.classList.add('sc-toast--success');
    if (kind === 'error')   e.toast.classList.add('sc-toast--error');
    e.toastIcon.textContent = kind === 'success' ? '✅' : kind === 'error' ? '⚠️' : 'ℹ️';
    e.toastText.textContent = msg || '';
    e.toast.style.display = 'inline-flex';
    // force reflow for transition
    // eslint-disable-next-line no-unused-expressions
    e.toast.offsetHeight;
    e.toast.classList.add('sc-toast--visible');
    if (_toastTimer) clearTimeout(_toastTimer);
    _toastTimer = setTimeout(() => {
      e.toast.classList.remove('sc-toast--visible');
      setTimeout(() => { e.toast.style.display = 'none'; }, 300);
    }, 2600);
  }

  // ============================================
  // MINE badge
  // ============================================
  function setMineBadge(n) {
    const e = els();
    if (!e.mineBadge) return;
    if (!n || n <= 0) {
      e.mineBadge.style.display = 'none';
    } else {
      e.mineBadge.style.display = 'inline-flex';
      e.mineBadge.textContent = String(n);
    }
  }

  // ============================================
  // FULLSCREEN IMAGE VIEWER
  // ============================================
  function openFullscreen(src) {
    if (!src) return;
    const viewer = document.getElementById('fullscreenViewer');
    const img    = document.getElementById('fullscreenImg');
    if (!viewer || !img) return;
    img.src = src;
    viewer.style.display = 'flex';
  }

  function closeFullscreen() {
    const viewer = document.getElementById('fullscreenViewer');
    const img    = document.getElementById('fullscreenImg');
    if (!viewer) return;
    viewer.style.display = 'none';
    if (img) img.src = '';
  }

  function _initFullscreen() {
    const viewer = document.getElementById('fullscreenViewer');
    const close  = document.getElementById('fullscreenClose');
    if (viewer) {
      viewer.addEventListener('click', (ev) => {
        // Click on backdrop (not the image) closes
        if (ev.target === viewer) closeFullscreen();
      });
    }
    if (close) close.addEventListener('click', closeFullscreen);

    // Delegated: any clickable product-preview or mine-card image opens fullscreen.
    // Only if the image actually has a src (not placeholder emoji).
    document.addEventListener('click', (ev) => {
      const target = ev.target.closest('.product-preview__img, .mine-card__img, .modal-img-wrap, .photo-box__preview img');
      if (!target) return;
      const img = target.tagName === 'IMG' ? target : target.querySelector('img');
      if (!img || !img.src) return;
      // Don't hijack clicks on the preview-action buttons below the image
      if (ev.target.closest('.photo-box__preview-actions')) return;
      openFullscreen(img.src);
    });
  }
  // Defer until DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', _initFullscreen);
  } else {
    _initFullscreen();
  }

  // ============================================
  // EXPORT
  // ============================================
  return {
    els,
    showTab,
    showState,
    setSelectedStoreCard,
    setSelectedStoreLabels,
    updateStatus,
    showScanBeam,
    showTorch,
    showSwitchCam,
    setTorchActive,
    renderAlreadyAdded,
    renderCrossStore,
    renderSuccess,
    buildProductPreview,
    setCategoryActive,
    clearCategoryActive,
    setFlagVisual,
    resetAllFlagVisuals,
    setSubmitEnabled,
    setFormBarcode,
    showPrefillBanner,
    showPhotoEmpty,
    showPhotoCapture,
    showPhotoPreview,
    showError,
    toast,
    setMineBadge,
    openFullscreen,
    closeFullscreen,
    CAT_LABELS,
    VERDICT_LABELS,
    FLAG_DEFS,
  };
})();
