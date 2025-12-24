// locationManager.js
// Universal location manager for Telegram WebApp with native LocationManager support
// Strategy: Get FRESH location on every launch, auto-refresh every 5 minutes while app is open
// Features:
// - Telegram LocationManager API (Bot API 8.0+) with persistent toggle
// - Fresh location on every app launch (no stale cached data shown)
// - Silent auto-refresh every 5 minutes while app is open
// - Fallback to browser geolocation for older Telegram versions
// - Prompts only on first launch, silent operation thereafter

const LocationManager = {
  // Storage keys
  STORAGE_KEY: 'userLocation',
  PERMISSION_KEY: 'locationPermissionGranted',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  SESSION_CHECK_KEY: 'gpsCheckedThisSession',
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes
  STALE_THRESHOLD: 24 * 60 * 60 * 1000, // 24 hours

  // Telegram LocationManager
  tgLocationManager: null,
  hasTelegramLocation: false,
  gpsPromptShown: false,
  isRequestingLocation: false,
  periodicRefreshInterval: null,

  // Translations for GPS modal (only used for fallback browser geolocation)
  translations: {
    uz: {
      title: '📍 GPS yoqilmagan',
      message: 'Joylashuvingizni aniqlash uchun telefoningizda GPS (Lokatsiya) yoqilgan bo\'lishi kerak.',
      instructions: 'Iltimos, telefoningiz sozlamalaridan GPS ni yoqing va qayta urining.',
      tryAgain: '🔄 Qayta urinish',
      close: '✕ Yopish'
    },
    ru: {
      title: '📍 GPS выключен',
      message: 'Для определения вашего местоположения необходимо включить GPS (Геолокацию) на вашем телефоне.',
      instructions: 'Пожалуйста, включите GPS в настройках телефона и попробуйте снова.',
      tryAgain: '🔄 Попробовать снова',
      close: '✕ Закрыть'
    },
    en: {
      title: '📍 GPS is turned off',
      message: 'To detect your location, GPS (Location Services) must be enabled on your phone.',
      instructions: 'Please enable GPS in your phone settings and try again.',
      tryAgain: '🔄 Try Again',
      close: '✕ Close'
    }
  },

  // ============================================
  // INITIALIZATION
  // ============================================

  async init() {
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
        
        // Listen for permission changes
        tg.onEvent('locationManagerUpdated', () => {
          console.log('📍 Permission changed');
          if (this.tgLocationManager.isAccessGranted) {
            this.getTelegramLocation();
          }
        });

        // ALWAYS check permissions on every launch
        if (this.tgLocationManager.isAccessGranted) {
          // Toggle ON - get fresh location
          this.showLoadingState();
          this.getTelegramLocation();
        } else {
          // Toggle OFF - always prompt (even if we have cache)
          this.showTogglePrompt();
        }

        // Start periodic refresh
        this.startPeriodicRefresh();

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

    // Prevent showing GPS modal multiple times
    if (this.gpsPromptShown) {
      console.log('⏭️ GPS prompt already shown this session, skipping...');
      const cached = this.getStoredLocation();
      if (cached) {
        this.hideLoadingState();
        this.updateUI(cached);
      }
      return;
    }

    console.log('📡 Requesting location from Telegram...');
    this.isRequestingLocation = true;

    this.tgLocationManager.getLocation(async (location) => {
      this.isRequestingLocation = false;
      this.hideLoadingState();
      
      if (location === null) {
        console.log('❌ Location null - GPS might be off');
        
        // Show GPS prompt only once per session
        if (!this.gpsPromptShown) {
          this.gpsPromptShown = true;
          this.showGPSModal();
        }
        
        // Fallback to cached location
        const cached = this.getStoredLocation();
        if (cached) {
          this.updateUI(cached);
          this.showStaleDataWarning();
        }
      } else {
        console.log('✅ Got fresh Telegram location');
        this.gpsPromptShown = false;
        const locationData = await this.processTelegramLocation(location);
        this.updateUI(locationData);
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
      uz: 'Joylashuv xususiyatlaridan foydalanish uchun bot sozlamalarida joylashuvga ruxsat bering.',
      ru: 'Чтобы использовать функции на основе местоположения, пожалуйста, включите доступ к местоположению в настройках бота.',
      en: 'To provide location-based features, please enable location access for this Mini App in the bot settings.'
    };
    
    const message = messages[userLang] || messages['en'];
    
    // Trigger toggle to appear in bot settings
    this.tgLocationManager.getLocation(() => {});
    
    tg.showPopup({
      title: '📍 Location Access Needed',
      message: message,
      buttons: [
        { id: 'settings', type: 'default', text: 'Open Settings' },
        { id: 'close', type: 'close', text: 'Close' }
      ]
    }, (buttonId) => {
      if (buttonId === 'settings') {
        if (this.tgLocationManager.openSettings) {
          this.tgLocationManager.openSettings();
        } else {
          tg.close();
        }
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
    this.injectModalStyles();
    
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
          
          // Show modal only on first error
          if (error.code === 2 && !this.gpsPromptShown) {
            this.gpsPromptShown = true;
            this.showGPSModal();
          }
          
          // Fallback to cached
          const stored = this.getStoredLocation();
          if (stored) {
            this.updateUI(stored);
            this.showStaleDataWarning();
          }
          
          this.markGpsCheckedThisSession();
          resolve(stored);
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
        // Silent fail - don't show modals
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
        this.showGPSModal();
        resolve(null);
        return;
      }

      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ Got position:', pos.coords.latitude, pos.coords.longitude);
          const locationData = await this.processPosition(pos);
          localStorage.setItem(this.PERMISSION_KEY, 'true');
          this.updateUI(locationData);
          this.hideGPSModal();
          this.markGpsCheckedThisSession();
          resolve(locationData);
        },
        (error) => {
          console.error('❌ Geolocation error:', error.code, error.message);
          
          if (error.code === 1) {
            console.log('🚫 User denied permission');
          } else if (error.code === 2) {
            console.log('📍 GPS appears to be off');
          } else if (error.code === 3) {
            console.log('⏱️ Location request timed out');
          }
          
          this.showGPSModal();
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
    const cityElements = document.querySelectorAll('#cityName, .city-name');
    cityElements.forEach(el => {
      if (el) el.innerText = '📍 Joylashuv aniqlanmoqda...';
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

  showStaleDataWarning() {
    const timestampElem = document.getElementById('locationTimestamp');
    if (timestampElem) {
      timestampElem.style.color = '#ff9800';
      timestampElem.innerHTML += ' ⚠️ <small>(Oxirgi ma\'lum joylashuv)</small>';
    }
    console.log('⚠️ Stale data warning shown');
  },

  // ============================================
  // GPS MODAL (for browser geolocation fallback)
  // ============================================

  injectModalStyles() {
    if (document.getElementById('gps-modal-styles')) return;
    
    const styles = document.createElement('style');
    styles.id = 'gps-modal-styles';
    styles.textContent = `
      .gps-modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.7);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
        padding: 20px;
        animation: gpsModalFadeIn 0.3s ease;
      }
      
      @keyframes gpsModalFadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      
      .gps-modal {
        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
        border-radius: 20px;
        padding: 24px;
        max-width: 340px;
        width: 100%;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        border: 1px solid rgba(255, 255, 255, 0.1);
        animation: gpsModalSlideUp 0.3s ease;
      }
      
      @keyframes gpsModalSlideUp {
        from { transform: translateY(20px); opacity: 0; }
        to { transform: translateY(0); opacity: 1; }
      }
      
      .gps-modal-icon {
        font-size: 48px;
        text-align: center;
        margin-bottom: 16px;
      }
      
      .gps-modal-title {
        color: #fff;
        font-size: 20px;
        font-weight: 600;
        text-align: center;
        margin: 0 0 12px 0;
      }
      
      .gps-modal-message {
        color: rgba(255, 255, 255, 0.8);
        font-size: 14px;
        line-height: 1.5;
        text-align: center;
        margin: 0 0 8px 0;
      }
      
      .gps-modal-instructions {
        color: rgba(255, 255, 255, 0.6);
        font-size: 13px;
        line-height: 1.4;
        text-align: center;
        margin: 0 0 20px 0;
      }
      
      .gps-modal-buttons {
        display: flex;
        flex-direction: column;
        gap: 10px;
      }
      
      .gps-modal-btn {
        padding: 14px 20px;
        border-radius: 12px;
        font-size: 15px;
        font-weight: 600;
        cursor: pointer;
        border: none;
        transition: all 0.2s ease;
      }
      
      .gps-modal-btn:active {
        transform: scale(0.98);
      }
      
      .gps-modal-btn-primary {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
      }
      
      .gps-modal-btn-close {
        background: rgba(255, 255, 255, 0.1);
        color: rgba(255, 255, 255, 0.8);
      }
    `;
    
    document.head.appendChild(styles);
  },

  showGPSModal() {
    this.hideGPSModal();
    
    const overlay = document.createElement('div');
    overlay.className = 'gps-modal-overlay';
    overlay.id = 'gps-modal-overlay';

    overlay.innerHTML = `
      <div class="gps-modal">
        <div class="gps-modal-icon">📍</div>
        <h2 class="gps-modal-title">${this.t('title')}</h2>
        <p class="gps-modal-message">${this.t('message')}</p>
        <p class="gps-modal-instructions">${this.t('instructions')}</p>
        
        <div class="gps-modal-buttons">
          <button class="gps-modal-btn gps-modal-btn-primary" id="gps-try-again">
            ${this.t('tryAgain')}
          </button>
          <button class="gps-modal-btn gps-modal-btn-close" id="gps-close">
            ${this.t('close')}
          </button>
        </div>
      </div>
    `;
    
    document.body.appendChild(overlay);
    
    // Event listeners
    document.getElementById('gps-try-again').addEventListener('click', () => {
      console.log('🔄 User clicked Try Again');
      this.hideGPSModal();
      this.resetGpsPrompt();
      
      if (this.hasTelegramLocation) {
        this.getTelegramLocation();
      } else {
        this.requestInitialPermission();
      }
    });
    
    document.getElementById('gps-close').addEventListener('click', () => {
      this.hideGPSModal();
      this.markGpsCheckedThisSession();
    });
    
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.hideGPSModal();
        this.markGpsCheckedThisSession();
      }
    });
  },

  hideGPSModal() {
    const overlay = document.getElementById('gps-modal-overlay');
    if (overlay) {
      overlay.remove();
    }
  },

  resetGpsPrompt() {
    this.gpsPromptShown = false;
    this.isRequestingLocation = false;
    console.log('🔄 GPS prompt flag reset');
  },

  // ============================================
  // UTILITY METHODS
  // ============================================

  getCurrentLang() {
    if (window.I18N && typeof I18N.getLanguage === 'function') {
      return I18N.getLanguage();
    }
    return localStorage.getItem('appLanguage') || 'uz';
  },

  t(key) {
    const lang = this.getCurrentLang();
    return this.translations[lang]?.[key] || this.translations['en'][key];
  },

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

  isLocationStale() {
    const location = this.getStoredLocation();
    if (!location || !location.timestamp) return true;
    
    const age = Date.now() - location.timestamp;
    return age > this.STALE_THRESHOLD;
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
