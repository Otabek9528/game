// places.js - Generic place finder (handles Mosques, Restaurants, Shops) with I18N support

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
    searchPlaceholder: '서울 강동구 구천면로 271',
    pageTitle: 'Sizga eng yaqin 5 masjid',
    searchedTitle: 'Izlangan joyga eng yaqinlari',
    noResultsText: 'Hech qanday masjid topilmadi'
  },
  restaurant: {
    name: 'Oshxona',
    namePlural: 'Oshxonalar',
    nameGenitive: 'Oshxona',
    icon: '🍽️',
    buildingType: 'Oshxona',
    defaultPhoto: '../../assets/restaurant.jpg',
    searchPlaceholder: '서울 강남구 테헤란로 123',
    pageTitle: 'Sizga eng yaqin 5 oshxona',
    searchedTitle: 'Izlangan joyga eng yaqinlari',
    noResultsText: 'Hech qanday oshxona topilmadi'
  },
  shop: {
    name: 'Do\'kon',
    namePlural: 'Do\'konlar',
    nameGenitive: 'Do\'kon',
    icon: '🏪',
    buildingType: "Do'kon",
    defaultPhoto: '../../assets/store.jpg',
    searchPlaceholder: '서울 용산구 이태원로 123',
    pageTitle: 'Sizga eng yaqin 5 do\'kon',
    searchedTitle: 'Izlangan joyga eng yaqinlari',
    noResultsText: 'Hech qanday do\'kon topilmadi'
  }
};

// Get translated config based on current language
function getTranslatedConfig(placeType) {
  const base = PLACE_CONFIGS[placeType] || PLACE_CONFIGS.mosque;
  
  // If I18N not loaded, return base config
  if (!window.I18N) return base;
  
  return {
    ...base,
    name: I18N.t(`places.${placeType}.name`) !== `places.${placeType}.name` ? I18N.t(`places.${placeType}.name`) : base.name,
    namePlural: I18N.t(`places.${placeType}.namePlural`) !== `places.${placeType}.namePlural` ? I18N.t(`places.${placeType}.namePlural`) : base.namePlural,
    pageTitle: I18N.t(`places.${placeType}.pageTitle`) !== `places.${placeType}.pageTitle` ? I18N.t(`places.${placeType}.pageTitle`) : base.pageTitle,
    searchedTitle: I18N.t(`places.${placeType}.searchedTitle`) !== `places.${placeType}.searchedTitle` ? I18N.t(`places.${placeType}.searchedTitle`) : base.searchedTitle,
    noResultsText: I18N.t(`places.${placeType}.noResults`) !== `places.${placeType}.noResults` ? I18N.t(`places.${placeType}.noResults`) : base.noResultsText
  };
}

// ============================================
// GLOBAL STATE
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();
tg.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {}

// Get place type from URL parameter
const urlParams = new URLSearchParams(window.location.search);
const PLACE_TYPE = urlParams.get('type') || 'mosque';
let CONFIG = PLACE_CONFIGS[PLACE_TYPE] || PLACE_CONFIGS.mosque;

const STATE_KEY = `${PLACE_TYPE}_search_state`;

let currentMode = 'location';
let currentSearchAddress = '';
let currentPlaces = [];
let carouselIntervals = {};

// DOM Elements
const placeCardsContainer = document.getElementById('placeCards');
const searchBar = document.getElementById('addressSearchBar');
const clearSearchBtn = document.getElementById('clearSearchBtn');
const searchBtn = document.getElementById('searchBtn');
const searchByAddressBtn = document.getElementById('searchByAddressBtn');
const searchNearbyBtn = document.getElementById('searchNearbyBtn');
const addressInputSection = document.getElementById('addressInputSection');
const searchPlaceholder = document.getElementById('searchPlaceholder');
const placesPageTitle = document.getElementById('placesPageTitle');
const loadingIndicator = document.getElementById('loadingIndicator');
const noResults = document.getElementById('noResults');

