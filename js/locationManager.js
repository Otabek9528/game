// locationManager.js
// Universal location manager for Telegram WebApp
// Works across multiple HTML pages without re-prompting
// Updated with GPS detection and user-friendly notifications

const LocationManager = {
  STORAGE_KEY: 'userLocation',
  PERMISSION_KEY: 'locationPermissionGranted',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes

  // Translations for the GPS modal
  translations: {
    uz: {
      title: '📍 GPS yoqilmagan',
      message: 'Joylashuvingizni aniqlash uchun telefoningizda GPS (Lokatsiya) yoqilgan bo\'lishi kerak.',
      instructions: 'Iltimos, quyidagi tugmani bosing yoki telefoningiz sozlamalaridan GPS ni yoqing.',
      openSettings: '⚙️ Sozlamalarni ochish',
      tryAgain: '🔄 Qayta urinish',
      close: '✕ Yopish',
      gpsOffError: 'GPS o\'chirilgan. Iltimos, yoqing va qayta urining.'
    },
    ru: {
      title: '📍 GPS выключен',
      message: 'Для определения вашего местоположения необходимо включить GPS (Геолокацию) на вашем телефоне.',
      instructions: 'Пожалуйста, нажмите кнопку ниже или включите GPS в настройках телефона.',
      openSettings: '⚙️ Открыть настройки',
      tryAgain: '🔄 Попробовать снова',
      close: '✕ Закрыть',
      gpsOffError: 'GPS выключен. Пожалуйста, включите и попробуйте снова.'
    },
    en: {
      title: '📍 GPS is turned off',
      message: 'To detect your location, GPS (Location Services) must be enabled on your phone.',
      instructions: 'Please tap the button below or enable GPS in your phone settings.',
      openSettings: '⚙️ Open Settings',
      tryAgain: '🔄 Try Again',
      close: '✕ Close',
      gpsOffError: 'GPS is off. Please enable it and try again.'
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

  // Initialize on every page load
  async init() {
    Telegram.WebApp.ready();
    Telegram.WebApp.disableVerticalSwipes();
    
    // Inject modal styles
    this.injectModalStyles();
    
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    const storedLocation = this.getStoredLocation();
    
    if (hasPermission && storedLocation) {
      console.log('✅ Using stored location');
      // Use cached location immediately
      this.updateUI(storedLocation);
      
      // Try silent background refresh (won't prompt)
      this.silentRefresh();
    } else if (storedLocation) {
      // Have location but no permission flag (legacy case)
      console.log('📍 Using cached location (no permission flag)');
      this.updateUI(storedLocation);
      localStorage.setItem(this.PERMISSION_KEY, 'true');
    } else {
      // First time - need to ask for permission
      console.log('🔔 First time - requesting permission');
      await this.requestInitialPermission();
    }
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
      
      .gps-modal-btn-secondary {
        background: rgba(255, 255, 255, 0.1);
        color: white;
        border: 1px solid rgba(255, 255, 255, 0.2);
      }
      
      .gps-modal-btn-secondary:hover {
        background: rgba(255, 255, 255, 0.15);
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
      
      .gps-modal-help {
        margin-top: 16px;
        padding-top: 16px;
        border-top: 1px solid rgba(255, 255, 255, 0.1);
      }
      
      .gps-modal-help-title {
        color: rgba(255, 255, 255, 0.6);
        font-size: 12px;
        margin: 0 0 8px 0;
        text-align: center;
      }
      
      .gps-modal-steps {
        color: rgba(255, 255, 255, 0.5);
        font-size: 11px;
        line-height: 1.6;
        margin: 0;
        padding-left: 16px;
      }
      
      .gps-modal-steps li {
        margin-bottom: 4px;
      }
    `;
    document.head.appendChild(styles);
  },

  // Show GPS off modal
  showGPSModal() {
    // Remove existing modal if any
    this.hideGPSModal();
    
    const isAndroid = /android/i.test(navigator.userAgent);
    const isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent);
    
    const overlay = document.createElement('div');
    overlay.className = 'gps-modal-overlay';
    overlay.id = 'gps-modal-overlay';
    
    // Manual steps based on platform
    let manualSteps = '';
    if (isAndroid) {
      manualSteps = `
        <div class="gps-modal-help">
          <p class="gps-modal-help-title">Android:</p>
          <ol class="gps-modal-steps">
            <li>Yuqoridan pastga suring</li>
            <li>"Location" yoki "GPS" tugmasini bosing</li>
            <li>Qayta urining</li>
          </ol>
        </div>
      `;
    } else if (isIOS) {
      manualSteps = `
        <div class="gps-modal-help">
          <p class="gps-modal-help-title">iPhone:</p>
          <ol class="gps-modal-steps">
            <li>Settings → Privacy → Location Services</li>
            <li>Location Services ni yoqing</li>
            <li>Telegram uchun "While Using" tanlang</li>
          </ol>
        </div>
      `;
    }
    
    overlay.innerHTML = `
      <div class="gps-modal">
        <div class="gps-modal-icon">📍</div>
        <h2 class="gps-modal-title">${this.t('title')}</h2>
        <p class="gps-modal-message">${this.t('message')}</p>
        <p class="gps-modal-instructions">${this.t('instructions')}</p>
        
        <div class="gps-modal-buttons">
          ${isAndroid ? `
            <button class="gps-modal-btn gps-modal-btn-primary" id="gps-open-settings">
              ${this.t('openSettings')}
            </button>
          ` : ''}
          <button class="gps-modal-btn gps-modal-btn-secondary" id="gps-try-again">
            ${this.t('tryAgain')}
          </button>
          <button class="gps-modal-btn gps-modal-btn-close" id="gps-close">
            ${this.t('close')}
          </button>
        </div>
        
        ${manualSteps}
      </div>
    `;
    
    document.body.appendChild(overlay);
    
    // Event listeners
    const openSettingsBtn = document.getElementById('gps-open-settings');
    if (openSettingsBtn) {
      openSettingsBtn.addEventListener('click', () => {
        this.openLocationSettings();
      });
    }
    
    document.getElementById('gps-try-again').addEventListener('click', () => {
      this.hideGPSModal();
      this.requestInitialPermission();
    });
    
    document.getElementById('gps-close').addEventListener('click', () => {
      this.hideGPSModal();
    });
    
    // Close on overlay click
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.hideGPSModal();
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

  // Open device location settings (Android only - deep linking)
  openLocationSettings() {
    const isAndroid = /android/i.test(navigator.userAgent);
    
    if (isAndroid) {
      // Try Android intent URL
      // This works in many Android browsers and Telegram
      const settingsUrls = [
        'intent://settings/location#Intent;scheme=android-app;end',
        'app-settings:',
      ];
      
      // Try opening Telegram's location settings request
      try {
        if (Telegram.WebApp.openLink) {
          // This might prompt user to enable location
          Telegram.WebApp.openLink('https://telegram.org', { try_instant_view: false });
        }
      } catch (e) {
        console.log('Could not open via Telegram');
      }
      
      // Show alert with instructions since direct settings access is limited
      try {
        if (Telegram.WebApp.showAlert) {
          const lang = this.getCurrentLang();
          const messages = {
            uz: 'Telefoningiz sozlamalarini oching:\n\n1. Yuqoridan pastga suring\n2. GPS/Location tugmasini bosing\n3. Ilovaga qayting va "Qayta urinish" bosing',
            ru: 'Откройте настройки телефона:\n\n1. Потяните сверху вниз\n2. Нажмите кнопку GPS/Локация\n3. Вернитесь в приложение и нажмите "Попробовать снова"',
            en: 'Open your phone settings:\n\n1. Swipe down from top\n2. Tap GPS/Location button\n3. Return to app and tap "Try Again"'
          };
          Telegram.WebApp.showAlert(messages[lang] || messages['en']);
        }
      } catch (e) {
        alert('Please enable GPS in your phone settings, then tap "Try Again"');
      }
    } else {
      // iOS - can't open settings directly, show instructions
      try {
        if (Telegram.WebApp.showAlert) {
          const lang = this.getCurrentLang();
          const messages = {
            uz: 'iPhone sozlamalarini oching:\n\nSettings → Privacy → Location Services → On\n\nKeyin Telegram uchun "While Using the App" tanlang',
            ru: 'Откройте настройки iPhone:\n\nНастройки → Конфиденциальность → Службы геолокации → Вкл\n\nЗатем выберите "При использовании" для Telegram',
            en: 'Open iPhone Settings:\n\nSettings → Privacy → Location Services → On\n\nThen select "While Using the App" for Telegram'
          };
          Telegram.WebApp.showAlert(messages[lang] || messages['en']);
        }
      } catch (e) {
        alert('Please enable Location Services in Settings → Privacy → Location Services');
      }
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
    return new Promise((resolve) => {
      // First check if geolocation is available
      if (!navigator.geolocation) {
        console.error('❌ Geolocation not supported');
        this.showGPSModal();
        resolve(null);
        return;
      }

      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const locationData = await this.processPosition(pos);
          localStorage.setItem(this.PERMISSION_KEY, 'true');
          this.updateUI(locationData);
          this.hideGPSModal();
          resolve(locationData);
        },
        (error) => {
          console.error('❌ Location error:', error.code, error.message);
          
          // Error codes:
          // 1 = PERMISSION_DENIED - user clicked deny
          // 2 = POSITION_UNAVAILABLE - GPS is off or not available
          // 3 = TIMEOUT - took too long
          
          if (error.code === 1) {
            // User denied permission - show modal explaining why we need it
            console.log('🚫 User denied permission');
            this.showGPSModal();
          } else if (error.code === 2) {
            // GPS is off or position unavailable
            console.log('📍 GPS appears to be off');
            this.showGPSModal();
          } else if (error.code === 3) {
            // Timeout - GPS might be slow or off
            console.log('⏱️ Location request timed out');
            this.showGPSModal();
          }
          
          // Don't set a fallback location - let user fix the issue
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

  // Silent refresh (no permission prompt after initial grant)
  async silentRefresh() {
    const lastUpdate = parseInt(localStorage.getItem(this.LAST_UPDATE_KEY) || '0');
    const now = Date.now();
    
    // Don't refresh too frequently
    if (now - lastUpdate < this.UPDATE_INTERVAL) {
      console.log('⏱️ Skipping refresh (too soon)');
      return;
    }

    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    if (!hasPermission) {
      console.log('⭕ Skipping silent refresh (no permission)');
      return;
    }

    // Try to get new position silently using cached data
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const locationData = await this.processPosition(pos);
        console.log('🔄 Location refreshed silently');
        this.updateUI(locationData);
      },
      (error) => {
        console.log('⚠️ Silent refresh failed (using cached):', error.message);
        // Continue using cached location - don't update anything
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
    
    // Check if we have permission already
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    
    if (!hasPermission) {
      console.log('⚠️ No permission yet, will prompt user');
      return this.requestInitialPermission();
    }
    
    // We have permission - try to use any cached position first
    console.log('✅ Using existing permission with cached position');

    return new Promise((resolve) => {
      const options = {
        enableHighAccuracy: false,
        timeout: 5000,
        maximumAge: Infinity // Accept ANY cached position to avoid prompting
      };

      console.log('📡 Getting cached position...');
      
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          console.log('✅ Got cached position (no prompt)');
          
          try {
            const locationData = await this.processPosition(pos);
            console.log('✅ Location updated successfully');
            
            this.updateUI(locationData);
            resolve(locationData);
          } catch (error) {
            console.error('❌ Error processing position:', error);
            resolve(this.getStoredLocation());
          }
        },
        (error) => {
          console.warn('⚠️ Could not get position:', error.message);
          
          // GPS might be off now - show modal
          if (error.code === 2) {
            this.showGPSModal();
            resolve(null);
          } else {
            // Try using stored location
            const stored = this.getStoredLocation();
            if (stored) {
              console.log('📍 Using stored location');
              this.updateUI(stored);
              resolve(stored);
            } else {
              this.showGPSModal();
              resolve(null);
            }
          }
        },
        options
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
    
    console.log('💾 Saving to localStorage:', locationData);
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
    console.log('🗑️ Location data cleared');
  }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  LocationManager.init();
});

// Make available globally
window.LocationManager = LocationManager;
