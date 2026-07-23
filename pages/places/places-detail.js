// places-detail.js - Place detail page functionality with I18N support

// ============================================
// PLACE TYPE CONFIGURATIONS (with I18N support)
// ============================================

const PLACE_CONFIGS = {
  mosque: {
    name: 'Masjid',
    namePlural: 'Masjidlar',
    nameGenitive: 'Masjid',
    icon: '🕌',
    buildingType: 'Masjid',
    defaultPhoto: '../../assets/mosque.png',
    detailTitle: 'Masjid Ma\'lumotlari',
    reviewPrompt: 'Masjid haqida fikringiz'
  },
  restaurant: {
    name: 'Oshxona',
    namePlural: 'Oshxonalar',
    nameGenitive: 'Oshxona',
    icon: '🍽️',
    buildingType: 'Restoran',
    defaultPhoto: '../../assets/restaurant.jpg',
    detailTitle: 'Oshxona Ma\'lumotlari',
    reviewPrompt: 'Oshxona haqida fikringiz'
  },
  shop: {
    name: 'Do\'kon',
    namePlural: 'Do\'konlar',
    nameGenitive: 'Do\'kon',
    icon: '🏪',
    buildingType: "Do'kon",
    defaultPhoto: '../../assets/store.jpg',
    detailTitle: 'Do\'kon Ma\'lumotlari',
    reviewPrompt: 'Do\'kon haqida fikringiz'
  }
};

// ============================================
// INLINE SVG ICONS (UI chrome — replaces emoji)
// ============================================

const PL_ICONS = {
  star: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2.5l2.83 6.1 6.67.77-4.94 4.56 1.32 6.57L12 17.2l-5.88 3.3 1.32-6.57L2.5 9.37l6.67-.77z"/></svg>',
  pin: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>',
  phone: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.13.96.36 1.9.7 2.8a2 2 0 0 1-.45 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.25a2 2 0 0 1 2.1-.45c.9.34 1.84.57 2.8.7A2 2 0 0 1 22 16.9z"/></svg>',
  copy: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="12" height="12" rx="2.5"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
  chat: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 11.5a8.4 8.4 0 0 1-8.5 8.3c-1.3 0-2.6-.3-3.7-.8L3 20l1.1-5.5a8 8 0 0 1-.6-3A8.4 8.4 0 0 1 12 3.2a8.4 8.4 0 0 1 9 8.3Z"/></svg>',
  nav: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 11.2 21.5 2.8a.5.5 0 0 1 .66.66L13.8 22a.5.5 0 0 1-.93-.03l-2.1-7.3a1 1 0 0 0-.68-.68l-7.3-2.1a.5.5 0 0 1-.03-.93Z"/></svg>',
  pen: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.4 2.4 0 0 1 3.4 3.4L8 18.8 3 20l1.2-5L17 3Z"/></svg>',
  check: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m4.5 12.5 5 5 10-11"/></svg>',
  rub: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true"><rect x="6.2" y="6.2" width="11.6" height="11.6"/><rect x="6.2" y="6.2" width="11.6" height="11.6" transform="rotate(45 12 12)"/></svg>'
};

async function incrementViewCount(placeId) {
  try {
    await fetch(`${API_CONFIG.BASE_URL}/api/place/${placeId}/view`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (e) {
    console.log('View count error:', e);
  }
}


// Get translated config based on current language
function getTranslatedConfig(placeType) {
  const base = PLACE_CONFIGS[placeType] || PLACE_CONFIGS.mosque;
  
  // If I18N not loaded, return base config
  if (!window.I18N) return base;
  
  return {
    ...base,
    name: I18N.t(`places.${placeType}.name`) !== `places.${placeType}.name` ? I18N.t(`places.${placeType}.name`) : base.name,
    namePlural: I18N.t(`places.${placeType}.namePlural`) !== `places.${placeType}.namePlural` ? I18N.t(`places.${placeType}.namePlural`) : base.namePlural,
    detailTitle: I18N.t(`detail.${placeType}.title`) !== `detail.${placeType}.title` ? I18N.t(`detail.${placeType}.title`) : base.detailTitle,
    reviewPrompt: I18N.t(`detail.${placeType}.reviewPrompt`) !== `detail.${placeType}.reviewPrompt` ? I18N.t(`detail.${placeType}.reviewPrompt`) : base.reviewPrompt
  };
}

// Get place type from URL parameter
const urlParams = new URLSearchParams(window.location.search);
const PLACE_TYPE = urlParams.get('type') || 'mosque';
let CONFIG = PLACE_CONFIGS[PLACE_TYPE] || PLACE_CONFIGS.mosque;

// Update page title
document.title = CONFIG.detailTitle;

// ============================================
// TELEGRAM WEBAPP INITIALIZATION
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();
Telegram.WebApp.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// Back button handlers
const handleMainBackButton = () => {
  window.location.href = `places.html?type=${PLACE_TYPE}`;
};

const handleModalBackButton = () => {
  closeImageModal();
};

// Setup initial back button
try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(handleMainBackButton);
  }
} catch (e) {}

