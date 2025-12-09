// homeScreenPrompt.js
// Prompts user to add the web app to their home screen
// - Shows prompt on 3rd visit to index.html
// - Respects 30-day cooldown after dismissal
// - Only prompts if not already added

const HomeScreenPrompt = {
  VISIT_COUNT_KEY: 'homeScreenVisitCount',
  DISMISSED_KEY: 'homeScreenPromptDismissed',
  VISIT_THRESHOLD: 5,
  COOLDOWN_DAYS: 30,

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
    // Only run on main page
    const isMainPage = window.location.pathname.endsWith('index.html') || 
                       window.location.pathname === '/' ||
                       window.location.pathname.endsWith('/');
    
    if (!isMainPage) return;

    // Increment visit count
    this.incrementVisitCount();
    
    // Check if we should show prompt
    this.checkAndShowPrompt();
  },

  // Increment visit counter
  incrementVisitCount() {
    const currentCount = parseInt(localStorage.getItem(this.VISIT_COUNT_KEY) || '0');
    const newCount = currentCount + 1;
    localStorage.setItem(this.VISIT_COUNT_KEY, newCount.toString());
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
    if (visitCount < this.VISIT_THRESHOLD) return;

    // Check 2: Already added
    if (this.isAlreadyAdded()) return;

    // Check 3: Recently dismissed
    if (this.isDismissedRecently()) return;

    // All checks passed - show prompt
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
    this.hidePrompt();

    try {
      Telegram.WebApp.addToHomeScreen();
    } catch (e) {
      console.error('addToHomeScreen failed:', e);
    }
  },

  // Handle "Ignore" button click
  handleIgnore() {
    localStorage.setItem(this.DISMISSED_KEY, Date.now().toString());
    this.hidePrompt();
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
