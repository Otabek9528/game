// locationManager.js
// Universal location manager for Telegram WebApp
// Works across multiple HTML pages without re-prompting
// Features:
// - Session-based GPS check (only checks GPS on first app open)
// - Silent background refresh for location updates
// - User-friendly modal when GPS is off

const LocationManager = {
  STORAGE_KEY: 'userLocation',
  PERMISSION_KEY: 'locationPermissionGranted',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  SESSION_CHECK_KEY: 'gpsCheckedThisSession', // sessionStorage key
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes
  

  // Telegram LocationManager
  tgLocationManager: null,
  hasTelegramLocation: false,
  gpsPromptShown: false, // ← ADD THIS FLAG

  // Translations for the GPS modal
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

  // Check if GPS was already checked this session
  isGpsCheckedThisSession() {
    return sessionStorage.getItem(this.SESSION_CHECK_KEY) === 'true';
  },

  // Mark GPS as checked for this session
  markGpsCheckedThisSession() {
    sessionStorage.setItem(this.SESSION_CHECK_KEY, 'true');
  },

  // Initialize on every page load
  async init() {
    console.log('🚀 LocationManager initializing...');
    
    const tg = Telegram.WebApp;
    tg.ready();
    tg.disableVerticalSwipes();
    
    // Check for Telegram LocationManager (Bot API 8.0+)
    this.tgLocationManager = tg.LocationManager;
    this.hasTelegramLocation = !!this.tgLocationManager;
    
    console.log('📍 Telegram LocationManager available:', this.hasTelegramLocation);
    
    // If Telegram LocationManager available, use it
    if (this.hasTelegramLocation) {
      await this.initTelegramLocation();
      return;
    }
    
    // Fallback to browser geolocation
    this.injectModalStyles();
    
    const isMainPage = window.location.pathname.endsWith('index.html') || 
                       window.location.pathname === '/' ||
                       window.location.pathname.endsWith('/');
    
    if (isMainPage && !this.isGpsCheckedThisSession()) {
      console.log('🏠 Main page first load - clearing cached location');
      localStorage.removeItem(this.STORAGE_KEY);
      localStorage.removeItem(this.PERMISSION_KEY);
      localStorage.removeItem(this.LAST_UPDATE_KEY);
    }
    
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    const storedLocation = this.getStoredLocation();
    const gpsAlreadyChecked = this.isGpsCheckedThisSession();
    
    console.log(`Permission: ${hasPermission}, Stored: ${storedLocation?.city || 'none'}, Checked: ${gpsAlreadyChecked}`);
    
    if (gpsAlreadyChecked && storedLocation) {
      console.log('✅ GPS already checked, using cached');
      this.updateUI(storedLocation);
      this.silentRefresh();
      return;
    }
    
    if (hasPermission && storedLocation) {
      console.log('📍 First check - verifying GPS...');
      this.updateUI(storedLocation);
      await this.verifyGpsAndRefresh(storedLocation);
      return;
    }
    
    if (storedLocation) {
      console.log('📍 Legacy location found');
      this.updateUI(storedLocation);
      localStorage.setItem(this.PERMISSION_KEY, 'true');
      this.markGpsCheckedThisSession();
      return;
    }
    
    console.log('🔔 No location - requesting permission');
    await this.requestInitialPermission();
  },

  // Initialize Telegram LocationManager
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

        const storedLocation = this.getStoredLocation();
        const isMainPage = window.location.pathname.endsWith('index.html') || 
                           window.location.pathname === '/' ||
                           window.location.pathname.endsWith('/');

        // Show toggle prompt on main page if no permission
        if (isMainPage && !this.tgLocationManager.isAccessGranted && !sessionStorage.getItem('togglePromptShown')) {
          sessionStorage.setItem('togglePromptShown', 'true');
          this.showTogglePrompt();
        } else if (this.tgLocationManager.isAccessGranted) {
          if (!this.isGpsCheckedThisSession()) {
            this.getTelegramLocation();
          } else if (storedLocation) {
            this.updateUI(storedLocation);
          }
        } else if (storedLocation) {
          this.updateUI(storedLocation);
        }

        this.markGpsCheckedThisSession();
        resolve();
      });
    });
  },


