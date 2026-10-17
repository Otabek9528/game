// ui.js — UI module
// Handles: state switching, viewfinder controls, status, clipboard, sound
// Exposes: window.UI
// ============================================

window.UI = (() => {

  let _els = null;

  function els() {
    if (_els) return _els;
    _els = {
      permissionState:  document.getElementById('permissionState'),
      errorState:       document.getElementById('errorState'),
      scannerDisplay:   document.getElementById('scannerDisplay'),
      errorMessage:     document.getElementById('errorMessage'),
      statusIndicator:  document.getElementById('statusIndicator'),
      statusText:       document.getElementById('statusText'),
      cameraInfoBadge:  document.getElementById('cameraInfoBadge'),
      torchBtn:         document.getElementById('torchBtn'),
      torchIcon:        document.getElementById('torchIcon'),
      switchCameraBtn:  document.getElementById('switchCameraBtn'),
      focusIndicator:   document.getElementById('focusIndicator'),
      videoElement:     document.getElementById('videoElement'),
      scanBeam:         document.getElementById('scanBeam'),
      viewfinderWrap:   document.getElementById('viewfinderWrap'),
      // Product result elements
      resultSection:    document.getElementById('resultSection'),
      notFoundSection:  document.getElementById('notFoundSection'),
      notFoundBarcode:  document.getElementById('notFoundBarcode'),
      verdictBanner:    document.getElementById('verdictBanner'),
      verdictEmoji:     document.getElementById('verdictEmoji'),
      verdictTitle:     document.getElementById('verdictTitle'),
      verdictDesc:      document.getElementById('verdictDesc'),
      productImageWrap: document.getElementById('productImageWrap'),
      productImage:     document.getElementById('productImage'),
      productName:      document.getElementById('productName'),
      barcodeType:      document.getElementById('barcodeType'),
      barcodeNumber:    document.getElementById('barcodeNumber'),
      copyBtn:          document.getElementById('copyBtn'),
      halalGrid:        document.getElementById('halalGrid'),
      factoryNotice:    document.getElementById('factoryNotice'),
      factoryIcon:      document.getElementById('factoryIcon'),
      factoryText:      document.getElementById('factoryText'),
      ingredientsPanel: document.getElementById('ingredientsPanel'),
      ingredientsText:  document.getElementById('ingredientsText'),
      discoverSection:  document.getElementById('discoverSection'),
      addProductWizard: document.getElementById('addProductWizard'),
      fullscreenViewer:  document.getElementById('fullscreenViewer'),
      fullscreenImg:     document.getElementById('fullscreenImg')
    };
    return _els;
  }

  // --- State switching ---
  function showState(state) {
    const e = els();
    e.permissionState.style.display = 'none';
    e.errorState.style.display = 'none';
    e.scannerDisplay.style.display = 'none';
    if (e.addProductWizard) e.addProductWizard.style.display = 'none';

    switch (state) {
      case 'permission': e.permissionState.style.display = 'flex'; break;
      case 'error':      e.errorState.style.display = 'flex'; break;
      case 'scanner':    e.scannerDisplay.style.display = 'block'; break;
      case 'wizard':
        e.addProductWizard.style.display = 'block';
        showDiscover(false);
        break;
    }
  }

  function showError(msg) {
    els().errorMessage.textContent = msg;
    showState('error');
  }

  // --- Product Detail Modal ---
  function showProductModal(data) {
    const modal = document.getElementById('productModal');
    const verdictMap = {
      halol:    { emoji: '✅', labelKey: 'bc.verdictJoiz', cls: 'joiz' },
      harom:    { emoji: '⛔️', labelKey: 'bc.verdictTaqiqlangan', cls: 'taqiqlangan' },
      shubhali: { emoji: '⚠️', labelKey: 'bc.verdictShubhali', cls: 'shubhali' }
    };
    const v = verdictMap[data.verdict] || verdictMap.halol;

    const badge = document.getElementById('modalVerdict');
    badge.className = `modal-verdict modal-verdict--${v.cls}`;
    document.getElementById('modalVerdictEmoji').textContent = v.emoji;
    document.getElementById('modalVerdictLabel').textContent = t(v.labelKey);

    const imgWrap = document.getElementById('modalImgWrap');
    if (data.image) {
      let modalImgSrc = data.image;
      if (modalImgSrc && modalImgSrc.startsWith('/api/')) {
        modalImgSrc = (window._API_BASE || '') + modalImgSrc;
      }
      document.getElementById('modalImg').src = modalImgSrc;
      imgWrap.style.display = 'block';
    } else {
      imgWrap.style.display = 'none';
    }

    document.getElementById('modalName').textContent = data.name || '—';
    document.getElementById('modalBarcode').textContent = data.barcode || '—';

    const grid = document.getElementById('modalHalalGrid');
    const checks = [
      { icon: '🐖', labelKey: 'bc.flag.pork', bad: data.pork },
      { icon: '🍷', labelKey: 'bc.flag.alcohol', bad: data.alcohol },
      { icon: '🍗', labelKey: 'bc.grid.meat', bad: data.meat },
      { icon: '🦐', labelKey: 'bc.grid.seafood', bad: data.seafood }
    ];
    grid.innerHTML = '';
    checks.forEach(c => {
      const ok = !c.bad;
      const label = t(c.labelKey);
      const el = document.createElement('div');
      el.className = `modal-halal-cell ${ok ? 'modal-halal-cell--ok' : 'modal-halal-cell--bad'}`;
      el.innerHTML = `<span class="modal-halal-cell__icon">${c.icon}</span>${ok ? '✅ ' + label + ' ' + t('bc.absent') : '❌ ' + label + ' ' + t('bc.present')}`;
      grid.appendChild(el);
    });

    const factory = document.getElementById('modalFactory');
    if (data.sameFactory !== undefined) {
      factory.className = `modal-factory ${data.sameFactory ? 'modal-factory--warn' : 'modal-factory--ok'}`;
      document.getElementById('modalFactoryIcon').textContent = data.sameFactory ? '🏭' : '✅';
      document.getElementById('modalFactoryText').textContent = data.sameFactory
        ? t('bc.factoryWarn')
        : t('bc.factoryOk');
      factory.style.display = 'flex';
    } else {
      factory.style.display = 'none';
    }

    const ingr = document.getElementById('modalIngredients');
    if (data.ingredients) {
      document.getElementById('modalIngredientsText').textContent = data.ingredients;
      ingr.style.display = 'block';
    } else {
      ingr.style.display = 'none';
    }

    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
  }

  function hideProductModal() {
    document.getElementById('productModal').style.display = 'none';
    document.body.style.overflow = '';
  }

  // --- Status ---
  function updateStatus(text, type = 'scanning') {
    const e = els();
    e.statusText.textContent = text;
    e.statusIndicator.className = `status-pill ${type}`;
  }

  // --- Camera info ---
  function updateCameraInfo(index, total) {
    const badge = els().cameraInfoBadge;
    if (badge && total > 1) {
      badge.textContent = `📷 ${index + 1}/${total}`;
      badge.style.display = 'inline-block';
    } else if (badge) {
      badge.style.display = 'none';
    }
  }

  function showTorch(visible) { els().torchBtn.style.display = visible ? 'flex' : 'none'; }
  function updateTorchIcon(isOn) {
    els().torchBtn.classList.toggle('active', isOn);
    els().torchIcon.textContent = isOn ? '💡' : '🔦';
  }
  function showSwitchBtn(visible) { els().switchCameraBtn.style.display = visible ? 'flex' : 'none'; }

  function flashFocusIndicator() {
    const fi = els().focusIndicator;
    fi.classList.add('active');
    setTimeout(() => fi.classList.remove('active'), 600);
  }

  function showScanBeam(visible) {
    const beam = els().scanBeam;
    if (beam) beam.style.display = visible ? 'block' : 'none';
  }

  // --- Result sections visibility ---
  function hideAllResults() {
    const e = els();
    e.resultSection.style.display = 'none';
    e.notFoundSection.style.display = 'none';
    e.viewfinderWrap.style.display = '';
    document.querySelector('.status-bar').style.display = '';
  }

  function showNotFound(barcode) {
    const e = els();
    e.resultSection.style.display = 'none';
    e.viewfinderWrap.style.display = 'none';
    document.querySelector('.status-bar').style.display = 'none';

    e.notFoundBarcode.textContent = barcode;
    e.notFoundSection.style.display = 'block';
    e.notFoundSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function showProductResult(data) {
    const e = els();
    e.notFoundSection.style.display = 'none';
    e.viewfinderWrap.style.display = 'none';
    document.querySelector('.status-bar').style.display = 'none';

    // Verdict
    e.verdictBanner.className = `verdict verdict--${data.verdict === 'halol' ? 'joiz' : data.verdict === 'harom' ? 'taqiqlangan' : data.verdict}`;
    const verdictMap = {
      halol:    { emoji: '✅', titleKey: 'bc.verdictJoiz', descKey: 'bc.verdictJoizDesc' },
      harom:    { emoji: '⛔️', titleKey: 'bc.verdictTaqiqlangan', descKey: 'bc.verdictTaqiqlanganDesc' },
      shubhali: { emoji: '⚠️', titleKey: 'bc.verdictShubhali', descKey: 'bc.verdictShubhaliDesc' }
    };
    const v = verdictMap[data.verdict] || verdictMap.halol;
    e.verdictEmoji.textContent = v.emoji;
    e.verdictTitle.textContent = t(v.titleKey);
    e.verdictDesc.textContent = t(v.descKey);

    if (data.image) {
      let imgSrc = data.image;
      if (imgSrc.startsWith('/api/')) {
        imgSrc = (window._API_BASE || '') + imgSrc;
      }
      e.productImage.src = imgSrc;
      e.productImageWrap.style.display = 'block';
    } else {
      e.productImageWrap.style.display = 'none';
    }

    e.productName.textContent = data.name || '—';
    e.barcodeType.textContent = data.format || '—';
    e.barcodeNumber.textContent = data.barcode || '—';

    _renderHalalGrid(data);
    _renderFactoryNotice(data.sameFactory);

    e.ingredientsText.textContent = data.ingredients || '';
    e.ingredientsPanel.style.display = 'none';

    e.resultSection.style.display = 'block';
    e.resultSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function _renderHalalGrid(data) {
    const grid = els().halalGrid;
    const checks = [
      { icon: '🐖', labelKey: 'bc.flag.pork',     bad: data.pork },
      { icon: '🍷', labelKey: 'bc.flag.alcohol',   bad: data.alcohol },
      { icon: '🍗', labelKey: 'bc.grid.meat',      bad: data.meat },
      { icon: '🦐', labelKey: 'bc.grid.seafood',   bad: data.seafood }
    ];
    grid.innerHTML = '';
    checks.forEach(c => {
      const ok = !c.bad;
      const label = t(c.labelKey);
      const el = document.createElement('div');
      el.className = `halal-cell ${ok ? 'halal-cell--ok' : 'halal-cell--bad'}`;
      el.innerHTML = `
        <span class="halal-cell__icon">${c.icon}</span>
        <div class="halal-cell__info">
          <span class="halal-cell__name">${label}</span>
          <span class="halal-cell__tag">${ok ? '✅ ' + t('bc.absent') : '❌ ' + t('bc.present')}</span>
        </div>`;
      grid.appendChild(el);
    });
  }

  function _renderFactoryNotice(sameFactory) {
    const e = els();
    if (sameFactory) {
      e.factoryNotice.className = 'factory-bar factory-bar--warn';
      e.factoryIcon.textContent = '🏭';
      e.factoryText.textContent = t('bc.factoryWarn');
    } else {
      e.factoryNotice.className = 'factory-bar factory-bar--ok';
      e.factoryIcon.textContent = '✅';
      e.factoryText.textContent = t('bc.factoryOk');
    }
    e.factoryNotice.style.display = 'flex';
  }

  // --- Discover section ---
  function showDiscover(visible) {
    els().discoverSection.style.display = visible ? 'block' : 'none';
  }

  // --- Clipboard ---
  async function copyToClipboard(text, tg) {
    const e = els();
    try { await navigator.clipboard.writeText(text); }
    catch (err) {
      const ta = document.createElement('textarea');
      ta.value = text; document.body.appendChild(ta);
      ta.select(); document.execCommand('copy');
      document.body.removeChild(ta);
    }
    e.copyBtn.classList.add('copied');
    e.copyBtn.innerHTML = '<span>✅</span>';
    setTimeout(() => {
      e.copyBtn.classList.remove('copied');
      e.copyBtn.innerHTML = '<span>📋</span>';
    }, 1500);
    if (tg && tg.showAlert) tg.showAlert(t('bc.copied'));
  }

  // --- Sound ---
  function playSuccessSound() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain); gain.connect(ctx.destination);
      osc.frequency.value = 1000; osc.type = 'sine';
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
      osc.start(ctx.currentTime); osc.stop(ctx.currentTime + 0.15);
    } catch (e) {}
  }

  // --- i18n: apply translations to all data-i18n elements ---
  function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const val = t(key);
      if (val && val !== key) {
        if (el.tagName === 'TITLE') document.title = val;
        else el.textContent = val;
      }
    });
    // HTML translations (for disclaimer with <strong>/<a>)
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
      const key = el.getAttribute('data-i18n-html');
      const val = t(key);
      if (val && val !== key) el.innerHTML = val;
    });
  }

  function getVideoElement() { return els().videoElement; }

  // --- Fullscreen image viewer ---
  function openFullscreenImage(src) {
    const e = els();
    e.fullscreenImg.src = src;
    e.fullscreenViewer.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  function closeFullscreenImage() {
    const e = els();
    e.fullscreenViewer.classList.remove('active');
    e.fullscreenImg.src = '';
    // Only restore scroll if modal isn't open behind it
    const modal = document.getElementById('productModal');
    if (!modal || modal.style.display === 'none') {
      document.body.style.overflow = '';
    }
  }
  
  return {
    showState, showError,
    updateStatus, updateCameraInfo,
    showTorch, updateTorchIcon, showSwitchBtn,
    flashFocusIndicator, showScanBeam,
    hideAllResults, showNotFound, showProductResult,
    showDiscover,
    showProductModal, hideProductModal,
    copyToClipboard, playSuccessSound,
    applyTranslations, openFullscreenImage, closeFullscreenImage,
    getVideoElement
  };
})();