let imageModal = null;
let currentModalPhotos = [];
let currentModalIndex = 0;
let isModalOpen = false;

// Back button handlers
const handleMainBackButton = () => {
  clearSearchState();
  window.location.href = "../../index.html";
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
// STATE MANAGEMENT
// ============================================

function saveSearchState() {
  const state = {
    mode: currentMode,
    address: currentSearchAddress,
    places: currentPlaces,
    timestamp: Date.now()
  };
  localStorage.setItem(STATE_KEY, JSON.stringify(state));
}

function loadSearchState() {
  const saved = localStorage.getItem(STATE_KEY);
  if (!saved) return null;
  
  try {
    const state = JSON.parse(saved);
    const age = Date.now() - state.timestamp;
    if (age > 30 * 60 * 1000) {
      clearSearchState();
      return null;
    }
    return state;
  } catch (e) {
    return null;
  }
}

function clearSearchState() {
  localStorage.removeItem(STATE_KEY);
}

// ============================================
// UI UPDATES (with I18N)
// ============================================

function updatePageTitle() {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  if (currentMode === 'address' && currentSearchAddress) {
    placesPageTitle.textContent = `${CONFIG.icon} ${CONFIG.searchedTitle}`;
  } else {
    placesPageTitle.textContent = `${CONFIG.icon} ${CONFIG.pageTitle}`;
  }
}

function updateUIText() {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  
  // Update page title
  document.title = window.I18N ? I18N.t('places.pageTitle').replace('{type}', CONFIG.namePlural) : `Yaqin ${CONFIG.namePlural}`;
  
  // Update search placeholder
  if (searchBar) {
    searchBar.placeholder = CONFIG.searchPlaceholder;
  }
  
  // Update no results text
  const noResultsText = document.querySelector('.no-results-text');
  if (noResultsText) {
    noResultsText.textContent = CONFIG.noResultsText;
  }
  
  // Update data-i18n elements
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (window.I18N) {
      const trans = I18N.t(key);
      if (trans !== key) {
        el.innerHTML = trans;
      }
    }
  });
  
  updatePageTitle();
}

// ============================================
// IMAGE MODAL
// ============================================

