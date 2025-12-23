// locationManager.js - Updated with Telegram LocationManager and proper GPS/Toggle checks
// Checks: 1) GPS on device, 2) Telegram toggle permission

const LocationManager = {
  STORAGE_KEY: 'userLocation',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  SESSION_CHECK_KEY: 'locationCheckedThisSession',
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes

  // Telegram LocationManager reference
  tgLocationManager: null,
  isLocationManagerAvailable: false,

  // Translations
  translations: {
    uz: {
      gpsTitle: '📍 GPS yoqilmagan',
      gpsMessage: 'Joylashuvingizni aniqlash uchun telefoningizda GPS (Lokatsiya) yoqilgan bo\'lishi kerak.',
      gpsButton: '⚙️ Sozlamalarga o\'tish',
      toggleTitle: '📍 Joylashuv ruxsati kerak',
      toggleMessage: 'Yaqin atrofdagi masjidlarni topish va qibla yo\'nalishini aniqlash uchun joylashuv ruxsati kerak.',
      toggleButton: '⚙️ Sozlamalarni ochish'
    },
    ru: {
      gpsTitle: '📍 GPS выключен',
      gpsMessage: 'Для определения вашего местоположения необходимо включить GPS (Геолокацию) на вашем телефоне.',
      gpsButton: '⚙️ Перейти в настройки',
      toggleTitle: '📍 Требуется разрешение',
      toggleMessage: 'Для поиска ближайших мечетей и определения направления киблы необходим доступ к местоположению.',
      toggleButton: '⚙️ Открыть настройки'
    },
    en: {
      gpsTitle: '📍 GPS is turned off',
      gpsMessage: 'To detect your location, GPS (Location Services) must be enabled on your phone.',
      gpsButton: '⚙️ Open Settings',
      toggleTitle: '📍 Location Permission Needed',
      toggleMessage: 'Location access is needed to find nearby mosques and determine Qibla direction.',
      toggleButton: '⚙️ Open Settings'
    }
  },

  // Get current language
  getCurrentLang() {
    const tg = window.Telegram?.WebApp;
    if (tg?.initDataUnsafe?.user?.language_code) {
      const lang = tg.initDataUnsafe.user.language_code;
      if (['uz', 'ru', 'en'].includes(lang)) return lang;
    }
    if (window.I18N && typeof I18N.getLanguage === 'function') {
      return I18N.getLanguage();
    }
    return 'uz';
  },

  // Get translation
  t(key) {
    const lang = this.getCurrentLang();
    return this.translations[lang]?.[key] || this.translations['en'][key];
  },

  // Check if location was checked this session
  isLocationCheckedThisSession() {
    return sessionStorage.getItem(this.SESSION_CHECK_KEY) === 'true';
  },

  // Mark location as checked
  markLocationCheckedThisSession() {
    sessionStorage.setItem(this.SESSION_CHECK_KEY, 'true');
  },

  // Initialize
  async init() {
    console.log('🚀 LocationManager initializing...');
    
    const tg = window.Telegram?.WebApp;
    if (!tg) {
      console.error('❌ Telegram WebApp not available');
      return;
    }

    tg.ready();
    tg.disableVerticalSwipes();
    
    // Initialize Telegram LocationManager if available
    this.tgLocationManager = tg.LocationManager;
    this.isLocationManagerAvailable = !!this.tgLocationManager;

    console.log('📍 Telegram LocationManager available:', this.isLocationManagerAvailable);

    if (this.isLocationManagerAvailable) {
      await this.initTelegramLocationManager();
    } else {
      await this.initBrowserGeolocation();
    }
  },

  // Initialize Telegram LocationManager
  async initTelegramLocationManager() {
    return new Promise((resolve) => {
      this.tgLocationManager.init(() => {
        console.log('✅ Telegram LocationManager initialized');
        console.log('📍 Access granted:', this.tgLocationManager.isAccessGranted);

        // Listen for permission changes
        const tg = window.Telegram.WebApp;
        tg.onEvent('locationManagerUpdated', () => {
          console.log('📍 Location Manager status changed');
          if (this.tgLocationManager.isAccessGranted) {
            this.getTelegramLocation();
          }
        });

        const storedLocation = this.getStoredLocation();

        if (this.tgLocationManager.isAccessGranted) {
          // Has permission - get location
          if (!this.isLocationCheckedThisSession()) {
            this.getTelegramLocation();
          } else if (storedLocation) {
            this.updateUI(storedLocation);
            this.silentRefreshTelegram();
          }
        } else if (storedLocation) {
          // No permission but has cached data
          this.updateUI(storedLocation);
        }

        this.markLocationCheckedThisSession();
        resolve();
      });
    });
  },

  // Get location using Telegram API
  getTelegramLocation() {
    if (!this.tgLocationManager?.isAccessGranted) {
      console.log('❌ No permission granted');
      return;
    }

    console.log('📡 Requesting location from Telegram...');

    this.tgLocationManager.getLocation(async (location) => {
      if (location === null) {
        console.log('❌ Location returned null');
        const cached = this.getStoredLocation();
        if (cached) this.updateUI(cached);
      } else {
        console.log('✅ Got location from Telegram:', location);
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
      accuracy: location.horizontal_accuracy,
      timestamp: Date.now()
    };
    
    console.log('💾 Saving location:', locationData.city);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(locationData));
    localStorage.setItem(this.LAST_UPDATE_KEY, locationData.timestamp.toString());
    
    return locationData;
  },

  // Silent refresh (Telegram)
  async silentRefreshTelegram() {
    const lastUpdate = parseInt(localStorage.getItem(this.LAST_UPDATE_KEY) || '0');
    const now = Date.now();
    
    if (now - lastUpdate < this.UPDATE_INTERVAL) {
      console.log('⏱️ Skipping silent refresh');
      return;
    }

    if (this.tgLocationManager?.isAccessGranted) {
      console.log('🔄 Silent refresh...');
      this.getTelegramLocation();
    }
  },

  // Initialize browser geolocation (fallback)
  async initBrowserGeolocation() {
    console.log('📍 Using browser geolocation API (fallback)');
    
    const storedLocation = this.getStoredLocation();
    
    if (storedLocation && this.isLocationCheckedThisSession()) {
      this.updateUI(storedLocation);
      this.silentRefreshBrowser();
      return;
    }

    if (storedLocation) {
      this.updateUI(storedLocation);
      await this.verifyGps(storedLocation);
    } else {
      await this.requestBrowserLocation();
    }

    this.markLocationCheckedThisSession();
  },

  // Verify GPS is on
  async verifyGps(fallbackLocation) {
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ GPS verified');
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          resolve(locationData);
        },
        (error) => {
          console.log('⚠️ GPS check failed:', error.message);
          
          // Show GPS modal only on error code 2 (GPS off)
          if (error.code === 2) {
            this.showGPSModal();
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

  // Request browser location
  async requestBrowserLocation() {
    return new Promise((resolve) => {
      if (!navigator.geolocation) {
        console.error('❌ Geolocation not supported');
        resolve(null);
        return;
      }

      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ Got position');
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          resolve(locationData);
        },
        (error) => {
          console.error('❌ Geolocation error:', error.message);
          
          // Only show GPS modal for GPS-off error
          if (error.code === 2) {
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

  // Silent refresh (browser)
  async silentRefreshBrowser() {
    const lastUpdate = parseInt(localStorage.getItem(this.LAST_UPDATE_KEY) || '0');
    const now = Date.now();
    
    if (now - lastUpdate < this.UPDATE_INTERVAL) {
      console.log('⏱️ Skipping silent refresh');
      return;
    }

    console.log('🔄 Silent refresh...');

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const locationData = await this.processPosition(pos);
        console.log('✅ Location refreshed');
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

  // Manual refresh (called by user button)
  async manualRefresh() {
    console.log('🔄 Manual refresh initiated');
    
    if (this.isLocationManagerAvailable && this.tgLocationManager.isAccessGranted) {
      this.getTelegramLocation();
      return;
    }

    if (this.isLocationManagerAvailable && !this.tgLocationManager.isAccessGranted) {
      // Show toggle prompt
      this.showTogglePrompt();
      return;
    }

    // Browser API
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const locationData = await this.processPosition(pos);
          this.updateUI(locationData);
          resolve(locationData);
        },
        (error) => {
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
  },

  // Show GPS modal (device GPS is off)
  showGPSModal() {
    const tg = window.Telegram?.WebApp;
    if (!tg) return;

    tg.showPopup({
      title: this.t('gpsTitle'),
      message: this.t('gpsMessage'),
      buttons: [
        { id: 'settings', type: 'default', text: this.t('gpsButton') },
        { id: 'close', type: 'close' }
      ]
    }, (buttonId) => {
      if (buttonId === 'settings') {
        // Open device settings (this varies by platform)
        tg.openLink('app-settings:');
      }
    });
  },

  // Show toggle prompt (Telegram toggle is off)
  showTogglePrompt() {
    const tg = window.Telegram?.WebApp;
    if (!tg) return;

    // Trigger location request to make toggle appear
    this.tgLocationManager.getLocation(() => {});

    tg.showPopup({
      title: this.t('toggleTitle'),
      message: this.t('toggleMessage'),
      buttons: [
        { id: 'settings', type: 'default', text: this.t('toggleButton') },
        { id: 'close', type: 'close' }
      ]
    }, (buttonId) => {
      if (buttonId === 'settings') {
        if (this.tgLocationManager && typeof this.tgLocationManager.openSettings === 'function') {
          this.tgLocationManager.openSettings();
        } else {
          tg.close();
        }
      }
    });
  },

  // Process position (browser)
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
        'Unknown'
      );
    } catch (error) {
      console.error('Geocoding error:', error);
      return 'Unknown';
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

  // Update UI
  updateUI(locationData) {
    if (!locationData) return;
    
    const cityElements = document.querySelectorAll('#cityName, .city-name');
    cityElements.forEach(el => {
      if (el) el.innerText = locationData.city;
    });

    const coordsElem = document.getElementById('coords');
    if (coordsElem) {
      coordsElem.innerText = `Coordinates: ${locationData.lat.toFixed(4)}, ${locationData.lon.toFixed(4)}`;
    }

    const timestampElem = document.getElementById('locationTimestamp');
    if (timestampElem && locationData.timestamp) {
      const date = new Date(locationData.timestamp);
      timestampElem.innerText = `Last update: ${date.toLocaleTimeString()}, ${date.toLocaleDateString()}`;
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

  // Clear location
  clearLocation() {
    localStorage.removeItem(this.STORAGE_KEY);
    localStorage.removeItem(this.LAST_UPDATE_KEY);
    sessionStorage.removeItem(this.SESSION_CHECK_KEY);
    console.log('🗑️ Location data cleared');
  }
};

// Auto-initialize
document.addEventListener('DOMContentLoaded', () => {
  LocationManager.init();
});

window.LocationManager = LocationManager;
