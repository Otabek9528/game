// homeScreenPrompt.js
// Prompts user to add the web app to their home screen
// - Shows prompt on 3rd visit to index.html
// - Respects 30-day cooldown after dismissal
// - Only prompts if not already added

const HomeScreenPrompt = {
  VISIT_COUNT_KEY: 'homeScreenVisitCount',
  DISMISSED_KEY: 'homeScreenPromptDismissed',
  VISIT_THRESHOLD: 3,
  COOLDOWN_DAYS: 30,
  DEBUG_MODE: true, // Set to false to hide debug panel

  // Debug logs
  debugLogs: [],

  log(message) {
    const timestamp = new Date().toLocaleTimeString();
    console.log(`[${timestamp}] 📱 ${message}`);
    
    if (this.DEBUG_MODE) {
      this.debugLogs.push({ time: timestamp, msg: message });
      this.updateDebugPanel();
    }
  },

  // Initialize debug panel
  initDebugPanel() {
    if (!this.DEBUG_MODE) return;
    if (document.getElementById('hs-debug-panel')) return;

    const panel = document.createElement('div');
    panel.id = 'hs-debug-panel';
    panel.innerHTML = `
      <div class="hs-debug-header">
        <span>📱 HomeScreen Debug</span>
        <button id="hs-debug-toggle">_</button>
        <button id="hs-debug-close">×</button>
      </div>
      <div class="hs-debug-status" id="hs-debug-status">
        <div><strong>Visit Count:</strong> <span id="hs-debug-visits">--</span></div>
        <div><strong>Threshold:</strong> <span id="hs-debug-threshold">${this.VISIT_THRESHOLD}</span></div>
        <div><strong>isAddedToHomeScreen:</strong> <span id="hs-debug-added">--</span></div>
        <div><strong>Dismissed:</strong> <span id="hs-debug-dismissed">--</span></div>
        <div><strong>Should Show:</strong> <span id="hs-debug-should">--</span></div>
      </div>
      <div class="hs-debug-actions">
        <button id="hs-debug-reset">🗑️ Reset All</button>
        <button id="hs-debug-force">🧪 Force Prompt</button>
      </div>
      <div class="hs-debug-logs" id="hs-debug-logs"></div>
    `;

    const style = document.createElement('style');
    style.textContent = `
      #hs-debug-panel {
        position: fixed;
        top: 10px;
        left: 10px;
        right: 10px;
        max-height: 45vh;
        background: rgba(0, 0, 50, 0.95);
        border: 2px solid #00aaff;
        border-radius: 10px;
        font-family: monospace;
        font-size: 11px;
        color: #00aaff;
        z-index: 99998;
        overflow: hidden;
        display: flex;
        flex-direction: column;
      }
      #hs-debug-panel.minimized .hs-debug-status,
      #hs-debug-panel.minimized .hs-debug-actions,
      #hs-debug-panel.minimized .hs-debug-logs {
        display: none;
      }
      .hs-debug-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: #003366;
        border-bottom: 1px solid #00aaff;
        font-weight: bold;
      }
      .hs-debug-header button {
        background: #004488;
        border: 1px solid #00aaff;
        color: #00aaff;
        width: 24px;
        height: 24px;
        border-radius: 4px;
        cursor: pointer;
        margin-left: 5px;
      }
      .hs-debug-status {
        padding: 10px 12px;
        border-bottom: 1px solid #003366;
        line-height: 1.6;
      }
      .hs-debug-status span {
        color: #ffff00;
      }
      .hs-debug-actions {
        padding: 8px 12px;
        display: flex;
        gap: 8px;
        border-bottom: 1px solid #003366;
      }
      .hs-debug-actions button {
        background: #004488;
        border: 1px solid #00aaff;
        color: #00aaff;
        padding: 6px 10px;
        border-radius: 5px;
        cursor: pointer;
        font-size: 11px;
      }
      .hs-debug-logs {
        flex: 1;
        overflow-y: auto;
        padding: 8px 12px;
        max-height: 100px;
      }
      .hs-debug-log-entry {
        padding: 2px 0;
        border-bottom: 1px solid #002244;
      }
      .hs-debug-log-entry .time {
        color: #888;
        margin-right: 8px;
      }
    `;
    document.head.appendChild(style);
    document.body.appendChild(panel);

    // Event listeners
    document.getElementById('hs-debug-toggle').addEventListener('click', () => {
      panel.classList.toggle('minimized');
    });

    document.getElementById('hs-debug-close').addEventListener('click', () => {
      panel.remove();
      this.DEBUG_MODE = false;
    });

    document.getElementById('hs-debug-reset').addEventListener('click', () => {
      localStorage.removeItem(this.VISIT_COUNT_KEY);
      localStorage.removeItem(this.DISMISSED_KEY);
      this.log('All data reset!');
      this.updateDebugStatus();
    });

    document.getElementById('hs-debug-force').addEventListener('click', () => {
      this.log('Forcing prompt display...');
      this.showPrompt();
    });

    this.updateDebugStatus();
  },

  // Update debug status display
  updateDebugStatus() {
    if (!this.DEBUG_MODE) return;

    const visitsEl = document.getElementById('hs-debug-visits');
    const addedEl = document.getElementById('hs-debug-added');
    const dismissedEl = document.getElementById('hs-debug-dismissed');
    const shouldEl = document.getElementById('hs-debug-should');

    const visitCount = this.getVisitCount();
    const isAdded = this.isAlreadyAdded();
    const isDismissed = this.isDismissedRecently();
    const shouldShow = visitCount >= this.VISIT_THRESHOLD && !isAdded && !isDismissed;

    if (visitsEl) visitsEl.textContent = visitCount;
    if (addedEl) addedEl.textContent = isAdded ? 'YES ✅' : 'NO ❌';
    if (dismissedEl) dismissedEl.textContent = isDismissed ? 'YES (in cooldown)' : 'NO';
    if (shouldEl) shouldEl.textContent = shouldShow ? 'YES ✅' : 'NO ❌';
  },

  // Update debug log panel
  updateDebugPanel() {
    const logsContainer = document.getElementById('hs-debug-logs');
    if (!logsContainer) return;

    logsContainer.innerHTML = this.debugLogs
      .slice(-15)
      .map(log => `
        <div class="hs-debug-log-entry">
          <span class="time">${log.time}</span>${log.msg}
        </div>
      `)
      .join('');

    logsContainer.scrollTop = logsContainer.scrollHeight;
  },

  // Translations
  translations: {
    uz: {
      title: 'Bosh ekranga qo\'shish',
      message: 'Ilovani tezroq ochish uchun bosh ekranga qo\'shing.',
      addButton: '➕ Qo\'shish',
      ignoreButton: 'Keyinroq'
    },
    ru: {
      title: 'Добавить на главный экран',
      message: 'Добавьте приложение на главный экран для быстрого доступа.',
      addButton: '➕ Добавить',
      ignoreButton: 'Позже'
    },
    en: {
      title: 'Add to Home Screen',
      message: 'Add the app to your home screen for quick access.',
      addButton: '➕ Add',
      ignoreButton: 'Later'
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

  // Initialize - call this on index.html load
  init() {
    // Initialize debug panel first
    this.initDebugPanel();
    this.log('Initializing...');
    
    // Only run on main page
    const isMainPage = window.location.pathname.endsWith('index.html') || 
                       window.location.pathname === '/' ||
                       window.location.pathname.endsWith('/');
    
    this.log(`Path: ${window.location.pathname}`);
    this.log(`Is main page: ${isMainPage}`);
    
    if (!isMainPage) {
      this.log('Not main page, skipping');
      return;
    }

    // Increment visit count
    this.incrementVisitCount();
    
    // Check if we should show prompt
    this.checkAndShowPrompt();
    
    // Update debug status
    this.updateDebugStatus();
  },

  // Increment visit counter
  incrementVisitCount() {
    const currentCount = parseInt(localStorage.getItem(this.VISIT_COUNT_KEY) || '0');
    const newCount = currentCount + 1;
    localStorage.setItem(this.VISIT_COUNT_KEY, newCount.toString());
    this.log(`Visit count incremented: ${currentCount} → ${newCount}`);
  },

  // Get current visit count
  getVisitCount() {
    return parseInt(localStorage.getItem(this.VISIT_COUNT_KEY) || '0');
  },

  // Check if dismissed within cooldown period
  isDismissedRecently() {
    const dismissedTimestamp = localStorage.getItem(this.DISMISSED_KEY);
    if (!dismissedTimestamp) return false;

    const dismissedDate = parseInt(dismissedTimestamp);
    const now = Date.now();
    const daysSinceDismissed = (now - dismissedDate) / (1000 * 60 * 60 * 24);

    return daysSinceDismissed < this.COOLDOWN_DAYS;
  },

  // Check if already added to home screen
  isAlreadyAdded() {
    try {
      return Telegram.WebApp.isAddedToHomeScreen === true;
    } catch (e) {
      console.log('📱 HomeScreenPrompt: Could not check isAddedToHomeScreen');
      return false;
    }
  },

  // Main check and show logic
  checkAndShowPrompt() {
    const visitCount = this.getVisitCount();
    
    // Check 1: Visit threshold
    if (visitCount < this.VISIT_THRESHOLD) {
      this.log(`Visit count ${visitCount} < ${this.VISIT_THRESHOLD}, not showing`);
      return;
    }

    // Check 2: Already added
    const isAdded = this.isAlreadyAdded();
    this.log(`isAddedToHomeScreen raw value: ${Telegram.WebApp.isAddedToHomeScreen}`);
    if (isAdded) {
      this.log('Already added to home screen, not showing');
      return;
    }

    // Check 3: Recently dismissed
    if (this.isDismissedRecently()) {
      this.log('Dismissed recently, in cooldown period');
      return;
    }

    // All checks passed - show prompt
    this.log('All checks passed - showing prompt!');
    this.showPrompt();
  },

  // Inject modal styles
  injectStyles() {
    if (document.getElementById('homescreen-prompt-styles')) return;

    const styles = document.createElement('style');
    styles.id = 'homescreen-prompt-styles';
    styles.textContent = `
      .homescreen-overlay {
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
        animation: hsModalFadeIn 0.3s ease;
      }
      
      @keyframes hsModalFadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      
      .homescreen-modal {
        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
        border-radius: 20px;
        padding: 24px;
        max-width: 320px;
        width: 100%;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        border: 1px solid rgba(255, 255, 255, 0.1);
        animation: hsModalSlideUp 0.3s ease;
      }
      
      @keyframes hsModalSlideUp {
        from { transform: translateY(20px); opacity: 0; }
        to { transform: translateY(0); opacity: 1; }
      }
      
      .homescreen-icon {
        font-size: 48px;
        text-align: center;
        margin-bottom: 16px;
      }
      
      .homescreen-title {
        color: #fff;
        font-size: 18px;
        font-weight: 600;
        text-align: center;
        margin: 0 0 12px 0;
      }
      
      .homescreen-message {
        color: rgba(255, 255, 255, 0.7);
        font-size: 14px;
        line-height: 1.5;
        text-align: center;
        margin: 0 0 20px 0;
      }
      
      .homescreen-buttons {
        display: flex;
        gap: 10px;
      }
      
      .homescreen-btn {
        flex: 1;
        padding: 12px 16px;
        border-radius: 12px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        border: none;
        transition: all 0.2s ease;
      }
      
      .homescreen-btn:active {
        transform: scale(0.98);
      }
      
      .homescreen-btn-add {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
      }
      
      .homescreen-btn-add:hover {
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
      }
      
      .homescreen-btn-ignore {
        background: rgba(255, 255, 255, 0.1);
        color: rgba(255, 255, 255, 0.7);
        border: 1px solid rgba(255, 255, 255, 0.2);
      }
      
      .homescreen-btn-ignore:hover {
        background: rgba(255, 255, 255, 0.15);
      }
    `;
    document.head.appendChild(styles);
  },

  // Show the prompt modal
  showPrompt() {
    this.injectStyles();
    this.hidePrompt(); // Remove any existing

    const overlay = document.createElement('div');
    overlay.className = 'homescreen-overlay';
    overlay.id = 'homescreen-overlay';

    overlay.innerHTML = `
      <div class="homescreen-modal">
        <div class="homescreen-icon">📱</div>
        <h2 class="homescreen-title">${this.t('title')}</h2>
        <p class="homescreen-message">${this.t('message')}</p>
        
        <div class="homescreen-buttons">
          <button class="homescreen-btn homescreen-btn-add" id="homescreen-add">
            ${this.t('addButton')}
          </button>
          <button class="homescreen-btn homescreen-btn-ignore" id="homescreen-ignore">
            ${this.t('ignoreButton')}
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    // Event listeners
    document.getElementById('homescreen-add').addEventListener('click', () => {
      this.handleAdd();
    });

    document.getElementById('homescreen-ignore').addEventListener('click', () => {
      this.handleIgnore();
    });

    // Close on overlay click
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.handleIgnore();
      }
    });

    // Haptic feedback
    try {
      if (Telegram.WebApp.HapticFeedback) {
        Telegram.WebApp.HapticFeedback.impactOccurred('light');
      }
    } catch (e) {}
  },

  // Hide the prompt modal
  hidePrompt() {
    const overlay = document.getElementById('homescreen-overlay');
    if (overlay) {
      overlay.remove();
    }
  },

  // Handle "Add" button click
  handleAdd() {
    this.log('User clicked Add');
    this.hidePrompt();

    try {
      Telegram.WebApp.addToHomeScreen();
      this.log('addToHomeScreen() called');
    } catch (e) {
      this.log('addToHomeScreen failed: ' + e.message);
    }
  },

  // Handle "Ignore" button click
  handleIgnore() {
    this.log('User clicked Ignore');
    localStorage.setItem(this.DISMISSED_KEY, Date.now().toString());
    this.hidePrompt();
    this.updateDebugStatus();
  }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  // Small delay to let other scripts initialize first
  setTimeout(() => {
    HomeScreenPrompt.init();
  }, 1000);
});

// Make available globally
window.HomeScreenPrompt = HomeScreenPrompt;
