#!/usr/bin/env python3
"""
patch_frontend.py — Idempotent edits to the existing store collector frontend
to enable the no-store add flow by REUSING the existing UI (not duplicating).

Run:
  python3 patch_frontend.py /path/to/frontend/dir

Touches:
  - store-collector.html   (1 new button only)
  - store-app.js           (no-store branching in submit + scan paths)
  - store-form.js          (handle null/__NOSTORE__ store)
  - store-submissions.js   (merge main-DB Mine rows + delete routing)

Creates .bak copies on first run. Re-runnable.
"""

import os, sys, re


# ═══════════════════════════════════════════════════════════════════════════
# HTML — just the new button
# ═══════════════════════════════════════════════════════════════════════════
HTML_OLD = '''          <button class="store-card store-card--nobrand" data-store="No Brand">
            <span class="store-card__logo">No Brand</span>
            <span class="store-card__check">✓</span>
          </button>
        </div>'''

HTML_NEW = '''          <button class="store-card store-card--nobrand" data-store="No Brand">
            <span class="store-card__logo">No Brand</span>
            <span class="store-card__check">✓</span>
          </button>
          <button class="store-card store-card--nostore" data-store="__NOSTORE__">
            <span class="store-card__logo">+ Boshqa</span>
            <span class="store-card__check" style="background:#c8600a;color:#fff">↗</span>
          </button>
        </div>'''

HTML_CSS_HOOK = '</head>'
HTML_CSS_INJECT = '''  <style>
    /* store-card--nostore: special styling for the "no store" entry */
    .store-card--nostore {
      background: linear-gradient(135deg, #fff5e6 0%, #ffe9c2 100%);
      border-color: #c8600a;
    }
    .store-card--nostore .store-card__logo { color: #c8600a; font-weight: 700; }
    /* Mine card source indicator */
    .mine-card__store--main { background: rgba(200,96,10,0.1); color: #c8600a; font-weight: 700; }
  </style>
</head>'''


# ═══════════════════════════════════════════════════════════════════════════
# store-app.js — no-store branching
# ═══════════════════════════════════════════════════════════════════════════

# Edit A — store-picker click: handle __NOSTORE__
APP_OLD_A = '''    // Store picker
    document.getElementById('storeGrid').addEventListener('click', (ev) => {
      const card = ev.target.closest('.store-card');
      if (!card) return;
      selectedStore = card.getAttribute('data-store');
      StoreUI.setSelectedStoreCard(selectedStore);
      StoreUI.setSelectedStoreLabels(selectedStore);
      // Short delay so the selection animation is visible before transition
      setTimeout(goPermission, 180);
    });'''

APP_NEW_A = '''    // Store picker
    document.getElementById('storeGrid').addEventListener('click', (ev) => {
      const card = ev.target.closest('.store-card');
      if (!card) return;
      const storeAttr = card.getAttribute('data-store');
      if (storeAttr === '__NOSTORE__') {
        // No-store path: same UI flow, different submit endpoint.
        // selectedStore stays null; labels show a friendly placeholder.
        selectedStore = null;
        StoreUI.setSelectedStoreCard(null);
        StoreUI.setSelectedStoreLabels("🌐 Asosiy baza");
      } else {
        selectedStore = storeAttr;
        StoreUI.setSelectedStoreCard(selectedStore);
        StoreUI.setSelectedStoreLabels(selectedStore);
      }
      // Short delay so the selection animation is visible before transition
      setTimeout(goPermission, 180);
    });'''


# Edit B — _checkBarcode: in no-store mode, look up main products only
APP_OLD_B = '''  async function _checkBarcode(barcode) {
    if (window.StoreUtils && !StoreUtils.isOnline()) {
      StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
      return;
    }
    try {
      const url = `${API_BASE}/api/store/check/${encodeURIComponent(selectedStore)}/${encodeURIComponent(barcode)}`;'''

