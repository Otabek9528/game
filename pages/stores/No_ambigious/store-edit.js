// ============================================
// store-edit.js — Edit-submission modal module
// All fields editable: barcode, store, category, flags, photo.
// Depends on: window.Camera, window.StoreUI, window.StoreSubmissions,
//             window.StoreAppActions
// Exposes:    window.StoreEdit
// ============================================

window.StoreEdit = (() => {

  const STORES = ['GS25', 'CU', '7-Eleven', 'Emart24', 'No Brand', 'Daiso'];
  const STORE_CLS = {
    'GS25':     'store-card--gs25',
    'CU':       'store-card--cu',
    '7-Eleven': 'store-card--seven',
    'Emart24':  'store-card--emart',
    'No Brand': 'store-card--nobrand',
    'Daiso':    'store-card--daiso',
  };
  const STORE_LOGO = {
    'GS25':     'GS25',
    'CU':       'CU',
    '7-Eleven': '7-<em>Eleven</em>',
    'Emart24':  'emart<em>24</em>',
    'No Brand': 'No Brand',
    'Daiso':    'DAISO',
  };

  // ----- session state -----
  let _original = null;       // untouched row from server
  let _state = null;          // editable snapshot
  let _photoBlob = null;      // new photo taken in modal (replaces)
  let _photoObjectUrl = null;
  let _saving = false;
  let _onSaved = null;        // callback(product)

  const API_BASE = () => window._SC_API_BASE || '';
  const USER_ID  = () => (window.StoreAppActions && StoreAppActions.getUserId()) || '';

  // ============================================
  // INIT
  // ============================================
  function init(opts) {
    opts = opts || {};
    _onSaved = opts.onSaved || (() => {});

    const backdrop = document.getElementById('editBackdrop');
    const close    = document.getElementById('editCloseBtn');
    const save     = document.getElementById('editSaveBtn');

    if (backdrop) backdrop.addEventListener('click', _close);
    if (close)    close.addEventListener('click',    _close);
    if (save)     save.addEventListener('click',     _save);
  }

  // ============================================
  // OPEN
  // ============================================
  function open(product) {
    if (!product) return;
    _original = product;
    _state = _cloneToState(product);
    _photoBlob = null;
    if (_photoObjectUrl) { URL.revokeObjectURL(_photoObjectUrl); _photoObjectUrl = null; }

    const body = document.getElementById('editBody');
    if (!body) return;
    body.innerHTML = _renderBody();
    _bindBody();
    _updateSaveEnabled();

    const modal = document.getElementById('editModal');
    if (modal) modal.style.display = 'flex';
  }

  function _cloneToState(p) {
    return {
      publicId: p.publicId,
      barcode:  p.barcode || '',
      store:    p.store   || '',
      category: p.category || '',
      pork:        !!p.pork,
      alcohol:     !!p.alcohol,
      meat:        !!p.meat,
      seafood:     !!p.seafood,
      sameFactory: !!p.sameFactory,
      allHalal:    !!p.allHalal,
      // Photo: prefer existing path reference
      photoPath: p.photo || '',
      image:     p.image || '',
    };
  }

  // ============================================
  // RENDER (inside #editBody)
  // ============================================
  function _renderBody() {
    return `
      <!-- Barcode (editable) -->
      <section class="form-section edit-section">
        <h4 class="form-section__title">
          <span class="form-section__num">1</span>
          Shtrix-kod
          <span class="form-section__req">*</span>
        </h4>
        <input class="sc-input" id="editBarcode" type="text" inputmode="numeric"
          value="${_esc(_state.barcode)}" autocomplete="off" />
      </section>

      <!-- Store -->
      <section class="form-section edit-section">
        <h4 class="form-section__title">
          <span class="form-section__num">2</span>
          Do'kon
          <span class="form-section__req">*</span>
        </h4>
        <div class="edit-store-grid" id="editStoreGrid">
          ${STORES.map(s => `
            <button class="edit-store-chip ${STORE_CLS[s]} ${s === _state.store ? 'edit-store-chip--active' : ''}"
                    data-store="${_esc(s)}" type="button">
              <span class="edit-store-chip__logo">${STORE_LOGO[s]}</span>
              <span class="edit-store-chip__check">✓</span>
            </button>
          `).join('')}
        </div>
      </section>

      <!-- Category -->
      <section class="form-section edit-section">
        <h4 class="form-section__title">
          <span class="form-section__num">3</span>
          Kategoriya
          <span class="form-section__req">*</span>
        </h4>
        <div class="category-grid" id="editCategoryGrid">
          ${_renderCategoryChips(_state.category)}
        </div>
      </section>

      <!-- Flags -->
      <section class="form-section edit-section">
        <h4 class="form-section__title">
          <span class="form-section__num">4</span>
          Tarkibdagi belgilar
          <span class="form-section__req">*</span>
        </h4>
        <p class="form-section__hint">
          Kamida bitta belgini tanlang. <strong>"Barchasi halol"</strong> tanlansa, boshqalari o'chiriladi va aksincha.
        </p>
        <div class="flag-list" id="editFlagList">
          ${_renderFlagRow('allhalal', '☪️', 'Barchasi halol',
                           "Ta'qiqlangan tarkib yo'q, ishlab chiqarish ham toza",
                           _state.allHalal, true)}
          <div class="flag-divider"><span>yoki alohida belgilar</span></div>
          ${_renderFlagRow('pork',    '🐖', "Cho'chqa mahsuloti",   'Tarkibda cho\'chqa go\'shti yoki jelatini bor',                _state.pork,        false)}
          ${_renderFlagRow('alcohol', '🍷', 'Alkogol',              'Spirt, vino, pivo yoki shunga o\'xshash',                     _state.alcohol,     false)}
          ${_renderFlagRow('meat',    '🍗', "Boshqa go'sht",        'Halol bo\'lmagan mol, tovuq va boshqa go\'sht',               _state.meat,        false)}
          ${_renderFlagRow('seafood', '🦐', 'Dengiz mahsulotlari',  'Qisqichbaqa, kalmar, ustritsa va h.k.',                       _state.seafood,     false)}
          ${_renderFlagRow('factory', '🏭', 'Bir xil zavod',        'Ta\'qiqlangan mahsulotlar ishlab chiqariladigan zavodda tayyorlangan', _state.sameFactory, false)}
        </div>
      </section>

      <!-- Photo -->
      <section class="form-section edit-section">
        <h4 class="form-section__title">
          <span class="form-section__num">5</span>
          Mahsulot rasmi
          <span class="form-section__req">*</span>
        </h4>
        <div class="photo-box" id="editPhotoBox">
          ${_renderPhotoBox()}
        </div>
      </section>

      <div class="edit-danger-note">
        <span>⚠️</span>
        <p>Shtrix-kod yoki do'konni o'zgartirsangiz, boshqa do'kondagi mavjud yozuv bilan to'qnashuv yuzaga kelishi mumkin.</p>
      </div>
      
      <div class="edit-footer">
        <button class="sc-btn sc-btn--primary sc-btn--block" id="editSaveBtnBottom" type="button">
          <span>✓</span><span>Saqlash</span>
        </button>
      </div>
    `;
  }

  function _renderCategoryChips(active) {
    const cats = [
      ['Drinks','🥤','Ichimliklar'],
      ['Snacks','🍿','Gazaklar'],
      ['Sweets','🍬','Shirinliklar'],
      ['Ice Cream','🍦','Muzqaymoq'],
      ['Baked Goods','🥐','Non mahsulotlari'],
      ['Cup Noodles/Ramen','🍜',"Lag'mon / Ramen"],
      ['Lunchbox/Dosirak','🍩','Pechenya/Pishiriqlar'],
      ['Dairy','🥛','Sut mahsulotlari'],
      ['Canned Food','🥫','Konserva'],
      ['Frozen Food','🧊','Muzlatilgan'],
      ['Condiments/Sauces','🧂','Sous va ziravorlar'],
      ['Fruits/Vegetables','🥬','Meva va sabzavot'],
      ['Dried Food','🌾','Quruq mahsulot'],
    ];
    return cats.map(([k,ic,lbl]) => `
      <button class="cat-chip ${k === active ? 'cat-chip--active' : ''}" data-cat="${_esc(k)}" type="button">
        <span class="cat-chip__icon">${ic}</span>
        <span class="cat-chip__label">${_esc(lbl)}</span>
      </button>
    `).join('');
  }

  function _renderFlagRow(flag, icon, name, desc, active, safe) {
    const cls = active ? (safe ? 'flag-toggle--active-safe' : 'flag-toggle--active') : '';
    const check = active ? '✓' : '';
    return `
      <button class="flag-toggle ${cls}" data-flag="${_esc(flag)}" type="button">
        <span class="flag-toggle__icon">${icon}</span>
        <div class="flag-toggle__content">
          <p class="flag-toggle__name">${_esc(name)}</p>
          <p class="flag-toggle__desc">${_esc(desc)}</p>
        </div>
        <div class="flag-toggle__check">${check}</div>
      </button>
    `;
  }

  function _renderPhotoBox() {
    // Priorities: new blob preview > existing path (reused) > empty.
    if (_photoObjectUrl) {
      return `
        <div class="photo-box__preview" style="display:block;">
          <img id="editPhotoImg" src="${_esc(_photoObjectUrl)}" alt="" />
          <div class="photo-box__preview-actions">
            <button class="sc-btn sc-btn--ghost sc-btn--sm" id="editRetakeBtn" type="button">
              <span>🔄</span><span>Qayta olish</span>
            </button>
            <button class="sc-btn sc-btn--ghost sc-btn--sm sc-btn--danger" id="editRemovePhotoBtn" type="button">
              <span>🗑️</span><span>O'chirish</span>
            </button>
          </div>
        </div>
      `;
    }
    if (_state.photoPath) {
      let src = _state.image || '';
      if (src && src.startsWith('/api/')) src = API_BASE() + src;
      return `
        <div class="photo-box__preview" style="display:block;">
          <img id="editPhotoImg" src="${_esc(src)}" alt="" />
          <span class="photo-box__tag">Saqlangan rasm</span>
          <div class="photo-box__preview-actions">
            <button class="sc-btn sc-btn--ghost sc-btn--sm" id="editRetakeBtn" type="button">
              <span>📷</span><span>Yangi rasm</span>
            </button>
            <button class="sc-btn sc-btn--ghost sc-btn--sm sc-btn--danger" id="editRemovePhotoBtn" type="button">
              <span>🗑️</span><span>O'chirish</span>
            </button>
          </div>
        </div>
      `;
    }
    return `
      <div class="photo-box__empty" style="display:flex;">
        <div class="photo-box__icon">📸</div>
        <p class="photo-box__hint">Rasm qo'shilmagan</p>
        <button class="sc-btn sc-btn--ghost sc-btn--sm" id="editOpenPhotoBtn" type="button">
          <span>📷</span><span>Kamerani ochish</span>
        </button>
      </div>
    `;
  }

  function _renderPhotoCapture() {
    return `
      <div class="photo-box__capture" style="display:block;">
        <div class="capture-camera">
          <video id="editCaptureVideo" autoplay playsinline muted></video>
          <div class="crosshair"></div>
          <div class="shutter-row">
            <button class="shutter-btn" id="editShutterBtn" type="button" title="Suratga olish"></button>
          </div>
        </div>
        <button class="photo-box__cancel" id="editCancelCaptureBtn" type="button">✕ Bekor qilish</button>
      </div>
    `;
  }

  // ============================================
  // BINDINGS (re-bound every re-render of body)
  // ============================================
  function _bindBody() {
    // Barcode
    const bc = document.getElementById('editBarcode');
    if (bc) {
      bc.addEventListener('input', () => {
        _state.barcode = (bc.value || '').trim();
        _updateSaveEnabled();
      });
    }

    // Stores
    const sg = document.getElementById('editStoreGrid');
    if (sg) {
      sg.addEventListener('click', (ev) => {
        const btn = ev.target.closest('.edit-store-chip');
        if (!btn) return;
        _state.store = btn.getAttribute('data-store');
        sg.querySelectorAll('.edit-store-chip').forEach(b => {
          b.classList.toggle('edit-store-chip--active', b === btn);
        });
        _updateSaveEnabled();
      });
    }

    // Categories
    const cg = document.getElementById('editCategoryGrid');
    if (cg) {
      cg.addEventListener('click', (ev) => {
        const chip = ev.target.closest('.cat-chip');
        if (!chip) return;
        _state.category = chip.getAttribute('data-cat');
        cg.querySelectorAll('.cat-chip').forEach(c => {
          c.classList.toggle('cat-chip--active', c === chip);
        });
        _updateSaveEnabled();
      });
    }

    // Flags
    const fl = document.getElementById('editFlagList');
    if (fl) {
      fl.addEventListener('click', (ev) => {
        const btn = ev.target.closest('.flag-toggle');
        if (!btn) return;
        _toggleFlag(btn.getAttribute('data-flag'));
      });
    }

    _bindPhoto();
    
    // Bottom save button (mirrors the top one)
    const saveBottom = document.getElementById('editSaveBtnBottom');
    if (saveBottom) saveBottom.addEventListener('click', _save);
  }

  function _toggleFlag(flag) {
    if (flag === 'allhalal') {
      const was = _state.allHalal;
      _state.pork = false; _state.alcohol = false; _state.meat = false;
      _state.seafood = false; _state.sameFactory = false;
      _state.allHalal = !was;
    } else {
      if (_state.allHalal) _state.allHalal = false;
      const map = { pork: 'pork', alcohol: 'alcohol', meat: 'meat',
                    seafood: 'seafood', factory: 'sameFactory' };
      const key = map[flag];
      if (!key) return;
      _state[key] = !_state[key];
    }
    _redrawFlagVisuals();
    _updateSaveEnabled();
  }

  function _redrawFlagVisuals() {
    const pairs = [
      ['allhalal', _state.allHalal,    true],
      ['pork',     _state.pork,        false],
      ['alcohol',  _state.alcohol,     false],
      ['meat',     _state.meat,        false],
      ['seafood',  _state.seafood,     false],
      ['factory',  _state.sameFactory, false],
    ];
    pairs.forEach(([flag, active, safe]) => {
      const el = document.querySelector(`#editFlagList .flag-toggle[data-flag="${flag}"]`);
      if (!el) return;
      el.classList.remove('flag-toggle--active', 'flag-toggle--active-safe');
      const check = el.querySelector('.flag-toggle__check');
      if (active) {
        el.classList.add(safe ? 'flag-toggle--active-safe' : 'flag-toggle--active');
        if (check) check.textContent = '✓';
      } else {
        if (check) check.textContent = '';
      }
    });
  }

  // ============================================
  // PHOTO (reusing Camera module)
  // ============================================
  function _bindPhoto() {
    const openBtn   = document.getElementById('editOpenPhotoBtn');
    const retakeBtn = document.getElementById('editRetakeBtn');
    const removeBtn = document.getElementById('editRemovePhotoBtn');

    if (openBtn)   openBtn.addEventListener('click', _openCapture);
    if (retakeBtn) retakeBtn.addEventListener('click', _openCapture);
    if (removeBtn) removeBtn.addEventListener('click', _removePhoto);
  }

  async function _openCapture() {
    const box = document.getElementById('editPhotoBox');
    if (!box) return;
    box.innerHTML = _renderPhotoCapture();

    const shutter = document.getElementById('editShutterBtn');
    const cancel  = document.getElementById('editCancelCaptureBtn');
    if (shutter) shutter.addEventListener('click', _takePhoto);
    if (cancel)  cancel.addEventListener('click',  _cancelCapture);

    try {
      await Camera.openForCapture(document.getElementById('editCaptureVideo'));
    } catch (e) {
      console.error('edit capture camera failed:', e);
      StoreUI.toast("Kamerani ochib bo'lmadi", 'error');
      _redrawPhotoBox();
    }
  }

  async function _takePhoto() {
    try {
      const video = document.getElementById('editCaptureVideo');
      const blob  = await Camera.grabPhoto(video);
      Camera.detach(video);

      _photoBlob = blob;
      if (_photoObjectUrl) URL.revokeObjectURL(_photoObjectUrl);
      _photoObjectUrl = URL.createObjectURL(blob);
      // New blob replaces the stored path; on save, base64 will be sent.
      _redrawPhotoBox();
      _updateSaveEnabled();
    } catch (e) {
      console.error('edit grabPhoto failed:', e);
      StoreUI.toast("Suratga olib bo'lmadi", 'error');
    }
  }

  function _cancelCapture() {
    Camera.detach(document.getElementById('editCaptureVideo'));
    _redrawPhotoBox();
  }

  function _removePhoto() {
    _photoBlob = null;
    if (_photoObjectUrl) { URL.revokeObjectURL(_photoObjectUrl); _photoObjectUrl = null; }
    // Clear the reference so the save button disables until user retakes.
    _state.photoPath = '';
    _state.image = '';
    _redrawPhotoBox();
    _updateSaveEnabled();
  }

  function _redrawPhotoBox() {
    const box = document.getElementById('editPhotoBox');
    if (box) {
      box.innerHTML = _renderPhotoBox();
      _bindPhoto();
    }
  }

  // ============================================
  // SAVE ENABLE GATE
  // ============================================
  function _hasAnyFlag() {
    return _state.pork || _state.alcohol || _state.meat ||
           _state.seafood || _state.sameFactory || _state.allHalal;
  }

  function _hasChanges() {
    const p = _original;
    if (!p) return false;
    if ((_state.barcode || '') !== (p.barcode || ''))   return true;
    if ((_state.store || '')   !== (p.store || ''))     return true;
    if ((_state.category || '')!== (p.category || ''))  return true;
    if (!!_state.pork        !== !!p.pork)        return true;
    if (!!_state.alcohol     !== !!p.alcohol)     return true;
    if (!!_state.meat        !== !!p.meat)        return true;
    if (!!_state.seafood     !== !!p.seafood)     return true;
    if (!!_state.sameFactory !== !!p.sameFactory) return true;
    if (!!_state.allHalal    !== !!p.allHalal)    return true;
    if (_photoBlob) return true;
    return false;
  }

  function _isValid() {
    if (!_state.barcode) return false;
    if (!_state.store) return false;
    if (!_state.category) return false;
    if (!_hasAnyFlag()) return false;
    // Photo required: either a new blob or an existing stored path
    if (!_photoBlob && !_state.photoPath) return false;
    return true;
  }

  function _updateSaveEnabled() {
    const disabled = _saving || !_isValid() || !_hasChanges();
    const top = document.getElementById('editSaveBtn');
    const bot = document.getElementById('editSaveBtnBottom');
    if (top) top.disabled = disabled;
    if (bot) bot.disabled = disabled;
  }

  // ============================================
  // SAVE (PUT)
  // ============================================
  async function _save() {
    if (_saving) return;
    if (!_isValid() || !_hasChanges()) return;

    _saving = true;
    _updateSaveEnabled();

    const payload = {
      userId:      USER_ID(),
      barcode:     _state.barcode,
      store:       _state.store,
      category:    _state.category,
      pork:        !!_state.pork,
      alcohol:     !!_state.alcohol,
      meat:        !!_state.meat,
      seafood:     !!_state.seafood,
      sameFactory: !!_state.sameFactory,
      allHalal:    !!_state.allHalal,
    };

    if (_photoBlob) {
      try {
        const compressed = (window.StoreUtils && StoreUtils.compressImage)
          ? await StoreUtils.compressImage(_photoBlob)
          : _photoBlob;
        payload.photo = await _blobToBase64(compressed);
      }
      catch (e) { console.error('base64 failed:', e); }
    }

    try {
      const url = `${API_BASE()}/api/store/product/${encodeURIComponent(_original.publicId)}`;
      const resp = await fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await resp.json().catch(() => ({}));

      if (resp.ok && data.success) {
        const updated = data.product;
        try {
          if (window.StoreSubmissions && StoreSubmissions.updateLocal) {
            StoreSubmissions.updateLocal(updated);
          }
        } catch (e) {}
        _onSaved(updated);
        _close();
        StoreUI.toast("Saqlandi", 'success');
        return;
      }

      // Error mapping
      let msg = data.error || "Saqlab bo'lmadi";
      if (resp.status === 403) msg = "Bu yozuvni faqat uni qo'shgan foydalanuvchi tahrirlay oladi.";
      if (resp.status === 404) msg = "Yozuv topilmadi. U o'chirilgan bo'lishi mumkin.";
      if (data && data.code === 'DUPLICATE') {
        msg = "Tanlangan do'konda ushbu shtrix-kod allaqachon mavjud.";
      }
      if (data && data.code === 'NO_FLAG') {
        msg = "Kamida bitta belgi kerak.";
      }
      StoreUI.toast(msg, 'error');
    } catch (e) {
      console.error('edit save failed:', e);
      StoreUI.toast("Ulanish xatoligi", 'error');
    } finally {
      _saving = false;
      _updateSaveEnabled();
    }
  }

  // ============================================
  // CLOSE
  // ============================================
  function _close() {
    if (_saving) return;
    try { Camera.detach(document.getElementById('editCaptureVideo')); } catch (e) {}
    if (_photoObjectUrl) { URL.revokeObjectURL(_photoObjectUrl); _photoObjectUrl = null; }
    _photoBlob = null;
    _original = null;
    _state = null;
    const modal = document.getElementById('editModal');
    if (modal) modal.style.display = 'none';
    const body = document.getElementById('editBody');
    if (body) body.innerHTML = '';
  }

  // ============================================
  // UTIL
  // ============================================
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

  return { init, open };
})();
