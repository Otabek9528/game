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

let carouselInterval = null;
let currentModalPhotos = [];
let currentModalIndex = 0;
let isModalOpen = false;

const imageModal = document.getElementById('imageModal');
const modalImage = document.getElementById('modalImage');
const modalClose = document.getElementById('modalClose');
const modalPrev = document.getElementById('modalPrev');
const modalNext = document.getElementById('modalNext');

// ============================================
// IMAGE MODAL FUNCTIONS
// ============================================

function openImageModal(photos, startIndex = 0) {
  currentModalPhotos = Array.isArray(photos) ? photos : [photos];
  currentModalIndex = startIndex;
  isModalOpen = true;
  
  updateModalImage();
  imageModal.classList.add('active');
  document.body.style.overflow = 'hidden';
  
  // Override back button to close modal
  if (tg.BackButton) {
    tg.BackButton.offClick(handleMainBackButton);
    tg.BackButton.onClick(handleModalBackButton);
  }
}

function closeImageModal() {
  imageModal.classList.remove('active');
  document.body.style.overflow = '';
  currentModalPhotos = [];
  currentModalIndex = 0;
  isModalOpen = false;
  
  // Restore original back button behavior
  if (tg.BackButton) {
    tg.BackButton.offClick(handleModalBackButton);
    tg.BackButton.onClick(handleMainBackButton);
  }
}

function navigateModal(direction) {
  if (currentModalPhotos.length <= 1) return;
  
  currentModalIndex += direction;
  
  if (currentModalIndex < 0) {
    currentModalIndex = currentModalPhotos.length - 1;
  } else if (currentModalIndex >= currentModalPhotos.length) {
    currentModalIndex = 0;
  }
  
  updateModalImage();
}

function updateModalImage() {
  const modalCounter = document.getElementById('modalCounter');
  
  if (modalImage && currentModalPhotos.length > 0) {
    modalImage.src = currentModalPhotos[currentModalIndex];
  }
  
  if (modalCounter) {
    modalCounter.textContent = `${currentModalIndex + 1} / ${currentModalPhotos.length}`;
  }
  
  const display = currentModalPhotos.length > 1 ? 'flex' : 'none';
  modalPrev.style.display = display;
  modalNext.style.display = display;
}

// Modal event listeners
imageModal.addEventListener('click', (e) => {
  if (e.target === imageModal) closeImageModal();
});

modalClose.addEventListener('click', (e) => {
  e.stopPropagation();
  closeImageModal();
});

modalPrev.addEventListener('click', (e) => {
  e.stopPropagation();
  navigateModal(-1);
});

modalNext.addEventListener('click', (e) => {
  e.stopPropagation();
  navigateModal(1);
});

document.addEventListener('keydown', (e) => {
  if (!imageModal.classList.contains('active')) return;
  
  if (e.key === 'Escape') {
    closeImageModal();
  } else if (e.key === 'ArrowLeft') {
    navigateModal(-1);
  } else if (e.key === 'ArrowRight') {
    navigateModal(1);
  }
});

// Touch swipe for modal navigation
let touchStartX = 0;
let touchEndX = 0;

const modalContent = imageModal.querySelector('.modal-content');
modalContent.addEventListener('touchstart', (e) => {
  touchStartX = e.changedTouches[0].screenX;
});

modalContent.addEventListener('touchend', (e) => {
  touchEndX = e.changedTouches[0].screenX;
  const swipeThreshold = 50;
  if (touchStartX - touchEndX > swipeThreshold) {
    navigateModal(1);
  } else if (touchEndX - touchStartX > swipeThreshold) {
    navigateModal(-1);
  }
});

// ============================================
// ENHANCED ZOOM WITH PAN FUNCTIONALITY
// ============================================

const modalImg = imageModal.querySelector('.modal-image');
let scale = 1;
let panning = false;
let pointX = 0;
let pointY = 0;
let start = { x: 0, y: 0 };
let lastTap = 0;

function setTransform() {
  modalImg.style.transform = `translate(${pointX}px, ${pointY}px) scale(${scale})`;
}

// Double-tap to toggle zoom
modalImg.addEventListener('click', (e) => {
  const currentTime = new Date().getTime();
  const tapLength = currentTime - lastTap;
  
  if (tapLength < 300 && tapLength > 0) {
    e.stopPropagation();
    if (scale > 1) {
      scale = 1;
      pointX = 0;
      pointY = 0;
    } else {
      scale = 2;
    }
    setTransform();
  }
  lastTap = currentTime;
});

// Pinch zoom
let initialDistance = 0;

