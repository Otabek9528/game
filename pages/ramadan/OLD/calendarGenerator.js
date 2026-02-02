/**
 * RAMADAN 2026 - Calendar Image Generator (Client-Side)
 * Generates calendar image directly in browser using html2canvas
 * NO SERVER REQUIRED - runs entirely on user's device
 */

// ===========================================
// CONFIGURATION
// ===========================================

const CalendarGenerator = {
  
  RAMADAN_START: new Date(2026, 1, 28), // February 28, 2026
  RAMADAN_DAYS: 30,
  
  API_BASE: 'https://api.aladhan.com/v1/timings',
  METHOD: 3,
  SCHOOL: 1,
  
  MONTHS_UZ: {
    0: 'Yan', 1: 'Fev', 2: 'Mar', 3: 'Apr',
    4: 'May', 5: 'Iyn', 6: 'Iyl', 7: 'Avg',
    8: 'Sen', 9: 'Okt', 10: 'Noy', 11: 'Dek'
  },
  
  WEEKDAYS_UZ: ['Yak', 'Dush', 'Sesh', 'Chor', 'Pay', 'Juma', 'Shan'],
  
  // ===========================================
  // MAIN FUNCTION
  // ===========================================
  
  async generate(lat, lon, cityName) {
    console.log('📅 Generating calendar for:', cityName);
    
    try {
      // Show loading
      this.showLoading('Vaqtlar yuklanmoqda...');
      
      // Fetch prayer times
      const prayerTimes = await this.fetchPrayerTimes(lat, lon);
      
      if (!prayerTimes || prayerTimes.length === 0) {
        throw new Error("Vaqtlarni yuklashda xatolik");
      }
      
      // Update loading
      this.showLoading('Taqvim yaratilmoqda...');
      
      // Generate HTML
      const html = this.generateHTML(cityName, prayerTimes);
      
      // Render to image
      const imageUrl = await this.renderToImage(html);
      
      // Hide loading
      this.hideLoading();
      
      // Show result
      this.showCalendarImage(imageUrl, cityName);
      
      return imageUrl;
      
    } catch (error) {
      console.error('❌ Calendar generation failed:', error);
      this.hideLoading();
      this.showError(error.message);
      return null;
    }
  },
  
  // ===========================================
  // FETCH PRAYER TIMES
  // ===========================================
  
  async fetchPrayerTimes(lat, lon) {
    const times = [];
    const batchSize = 5;
    
    for (let i = 0; i < this.RAMADAN_DAYS; i += batchSize) {
      const batch = [];
      
      for (let j = i; j < Math.min(i + batchSize, this.RAMADAN_DAYS); j++) {
        const date = new Date(this.RAMADAN_START);
        date.setDate(this.RAMADAN_START.getDate() + j);
        batch.push(this.fetchDayTimes(lat, lon, date, j + 1));
      }
      
      const results = await Promise.all(batch);
      times.push(...results);
      
      // Update progress
      const progress = Math.round((times.length / this.RAMADAN_DAYS) * 100);
      this.showLoading(`Vaqtlar yuklanmoqda... ${progress}%`);
      
      // Small delay between batches to avoid rate limiting
      if (i + batchSize < this.RAMADAN_DAYS) {
        await new Promise(r => setTimeout(r, 100));
      }
    }
    
    return times;
  },
  
  async fetchDayTimes(lat, lon, date, dayNum) {
    const dateStr = `${date.getDate()}-${date.getMonth() + 1}-${date.getFullYear()}`;
    
    try {
      const url = `${this.API_BASE}/${dateStr}?latitude=${lat}&longitude=${lon}&method=${this.METHOD}&school=${this.SCHOOL}`;
      const response = await fetch(url);
      
      if (!response.ok) throw new Error('API error');
      
      const data = await response.json();
      const timings = data.data.timings;
      
      return {
        day: dayNum,
        date: date,
        dateStr: `${date.getDate()}-${this.MONTHS_UZ[date.getMonth()]}`,
        weekday: this.WEEKDAYS_UZ[date.getDay()],
        isFriday: date.getDay() === 5,
        suhur: timings.Fajr.slice(0, 5),
        iftar: timings.Maghrib.slice(0, 5)
      };
    } catch (e) {
      console.error(`Error fetching day ${dayNum}:`, e);
      return {
        day: dayNum,
        date: date,
        dateStr: `${date.getDate()}-${this.MONTHS_UZ[date.getMonth()]}`,
        weekday: this.WEEKDAYS_UZ[date.getDay()],
        isFriday: date.getDay() === 5,
        suhur: '--:--',
        iftar: '--:--'
      };
    }
  },
  
  // ===========================================
  // GENERATE HTML
  // ===========================================
  
  generateHTML(cityName, prayerTimes) {
    const generateTableRows = (startIdx, endIdx) => {
      let rows = '';
      for (let i = startIdx; i < endIdx; i++) {
        const day = prayerTimes[i];
        const fridayClass = day.isFriday ? ' class="friday"' : '';
        rows += `
          <tr${fridayClass}>
            <td>${day.day}</td>
            <td class="date">${day.dateStr}</td>
            <td class="weekday">${day.weekday}</td>
            <td class="time-suhur">${day.suhur}</td>
            <td class="time-iftar">${day.iftar}</td>
          </tr>`;
      }
      return rows;
    };
    
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Rubik:wght@400;500;600;700&display=swap');
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: 'Rubik', sans-serif;
      background: transparent;
      margin: 0;
      padding: 0;
    }
    
    .calendar {
      width: 540px;
      background: linear-gradient(180deg, #0a0a0f 0%, #12100a 30%, #1a1510 50%, #12100a 70%, #0a0a0f 100%);
      border-radius: 16px;
      overflow: hidden;
      position: relative;
      padding: 14px 14px 16px 14px;
    }
    
    .calendar::before {
      content: '';
      position: absolute;
      top: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 100%;
      height: 180px;
      background: radial-gradient(ellipse at top center, rgba(244,197,66,0.12) 0%, transparent 70%);
      pointer-events: none;
    }
    
    .calendar::after {
      content: '';
      position: absolute;
      top: 8px;
      left: 8px;
      right: 8px;
      bottom: 8px;
      border: 1px solid rgba(244,197,66,0.15);
      border-radius: 12px;
      pointer-events: none;
    }
    
    .lanterns {
      position: absolute;
      top: 12px;
      left: 0;
      right: 0;
      display: flex;
      justify-content: space-between;
      padding: 0 16px;
      font-size: 28px;
      z-index: 2;
      filter: drop-shadow(0 0 8px rgba(244,197,66,0.5));
    }
    
    .header {
      text-align: center;
      position: relative;
      z-index: 1;
      padding-top: 12px;
      margin-bottom: 16px;
    }
    
    .arabic {
      font-family: 'Amiri', serif;
      font-size: 32px;
      color: #f4c542;
      text-shadow: 0 0 20px rgba(244,197,66,0.4);
      margin-bottom: 2px;
    }
    
    .title {
      font-size: 18px;
      font-weight: 700;
      color: #fff;
      letter-spacing: 2px;
      text-transform: uppercase;
    }
    
    .subtitle {
      font-size: 11px;
      color: #f4c542;
      margin-top: 2px;
      letter-spacing: 0.5px;
    }
    
    .subtitle .by-bot {
      color: #94a3b8;
      font-size: 10px;
      margin-left: 4px;
    }
    
    .subtitle .bot-name {
      color: #10b981;
      font-weight: 500;
    }
    
    .city {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      margin-top: 8px;
      padding: 4px 12px;
      background: rgba(244,197,66,0.1);
      border: 1px solid rgba(244,197,66,0.2);
      border-radius: 16px;
      font-size: 12px;
      color: #f4c542;
    }
    
    .ashara-section {
      position: relative;
      z-index: 1;
      margin-bottom: 12px;
    }
    
    .ashara-section:last-of-type {
      margin-bottom: 0;
    }
    
    .ashara-title {
      text-align: center;
      font-size: 13px;
      font-weight: 600;
      color: #f4c542;
      margin-bottom: 8px;
      padding: 6px 16px;
      background: linear-gradient(90deg, transparent, rgba(244,197,66,0.2), transparent);
    }
    
    .days-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 11px;
      background: rgba(0,0,0,0.3);
      border-radius: 10px;
      overflow: hidden;
      border: 1px solid rgba(244,197,66,0.1);
    }
    
    .days-table thead th {
      background: linear-gradient(180deg, rgba(244,197,66,0.2), rgba(244,197,66,0.1));
      padding: 8px 4px;
      text-align: center;
      font-weight: 600;
      font-size: 9px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #f4c542;
      border-bottom: 1px solid rgba(244,197,66,0.2);
    }
    
    .days-table tbody tr {
      border-bottom: 1px solid rgba(255,255,255,0.04);
    }
    
    .days-table tbody tr:nth-child(odd) {
      background: rgba(255,255,255,0.02);
    }
    
    .days-table tbody tr:nth-child(even) {
      background: rgba(0,0,0,0.1);
    }
    
    .days-table tbody tr:last-child {
      border-bottom: none;
    }
    
    .days-table tbody tr.friday {
      background: linear-gradient(90deg, rgba(244,197,66,0.15), rgba(245,158,11,0.1), rgba(244,197,66,0.15));
      border-left: 3px solid #f4c542;
    }
    
    .days-table tbody tr.friday td {
      color: #fff;
    }
    
    .days-table tbody tr.friday td:first-child {
      color: #f4c542;
    }
    
    .days-table tbody tr.friday .weekday {
      color: #f4c542;
      font-weight: 600;
    }
    
    .days-table tbody td {
      padding: 7px 4px;
      text-align: center;
      color: #cbd5e1;
    }
    
    .days-table tbody td:first-child {
      font-weight: 700;
      color: #f4c542;
      font-size: 12px;
    }
    
    .days-table .date {
      color: #94a3b8;
      font-size: 10px;
    }
    
    .days-table .weekday {
      color: #64748b;
      font-size: 10px;
    }
    
    .days-table .time-suhur {
      color: #a5b4fc;
      font-weight: 600;
      font-size: 11px;
    }
    
    .days-table .time-iftar {
      color: #fcd34d;
      font-weight: 600;
      font-size: 11px;
    }
    
    .stars {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      pointer-events: none;
      overflow: hidden;
    }
    
    .star {
      position: absolute;
      color: #f4c542;
      font-size: 8px;
      opacity: 0.3;
    }
    
    .star:nth-child(1) { top: 15%; left: 5%; }
    .star:nth-child(2) { top: 8%; left: 20%; }
    .star:nth-child(3) { top: 12%; right: 15%; }
    .star:nth-child(4) { top: 20%; right: 8%; }
    .star:nth-child(5) { top: 25%; left: 10%; }
    .star:nth-child(6) { top: 5%; left: 40%; }
  </style>
</head>
<body>
  <div class="calendar">
    <div class="stars">
      <span class="star">✦</span>
      <span class="star">✧</span>
      <span class="star">✦</span>
      <span class="star">✧</span>
      <span class="star">✦</span>
      <span class="star">✧</span>
    </div>
    
    <div class="lanterns">
      <span>🏮</span>
      <span>🏮</span>
    </div>
    
    <div class="header">
      <div class="arabic">رمضان مبارك</div>
      <div class="title">Ramazon Taqvimi</div>
      <div class="subtitle">1447 Hijriy / 2026 Milodiy <span class="by-bot">by <span class="bot-name">@muslim_vegukin_bot</span></span></div>
      <div class="city">📍 ${cityName}</div>
    </div>
    
    <div class="ashara-section">
      <div class="ashara-title">═══ 1-ASHARA • Rahmat ═══</div>
      <table class="days-table">
        <thead>
          <tr>
            <th>Kun</th>
            <th>Sana</th>
            <th>Hafta</th>
            <th>Saharlik</th>
            <th>Iftorlik</th>
          </tr>
        </thead>
        <tbody>
          ${generateTableRows(0, 10)}
        </tbody>
      </table>
    </div>
    
    <div class="ashara-section">
      <div class="ashara-title">═══ 2-ASHARA • Mag'firat ═══</div>
      <table class="days-table">
        <thead>
          <tr>
            <th>Kun</th>
            <th>Sana</th>
            <th>Hafta</th>
            <th>Saharlik</th>
            <th>Iftorlik</th>
          </tr>
        </thead>
        <tbody>
          ${generateTableRows(10, 20)}
        </tbody>
      </table>
    </div>
    
    <div class="ashara-section">
      <div class="ashara-title">═══ 3-ASHARA • Najot ═══</div>
      <table class="days-table">
        <thead>
          <tr>
            <th>Kun</th>
            <th>Sana</th>
            <th>Hafta</th>
            <th>Saharlik</th>
            <th>Iftorlik</th>
          </tr>
        </thead>
        <tbody>
          ${generateTableRows(20, 30)}
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>`;
  },
  
  // ===========================================
  // RENDER HTML TO IMAGE
  // ===========================================
  
  async renderToImage(html) {
    // Create hidden container
    const container = document.createElement('div');
    container.id = 'calendar-render-container';
    container.style.cssText = `
      position: fixed;
      left: -9999px;
      top: 0;
      z-index: -1;
      background: transparent;
    `;
    
    // Create iframe to render HTML
    const iframe = document.createElement('iframe');
    iframe.style.cssText = `
      width: 600px;
      height: 1600px;
      border: none;
      background: transparent;
    `;
    
    container.appendChild(iframe);
    document.body.appendChild(container);
    
    // Write HTML to iframe
    iframe.contentDocument.open();
    iframe.contentDocument.write(html);
    iframe.contentDocument.close();
    
    // Wait for fonts and content to load
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Wait for fonts
    if (iframe.contentDocument.fonts) {
      await iframe.contentDocument.fonts.ready;
    }
    
    // Additional wait for images/emojis
    await new Promise(resolve => setTimeout(resolve, 300));
    
    // Use html2canvas to capture
    const calendar = iframe.contentDocument.querySelector('.calendar');
    
    if (!calendar) {
      container.remove();
      throw new Error('Calendar element not found');
    }
    
    const canvas = await html2canvas(calendar, {
      backgroundColor: null,
      scale: 2, // Higher resolution
      useCORS: true,
      allowTaint: true,
      logging: false
    });
    
    // Clean up
    container.remove();
    
    // Convert to blob URL
    return new Promise((resolve, reject) => {
      canvas.toBlob(blob => {
        if (blob) {
          resolve(URL.createObjectURL(blob));
        } else {
          reject(new Error('Failed to create image'));
        }
      }, 'image/png', 1.0);
    });
  },
  
  // ===========================================
  // UI FUNCTIONS
  // ===========================================
  
  showLoading(text) {
    if (window.RamadanPage) {
      window.RamadanPage.showLoading(text);
    }
  },
  
  hideLoading() {
    if (window.RamadanPage) {
      window.RamadanPage.hideLoading();
    }
  },
  
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
    
    // Add styles
    this.addModalStyles();
    
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
    
    downloadBtn.addEventListener('click', () => {
      this.downloadImage(imageUrl, cityName);
    });
    
    shareBtn.addEventListener('click', async () => {
      await this.shareImage(imageUrl, cityName);
    });
    
    // Haptic feedback
    if (window.Telegram?.WebApp?.HapticFeedback) {
      window.Telegram.WebApp.HapticFeedback.impactOccurred('medium');
    }
  },
  
  addModalStyles() {
    if (document.getElementById('calendar-modal-styles')) return;
    
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
        background: var(--bg-secondary, #1a2d42);
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
      
      .calendar-btn-share {
        background: linear-gradient(135deg, #f4c542, #eab308);
        color: #1a1a2e;
      }
    `;
    document.head.appendChild(styles);
  },
  
  downloadImage(imageUrl, cityName) {
    const tg = window.Telegram?.WebApp;
    
    // Convert blob URL to base64 for better compatibility
    fetch(imageUrl)
      .then(res => res.blob())
      .then(blob => {
        const reader = new FileReader();
        reader.onloadend = () => {
          const base64 = reader.result;
          
          // Method 1: Try opening in new tab (works in most browsers)
          const newTab = window.open();
          if (newTab) {
            newTab.document.write(`
              <!DOCTYPE html>
              <html>
              <head>
                <title>Ramazon 2026 Taqvimi - ${cityName}</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                  body {
                    margin: 0;
                    padding: 16px;
                    background: #0a1628;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    min-height: 100vh;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  }
                  h3 {
                    color: #f4c542;
                    margin-bottom: 12px;
                    text-align: center;
                  }
                  p {
                    color: #94a3b8;
                    font-size: 14px;
                    margin-bottom: 16px;
                    text-align: center;
                  }
                  img {
                    max-width: 100%;
                    border-radius: 12px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.5);
                  }
                </style>
              </head>
              <body>
                <h3>📅 Ramazon 2026 Taqvimi</h3>
                <p>Rasmni bosib turing va "Saqlash" ni tanlang</p>
                <img src="${base64}" alt="Ramazon Taqvimi ${cityName}" />
              </body>
              </html>
            `);
            newTab.document.close();
            
            if (tg?.HapticFeedback) {
              tg.HapticFeedback.notificationOccurred('success');
            }
          } else {
            // Method 2: Fallback - create downloadable link
            const link = document.createElement('a');
            link.href = base64;
            link.download = `ramazon_2026_${cityName.replace(/\s+/g, '_')}.png`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            if (tg) {
              tg.showAlert("Rasm yuklab olindi!");
            }
          }
        };
        reader.readAsDataURL(blob);
      })
      .catch(err => {
        console.error('Download error:', err);
        if (tg) {
          tg.showAlert("Xatolik yuz berdi. Qaytadan urinib ko'ring.");
        }
      });
  },
  
  async shareImage(imageUrl, cityName) {
    const tg = window.Telegram?.WebApp;
    
    try {
      // Convert to base64
      const response = await fetch(imageUrl);
      const blob = await response.blob();
      
      // Method 1: Try Telegram's switchInlineQuery (share to chat)
      if (tg?.switchInlineQuery) {
        // This opens chat selector with pre-filled message
        // Unfortunately can't share image directly, but can share bot link
        const shareText = `Ramazon 2026 taqvimi - ${cityName} 🌙\n\nTaqvimni olish uchun: @muslim_vegukin_bot`;
        
        // Show options to user
        tg.showPopup({
          title: 'Ulashish',
          message: 'Qanday ulashmoqchisiz?',
          buttons: [
            { id: 'save_share', type: 'default', text: '💾 Saqlash va ulashish' },
            { id: 'bot_link', type: 'default', text: '🤖 Bot havolasini ulashish' },
            { id: 'cancel', type: 'cancel' }
          ]
        }, (buttonId) => {
          if (buttonId === 'save_share') {
            // Open image in new tab for saving
            this.downloadImage(imageUrl, cityName);
            setTimeout(() => {
              tg.showAlert("Rasmni saqlang, so'ng Telegram chatga yuboring");
            }, 500);
          } else if (buttonId === 'bot_link') {
            // Share bot link via inline query
            tg.switchInlineQuery(shareText, ['users', 'groups', 'channels']);
          }
          
          if (tg?.HapticFeedback) {
            tg.HapticFeedback.impactOccurred('light');
          }
        });
        return;
      }
      
      // Method 2: Try Web Share API (works on some mobile browsers)
      const file = new File([blob], `ramazon_2026_${cityName.replace(/\s+/g, '_')}.png`, { type: 'image/png' });
      
      if (navigator.canShare && navigator.canShare({ files: [file] })) {
        await navigator.share({
          title: 'Ramazon 2026 Taqvimi',
          text: `Ramazon 2026 taqvimi - ${cityName}\n@muslim_vegukin_bot orqali yaratildi`,
          files: [file]
        });
        
        if (tg?.HapticFeedback) {
          tg.HapticFeedback.notificationOccurred('success');
        }
        return;
      }
      
      // Method 3: Fallback - save first then share manually
      this.downloadImage(imageUrl, cityName);
      setTimeout(() => {
        if (tg) {
          tg.showAlert("Rasmni saqlang va Telegram orqali do'stlaringizga yuboring!");
        } else {
          alert("Rasmni saqlang va ulashing");
        }
      }, 500);
      
    } catch (error) {
      console.log('Share error:', error);
      
      // Fallback
      this.downloadImage(imageUrl, cityName);
      if (tg) {
        tg.showAlert("Rasmni saqlang va Telegram orqali ulashing");
      }
    }
  },
  
  showError(message) {
    const tg = window.Telegram?.WebApp;
    if (tg) {
      tg.showAlert(`Xatolik: ${message}\n\nIltimos, qaytadan urinib ko'ring.`);
    } else {
      alert(`Xatolik: ${message}`);
    }
  }
};

// ===========================================
// GLOBAL FUNCTION
// ===========================================

window.generateRamadanCalendarImage = function() {
  // Get location from RamadanPage state
  const state = window.RamadanPage?.getState?.();
  
  if (!state?.location) {
    CalendarGenerator.showError("Joylashuv topilmadi");
    return;
  }
  
  const { lat, lon, city } = state.location;
  return CalendarGenerator.generate(lat, lon, city || 'Noma\'lum');
};
