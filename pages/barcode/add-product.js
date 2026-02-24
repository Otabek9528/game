// add-product.js — Add Product Wizard Module
// 3-step wizard: photo capture → flags → submit
// Depends on: Camera, UI, AppActions
// Exposes: window.AddProduct
// ============================================

window.AddProduct = (() => {

  let barcode = '';
  let photoBlob = null;
  let flags = { pork: false, alcohol: false, meat: false, seafood: false, factory: false, allhalal: false };

  const FLAG_IDS = {
    pork: 'flagPork', alcohol: 'flagAlcohol', meat: 'flagMeat',
    seafood: 'flagSeafood', factory: 'flagFactory', allhalal: 'flagAllHalal'
  };

  const STEP_LABELS = {
    1: '📸 Mahsulot rasmi', '1b': '📸 Rasmni tekshiring',
    2: '🏷️ Ta\'qiqlangan moddalar', 3: '📤 Yuborilmoqda', '3b': '✅ Yuborildi'
  };

  // === PUBLIC ===
  function start(scannedBarcode) {
    barcode = scannedBarcode;
    photoBlob = null;
    _resetFlags();
    document.getElementById('wizardBarcode').textContent = barcode;
    if (window.Scanner) Scanner.stop();
    UI.showState('wizard');
    _goToStep(1);
    _openCaptureCamera();
  }

  // === STEP NAVIGATION ===
  function _goToStep(step) {
    ['wizardStep1','wizardStep1b','wizardStep2','wizardStep3','wizardStep3b']
      .forEach(id => document.getElementById(id).style.display = 'none');
    document.getElementById(`wizardStep${step}`).style.display = 'block';
    _updateDots(step);
    document.getElementById('wizardStepLabel').textContent = STEP_LABELS[step] || '';
    document.getElementById('addProductWizard').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function _updateDots(step) {
    const dots = [document.getElementById('stepDot1'), document.getElementById('stepDot2'), document.getElementById('stepDot3')];
    dots.forEach(d => d.className = 'step-dot');

    if (step === 1 || step === '1b') {
      dots[0].classList.add('step-dot--active');
    } else if (step == 2) {
      dots[0].classList.add('step-dot--done');
      dots[1].classList.add('step-dot--active');
    } else if (step == 3) {
      dots[0].classList.add('step-dot--done');
      dots[1].classList.add('step-dot--done');
      dots[2].classList.add('step-dot--active');
    } else if (step === '3b') {
      dots.forEach(d => d.classList.add('step-dot--done'));
    }
  }

  // === STEP 1: CAMERA ===
  async function _openCaptureCamera() {
    try {
      await Camera.openForCapture(document.getElementById('captureVideo'));
    } catch (e) {
      console.error('Capture camera failed:', e);
      _goToStep(2); // Skip photo
    }
  }

  async function _takePhoto() {
    try {
      photoBlob = await Camera.grabPhoto(document.getElementById('captureVideo'));
      Camera.detach(document.getElementById('captureVideo'));
      document.getElementById('previewImage').src = URL.createObjectURL(photoBlob);
      _goToStep('1b');
    } catch (e) { console.error('Photo capture failed:', e); }
  }

  function _retakePhoto() {
    photoBlob = null;
    _goToStep(1);
    _openCaptureCamera();
  }

  function _confirmPhoto() {
    Camera.detach(document.getElementById('captureVideo'));
    _goToStep(2);
  }

  // === STEP 2: FLAGS ===
  function _resetFlags() {
    flags = { pork: false, alcohol: false, meat: false, seafood: false, factory: false, allhalal: false };
    Object.values(FLAG_IDS).forEach(id => {
      const el = document.getElementById(id);
      if (el) {
        el.classList.remove('flag-toggle--active', 'flag-toggle--active-safe');
        el.querySelector('.flag-toggle__check').textContent = '';
      }
    });
  }

  function _toggleFlag(name) {
    if (name === 'allhalal') {
      const wasOn = flags.allhalal;
      _resetFlags();
      if (!wasOn) {
        flags.allhalal = true;
        _applyVisual('allhalal', true, true);
      }
      return;
    }
    // Deselect "all halal"
    if (flags.allhalal) {
      flags.allhalal = false;
      _applyVisual('allhalal', false, true);
    }
    flags[name] = !flags[name];
    _applyVisual(name, flags[name], false);
  }

  function _applyVisual(name, active, safe) {
    const el = document.getElementById(FLAG_IDS[name]);
    if (!el) return;
    el.classList.remove('flag-toggle--active', 'flag-toggle--active-safe');
    const check = el.querySelector('.flag-toggle__check');
    if (active) {
      el.classList.add(safe ? 'flag-toggle--active-safe' : 'flag-toggle--active');
      check.textContent = '✓';
    } else {
      check.textContent = '';
    }
  }

  // === STEP 3: SUBMIT ===
  async function _submit() {
    _goToStep(3);
    try {
      let photoB64 = '';
      if (photoBlob) {
        photoB64 = await new Promise((res, rej) => {
          const r = new FileReader();
          r.onloadend = () => res(r.result);
          r.onerror = rej;
          r.readAsDataURL(photoBlob);
        });
      }

      const payload = {
        barcode, photo: photoB64,
        pork: flags.pork, alcohol: flags.alcohol,
        meat: flags.meat, seafood: flags.seafood,
        sameFactory: flags.factory, userId: ''
      };
      try {
        const u = window.Telegram?.WebApp?.initDataUnsafe?.user;
        if (u) payload.userId = String(u.id);
      } catch (e) {}

      const resp = await fetch(`${window._API_BASE || ''}/api/scanner/product/add`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const result = await resp.json();

      if (result.success) {
        _showConfirmation(result);
        // Log insertion
        try {
          const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
          fetch(`${window._API_BASE || ''}/api/log-interaction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              user_id: tgUser ? String(tgUser.id) : 'unknown',
              username: tgUser?.username || 'unknown',
              action: `scanner_inserted:${barcode}`
            })
          }).catch(() => {});
        } catch (e) {}
      } else {
        throw new Error(result.error || 'Xatolik');
      }
    } catch (err) {
      console.error('Submit failed:', err);
      const tg = window.Telegram?.WebApp;
      if (tg?.showAlert) tg.showAlert('Xatolik: ' + err.message);
      _goToStep(2);
    }
  }

  function _showConfirmation(result) {
    let verdictText = '✅ Joiz';
    if (result.verdict === 'harom') verdictText = '⛔️ Ta\'qiqlangan';
    else if (result.verdict === 'shubhali') verdictText = '⚠️ Shubhali';

    const labels = [];
    if (flags.pork) labels.push("🐖 Cho'chqa");
    if (flags.alcohol) labels.push('🍷 Alkogol');
    if (flags.meat) labels.push("🍗 Go'sht");
    if (flags.seafood) labels.push('🦐 Dengiz m.');
    if (flags.factory) labels.push('🏭 Bir zavod');
    if (flags.allhalal) labels.push('✅ Barchasi joiz');

    document.getElementById('confirmSummary').innerHTML = `
      <div class="confirm-summary__row">
        <span class="confirm-summary__label">Shtrix-kod</span>
        <span class="confirm-summary__value"><code>${barcode}</code></span>
      </div>
      <div class="confirm-summary__row">
        <span class="confirm-summary__label">Rasm</span>
        <span class="confirm-summary__value">${photoBlob ? '📸 Yuklangan' : "— Yo'q"}</span>
      </div>
      <div class="confirm-summary__row">
        <span class="confirm-summary__label">Holati</span>
        <span class="confirm-summary__value">${verdictText}</span>
      </div>
      <div class="confirm-summary__row">
        <span class="confirm-summary__label">Belgilar</span>
        <span class="confirm-summary__value">${labels.join(', ') || '—'}</span>
      </div>`;
    _goToStep('3b');
  }

  // === CANCEL ===
  function _cancel() {
    Camera.detach(document.getElementById('captureVideo'));
    photoBlob = null;
    _resetFlags();
    if (window.AppActions) window.AppActions.scanAgain();
  }

  // === INIT ===
  function init() {
    document.getElementById('shutterBtn').addEventListener('click', _takePhoto);
    document.getElementById('wizardCancelBtn1').addEventListener('click', _cancel);
    document.getElementById('retakeBtn').addEventListener('click', _retakePhoto);
    document.getElementById('confirmPhotoBtn').addEventListener('click', _confirmPhoto);
    document.getElementById('wizardBackBtn2').addEventListener('click', () => _goToStep('1b'));
    document.getElementById('wizardSubmitBtn').addEventListener('click', _submit);

    document.querySelectorAll('.flag-toggle[data-flag]').forEach(el => {
      el.addEventListener('click', () => _toggleFlag(el.getAttribute('data-flag')));
    });
  }

  return { init, start };
})();
