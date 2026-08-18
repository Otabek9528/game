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

// The detail API has no user coordinates, so it may omit distance.
// The list page already computed it — recover it from the saved search state.
function getDistanceFromSearchState(placeId) {
  try {
    const saved = localStorage.getItem(`${PLACE_TYPE}_search_state`);
    if (!saved) return null;
    const state = JSON.parse(saved);
    const match = (state.places || []).find(p => String(p.id) === String(placeId));
    return (match && match.distance !== null && match.distance !== undefined) ? match.distance : null;
  } catch (e) {
    return null;
  }
}

async function renderPlaceDetail(place) {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  
  if (place.distance === null || place.distance === undefined) {
    place.distance = getDistanceFromSearchState(place.id);
  }
  
  const photos = await discoverPhotos(place.photo, 10);
  
  const photoHTML = createDetailPhotoCarousel(photos);
  const starRatingHTML = generateStarRating(place.reviews);
  const reviewsHTML = renderReviews(place.reviews);
  const reviewCount = place.reviews ? place.reviews.length : 0;
  const hasDistance = place.distance !== null && place.distance !== undefined;
  const distanceDisplay = hasDistance ? Number(place.distance).toFixed(1) : 'N/A';
  
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
          ${hasDistance ? `
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
        
        <!-- Community-submitted, admin-moderated. Filled by PlaceExtras
             with DOM APIs so no place-supplied string touches innerHTML. -->
        <div class="detail-section" id="pdSocialSection"></div>
        <div class="detail-section" id="pdNoteSection"></div>

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

  // Social links + owner note. Mounted last so it can read place.pendingFields.
  if (window.PlaceExtras) PlaceExtras.mount(place);
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

/* ============================================================
   PLACE EXTRAS — social links + owner info note

   Community-submitted, admin-moderated. Everything a visitor can
   see here is either already approved (it came back on the place
   payload) or is shown as "waiting for review" — a submission is
   never rendered as though it were live.

   Mounted by renderPlaceDetail() into the two empty sections it
   leaves in the card, and re-mounted on languageChanged.

   Sheet markup lives in places-detail.html; this only fills and
   drives it.
   ============================================================ */
(function () {
  'use strict';

  // Trailing slash trimmed once here — API_CONFIG.BASE_URL carries one, and
  // the older `${BASE_URL}/api/...` call sites end up with a double slash.
  var API_BASE = (window.API_CONFIG && API_CONFIG.BASE_URL
    ? API_CONFIG.BASE_URL
    : 'https://vegukin-api.duckdns.org/').replace(/\/+$/, '');

  // Keep in step with NOTE_MAX_LENGTH in place_submissions_api.py. The server
  // is the authority; this only stops the keyboard before the round-trip.
  var NOTE_MAX = 500;

  var TOAST_MS = 3200;

  var PD_ICONS = {
    telegram: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M9.78 18.65l.28-4.23 7.68-6.92c.34-.31-.07-.46-.52-.19L7.74 13.3 3.64 12c-.88-.25-.89-.86.2-1.3l15.97-6.16c.73-.33 1.43.18 1.15 1.3l-2.72 12.81c-.19.91-.74 1.13-1.5.71L12.6 16.3l-2.01 1.95c-.23.23-.42.42-.81.42z"/></svg>',
    tiktok: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.6 2h-3.2v13.2a2.9 2.9 0 1 1-2.4-2.85V9.1a6.1 6.1 0 1 0 5.6 6.08V8.9a7.3 7.3 0 0 0 4.3 1.38V7.06A4.4 4.4 0 0 1 16.6 2z"/></svg>',
    instagram: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5.2"/><circle cx="12" cy="12" r="4.1"/><circle cx="17.3" cy="6.7" r="1.25" fill="currentColor" stroke="none"/></svg>',
    plus: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"/></svg>',
    clock: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
    info: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v4h1"/></svg>',
    pen: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.4 2.4 0 0 1 3.4 3.4L8 18.8 3 20l1.2-5L17 3Z"/></svg>'
  };

  var PLATFORMS = [
    { field: 'telegram',  prop: 'telegramUrl',  label: 'Telegram',  icon: PD_ICONS.telegram,
      hintKey: 'detail.sheet.telegramHint',  placeholder: '@username' },
    { field: 'tiktok',    prop: 'tiktokUrl',    label: 'TikTok',    icon: PD_ICONS.tiktok,
      hintKey: 'detail.sheet.tiktokHint',    placeholder: '@username' },
    { field: 'instagram', prop: 'instagramUrl', label: 'Instagram', icon: PD_ICONS.instagram,
      hintKey: 'detail.sheet.instagramHint', placeholder: '@username' }
  ];

  var place = null;          // last rendered place payload
  var pendingFields = [];    // fields already queued, from the API
  var sheetCtx = null;       // { field, isEdit, current }
  var sending = false;
  var toastTimer = null;

  function $(id) { return document.getElementById(id); }

  function t(key, fallback) {
    if (window.I18N) {
      var v = I18N.t(key);
      if (v !== key) return v;
    }
    return fallback;
  }

  function haptic(kind) {
    try { tg.HapticFeedback.impactOccurred(kind || 'light'); } catch (e) {}
  }

  function notify(kind) {
    try { tg.HapticFeedback.notificationOccurred(kind); } catch (e) {}
  }

  // The page ships data-i18n attributes but nothing ever applied them, so the
  // loading/error/retry strings were stuck in Uzbek. Applying them here fixes
  // those too. textContent, not innerHTML — none of these keys carry markup.
  function applyI18n(root) {
    var scope = root || document;
    var nodes = scope.querySelectorAll('[data-i18n]');
    for (var i = 0; i < nodes.length; i++) {
      var key = nodes[i].getAttribute('data-i18n');
      var val = window.I18N ? I18N.t(key) : key;
      if (val && val !== key) nodes[i].textContent = val;
    }
  }

  // Section headings pair a trusted constant SVG with a translated label.
  // The icon goes in via innerHTML; the label always via a text node, so no
  // place-supplied string ever reaches innerHTML on this page.
  function sectionTitle(labelText) {
    var h = document.createElement('h3');
    h.className = 'detail-section-title';
    h.innerHTML = PL_ICONS.rub;
    h.appendChild(document.createTextNode(' ' + labelText));
    return h;
  }

  function iconSpan(className, svg) {
    var s = document.createElement('span');
    s.className = className;
    s.innerHTML = svg;
    return s;
  }

  // Show "@handle" rather than the full URL — shorter, and it reads as an
  // identity instead of a link.
  function displayHandle(field, url) {
    try {
      var u = new URL(url);
      var segs = u.pathname.split('/').filter(Boolean);
      if (!segs.length) return url;
      if (field === 'telegram' && (segs[0].charAt(0) === '+' || segs[0] === 'joinchat')) {
        return t('detail.social.inviteLink', 'Havola');
      }
      if (field === 'tiktok' && (u.hostname === 'vm.tiktok.com' || u.hostname === 'vt.tiktok.com')) {
        return t('detail.social.inviteLink', 'Havola');
      }
      return '@' + segs[0].replace(/^@/, '');
    } catch (e) {
      return url;
    }
  }

  // Opening a profile from inside a Telegram webview.
  //
  // A plain target="_blank" is swallowed by the webview — the tap does
  // nothing, which is why only the t.me tile appeared to work (Telegram
  // recognises its own links). Telegram exposes two explicit methods:
  //
  //   openTelegramLink : opens a t.me link inside Telegram itself — one tap,
  //                      straight to the channel, no browser in between
  //   openLink         : hands the URL to the external browser, which is what
  //                      lets the OS forward instagram.com / tiktok.com into
  //                      the installed app via universal links
  //
  // The href stays on the anchor so long-press-to-copy still works and the
  // page degrades to an ordinary link when opened outside Telegram.
  function openProfile(field, url) {
    try {
      if (field === 'telegram' && tg && typeof tg.openTelegramLink === 'function') {
        tg.openTelegramLink(url);
        return;
      }
      if (tg && typeof tg.openLink === 'function') {
        tg.openLink(url);
        return;
      }
    } catch (e) {}
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  function isPending(field) {
    return pendingFields.indexOf(field) !== -1;
  }

  function markPending(field) {
    if (!isPending(field)) pendingFields.push(field);
    if (place) place.pendingFields = pendingFields.slice();
  }

  // ============================================
  // SOCIAL ROW
  // ============================================

  function buildTile(p) {
    var value = place ? place[p.prop] : null;

    var tile = document.createElement('div');
    tile.className = 'pd-social-tile pd-social-tile--on pd-social-tile--' + p.field;

    var link = document.createElement('a');
    link.className = 'pd-social-link';
    link.href = value;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    link.appendChild(iconSpan('pd-social-icon', p.icon));

    var text = document.createElement('span');
    text.className = 'pd-social-text';
    var name = document.createElement('span');
    name.className = 'pd-social-name';
    name.textContent = p.label;
    text.appendChild(name);
    var handle = document.createElement('span');
    handle.className = 'pd-social-state';
    handle.textContent = displayHandle(p.field, value);
    text.appendChild(handle);
    link.appendChild(text);

    link.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      haptic('light');
      openProfile(p.field, value);
    });
    tile.appendChild(link);

    // No correction affordance: once a link is set it is fixed, and changes go
    // through the admin rather than back through the queue. Letting anyone
    // re-propose a link that already works produced churn to review and a
    // steady trickle of competing values for the same field.
    return tile;
  }

  // One quiet line + text link, used wherever there is nothing to show yet.
  // Deliberately not a button: a big "+" reads as "press me" and collects
  // curiosity taps, while a sentence reads as "if you happen to know this".
  function quietPrompt(text, linkLabel, onClick) {
    var wrap = document.createElement('p');
    wrap.className = 'pd-quiet';
    wrap.appendChild(document.createTextNode(text + ' '));
    var link = document.createElement('button');
    link.type = 'button';
    link.className = 'pd-quiet-link';
    link.textContent = linkLabel;
    link.addEventListener('click', onClick);
    wrap.appendChild(link);
    return wrap;
  }

  function renderSocial() {
    var host = $('pdSocialSection');
    if (!host) return;
    host.hidden = false;
    host.textContent = '';

    // A field awaiting review is shown exactly as if nothing were there — no
    // "under review" badge — but it is not offered for input either, so a
    // second person cannot queue a competing value and the first cannot
    // resubmit thinking it failed.
    var shown = [];
    var offerable = [];
    PLATFORMS.forEach(function (p) {
      if (place && place[p.prop]) shown.push(p);
      else if (!isPending(p.field)) offerable.push(p);
    });

    // Nothing to show and nothing to offer: drop the section entirely rather
    // than leave a heading over empty space.
    if (!shown.length && !offerable.length) {
      host.hidden = true;
      return;
    }

    host.appendChild(sectionTitle(t('detail.social.title', 'Ijtimoiy tarmoqlar')));

    if (!shown.length) {
      host.appendChild(quietPrompt(
        t('detail.social.emptyPrompt', 'Bu joyning ijtimoiy tarmoqlarini bilasizmi?'),
        t('detail.social.add', 'Qo\'shish'),
        function () { pickField(offerable); }));
      return;
    }

    // Column count follows the number of real links, so a place with only a
    // Telegram group gets one wide, confident tile instead of a third of a row
    // next to two blanks.
    var grid = document.createElement('div');
    grid.className = 'pd-social-grid pd-social-grid--' + shown.length;
    shown.forEach(function (p) { grid.appendChild(buildTile(p)); });
    host.appendChild(grid);

    // The remaining platforms are an aside, not a call to action: same quiet
    // text link as the all-empty state, so the real links keep the focus.
    if (offerable.length) {
      host.appendChild(quietPrompt(
        t('detail.social.addMorePrompt', 'Boshqa tarmoqdagi sahifasini bilasizmi?'),
        t('detail.social.add', 'Qo\'shish'),
        function () { pickField(offerable); }));
    }
  }

  // ============================================
  // INFO NOTE
  // ============================================

  function renderNote() {
    var host = $('pdNoteSection');
    if (!host) return;
    host.hidden = false;
    host.textContent = '';

    var value = place ? place.ownerNote : null;
    var pending = isPending('note');

    if (!value && pending) {
      host.hidden = true;      // queued: shown as nothing, offered as nothing
      return;
    }

    host.appendChild(sectionTitle(t('detail.note.title', 'Qo\'shimcha ma\'lumot')));

    if (value) {
      var card = document.createElement('div');
      card.className = 'pd-note-card';
      var text = document.createElement('p');
      text.className = 'pd-note-text';
      // textContent, always. Line breaks survive via white-space: pre-line
      // in the CSS rather than by turning newlines into <br>.
      text.textContent = value;
      card.appendChild(text);
      host.appendChild(card);

      if (!pending) {
        host.appendChild(noteAction(
          t('detail.note.suggestEdit', 'O\'zgartirish taklif qilish'), value));
      }
      return;
    }

    host.appendChild(quietPrompt(
      t('detail.note.empty', 'Ish vaqti va dam olish kunlari hali qo\'shilmagan.'),
      t('detail.note.addCta', 'Ma\'lumot qo\'shish'),
      function () { openSheet('note', null); }));
  }

  function noteAction(label, current) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'pd-note-cta';
    btn.innerHTML = current ? PD_ICONS.pen : PD_ICONS.plus;
    btn.appendChild(document.createTextNode(' ' + label));
    btn.addEventListener('click', function () { openSheet('note', current); });
    return btn;
  }

  // ============================================
  // SUBMISSION SHEET
  // ============================================

  // With one platform left there is nothing to choose, so go straight in.
  function pickField(missing) {
    if (!missing || !missing.length) return;
    if (missing.length === 1) { openSheet(missing[0].field, null); return; }
    openPicker(missing);
  }

  function openPicker(missing) {
    var backdrop = $('pdSheetBackdrop');
    var picker = $('pdSheetPicker');
    if (!backdrop || !picker) return;

    sheetCtx = null;
    picker.textContent = '';
    missing.forEach(function (p) {
      var row = document.createElement('button');
      row.type = 'button';
      row.className = 'pd-picker-row pd-picker-row--' + p.field;
      row.appendChild(iconSpan('pd-picker-icon', p.icon));
      var name = document.createElement('span');
      name.className = 'pd-picker-name';
      name.textContent = p.label;
      row.appendChild(name);
      row.addEventListener('click', function () { openSheet(p.field, null); });
      picker.appendChild(row);
    });

    showSheet('pick', t('detail.sheet.pickTitle', 'Nimani qo\'shmoqchisiz?'), PD_ICONS.plus);
  }

  function platformFor(field) {
    for (var i = 0; i < PLATFORMS.length; i++) {
      if (PLATFORMS[i].field === field) return PLATFORMS[i];
    }
    return null;
  }

  function sheetTitleText(field, isEdit) {
    if (field === 'note') {
      return isEdit
        ? t('detail.sheet.noteEditTitle', 'Ma\'lumotni o\'zgartirish')
        : t('detail.sheet.noteAddTitle', 'Ma\'lumot qo\'shish');
    }
    var p = platformFor(field);
    var name = p ? p.label : field;
    var tpl = isEdit
      ? t('detail.sheet.editTitle', '{platform} havolasini o\'zgartirish')
      : t('detail.sheet.addTitle', '{platform} havolasini qo\'shish');
    return tpl.replace('{platform}', name);
  }

  // Shared open mechanics for both sheet modes ('pick' and 'input').
  function showSheet(mode, titleText, iconHTML, iconClass) {
    var backdrop = $('pdSheetBackdrop');
    var sheet = $('pdSheet');
    if (!backdrop || !sheet) return;

    var picking = mode === 'pick';

    $('pdSheetIcon').innerHTML = iconHTML || '';
    $('pdSheetIcon').className = 'pd-sheet-icon' + (iconClass ? ' ' + iconClass : '');
    $('pdSheetTitle').textContent = titleText;

    $('pdSheetPicker').hidden = !picking;
    $('pdSheetMeta').hidden = picking;
    $('pdSheetModeration').hidden = picking;
    $('pdSheetSend').hidden = picking;
    if (picking) {
      $('pdSheetCurrent').hidden = true;
      $('pdSheetInput').hidden = true;
      $('pdSheetTextarea').hidden = true;
    }

    setError(null);

    if (backdrop.hidden) {
      backdrop.hidden = false;
      // Next frame, so the transition has a start state to animate from.
      requestAnimationFrame(function () {
        backdrop.classList.add('visible');
        sheet.classList.add('visible');
      });
      haptic('light');
      if (tg.BackButton) {
        tg.BackButton.offClick(handleMainBackButton);
        tg.BackButton.onClick(handleSheetBackButton);
      }
    }
  }

  function openSheet(field, current) {
    sheetCtx = { field: field, isEdit: !!current, current: current || null };
    sending = false;

    var isNote = field === 'note';
    var p = platformFor(field);

    var input = $('pdSheetInput');
    var area = $('pdSheetTextarea');
    var counter = $('pdSheetCounter');

    input.hidden = isNote;
    area.hidden = !isNote;
    counter.hidden = !isNote;

    if (isNote) {
      area.value = current || '';
      area.placeholder = t('detail.sheet.notePlaceholder',
        'Masalan:\nDu-Ju: 11:00 - 22:00\nShanba: yopiq');
      updateCounter();
    } else {
      input.value = '';
      input.placeholder = p ? p.placeholder : '';
    }

    // Current value, shown when this is a correction so the reviewer's diff
    // and the submitter's starting point agree.
    var curWrap = $('pdSheetCurrent');
    if (current) {
      $('pdSheetCurrentValue').textContent = isNote ? current : displayHandle(field, current);
      curWrap.hidden = false;
    } else {
      curWrap.hidden = true;
    }

    $('pdSheetHint').textContent = isNote
      ? t('detail.sheet.noteHint', 'Ish vaqti, dam olish kunlari yoki e\'lon.')
      : t(p ? p.hintKey : '', '@username yoki havola');

    setSending(false);
    showSheet('input', sheetTitleText(field, !!current),
      isNote ? PD_ICONS.info : (p ? p.icon : ''),
      isNote ? '' : 'pd-sheet-icon--' + field);

    // Deliberately not focused. Auto-focus makes the on-screen keyboard jump
    // up the moment the sheet opens, covering half of it before the user has
    // read what is being asked for. They tap the field when ready.
  }

  function closeSheet() {
    var backdrop = $('pdSheetBackdrop');
    var sheet = $('pdSheet');
    if (!backdrop || !sheet || backdrop.hidden) return;

    backdrop.classList.remove('visible');
    sheet.classList.remove('visible');
    sheet.style.transform = '';
    setTimeout(function () { backdrop.hidden = true; }, 280);

    sheetCtx = null;

    if (tg.BackButton) {
      tg.BackButton.offClick(handleSheetBackButton);
      tg.BackButton.onClick(handleMainBackButton);
    }
  }

  // Named, so offClick can remove exactly this handler.
  function handleSheetBackButton() { closeSheet(); }

  function isSheetOpen() {
    var b = $('pdSheetBackdrop');
    return !!b && !b.hidden;
  }

  function setError(message) {
    var el = $('pdSheetError');
    if (!el) return;
    if (!message) {
      el.hidden = true;
      el.textContent = '';
      return;
    }
    el.textContent = message;
    el.hidden = false;
  }

  function setSending(on) {
    sending = on;
    var btn = $('pdSheetSend');
    if (!btn) return;
    btn.disabled = on;
    btn.textContent = on
      ? t('detail.sheet.sending', 'Yuborilmoqda...')
      : t('detail.sheet.send', 'Yuborish');
  }

  function updateCounter() {
    var area = $('pdSheetTextarea');
    var counter = $('pdSheetCounter');
    if (!area || !counter) return;
    var n = area.value.length;
    counter.textContent = n + ' / ' + NOTE_MAX;
    counter.classList.toggle('pd-sheet-counter--near', n > NOTE_MAX - 50);
  }

  // Server codes -> localised copy. Anything unmapped falls back to the
  // server's own English text, so a new code still says something useful.
  function messageForCode(code, serverText) {
    var key = 'detail.submit.err.' + code;
    var msg = window.I18N ? I18N.t(key) : key;
    if (msg && msg !== key) return msg;
    return serverText || t('detail.submit.err.server_error',
      'Xatolik yuz berdi. Qaytadan urinib ko\'ring.');
  }

  function submit() {
    if (sending || !sheetCtx || !place) return;

    var field = sheetCtx.field;
    var isNote = field === 'note';
    var value = isNote ? $('pdSheetTextarea').value : $('pdSheetInput').value;

    if (!value || !value.trim()) {
      setError(t('detail.submit.err.empty', 'Avval to\'ldiring.'));
      return;
    }

    setError(null);
    setSending(true);

    fetch(API_BASE + '/api/place/' + encodeURIComponent(place.id) + '/submit', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Signed initData — the server verifies this and ignores any user id
        // we might send, so a submission cannot be attributed to someone else.
        'X-Init-Data': (tg && tg.initData) ? tg.initData : ''
      },
      body: JSON.stringify({ field: field, value: value }),
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    })
      .then(function (res) {
        return res.json().then(function (data) { return { ok: res.ok, data: data }; });
      })
      .then(function (r) {
        if (r.ok && r.data && r.data.success) {
          // The value is deliberately NOT written into the card. It shows as
          // pending until an admin approves it and the API returns it.
          markPending(field);
          closeSheet();
          renderSocial();
          renderNote();
          notify('success');
          showToast(t('detail.submit.ok',
            'Rahmat! Taklifingiz ko\'rib chiqilmoqda.'));
          return;
        }

        var code = (r.data && r.data.code) || 'server_error';
        var text = messageForCode(code, r.data && r.data.error);

        // Nothing the submitter can retype will change these, so the sheet
        // closes and the answer arrives as a toast instead of an inline error
        // above an input they would keep poking at.
        if (code === 'already_pending') {
          markPending(field);
          closeSheet();
          renderSocial();
          renderNote();
          showToast(text);
          return;
        }
        if (code === 'rate_limited' || code === 'same_as_current' ||
            code === 'place_not_found') {
          closeSheet();
          showToast(text);
          return;
        }

        setSending(false);
        setError(text);
        notify('error');
      })
      .catch(function (err) {
        setSending(false);
        setError(err && err.name === 'TimeoutError'
          ? t('detail.submit.err.timeout',
              'Server javob bermadi. Qaytadan urinib ko\'ring.')
          : t('detail.submit.err.network',
              'Internetga ulanib bo\'lmadi. Qaytadan urinib ko\'ring.'));
        notify('error');
      });
  }

  // ============================================
  // TOAST
  // ============================================

  function showToast(message) {
    var el = $('pdToast');
    if (!el) return;
    el.textContent = message;
    el.hidden = false;
    requestAnimationFrame(function () { el.classList.add('visible'); });
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      el.classList.remove('visible');
      setTimeout(function () { el.hidden = true; }, 260);
    }, TOAST_MS);
  }

  // ============================================
  // WIRING
  // ============================================

  function bindSheetOnce() {
    if (bindSheetOnce.done) return;
    bindSheetOnce.done = true;

    var backdrop = $('pdSheetBackdrop');
    var sheet = $('pdSheet');
    if (!backdrop || !sheet) return;

    backdrop.addEventListener('click', function (e) {
      if (e.target === backdrop) closeSheet();
    });

    var cancel = $('pdSheetCancel');
    if (cancel) cancel.addEventListener('click', closeSheet);

    var send = $('pdSheetSend');
    if (send) send.addEventListener('click', submit);

    var input = $('pdSheetInput');
    if (input) {
      input.addEventListener('input', function () { setError(null); });
      input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') { e.preventDefault(); submit(); }
      });
    }

    var area = $('pdSheetTextarea');
    if (area) {
      area.addEventListener('input', function () {
        setError(null);
        updateCounter();
      });
    }

    window.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && isSheetOpen()) closeSheet();
    });

    bindSheetDrag(sheet);
  }

  // Swipe down to dismiss, from anywhere on the sheet.
  //
  // Three things must keep working while this is bound, which is why it is not
  // simply "any downward drag closes":
  //   - typing and selecting text in the input/textarea
  //   - scrolling the body when the content is taller than the sheet
  //   - horizontal gestures, which belong to the browser
  // So the gesture only becomes a dismiss once it is clearly vertical, clearly
  // downward, and the body is already scrolled to the top.
  function bindSheetDrag(sheet) {
    var DISMISS_PX = 90;   // past this on release, it closes
    var SLOP_PX = 8;       // movement before we decide whose gesture this is

    var startY = 0, startX = 0, dy = 0;
    var tracking = false, committed = false, scroller = null;

    function interactive(el) {
      return !!(el && el.closest && el.closest('input, textarea, select, button, a'));
    }

    function onStart(e) {
      if (sending) return;              // never yank the sheet out mid-submit
      if (interactive(e.target)) return;
      var t = e.touches ? e.touches[0] : e;
      startY = t.clientY;
      startX = t.clientX;
      dy = 0;
      tracking = true;
      committed = false;
      scroller = $('pdSheetBody');
    }

    function abandon(sheetEl) {
      tracking = false;
      committed = false;
      sheetEl.style.transition = '';
    }

    function onMove(e) {
      if (!tracking) return;
      var t = e.touches ? e.touches[0] : e;
      var moveY = t.clientY - startY;
      var moveX = t.clientX - startX;

      if (!committed) {
        if (Math.abs(moveY) < SLOP_PX && Math.abs(moveX) < SLOP_PX) return;
        // Mostly sideways, heading up, or there is content scrolled above:
        // not a dismiss. Hand the gesture back rather than fighting it.
        if (Math.abs(moveX) > Math.abs(moveY) || moveY < 0 ||
            (scroller && scroller.scrollTop > 0)) {
          abandon(sheet);
          return;
        }
        committed = true;
        sheet.style.transition = 'none';
      }

      dy = Math.max(0, moveY);
      // Without this the page behind scrolls along with the sheet.
      if (e.cancelable) e.preventDefault();
      sheet.style.transform = 'translateY(' + dy + 'px)';
    }

    function onEnd() {
      if (!tracking) return;
      var travelled = dy;
      tracking = false;
      committed = false;
      sheet.style.transition = '';
      if (travelled > DISMISS_PX) {
        closeSheet();
      } else {
        sheet.style.transform = '';
      }
      dy = 0;
    }

    sheet.addEventListener('touchstart', onStart, { passive: true });
    sheet.addEventListener('touchmove', onMove, { passive: false });
    sheet.addEventListener('touchend', onEnd);
    sheet.addEventListener('touchcancel', onEnd);

    // Mouse drags are tracked on the window so the gesture survives the
    // pointer leaving the sheet mid-drag.
    sheet.addEventListener('mousedown', onStart);
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onEnd);
  }

  function mount(placeData) {
    place = placeData || null;
    pendingFields = (place && place.pendingFields) ? place.pendingFields.slice() : [];
    bindSheetOnce();
    applyI18n(document);
    renderSocial();
    renderNote();
  }

  window.addEventListener('languageChanged', function () {
    applyI18n(document);
    if (place) {
      renderSocial();
      renderNote();
    }
    if (isSheetOpen() && sheetCtx) {
      $('pdSheetTitle').textContent = sheetTitleText(sheetCtx.field, sheetCtx.isEdit);
      setSending(sending);
    }
  });

  window.PlaceExtras = { mount: mount };
})();