function createImageModal() {
  if (imageModal) return;
  
  imageModal = document.createElement('div');
  imageModal.className = 'image-modal';
  imageModal.innerHTML = `
    <div class="modal-content">
      <button class="modal-nav modal-nav-prev" id="modalPrev">‹</button>
      <img src="" alt="Full size image" class="modal-image" id="modalImage" />
      <button class="modal-nav modal-nav-next" id="modalNext">›</button>
      <button class="modal-close" id="modalClose">✕</button>
      <div class="modal-counter" id="modalCounter">1 / 1</div>
    </div>
  `;
  
  document.body.appendChild(imageModal);
  
  imageModal.addEventListener('click', (e) => {
    if (e.target === imageModal) closeImageModal();
  });
  
  document.getElementById('modalClose').addEventListener('click', (e) => {
    e.stopPropagation();
    closeImageModal();
  });
  
  document.getElementById('modalPrev').addEventListener('click', (e) => {
    e.stopPropagation();
    navigateModal(-1);
  });
  
  document.getElementById('modalNext').addEventListener('click', (e) => {
    e.stopPropagation();
    navigateModal(1);
  });
  
  document.addEventListener('keydown', handleModalKeyboard);
  
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

  // Enhanced zoom with pan functionality
  const modalImg = imageModal.querySelector('.modal-image');
  let scale = 1;
  let panning = false;
  let pointX = 0;
  let pointY = 0;
  let start = { x: 0, y: 0 };
  let lastTap = 0;
  let initialDistance = 0;
  
  function setTransform() {
    modalImg.style.transform = `translate(${pointX}px, ${pointY}px) scale(${scale})`;
  }
  
  // Double-tap to toggle zoom
  modalImg.addEventListener('click', (e) => {
    const currentTime = new Date().getTime();
    const tapLength = currentTime - lastTap;
    
    if (tapLength < 300 && tapLength > 0) {
      e.preventDefault();
      if (scale === 1) {
        scale = 2.5;
        const rect = modalImg.getBoundingClientRect();
        pointX = (rect.width / 2 - e.clientX) * 0.5;
        pointY = (rect.height / 2 - e.clientY) * 0.5;
      } else {
        scale = 1;
        pointX = 0;
        pointY = 0;
      }
      setTransform();
    }
    lastTap = currentTime;
  });
  
  // Pinch zoom
  modalImg.addEventListener('touchstart', (e) => {
    if (e.touches.length === 2) {
      e.preventDefault();
      initialDistance = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
    } else if (e.touches.length === 1 && scale > 1) {
      panning = true;
      start = {
        x: e.touches[0].clientX - pointX,
        y: e.touches[0].clientY - pointY
      };
    }
  });
  
  modalImg.addEventListener('touchmove', (e) => {
    if (e.touches.length === 2 && initialDistance > 0) {
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
}

function handleModalKeyboard(e) {
  if (!imageModal || !imageModal.classList.contains('active')) return;
  
  if (e.key === 'Escape') {
    closeImageModal();
  } else if (e.key === 'ArrowLeft') {
    navigateModal(-1);
  } else if (e.key === 'ArrowRight') {
    navigateModal(1);
  }
}

function openImageModal(photos, startIndex = 0) {
  if (!imageModal) createImageModal();
  
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
  if (!imageModal) return;
  
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
  const modalImage = document.getElementById('modalImage');
  const modalCounter = document.getElementById('modalCounter');
  const modalPrev = document.getElementById('modalPrev');
  const modalNext = document.getElementById('modalNext');
  
  if (modalImage && currentModalPhotos.length > 0) {
    modalImage.src = currentModalPhotos[currentModalIndex];
  }
  
  if (modalCounter) {
    modalCounter.textContent = `${currentModalIndex + 1} / ${currentModalPhotos.length}`;
  }
  
  if (modalPrev && modalNext) {
    const display = currentModalPhotos.length > 1 ? 'flex' : 'none';
    modalPrev.style.display = display;
    modalNext.style.display = display;
  }
}

// ============================================
// API FUNCTIONS
// ============================================

async function fetchNearbyPlaces(lat, lon, limit = 5) {
  const url = getApiUrl(API_CONFIG.ENDPOINTS.PLACES_NEARBY, { 
    lat, 
    lon, 
    building_type: CONFIG.buildingType, 
    limit 
  });
  
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (data.success && data.places) {
      return data.places;
    } else {
      throw new Error('Invalid API response');
    }
  } catch (error) {
    throw error;
  }
}

async function fetchPlacesByAddress(address, limit = 5) {
  const url = getApiUrl(API_CONFIG.ENDPOINTS.PLACES_BY_ADDRESS, { 
    address, 
    building_type: CONFIG.buildingType, 
    limit 
  });
  
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (data.success && data.places) {
      return data.places;
    } else {
      throw new Error('Invalid API response');
    }
  } catch (error) {
    throw error;
  }
}

// ============================================
// PHOTO FUNCTIONS (Optimized with Lazy Loading)
// ============================================

function checkImageExists(url) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => resolve(true);
    img.onerror = () => resolve(false);
    img.src = url;
  });
}

// Quick check for first photo only (fast initial load)
async function getFirstPhoto(photoPath) {
  const extensions = ['jpg', 'jpeg', 'png'];
  const basePath = `../../${photoPath}`;
  
  for (const ext of extensions) {
    const photoUrl = `${basePath}/1.${ext}`;
    const exists = await checkImageExists(photoUrl);
    if (exists) {
      return photoUrl;
    }
  }
  return null;
}

// Discover all photos (called lazily when card becomes visible)
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
// CAROUSEL FUNCTIONS (with Lazy Loading)
// ============================================

