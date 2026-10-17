// parcel.js - Parcel/Pochta page functionality

// ============================================
// TELEGRAM WEBAPP INITIALIZATION
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();

try {
  tg.disableVerticalSwipes();
} catch (e) {}

try {
  tg.expand();
} catch (e) {}

// ============================================
// STATE MANAGEMENT
// ============================================

let currentView = 'main'; // 'main', 'dates', 'citySelect', 'cities', 'posts'
let currentCountry = null; // 'uzb' or 'kor'
let navigationHistory = [];

// ============================================
// DOM ELEMENTS
// ============================================

// Sections
const searchMethods = document.getElementById('searchMethods');
const datesSection = document.getElementById('datesSection');

const citiesSection = document.getElementById('citiesSection');
const postsSection = document.getElementById('postsSection');

// Lists
const datesList = document.getElementById('datesList');
const citiesList = document.getElementById('citiesList');
const postsList = document.getElementById('postsList');

// Loading & Empty States
const datesLoading = document.getElementById('datesLoading');
const datesEmpty = document.getElementById('datesEmpty');
const citiesLoading = document.getElementById('citiesLoading');
const citiesEmpty = document.getElementById('citiesEmpty');
const postsLoading = document.getElementById('postsLoading');
const postsEmpty = document.getElementById('postsEmpty');

// Headings
const citiesHeading = document.getElementById('citiesHeading');
const postsHeading = document.getElementById('postsHeading');

// Buttons
const searchByDateBtn = document.getElementById('searchByDateBtn');
const searchByCityBtn = document.getElementById('searchByCityBtn');
const datesBackBtn = document.getElementById('datesBackBtn');

const citiesBackBtn = document.getElementById('citiesBackBtn');
const postsBackBtn = document.getElementById('postsBackBtn');


// ============================================
// VIEW MANAGEMENT
// ============================================

function showView(viewName) {
  // Hide all sections
  searchMethods.style.display = 'none';
  datesSection.style.display = 'none';
  
  citiesSection.style.display = 'none';
  postsSection.style.display = 'none';
  
  // Show requested section
  switch(viewName) {
    case 'main':
      searchMethods.style.display = 'block';
      break;
    case 'dates':
      datesSection.style.display = 'block';
      break;
    case 'cities':
      citiesSection.style.display = 'block';
      break;
    case 'posts':
      postsSection.style.display = 'block';
      break;
  }
  
  currentView = viewName;
  window.scrollTo(0, 0);
}

function navigateTo(viewName) {
  navigationHistory.push(currentView);
  showView(viewName);
}

function navigateBack() {
  if (navigationHistory.length > 0) {
    const previousView = navigationHistory.pop();
    showView(previousView);
  } else {
    showView('main');
  }
}

// ============================================
// API FUNCTIONS
// ============================================

