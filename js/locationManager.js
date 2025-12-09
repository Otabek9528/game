// locationManager.js
// Universal location manager for Telegram WebApp
// Works across multiple HTML pages without re-prompting
// Updated with GPS detection and user-friendly notifications

const LocationManager = {
  STORAGE_KEY: 'userLocation',
  PERMISSION_KEY: 'locationPermissionGranted',
  LAST_UPDATE_KEY: 'lastLocationUpdate',
  UPDATE_INTERVAL: 5 * 60 * 1000, // 5 minutes
  DEBUG_MODE: true, // Set to false to hide debug panel in production

  // Debug logger
  debugLogs: [],
  
  log(message, type = 'info') {
    const timestamp = new Date().toLocaleTimeString();
    const logEntry = `[${timestamp}] ${message}`;
    console.log(logEntry);
    
    if (this.DEBUG_MODE) {
      this.debugLogs.push({ time: timestamp, msg: message, type });
      this.updateDebugPanel();
    }
  },

  // Initialize debug panel
  initDebugPanel() {
    if (!this.DEBUG_MODE) return;
    if (document.getElementById('location-debug-panel')) return;

    const panel = document.createElement('div');
    panel.id = 'location-debug-panel';
    panel.innerHTML = `
      <div class="debug-header">
        <span>📍 Location Debug</span>
        <button id="debug-toggle-btn">_</button>
        <button id="debug-close-btn">×</button>
      </div>
      <div class="debug-status" id="debug-status">
        <div><strong>Stored Location:</strong> <span id="debug-stored">checking...</span></div>
        <div><strong>Permission:</strong> <span id="debug-permission">checking...</span></div>
        <div><strong>Current City:</strong> <span id="debug-city">--</span></div>
        <div><strong>Coordinates:</strong> <span id="debug-coords">--</span></div>
        <div><strong>Last Update:</strong> <span id="debug-timestamp">--</span></div>
      </div>
      <div class="debug-actions">
        <button id="debug-refresh-btn">🔄 Refresh Location</button>
        <button id="debug-clear-btn">🗑️ Clear Storage</button>
        <button id="debug-test-modal-btn">🧪 Test Modal</button>
      </div>
      <div class="debug-logs" id="debug-logs"></div>
    `;

    const style = document.createElement('style');
    style.textContent = `
      #location-debug-panel {
        position: fixed;
        bottom: 10px;
        left: 10px;
        right: 10px;
        max-height: 50vh;
        background: rgba(0, 0, 0, 0.95);
        border: 2px solid #00ff00;
        border-radius: 10px;
        font-family: monospace;
        font-size: 11px;
        color: #00ff00;
        z-index: 99999;
        overflow: hidden;
        display: flex;
        flex-direction: column;
      }
      #location-debug-panel.minimized .debug-status,
      #location-debug-panel.minimized .debug-actions,
      #location-debug-panel.minimized .debug-logs {
        display: none;
      }
      .debug-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: #003300;
        border-bottom: 1px solid #00ff00;
        font-weight: bold;
      }
      .debug-header button {
        background: #004400;
        border: 1px solid #00ff00;
        color: #00ff00;
        width: 24px;
        height: 24px;
        border-radius: 4px;
        cursor: pointer;
        margin-left: 5px;
      }
      .debug-status {
        padding: 10px 12px;
        border-bottom: 1px solid #004400;
        line-height: 1.6;
      }
      .debug-status span {
        color: #ffff00;
      }
      .debug-actions {
        padding: 8px 12px;
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
        border-bottom: 1px solid #004400;
      }
      .debug-actions button {
        background: #004400;
        border: 1px solid #00ff00;
        color: #00ff00;
        padding: 6px 10px;
        border-radius: 5px;
        cursor: pointer;
        font-size: 11px;
      }
      .debug-actions button:active {
        background: #006600;
      }
      .debug-logs {
        flex: 1;
        overflow-y: auto;
        padding: 8px 12px;
        max-height: 150px;
      }
      .debug-log-entry {
        padding: 2px 0;
        border-bottom: 1px solid #002200;
      }
      .debug-log-entry.error {
        color: #ff4444;
      }
      .debug-log-entry.success {
        color: #44ff44;
      }
      .debug-log-entry.warning {
        color: #ffaa00;
      }
      .debug-log-entry .time {
        color: #888;
        margin-right: 8px;
      }
    `;
    document.head.appendChild(style);
    document.body.appendChild(panel);

    // Event listeners
    document.getElementById('debug-toggle-btn').addEventListener('click', () => {
      panel.classList.toggle('minimized');
    });
    
    document.getElementById('debug-close-btn').addEventListener('click', () => {
      panel.remove();
      this.DEBUG_MODE = false;
    });

    document.getElementById('debug-refresh-btn').addEventListener('click', () => {
      this.log('Manual refresh triggered by debug panel', 'info');
      this.manualRefresh();
    });

    document.getElementById('debug-clear-btn').addEventListener('click', () => {
      this.clearLocation();
      this.updateDebugStatus();
      this.log('Storage cleared!', 'warning');
    });

    document.getElementById('debug-test-modal-btn').addEventListener('click', () => {
      this.log('Testing GPS modal...', 'info');
      this.showGPSModal();
    });

    this.updateDebugStatus();
  },

  // Update debug status display
  updateDebugStatus() {
    if (!this.DEBUG_MODE) return;

    const stored = this.getStoredLocation();
    const permission = localStorage.getItem(this.PERMISSION_KEY);

    const storedEl = document.getElementById('debug-stored');
    const permEl = document.getElementById('debug-permission');
    const cityEl = document.getElementById('debug-city');
    const coordsEl = document.getElementById('debug-coords');
    const timestampEl = document.getElementById('debug-timestamp');

    if (storedEl) {
      storedEl.textContent = stored ? 'YES ✅' : 'NO ❌';
    }
    if (permEl) {
      permEl.textContent = permission === 'true' ? 'GRANTED ✅' : 'NOT GRANTED ❌';
    }
    if (cityEl && stored) {
      cityEl.textContent = stored.city || '--';
    }
    if (coordsEl && stored) {
      coordsEl.textContent = stored.lat && stored.lon 
        ? `${stored.lat.toFixed(4)}, ${stored.lon.toFixed(4)}` 
        : '--';
    }
    if (timestampEl && stored && stored.timestamp) {
      const date = new Date(stored.timestamp);
      timestampEl.textContent = date.toLocaleString();
    }
  },

  // Update debug log panel
  updateDebugPanel() {
    const logsContainer = document.getElementById('debug-logs');
    if (!logsContainer) return;

    logsContainer.innerHTML = this.debugLogs
      .slice(-20) // Keep last 20 logs
      .map(log => `
        <div class="debug-log-entry ${log.type}">
          <span class="time">${log.time}</span>${log.msg}
        </div>
      `)
      .join('');
    
    logsContainer.scrollTop = logsContainer.scrollHeight;
  },

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
    // Initialize debug panel first
    this.initDebugPanel();
    this.log('🚀 LocationManager initializing...', 'info');
    
    Telegram.WebApp.ready();
    Telegram.WebApp.disableVerticalSwipes();
    
    // Inject modal styles
    this.injectModalStyles();
    
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    const storedLocation = this.getStoredLocation();
    
    this.log(`Permission flag: ${hasPermission}`, 'info');
    this.log(`Stored location: ${storedLocation ? storedLocation.city : 'NONE'}`, 'info');
    
    if (hasPermission && storedLocation) {
      this.log('✅ Using stored location: ' + storedLocation.city, 'success');
      // Use cached location immediately
      this.updateUI(storedLocation);
      this.updateDebugStatus();
      
      // Try silent background refresh (won't prompt)
      this.silentRefresh();
    } else if (storedLocation) {
      // Have location but no permission flag (legacy case)
      this.log('📍 Using cached location (no permission flag)', 'warning');
      this.updateUI(storedLocation);
      localStorage.setItem(this.PERMISSION_KEY, 'true');
      this.updateDebugStatus();
    } else {
      // First time - need to ask for permission
      this.log('🔔 No stored location - requesting permission', 'warning');
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
    this.log('🔔 Showing GPS modal to user', 'warning');
    
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
    this.log('📡 Requesting geolocation permission...', 'info');
    
    return new Promise((resolve) => {
      // First check if geolocation is available
      if (!navigator.geolocation) {
        this.log('❌ Geolocation API not supported!', 'error');
        this.showGPSModal();
        resolve(null);
        return;
      }

      this.log('⏳ Calling getCurrentPosition...', 'info');

      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          this.log(`✅ Got position: ${pos.coords.latitude}, ${pos.coords.longitude}`, 'success');
          const locationData = await this.processPosition(pos);
          localStorage.setItem(this.PERMISSION_KEY, 'true');
          this.updateUI(locationData);
          this.updateDebugStatus();
          this.hideGPSModal();
          resolve(locationData);
        },
        (error) => {
          this.log(`❌ Geolocation error: code=${error.code}, msg=${error.message}`, 'error');
          
          // Error codes:
          // 1 = PERMISSION_DENIED - user clicked deny
          // 2 = POSITION_UNAVAILABLE - GPS is off or not available
          // 3 = TIMEOUT - took too long
          
          if (error.code === 1) {
            this.log('🚫 PERMISSION_DENIED - User denied permission', 'error');
            this.showGPSModal();
          } else if (error.code === 2) {
            this.log('📍 POSITION_UNAVAILABLE - GPS appears to be OFF', 'error');
            this.showGPSModal();
          } else if (error.code === 3) {
            this.log('⏱️ TIMEOUT - Location request timed out', 'error');
            this.showGPSModal();
          }
          
          this.updateDebugStatus();
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
      this.log('⏱️ Skipping refresh (too soon)', 'info');
      return;
    }

    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    if (!hasPermission) {
      this.log('⭕ Skipping silent refresh (no permission)', 'warning');
      return;
    }

    this.log('🔄 Attempting silent refresh...', 'info');

    // Try to get new position silently using cached data
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const locationData = await this.processPosition(pos);
        this.log('✅ Location refreshed silently: ' + locationData.city, 'success');
        this.updateUI(locationData);
        this.updateDebugStatus();
      },
      (error) => {
        this.log(`⚠️ Silent refresh failed: ${error.message}`, 'warning');
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
    this.log('🔄 Manual refresh initiated', 'info');
    
    // Check if we have permission already
    const hasPermission = localStorage.getItem(this.PERMISSION_KEY) === 'true';
    
    if (!hasPermission) {
      this.log('⚠️ No permission yet, will prompt user', 'warning');
      return this.requestInitialPermission();
    }
    
    this.log('✅ Have permission, getting position...', 'info');

    return new Promise((resolve) => {
      const options = {
        enableHighAccuracy: false,
        timeout: 5000,
        maximumAge: Infinity // Accept ANY cached position to avoid prompting
      };

      this.log('📡 Getting cached position...', 'info');
      
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          this.log(`✅ Got position: ${pos.coords.latitude}, ${pos.coords.longitude}`, 'success');
          
          try {
            const locationData = await this.processPosition(pos);
            this.log('✅ Location updated: ' + locationData.city, 'success');
            
            this.updateUI(locationData);
            this.updateDebugStatus();
            resolve(locationData);
          } catch (error) {
            this.log('❌ Error processing position: ' + error, 'error');
            resolve(this.getStoredLocation());
          }
        },
        (error) => {
          this.log(`⚠️ Could not get position: code=${error.code}, ${error.message}`, 'warning');
          
          // GPS might be off now - show modal
          if (error.code === 2) {
            this.log('📍 GPS is OFF - showing modal', 'error');
            this.showGPSModal();
            resolve(null);
          } else {
            // Try using stored location
            const stored = this.getStoredLocation();
            if (stored) {
              this.log('📍 Using stored location: ' + stored.city, 'info');
              this.updateUI(stored);
              resolve(stored);
            } else {
              this.log('❌ No stored location - showing modal', 'error');
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
    
    this.log(`🌍 Processing position: ${lat.toFixed(4)}, ${lon.toFixed(4)}`, 'info');
    
    const city = await this.getCityName(lat, lon);
    
    this.log(`🏙️ City resolved: ${city}`, 'success');
    
    const locationData = {
      lat,
      lon,
      city,
      timestamp: Date.now()
    };
    
    this.log('💾 Saving to localStorage...', 'info');
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
    this.log('🗑️ All location data cleared from storage', 'warning');
  }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  LocationManager.init();
});

// Make available globally
window.LocationManager = LocationManager;
