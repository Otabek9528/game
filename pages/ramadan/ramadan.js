/**
 * RAMADAN 2026 - Muslim Vegukin Bot WebApp
 * Premium Islamic Calendar & Prayer Times
 * 
 * Uses existing location from localStorage (set by locationManager.js)
 */

// ===========================================
// CONFIGURATION
// ===========================================

const CONFIG = {
  // Ramadan 2026 estimated start (may need adjustment based on moon sighting)
  RAMADAN_START: new Date(2026, 1, 1), // February 28, 2026
  RAMADAN_DAYS: 30,
  
  // Aladhan API
  API_BASE: 'https://api.aladhan.com/v1',
  METHOD: 3, // Muslim World League
  SCHOOL: 1, // Hanafi
  
  // localStorage key (same as locationManager.js)
  LOCATION_STORAGE_KEY: 'userLocation',
  
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
// STATE
// ===========================================

const State = {
  location: null,
  cityName: '---',
  activeTab: 'tomorrow',
  todayTimes: null,
  tomorrowTimes: null,
  heroCountdownInterval: null,
  nextEventInterval: null
};

// ===========================================
// TELEGRAM WEBAPP
// ===========================================

const tg = window.Telegram?.WebApp;

function initTelegram() {
  if (!tg) return;
  
  tg.ready();
  tg.expand();
  
  try {
    tg.disableVerticalSwipes();
  } catch (e) {}
  
  // Back button
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      window.location.href = '../../index.html';
    });
  }
}

function haptic(type = 'light') {
  try {
    if (tg?.HapticFeedback) {
      tg.HapticFeedback.impactOccurred(type);
    }
  } catch (e) {}
}

// ===========================================
// LOCATION (from existing locationManager)
// ===========================================

function getStoredLocation() {
  try {
    const stored = localStorage.getItem(CONFIG.LOCATION_STORAGE_KEY);
    if (stored) {
      const data = JSON.parse(stored);
      if (data.lat && data.lon) {
        return {
          lat: data.lat,
          lon: data.lon,
          city: data.city || 'Noma\'lum'
        };
      }
    }
  } catch (e) {
    console.error('Error reading location:', e);
  }
  return null;
}

// ===========================================
// UTILITY FUNCTIONS
// ===========================================

function formatDate(date, includeWeekday = false) {
  const day = date.getDate();
  const month = CONFIG.MONTHS_UZ[date.getMonth()];
  const weekday = CONFIG.WEEKDAYS_UZ[date.getDay()];
  
  if (includeWeekday) {
    return `${weekday}, ${day}-${month}`;
  }
  return `${day}-${month}`;
}

function calculateRamadanDay(date) {
  const start = new Date(CONFIG.RAMADAN_START);
  start.setHours(0, 0, 0, 0);
  
  const target = new Date(date);
  target.setHours(0, 0, 0, 0);
  
  const diffTime = target.getTime() - start.getTime();
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  return diffDays + 1;
}

function isRamadan(date = new Date()) {
  const day = calculateRamadanDay(date);
  return day >= 1 && day <= CONFIG.RAMADAN_DAYS;
}

function isBeforeRamadan(date = new Date()) {
  return date < CONFIG.RAMADAN_START;
}

function getCountdownToRamadan() {
  const now = new Date();
  const diff = CONFIG.RAMADAN_START.getTime() - now.getTime();
  
  if (diff <= 0) return null;
  
  return {
    days: Math.floor(diff / (1000 * 60 * 60 * 24)),
    hours: Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
    minutes: Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
  };
}

function getTimeUntilIftar(iftarTimeStr) {
  if (!iftarTimeStr || iftarTimeStr === '--:--') return null;
  
  const now = new Date();
  const [hours, minutes] = iftarTimeStr.split(':').map(Number);
  
  const iftar = new Date(now);
  iftar.setHours(hours, minutes, 0, 0);
  
  const diff = iftar.getTime() - now.getTime();
  
  if (diff <= 0) return null;
  
  const h = Math.floor(diff / (1000 * 60 * 60));
  const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const s = Math.floor((diff % (1000 * 60)) / 1000);
  
  return { hours: h, minutes: m, seconds: s };
}

