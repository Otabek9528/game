// shops.js - Vegukin Shops feature page

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// ===========================================
// DEMO SHOP DATA
// ===========================================

const DEMO_SHOPS = [
  {
    icon: '🍞',
    name: 'Pishiriqlar do\'koni',
    desc: 'Non, somsa, patir va turli pishiriqlar',
    shopId: 'bakeryKR'
  },
  {
    icon: '🥟',
    name: 'Yarim tayyor mahsulotlar do\'koni',
    desc: 'Chuchvara, manti, lag\'mon va boshqalar',
    shopId: 'semiproductsKR'
  },
  {
    icon: '👗',
    name: 'Kiyim-kechak do\'koni',
    desc: 'Erkak, ayol va bolalar kiyimlari',
    shopId: 'clothesKR'
  },
  {
    icon: '💄',
    name: 'Kosmetika do\'koni',
    desc: 'Yuz, tana va soch uchun mahsulotlar',
    shopId: 'cosmeticsKR'
  },
  {
    icon: '🥩',
    name: 'Halol mahsulotlar do\'koni',
    desc: 'Go\'sht, sut, yog\' va boshqa halol mahsulotlar',
    shopId: 'halal_mart'
  }
];

// ===========================================
// RENDER DEMO SHOPS
// ===========================================

function renderDemoShops() {
  const container = document.getElementById('demoList');
  if (!container) return;

  container.innerHTML = '';

  DEMO_SHOPS.forEach(function(shop, index) {
    const card = document.createElement('a');
    card.className = 'demo-card';
    card.href = 'https://t.me/muslim_vegukin_bot/shop?startapp=' + shop.shopId;
    card.target = '_blank';

    card.innerHTML =
      '<div class="demo-icon">' + shop.icon + '</div>' +
      '<div class="demo-info">' +
        '<span class="demo-name">' + shop.name + '</span>' +
        '<span class="demo-desc">' + shop.desc + '</span>' +
      '</div>' +
      '<span class="demo-arrow">→</span>';

    // Open via Telegram's link handler if available
    card.addEventListener('click', function(e) {
      e.preventDefault();

      // Haptic feedback
      try {
        if (tg.HapticFeedback) {
          tg.HapticFeedback.impactOccurred('light');
        }
      } catch (ex) {}

      // Open inside Telegram
      try {
        tg.openTelegramLink('https://t.me/muslim_vegukin_bot/shop?startapp=' + shop.shopId);
      } catch (ex) {
        window.open(card.href, '_blank');
      }
    });

    // Staggered animation
    card.style.animationDelay = (index * 0.05) + 's';

    container.appendChild(card);
  });
}

// ===========================================
// BACK BUTTON
// ===========================================

function handleBackButton() {
  window.location.href = '../../index.html';
}

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(handleBackButton);
  }
} catch (e) {}

// ===========================================
// CTA BUTTON — open via Telegram
// ===========================================

function initCtaButton() {
  var ctaBtn = document.querySelector('.cta-btn');
  if (!ctaBtn) return;

  ctaBtn.addEventListener('click', function(e) {
    e.preventDefault();
    try {
      tg.openTelegramLink('https://t.me/otabeksattarov');
    } catch (ex) {
      window.open('https://t.me/otabeksattarov', '_blank');
    }
  });
}

// ===========================================
// INIT
// ===========================================

document.addEventListener('DOMContentLoaded', function() {
  renderDemoShops();
  initCtaButton();

  // Log feature open (only if not coming from index — index already logs on click)
  if (window.logInteraction && !document.referrer.includes('index.html')) {
    window.logInteraction('vegukinShops');
  }

  console.log('✅ Shops page loaded');
});
