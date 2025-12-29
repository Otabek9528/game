/* ==========================================
   AD MODAL MANAGER
   Handles ad fetching, display, and user interactions
   ========================================== */

class AdModalManager {
  constructor(apiBaseUrl) {
    this.apiBaseUrl = apiBaseUrl;
    this.sessionKey = 'ad_shown_this_session';
    this.currentAd = null;
    this.modalElement = null;
  }

  /**
   * Initialize ad system - call this on page load
   */
  async init() {
    // Check if ad was already shown this session
    if (this.wasAdShownThisSession()) {
      return;
    }

    // Get user ID from Telegram WebApp
    const userId = this.getTelegramUserId();
    if (!userId) {
      return;
    }

    // Fetch and show ad
    await this.fetchAndShowAd(userId);
  }

  /**
   * Check if ad was shown in current session
   */
  wasAdShownThisSession() {
    return sessionStorage.getItem(this.sessionKey) === 'true';
  }

  /**
   * Mark ad as shown in session
   */
  markAdAsShown() {
    sessionStorage.setItem(this.sessionKey, 'true');
  }

  /**
   * Get Telegram user ID
   */
  getTelegramUserId() {
    try {
      const telegram = window.Telegram?.WebApp;
      if (telegram && telegram.initDataUnsafe?.user?.id) {
        return telegram.initDataUnsafe.user.id;
      }
      return null;
    } catch (error) {
      console.error('[AdModal] Error getting Telegram user ID:', error);
      return null;
    }
  }

  /**
   * Fetch ad from API
   */
  async fetchAd(userId) {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/ads/next?user_id=${userId}`);
      
      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success && data.ad) {
        return data.ad;
      }
      
      return null;
    } catch (error) {
      console.error('[AdModal] Error fetching ad:', error);
      return null;
    }
  }

  /**
   * Fetch and show ad
   */
  async fetchAndShowAd(userId) {
    const ad = await this.fetchAd(userId);
    
    if (!ad) {
      this.markAdAsShown(); // Mark as shown to avoid repeated API calls
      return;
    }

    this.currentAd = ad;
    this.showAdModal(ad, userId);
    this.markAdAsShown();
  }

  /**
   * Create and show ad modal
   */
  showAdModal(ad, userId) {
    // Create modal HTML
    const modalHTML = `
      <div class="ad-modal-overlay" id="adModalOverlay">
        <div class="ad-modal-container">
          <!-- Close Button -->
          <button class="ad-modal-close" id="adModalClose" aria-label="Close">
            ✕
          </button>

          <!-- Ad Image -->
          ${ad.image 
            ? `<img src="../../assets/ads/${ad.image}" alt="Ad" class="ad-modal-image" onerror="this.style.display='none'">` 
            : `<div class="ad-modal-image-placeholder">📢</div>`
          }

          <!-- Ad Content -->
          <div class="ad-modal-content">
            ${ad.view_count ? `
              <div class="ad-modal-stats">
                <span>👁️</span>
                <span>${ad.view_count}</span>
              </div>
            ` : ''}
            
            <div class="ad-modal-html">
              ${ad.html}
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="ad-modal-actions">
            <button class="ad-modal-hide-btn" id="adModalHideBtn">
              ${ad.button_text || "❌ Bu reklamani boshqa ko'rsatma"}
            </button>
          </div>
        </div>
      </div>
    `;

    // Insert modal into DOM
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    this.modalElement = document.getElementById('adModalOverlay');

    // Prevent body scroll
    document.body.style.overflow = 'hidden';

    // Attach event listeners
    this.attachEventListeners(userId);
  }

  /**
   * Attach event listeners to modal buttons
   */
  attachEventListeners(userId) {
    const closeBtn = document.getElementById('adModalClose');
    const hideBtn = document.getElementById('adModalHideBtn');
    const overlay = document.getElementById('adModalOverlay');

    // Close button (X) - just closes modal
    closeBtn?.addEventListener('click', () => {
      this.closeModal();
    });

    // Click outside modal to close
    overlay?.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.closeModal();
      }
    });

    // Hide for 7 days button
    hideBtn?.addEventListener('click', async () => {
      await this.hideAdForUser(userId);
    });

    // ESC key to close
    document.addEventListener('keydown', this.handleEscKey.bind(this));
  }

  /**
   * Handle ESC key press
   */
  handleEscKey(e) {
    if (e.key === 'Escape' && this.modalElement) {
      this.closeModal();
    }
  }

  /**
   * Close modal without hiding ad permanently
   */
  closeModal() {
    if (!this.modalElement) return;

    // Add fade-out animation
    this.modalElement.classList.add('fade-out');

    // Remove modal after animation
    setTimeout(() => {
      this.modalElement?.remove();
      this.modalElement = null;
      document.body.style.overflow = '';
      document.removeEventListener('keydown', this.handleEscKey);
    }, 300);
  }

  /**
   * Hide ad for user (7 days)
   */
  async hideAdForUser(userId) {
    if (!this.currentAd) return;

    const hideBtn = document.getElementById('adModalHideBtn');
    if (hideBtn) {
      hideBtn.disabled = true;
      hideBtn.textContent = 'Yuklanmoqda...';
    }

    try {
      const response = await fetch(`${this.apiBaseUrl}/api/ads/hide`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: userId,
          ad_id: this.currentAd.ad_id,
        }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data = await response.json();

      if (data.success) {
        this.showSuccessMessage();
      } else {
        throw new Error('Failed to hide ad');
      }
    } catch (error) {
      console.error('[AdModal] Error hiding ad:', error);
      
      // Show error message
      if (hideBtn) {
        hideBtn.textContent = '❌ Xatolik yuz berdi';
        setTimeout(() => {
          this.closeModal();
        }, 2000);
      }
    }
  }

  /**
   * Show success message after hiding ad
   */
  showSuccessMessage() {
    const container = this.modalElement?.querySelector('.ad-modal-container');
    if (!container) return;

    // Create success overlay
    const successHTML = `
      <div class="ad-modal-success">
        <div class="ad-modal-success-icon">✅</div>
        <p class="ad-modal-success-text">
          Bu reklama sizga 7 kun davomida ko'rsatilmaydi
        </p>
      </div>
    `;

    container.insertAdjacentHTML('beforeend', successHTML);

    // Close modal after 2 seconds
    setTimeout(() => {
      this.closeModal();
    }, 2000);
  }
}

/* ==========================================
   AUTO-INITIALIZE ON PAGE LOAD
   ========================================== */

// Initialize ad system when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initAdSystem);
} else {
  initAdSystem();
}

function initAdSystem() {
  // Wait a bit for Telegram WebApp to initialize
  setTimeout(() => {
    // Get API base URL from apiConfig.js or use default
    const apiBaseUrl = window.API_BASE_URL || 'https://vegukin-api.duckdns.org';
    
    const adManager = new AdModalManager(apiBaseUrl);
    adManager.init();
  }, 500);
}
