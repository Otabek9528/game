/**
 * RAMADAN 2026 - Muslim Vegukin Bot WebApp
 * Premium Islamic Calendar & Prayer Times
 */

// ===========================================
// CONFIGURATION
// ===========================================

const CONFIG = {
  // Ramadan 2026 starts on February 28, 2026 (estimated)
  RAMADAN_START: new Date(2026, 1, 28), // Month is 0-indexed
  RAMADAN_DAYS: 30,
  
  // Aladhan API settings
  API_BASE: 'https://api.aladhan.com/v1',
  METHOD: 3, // Muslim World League
  SCHOOL: 1, // Hanafi
  
  // Timezone
  TIMEZONE: 'Asia/Seoul',
  
  // Month names in Uzbek
  MONTHS_UZ: {
    0: 'Yanvar', 1: 'Fevral', 2: 'Mart', 3: 'Aprel',
    4: 'May', 5: 'Iyun', 6: 'Iyul', 7: 'Avgust',
    8: 'Sentabr', 9: 'Oktabr', 10: 'Noyabr', 11: 'Dekabr'
  },
  
  // Weekday names in Uzbek
  WEEKDAYS_UZ: ['Yakshanba', 'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba']
};

// ===========================================
// STATE MANAGEMENT
// ===========================================

const State = {
  location: null,
  cityName: 'Noma\'lum',
  currentView: 'main',
  prayerCache: new Map(),
  monthlyData: null
};

// ===========================================
// TELEGRAM WEBAPP INITIALIZATION
// ===========================================

const tg = window.Telegram?.WebApp;

function initTelegram() {
  if (!tg) return;
  
  tg.ready();
  tg.expand();
  
  try {
    tg.disableVerticalSwipes();
  } catch (e) {}
  
  // Setup back button
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      if (State.currentView !== 'main') {
        closeDetailView();
      } else {
        window.location.href = '../../index.html';
      }
    });
  }
}

// ===========================================
// UTILITY FUNCTIONS
// ===========================================

function formatDate(date, format = 'full') {
  const day = date.getDate();
  const month = CONFIG.MONTHS_UZ[date.getMonth()];
  const year = date.getFullYear();
  const weekday = CONFIG.WEEKDAYS_UZ[date.getDay()];
  
  switch (format) {
    case 'short':
      return `${day}-${month}`;
    case 'full':
      return `${day}-${month}, ${year}`;
    case 'withWeekday':
      return `${weekday}, ${day}-${month}`;
    default:
      return `${day}-${month}`;
  }
}

function calculateRamadanDay(date) {
  const diffTime = date.getTime() - CONFIG.RAMADAN_START.getTime();
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  return diffDays + 1;
}

function isRamadan(date = new Date()) {
  const ramadanDay = calculateRamadanDay(date);
  return ramadanDay >= 1 && ramadanDay <= CONFIG.RAMADAN_DAYS;
}

function getTimeUntilRamadan() {
  const now = new Date();
  const diff = CONFIG.RAMADAN_START.getTime() - now.getTime();
  
  if (diff <= 0) return null;
  
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  
  return { days, hours, minutes };
}

function getTimeUntilIftar(iftarTime) {
  const now = new Date();
  const [hours, minutes] = iftarTime.split(':').map(Number);
  
  const iftar = new Date(now);
  iftar.setHours(hours, minutes, 0, 0);
  
  const diff = iftar.getTime() - now.getTime();
  
  if (diff <= 0) return null;
  
  const h = Math.floor(diff / (1000 * 60 * 60));
  const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const s = Math.floor((diff % (1000 * 60)) / 1000);
  
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

function hapticFeedback(type = 'light') {
  try {
    if (tg?.HapticFeedback) {
      tg.HapticFeedback.impactOccurred(type);
    }
  } catch (e) {}
}

// ===========================================
// LOCATION SERVICES
// ===========================================

async function getStoredLocation() {
  try {
    const stored = localStorage.getItem('ramadan_location');
    if (stored) {
      const data = JSON.parse(stored);
      // Check if location is less than 24 hours old
      if (Date.now() - data.timestamp < 24 * 60 * 60 * 1000) {
        return data;
      }
    }
  } catch (e) {}
  return null;
}

function storeLocation(lat, lon, cityName) {
  try {
    localStorage.setItem('ramadan_location', JSON.stringify({
      lat, lon, cityName,
      timestamp: Date.now()
    }));
  } catch (e) {}
}

async function requestLocation() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation not supported'));
      return;
    }
    
    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          lat: position.coords.latitude,
          lon: position.coords.longitude
        });
      },
      (error) => {
        reject(error);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000
      }
    );
  });
}