// Create skeleton placeholder while loading (with I18N)
function createSkeletonCard(placeId) {
  const loadingText = window.I18N ? I18N.t('places.loadingPhotos') : 'Rasmlar yuklanmoqda...';
  const hintText = window.I18N ? I18N.t('places.loadingHint') : 'Internet tezligingizga bog\'liq';
  
  return `
    <div class="place-photo-skeleton" data-place-id="${placeId}">
      <div class="skeleton-shimmer"></div>
      <div class="skeleton-text">
        <span class="skeleton-icon">🖼️</span>
        <span class="skeleton-message">${loadingText}</span>
        <span class="skeleton-hint">${hintText}</span>
      </div>
    </div>
  `;
}

// Create single photo display
function createSinglePhoto(photo, placeId) {
  return `
    <div class="place-photo-single" data-photos='${JSON.stringify([photo])}' data-place-id="${placeId}">
      <img src="${photo}" alt="${CONFIG.name} photo" loading="lazy" />
    </div>
  `;
}

function createPhotoCarousel(placeId, photos) {
  if (!photos || photos.length === 0) {
    return `
      <div class="place-photo-single" data-photos='["${CONFIG.defaultPhoto}"]' data-place-id="${placeId}">
        <img src="${CONFIG.defaultPhoto}" alt="${CONFIG.name} photo" loading="lazy" />
      </div>
    `;
  }
  
  if (photos.length === 1) {
    return `
      <div class="place-photo-single" data-photos='${JSON.stringify(photos)}' data-place-id="${placeId}">
        <img src="${photos[0]}" alt="${CONFIG.name} photo" loading="lazy" />
      </div>
    `;
  }
  
  let photosHTML = '';
  let dotsHTML = '';
  
  photos.forEach((photo, index) => {
    const positionClass = index === 0 ? 'center' : 
                         index === 1 ? 'right' : 'hidden';
    
    photosHTML += `
      <div class="carousel-photo ${positionClass}" data-index="${index}" data-photo="${photo}">
        <img src="${photo}" alt="${CONFIG.name} photo ${index + 1}" loading="lazy" />
      </div>
    `;
    
    dotsHTML += `
      <span class="dot ${index === 0 ? 'active' : ''}" data-index="${index}"></span>
    `;
  });
  
  return `
    <div class="photo-carousel" data-place-id="${placeId}" data-photos='${JSON.stringify(photos)}'>
      <div class="carousel-track">
        ${photosHTML}
      </div>
      <div class="carousel-dots">
        ${dotsHTML}
      </div>
    </div>
  `;
}

// Upgrade skeleton to full carousel when photos are discovered
function upgradeToCarousel(placeId, photos) {
  const card = document.querySelector(`.place-card[data-place-id="${placeId}"]`);
  if (!card) return;
  
  const imageContainer = card.querySelector('.place-card-image');
  if (!imageContainer) return;
  
  // Replace skeleton with actual carousel/photo
  imageContainer.innerHTML = createPhotoCarousel(placeId, photos);
  
  // Initialize carousel if multiple photos
  if (photos.length > 1) {
    initCarousel(placeId, photos.length);
  } else {
    // Single photo click handler
    const singlePhoto = imageContainer.querySelector('.place-photo-single');
    if (singlePhoto) {
      singlePhoto.addEventListener('click', (e) => {
        e.stopPropagation();
        const photoData = JSON.parse(singlePhoto.getAttribute('data-photos') || '[]');
        if (photoData.length > 0) {
          openImageModal(photoData, 0);
        }
      });
    }
  }
}