function getTimeUntilSuhur(suhurTimeStr) {
  if (!suhurTimeStr || suhurTimeStr === '--:--') return null;
  
  const now = new Date();
  const [hours, minutes] = suhurTimeStr.split(':').map(Number);
  
  const suhur = new Date(now);
  suhur.setHours(hours, minutes, 0, 0);
  
  // If suhur time has passed today, it's tomorrow's suhur
  if (suhur <= now) {
    suhur.setDate(suhur.getDate() + 1);
  }
  
  const diff = suhur.getTime() - now.getTime();
  
  if (diff <= 0) return null;
  
  const h = Math.floor(diff / (1000 * 60 * 60));
  const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const s = Math.floor((diff % (1000 * 60)) / 1000);
  
  return { hours: h, minutes: m, seconds: s };
}

function getNextEvent(suhurTime, iftarTime) {
  // Returns 'suhur' or 'iftar' based on which is coming next
  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  
  if (!suhurTime || !iftarTime) return null;
  
  const [sH, sM] = suhurTime.split(':').map(Number);
  const [iH, iM] = iftarTime.split(':').map(Number);
  
  const suhurMinutes = sH * 60 + sM;
  const iftarMinutes = iH * 60 + iM;
  
  // Logic:
  // Before Suhur (e.g., 3am) → next is Suhur
  // After Suhur, Before Iftar (e.g., 2pm) → next is Iftar
  // After Iftar (e.g., 8pm) → next is tomorrow's Suhur
  
  if (currentMinutes < suhurMinutes) {
    return 'suhur';
  } else if (currentMinutes < iftarMinutes) {
    return 'iftar';
  } else {
    return 'suhur'; // Tomorrow's suhur
  }
}

// ===========================================
// API FUNCTIONS
// ===========================================

async function fetchPrayerTimes(lat, lon, date = new Date()) {
  const dateStr = `${date.getDate()}-${date.getMonth() + 1}-${date.getFullYear()}`;
  
  try {
    const url = `${CONFIG.API_BASE}/timings/${dateStr}?latitude=${lat}&longitude=${lon}&method=${CONFIG.METHOD}&school=${CONFIG.SCHOOL}`;
    const response = await fetch(url);
    
    if (!response.ok) throw new Error('API error');
    
    const data = await response.json();
    const timings = data.data.timings;
    
    return {
      suhur: timings.Fajr.slice(0, 5),
      iftar: timings.Maghrib.slice(0, 5)
    };
  } catch (e) {
    console.error('Prayer times fetch error:', e);
    return null;
  }
}

// ===========================================
// UI UPDATES
// ===========================================

function updateCityDisplay() {
  const elements = ['headerCityName', 'calendarCityName'];
  elements.forEach(id => {
    const el = document.getElementById(id);
    if (el) el.textContent = State.cityName;
  });
}

function updateHeroSection() {
  const now = new Date();
  
  const heroBeforeRamadan = document.getElementById('heroBeforeRamadan');
  const heroDuringRamadan = document.getElementById('heroDuringRamadan');
  const heroAfterRamadan = document.getElementById('heroAfterRamadan');
  
  // Hide all first
  heroBeforeRamadan.style.display = 'none';
  heroDuringRamadan.style.display = 'none';
  heroAfterRamadan.style.display = 'none';
  
  if (isBeforeRamadan(now)) {
    // Show countdown to Ramadan
    heroBeforeRamadan.style.display = 'block';
    updateCountdown();
    startHeroCountdown();
  } else if (isRamadan(now)) {
    // Show during Ramadan view
    heroDuringRamadan.style.display = 'flex';
    
    // Update current date
    const currentDateEl = document.getElementById('currentDate');
    if (currentDateEl) {
      currentDateEl.textContent = formatCurrentDate(now);
    }
    
    // Update Ramadan day number
    const dayNum = calculateRamadanDay(now);
    document.getElementById('badgeDayNum').textContent = dayNum;
    
    // Update next event if we have times
    if (State.todayTimes) {
      updateNextEventDisplay();
      startNextEventCountdown();
    }
  } else {
    // After Ramadan
    heroAfterRamadan.style.display = 'block';
  }
}

// Format current date in Uzbek
function formatCurrentDate(date) {
  const day = date.getDate();
  const month = CONFIG.MONTHS_UZ[date.getMonth()];
  const weekday = CONFIG.WEEKDAYS_UZ[date.getDay()];
  return `${day}-${month}, ${weekday}`;
}

function updateCountdown() {
  const countdown = getCountdownToRamadan();
  
  if (countdown) {
    document.getElementById('countdownDays').textContent = String(countdown.days).padStart(2, '0');
    document.getElementById('countdownHours').textContent = String(countdown.hours).padStart(2, '0');
    document.getElementById('countdownMinutes').textContent = String(countdown.minutes).padStart(2, '0');
  }
}