modalImg.addEventListener('touchstart', (e) => {
  if (e.touches.length === 2) {
    e.preventDefault();
    const touch1 = e.touches[0];
    const touch2 = e.touches[1];
    initialDistance = Math.hypot(
      touch2.clientX - touch1.clientX,
      touch2.clientY - touch1.clientY
    );
  } else if (e.touches.length === 1 && scale > 1) {
    panning = true;
    start = { x: e.touches[0].clientX - pointX, y: e.touches[0].clientY - pointY };
  }
});

modalImg.addEventListener('touchmove', (e) => {
  if (e.touches.length === 2) {
    e.preventDefault();
    const touch1 = e.touches[0];
    const touch2 = e.touches[1];
    const currentDistance = Math.hypot(
      touch2.clientX - touch1.clientX,
      touch2.clientY - touch1.clientY
    );
    
    scale = Math.min(Math.max(1, (currentDistance / initialDistance) * scale), 4);
    setTransform();
  } else if (panning && e.touches.length === 1) {
    e.preventDefault();
    pointX = e.touches[0].clientX - start.x;
    pointY = e.touches[0].clientY - start.y;
    setTransform();
  }
});

modalImg.addEventListener('touchend', (e) => {
  if (e.touches.length < 2) {
    initialDistance = 0;
  }
  if (e.touches.length === 0) {
    panning = false;
    if (scale < 1.1) {
      scale = 1;
      pointX = 0;
      pointY = 0;
      setTransform();
    }
  }
});

// Mouse drag for desktop
modalImg.addEventListener('mousedown', (e) => {
  if (scale > 1) {
    e.preventDefault();
    panning = true;
    start = { x: e.clientX - pointX, y: e.clientY - pointY };
  }
});

document.addEventListener('mousemove', (e) => {
  if (panning) {
    e.preventDefault();
    pointX = e.clientX - start.x;
    pointY = e.clientY - start.y;
    setTransform();
  }
});

document.addEventListener('mouseup', () => {
  panning = false;
});

// Reset on modal close
imageModal.addEventListener('click', (e) => {
  if (e.target === imageModal) {
    scale = 1;
    pointX = 0;
    pointY = 0;
    setTransform();
  }
});

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
      <img src="${CONFIG.defaultPhoto}" alt="${CONFIG.name} photo" style="width: 100%; height: 100%; object-fit: cover; cursor: pointer;" onclick="openImageModal(['${CONFIG.defaultPhoto}'], 0)" />
    `;
  }
  
  if (photos.length === 1) {
    return `
      <img src="${photos[0]}" alt="${CONFIG.name} photo" style="width: 100%; height: 100%; object-fit: cover; cursor: pointer;" onclick="openImageModal(['${photos[0]}'], 0)" />
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
      let relativePos = (index - newIndex + totalPhotos) % totalPhotos;
      
      photo.classList.remove('center', 'left', 'right', 'hidden');
      
      if (relativePos === 0) {
        photo.classList.add('center');
      } else if (relativePos === 1) {
        photo.classList.add('right');
      } else if (relativePos === totalPhotos - 1) {
        photo.classList.add('left');
      } else {
        photo.classList.add('hidden');
      }
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
  
  // Auto-rotate carousel
  carouselInterval = setInterval(() => {
    updateCarousel((currentIndex + 1) % photos.length);
  }, 4000);
}

// ============================================
// RATING AND REVIEW FUNCTIONS (with I18N)
// ============================================