function initCarousel(placeId, photoCount) {
  const carousel = document.querySelector(`.photo-carousel[data-place-id="${placeId}"]`);
  if (!carousel || photoCount <= 1) {
    return;
  }
  
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
  
  // Click on center photo to open modal
  photos.forEach((photo) => {
    photo.addEventListener('click', (e) => {
      e.stopPropagation();
      if (photo.classList.contains('center')) {
        const photoIndex = parseInt(photo.getAttribute('data-index'));
        openImageModal(allPhotos, photoIndex);
      }
    });
  });
  
  // Click on dots to navigate
  dots.forEach((dot, index) => {
    dot.addEventListener('click', (e) => {
      e.stopPropagation();
      updateCarousel(index);
      
      if (carouselIntervals[placeId]) {
        clearInterval(carouselIntervals[placeId]);
      }
      startAutoRotation();
    });
  });
  
  function startAutoRotation() {
    carouselIntervals[placeId] = setInterval(() => {
      const nextIndex = (currentIndex + 1) % photos.length;
      updateCarousel(nextIndex);
    }, 3000);
  }
  
  startAutoRotation();
  
  carousel.addEventListener('mouseenter', () => {
    if (carouselIntervals[placeId]) {
      clearInterval(carouselIntervals[placeId]);
    }
  });
  
  carousel.addEventListener('mouseleave', () => {
    startAutoRotation();
  });
}

// ============================================
// LAZY LOADING WITH INTERSECTION OBSERVER
// ============================================

let lazyLoadObserver = null;
const loadedPlaces = new Set(); // Track which places have loaded photos

function setupLazyLoading() {
  // Clean up existing observer
  if (lazyLoadObserver) {
    lazyLoadObserver.disconnect();
  }
  
  lazyLoadObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const card = entry.target;
        const placeId = card.getAttribute('data-place-id');
        const photoPath = card.getAttribute('data-photo-path');
        
        // Only load once
        if (!loadedPlaces.has(placeId) && photoPath) {
          loadedPlaces.add(placeId);
          
          // Discover all photos for this place
          discoverPhotos(photoPath, 10).then(photos => {
            if (photos.length > 0) {
              upgradeToCarousel(placeId, photos);
            } else {
              upgradeToCarousel(placeId, [CONFIG.defaultPhoto]);
            }
          });
        }
        
        // Stop observing this card
        lazyLoadObserver.unobserve(card);
      }
    });
  }, {
    root: null,
    rootMargin: '100px', // Start loading 100px before card enters viewport
    threshold: 0.1
  });
}

// ============================================
// RENDERING (Optimized with I18N)
// ============================================

