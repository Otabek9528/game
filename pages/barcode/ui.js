// ui.js — UI module
// Handles: state switching, viewfinder controls, status, clipboard, sound
// Product result rendering will be added in Milestone 3
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
      tipBar:           document.getElementById('tipBar'),
      // Wizard (referenced from add-product.js)
      addProductWizard: document.getElementById('addProductWizard')
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
      halol:    { emoji: '☪️', label: 'Halol', cls: 'halol' },
      harom:    { emoji: '⛔️', label: 'Harom', cls: 'harom' },
      shubhali: { emoji: '⚠️', label: 'Shubhali', cls: 'shubhali' }
    };
    const v = verdictMap[data.verdict] || verdictMap.halol;

    // Verdict badge
    const badge = document.getElementById('modalVerdict');
    badge.className = `modal-verdict modal-verdict--${v.cls}`;
    document.getElementById('modalVerdictEmoji').textContent = v.emoji;
    document.getElementById('modalVerdictLabel').textContent = v.label;

    // Image
    const imgWrap = document.getElementById('modalImgWrap');
    if (data.image) {
      document.getElementById('modalImg').src = data.image;
      imgWrap.style.display = 'block';
    } else {
      imgWrap.style.display = 'none';
    }

    // Name & barcode
    document.getElementById('modalName').textContent = data.name || '—';
    document.getElementById('modalBarcode').textContent = data.barcode || '—';

    // Halal grid
    const grid = document.getElementById('modalHalalGrid');
    const checks = [
      { icon: '🐖', label: "Cho'chqa", bad: data.pork },
      { icon: '🍷', label: 'Alkogol', bad: data.alcohol },
      { icon: '🍗', label: "Go'sht", bad: data.meat },
      { icon: '🦐', label: 'Dengiz m.', bad: data.seafood }
    ];
    grid.innerHTML = '';
    checks.forEach(c => {
      const ok = !c.bad;
      const el = document.createElement('div');
      el.className = `modal-halal-cell ${ok ? 'modal-halal-cell--ok' : 'modal-halal-cell--bad'}`;
      el.innerHTML = `<span class="modal-halal-cell__icon">${c.icon}</span>${ok ? "✅ " + c.label + " yo'q" : "❌ " + c.label + " bor"}`;
      grid.appendChild(el);
    });

    // Factory
    const factory = document.getElementById('modalFactory');
    if (data.sameFactory !== undefined) {
      factory.className = `modal-factory ${data.sameFactory ? 'modal-factory--warn' : 'modal-factory--ok'}`;
      document.getElementById('modalFactoryIcon').textContent = data.sameFactory ? '🏭' : '✅';
      document.getElementById('modalFactoryText').textContent = data.sameFactory
        ? "Harom mahsulotlar ishlab chiqarilgan uskunalarda tayyorlangan"
        : "Toza ishlab chiqarish";
      factory.style.display = 'flex';
    } else {
      factory.style.display = 'none';
    }

    // Ingredients
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

  // --- Scan beam control ---
  function showScanBeam(visible) {
    const beam = els().scanBeam;
    if (beam) beam.style.display = visible ? 'block' : 'none';
  }

  // --- Result sections visibility ---
  function hideAllResults() {
    const e = els();
    e.resultSection.style.display = 'none';
    e.notFoundSection.style.display = 'none';
  }

  function showNotFound(barcode) {
    const e = els();
    e.resultSection.style.display = 'none';
    e.notFoundBarcode.textContent = barcode;
    e.notFoundSection.style.display = 'block';
    e.notFoundSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  // --- Product result (Milestone 3 will flesh this out) ---
  function showProductResult(data) {
    const e = els();
    e.notFoundSection.style.display = 'none';

    // Verdict
    e.verdictBanner.className = `verdict verdict--${data.verdict}`;
    const verdictMap = {
      halol:    { emoji: '☪️', title: 'Halol', desc: 'Tarkibida harom ingredientlar topilmadi' },
      harom:    { emoji: '⛔️', title: 'Harom', desc: 'Tarkibida harom ingredientlar aniqlandi' },
      shubhali: { emoji: '⚠️', title: 'Shubhali', desc: "Harom moddalar yo'q, lekin bir zavodda ishlab chiqarilgan" }
    };
    const v = verdictMap[data.verdict] || verdictMap.halol;
    e.verdictEmoji.textContent = v.emoji;
    e.verdictTitle.textContent = v.title;
    e.verdictDesc.textContent = v.desc;

    // Image
    if (data.image) {
      e.productImage.src = data.image;
      e.productImageWrap.style.display = 'block';
    } else {
      e.productImageWrap.style.display = 'none';
    }

    // Name & barcode
    e.productName.textContent = data.name || '—';
    e.barcodeType.textContent = data.format || '—';
    e.barcodeNumber.textContent = data.barcode || '—';

    // Halal grid
    _renderHalalGrid(data);

    // Factory
    _renderFactoryNotice(data.sameFactory);

    // Ingredients
    e.ingredientsText.textContent = data.ingredients || '';
    e.ingredientsPanel.style.display = 'none';

    e.resultSection.style.display = 'block';
    e.resultSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function _renderHalalGrid(data) {
    const grid = els().halalGrid;
    const checks = [
      { icon: '🐖', label: "Cho'chqa",      bad: data.pork },
      { icon: '🍷', label: 'Alkogol',        bad: data.alcohol },
      { icon: '🍗', label: "Boshqa go'sht",  bad: data.meat },
      { icon: '🦐', label: 'Dengiz m.',      bad: data.seafood }
    ];
    grid.innerHTML = '';
    checks.forEach(c => {
      const ok = !c.bad;
      const el = document.createElement('div');
      el.className = `halal-cell ${ok ? 'halal-cell--ok' : 'halal-cell--bad'}`;
      el.innerHTML = `
        <span class="halal-cell__icon">${c.icon}</span>
        <div class="halal-cell__info">
          <span class="halal-cell__name">${c.label}</span>
          <span class="halal-cell__tag">${ok ? "✅ Yo'q" : '❌ Bor'}</span>
        </div>`;
      grid.appendChild(el);
    });
  }

  function _renderFactoryNotice(sameFactory) {
    const e = els();
    if (sameFactory) {
      e.factoryNotice.className = 'factory-bar factory-bar--warn';
      e.factoryIcon.textContent = '🏭';
      e.factoryText.textContent = "Mahsulot harom mahsulotlar tayyorlangan uskunalarda ishlab chiqarilgan.";
    } else {
      e.factoryNotice.className = 'factory-bar factory-bar--ok';
      e.factoryIcon.textContent = '✅';
      e.factoryText.textContent = "Korxonada harom mahsulotlar ishlatilinmaydi.";
    }
    e.factoryNotice.style.display = 'flex';
  }

  // --- Discover section ---
  function showDiscover(visible) {
    els().discoverSection.style.display = visible ? 'block' : 'none';
    els().tipBar.style.display = visible ? 'block' : 'none';
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
    if (tg && tg.showAlert) tg.showAlert('Nusxalandi! ✅');
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

  function getVideoElement() { return els().videoElement; }

  return {
    showState, showError,
    updateStatus, updateCameraInfo,
    showTorch, updateTorchIcon, showSwitchBtn,
    flashFocusIndicator, showScanBeam,
    hideAllResults, showNotFound, showProductResult,
    showDiscover,
    showProductModal, hideProductModal,
    copyToClipboard, playSuccessSound,
    getVideoElement
  };
})();
