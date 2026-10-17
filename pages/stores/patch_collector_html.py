#!/usr/bin/env python3
"""
patch_collector_html.py — Apply 3 idempotent edits to store-collector.html
to add the "no-store" add flow.

Usage:
  python3 patch_collector_html.py /path/to/store-collector.html

Edits:
  1. Insert a 7th store card (data-store="__NOSTORE__") at the end of #storeGrid
  2. Insert <section id="paneNoStore"> with all states, right after </section> of paneCollect
  3. Insert <script src="store-add-no-store.js"></script> after store-app.js
"""
import sys
import re
import os


# ── Edit 1: new store card ────────────────────────────────────────────────────
NEW_STORE_CARD = '''          <button class="store-card store-card--nostore" data-store="__NOSTORE__">
            <span class="store-card__logo">+ Boshqa</span>
            <span class="store-card__check" style="background:#c8600a;color:#fff">↗</span>
          </button>
        </div>'''

# Match the closing </div> of #storeGrid. The "No Brand" button is the last
# one in the existing layout — anchor on it.
EDIT1_OLD = '''          <button class="store-card store-card--nobrand" data-store="No Brand">
            <span class="store-card__logo">No Brand</span>
            <span class="store-card__check">✓</span>
          </button>
        </div>'''
EDIT1_NEW = '''          <button class="store-card store-card--nobrand" data-store="No Brand">
            <span class="store-card__logo">No Brand</span>
            <span class="store-card__check">✓</span>
          </button>
''' + NEW_STORE_CARD