function generateStarRating(averageRating, reviewCount) {
  const noRatingText = window.I18N ? I18N.t('places.noRating') : 'Izoh qoldirilmagan';
  
  if (!reviewCount || reviewCount === 0) {
    return `<span class="no-rating-text">${noRatingText}</span>`;
  }
  
  const roundedRating = Math.round(averageRating);
  
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

async function renderPlaceCards(places) {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  
  // Clear previous carousels and observers
  Object.values(carouselIntervals).forEach(interval => clearInterval(interval));
  carouselIntervals = {};
  loadedPlaces.clear();
  
  placeCardsContainer.innerHTML = '';
  
  if (!places || places.length === 0) {
    loadingIndicator.style.display = 'none';
    noResults.style.display = 'block';
    placeCardsContainer.style.display = 'none';
    return;
  }
  
  noResults.style.display = 'none';
  placeCardsContainer.style.display = 'flex';
  
  // Setup lazy loading observer
  setupLazyLoading();
  
  // Translated texts
  const noInfoText = window.I18N ? I18N.t('places.noInfo') : 'Ma\'lumot yo\'q';
  const noAddressText = window.I18N ? I18N.t('places.noAddress') : 'Manzil ma\'lumoti yo\'q';
  
  // Render all cards immediately with skeletons
  for (const place of places) {
    const card = document.createElement('div');
    card.className = 'place-card';
    card.setAttribute('data-place-id', place.id);
    card.setAttribute('data-photo-path', place.photo || '');
    
    const starRatingHTML = generateStarRating(place.averageRating, place.reviewCount);
	const distanceDisplay = (place.distance !== null && place.distance !== undefined) ? place.distance.toFixed(2) : 'N/A';
    const phoneDisplay = place.phone || noInfoText;
    
    card.innerHTML = `
      <div class="card-top-badges">
        <div class="place-rating-badge">
          ${starRatingHTML}
        </div>
        <div class="place-distance-badge">
          <span>📍</span>
          <span>${distanceDisplay} km</span>
        </div>
      </div>
      
      <div class="place-card-image">
        ${createSkeletonCard(place.id)}
      </div>
      
      <div class="place-card-content">
        <h3 class="place-name">${place.name}</h3>
        <p class="place-name-ko">${place.city || 'Unknown City'}</p>
        <div class="place-info">
          <div class="place-info-item">
            <span class="info-icon">📞</span>
            <span class="info-text">${phoneDisplay}</span>
          </div>
          <div class="place-info-item">
            <span class="info-icon">📍</span>
            <span class="info-text">${place.address || noAddressText}</span>
          </div>
        </div>
      </div>
    `;
    
    // Add click handler to the card (works even while loading)
    card.addEventListener('click', (e) => {
      // Don't navigate if clicking on carousel photo (to open modal)
      if (e.target.closest('.carousel-photo') || e.target.closest('.place-photo-single')) {
        return;
      }
      saveSearchState();
      sessionStorage.setItem('comingFromDetail', 'true');
      window.location.href = `places-detail.html?type=${PLACE_TYPE}&id=${place.id}`;
    });
    
    placeCardsContainer.appendChild(card);
    
    // Observe this card for lazy loading
    lazyLoadObserver.observe(card);
  }
  
  currentPlaces = places;
  updatePageTitle();
  loadingIndicator.style.display = 'none';
}

function showError(message) {
  loadingIndicator.style.display = 'none';
  noResults.style.display = 'block';
  placeCardsContainer.style.display = 'none';
  searchPlaceholder.style.display = 'none';
  placesPageTitle.style.display = 'block';
  
  const noResultsText = document.querySelector('.no-results-text');
  const noResultsHint = document.querySelector('.no-results-hint');
  
  const errorTitle = window.I18N ? I18N.t('places.error') : 'Xatolik yuz berdi';
  if (noResultsText) noResultsText.textContent = errorTitle;
  if (noResultsHint) noResultsHint.textContent = message;
}

// ============================================
// EVENT HANDLERS
// ============================================

// Button 1: Search by Address - toggle input section
searchByAddressBtn.addEventListener('click', () => {
  const isOpen = addressInputSection.style.display !== 'none';
  addressInputSection.style.display = isOpen ? 'none' : 'block';
  if (!isOpen) {
    searchBar.focus();
  }
});

// Button 2: Search Nearby (current location)
searchNearbyBtn.addEventListener('click', async () => {
  // Hide placeholder and address input, show loading
  searchPlaceholder.style.display = 'none';
  addressInputSection.style.display = 'none';
  placesPageTitle.style.display = 'block';
  loadingIndicator.style.display = 'flex';
  placeCardsContainer.style.display = 'none';
  noResults.style.display = 'none';
  
  currentMode = 'location';
  currentSearchAddress = '';
  updatePageTitle();
  
  const location = LocationManager.getCurrentLocation();
  
  if (location && location.lat && location.lon) {
    try {
      const places = await fetchNearbyPlaces(location.lat, location.lon, 5);
      loadingIndicator.style.display = 'none';
      await renderPlaceCards(places);
      saveSearchState();
    } catch (error) {
      const loadErrorText = window.I18N ? I18N.t('places.loadError') : `${CONFIG.namePlural}ni yuklashda xatolik yuz berdi`;
      const timeoutErrorText = window.I18N ? I18N.t('places.timeoutError') : 'Server javob bermadi. Iltimos, qaytadan urinib ko\'ring.';
      
      let errorMessage = loadErrorText;
      if (error.name === 'TimeoutError') {
        errorMessage = timeoutErrorText;
      }
      showError(errorMessage);
    }
  } else {
    loadingIndicator.style.display = 'none';
    const locationErrorText = window.I18N ? I18N.t('places.locationError') : 'Joylashuv ma\'lumotlari topilmadi';
    showError(locationErrorText);
  }
});

// Search bar input handler
searchBar.addEventListener('input', (e) => {
  const value = e.target.value.trim();
  clearSearchBtn.style.display = value ? 'flex' : 'none';
});

// Search bar enter key
searchBar.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') {
    const address = searchBar.value.trim();
    if (address) performAddressSearch(address);
  }
});