APP_NEW_B = '''  async function _checkBarcode(barcode) {
    if (window.StoreUtils && !StoreUtils.isOnline()) {
      StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
      return;
    }

    // No-store mode: skip the store-side /api/store/check call. Quickly probe
    // the main products table; if found, show the existing "already added"
    // state, else open the blank form. The /add endpoint will also do its
    // own dup check across BOTH tables as a final safety net.
    if (selectedStore === null) {
      try {
        const r = await fetch(`${API_BASE}/api/scanner/product/${encodeURIComponent(barcode)}`);
        const d = await r.json();
        if (d && d.found) {
          _stopScanner();
          // Reshape main-DB product into the schema renderAlreadyAdded expects.
          // Main vocab (halol/harom/shubhali) → store vocab (joiz/nojoiz/shubhali).
          const vmap = { halol: 'joiz', harom: 'nojoiz', shubhali: 'shubhali' };
          const reshaped = {
            barcode:  d.barcode,
            store:    "🌐 Asosiy baza",
            category: d.category || '',
            verdict:  vmap[d.verdict] || 'joiz',
            image:    d.image || '',
            pork:     d.pork, alcohol: d.alcohol, meat: d.meat, seafood: d.seafood,
            sameFactory: d.sameFactory,
            ambiguousIngredient: d.ambiguousIngredient,
          };
          StoreUI.renderAlreadyAdded(reshaped);
          StoreUI.showState('stateAlreadyAdded');
          return;
        }
        // Not found in main — open blank form
        _stopScanner();
        StoreForm.openBlank(barcode, null);
        return;
      } catch (e) {
        // Network/parse error → fall through to the blank form rather than block.
        console.warn('main-DB check failed, opening blank form:', e);
        _stopScanner();
        StoreForm.openBlank(barcode, null);
        return;
      }
    }

    try {
      const url = `${API_BASE}/api/store/check/${encodeURIComponent(selectedStore)}/${encodeURIComponent(barcode)}`;'''


# Edit C — _submitProduct: route to /api/scanner/product/add when no-store
APP_OLD_C = '''  async function _submitProduct(payload) {
    if (window.StoreUtils && !StoreUtils.isOnline()) {
      StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
      return;
    }

    StoreUI.showState('stateSubmitting');
    payload.userId = tgUserId;

    try {
      const { ok, status, data, error } = window.StoreUtils
        ? await StoreUtils.fetchJson(`${API_BASE}/api/store/product/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
            timeoutMs: 30000,
          })
        : await _rawFetchJson(`${API_BASE}/api/store/product/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          });'''

APP_NEW_C = '''  async function _submitProduct(payload) {
    if (window.StoreUtils && !StoreUtils.isOnline()) {
      StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
      return;
    }

    StoreUI.showState('stateSubmitting');
    payload.userId = tgUserId;

    // No-store mode: route to the main-DB add endpoint instead.
    // The form set payload.store = null/__NOSTORE__ — strip it for the
    // /api/scanner/product/add endpoint, which doesn't expect a store.
    const isNoStore = (selectedStore === null);
    const submitUrl = isNoStore
      ? `${API_BASE}/api/scanner/product/add`
      : `${API_BASE}/api/store/product/add`;
    if (isNoStore) {
      delete payload.store;
      // allHalal is a store-side concept; main DB doesn't track it.
      // The 4 individual haram flags + ambiguous already capture the same info.
      delete payload.allHalal;
    }

    try {
      const { ok, status, data, error } = window.StoreUtils
        ? await StoreUtils.fetchJson(submitUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
            timeoutMs: 30000,
          })
        : await _rawFetchJson(submitUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          });'''


# Edit D — _submitProduct success handler: reshape main-DB response for renderSuccess
# and skip StoreSubmissions.addLocal for no-store rows.
APP_OLD_D = '''      if (ok && data.success) {
        StoreUI.setSelectedStoreLabels(selectedStore);
        StoreUI.renderSuccess(data.product);
        StoreUI.showState('stateSuccess');
        _crossStoreContext = null;
        lastBarcode = null;
        // Update Mine cache + badge so the tab is fresh without a refetch
        try {
          if (window.StoreSubmissions && StoreSubmissions.addLocal) {
            StoreSubmissions.addLocal(data.product);'''

APP_NEW_D = '''      if (ok && data.success) {
        // No-store success: reshape the main-DB product to the success-card schema
        let successProduct = data.product;
        if (isNoStore && successProduct) {
          const vmap = { halol: 'joiz', harom: 'nojoiz', shubhali: 'shubhali' };
          successProduct = {
            publicId: String(successProduct.id || ''),
            barcode:  successProduct.barcode,
            store:    "🌐 Asosiy baza",
            category: successProduct.category || '',
            verdict:  vmap[successProduct.verdict] || 'joiz',
            image:    successProduct.image || '',
            pork:     successProduct.pork,
            alcohol:  successProduct.alcohol,
            meat:     successProduct.meat,
            seafood:  successProduct.seafood,
            sameFactory: successProduct.sameFactory,
            ambiguousIngredient: successProduct.ambiguousIngredient,
            createdAt: new Date().toISOString(),
            userId: tgUserId,
            source: 'main',
          };
        }
        StoreUI.setSelectedStoreLabels(isNoStore ? "🌐 Asosiy baza" : selectedStore);
        StoreUI.renderSuccess(successProduct);
        StoreUI.showState('stateSuccess');
        _crossStoreContext = null;
        lastBarcode = null;
        // Update Mine cache + badge so the tab is fresh without a refetch
        try {
          if (window.StoreSubmissions && StoreSubmissions.addLocal) {
            StoreSubmissions.addLocal(successProduct);'''