# ── Edit 2: paneNoStore section ───────────────────────────────────────────────
# Inserted right after the closing </section> of #paneCollect.
PANE_NOSTORE = '''
    <!-- ==================================================
         PANE: NO-STORE ADD (writes to main products table)
         ================================================== -->
    <section class="sc-tabpane" id="paneNoStore" style="display:none;">

      <!-- STATE: Permission CTA -->
      <div class="sc-state" id="nsPermission" style="display:none;">
        <div class="sc-hero sc-hero--permission">
          <div class="selected-chip">
            <span class="selected-chip__label">Rejim:</span>
            <span class="selected-chip__value">Do'konsiz qo'shish</span>
            <button class="selected-chip__change" id="nsCloseFromPermBtn">Bekor qilish</button>
          </div>
          <div class="permission-visual">
            <div class="permission-visual__camera">📷</div>
            <div class="permission-visual__pulse"></div>
          </div>
          <h2 class="sc-hero__title">Mahsulotni skanerlang</h2>
          <p class="sc-hero__desc">Shtrix-kodni kameraga yo'naltiring. Mahsulot asosiy bazaga to'g'ridan-to'g'ri qo'shiladi.</p>
          <button class="sc-cta" id="nsAllowCameraBtn">
            <span>📸</span><span>Kamerani yoqish</span>
          </button>
        </div>
      </div>

      <!-- STATE: Scanner -->
      <div class="sc-state" id="nsScanner" style="display:none;">
        <div class="sc-scanner">
          <video id="nsVideo" autoplay playsinline muted></video>
          <div class="sc-scanner__overlay">
            <div class="sc-scanner__frame"></div>
            <p class="sc-scanner__status" id="nsScanStatus">Kamera ochilmoqda…</p>
          </div>
          <div class="sc-scanner__toolbar">
            <button class="sc-icon-btn" id="nsTorchBtn" style="display:none">⚡</button>
            <button class="sc-icon-btn" id="nsManualBtn">⌨️</button>
            <button class="sc-icon-btn" id="nsCloseFromScanBtn">✕</button>
          </div>
        </div>
      </div>

      <!-- STATE: Form -->
      <div class="sc-state" id="nsForm" style="display:none;">
        <div class="sc-hero">
          <div class="selected-chip">
            <span class="selected-chip__label">Shtrix-kod:</span>
            <span class="selected-chip__value" id="nsBarcodeShow">—</span>
            <button class="selected-chip__change" id="nsFormCancelBtn">Bekor qilish</button>
          </div>
          <p class="sc-hero__desc" style="margin-top:8px;color:#c8600a;font-weight:600">
            ⚠ Bu mahsulot asosiy bazaga qo'shiladi (do'konsiz)
          </p>
        </div>

        <div class="form-section">
          <h3 class="form-section__title">1. Kategoriya</h3>
          <div class="category-grid" id="nsCategoryGrid">
            <button class="cat-chip" data-cat="Drinks"><span class="cat-chip__icon">🥤</span><span class="cat-chip__label">Ichimliklar</span></button>
            <button class="cat-chip" data-cat="Snacks"><span class="cat-chip__icon">🍿</span><span class="cat-chip__label">Gazaklar</span></button>
            <button class="cat-chip" data-cat="Sweets"><span class="cat-chip__icon">🍬</span><span class="cat-chip__label">Shirinliklar</span></button>
            <button class="cat-chip" data-cat="Ice Cream"><span class="cat-chip__icon">🍦</span><span class="cat-chip__label">Muzqaymoq</span></button>
            <button class="cat-chip" data-cat="Baked Goods"><span class="cat-chip__icon">🥐</span><span class="cat-chip__label">Non mahsulotlari</span></button>
            <button class="cat-chip" data-cat="Cup Noodles/Ramen"><span class="cat-chip__icon">🍜</span><span class="cat-chip__label">Lag'mon / Ramen</span></button>
            <button class="cat-chip" data-cat="Lunchbox/Dosirak"><span class="cat-chip__icon">🍩</span><span class="cat-chip__label">Pechenya/Pishiriqlar</span></button>
            <button class="cat-chip" data-cat="Dairy"><span class="cat-chip__icon">🥛</span><span class="cat-chip__label">Sut mahsulotlari</span></button>
            <button class="cat-chip" data-cat="Canned Food"><span class="cat-chip__icon">🥫</span><span class="cat-chip__label">Konserva</span></button>
            <button class="cat-chip" data-cat="Frozen Food"><span class="cat-chip__icon">🧊</span><span class="cat-chip__label">Muzlatilgan</span></button>
            <button class="cat-chip" data-cat="Condiments/Sauces"><span class="cat-chip__icon">🧂</span><span class="cat-chip__label">Sous va ziravorlar</span></button>
            <button class="cat-chip" data-cat="Fruits/Vegetables"><span class="cat-chip__icon">🥬</span><span class="cat-chip__label">Meva va sabzavot</span></button>
            <button class="cat-chip" data-cat="Dried Food"><span class="cat-chip__icon">🌾</span><span class="cat-chip__label">Quruq mahsulot</span></button>
          </div>
        </div>

        <div class="form-section">
          <h3 class="form-section__title">2. Tarkib</h3>
          <div class="flag-grid">
            <button class="flag-toggle" data-flag="allhalal">
              <span class="flag-toggle__icon">☪️</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Barchasi halol</p>
                <p class="flag-toggle__desc">Ta'qiqlangan tarkib yo'q</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
            <button class="flag-toggle" data-flag="pork">
              <span class="flag-toggle__icon">🐖</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Cho'chqa mahsuloti</p>
                <p class="flag-toggle__desc">Tarkibda cho'chqa go'shti yoki jelatini bor</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
            <button class="flag-toggle" data-flag="alcohol">
              <span class="flag-toggle__icon">🍷</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Alkogol</p>
                <p class="flag-toggle__desc">Spirt, vino, pivo yoki shunga o'xshash</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
            <button class="flag-toggle" data-flag="meat">
              <span class="flag-toggle__icon">🍗</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Boshqa go'sht</p>
                <p class="flag-toggle__desc">Halol bo'lmagan mol, tovuq va boshqa go'sht</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
            <button class="flag-toggle" data-flag="seafood">
              <span class="flag-toggle__icon">🦐</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Dengiz mahsulotlari</p>
                <p class="flag-toggle__desc">Qisqichbaqa, kalmar, ustritsa va h.k.</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
            <button class="flag-toggle" data-flag="factory">
              <span class="flag-toggle__icon">🏭</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Bir zavodda</p>
                <p class="flag-toggle__desc">Halol bo'lmagan mahsulotlar bilan bir zavodda ishlab chiqarilgan</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
            <button class="flag-toggle" data-flag="ambiguous">
              <span class="flag-toggle__icon">❓</span>
              <div class="flag-toggle__content">
                <p class="flag-toggle__name">Mavhum tarkib</p>
                <p class="flag-toggle__desc">Halol/harom ekani aniq emas (E-kodlar, jelatin va h.k.)</p>
              </div>
              <div class="flag-toggle__check"></div>
            </button>
          </div>
        </div>

        <div class="form-section">
          <h3 class="form-section__title">3. Surat</h3>
          <div id="nsPhotoEmpty" style="display:block;">
            <button class="sc-cta sc-cta--photo" id="nsOpenPhotoBtn">
              <span>📸</span><span>Suratga olish</span>
            </button>
          </div>
          <div id="nsPhotoCapture" style="display:none;">
            <video id="nsCaptureVideo" autoplay playsinline muted style="width:100%;border-radius:12px;"></video>
            <div style="display:flex;gap:8px;margin-top:8px;">
              <button class="sc-cta" id="nsShutterBtn" style="flex:1;">📷 Olish</button>
              <button class="sc-icon-btn" id="nsCancelPhotoBtn">✕</button>
            </div>
          </div>
          <div id="nsPhotoPreview" style="display:none;">
            <img id="nsPreviewImg" alt="" style="width:100%;border-radius:12px;display:block;">
            <div style="display:flex;gap:8px;margin-top:8px;">
              <button class="sc-cta" id="nsRetakeBtn" style="flex:1;">🔄 Qayta olish</button>
              <button class="sc-icon-btn" id="nsRemovePhotoBtn">🗑</button>
            </div>
          </div>
        </div>

        <div class="form-footer">
          <button class="sc-cta" id="nsFormSubmitBtn" disabled>
            <span>✓</span><span>Bazaga qo'shish</span>
          </button>
        </div>
      </div>

      <!-- STATE: Submitting -->
      <div class="sc-state" id="nsSubmitting" style="display:none;">
        <div class="sc-hero">
          <div class="permission-visual">
            <div class="permission-visual__camera">⏳</div>
          </div>
          <h2 class="sc-hero__title">Yuborilmoqda…</h2>
          <p class="sc-hero__desc">Mahsulot bazaga qo'shilmoqda.</p>
        </div>
      </div>

      <!-- STATE: Success -->
      <div class="sc-state" id="nsSuccess" style="display:none;">
        <div class="sc-hero">
          <h2 class="sc-hero__title" style="color:#1a7a42">✓ Qo'shildi!</h2>
          <p class="sc-hero__desc">Mahsulot bazaga muvaffaqiyatli qo'shildi.</p>
          <div id="nsSuccessPreview" style="margin-top:14px;"></div>
          <div style="display:flex;gap:8px;margin-top:16px;">
            <button class="sc-cta" id="nsSuccessAnotherBtn" style="flex:1;">➕ Yana qo'shish</button>
            <button class="sc-icon-btn" id="nsSuccessCloseBtn">✕</button>
          </div>
        </div>
      </div>

      <!-- STATE: Error -->
      <div class="sc-state" id="nsError" style="display:none;">
        <div class="sc-hero">
          <h2 class="sc-hero__title" style="color:#c0392b" id="nsErrorTitle">Xatolik</h2>
          <p class="sc-hero__desc" id="nsErrorBody">—</p>
          <div style="display:flex;gap:8px;margin-top:16px;">
            <button class="sc-cta" id="nsErrorRetryBtn" style="flex:1;">🔄 Qayta urinish</button>
            <button class="sc-icon-btn" id="nsErrorBackBtn">←</button>
          </div>
        </div>
      </div>

      <!-- STATE: Duplicate -->
      <div class="sc-state" id="nsDuplicate" style="display:none;">
        <div class="sc-hero">
          <h2 class="sc-hero__title" style="color:#c8600a">Mahsulot mavjud</h2>
          <div id="nsDuplicatePreview" style="margin-top:14px;"></div>
          <div style="display:flex;gap:8px;margin-top:16px;">
            <button class="sc-cta" id="nsDuplicateAnotherBtn" style="flex:1;">📷 Boshqasini skanerlash</button>
            <button class="sc-icon-btn" id="nsDuplicateCloseBtn">✕</button>
          </div>
        </div>
      </div>

    </section>

'''