// Search button click
searchBtn.addEventListener('click', () => {
  const address = searchBar.value.trim();
  if (address) performAddressSearch(address);
});

// Clear search button
clearSearchBtn.addEventListener('click', () => {
  searchBar.value = '';
  clearSearchBtn.style.display = 'none';
  searchBar.focus();
});

async function performAddressSearch(address) {
  currentMode = 'address';
  currentSearchAddress = address;
  
  // Hide placeholder, show loading
  searchPlaceholder.style.display = 'none';
  placesPageTitle.style.display = 'block';
  updatePageTitle();
  
  loadingIndicator.style.display = 'flex';
  placeCardsContainer.style.display = 'none';
  noResults.style.display = 'none';
  
  searchBar.blur();
  addressInputSection.style.display = 'none';
  
  try {
    const places = await fetchPlacesByAddress(address, 5);
    await renderPlaceCards(places);
    saveSearchState();
  } catch (error) {
    const addressErrorText = window.I18N ? I18N.t('places.addressError') : 'Manzil bo\'yicha qidirishda xatolik. Iltimos, boshqa manzilni sinab ko\'ring.';
    const timeoutErrorText = window.I18N ? I18N.t('places.timeoutError') : 'Server javob bermadi (30 soniya). Iltimos, bir oz kuting va qaytadan urinib ko\'ring.';
    
    let errorMessage = addressErrorText;
    if (error.name === 'TimeoutError') {
      errorMessage = timeoutErrorText;
    }
    
    showError(errorMessage);
  }
}

// ============================================
// LANGUAGE CHANGE LISTENER
// ============================================

window.addEventListener('languageChanged', () => {
  updateUIText();
  // Re-render if we have places
  if (currentPlaces.length > 0) {
    renderPlaceCards(currentPlaces);
  }
});

// ============================================
// INITIALIZATION
// ============================================

async function initializePlacesPage() {
  updateUIText();
  
  // Check if coming back from detail page using sessionStorage flag
  const comingFromDetail = sessionStorage.getItem('comingFromDetail') === 'true';
  
  // Clear the flag after reading
  sessionStorage.removeItem('comingFromDetail');
  
  // If NOT coming from detail page, clear state (fresh start)
  if (!comingFromDetail) {
    clearSearchState();
  }
  
  // Try to load saved state (only works if coming from detail page)
  const savedState = loadSearchState();
  
  if (savedState && savedState.places && savedState.places.length > 0) {
    // Restore previous search results
    currentMode = savedState.mode;
    currentSearchAddress = savedState.address;
    updatePageTitle();
    currentPlaces = savedState.places;
    
    // If it was address search, show the address in the input
    if (currentMode === 'address' && currentSearchAddress) {
      searchBar.value = currentSearchAddress;
      clearSearchBtn.style.display = 'flex';
    }
    
    // Hide placeholder, show title and results
    searchPlaceholder.style.display = 'none';
    placesPageTitle.style.display = 'block';
    await renderPlaceCards(savedState.places);
    return;
  }
  
  // No saved state - show placeholder, wait for user to choose
  searchPlaceholder.style.display = 'flex';
  placesPageTitle.style.display = 'none';
  loadingIndicator.style.display = 'none';
  placeCardsContainer.style.display = 'none';
  noResults.style.display = 'none';
}

createImageModal();
document.addEventListener('DOMContentLoaded', initializePlacesPage);