# Edit E — _submitProduct 409 duplicate handling for no-store
APP_OLD_E = '''      if (!data) {
        StoreUI.showError("Ulanish xatoligi", "Serverga ulanib bo'lmadi. Qaytadan urinib ko'ring.");
        return;
      }

      if (ok && data.success) {'''

APP_NEW_E = '''      if (!data) {
        StoreUI.showError("Ulanish xatoligi", "Serverga ulanib bo'lmadi. Qaytadan urinib ko'ring.");
        return;
      }

      // No-store duplicate (409): show "already added" with the existing product.
      if (isNoStore && status === 409 && (data.existsInStore || data.existsInMain)) {
        const ep = data.existingProduct;
        const vmap = { halol: 'joiz', harom: 'nojoiz', shubhali: 'shubhali' };
        const reshaped = ep ? {
          barcode: ep.barcode,
          store:   data.existsInStore ? "Do'kon bazasida mavjud" : "🌐 Asosiy baza",
          category: ep.category || '',
          verdict: vmap[ep.verdict] || 'joiz',
          image:   ep.image || '',
          pork: ep.pork, alcohol: ep.alcohol, meat: ep.meat, seafood: ep.seafood,
          sameFactory: ep.sameFactory,
          ambiguousIngredient: ep.ambiguousIngredient,
        } : {
          barcode: payload.barcode,
          store:   data.existsInStore ? "Do'kon bazasida mavjud" : "🌐 Asosiy baza",
          verdict: 'shubhali',
        };
        StoreUI.renderAlreadyAdded(reshaped);
        StoreUI.showState('stateAlreadyAdded');
        return;
      }

      if (ok && data.success) {'''


# ═══════════════════════════════════════════════════════════════════════════
# store-form.js — handle null/__NOSTORE__ store
# ═══════════════════════════════════════════════════════════════════════════

# Edit F — openBlank: tolerate null store
FORM_OLD_F = '''  function openBlank(_barcode, _store) {
    _reset();
    barcode = _barcode;
    targetStore = _store;
    StoreUI.setFormBarcode(barcode);
    StoreUI.setSelectedStoreLabels(targetStore);
    StoreUI.showPrefillBanner(false);
    StoreUI.showPhotoEmpty();
    StoreUI.showState('stateForm');
    _updateSubmitEnabled();
  }'''

FORM_NEW_F = '''  function openBlank(_barcode, _store) {
    _reset();
    barcode = _barcode;
    targetStore = _store;
    StoreUI.setFormBarcode(barcode);
    StoreUI.setSelectedStoreLabels(targetStore == null ? "🌐 Asosiy baza" : targetStore);
    StoreUI.showPrefillBanner(false);
    StoreUI.showPhotoEmpty();
    StoreUI.showState('stateForm');
    _updateSubmitEnabled();
  }'''


# Edit G — _submit payload: send store=null (or omit) when no-store
FORM_OLD_G = '''    const payload = {
      barcode: barcode,
      store: targetStore,
      category: category,
      pork: flags.pork,
      alcohol: flags.alcohol,
      meat: flags.meat,
      seafood: flags.seafood,
      sameFactory: flags.factory,
      allHalal: flags.allhalal,
      ambiguousIngredient: flags.ambiguous,
    };'''

FORM_NEW_G = '''    const payload = {
      barcode: barcode,
      // store omitted when null (no-store mode) — store-app.js strips it anyway,
      // but keeping conditional avoids sending a null to the store endpoint.
      ...(targetStore != null ? { store: targetStore } : {}),
      category: category,
      pork: flags.pork,
      alcohol: flags.alcohol,
      meat: flags.meat,
      seafood: flags.seafood,
      sameFactory: flags.factory,
      allHalal: flags.allhalal,
      ambiguousIngredient: flags.ambiguous,
    };'''


# ═══════════════════════════════════════════════════════════════════════════
# store-submissions.js — merge main-DB Mine + route delete by source
# ═══════════════════════════════════════════════════════════════════════════

# Edit H — refresh(): fetch both endpoints in parallel and merge
SUB_OLD_H = '''    try {
      const resp = await fetch(`${API_BASE()}/api/store/mine?userId=${encodeURIComponent(uid)}`);
      if (!resp.ok) throw new Error('HTTP ' + resp.status);
      const data = await resp.json();
      _submissions = Array.isArray(data.products) ? data.products : [];
    } catch (e) {
      console.error('mine fetch failed:', e);
      _submissions = [];
      StoreUI.toast("Ro'yxatni yuklab bo'lmadi", 'error');
    }'''

SUB_NEW_H = '''    try {
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
    }'''