function generateStarRating(reviews) {
  const noRatingText = window.I18N ? I18N.t('detail.noReviews') : 'Hali izoh yo\'q';
  
  if (!reviews || reviews.length === 0) {
    return `<span class="no-rating-text">${noRatingText}</span>`;
  }
  
  const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
  const roundedRating = Math.round(avgRating);
  
  let starsHTML = '';
  for (let i = 1; i <= 5; i++) {
    if (i <= roundedRating) {
      starsHTML += `<span class="star gold">⭐</span>`;
    } else {
      starsHTML += `<span class="star grey">☆</span>`;
    }
  }
  
  return `<div class="star-container">${starsHTML}</div>`;
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
    const stars = '⭐'.repeat(review.rating);
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
      `<a href="tel:${phone}" class="detail-link" style="display: block; margin-bottom: 4px;">${phone}</a>`
    ).join('');
  }
  
  detailContent.innerHTML = `
    <div class="detail-card">
      <div class="detail-photo-section">
        <div class="detail-badges">
          <div class="detail-combined-badge">
            <div class="badge-stars">
              ${starRatingHTML}
            </div>
            ${place.distance ? `
              <div class="badge-distance">
                <span>📍</span>
                <span>${distanceDisplay} km</span>
              </div>
            ` : ''}
          </div>
        </div>
        
        ${photoHTML}
      </div>
      
      <div class="detail-content">
        <h1 class="detail-title">${place.name}</h1>
        <p class="detail-subtitle">${place.city || 'Unknown City'}</p>
        
        <div class="detail-section">
          <h3 class="detail-section-title">📞 ${contactTitle}</h3>
          <div class="detail-info-item">
            <span class="detail-icon">📱</span>
            <div style="flex: 1;">
              ${renderPhoneNumbers(place.phone)}
            </div>
          </div>
        </div>
        
        <div class="detail-section">
          <h3 class="detail-section-title">📍 ${addressTitle}</h3>
          <div class="detail-info-item" style="cursor: pointer;" onclick="copyAddress('${(place.address || '').replace(/'/g, "\\'")}', event)">
            <span class="detail-icon">🌐</span>
            <span class="detail-text">${place.address || noAddressText}</span>
            <span style="margin-left: auto; opacity: 0.5; font-size: 0.9rem;">📋</span>
          </div>
        </div>
        
        ${reviewCount > 0 ? `
          <div class="detail-section">
            <h3 class="detail-section-title">💬 ${reviewsTitle} (${reviewCount})</h3>
            <div class="reviews-container">
              ${reviewsHTML}
            </div>
          </div>
        ` : ''}
        
        <div class="detail-section">
          <h3 class="detail-section-title">🗺️ ${navigationTitle}</h3>
          <div class="nav-buttons">
            ${place.kakaoMapUrl ? `
              <a href="${place.kakaoMapUrl}" target="_blank" class="nav-button kakao-button">
                <span class="nav-icon">🟡</span>
                <span>KakaoMap</span>
              </a>
            ` : ''}
            ${place.naverMapUrl ? `
              <a href="${place.naverMapUrl}" target="_blank" rel="noopener" class="nav-button naver-button" onclick="event.preventDefault(); window.Telegram.WebApp.openLink('${place.naverMapUrl}', {try_instant_view: false});">
                <span class="nav-icon">🟢</span>
                <span>NaverMap</span>
              </a>
            ` : ''}
          </div>
        </div>
        
        <div class="detail-section review-section">
          <div class="review-collapsible">
            <button class="review-toggle-btn" id="reviewToggleBtn">
              <span>✍️ ${leaveReviewText}</span>
              <span class="toggle-arrow" id="reviewToggleArrow">▼</span>
            </button>
            <div id="reviewCollapsible" style="display: none;">
              <p style="text-align: center; margin: 16px 0 12px 0; color: #666; font-size: 0.9rem;">
              </p>
              
              <div style="background: #f0f9f5; border-left: 4px solid #00a884; padding: 14px; border-radius: 8px; margin-bottom: 16px;">
                <p style="margin: 0 0 10px 0; font-weight: 600; color: #2c5e2e; font-size: 0.95rem;">📝 ${reviewHintTitle}</p>
                <p style="margin: 4px 0; font-size: 0.88rem; color: #555;">✅ ${reviewHint1}</p>
                <p style="margin: 4px 0; font-size: 0.88rem; color: #555;">🕌 ${reviewHint2}</p>
                <p style="margin: 4px 0; font-size: 0.88rem; color: #555;">📋 ${reviewHint3}</p>
                <p style="margin: 4px 0; font-size: 0.88rem; color: #555;">🗺️ ${reviewHint4}</p>
              </div>
              
              <p style="text-align: center; margin: 0 0 8px 0; color: #666; font-size: 0.95rem;">${rateText}</p>
              <div class="star-rating-input" id="starRatingInput">
                <span class="star-input" data-rating="1">⭐</span>
                <span class="star-input" data-rating="2">⭐</span>
                <span class="star-input" data-rating="3">⭐</span>
                <span class="star-input" data-rating="4">⭐</span>
                <span class="star-input" data-rating="5">⭐</span>
              </div>
              <textarea 
                class="review-textarea" 
                id="reviewText" 
                placeholder="${reviewPlaceholder}"></textarea>
              <button class="review-submit-btn" id="submitReviewBtn">${submitText}</button>
              
              <div id="reviewSuccessMessage" style="display: none; text-align: center; padding: 30px 20px;">
                <div style="font-size: 3rem; margin-bottom: 12px;">✅</div>
                <h3 style="color: #00a884; margin: 0 0 8px 0;">${thankYouText}</h3>
                <p style="color: #666; margin: 0;">${reviewReceivedText}</p>
              </div>
            </div>
          </div>

        </div>
      </div>
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
        document.querySelector('.review-collapsible > div').style.display = 'none';
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