# Anchor: insert after the closing </section> of paneCollect, which directly
# precedes the comment-marked TAB: MINE.
EDIT2_OLD = '''    </section>


    <!-- ==================================================
         TAB: MINE (My Submissions)'''
EDIT2_NEW = '''    </section>
''' + PANE_NOSTORE + '''

    <!-- ==================================================
         TAB: MINE (My Submissions)'''


# ── Edit 3: script tag ────────────────────────────────────────────────────────
EDIT3_OLD = '<script src="store-app.js"></script>'
EDIT3_NEW = '<script src="store-app.js"></script>\n  <script src="store-add-no-store.js"></script>'

# ── CSS additions (appended in a <style> tag at the end of <head>) ────────────
CSS_INJECT = '''  <style>
    /* ─── store-add-no-store: pill + preview styles ─── */
    .store-card--nostore {
      background: linear-gradient(135deg, #fff5e6 0%, #ffe9c2 100%);
      border-color: #c8600a;
    }
    .store-card--nostore .store-card__logo { color: #c8600a; font-weight: 700; }
    .ns-preview {
      display: flex; gap: 12px; padding: 12px;
      border-radius: 12px; background: #fff; border: 1px solid #e2ddd4;
    }
    .ns-preview--halol    { border-color: #d1f5e0; background: #f0faf4; }
    .ns-preview--shubhali { border-color: #faecc8; background: #fdf8ec; }
    .ns-preview--harom    { border-color: #fde3df; background: #fef2f0; }
    .ns-preview__img { width: 64px; height: 64px; border-radius: 8px; background: #f0f0f0;
                       display: flex; align-items: center; justify-content: center;
                       font-size: 1.6rem; overflow: hidden; flex-shrink: 0; }
    .ns-preview__img img { width: 100%; height: 100%; object-fit: cover; }
    .ns-preview__body { flex: 1; min-width: 0; }
    .ns-preview__verdict { display: inline-block; padding: 2px 8px; border-radius: 100px;
                           font-size: 0.75rem; font-weight: 700; margin-bottom: 4px; }
    .ns-preview__verdict--halol    { background: #d1f5e0; color: #145c34; }
    .ns-preview__verdict--shubhali { background: #faecc8; color: #b8860b; }
    .ns-preview__verdict--harom    { background: #fde3df; color: #c0392b; }
    .ns-preview__bc { font-family: 'IBM Plex Mono', monospace; font-size: 0.78rem;
                      color: #5c5650; display: block; margin: 4px 0; }
    .ns-preview__cat { font-size: 0.85rem; color: #2c2825; margin: 0; }
    .ns-state__msg { font-size: 0.95rem; color: #5c5650; margin: 8px 0 14px; }
  </style>
</head>'''