function startHeroCountdown() {
  // Clear existing interval
  if (State.heroCountdownInterval) {
    clearInterval(State.heroCountdownInterval);
  }
  
  State.heroCountdownInterval = setInterval(() => {
    if (isBeforeRamadan()) {
      updateCountdown();
    } else {
      clearInterval(State.heroCountdownInterval);
      updateHeroSection(); // Switch to during Ramadan view
    }
  }, 60000); // Update every minute
}

function updateNextEventDisplay() {
  if (!State.todayTimes) return;
  
  const { suhur, iftar } = State.todayTimes;
  const nextEvent = getNextEvent(suhur, iftar);
  
  const countdownLabelBox = document.getElementById('countdownLabelBox');
  const countdownIcon = document.getElementById('countdownIcon');
  const countdownText = document.getElementById('countdownText');
  const quickSuhur = document.getElementById('quickSuhur');
  const quickIftar = document.getElementById('quickIftar');
  
  // Update quick times reference
  document.getElementById('quickSuhurTime').textContent = suhur;
  document.getElementById('quickIftarTime').textContent = iftar;
  
  // Remove active/mode classes
  countdownLabelBox.classList.remove('suhur-mode', 'iftar-mode');
  quickSuhur.classList.remove('active');
  quickIftar.classList.remove('active');
  
  if (nextEvent === 'suhur') {
    countdownLabelBox.classList.add('suhur-mode');
    countdownIcon.textContent = '🌙';
    countdownText.textContent = 'Saharlikgacha';
    quickSuhur.classList.add('active');
  } else {
    countdownLabelBox.classList.add('iftar-mode');
    countdownIcon.textContent = '🌅';
    countdownText.textContent = 'Iftorlikgacha';
    quickIftar.classList.add('active');
  }
  
  // Update the countdown values
  updateNextEventCountdownValues();
}

function updateNextEventCountdownValues() {
  if (!State.todayTimes) return;
  
  const { suhur, iftar } = State.todayTimes;
  const nextEvent = getNextEvent(suhur, iftar);
  
  let remaining;
  
  if (nextEvent === 'suhur') {
    // If after iftar, use tomorrow's suhur
    const now = new Date();
    const [iH, iM] = iftar.split(':').map(Number);
    const iftarMinutes = iH * 60 + iM;
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    
    if (currentMinutes >= iftarMinutes && State.tomorrowTimes) {
      remaining = getTimeUntilSuhur(State.tomorrowTimes.suhur);
    } else {
      remaining = getTimeUntilSuhur(suhur);
    }
  } else {
    remaining = getTimeUntilIftar(iftar);
  }
  
  if (remaining) {
    document.getElementById('nextCountdownHours').textContent = String(remaining.hours).padStart(2, '0');
    document.getElementById('nextCountdownMinutes').textContent = String(remaining.minutes).padStart(2, '0');
    document.getElementById('nextCountdownSeconds').textContent = String(remaining.seconds).padStart(2, '0');
  }
}

function startNextEventCountdown() {
  // Clear existing interval
  if (State.nextEventInterval) {
    clearInterval(State.nextEventInterval);
  }
  
  State.nextEventInterval = setInterval(() => {
    if (isRamadan()) {
      updateNextEventCountdownValues();
      
      // Check if we need to switch the event (suhur <-> iftar)
      // by re-evaluating every minute
      const now = new Date();
      if (now.getSeconds() === 0) {
        updateNextEventDisplay();
      }
    } else {
      clearInterval(State.nextEventInterval);
    }
  }, 1000); // Update every second
}

async function fetchTodayTimes() {
  if (!State.location) return;
  
  const today = new Date();
  
  // Fetch times if not cached
  if (!State.todayTimes) {
    State.todayTimes = await fetchPrayerTimes(State.location.lat, State.location.lon, today);
  }
  
  // Update hero section now that we have times
  if (State.todayTimes && isRamadan()) {
    updateNextEventDisplay();
    startNextEventCountdown();
  }
}

async function updateTomorrowTab() {
  if (!State.location) return;
  
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const ramadanDay = calculateRamadanDay(tomorrow);
  
  // Update date display
  document.getElementById('tomorrowDate').textContent = formatDate(tomorrow, true);
  
  if (isRamadan(tomorrow)) {
    document.getElementById('tomorrowRamadan').textContent = `Ramazonning ${ramadanDay}-kuni`;
  } else if (ramadanDay === 1) {
    document.getElementById('tomorrowRamadan').textContent = 'Ramazonning 1-kuni';
  } else {
    document.getElementById('tomorrowRamadan').textContent = '';
  }
  
  // Fetch times if not cached
  if (!State.tomorrowTimes) {
    State.tomorrowTimes = await fetchPrayerTimes(State.location.lat, State.location.lon, tomorrow);
  }
  
  if (State.tomorrowTimes) {
    document.getElementById('tomorrowSuhur').textContent = State.tomorrowTimes.suhur;
    document.getElementById('tomorrowIftar').textContent = State.tomorrowTimes.iftar;
  }
}