// ============================================
// DOM ELEMENTS
// ============================================

const detailLoading = document.getElementById('detailLoading');
const detailError = document.getElementById('detailError');
const detailContent = document.getElementById('detailContent');
const errorMessage = document.getElementById('errorMessage');


// ============================================
// IMAGE VIEWER  (shared module — see photo-viewer.js)
// ============================================
// The old inline modal + zoom block lived here. It is replaced by the
// shared PhotoViewer, which also powers places.html.
// openImageModal / closeImageModal are kept as thin wrappers because
// createDetailPhotoCarousel() emits inline onclick="openImageModal(...)".

PhotoViewer.configure({
  onOpen: function () {
    if (tg.BackButton) {
      tg.BackButton.offClick(handleMainBackButton);
      tg.BackButton.onClick(handleModalBackButton);
    }
  },
  onClose: function () {
    if (tg.BackButton) {
      tg.BackButton.offClick(handleModalBackButton);
      tg.BackButton.onClick(handleMainBackButton);
    }
  }
});

function openImageModal(photos, startIndex) {
  PhotoViewer.open(photos, startIndex || 0);
}

function closeImageModal() {
  PhotoViewer.close();
}


// ============================================
// API FUNCTIONS
// ============================================

function getPlaceId() {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('id');
}

async function fetchPlaceDetail(id) {
  const url = `${API_CONFIG.BASE_URL}/api/place/${id}`;
  
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    if (!response.ok) {
      throw new Error(`API error: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    
    if (data.success && data.place) {
      return data.place;
    } else {
      throw new Error('Invalid API response format');
    }
  } catch (error) {
    throw error;
  }
}

// ============================================
// PHOTO FUNCTIONS
// ============================================

function checkImageExists(url) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => resolve(true);
    img.onerror = () => resolve(false);
    img.src = url;
  });
}

async function discoverPhotos(photoPath, maxPhotos = 10) {
  const photos = [];
  const extensions = ['jpg', 'jpeg', 'png'];
  const basePath = `../../${photoPath}`;
  
  for (let i = 1; i <= maxPhotos; i++) {
    let photoFound = false;
    
    for (const ext of extensions) {
      const photoUrl = `${basePath}/${i}.${ext}`;
      
      try {
        const exists = await checkImageExists(photoUrl);
        if (exists) {
          photos.push(photoUrl);
          photoFound = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (!photoFound) break;
  }
  
  return photos;
}

// ============================================
// CAROUSEL FUNCTIONS
// ============================================

function createDetailPhotoCarousel(photos) {
  if (!photos || photos.length === 0) {
    return `
      <img src="${CONFIG.defaultPhoto}" alt="${CONFIG.name} photo" class="detail-single-photo" onclick="openImageModal(['${CONFIG.defaultPhoto}'], 0)" />
    `;
  }
  
  if (photos.length === 1) {
    return `
      <img src="${photos[0]}" alt="${CONFIG.name} photo" class="detail-single-photo" onclick="openImageModal(['${photos[0]}'], 0)" />
    `;
  }
  
  let photosHTML = '';
  let dotsHTML = '';
  
  photos.forEach((photo, index) => {
    const positionClass = index === 0 ? 'center' : 
                         index === 1 ? 'right' : 'hidden';
    
    photosHTML += `
      <div class="carousel-photo ${positionClass}" data-index="${index}" data-photo="${photo}">
        <img src="${photo}" alt="${CONFIG.name} photo ${index + 1}" />
      </div>
    `;
    
    dotsHTML += `
      <span class="dot ${index === 0 ? 'active' : ''}" data-index="${index}"></span>
    `;
  });
  
  return `
    <div class="photo-carousel" id="detailCarousel" data-photos='${JSON.stringify(photos)}'>
      <div class="carousel-track">
        ${photosHTML}
      </div>
      <div class="carousel-dots">
        ${dotsHTML}
      </div>
    </div>
  `;
}

function initDetailCarousel(photoCount) {
  const carousel = document.getElementById('detailCarousel');
  if (!carousel || photoCount <= 1) return;
  
  const photos = carousel.querySelectorAll('.carousel-photo');
  const dots = carousel.querySelectorAll('.dot');
  const allPhotos = JSON.parse(carousel.getAttribute('data-photos'));
  let currentIndex = 0;
  
  function updateCarousel(newIndex) {
    const totalPhotos = photos.length;
    
    photos.forEach((photo, index) => {
      const relativePos = (index - newIndex + totalPhotos) % totalPhotos;

      // Off-stage photos get a side, so they slide in from the correct edge
      // instead of emerging from behind the centre photo. `<=` puts the
      // exactly-opposite photo of an even-length loop ahead rather than
      // behind, which is the side it will be needed on next.
      let slot;
      if (relativePos === 0) slot = 'center';
      else if (relativePos === 1) slot = 'right';
      else if (relativePos === totalPhotos - 1) slot = 'left';
      else slot = relativePos <= totalPhotos / 2 ? 'hidden-right' : 'hidden-left';

      CoverflowSlot.apply(photo, slot);
    });
    
    dots.forEach((dot, index) => {
      dot.classList.toggle('active', index === newIndex);
    });
    
    currentIndex = newIndex;
  }
  
  photos.forEach((photo) => {
    photo.addEventListener('click', (e) => {
      e.stopPropagation();
      
      if (photo.classList.contains('center')) {
        openImageModal(allPhotos, currentIndex);
      } else if (photo.classList.contains('right')) {
        updateCarousel((currentIndex + 1) % photos.length);
      } else if (photo.classList.contains('left')) {
        updateCarousel((currentIndex - 1 + photos.length) % photos.length);
      }
    });
  });
  
  dots.forEach((dot, index) => {
    dot.addEventListener('click', (e) => {
      e.stopPropagation();
      updateCarousel(index);
    });
  });

  // Manual swipe. No auto-rotation on the detail page: the user is already
  // committed to this place, and tapping the centre photo opens the
  // fullscreen viewer, which is the proper way to browse the photos.
  if (window.SwipeNav) {
    SwipeNav.attach(carousel, {
      onNext: () => updateCarousel((currentIndex + 1) % photos.length),
      onPrev: () => updateCarousel((currentIndex - 1 + photos.length) % photos.length)
    });
  }
}

// ============================================
// RATING AND REVIEW FUNCTIONS (with I18N)
// ============================================

function renderStars(rating) {
  const rounded = Math.round(Number(rating || 0));
  let starsHTML = '';
  for (let i = 1; i <= 5; i++) {
    starsHTML += `<span class="${i <= rounded ? 'star-on' : 'star-off'}">${PL_ICONS.star}</span>`;
  }
  return `<span class="stars">${starsHTML}</span>`;
}

function generateStarRating(reviews) {
  const noRatingText = window.I18N ? I18N.t('detail.noReviews') : 'Hali izoh yo\'q';
  
  if (!reviews || reviews.length === 0) {
    return `<span class="detail-chip--muted">${noRatingText}</span>`;
  }
  
  const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
  const rating = (Math.round(avgRating * 10) / 10).toFixed(1);
  
  return `${renderStars(avgRating)}<span class="chip-num">${rating}</span><span class="chip-count">(${reviews.length})</span>`;
}

function formatDate(dateString) {
  try {
    const date = new Date(dateString);
    const lang = window.I18N ? I18N.getLanguage() : 'uz';
    const locale = lang === 'ru' ? 'ru-RU' : lang === 'en' ? 'en-US' : 'uz-UZ';
    return date.toLocaleDateString(locale, { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  } catch (e) {
    return dateString;
  }
}

function renderReviews(reviews) {
  const noReviewsText = window.I18N ? I18N.t('detail.noReviewsYet') : 'Hali Izohlar yo\'q';
  const noTextText = window.I18N ? I18N.t('detail.noReviewText') : 'Izoh matni yo\'q';
  
  if (!reviews || reviews.length === 0) {
    return `<div class="no-reviews">${noReviewsText}</div>`;
  }

  let reviewsHTML = '';
  reviews.forEach(review => {
    const stars = renderStars(review.rating);
    const date = formatDate(review.timestamp);
    
    reviewsHTML += `
      <div class="review-card">
        <div class="review-header">
          <div class="review-rating">
            <span class="review-stars">${stars}</span>
          </div>
          <span class="review-date">${date}</span>
        </div>
        <p class="review-text">${review.text || noTextText}</p>
      </div>
    `;
  });

  return reviewsHTML;
}

function copyAddress(address, event) {
  const noAddressText = window.I18N ? I18N.t('places.noAddress') : 'Manzil ma\'lumoti yo\'q';
  if (!address || address === noAddressText) return;
  
  event.stopPropagation();
  
  const copiedText = window.I18N ? I18N.t('detail.addressCopied') : 'Manzil nusxalandi! ✅';
  
  navigator.clipboard.writeText(address).then(() => {
    const item = event.currentTarget;
    const originalBg = item.style.background;
    item.style.background = '#d4edda';
    
    setTimeout(() => {
      item.style.background = originalBg;
    }, 300);
    
    if (window.Telegram && window.Telegram.WebApp) {
      window.Telegram.WebApp.showAlert(copiedText);
    }
  }).catch(err => {
    console.error('Copy failed:', err);
  });
}

// ============================================
// RENDER PLACE DETAIL (with I18N)
// ============================================

async function renderPlaceDetail(place) {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  
  const photos = await discoverPhotos(place.photo, 10);
  
  const photoHTML = createDetailPhotoCarousel(photos);
  const starRatingHTML = generateStarRating(place.reviews);
  const reviewsHTML = renderReviews(place.reviews);
  const reviewCount = place.reviews ? place.reviews.length : 0;
  const distanceDisplay = place.distance ? place.distance.toFixed(1) : 'N/A';
  
  // Translated texts
  const t = window.I18N ? (key) => I18N.t(key) : (key) => key;
  const noInfoText = t('places.noInfo') !== 'places.noInfo' ? t('places.noInfo') : 'Ma\'lumot yo\'q';
  const noAddressText = t('places.noAddress') !== 'places.noAddress' ? t('places.noAddress') : 'Manzil ma\'lumoti yo\'q';
  const contactTitle = t('detail.contact') !== 'detail.contact' ? t('detail.contact') : 'Kontakt';
  const addressTitle = t('detail.address') !== 'detail.address' ? t('detail.address') : 'Manzil';
  const reviewsTitle = t('detail.reviews') !== 'detail.reviews' ? t('detail.reviews') : 'Izohlar';
  const navigationTitle = t('detail.navigation') !== 'detail.navigation' ? t('detail.navigation') : 'Navigatsiya';
  const leaveReviewText = t('detail.leaveReview') !== 'detail.leaveReview' ? t('detail.leaveReview') : 'Izoh qoldirish';
  const reviewHintTitle = t('detail.reviewHintTitle') !== 'detail.reviewHintTitle' ? t('detail.reviewHintTitle') : 'Izohingizda quyidagilarni yozishingiz mumkin:';
  const reviewHint1 = CONFIG.reviewPrompt;
  const reviewHint2 = t('detail.reviewHint2') !== 'detail.reviewHint2' ? t('detail.reviewHint2') : 'Ochilish va yopilish vaqtlari';
  const reviewHint3 = t('detail.reviewHint3') !== 'detail.reviewHint3' ? t('detail.reviewHint3') : 'Kirish eshikdagi parol (agar bor bo\'lsa)';
  const reviewHint4 = t('detail.reviewHint4') !== 'detail.reviewHint4' ? t('detail.reviewHint4') : 'Lokatsiyaga olib boriladigan yo\'l tushuntirishlar';
  const rateText = t('detail.rate') !== 'detail.rate' ? t('detail.rate') : 'Baholang:';
  const reviewPlaceholder = t('detail.reviewPlaceholder') !== 'detail.reviewPlaceholder' ? t('detail.reviewPlaceholder') : 'Izohingizni yozing ...';
  const submitText = t('detail.submit') !== 'detail.submit' ? t('detail.submit') : 'Yuborish';
  const thankYouText = t('detail.thankYou') !== 'detail.thankYou' ? t('detail.thankYou') : 'Rahmat!';
  const reviewReceivedText = t('detail.reviewReceived') !== 'detail.reviewReceived' ? t('detail.reviewReceived') : 'Izohingiz muvaffaqiyatli qabul qilindi va ko\'rib chiqilmoqda.';
  
  // Process phone numbers - split if multiple
  function renderPhoneNumbers(phoneString) {
    if (!phoneString) {
      return `<span class="detail-text">${noInfoText}</span>`;
    }
    
    const phones = phoneString.split(',').map(p => p.trim()).filter(p => p);
    
    if (phones.length === 1) {
      return `<a href="tel:${phones[0]}" class="detail-link">${phones[0]}</a>`;
    }
    
    return phones.map(phone => 
      `<a href="tel:${phone}" class="detail-link detail-phone-line">${phone}</a>`
    ).join('');
  }
  
  detailContent.innerHTML = `
    <div class="detail-card">
      <div class="detail-photo-section">
        ${photoHTML}
      </div>
      
      <div class="detail-head">
        <p class="detail-eyebrow">${PL_ICONS.rub} ${CONFIG.name}</p>
        <h1 class="detail-title">${place.name}</h1>
        <p class="detail-subtitle">${place.city || 'Unknown City'}</p>
        <div class="detail-chips">
          <div class="detail-chip detail-chip--rating">
            ${starRatingHTML}
          </div>
          ${place.distance ? `
            <div class="detail-chip detail-chip--distance">
              ${PL_ICONS.pin}
              <span>${distanceDisplay} km</span>
            </div>
          ` : ''}
        </div>
      </div>
      
      <div class="detail-content">
        <div class="detail-section">
          <h3 class="detail-section-title">${PL_ICONS.rub} ${contactTitle}</h3>
          <div class="detail-info-item">
            <span class="detail-icon">${PL_ICONS.phone}</span>
            <div style="flex: 1;">
              ${renderPhoneNumbers(place.phone)}
            </div>
          </div>
        </div>
        
        <div class="detail-section">
          <h3 class="detail-section-title">${PL_ICONS.rub} ${addressTitle}</h3>
          <div class="detail-info-item" style="cursor: pointer;" onclick="copyAddress('${(place.address || '').replace(/'/g, "\\'")}', event)">
            <span class="detail-icon">${PL_ICONS.pin}</span>
            <span class="detail-text">${place.address || noAddressText}</span>
            <span class="detail-copy-mark">${PL_ICONS.copy}</span>
          </div>
        </div>
        
        ${reviewCount > 0 ? `
          <div class="detail-section">
            <h3 class="detail-section-title">${PL_ICONS.rub} ${reviewsTitle} (${reviewCount})</h3>
            <div class="reviews-container">
              ${reviewsHTML}
            </div>
          </div>
        ` : ''}
        
        <div class="detail-section review-section">
          <div class="review-collapsible">
            <button class="review-toggle-btn" id="reviewToggleBtn">
              <span class="toggle-label">${PL_ICONS.pen} ${leaveReviewText}</span>
              <span class="toggle-arrow" id="reviewToggleArrow">▼</span>
            </button>
            <div id="reviewCollapsible" style="display: none;">
              <p class="review-form-lede"></p>
              
              <div class="review-form-body">
                <div class="review-hints">
                  <p class="review-hints-title">${reviewHintTitle}</p>
                  <p class="review-hint-line">✅ ${reviewHint1}</p>
                  <p class="review-hint-line">🕌 ${reviewHint2}</p>
                  <p class="review-hint-line">📋 ${reviewHint3}</p>
                  <p class="review-hint-line">🗺️ ${reviewHint4}</p>
                </div>
                
                <p class="rate-label">${rateText}</p>
                <div class="star-rating-input" id="starRatingInput">
                  <span class="star-input" data-rating="1">${PL_ICONS.star}</span>
                  <span class="star-input" data-rating="2">${PL_ICONS.star}</span>
                  <span class="star-input" data-rating="3">${PL_ICONS.star}</span>
                  <span class="star-input" data-rating="4">${PL_ICONS.star}</span>
                  <span class="star-input" data-rating="5">${PL_ICONS.star}</span>
                </div>
                <textarea 
                  class="review-textarea" 
                  id="reviewText" 
                  placeholder="${reviewPlaceholder}"></textarea>
                <button class="review-submit-btn" id="submitReviewBtn">${submitText}</button>
              </div>
              
              <div id="reviewSuccessMessage" class="review-success" style="display: none;">
                <div class="review-success-icon">${PL_ICONS.check}</div>
                <h3>${thankYouText}</h3>
                <p>${reviewReceivedText}</p>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
    
    ${(place.kakaoMapUrl || place.naverMapUrl) ? `
      <div class="nav-dock" aria-label="${navigationTitle}">
        ${place.kakaoMapUrl ? `
          <a href="${place.kakaoMapUrl}" target="_blank" class="dock-btn dock-btn--kakao">
            ${PL_ICONS.nav}
            <span>KakaoMap</span>
          </a>
        ` : ''}
        ${place.naverMapUrl ? `
          <a href="${place.naverMapUrl}" target="_blank" rel="noopener" class="dock-btn dock-btn--naver" onclick="event.preventDefault(); window.Telegram.WebApp.openLink('${place.naverMapUrl}', {try_instant_view: false});">
            ${PL_ICONS.nav}
            <span>NaverMap</span>
          </a>
        ` : ''}
      </div>
    ` : ''}
  `;
  
  if (photos.length > 1) {
    initDetailCarousel(photos.length);
  }

  initReviewSubmission(place.id);      
}




// ============================================
// REVIEW SUBMISSION (with I18N)
// ============================================

function initReviewSubmission(placeId) {
  const toggleBtn = document.getElementById('reviewToggleBtn');
  const collapsible = document.getElementById('reviewCollapsible');
  const arrow = document.getElementById('reviewToggleArrow');
  const stars = document.querySelectorAll('.star-input');
  const submitBtn = document.getElementById('submitReviewBtn');
  const reviewText = document.getElementById('reviewText');
  
  let selectedRating = 0;
  
  // Translated texts
  const t = window.I18N ? (key) => I18N.t(key) : (key) => key;
  const selectRatingText = t('detail.selectRating') !== 'detail.selectRating' ? t('detail.selectRating') : 'Iltimos, baho tanlang!';
  const loadingText = t('detail.loading') !== 'detail.loading' ? t('detail.loading') : 'Yuklanmoqda...';
  const submitText = t('detail.submit') !== 'detail.submit' ? t('detail.submit') : 'Yuborish';
  const errorText = t('detail.submitError') !== 'detail.submitError' ? t('detail.submitError') : 'Xatolik yuz berdi. Internetni tekshiring.';
  
  toggleBtn.addEventListener('click', () => {
    const isVisible = collapsible.style.display !== 'none';
    collapsible.style.display = isVisible ? 'none' : 'block';
    arrow.textContent = isVisible ? '▼' : '▲';
    toggleBtn.classList.toggle('active', !isVisible);
  });
  
  stars.forEach(star => {
    star.addEventListener('click', () => {
      selectedRating = parseInt(star.dataset.rating);
      stars.forEach((s, idx) => {
        s.classList.toggle('selected', idx < selectedRating);
      });
    });
  });
  
  submitBtn.addEventListener('click', async () => {
    if (selectedRating === 0) {
      tg.showAlert(selectRatingText);
      return;
    }
    
    submitBtn.disabled = true;
    submitBtn.textContent = loadingText;
    
    try {
      const userId = tg.initDataUnsafe?.user?.id || 'web_user';
      
      const reviewData = {
        place_id: placeId,
        mosque_id: placeId,  // Backward compatibility
        user_id: userId,
        rating: selectedRating,
        review_text: reviewText.value.trim() || '',
        timestamp: new Date().toISOString()
      };
      
      const response = await fetch(`${API_CONFIG.BASE_URL}/api/review/submit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(reviewData)
      });
      
      const result = await response.json();
      
      if (result.success) {
        document.querySelector('.review-collapsible .review-form-body').style.display = 'none';
        document.getElementById('starRatingInput').style.display = 'none';
        reviewText.style.display = 'none';
        submitBtn.style.display = 'none';
        document.querySelector('.review-collapsible p').style.display = 'none';
        document.getElementById('reviewSuccessMessage').style.display = 'block';
        
        setTimeout(() => {
          window.location.reload();
        }, 2000);
      } else {
        const tryAgainText = t('detail.tryAgain') !== 'detail.tryAgain' ? t('detail.tryAgain') : 'Qaytadan urinib ko\'ring';
        tg.showAlert('Xatolik: ' + (result.error || tryAgainText));
        submitBtn.disabled = false;
        submitBtn.textContent = submitText;
      }
    } catch (error) {
      tg.showAlert(errorText);
      submitBtn.disabled = false;
      submitBtn.textContent = submitText;
    }
  });
}