async function fetchDates() {
  try {
    const response = await fetch(`${API_CONFIG.BASE_URL}/api/parcels/dates`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    const data = await response.json();
    
    if (data.success) {
      return data.dates;
    } else {
      throw new Error(data.error || 'Failed to fetch dates');
    }
  } catch (error) {
    console.error('Error fetching dates:', error);
    throw error;
  }
}

async function fetchPostsByDate(date) {
  try {
    const response = await fetch(`${API_CONFIG.BASE_URL}/api/parcels/by-date?date=${encodeURIComponent(date)}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    const data = await response.json();
    
    if (data.success) {
      return data.posts;
    } else {
      throw new Error(data.error || 'Failed to fetch posts');
    }
  } catch (error) {
    console.error('Error fetching posts by date:', error);
    throw error;
  }
}

async function fetchCities(country) {
  try {
    const response = await fetch(`${API_CONFIG.BASE_URL}/api/parcels/cities?country=${country}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    const data = await response.json();
    
    if (data.success) {
      return data.cities;
    } else {
      throw new Error(data.error || 'Failed to fetch cities');
    }
  } catch (error) {
    console.error('Error fetching cities:', error);
    throw error;
  }
}

async function fetchPostsByCity(city, country) {
  try {
    const response = await fetch(`${API_CONFIG.BASE_URL}/api/parcels/by-city?city=${encodeURIComponent(city)}&country=${country}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(API_CONFIG.DEFAULTS.TIMEOUT)
    });
    
    const data = await response.json();
    
    if (data.success) {
      return data.posts;
    } else {
      throw new Error(data.error || 'Failed to fetch posts');
    }
  } catch (error) {
    console.error('Error fetching posts by city:', error);
    throw error;
  }
}

// ============================================
// RENDER FUNCTIONS
// ============================================

function renderDates(dates) {
  datesList.innerHTML = '';
  
  if (!dates || dates.length === 0) {
    datesEmpty.style.display = 'flex';
    return;
  }
  
  datesEmpty.style.display = 'none';
  
  dates.forEach((dateInfo, index) => {
    const dateItem = document.createElement('div');
    dateItem.className = 'date-item';
    dateItem.style.animationDelay = `${index * 0.05}s`;
    
    // Parse date for display
    const parts = dateInfo.date_formatted.split('.');
    const day = parts[0];
    const monthNames = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
    const month = monthNames[parseInt(parts[1]) - 1] || parts[1];
    
    dateItem.innerHTML = `
      <div class="date-icon">
        <span class="date-day">${day}</span>
        <span class="date-month">${month}</span>
      </div>
      <div class="date-info">
        <span class="date-full">${dateInfo.date_uzbek}</span>
        <span class="date-weekday">${dateInfo.weekday}</span>
      </div>
      <span class="date-count">${dateInfo.count} ta e'lon</span>
    `;
    
    dateItem.addEventListener('click', () => {
      loadPostsByDate(dateInfo.date_formatted, dateInfo.date_uzbek);
    });
    
    datesList.appendChild(dateItem);
  });
}

function renderCities(cities, country) {
  citiesList.innerHTML = '';
  
  if (!cities || cities.length === 0) {
    citiesEmpty.style.display = 'flex';
    return;
  }
  
  citiesEmpty.style.display = 'none';
  
  const flag = country === 'uzb' ? '🇺🇿' : '🇰🇷';
  
  cities.forEach((cityInfo, index) => {
    const cityItem = document.createElement('div');
    cityItem.className = 'city-item';
    cityItem.style.animationDelay = `${index * 0.03}s`;
    
    cityItem.innerHTML = `
      <div class="city-icon">${flag}</div>
      <span class="city-name">${cityInfo.city}</span>
      <span class="city-count">${cityInfo.count} ta e'lon</span>
    `;
    
    cityItem.addEventListener('click', () => {
      loadPostsByCity(cityInfo.city, country);
    });
    
    citiesList.appendChild(cityItem);
  });
}

function renderPosts(posts, title) {
  postsList.innerHTML = '';
  postsHeading.textContent = `📋 ${title}`;
  
  if (!posts || posts.length === 0) {
    postsEmpty.style.display = 'flex';
    return;
  }
  
  postsEmpty.style.display = 'none';
  
  posts.forEach((post, index) => {
    const postCard = document.createElement('div');
    postCard.className = 'post-card';
    postCard.style.animationDelay = `${index * 0.1}s`;
    
    // Determine contact link
    let contactLink = '';
    let contactText = '';
    
    if (post.username) {
      const cleanUsername = post.username.replace('@', '');
      contactLink = `https://t.me/${cleanUsername}`;
      contactText = `@${cleanUsername}`;
    } else {
      contactLink = `tg://user?id=${post.telegram_id}`;
      contactText = 'Telegram orqali bog\'lanish';
    }
    
   
    // Clean and escape message text
    const cleanText = escapeHtml(post.message_text || '').replace(/\u00a0/g, ' ');
    
    // Build contact button - only show if username exists
    const contactBtnHTML = post.username ? `
      <div class="post-footer">
        <a href="${contactLink}" target="_blank" class="contact-btn">
          <span class="btn-icon">✈️</span>
          <span>Telegram orqali bog'lanish</span>
        </a>
      </div>
    ` : '';

    postCard.innerHTML = `
      <div class="post-header">
        <div class="post-avatar">✈️</div>
        <div class="post-user-info">
          <span class="post-username">${post.username ? '@' + post.username.replace('@', '') : 'Kuryer kontakti xabarda ko\'rsatilgan'}</span>
          <span class="post-date">📅 ${post.flight_time || ''}</span>
        </div>
      </div>
      <div class="post-body">
        <p class="post-text">${cleanText}</p>
      </div>
      ${contactBtnHTML}
    `;
    
    postsList.appendChild(postCard);
  });
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// ============================================
// LOAD FUNCTIONS
// ============================================

async function loadDates() {
  navigateTo('dates');
  
  datesList.innerHTML = '';
  datesLoading.style.display = 'flex';
  datesEmpty.style.display = 'none';
  
  try {
    const dates = await fetchDates();
    datesLoading.style.display = 'none';
    renderDates(dates);
  } catch (error) {
    datesLoading.style.display = 'none';
    datesEmpty.style.display = 'flex';
    datesEmpty.querySelector('p').textContent = 'Xatolik yuz berdi. Qaytadan urinib ko\'ring.';
  }
}

async function loadPostsByDate(date, dateLabel) {
  navigateTo('posts');
  
  postsList.innerHTML = '';
  postsLoading.style.display = 'flex';
  postsEmpty.style.display = 'none';
  postsHeading.textContent = `📋 ${dateLabel}`;
  
  try {
    const posts = await fetchPostsByDate(date);
    postsLoading.style.display = 'none';
    renderPosts(posts, dateLabel);
  } catch (error) {
    postsLoading.style.display = 'none';
    postsEmpty.style.display = 'flex';
    postsEmpty.querySelector('p').textContent = 'Xatolik yuz berdi. Qaytadan urinib ko\'ring.';
  }
}

async function loadCities(country) {
  currentCountry = country;
  navigateTo('cities');
  
  const countryLabel = country === 'uzb' ? '🇺🇿 O\'zbekiston' : '🇰🇷 Koreya';
  citiesHeading.textContent = `${countryLabel} shaharlari`;
  
  citiesList.innerHTML = '';
  citiesLoading.style.display = 'flex';
  citiesEmpty.style.display = 'none';
  
  try {
    const cities = await fetchCities(country);
    citiesLoading.style.display = 'none';
    renderCities(cities, country);
  } catch (error) {
    citiesLoading.style.display = 'none';
    citiesEmpty.style.display = 'flex';
    citiesEmpty.querySelector('p').textContent = 'Xatolik yuz berdi. Qaytadan urinib ko\'ring.';
  }
}

async function loadCitiesWithTabs(country, isTabSwitch = false) {
  // Only add to navigation history if not switching tabs
  if (!isTabSwitch) {
    navigateTo('cities');
  }
  
  // Update tab states
  const tabUzb = document.getElementById('tabUzb');
  const tabKor = document.getElementById('tabKor');
  
  tabUzb.classList.toggle('active', country === 'uzb');
  tabKor.classList.toggle('active', country === 'kor');
  
  currentCountry = country;
  
  citiesList.innerHTML = '';
  citiesLoading.style.display = 'flex';
  citiesEmpty.style.display = 'none';
  
  try {
    const cities = await fetchCities(country);
    citiesLoading.style.display = 'none';
    renderCities(cities, country);
  } catch (error) {
    citiesLoading.style.display = 'none';
    citiesEmpty.style.display = 'flex';
    citiesEmpty.querySelector('p').textContent = 'Xatolik yuz berdi. Qaytadan urinib ko\'ring.';
  }
}


async function loadPostsByCity(city, country) {
  navigateTo('posts');
  
  postsList.innerHTML = '';
  postsLoading.style.display = 'flex';
  postsEmpty.style.display = 'none';
  
  const flag = country === 'uzb' ? '🇺🇿' : '🇰🇷';
  postsHeading.textContent = `📋 ${flag} ${city}`;
  
  try {
    const posts = await fetchPostsByCity(city, country);
    postsLoading.style.display = 'none';
    renderPosts(posts, `${flag} ${city}`);
  } catch (error) {
    postsLoading.style.display = 'none';
    postsEmpty.style.display = 'flex';
    postsEmpty.querySelector('p').textContent = 'Xatolik yuz berdi. Qaytadan urinib ko\'ring.';
  }
}

// ============================================
// EVENT LISTENERS
// ============================================

// Main buttons
searchByDateBtn.addEventListener('click', loadDates);
searchByCityBtn.addEventListener('click', () => {
  currentCountry = 'uzb'; // Default to Uzbekistan
  loadCitiesWithTabs('uzb');
});



// Back buttons
datesBackBtn.addEventListener('click', navigateBack);
citiesBackBtn.addEventListener('click', navigateBack);
postsBackBtn.addEventListener('click', navigateBack);


// Country tabs (isTabSwitch = true to prevent adding to navigation history)
document.getElementById('tabUzb').addEventListener('click', () => loadCitiesWithTabs('uzb', true));
document.getElementById('tabKor').addEventListener('click', () => loadCitiesWithTabs('kor', true));
// ============================================
// TELEGRAM BACK BUTTON
// ============================================

function handleTelegramBackButton() {
  if (currentView === 'main') {
    window.location.href = '../../index.html';
  } else {
    navigateBack();
  }
}

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(handleTelegramBackButton);
  }
} catch (e) {}

// ============================================
// HAPTIC FEEDBACK
// ============================================

function addHapticToButtons() {
  const buttons = document.querySelectorAll('button, .date-item, .city-item, .contact-btn');
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      try {
        if (tg.HapticFeedback) {
          tg.HapticFeedback.impactOccurred('light');
        }
      } catch (e) {}
    });
  });
}

// ============================================
// INITIALIZATION
// ============================================

function initParcelPage() {
  showView('main');
  addHapticToButtons();
  console.log('✅ Parcel page loaded');
}

document.addEventListener('DOMContentLoaded', initParcelPage);