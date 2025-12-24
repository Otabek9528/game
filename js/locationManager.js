// locationManager.js
// Universal location manager for Telegram WebApp with native LocationManager support
// Strategy: Get FRESH location on every launch, auto-refresh every 5 minutes while app is open
// Features:
// - Telegram LocationManager API (Bot API 8.0+) with persistent toggle
// - Fresh location on every app launch (no stale cached data shown)
// - Silent auto-refresh every 5 minutes while app is open
// - Uses Telegram's native popups (no custom modals)
// - App closes after settings prompt for clean UX

const LocationManager = {
  // Storage keys
  STORAGE_KEY: 'userLocation',
  PERMISSION_KEY: 'locationPermissionGranted',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  SESSION_CHECK_KEY: 'gpsCheckedThisSession',
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes

  // Telegram LocationManager
  tgLocationManager: null,
  hasTelegramLocation: false,
  isRequestingLocation: false,
  periodicRefreshInterval: null,
  isInitialized: false, // Prevent double initialization

  // Translations
  translations: {
    uz: {
      loading: 'Yuklanmoqda...'
    },
    ru: {
      loading: 'Загрузка...'
    },
    en: {
      loading: 'Loading...'
    }
  },

  // Get current language
  getCurrentLang() {
    if (window.I18N && typeof I18N.getLanguage === 'function') {
      return I18N.getLanguage();
    }
    return localStorage.getItem('appLanguage') || 'uz';
  },

  // Get translation
  t(key) {
    const lang = this.getCurrentLang();
    return this.translations[lang]?.[key] || this.translations['en'][key];
  },

  // ============================================
  // INITIALIZATION
  // ============================================

  async init() {
    // Prevent double initialization
    if (this.isInitialized) {
      console.log('⏭️ LocationManager already initialized, skipping...');
      return;
    }
    this.isInitialized = true;
    
    console.log('🚀 LocationManager initializing...');
    
    const tg = Telegram.WebApp;
    tg.ready();
    tg.disableVerticalSwipes();
    
    // Check for Telegram LocationManager (Bot API 8.0+)
    this.tgLocationManager = tg.LocationManager;
    this.hasTelegramLocation = !!this.tgLocationManager;
    
    console.log('📍 Telegram LocationManager available:', this.hasTelegramLocation);
    
    // Use Telegram LocationManager if available
    if (this.hasTelegramLocation) {
      await this.initTelegramLocation();
      return;
    }
    
    // Fallback to browser geolocation for older versions
    this.initBrowserGeolocation();
  },

  // ============================================
  // TELEGRAM LOCATIONMANAGER (PRIMARY METHOD)
  // ============================================

  async initTelegramLocation() {
    return new Promise((resolve) => {
      this.tgLocationManager.init(() => {
        console.log('✅ Telegram LocationManager initialized');
        console.log('📍 Access granted:', this.tgLocationManager.isAccessGranted);

        const tg = Telegram.WebApp;
        
        // DON'T listen for permission changes - causes infinite loop!
        // The event fires repeatedly when GPS is off
        
        // ALWAYS check permissions on every launch
        if (this.tgLocationManager.isAccessGranted) {
          // Toggle ON - get fresh location
          this.showLoadingState();
          this.getTelegramLocation();
        } else {
          // Toggle OFF - always prompt
          this.showTogglePrompt();
        }

        // Periodic refresh will start after first successful location
        // Don't start it here to avoid duplicate requests

        this.markGpsCheckedThisSession();
        resolve();
      });
    });
  },

  getTelegramLocation() {
    // Prevent multiple simultaneous requests
    if (this.isRequestingLocation) {
      console.log('⏭️ Location request already in progress, skipping...');
      return;
    }
    
    // Set flag immediately
    this.isRequestingLocation = true;
    
    console.log('📡 Requesting location from Telegram...');

    this.tgLocationManager.getLocation(async (location) => {
      this.isRequestingLocation = false;
      this.hideLoadingState();
      
      if (location === null) {
        console.log('❌ Location null - GPS might be off');
        // Close app so user can enable GPS and reopen
        const tg = Telegram.WebApp;
        tg.close();
      } else {
        console.log('✅ Got fresh Telegram location');
        const locationData = await this.processTelegramLocation(location);
        this.updateUI(locationData);
        
        // Start periodic refresh only after first successful location
        if (!this.periodicRefreshInterval) {
          this.startPeriodicRefresh();
        }
      }
    });
  },

  async processTelegramLocation(location) {
    const lat = location.latitude;
    const lon = location.longitude;
    const city = await this.getCityName(lat, lon);
    
    const locationData = {
      lat,
      lon,
      city,
      timestamp: Date.now()
    };
    
    console.log('💾 Saving fresh location:', city);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(locationData));
    localStorage.setItem(this.LAST_UPDATE_KEY, locationData.timestamp.toString());
    localStorage.setItem(this.PERMISSION_KEY, 'true');
    
    return locationData;
  },

  showTogglePrompt() {
    const tg = Telegram.WebApp;
    const userLang = tg.initDataUnsafe?.user?.language_code || this.getCurrentLang();
    
    const messages = {
      uz: '1. "Sozlamalarni ochish" tugmasini bosing\n2. "Geolokatsiya" tugmachasini yoqing\n3. Ilovani qayta oching',
      ru: '1. Нажмите кнопку "Открыть настройки"\n2. Включите переключатель "Геолокация"\n3. Откройте приложение заново',
      en: '1. Tap "Open Settings" button\n2. Turn ON the "Geolocation" toggle switch\n3. Reopen the app'
    };
    
    const message = messages[userLang] || messages['en'];
    
    // Create modal overlay
    const overlay = document.createElement('div');
    overlay.id = 'location-guide-modal';
    overlay.innerHTML = `
      <style>
        #location-guide-modal {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.7);
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 10000;
          padding: 20px;
          animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        
        .guide-modal-content {
          background: white;
          border-radius: 20px;
          padding: 24px;
          max-width: 400px;
          width: 100%;
          max-height: 80vh;
          overflow-y: auto;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          animation: slideUp 0.3s ease;
        }
        
        @keyframes slideUp {
          from { transform: translateY(30px); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }
        
        .guide-modal-title {
          font-size: 1.3rem;
          font-weight: 600;
          margin: 0 0 16px 0;
          text-align: center;
          color: #333;
        }
        
        .guide-modal-image {
          width: 80%;
          display: block;
          margin: 0 auto 16px auto;
          border-radius: 12px;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        
        .guide-modal-text {
          font-size: 0.95rem;
          line-height: 1.6;
          color: #555;
          margin-bottom: 20px;
          text-align: left;
        }
        
        .guide-modal-button {
          width: 100%;
          padding: 14px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 1rem;
          font-weight: 600;
          cursor: pointer;
          transition: transform 0.2s;
        }
        
        .guide-modal-button:active {
          transform: scale(0.98);
        }

        .guide-modal-text {
          white-space: pre-line;  
        }
      </style>
      
      <div class="guide-modal-content">
        <h2 class="guide-modal-title">📍 Enable Location Access</h2>
        
        <img src="assets/location-toggle-guide.jpg" alt="Location Toggle Guide" class="guide-modal-image">
        
        <p class="guide-modal-text">${message}</p>
        
        <button class="guide-modal-button" id="openSettingsBtn">
          Open Settings
        </button>
      </div>
    `;
    
    document.body.appendChild(overlay);
    
    // Handle button click
    document.getElementById('openSettingsBtn').addEventListener('click', () => {
      overlay.remove();
      if (tg.LocationManager && tg.LocationManager.openSettings) {
        tg.LocationManager.openSettings();
      } else {
        tg.close();
      }
    });
    
    // Close on overlay click
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        overlay.remove();
      }
    });
  },

  // ============================================
  // PERIODIC AUTO-REFRESH
  // ============================================

  startPeriodicRefresh() {
    // Clear any existing interval
    if (this.periodicRefreshInterval) {
      clearInterval(this.periodicRefreshInterval);
    }

    // Refresh every 5 minutes while app is open
    this.periodicRefreshInterval = setInterval(() => {
      console.log('🔄 Periodic auto-refresh (5 min interval)');
      
      if (this.hasTelegramLocation) {
        if (this.tgLocationManager.isAccessGranted && !this.isRequestingLocation) {
          this.getTelegramLocation();
        } else {
          console.log('⏭️ Skipping refresh - toggle off or request in progress');
        }
      } else {
        // Browser geolocation fallback
        const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
        if (hasPermission) {
          this.silentRefreshBrowser();
        }
      }
    }, this.UPDATE_INTERVAL);

    console.log('✅ Periodic refresh started (every 5 minutes)');
  },

  // ============================================
  // BROWSER GEOLOCATION (FALLBACK)
  // ============================================

  initBrowserGeolocation() {
    const storedLocation = this.getStoredLocation();
    
    // Show loading state
    this.showLoadingState();
    
    // Always try to get fresh location on launch
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    
    if (hasPermission || storedLocation) {
      // Try to get fresh location
      this.getFreshBrowserLocation();
    } else {
      // First launch - request permission
      this.hideLoadingState();
      this.requestInitialPermission();
    }
    
    // Start periodic refresh
    this.startPeriodicRefresh();
  },

  async getFreshBrowserLocation() {
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ Got fresh browser location');
          this.hideLoadingState();
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          localStorage.setItem(this.PERMISSION_KEY, 'true');
          this.markGpsCheckedThisSession();
          resolve(locationData);
        },
        (error) => {
          console.warn('⚠️ Failed to get fresh location:', error.message);
          this.hideLoadingState();
          
          // Close app on GPS error - user needs to enable GPS
          if (error.code === 2) {
            console.log('📍 GPS is off - closing app');
            const tg = Telegram.WebApp;
            tg.close();
          }
          
          this.markGpsCheckedThisSession();
          resolve(null);
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        }
      );
    });
  },

  async silentRefreshBrowser() {
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    if (!hasPermission) {
      console.log('⭕ Skipping refresh (no permission)');
      return;
    }

    console.log('🔄 Silent browser refresh...');

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const locationData = await this.processPosition(pos);
        console.log('✅ Location silently refreshed:', locationData.city);
        this.updateUI(locationData);
      },
      (error) => {
        console.log('⚠️ Silent refresh failed:', error.message);
        // Silent fail - don't interrupt user
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  },

  async requestInitialPermission() {
    console.log('📡 Requesting geolocation permission...');
    
    return new Promise((resolve) => {
      if (!navigator.geolocation) {
        console.error('❌ Geolocation API not supported!');
        const tg = Telegram.WebApp;
        tg.close();
        resolve(null);
        return;
      }

      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ Got position:', pos.coords.latitude, pos.coords.longitude);
          const locationData = await this.processPosition(pos);
          localStorage.setItem(this.PERMISSION_KEY, 'true');
          this.updateUI(locationData);
          this.markGpsCheckedThisSession();
          resolve(locationData);
        },
        (error) => {
          console.error('❌ Geolocation error:', error.code, error.message);
          
          // Close app - user needs to fix GPS/permission
          const tg = Telegram.WebApp;
          tg.close();
          resolve(null);
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        }
      );
    });
  },

  // ============================================
  // LOCATION PROCESSING
  // ============================================

  async processPosition(pos) {
    const lat = pos.coords.latitude;
    const lon = pos.coords.longitude;
    const city = await this.getCityName(lat, lon);
    
    const locationData = {
      lat,
      lon,
      city,
      timestamp: Date.now()
    };
    
    console.log('💾 Saving location:', locationData.city);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(locationData));
    localStorage.setItem(this.LAST_UPDATE_KEY, locationData.timestamp.toString());
    
    return locationData;
  },

  async getCityName(lat, lon) {
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&accept-language=en`
      );
      const data = await res.json();
      return (
        data.address.city ||
        data.address.town ||
        data.address.village ||
        data.address.county ||
        'Noma\'lum'
      );
    } catch (error) {
      console.error('Geocoding error:', error);
      return 'Noma\'lum';
    }
  },

  // ============================================
  // UI UPDATES
  // ============================================

  showLoadingState() {
    const loadingText = this.t('loading');
    const cityElements = document.querySelectorAll('#cityName, .city-name');
    cityElements.forEach(el => {
      if (el) el.innerText = `📍 ${loadingText}`;
    });
    console.log('⏳ Loading state shown');
  },

  hideLoadingState() {
    console.log('✅ Loading state hidden');
  },

  updateUI(locationData) {
    if (!locationData) return;
    
    console.log('🎨 Updating UI with location:', locationData.city);
    
    // Update city name elements
    const cityElements = document.querySelectorAll('#cityName, .city-name');
    cityElements.forEach(el => {
      if (el) el.innerText = locationData.city;
    });

    // Update coordinates if element exists
    const coordsElem = document.getElementById('coords');
    if (coordsElem) {
      coordsElem.innerText = `Koordinatalar: ${locationData.lat.toFixed(4)}, ${locationData.lon.toFixed(4)}`;
    }

    // Update timestamp display if exists
    const timestampElem = document.getElementById('locationTimestamp');
    if (timestampElem && locationData.timestamp) {
      const date = new Date(locationData.timestamp);
      const timeString = date.toLocaleTimeString();
      const dateString = date.toLocaleDateString();
      timestampElem.innerText = `Oxirgi yangilanish: ${timeString}, ${dateString}`;
      timestampElem.style.color = '#888';
      timestampElem.style.fontWeight = 'normal';
    }

    // Trigger prayer times update
    if (typeof updatePrayerData === 'function') {
      updatePrayerData(locationData.lat, locationData.lon, locationData.city);
    }

    // Dispatch custom event for other scripts
    window.dispatchEvent(new CustomEvent('locationUpdated', { 
      detail: locationData 
    }));
  },

  // ============================================
  // UTILITY METHODS
  // ============================================

  isGpsCheckedThisSession() {
    return sessionStorage.getItem(this.SESSION_CHECK_KEY) === 'true';
  },

  markGpsCheckedThisSession() {
    sessionStorage.setItem(this.SESSION_CHECK_KEY, 'true');
  },

  getStoredLocation() {
    const stored = localStorage.getItem(this.STORAGE_KEY);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch {
        return null;
      }
    }
    return null;
  },

  getCurrentLocation() {
    return this.getStoredLocation();
  },

  clearLocation() {
    localStorage.removeItem(this.STORAGE_KEY);
    localStorage.removeItem(this.PERMISSION_KEY);
    localStorage.removeItem(this.LAST_UPDATE_KEY);
    sessionStorage.removeItem(this.SESSION_CHECK_KEY);
    if (this.periodicRefreshInterval) {
      clearInterval(this.periodicRefreshInterval);
    }
    console.log('🗑️ All location data cleared');
  }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  LocationManager.init();
});

// Make available globally
window.LocationManager = LocationManager;