# Edit I — _renderCard: show "main" source differently
SUB_OLD_I = '''      <article class="mine-card mine-card--${v.cls}">
        <div class="mine-card__img">${imgHtml}</div>
        <div class="mine-card__body">
          <div class="mine-card__top">
            <span class="mine-card__store">${_esc(p.store)}</span>
            <span class="mine-card__verdict mine-card__verdict--${v.cls}">${v.txt}</span>
          </div>'''

SUB_NEW_I = '''      <article class="mine-card mine-card--${v.cls}">
        <div class="mine-card__img">${imgHtml}</div>
        <div class="mine-card__body">
          <div class="mine-card__top">
            <span class="mine-card__store${p.source === 'main' ? ' mine-card__store--main' : ''}">${_esc(p.store)}</span>
            <span class="mine-card__verdict mine-card__verdict--${v.cls}">${v.txt}</span>
          </div>'''


# Edit J — _performDelete: route by source
SUB_OLD_J = '''    try {
      const resp = await fetch(
        `${API_BASE()}/api/store/product/${encodeURIComponent(pid)}?userId=${encodeURIComponent(uid)}`,
        { method: 'DELETE' }
      );'''

SUB_NEW_J = '''    try {
      const isMain = _deleteTarget.source === 'main';
      const url = isMain
        ? `${API_BASE()}/api/scanner/product/${encodeURIComponent(pid)}?userId=${encodeURIComponent(uid)}`
        : `${API_BASE()}/api/store/product/${encodeURIComponent(pid)}?userId=${encodeURIComponent(uid)}`;
      const resp = await fetch(url, { method: 'DELETE' });'''


# Edit K — _requestEdit: block edit for main-DB rows for now (no edit UI for those)
SUB_OLD_K = '''  function _requestEdit(product) {
    if (typeof _onEditRequest === 'function') {
      _onEditRequest(product);
    } else {
      StoreUI.toast("Tahrirlash M7-bosqichda ulanadi", 'info');
    }
  }'''

SUB_NEW_K = '''  function _requestEdit(product) {
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
  }'''


# ═══════════════════════════════════════════════════════════════════════════
# DRIVER
# ═══════════════════════════════════════════════════════════════════════════
def apply_edit(text, old, new, label):
    if new in text:
        print(f'  · {label}: already applied')
        return text
    if old not in text:
        print(f'  ✗ {label}: anchor not found — manual inspection needed')
        return text
    print(f'  ✓ {label}: applied')
    return text.replace(old, new, 1)


def patch_file(path, edits):
    if not os.path.isfile(path):
        print(f'  SKIP — file not found: {path}')
        return False
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    bak = path + '.bak'
    if not os.path.isfile(bak):
        with open(bak, 'w', encoding='utf-8') as f:
            f.write(text)
        print(f'  backup: {bak}')
    for label, old, new in edits:
        text = apply_edit(text, old, new, label)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    return True


def main():
    if len(sys.argv) < 2:
        print('Usage: python3 patch_frontend.py /path/to/frontend/dir')
        sys.exit(1)
    base = sys.argv[1]

    print(f'\n[1/4] HTML:  {base}/store-collector.html')
    patch_file(os.path.join(base, 'store-collector.html'), [
        ('HTML new "+ Boshqa" button', HTML_OLD, HTML_NEW),
        ('HTML CSS injection',         HTML_CSS_HOOK, HTML_CSS_INJECT),
    ])

    print(f'\n[2/4] store-app.js')
    patch_file(os.path.join(base, 'store-app.js'), [
        ('A: store-picker click handler',         APP_OLD_A, APP_NEW_A),
        ('B: _checkBarcode no-store branch',       APP_OLD_B, APP_NEW_B),
        ('C: _submitProduct URL routing',          APP_OLD_C, APP_NEW_C),
        ('D: success handler reshape + isNoStore', APP_OLD_D, APP_NEW_D),
        ('E: 409 dup handling for no-store',       APP_OLD_E, APP_NEW_E),
    ])

    print(f'\n[3/4] store-form.js')
    patch_file(os.path.join(base, 'store-form.js'), [
        ('F: openBlank tolerates null store',      FORM_OLD_F, FORM_NEW_F),
        ('G: submit payload skips store when null', FORM_OLD_G, FORM_NEW_G),
    ])

    print(f'\n[4/4] store-submissions.js')
    patch_file(os.path.join(base, 'store-submissions.js'), [
        ('H: parallel fetch + merge',  SUB_OLD_H, SUB_NEW_H),
        ('I: render card main badge',  SUB_OLD_I, SUB_NEW_I),
        ('J: delete routes by source', SUB_OLD_J, SUB_NEW_J),
        ('K: block edit for main-DB',  SUB_OLD_K, SUB_NEW_K),
    ])

    print('\nDONE.')


if __name__ == '__main__':
    main()