def apply_edit(html, old, new, label):
    if new in html:
        print(f'  · {label}: already applied, skipping')
        return html
    if old not in html:
        print(f'  ✗ {label}: anchor not found — manual inspection needed')
        return html
    print(f'  ✓ {label}: applied')
    return html.replace(old, new, 1)


def main():
    if len(sys.argv) < 2:
        print('Usage: python3 patch_collector_html.py /path/to/store-collector.html')
        sys.exit(1)

    path = sys.argv[1]
    if not os.path.isfile(path):
        print(f'File not found: {path}')
        sys.exit(1)

    with open(path, 'r', encoding='utf-8') as f:
        html = f.read()

    backup = path + '.bak'
    if not os.path.isfile(backup):
        with open(backup, 'w', encoding='utf-8') as f:
            f.write(html)
        print(f'[patch] Backup created: {backup}')

    print('[patch] Applying edits...')
    html = apply_edit(html, EDIT1_OLD, EDIT1_NEW, 'Edit 1 — new store card')
    html = apply_edit(html, EDIT2_OLD, EDIT2_NEW, 'Edit 2 — paneNoStore section')
    html = apply_edit(html, EDIT3_OLD, EDIT3_NEW, 'Edit 3 — script tag')
    html = apply_edit(html, '</head>', CSS_INJECT, 'Edit 4 — CSS injection')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f'[patch] DONE. Edited: {path}')


if __name__ == '__main__':
    main()