async function getCityName(lat, lon) {
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`,
      { headers: { 'Accept-Language': 'en' } }
    );
    
    if (!response.ok) throw new Error('City lookup failed');
    
    const data = await response.json();
    return data.address?.city || 
           data.address?.town || 
           data.address?.county || 
           'Noma\'lum';
  } catch (e) {
    console.error('City name error:', e);
    return 'Noma\'lum';
  }
}

// ===========================================
// PRAYER TIMES API
// ===========================================

async function fetchPrayerTimes(lat, lon, date = new Date()) {
  const dateStr = `${date.getDate()}-${date.getMonth() + 1}-${date.getFullYear()}`;
  const cacheKey = `${lat.toFixed(4)}_${lon.toFixed(4)}_${dateStr}`;
  
  // Check cache
  if (State.prayerCache.has(cacheKey)) {
    return State.prayerCache.get(cacheKey);
  }
  
  try {
    const url = `${CONFIG.API_BASE}/timings/${dateStr}?latitude=${lat}&longitude=${lon}&method=${CONFIG.METHOD}&school=${CONFIG.SCHOOL}`;
    
    const response = await fetch(url);
    if (!response.ok) throw new Error('API request failed');
    
    const data = await response.json();
    const timings = data.data.timings;
    
    const result = {
      suhur: timings.Fajr.slice(0, 5),
      iftar: timings.Maghrib.slice(0, 5),
      sunrise: timings.Sunrise.slice(0, 5),
      dhuhr: timings.Dhuhr.slice(0, 5),
      asr: timings.Asr.slice(0, 5),
      isha: timings.Isha.slice(0, 5)
    };
    
    // Cache result
    State.prayerCache.set(cacheKey, result);
    
    return result;
  } catch (e) {
    console.error('Prayer times error:', e);
    return null;
  }
}

async function fetchMonthlyPrayerTimes(lat, lon) {
  if (State.monthlyData) return State.monthlyData;
  
  const data = [];
  
  for (let i = 0; i < CONFIG.RAMADAN_DAYS; i++) {
    const date = new Date(CONFIG.RAMADAN_START);
    date.setDate(date.getDate() + i);
    
    const times = await fetchPrayerTimes(lat, lon, date);
    
    if (times) {
      data.push({
        day: i + 1,
        date: new Date(date),
        gregorian: formatDate(date, 'short'),
        suhur: times.suhur,
        iftar: times.iftar,
        isFriday: date.getDay() === 5,
        isToday: isSameDay(date, new Date())
      });
    }
    
    // Small delay to avoid rate limiting
    if (i < CONFIG.RAMADAN_DAYS - 1) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  
  State.monthlyData = data;
  return data;
}

function isSameDay(d1, d2) {
  return d1.getDate() === d2.getDate() &&
         d1.getMonth() === d2.getMonth() &&
         d1.getFullYear() === d2.getFullYear();
}

// ===========================================
// UI FUNCTIONS
// ===========================================

function showLoading() {
  document.getElementById('loadingOverlay').classList.add('active');
}

function hideLoading() {
  document.getElementById('loadingOverlay').classList.remove('active');
}

function showLocationModal() {
  document.getElementById('locationModal').classList.add('active');
}

function hideLocationModal() {
  document.getElementById('locationModal').classList.remove('active');
}

function updateHeroSection() {
  const now = new Date();
  
  if (isRamadan(now)) {
    // During Ramadan - show day badge
    const dayNum = calculateRamadanDay(now);
    
    document.getElementById('heroTitle').textContent = 'Ramazon Muborak';
    document.getElementById('heroSubtitle').textContent = 'Muqaddas oy davom etmoqda';
    document.getElementById('countdown').style.display = 'none';
    
    const badge = document.getElementById('ramadanDayBadge');
    badge.style.display = 'inline-flex';
    document.getElementById('ramadanDayNumber').textContent = dayNum;
    
    // Show today section
    document.getElementById('todaySection').style.display = 'block';
    updateTodaySection();
  } else {
    // Before Ramadan - show countdown
    const timeLeft = getTimeUntilRamadan();
    
    if (timeLeft) {
      document.getElementById('countdownDays').textContent = String(timeLeft.days).padStart(2, '0');
      document.getElementById('countdownHours').textContent = String(timeLeft.hours).padStart(2, '0');
      document.getElementById('countdownMinutes').textContent = String(timeLeft.minutes).padStart(2, '0');
      
      document.getElementById('heroTitle').textContent = 'Ramazon 2026';
      document.getElementById('heroSubtitle').textContent = 'Muqaddas oy boshlanishiga';
    }
    
    document.getElementById('todaySection').style.display = 'none';
    document.getElementById('ramadanDayBadge').style.display = 'none';
  }
}

async function updateTodaySection() {
  if (!State.location) return;
  
  const now = new Date();
  const times = await fetchPrayerTimes(State.location.lat, State.location.lon, now);
  
  if (!times) return;
  
  document.getElementById('todayDate').textContent = formatDate(now, 'withWeekday');
  document.getElementById('cityName').textContent = State.cityName;
  document.getElementById('suhurTime').textContent = times.suhur;
  document.getElementById('iftarTime').textContent = times.iftar;
  
  // Update iftar countdown
  updateIftarCountdown(times.iftar);
}

function updateIftarCountdown(iftarTime) {
  const countdown = getTimeUntilIftar(iftarTime);
  const element = document.getElementById('iftarCountdown');
  const container = document.getElementById('countdownIftar');
  
  if (countdown) {
    element.textContent = countdown;
    container.style.display = 'flex';
  } else {
    container.style.display = 'none';
  }
}

function updateCityDisplays() {
  const elements = [
    'cityName', 'detailCity', 'calendarCityName'
  ];
  
  elements.forEach(id => {
    const el = document.getElementById(id);
    if (el) el.textContent = State.cityName;
  });
}

// ===========================================
// DETAIL VIEWS
// ===========================================

function openDetailView(viewId) {
  const view = document.getElementById(viewId);
  if (!view) return;
  
  view.classList.add('active');
  State.currentView = viewId;
  hapticFeedback('light');
  
  // Update Telegram back button
  if (tg?.BackButton) {
    tg.BackButton.show();
  }
}

function closeDetailView() {
  const views = ['detailView', 'calendarView', 'duasView'];
  views.forEach(id => {
    document.getElementById(id)?.classList.remove('active');
  });
  
  State.currentView = 'main';
  hapticFeedback('light');
}

async function showTodayTomorrow(type = 'today') {
  if (!State.location) {
    showLocationModal();
    return;
  }
  
  showLoading();
  
  const date = new Date();
  if (type === 'tomorrow') {
    date.setDate(date.getDate() + 1);
  }
  
  const times = await fetchPrayerTimes(State.location.lat, State.location.lon, date);
  
  hideLoading();
  
  if (!times) {
    alert('Namoz vaqtlarini olishda xatolik yuz berdi');
    return;
  }
  
  // Update detail view
  const title = type === 'today' ? 'Bugungi taqvim' : 'Ertangi taqvim';
  document.getElementById('detailTitle').textContent = title;
  
  document.getElementById('detailGregorian').textContent = formatDate(date, 'full');
  
  const ramadanDay = calculateRamadanDay(date);
  if (ramadanDay >= 1 && ramadanDay <= CONFIG.RAMADAN_DAYS) {
    document.getElementById('detailRamadan').textContent = `Ramazonning ${ramadanDay}-kuni`;
  } else {
    document.getElementById('detailRamadan').textContent = '';
  }
  
  document.getElementById('detailCity').textContent = State.cityName;
  document.getElementById('detailSuhur').textContent = times.suhur;
  document.getElementById('detailIftar').textContent = times.iftar;
  
  openDetailView('detailView');
}

async function showCalendar() {
  if (!State.location) {
    showLocationModal();
    return;
  }
  
  showLoading();
  
  const data = await fetchMonthlyPrayerTimes(State.location.lat, State.location.lon);
  
  hideLoading();
  
  if (!data || data.length === 0) {
    alert('Taqvimni yuklashda xatolik yuz berdi');
    return;
  }
  
  // Render calendar table
  const tbody = document.getElementById('calendarBody');
  tbody.innerHTML = '';
  
  data.forEach(day => {
    const tr = document.createElement('tr');
    
    if (day.isFriday) tr.classList.add('friday');
    if (day.isToday) tr.classList.add('today');
    
    tr.innerHTML = `
      <td>${day.day}</td>
      <td>${day.gregorian}</td>
      <td>${day.suhur}</td>
      <td>${day.iftar}</td>
    `;
    
    tbody.appendChild(tr);
  });
  
  openDetailView('calendarView');
}

function showDuas() {
  openDetailView('duasView');
}

// ===========================================
// EVENT HANDLERS
// ===========================================

function setupEventListeners() {
  // Back button in header
  document.getElementById('backBtn')?.addEventListener('click', (e) => {
    e.preventDefault();
    if (State.currentView !== 'main') {
      closeDetailView();
    } else {
      window.location.href = '../../index.html';
    }
  });
  
  // Menu buttons
  document.getElementById('btnToday')?.addEventListener('click', () => {
    hapticFeedback();
    showTodayTomorrow('today');
  });
  
  document.getElementById('btnTomorrow')?.addEventListener('click', () => {
    hapticFeedback();
    showTodayTomorrow('tomorrow');
  });
  
  document.getElementById('btnCalendar')?.addEventListener('click', () => {
    hapticFeedback();
    showCalendar();
  });
  
  document.getElementById('btnDuas')?.addEventListener('click', () => {
    hapticFeedback();
    showDuas();
  });
  
  // Info link
  document.getElementById('infoLink')?.addEventListener('click', (e) => {
    e.preventDefault();
    hapticFeedback();
    // Could open an info modal or external link
    alert('Turli taqvimlardagi farqlar haqida ma\'lumot tez orada qo\'shiladi');
  });
  
  // Detail view back buttons
  document.getElementById('detailBack')?.addEventListener('click', closeDetailView);
  document.getElementById('calendarBack')?.addEventListener('click', closeDetailView);
  document.getElementById('duasBack')?.addEventListener('click', closeDetailView);
  
  // Location modal
  document.getElementById('requestLocationBtn')?.addEventListener('click', async () => {
    hapticFeedback();
    hideLocationModal();
    await initLocation();
  });
  
  document.getElementById('skipLocationBtn')?.addEventListener('click', () => {
    hapticFeedback('light');
    hideLocationModal();
  });
  
  // Handle swipe back on mobile
  let touchStartX = 0;
  document.addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX;
  }, { passive: true });
  
  document.addEventListener('touchend', (e) => {
    const touchEndX = e.changedTouches[0].clientX;
    const diff = touchEndX - touchStartX;
    
    if (diff > 100 && touchStartX < 50 && State.currentView !== 'main') {
      closeDetailView();
    }
  }, { passive: true });
}

// ===========================================
// INITIALIZATION
// ===========================================

async function initLocation() {
  showLoading();
  
  try {
    // Check for stored location first
    const stored = await getStoredLocation();
    
    if (stored) {
      State.location = { lat: stored.lat, lon: stored.lon };
      State.cityName = stored.cityName;
    } else {
      // Request new location
      const coords = await requestLocation();
      State.location = coords;
      
      // Get city name
      State.cityName = await getCityName(coords.lat, coords.lon);
      
      // Store for future use
      storeLocation(coords.lat, coords.lon, State.cityName);
    }
    
    updateCityDisplays();
    updateTodaySection();
    
  } catch (e) {
    console.error('Location error:', e);
    // Use default location (Seoul)
    State.location = { lat: 37.5665, lon: 126.9780 };
    State.cityName = 'Seoul';
    updateCityDisplays();
  }
  
  hideLoading();
}

async function init() {
  initTelegram();
  setupEventListeners();
  
  // Update hero section
  updateHeroSection();
  
  // Start countdown update interval
  setInterval(updateHeroSection, 60000);
  
  // Start iftar countdown interval (if during Ramadan)
  setInterval(() => {
    if (isRamadan() && State.location) {
      updateTodaySection();
    }
  }, 1000);
  
  // Initialize location
  const stored = await getStoredLocation();
  if (stored) {
    State.location = { lat: stored.lat, lon: stored.lon };
    State.cityName = stored.cityName;
    updateCityDisplays();
    
    if (isRamadan()) {
      updateTodaySection();
    }
  } else {
    // Show location modal after a short delay
    setTimeout(() => {
      showLocationModal();
    }, 1500);
  }
}

// Start app
document.addEventListener('DOMContentLoaded', init);
