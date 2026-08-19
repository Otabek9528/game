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

// ============================================
// INLINE SVG ICONS (UI chrome — replaces emoji)
// ============================================

const PL_ICONS = {
  star: '<svg class="pl-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2.5l2.83 6.1 6.67.77-4.94 4.56 1.32 6.57L12 17.2l-5.88 3.3 1.32-6.57L2.5 9.37l6.67-.77z"/></svg>',
  pin: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>',
  phone: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.13.96.36 1.9.7 2.8a2 2 0 0 1-.45 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.25a2 2 0 0 1 2.1-.45c.9.34 1.84.57 2.8.7A2 2 0 0 1 22 16.9z"/></svg>',
  image: '<svg class="pl-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="4" width="18" height="16" rx="2.5"/><circle cx="9" cy="10" r="1.8"/><path d="m21 16-4.5-4.5L7 21"/></svg>'
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
let carouselResume = {};   // placeId -> restart fn, for pause/resume

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
// IMAGE VIEWER  (shared module — see photo-viewer.js)
// ============================================
// The old createImageModal() block lived here. PhotoViewer builds and
// owns its own DOM, so createImageModal() is now a no-op kept only so
// the existing bootstrap call at the bottom of this file stays valid.

PhotoViewer.configure({
  onOpen: function () {
    pauseAllCarousels();
    if (tg.BackButton) {
      tg.BackButton.offClick(handleMainBackButton);
      tg.BackButton.onClick(handleModalBackButton);
    }
  },
  onClose: function () {
    resumeAllCarousels();
    if (tg.BackButton) {
      tg.BackButton.offClick(handleModalBackButton);
      tg.BackButton.onClick(handleMainBackButton);
    }
  }
});

function createImageModal() { /* no-op — PhotoViewer self-initialises */ }

function openImageModal(photos, startIndex = 0) {
  PhotoViewer.open(photos, startIndex);
}

function closeImageModal() {
  PhotoViewer.close();
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
  const extensions = ['jpg', 'jpeg', 'png'];
  const basePath = `../../${photoPath}`;

  // Finding photos costs round trips, not bytes: every miss is a 404 we wait
  // on. Asking for one extension of one index at a time meant a card with
  // three photos spent a dozen serial requests before showing anything. A
  // batch asks for every extension of every index at once, so the usual card
  // resolves in a single round trip.
  const BATCH = 5;
  const found = [];

  for (let start = 1; start <= maxPhotos; start += BATCH) {
    const indices = [];
    for (let i = start; i < start + BATCH && i <= maxPhotos; i++) indices.push(i);

    const hits = await Promise.all(indices.map(async (i) => {
      const perExt = await Promise.all(extensions.map(async (ext) => {
        const url = `${basePath}/${i}.${ext}`;
        try {
          return (await checkImageExists(url)) ? url : null;
        } catch (e) {
          return null;
        }
      }));
      // Extension order is the preference order, so keep the first hit.
      return perExt.find(Boolean) || null;
    }));

    // Numbering has to stay contiguous from 1: stop at the first gap even if
    // later indices exist, otherwise a stray 7.jpg would appear as photo 2.
    let gap = false;
    for (const hit of hits) {
      if (!hit) { gap = true; break; }
      found.push(hit);
    }
    if (gap) break;
  }

  return found;
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
        <span class="skeleton-icon">${PL_ICONS.image}</span>
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
  
  // Centre photo opens the viewer; the side peeks navigate.
  // Anything else is left to bubble so the card link still works.
  photos.forEach((photo) => {
    photo.addEventListener('click', (e) => {
      if (photo.classList.contains('center')) {
        e.stopPropagation();
        openImageModal(allPhotos, currentIndex);
      } else if (photo.classList.contains('right')) {
        e.stopPropagation();
        nudge(currentIndex + 1);
      } else if (photo.classList.contains('left')) {
        e.stopPropagation();
        nudge(currentIndex - 1 + photos.length);
      }
    });
  });
  
  // Any deliberate navigation moves the carousel and restarts the clock,
  // so the timer never overrides the user mid-look.
  function nudge(index) {
    updateCarousel(index % photos.length);
    stopAutoRotation();
    startAutoRotation();
  }

  dots.forEach((dot, index) => {
    dot.addEventListener('click', (e) => {
      e.stopPropagation();
      nudge(index);
    });
  });

  if (window.SwipeNav) {
    SwipeNav.attach(carousel, {
      onNext: () => nudge(currentIndex + 1),
      onPrev: () => nudge(currentIndex - 1 + photos.length)
    });
  }

  function stopAutoRotation() {
    if (carouselIntervals[placeId]) {
      clearInterval(carouselIntervals[placeId]);
      delete carouselIntervals[placeId];
    }
  }

  function startAutoRotation() {
    stopAutoRotation();   // never stack two timers on one card
    carouselIntervals[placeId] = setInterval(() => {
      updateCarousel((currentIndex + 1) % photos.length);
    }, 3000);
  }

  carouselResume[placeId] = startAutoRotation;
  startAutoRotation();

  carousel.addEventListener('mouseenter', stopAutoRotation);
  carousel.addEventListener('mouseleave', startAutoRotation);
}

// Cards keep rotating behind the fullscreen viewer otherwise, so you close
// it and the carousel has drifted somewhere else.
function pauseAllCarousels() {
  Object.keys(carouselIntervals).forEach((id) => {
    clearInterval(carouselIntervals[id]);
    delete carouselIntervals[id];
  });
}

function resumeAllCarousels() {
  Object.keys(carouselResume).forEach((id) => {
    try { carouselResume[id](); } catch (e) {}
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
    // Probing starts well before the card is on screen, so the photos are
    // usually there by the time it is — 100px was about a third of a card.
    rootMargin: '600px',
    threshold: 0.1
  });
}

// ============================================
// RENDERING (Optimized with I18N)
// ============================================

function renderStars(rating) {
  const rounded = Math.round(Number(rating || 0));
  let starsHTML = '';
  for (let i = 1; i <= 5; i++) {
    starsHTML += `<span class="${i <= rounded ? 'star-on' : 'star-off'}">${PL_ICONS.star}</span>`;
  }
  return `<span class="stars">${starsHTML}</span>`;
}

function generateStarRating(averageRating, reviewCount) {
  const noRatingText = window.I18N ? I18N.t('places.noRating') : 'Izoh qoldirilmagan';
  
  if (!reviewCount || reviewCount === 0) {
    return `<span class="chip-muted">${noRatingText}</span>`;
  }
  
  return `${renderStars(averageRating)}<span class="chip-count">(${reviewCount})</span>`;
}

async function renderPlaceCards(places) {
  CONFIG = getTranslatedConfig(PLACE_TYPE);
  
  // Clear previous carousels and observers
  Object.values(carouselIntervals).forEach(interval => clearInterval(interval));
  carouselIntervals = {};
  carouselResume = {};
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
      <div class="place-card-image">
        ${createSkeletonCard(place.id)}
      </div>
      
      <div class="media-chips">
        <div class="chip chip-rating">
          ${starRatingHTML}
        </div>
        <div class="chip chip-distance">
          ${PL_ICONS.pin}
          <span>${distanceDisplay} km</span>
        </div>
      </div>
      
      <div class="place-card-content">
        <h3 class="place-name">${place.name}</h3>
        <p class="place-name-ko">${place.city || 'Unknown City'}</p>
        <div class="place-info">
          <div class="place-info-item">
            <span class="info-icon">${PL_ICONS.phone}</span>
            <span class="info-text">${phoneDisplay}</span>
          </div>
          <div class="place-info-item">
            <span class="info-icon">${PL_ICONS.pin}</span>
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

// Reflect the chosen search mode on the segmented switch
function setActiveMode(mode) {
  if (searchNearbyBtn) searchNearbyBtn.classList.toggle('is-active', mode === 'location');
  if (searchByAddressBtn) searchByAddressBtn.classList.toggle('is-active', mode === 'address');
}

// Button 1: Search by Address - toggle input section
searchByAddressBtn.addEventListener('click', () => {
  const isOpen = addressInputSection.style.display !== 'none';
  addressInputSection.style.display = isOpen ? 'none' : 'block';
  if (!isOpen) {
    setActiveMode('address');
    searchBar.focus();
  } else {
    setActiveMode(currentMode === 'address' ? 'address' : currentMode === 'location' && currentPlaces.length > 0 ? 'location' : null);
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
  setActiveMode('location');
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
  setActiveMode('address');
  
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
    setActiveMode(currentMode);
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
