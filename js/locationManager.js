// locationManager.js - Updated to use Telegram's native LocationManager API
// Features:
// - Persistent toggle-based permission (user sets once, never asked again)
// - No permission prompts after first toggle enable
// - Clean integration with Telegram's native UI
// - Maintains all existing functionality (caching, silent refresh, etc.)

const LocationManager = {
  STORAGE_KEY: 'userLocation',
  PERMISSION_KEY: 'locationPermissionGranted',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  SESSION_CHECK_KEY: 'gpsCheckedThisSession',
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes

  // Translations for modals
  translations: {
    uz: {
      title: '📍 Joylashuv ruxsati kerak',
      message: 'Yaqin atrofdagi masjidlarni topish va qibla yo\'nalishini aniqlash uchun joylashuv ruxsati kerak.',
      instructions: 'Iltimos, sozlamalarda "Geolocation" tugmasini yoqing.',
      openSettings: '⚙️ Sozlamalarni ochish',
      close: '✕ Yopish',
      permissionDenied: 'Joylashuv ruxsati berilmagan',
      enableToggle: 'Bot profilida joylashuv tugmasini yoqing'
    },
    ru: {
      title: '📍 Требуется разрешение геолокации',
      message: 'Для поиска ближайших мечетей и определения направления киблы необходим доступ к местоположению.',
      instructions: 'Пожалуйста, включите переключатель "Geolocation" в настройках.',
      openSettings: '⚙️ Открыть настройки',
      close: '✕ Закрыть',
      permissionDenied: 'Доступ к местоположению не предоставлен',
      enableToggle: 'Включите переключатель местоположения в профиле бота'
    },
    en: {
      title: '📍 Location Permission Required',
      message: 'Location access is needed to find nearby mosques and determine Qibla direction.',
      instructions: 'Please enable the "Geolocation" toggle in settings.',
      openSettings: '⚙️ Open Settings',
      close: '✕ Close',
      permissionDenied: 'Location permission not granted',
      enableToggle: 'Enable location toggle in bot profile'
    }
  },

  // Telegram LocationManager reference
  tgLocationManager: null,
  isLocationManagerAvailable: false,

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
    
    if (typeof Telegram === 'undefined' || !Telegram.WebApp) {
      console.error('❌ Telegram WebApp not available!');
      return;
    }

    Telegram.WebApp.ready();
    Telegram.WebApp.disableVerticalSwipes();
    
    // Check if Telegram's LocationManager is available (Bot API 8.0+)
    this.tgLocationManager = Telegram.WebApp.LocationManager;
    this.isLocationManagerAvailable = !!this.tgLocationManager;

    console.log('📍 Telegram LocationManager available:', this.isLocationManagerAvailable);

    // Inject modal styles
    this.injectModalStyles();
    
    // Initialize Telegram LocationManager if available
    if (this.isLocationManagerAvailable) {
      await this.initTelegramLocationManager();
    } else {
      // Fallback to old browser geolocation API
      console.log('⚠️ Falling back to browser geolocation API');
      await this.initBrowserGeolocation();
    }
  },

  // Initialize Telegram's native LocationManager
  async initTelegramLocationManager() {
    return new Promise((resolve) => {
      // Initialize the LocationManager
      this.tgLocationManager.init(() => {
        console.log('✅ Telegram LocationManager initialized');
        console.log('📍 Location available:', this.tgLocationManager.isLocationAvailable);
        console.log('📍 Access requested:', this.tgLocationManager.isAccessRequested);
        console.log('📍 Access granted:', this.tgLocationManager.isAccessGranted);

        // Listen for location manager updates
        Telegram.WebApp.onEvent('locationManagerUpdated', () => {
          console.log('📍 Location Manager status changed');
          console.log('📍 Access granted:', this.tgLocationManager.isAccessGranted);
          
          // If permission was just granted, immediately get location
          if (this.tgLocationManager.isAccessGranted) {
            this.getTelegramLocation();
          }
        });

        // Check if we have stored location
        const storedLocation = this.getStoredLocation();
        const hasAccess = this.tgLocationManager.isAccessGranted;

        if (hasAccess && !this.isGpsCheckedThisSession()) {
          // We have access and haven't checked this session - get fresh location
          console.log('✅ Permission granted, getting location...');
          this.getTelegramLocation();
        } else if (hasAccess && storedLocation) {
          // We have access and cached location - use cached and optionally refresh
          console.log('✅ Using cached location:', storedLocation.city);
          this.updateUI(storedLocation);
          this.markGpsCheckedThisSession();
          
          // Silent refresh if needed
          this.silentRefreshTelegram();
        } else if (!hasAccess && !this.tgLocationManager.isAccessRequested) {
          // No access and never requested - show prompt to enable toggle
          console.log('📍 No access, showing settings prompt...');
          this.showLocationSettingsPrompt();
        } else if (!hasAccess && storedLocation) {
          // Had access before but lost it - use cached and show prompt
          console.log('⚠️ Lost access, using cached location');
          this.updateUI(storedLocation);
        } else {
          // No access and no cached location
          console.log('❌ No access and no cached location');
          this.showLocationSettingsPrompt();
        }

        resolve();
      });
    });
  },

  // Get location using Telegram's LocationManager
  getTelegramLocation() {
    if (!this.tgLocationManager || !this.tgLocationManager.isAccessGranted) {
      console.log('❌ Cannot get location: no access granted');
      this.showLocationSettingsPrompt();
      return;
    }

    console.log('📡 Requesting location from Telegram...');

    this.tgLocationManager.getLocation(async (location) => {
      if (location === null) {
        console.log('❌ Location request returned null');
        // Use cached location if available
        const cached = this.getStoredLocation();
        if (cached) {
          this.updateUI(cached);
        } else {
          this.showLocationSettingsPrompt();
        }
        return;
      }

      console.log('✅ Got location from Telegram:', location);
      
      // Process the location data
      const locationData = await this.processTelegramLocation(location);
      this.updateUI(locationData);
      this.markGpsCheckedThisSession();
    });
  },

  // Process Telegram location data
  async processTelegramLocation(location) {
    const lat = location.latitude;
    const lon = location.longitude;
    const city = await this.getCityName(lat, lon);
    
    const locationData = {
      lat,
      lon,
      city,
      accuracy: location.horizontal_accuracy,
      altitude: location.altitude,
      timestamp: Date.now()
    };
    
    console.log('💾 Saving location:', locationData.city);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(locationData));
    localStorage.setItem(this.LAST_UPDATE_KEY, locationData.timestamp.toString());
    localStorage.setItem(this.PERMISSION_KEY, 'true');
    
    return locationData;
  },

  // Silent refresh using Telegram LocationManager
  async silentRefreshTelegram() {
    const lastUpdate = parseInt(localStorage.getItem(this.LAST_UPDATE_KEY) || '0');
    const now = Date.now();
    
    // Don't refresh too frequently
    if (now - lastUpdate < this.UPDATE_INTERVAL) {
      console.log('⏱️ Skipping silent refresh (updated recently)');
      return;
    }

    if (!this.tgLocationManager || !this.tgLocationManager.isAccessGranted) {
      console.log('⭕ Skipping silent refresh (no access)');
      return;
    }

    console.log('🔄 Attempting silent background refresh...');
    this.getTelegramLocation();
  },

  // Show prompt to open location settings
  showLocationSettingsPrompt() {
    // Use Telegram's native popup
    Telegram.WebApp.showPopup({
      title: this.t('title'),
      message: this.t('message') + '\n\n' + this.t('instructions'),
      buttons: [
        { id: 'settings', type: 'default', text: this.t('openSettings') },
        { id: 'cancel', type: 'cancel', text: this.t('close') }
      ]
    }, (buttonId) => {
      if (buttonId === 'settings') {
        this.openLocationSettings();
      }
    });
  },

  // Open Telegram's location settings
  openLocationSettings() {
    if (this.tgLocationManager && typeof this.tgLocationManager.openSettings === 'function') {
      console.log('⚙️ Opening Telegram location settings...');
      this.tgLocationManager.openSettings();
    } else {
      console.log('❌ Cannot open settings - not available');
      Telegram.WebApp.showAlert(this.t('enableToggle'));
    }
  },

  // Fallback: Initialize browser geolocation (for older Telegram versions)
  async initBrowserGeolocation() {
    console.log('📍 Using browser geolocation API');
    
    const isMainPage = window.location.pathname.endsWith('index.html') || 
                       window.location.pathname === '/' ||
                       window.location.pathname.endsWith('/');
    
    if (isMainPage && !this.isGpsCheckedThisSession()) {
      console.log('🏠 Main page first load - clearing cached location for fresh check');
      localStorage.removeItem(this.STORAGE_KEY);
      localStorage.removeItem(this.PERMISSION_KEY);
      localStorage.removeItem(this.LAST_UPDATE_KEY);
    }
    
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    const storedLocation = this.getStoredLocation();
    const gpsAlreadyChecked = this.isGpsCheckedThisSession();
    
    if (gpsAlreadyChecked && storedLocation) {
      console.log('✅ GPS already checked this session, using cached location');
      this.updateUI(storedLocation);
      this.silentRefresh();
      return;
    }
    
    if (hasPermission && storedLocation) {
      console.log('📍 First check this session - verifying GPS...');
      this.updateUI(storedLocation);
      await this.verifyGpsAndRefresh(storedLocation);
      return;
    }
    
    if (storedLocation) {
      console.log('📍 Legacy cached location found');
      this.updateUI(storedLocation);
      localStorage.setItem(this.PERMISSION_KEY, 'true');
      this.markGpsCheckedThisSession();
      return;
    }
    
    console.log('🔔 No stored location - requesting permission');
    await this.requestInitialPermission();
  },

  // Verify GPS and refresh (browser API)
  async verifyGpsAndRefresh(fallbackLocation) {
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ GPS verified working');
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          this.markGpsCheckedThisSession();
          resolve(locationData);
        },
        (error) => {
          console.log('⚠️ GPS check failed:', error.message);
          if (error.code === 1 || error.code === 2) {
            this.showGPSModal();
          } else {
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

  // Request initial permission (browser API)
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
          console.log('✅ Got position');
          const locationData = await this.processPosition(pos);
          localStorage.setItem(this.PERMISSION_KEY, 'true');
          this.updateUI(locationData);
          this.hideGPSModal();
          this.markGpsCheckedThisSession();
          resolve(locationData);
        },
        (error) => {
          console.error('❌ Geolocation error:', error.message);
          this.showGPSModal();
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

  // Silent refresh (browser API)
  async silentRefresh() {
    const lastUpdate = parseInt(localStorage.getItem(this.LAST_UPDATE_KEY) || '0');
    const now = Date.now();
    
    if (now - lastUpdate < this.UPDATE_INTERVAL) {
      console.log('⏱️ Skipping silent refresh');
      return;
    }

    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    if (!hasPermission) return;

    console.log('🔄 Silent background refresh...');

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const locationData = await this.processPosition(pos);
        console.log('✅ Location silently refreshed');
        this.updateUI(locationData);
      },
      (error) => {
        console.log('⚠️ Silent refresh failed');
      },
      {
        enableHighAccuracy: false,
        timeout: 5000,
        maximumAge: 600000
      }
    );
  },

  // Manual refresh - works with both APIs
  async manualRefresh() {
    console.log('🔄 Manual refresh initiated');
    
    if (this.isLocationManagerAvailable && this.tgLocationManager.isAccessGranted) {
      // Use Telegram API
      this.getTelegramLocation();
    } else if (this.isLocationManagerAvailable) {
      // Show settings prompt
      this.showLocationSettingsPrompt();
    } else {
      // Use browser API
      const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
      
      if (!hasPermission) {
        return this.requestInitialPermission();
      }

      return new Promise((resolve) => {
        navigator.geolocation.getCurrentPosition(
          async (pos) => {
            const locationData = await this.processPosition(pos);
            this.updateUI(locationData);
            resolve(locationData);
          },
          (error) => {
            console.warn('⚠️ Manual refresh failed');
            if (error.code === 2) {
              this.showGPSModal();
            }
            resolve(this.getStoredLocation());
          },
          {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 0
          }
        );
      });
    }
  },

  // Process position (browser API)
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

  // Get stored location
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

  // Update UI elements
  updateUI(locationData) {
    if (!locationData) return;
    
    const cityElements = document.querySelectorAll('#cityName, .city-name');
    cityElements.forEach(el => {
      if (el) el.innerText = locationData.city;
    });

    const coordsElem = document.getElementById('coords');
    if (coordsElem) {
      coordsElem.innerText = `Koordinatalar: ${locationData.lat.toFixed(4)}, ${locationData.lon.toFixed(4)}`;
    }

    const timestampElem = document.getElementById('locationTimestamp');
    if (timestampElem && locationData.timestamp) {
      const date = new Date(locationData.timestamp);
      timestampElem.innerText = `Oxirgi yangilanish: ${date.toLocaleTimeString()}, ${date.toLocaleDateString()}`;
    }

    if (typeof updatePrayerData === 'function') {
      updatePrayerData(locationData.lat, locationData.lon, locationData.city);
    }

    window.dispatchEvent(new CustomEvent('locationUpdated', { 
      detail: locationData 
    }));
  },

  // Get current location
  getCurrentLocation() {
    return this.getStoredLocation();
  },

  // Check if location is stale
  isLocationStale() {
    const location = this.getStoredLocation();
    if (!location || !location.timestamp) return true;
    
    const age = Date.now() - location.timestamp;
    return age > 24 * 60 * 60 * 1000;
  },

  // Clear stored location
  clearLocation() {
    localStorage.removeItem(this.STORAGE_KEY);
    localStorage.removeItem(this.PERMISSION_KEY);
    localStorage.removeItem(this.LAST_UPDATE_KEY);
    sessionStorage.removeItem(this.SESSION_CHECK_KEY);
    console.log('🗑️ All location data cleared');
  },

  // Modal styles injection
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
      
      .gps-modal-btn-primary {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
      }
      
      .gps-modal-btn-secondary {
        background: rgba(255, 255, 255, 0.1);
        color: rgba(255, 255, 255, 0.8);
      }
    `;
    document.head.appendChild(styles);
  },

  // Show GPS modal (fallback for browser API)
  showGPSModal() {
    this.hideGPSModal();
    
    const overlay = document.createElement('div');
    overlay.className = 'gps-modal-overlay';
    overlay.id = 'gps-modal-overlay';
    
    overlay.innerHTML = `
      <div class="gps-modal">
        <div class="gps-modal-title">${this.t('title')}</div>
        <div class="gps-modal-message">${this.t('message')}<br><br>${this.t('instructions')}</div>
        <div class="gps-modal-buttons">
          <button class="gps-modal-btn gps-modal-btn-primary" onclick="LocationManager.manualRefresh(); LocationManager.hideGPSModal();">
            ${this.t('tryAgain') || '🔄 Try Again'}
          </button>
          <button class="gps-modal-btn gps-modal-btn-secondary" onclick="LocationManager.hideGPSModal()">
            ${this.t('close')}
          </button>
        </div>
      </div>
    `;
    
    document.body.appendChild(overlay);
  },

  // Hide GPS modal
  hideGPSModal() {
    const overlay = document.getElementById('gps-modal-overlay');
    if (overlay) {
      overlay.remove();
    }
  }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  LocationManager.init();
});

// Make available globally
window.LocationManager = LocationManager;