// ============================================
// ERROR HANDLING & PAGE LOADING (with I18N)
// ============================================

function showError(message) {
  detailLoading.style.display = 'none';
  detailContent.style.display = 'none';
  detailError.style.display = 'block';
  errorMessage.textContent = message;
}

async function loadPlaceDetail() {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  
  const placeId = getPlaceId();
  
  // Translated texts
  const t = window.I18N ? (key) => I18N.t(key) : (key) => key;
  const idNotFoundText = t('detail.idNotFound') !== 'detail.idNotFound' ? t('detail.idNotFound') : `${CONFIG.name} ID topilmadi. Iltimos, orqaga qaytib, qaytadan tanlang.`;
  const loadErrorText = t('detail.loadError') !== 'detail.loadError' ? t('detail.loadError') : `Ma'lumotlarni yuklashda xatolik yuz berdi. Iltimos, internetni tekshirib, qaytadan urinib ko'ring.`;
  const timeoutErrorText = t('detail.timeoutError') !== 'detail.timeoutError' ? t('detail.timeoutError') : 'Server javob bermadi (30 soniya). Server uyg\'onayotgan bo\'lishi mumkin, iltimos 1 daqiqa kuting va qaytadan urinib ko\'ring.';
  const notFoundErrorText = t('detail.notFound') !== 'detail.notFound' ? t('detail.notFound') : `${CONFIG.name} topilmadi. Bu ${CONFIG.name.toLowerCase()} bazadan o'chirilgan bo'lishi mumkin.`;
  
  if (!placeId) {
    showError(idNotFoundText);
    return;
  }

  detailLoading.style.display = 'flex';
  detailError.style.display = 'none';
  detailContent.style.display = 'none';
  
  try {
    const place = await fetchPlaceDetail(placeId);
    console.log(`📊 View count for "${place.name}": ${place.view_count || 0}`);
    incrementViewCount(placeId);
    
    detailLoading.style.display = 'none';
    detailContent.style.display = 'block';
    
    await renderPlaceDetail(place);
    
  } catch (error) {
    let errorMsg = loadErrorText;
    
    if (error.name === 'TimeoutError') {
      errorMsg = timeoutErrorText;
    } else if (error.message.includes('404')) {
      errorMsg = notFoundErrorText;
    }
    
    showError(errorMsg);
  }
}

// ============================================
// INITIALIZATION
// ============================================

document.addEventListener('DOMContentLoaded', loadPlaceDetail);

console.log('✅ Places Detail JS loaded');
