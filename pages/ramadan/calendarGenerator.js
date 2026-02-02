/**
 * RAMADAN 2026 - Calendar Image Generator (Frontend)
 * Calls backend API to generate calendar image
 */

// ===========================================
// CONFIGURATION
// ===========================================

const CalendarGenerator = {
  // API endpoint - UPDATE THIS TO YOUR ACTUAL API URL
  API_URL: 'https://vegukin-api.duckdns.org/api/ramadan/calendar-image',
  
  // ===========================================
  // MAIN FUNCTION
  // ===========================================
  
  async generate(lat, lon, cityName) {
    console.log('📅 Generating calendar for:', cityName);
    
    // Show loading state
    if (window.RamadanPage) {
      window.RamadanPage.showLoading('Taqvim yaratilmoqda...');
    }
    
    try {
      // Build URL with parameters
      const params = new URLSearchParams({
        lat: lat.toString(),
        lon: lon.toString(),
        city: cityName
      });
      
      const url = `${this.API_URL}?${params.toString()}`;
      
      // Fetch the image
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }
      
      // Get image as blob
      const blob = await response.blob();
      
      // Create object URL for the image
      const imageUrl = URL.createObjectURL(blob);
      
      // Hide loading
      if (window.RamadanPage) {
        window.RamadanPage.hideLoading();
      }
      
      // Show the image to user
      this.showCalendarImage(imageUrl, cityName);
      
      return imageUrl;
      
    } catch (error) {
      console.error('❌ Calendar generation failed:', error);
      
      // Hide loading
      if (window.RamadanPage) {
        window.RamadanPage.hideLoading();
      }
      
      // Show error
      this.showError(error.message);
      
      return null;
    }
  },
  
  // ===========================================
  // UI FUNCTIONS
  // ===========================================
  
  showCalendarImage(imageUrl, cityName) {
    // Create modal overlay
    const modal = document.createElement('div');
    modal.className = 'calendar-modal';
    modal.innerHTML = `
      <div class="calendar-modal-backdrop"></div>
      <div class="calendar-modal-content">
        <div class="calendar-modal-header">
          <h3>📅 Ramazon Taqvimi</h3>
          <button class="calendar-modal-close" aria-label="Yopish">✕</button>
        </div>
        <div class="calendar-modal-body">
          <img src="${imageUrl}" alt="Ramazon 2026 Taqvimi - ${cityName}" class="calendar-image" />
        </div>
        <div class="calendar-modal-actions">
          <button class="calendar-btn calendar-btn-download">
            <span>💾</span> Saqlash
          </button>
          <button class="calendar-btn calendar-btn-share">
            <span>📤</span> Ulashish
          </button>
        </div>
      </div>
    `;
    
    // Add styles if not already present
    if (!document.getElementById('calendar-modal-styles')) {
      const styles = document.createElement('style');
      styles.id = 'calendar-modal-styles';
      styles.textContent = `
        .calendar-modal {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          z-index: 1000;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 16px;
        }
        
        .calendar-modal-backdrop {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.85);
          backdrop-filter: blur(8px);
        }
        
        .calendar-modal-content {
          position: relative;
          background: #1a2d42;
          border-radius: 16px;
          max-width: 100%;
          max-height: 90vh;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          border: 1px solid rgba(244, 197, 66, 0.2);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
        }
        
        .calendar-modal-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 12px 16px;
          border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .calendar-modal-header h3 {
          margin: 0;
          font-size: 16px;
          color: #f4c542;
        }
        
        .calendar-modal-close {
          background: rgba(255, 255, 255, 0.1);
          border: none;
          color: #94a3b8;
          width: 32px;
          height: 32px;
          border-radius: 8px;
          cursor: pointer;
          font-size: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .calendar-modal-close:hover {
          background: rgba(255, 255, 255, 0.2);
          color: #fff;
        }
        
        .calendar-modal-body {
          flex: 1;
          overflow: auto;
          padding: 16px;
          display: flex;
          justify-content: center;
        }
        
        .calendar-image {
          max-width: 100%;
          height: auto;
          border-radius: 12px;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
        }
        
        .calendar-modal-actions {
          display: flex;
          gap: 12px;
          padding: 12px 16px;
          border-top: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .calendar-btn {
          flex: 1;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          padding: 12px 16px;
          border: none;
          border-radius: 10px;
          font-family: inherit;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
        }
        
        .calendar-btn-download {
          background: linear-gradient(135deg, #10b981, #059669);
          color: white;
        }
        
        .calendar-btn-download:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
        }
        
        .calendar-btn-share {
          background: linear-gradient(135deg, #f4c542, #eab308);
          color: #1a1a2e;
        }
        
        .calendar-btn-share:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(244, 197, 66, 0.3);
        }
      `;
      document.head.appendChild(styles);
    }
    
    // Add to document
    document.body.appendChild(modal);
    
    // Event listeners
    const closeBtn = modal.querySelector('.calendar-modal-close');
    const backdrop = modal.querySelector('.calendar-modal-backdrop');
    const downloadBtn = modal.querySelector('.calendar-btn-download');
    const shareBtn = modal.querySelector('.calendar-btn-share');
    
    const closeModal = () => {
      modal.remove();
      URL.revokeObjectURL(imageUrl);
    };
    
    closeBtn.addEventListener('click', closeModal);
    backdrop.addEventListener('click', closeModal);
    
    // Download button
    downloadBtn.addEventListener('click', () => {
      this.downloadImage(imageUrl, cityName);
    });
    
    // Share button
    shareBtn.addEventListener('click', async () => {
      await this.shareImage(imageUrl, cityName);
    });
    
    // Haptic feedback
    if (window.Telegram?.WebApp?.HapticFeedback) {
      window.Telegram.WebApp.HapticFeedback.impactOccurred('medium');
    }
  },
  
  downloadImage(imageUrl, cityName) {
    const link = document.createElement('a');
    link.href = imageUrl;
    link.download = `ramadan_2026_${cityName.replace(/\s+/g, '_')}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // Haptic feedback
    if (window.Telegram?.WebApp?.HapticFeedback) {
      window.Telegram.WebApp.HapticFeedback.notificationOccurred('success');
    }
  },
  
  async shareImage(imageUrl, cityName) {
    try {
      // Fetch the image as blob for sharing
      const response = await fetch(imageUrl);
      const blob = await response.blob();
      const file = new File([blob], `ramadan_2026_${cityName.replace(/\s+/g, '_')}.png`, { type: 'image/png' });
      
      // Check if Web Share API is available
      if (navigator.canShare && navigator.canShare({ files: [file] })) {
        await navigator.share({
          title: 'Ramazon 2026 Taqvimi',
          text: `Ramazon 2026 taqvimi - ${cityName}\n@muslim_vegukin_bot orqali yaratildi`,
          files: [file]
        });
        
        // Haptic feedback
        if (window.Telegram?.WebApp?.HapticFeedback) {
          window.Telegram.WebApp.HapticFeedback.notificationOccurred('success');
        }
      } else {
        // Fallback: show message
        const tg = window.Telegram?.WebApp;
        if (tg) {
          tg.showAlert("Rasmni saqlang va Telegram orqali ulashing");
        } else {
          alert("Rasmni saqlang va keyin ulashing");
        }
      }
    } catch (error) {
      console.log('Share cancelled or failed:', error);
    }
  },
  
  showError(message) {
    const tg = window.Telegram?.WebApp;
    
    if (tg) {
      tg.showAlert(`Xatolik yuz berdi: ${message}\n\nIltimos, qaytadan urinib ko'ring.`);
    } else {
      alert(`Xatolik: ${message}`);
    }
  }
};

// ===========================================
// GLOBAL FUNCTION FOR RAMADAN PAGE
// ===========================================

window.generateRamadanCalendarImage = function(lat, lon, cityName) {
  return CalendarGenerator.generate(lat, lon, cityName);
};

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CalendarGenerator;
}