// ===========================================
// TAB NAVIGATION
// ===========================================

function initTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');
  
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.dataset.tab;
      
      // Update active states
      tabBtns.forEach(b => b.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));
      
      btn.classList.add('active');
      document.getElementById(`tab${capitalize(tabId)}`).classList.add('active');
      
      State.activeTab = tabId;
      haptic('light');
      
      // Load tab content if needed
      if (tabId === 'tomorrow') {
        updateTomorrowTab();
      }
    });
  });
}

function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// ===========================================
// EVENT HANDLERS
// ===========================================

function setupEventListeners() {
  // Back button
  document.getElementById('backBtn')?.addEventListener('click', (e) => {
    e.preventDefault();
    haptic();
    window.location.href = '../../index.html';
  });
  
  // Generate calendar button
  document.getElementById('generateCalendarBtn')?.addEventListener('click', () => {
    haptic('medium');
    generateCalendar();
  });
  
  // Info link
  document.getElementById('infoLink')?.addEventListener('click', (e) => {
      e.preventDefault();
      haptic();
      if (tg) {
        tg.openLink('https://telegra.ph/Ta%D2%9Bvimlardagi-tafovvutlar-02-03', { try_instant_view: true });
      } else {
        window.open('https://telegra.ph/Ta%D2%9Bvimlardagi-tafovvutlar-02-03', '_blank');
      }
  });
}

// ===========================================
// CALENDAR GENERATION (Placeholder)
// ===========================================

function generateCalendar() {
  if (!State.location) {
    if (tg) {
      tg.showAlert('Joylashuv ma\'lumotlari topilmadi. Iltimos, asosiy sahifaga qayting.');
    } else {
      alert('Joylashuv ma\'lumotlari topilmadi');
    }
    return;
  }
  
  // Show loading
  showLoading('Taqvim yaratilmoqda...');
  
  // This will call the separate calendarGenerator.js function
  // For now, just show a placeholder message
  if (typeof window.generateRamadanCalendarImage === 'function') {
    window.generateRamadanCalendarImage(State.location.lat, State.location.lon, State.cityName);
  } else {
    // Placeholder until calendarGenerator.js is implemented
    setTimeout(() => {
      hideLoading();
      if (tg) {
        tg.showAlert('Taqvim generatsiyasi tez orada qo\'shiladi!');
      } else {
        alert('Taqvim generatsiyasi tez orada qo\'shiladi!');
      }
    }, 1500);
  }
}

// ===========================================
// LOADING STATE
// ===========================================

function showLoading(text = 'Yuklanmoqda...') {
  const overlay = document.getElementById('loadingOverlay');
  const loadingText = document.getElementById('loadingText');
  
  if (loadingText) loadingText.textContent = text;
  overlay?.classList.add('active');
}

function hideLoading() {
  document.getElementById('loadingOverlay')?.classList.remove('active');
}

// ===========================================
// INITIALIZATION
// ===========================================

async function init() {
  console.log('🌙 Ramadan 2026 Page Init');
  
  // Initialize Telegram
  initTelegram();
  
  // Get location from existing storage
  const location = getStoredLocation();
  
  if (location) {
    State.location = location;
    State.cityName = location.city;
    console.log('📍 Location loaded:', State.cityName);
  } else {
    console.warn('⚠️ No location found in storage');
    State.cityName = 'Noma\'lum';
  }
  
  // Update UI
  updateCityDisplay();
  updateHeroSection();
  
  // Initialize tabs
  initTabs();
  
  // Setup event listeners
  setupEventListeners();
  
  // Load data
  if (State.location) {
    // Fetch today's times for hero section
    await fetchTodayTimes();
    // Fetch and display tomorrow's data (default tab)
    await updateTomorrowTab();
  }
  
  console.log('✅ Ramadan page ready');
}

// Start when DOM is ready
document.addEventListener('DOMContentLoaded', init);

// Expose for calendar generator
window.RamadanPage = {
  showLoading,
  hideLoading,
  getState: () => State
};