// Get location using Telegram API
  getTelegramLocation() {
    console.log('📡 Requesting location from Telegram...');

    this.tgLocationManager.getLocation(async (location) => {
      if (location === null) {
        console.log('❌ Location null - GPS might be off');
        
        // Show GPS prompt only once per session
        if (!this.gpsPromptShown) {
          this.gpsPromptShown = true;
          this.showGPSModal();
        }
        
        const cached = this.getStoredLocation();
        if (cached) this.updateUI(cached);
      } else {
        console.log('✅ Got Telegram location');
        this.gpsPromptShown = false; // Reset flag on success
        const locationData = await this.processTelegramLocation(location);
        this.updateUI(locationData);
      }
    });
  },

  // Process Telegram location
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
    
    console.log('💾 Saving location:', city);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(locationData));
    localStorage.setItem(this.LAST_UPDATE_KEY, locationData.timestamp.toString());
    localStorage.setItem(this.PERMISSION_KEY, 'true');
    
    return locationData;
  },

  // Show toggle prompt
  showTogglePrompt() {
    const tg = Telegram.WebApp;
    const userLang = tg.initDataUnsafe?.user?.language_code || this.getCurrentLang();
    
    const messages = {
      uz: 'Joylashuv xususiyatlaridan foydalanish uchun bot sozlamalarida joylashuvga ruxsat bering.',
      ru: 'Чтобы использовать функции на основе местоположения, пожалуйста, включите доступ к местоположению в настройках бота.',
      en: 'To provide location-based features, please enable location access for this Mini App in the bot settings.'
    };
    
    const message = messages[userLang] || messages['en'];
    
    // Trigger toggle to appear
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

  // Verify GPS is working and refresh location (first check of session)
  async verifyGpsAndRefresh(fallbackLocation) {
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          // GPS is working - update location
          console.log('✅ GPS verified working, refreshing location...');
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          this.markGpsCheckedThisSession();
          resolve(locationData);
        },
        (error) => {
          console.log('⚠️ GPS check failed:', error.code, error.message);
          
          // GPS might be off - show modal
          if (error.code === 1 || error.code === 2) {
            console.log('📍 GPS appears to be off - showing modal');
            this.showGPSModal();
          } else {
            // Timeout or other error - just use cached location
            console.log('⏱️ GPS timeout - using cached location');
            this.markGpsCheckedThisSession();
          }
          
          resolve(fallbackLocation);
        },
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        }
      );
    });
  },

  // Inject CSS for modal
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
      
      .gps-modal-btn-primary:hover {
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
      }
      
      .gps-modal-btn-close {
        background: transparent;
        color: rgba(255, 255, 255, 0.5);
        font-size: 13px;
        padding: 10px;
      }
      
      .gps-modal-btn-close:hover {
        color: rgba(255, 255, 255, 0.8);
      }
    `;
    document.head.appendChild(styles);
  },

  // Show GPS off modal
  showGPSModal() {
    // Remove existing modal if any
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
      this.hideGPSModal();
      this.requestInitialPermission();
    });
    
    document.getElementById('gps-close').addEventListener('click', () => {
      this.hideGPSModal();
      // Mark as checked so user isn't bothered again this session
      this.markGpsCheckedThisSession();
    });
    
    // Close on overlay click
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.hideGPSModal();
        this.markGpsCheckedThisSession();
      }
    });
    
    // Haptic feedback
    try {
      if (Telegram.WebApp.HapticFeedback) {
        Telegram.WebApp.HapticFeedback.notificationOccurred('warning');
      }
    } catch (e) {}
  },

  // Hide GPS modal
  hideGPSModal() {
    const overlay = document.getElementById('gps-modal-overlay');
    if (overlay) {
      overlay.remove();
    }
  },

  // Get stored location data
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

  // Request permission only on first use
  async requestInitialPermission() {
    console.log('📡 Requesting geolocation permission...');
    
    return new Promise((resolve) => {
      // First check if geolocation is available
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
          
          // Error codes:
          // 1 = PERMISSION_DENIED - user clicked deny
          // 2 = POSITION_UNAVAILABLE - GPS is off or not available
          // 3 = TIMEOUT - took too long
          
          if (error.code === 1) {
            console.log('🚫 User denied permission');
            this.showGPSModal();
          } else if (error.code === 2) {
            console.log('📍 GPS appears to be off');
            this.showGPSModal();
          } else if (error.code === 3) {
            console.log('⏱️ Location request timed out');
            this.showGPSModal();
          }
          
          resolve(null);
        },
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        }
      );
    });
  },

  // Silent refresh - runs in background, never shows modal
  async silentRefresh() {
    const lastUpdate = parseInt(localStorage.getItem(this.LAST_UPDATE_KEY) || '0');
    const now = Date.now();
    
    // Don't refresh too frequently
    if (now - lastUpdate < this.UPDATE_INTERVAL) {
      console.log('⏱️ Skipping silent refresh (updated recently)');
      return;
    }

    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    if (!hasPermission) {
      console.log('⭕ Skipping silent refresh (no permission)');
      return;
    }

    console.log('🔄 Attempting silent background refresh...');

    // Try to get new position silently - accept cached position
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const locationData = await this.processPosition(pos);
        console.log('✅ Location silently refreshed:', locationData.city);
        this.updateUI(locationData);
      },
      (error) => {
        // Silent refresh failed - just continue with cached location
        // Do NOT show modal - this is background refresh
        console.log('⚠️ Silent refresh failed (using cached):', error.message);
      },
      {
        enableHighAccuracy: false,
        timeout: 5000,
        maximumAge: 600000 // Accept up to 10 minute old cached position
      }
    );
  },

  // Manual refresh triggered by user button
  async manualRefresh() {
    console.log('🔄 Manual refresh initiated');
    
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    
    if (!hasPermission) {
      console.log('⚠️ No permission yet');
      return this.requestInitialPermission();
    }

    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ Got position for manual refresh');
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          resolve(locationData);
        },
        (error) => {
          console.warn('⚠️ Manual refresh failed:', error.message);
          
          if (error.code === 2) {
            this.showGPSModal();
            resolve(null);
          } else {
            const stored = this.getStoredLocation();
            if (stored) {
              this.updateUI(stored);
              resolve(stored);
            } else {
              this.showGPSModal();
              resolve(null);
            }
          }
        },
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        }
      );
    });
  },

  // Process position and get city name
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

  // Reverse geocoding
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

  // Update UI elements on current page
  updateUI(locationData) {
    if (!locationData) return;
    
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

  // Get current location (returns cached if available)
  getCurrentLocation() {
    return this.getStoredLocation();
  },

  // Check if location is stale (older than 24 hours)
  isLocationStale() {
    const location = this.getStoredLocation();
    if (!location || !location.timestamp) return true;
    
    const age = Date.now() - location.timestamp;
    return age > 24 * 60 * 60 * 1000; // 24 hours
  },

  // Clear stored location (useful for testing or reset)
  clearLocation() {
    localStorage.removeItem(this.STORAGE_KEY);
    localStorage.removeItem(this.PERMISSION_KEY);
    localStorage.removeItem(this.LAST_UPDATE_KEY);
    sessionStorage.removeItem(this.SESSION_CHECK_KEY);
    console.log('🗑️ All location data cleared');
  }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  LocationManager.init();
});

// Make available globally
window.LocationManager = LocationManager;
