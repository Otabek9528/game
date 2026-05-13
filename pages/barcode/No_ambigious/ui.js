// ui.js — UI module (M7)
// M7: store-scope branching removed. Found-in banner simplified.
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
      fullscreenViewer:  document.getElementById('fullscreenViewer'),
      fullscreenImg:     document.getElementById('fullscreenImg')
    };
    return _els;
  }

  // ============================================
  // Verdict / store helpers
  // ============================================
  const VERDICT_MAP = {
    joiz:     { emoji: '✅', cls: 'joiz',        labelKey: 'bc.verdictJoiz',        descKey: 'bc.verdictJoizDesc' },
    nojoiz:   { emoji: '⛔️', cls: 'taqiqlangan', labelKey: 'bc.verdictTaqiqlangan', descKey: 'bc.verdictTaqiqlanganDesc' },
    shubhali: { emoji: '⚠️', cls: 'shubhali',    labelKey: 'bc.verdictShubhali',    descKey: 'bc.verdictShubhaliDesc' }
  };

  const EMBLEM_FILES = {
    'No Brand': 'nobrand.png', 'Emart24': 'emart24.png', '7-Eleven': '7_11.png',
    'GS25': 'gs25.png', 'CU': 'cu.png', 'Daiso': 'daiso.png'
  };

  function _verdictConf(v) {
    return VERDICT_MAP[(v || '').toLowerCase()] || VERDICT_MAP.joiz;
  }

  function _esc(s) {
    const d = document.createElement('div');
    d.textContent = s == null ? '' : String(s);
    return d.innerHTML;
  }

  function _resolveImg(src) {
    if (!src) return '';
    if (src.startsWith('/api/')) return (window._API_BASE || '') + src;
    return src;
  }

  // --- State switching ---
  function showState(state) {
    const e = els();
    e.permissionState.style.display = 'none';
    e.errorState.style.display = 'none';
    e.scannerDisplay.style.display = 'none';

    switch (state) {
      case 'permission': e.permissionState.style.display = 'flex'; break;
      case 'error':      e.errorState.style.display = 'flex'; break;
      case 'scanner':    e.scannerDisplay.style.display = 'block'; break;
    }
  }

  function showError(msg) {
    els().errorMessage.textContent = msg;
    showState('error');
  }

  // ============================================
  // Product Detail Modal
  // ============================================
  function showProductModal(data) {
    const modal = document.getElementById('productModal');
    const v = _verdictConf(data.verdict);

    const badge = document.getElementById('modalVerdict');
    badge.className = `modal-verdict modal-verdict--${v.cls}`;
    document.getElementById('modalVerdictEmoji').textContent = v.emoji;
    document.getElementById('modalVerdictLabel').textContent = t(v.labelKey);

    const imgWrap = document.getElementById('modalImgWrap');
    const imgSrc = _resolveImg(data.image);
    if (imgSrc) {
      document.getElementById('modalImg').src = imgSrc;
      imgWrap.style.display = 'block';
    } else {
      imgWrap.style.display = 'none';
    }

    document.getElementById('modalName').textContent = data.name || data.nameEnglish || '—';
    document.getElementById('modalBarcode').textContent = data.barcode || '—';

    const grid = document.getElementById('modalHalalGrid');
    const checks = [
      { icon: '🐖', labelKey: 'bc.flag.pork',    bad: !!data.pork },
      { icon: '🍷', labelKey: 'bc.flag.alcohol', bad: !!data.alcohol },
      { icon: '🍗', labelKey: 'bc.grid.meat',    bad: !!data.meat },
      { icon: '🦐', labelKey: 'bc.grid.seafood', bad: !!data.seafood }
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
    if (data.sameFactory !== undefined && data.sameFactory !== null) {
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
    const foundBanner = document.getElementById('foundInBanner');
    if (foundBanner) foundBanner.remove();
    const otherStripe = document.getElementById('otherStoresStripe');
    if (otherStripe) otherStripe.remove();
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

  // ============================================
  // Product result — M7: simplified store info
  // ============================================
  function showProductResult(data) {
    const e = els();
    e.notFoundSection.style.display = 'none';
    e.viewfinderWrap.style.display = 'none';
    document.querySelector('.status-bar').style.display = 'none';

    const v = _verdictConf(data.verdict);
    e.verdictBanner.className = `verdict verdict--${v.cls}`;
    e.verdictEmoji.textContent = v.emoji;
    e.verdictTitle.textContent = t(v.labelKey);
    e.verdictDesc.textContent = t(v.descKey);

    const imgSrc = _resolveImg(data.image);
    if (imgSrc) {
      e.productImage.src = imgSrc;
      e.productImageWrap.style.display = 'block';
    } else {
      e.productImageWrap.style.display = 'none';
    }

    e.productName.textContent = data.name || data.nameEnglish || '—';
    e.barcodeType.textContent = data.format || '—';
    e.barcodeNumber.textContent = data.barcode || '—';

    _renderHalalGrid(data);
    _renderFactoryNotice(data.sameFactory);

    e.ingredientsText.textContent = data.ingredients || '';
    e.ingredientsPanel.style.display = 'none';

    _renderFoundInBanner(data);
    _renderOtherStoresStripe(data);

    e.resultSection.style.display = 'block';
    e.resultSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  // M7: simplified — only "Topildi: <store>" or "Umumiy ma'lumotlar bazasi"
  function _renderFoundInBanner(data) {
    const result = els().resultSection;
    if (!result) return;
    const prev = document.getElementById('foundInBanner');
    if (prev) prev.remove();

    let kind, html;
    if (data.source === 'store_products' && data.store) {
      kind = 'inStore';
      const file = EMBLEM_FILES[data.store];
      html = `
        ${file ? `<img class="store-info-banner__emblem" src="../../assets/stores/${file}" alt="" onerror="this.style.display='none'">` : ''}
        <span class="store-info-banner__text">
          <span data-i18n="bc.store.foundIn">Topildi:</span>
          <strong>${_esc(data.store)}</strong>
        </span>`;
    } else if (data.source === 'general') {
      kind = 'general';
      html = `
        <span class="store-info-banner__icon">📚</span>
        <span class="store-info-banner__text">
          <span data-i18n="bc.store.generalDb">Umumiy ma'lumotlar bazasi</span>
          <span class="store-info-banner__sub" data-i18n="bc.store.storeUnknown">· Do'kon belgilanmagan</span>
        </span>`;
    } else {
      return;
    }

    const banner = document.createElement('div');
    banner.id = 'foundInBanner';
    banner.className = `store-info-banner store-info-banner--${kind === 'inStore' ? 'inThisStore' : 'general'}`;
    banner.innerHTML = html;
    result.insertBefore(banner, result.firstChild);
  }

  function _renderOtherStoresStripe(data) {
    const result = els().resultSection;
    if (!result) return;
    const prev = document.getElementById('otherStoresStripe');
    if (prev) prev.remove();

    const others = Array.isArray(data.otherStores) ? data.otherStores : [];
    if (others.length === 0) return;

    const stripe = document.createElement('div');
    stripe.id = 'otherStoresStripe';
    stripe.className = 'other-stores-stripe';

    const label = `<span class="other-stores-stripe__label" data-i18n="bc.store.alsoAt">Boshqa do'konlarda ham bor:</span>`;
    const chips = others.map(o => {
      const file = EMBLEM_FILES[o.store];
      const safe = _esc(o.store);
      const emblemHtml = file
        ? `<img class="other-stores-stripe__emblem" src="../../assets/stores/${file}" alt="${safe}" onerror="this.style.display='none'">`
        : '';
      return `<span class="other-stores-stripe__chip" title="${safe}">${emblemHtml}<span>${safe}</span></span>`;
    }).join('');

    stripe.innerHTML = label + `<div class="other-stores-stripe__chips">${chips}</div>`;
    result.appendChild(stripe);
  }

  function _renderHalalGrid(data) {
    const grid = els().halalGrid;
    const checks = [
      { icon: '🐖', labelKey: 'bc.flag.pork',     bad: !!data.pork },
      { icon: '🍷', labelKey: 'bc.flag.alcohol',   bad: !!data.alcohol },
      { icon: '🍗', labelKey: 'bc.grid.meat',      bad: !!data.meat },
      { icon: '🦐', labelKey: 'bc.grid.seafood',   bad: !!data.seafood }
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
    if (sameFactory === undefined || sameFactory === null) {
      e.factoryNotice.style.display = 'none';
      return;
    }
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

  // --- i18n ---
  function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const val = t(key);
      if (val && val !== key) {
        if (el.tagName === 'TITLE') document.title = val;
        else el.textContent = val;
      }
    });
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
      const key = el.getAttribute('data-i18n-html');
      const val = t(key);
      if (val && val !== key) el.innerHTML = val;
    });
    // Manual entry placeholder
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      const key = el.getAttribute('data-i18n-placeholder');
      const val = t(key);
      if (val && val !== key) el.setAttribute('placeholder', val);
    });
  }

  function getVideoElement() { return els().videoElement; }

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
    showProductModal, hideProductModal,
    copyToClipboard, playSuccessSound,
    applyTranslations, openFullscreenImage, closeFullscreenImage,
    getVideoElement
  };
})();
