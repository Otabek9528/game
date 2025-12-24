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
  locationCallCount: 0, // Track how many times getTelegramLocation is called

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
        
        // Listen for permission changes
        tg.onEvent('locationManagerUpdated', () => {
          console.log('📍 Permission changed');
          if (this.tgLocationManager.isAccessGranted && !this.isRequestingLocation) {
            this.getTelegramLocation();
          }
        });

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
    // Increment and show call counter
    this.locationCallCount++;
    
    // Show visual feedback on screen
    const cityElements = document.querySelectorAll('#cityName, .city-name');
    cityElements.forEach(el => {
      if (el) el.innerText = `🔴 DEBUG: Called ${this.locationCallCount} times`;
    });
    
    // Prevent multiple simultaneous requests
    if (this.isRequestingLocation) {
      console.log('⏭️ Location request already in progress, skipping...');
      console.trace('Called from:');
      return;
    }

    console.log('📡 Requesting location from Telegram...');
    console.trace('Called from:');
    this.isRequestingLocation = true;

    // Set a timeout to close app if GPS fails
    const gpsTimeout = setTimeout(() => {
      console.log('⏱️ GPS timeout - closing app');
      const tg = Telegram.WebApp;
      tg.close();
    }, 3000); // Close after 3 seconds if no response

    this.tgLocationManager.getLocation(async (location) => {
      clearTimeout(gpsTimeout); // Cancel timeout on success
      this.isRequestingLocation = false;
      this.hideLoadingState();
      
      if (location === null) {
        console.log('❌ Location null - GPS might be off');
        // Close immediately
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
      uz: 'Joylashuv xususiyatlaridan foydalanish uchun bot sozlamalarida joylashuvga ruxsat bering va ilovani qayta oching.',
      ru: 'Чтобы использовать функции на основе местоположения, включите доступ к местоположению в настройках бота и перезапустите приложение.',
      en: 'To use location features, please enable location access in bot settings and reopen the app.'
    };
    
    const message = messages[userLang] || messages['en'];
    
    tg.showPopup({
      title: '📍 Location Access Needed',
      message: message,
      buttons: [
        { id: 'settings', type: 'default', text: 'Open Settings' }
      ]
    }, (buttonId) => {
      if (buttonId === 'settings') {
        // Close the app - user will land on bot settings
        tg.close();
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

  // ============================================
  // UTILITY METHODS
  // ============================================

  getCurrentLang() {
    if (window.I18N && typeof I18N.getLanguage === 'function') {
      return I18N.getLanguage();
    }
    return localStorage.getItem('appLanguage') || 'uz';
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