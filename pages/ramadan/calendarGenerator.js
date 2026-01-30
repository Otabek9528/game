/**
 * RAMADAN 2026 - Calendar Image Generator
 * Generates a beautiful monthly calendar image
 * 
 * Features:
 * - Premium Islamic design
 * - Friday highlighting
 * - City name display
 * - Watermark (@muslim_vegukin_bot)
 * - Easy to read layout
 */

// ===========================================
// CONFIGURATION
// ===========================================

const CalendarConfig = {
  // Canvas dimensions (optimized for mobile sharing)
  WIDTH: 1080,
  HEIGHT: 1920,
  
  // Ramadan 2026
  RAMADAN_START: new Date(2026, 1, 28), // February 28, 2026
  RAMADAN_DAYS: 30,
  
  // API
  API_BASE: 'https://api.aladhan.com/v1',
  METHOD: 3,
  SCHOOL: 1,
  
  // Colors - Premium Islamic Palette
  COLORS: {
    // Backgrounds
    bgGradientStart: '#0a1628',
    bgGradientMid: '#122a42',
    bgGradientEnd: '#1a3d5c',
    
    // Accents
    gold: '#f5c842',
    goldLight: '#fde68a',
    goldDark: '#ca8a04',
    emerald: '#10b981',
    emeraldDark: '#047857',
    
    // Text
    textPrimary: '#f8fafc',
    textSecondary: '#94a3b8',
    textMuted: '#64748b',
    
    // Table
    headerBg: '#065f46',
    rowEven: 'rgba(255, 255, 255, 0.03)',
    rowOdd: 'rgba(255, 255, 255, 0.06)',
    fridayBg: 'rgba(245, 200, 66, 0.15)',
    fridayBorder: 'rgba(245, 200, 66, 0.4)',
    border: 'rgba(255, 255, 255, 0.1)'
  },
  
  // Fonts
  FONTS: {
    arabic: '"Amiri", serif',
    title: '"Rubik", sans-serif',
    body: '"Rubik", sans-serif'
  },
  
  // Uzbek weekday names
  WEEKDAYS_UZ: ['Yakshanba', 'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba'],
  
  // Uzbek month names
  MONTHS_UZ: {
    0: 'Yanvar', 1: 'Fevral', 2: 'Mart', 3: 'Aprel',
    4: 'May', 5: 'Iyun', 6: 'Iyul', 7: 'Avgust',
    8: 'Sentabr', 9: 'Oktabr', 10: 'Noyabr', 11: 'Dekabr'
  }
};

// ===========================================
// MAIN GENERATOR CLASS
// ===========================================

class RamadanCalendarGenerator {
  constructor() {
    this.canvas = null;
    this.ctx = null;
    this.data = [];
    this.cityName = '';
    this.lat = 0;
    this.lon = 0;
  }
  
  // Initialize canvas
  initCanvas() {
    this.canvas = document.createElement('canvas');
    this.canvas.width = CalendarConfig.WIDTH;
    this.canvas.height = CalendarConfig.HEIGHT;
    this.ctx = this.canvas.getContext('2d');
  }
  
  // Fetch all prayer times for Ramadan
  async fetchAllTimes(lat, lon) {
    const times = [];
    const startDate = new Date(CalendarConfig.RAMADAN_START);
    
    for (let i = 0; i < CalendarConfig.RAMADAN_DAYS; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      
      const dateStr = `${date.getDate()}-${date.getMonth() + 1}-${date.getFullYear()}`;
      
      try {
        const url = `${CalendarConfig.API_BASE}/timings/${dateStr}?latitude=${lat}&longitude=${lon}&method=${CalendarConfig.METHOD}&school=${CalendarConfig.SCHOOL}`;
        const response = await fetch(url);
        const data = await response.json();
        
        times.push({
          day: i + 1,
          date: new Date(date),
          gregorian: `${date.getDate()}-${CalendarConfig.MONTHS_UZ[date.getMonth()]}`,
          weekday: CalendarConfig.WEEKDAYS_UZ[date.getDay()],
          isFriday: date.getDay() === 5,
          suhur: data.data.timings.Fajr.slice(0, 5),
          iftar: data.data.timings.Maghrib.slice(0, 5)
        });
        
        // Small delay to avoid rate limiting
        if (i < CalendarConfig.RAMADAN_DAYS - 1) {
          await new Promise(r => setTimeout(r, 50));
        }
        
        // Update progress
        if (window.RamadanPage) {
          const progress = Math.round(((i + 1) / CalendarConfig.RAMADAN_DAYS) * 100);
          window.RamadanPage.showLoading(`Ma'lumotlar yuklanmoqda... ${progress}%`);
        }
        
      } catch (e) {
        console.error(`Error fetching day ${i + 1}:`, e);
        times.push({
          day: i + 1,
          date: new Date(date),
          gregorian: `${date.getDate()}-${CalendarConfig.MONTHS_UZ[date.getMonth()]}`,
          weekday: CalendarConfig.WEEKDAYS_UZ[date.getDay()],
          isFriday: date.getDay() === 5,
          suhur: '--:--',
          iftar: '--:--'
        });
      }
    }
    
    return times;
  }
  
  // Draw gradient background
  drawBackground() {
    const { ctx, canvas } = this;
    const { COLORS } = CalendarConfig;
    
    // Main gradient
    const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);
    gradient.addColorStop(0, COLORS.bgGradientStart);
    gradient.addColorStop(0.5, COLORS.bgGradientMid);
    gradient.addColorStop(1, COLORS.bgGradientEnd);
    
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // Decorative circles/glows
    ctx.save();
    ctx.globalAlpha = 0.1;
    
    // Top right glow
    const glow1 = ctx.createRadialGradient(canvas.width - 100, 150, 0, canvas.width - 100, 150, 300);
    glow1.addColorStop(0, COLORS.gold);
    glow1.addColorStop(1, 'transparent');
    ctx.fillStyle = glow1;
    ctx.fillRect(0, 0, canvas.width, 500);
    
    // Bottom left glow
    const glow2 = ctx.createRadialGradient(100, canvas.height - 200, 0, 100, canvas.height - 200, 400);
    glow2.addColorStop(0, COLORS.emerald);
    glow2.addColorStop(1, 'transparent');
    ctx.fillStyle = glow2;
    ctx.fillRect(0, canvas.height - 600, canvas.width, 600);
    
    ctx.restore();
  }
  
  // Draw header section
  drawHeader() {
    const { ctx, canvas, cityName } = this;
    const { COLORS } = CalendarConfig;
    
    let y = 80;
    
    // Crescent moon icon
    ctx.save();
    ctx.font = '80px serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = COLORS.gold;
    ctx.shadowColor = COLORS.gold;
    ctx.shadowBlur = 30;
    ctx.fillText('☪', canvas.width / 2, y + 60);
    ctx.restore();
    
    y += 100;
    
    // Title
    ctx.font = 'bold 64px Rubik, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = COLORS.textPrimary;
    ctx.fillText('RAMAZON 2026', canvas.width / 2, y + 50);
    
    y += 70;
    
    // Subtitle - Taqvimi
    ctx.font = '36px Rubik, sans-serif';
    ctx.fillStyle = COLORS.gold;
    ctx.fillText('Saharlik va Iftorlik Taqvimi', canvas.width / 2, y + 30);
    
    y += 60;
    
    // City name with location icon
    ctx.font = '32px Rubik, sans-serif';
    ctx.fillStyle = COLORS.textSecondary;
    ctx.fillText(`📍 ${cityName}`, canvas.width / 2, y + 20);
    
    y += 50;
    
    // Decorative line
    const lineWidth = 400;
    const lineX = (canvas.width - lineWidth) / 2;
    
    const lineGradient = ctx.createLinearGradient(lineX, 0, lineX + lineWidth, 0);
    lineGradient.addColorStop(0, 'transparent');
    lineGradient.addColorStop(0.5, COLORS.gold);
    lineGradient.addColorStop(1, 'transparent');
    
    ctx.strokeStyle = lineGradient;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(lineX, y + 20);
    ctx.lineTo(lineX + lineWidth, y + 20);
    ctx.stroke();
    
    return y + 50;
  }
  
  // Draw table
  drawTable(startY) {
    const { ctx, canvas, data } = this;
    const { COLORS } = CalendarConfig;
    
    const padding = 40;
    const tableWidth = canvas.width - (padding * 2);
    const tableX = padding;
    
    // Column widths
    const colWidths = {
      day: 70,       // Ramadan day
      date: 160,     // Gregorian date
      weekday: 180,  // Weekday name
      suhur: 150,    // Suhur time
      iftar: 150     // Iftar time
    };
    
    // Recalculate to fit
    const totalColWidth = Object.values(colWidths).reduce((a, b) => a + b, 0);
    const scale = tableWidth / totalColWidth;
    Object.keys(colWidths).forEach(k => colWidths[k] *= scale);
    
    const rowHeight = 52;
    const headerHeight = 60;
    
    let y = startY;
    
    // Table header background
    ctx.fillStyle = COLORS.headerBg;
    this.roundRect(tableX, y, tableWidth, headerHeight, 12, true, false);
    
    // Header text
    ctx.font = 'bold 24px Rubik, sans-serif';
    ctx.fillStyle = COLORS.textPrimary;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    let x = tableX;
    const headerY = y + headerHeight / 2;
    
    ctx.fillText('Kun', x + colWidths.day / 2, headerY);
    x += colWidths.day;
    
    ctx.fillText('Sana', x + colWidths.date / 2, headerY);
    x += colWidths.date;
    
    ctx.fillText('Hafta kuni', x + colWidths.weekday / 2, headerY);
    x += colWidths.weekday;
    
    ctx.fillStyle = '#a5b4fc'; // Light purple for Suhur
    ctx.fillText('Saharlik', x + colWidths.suhur / 2, headerY);
    x += colWidths.suhur;
    
    ctx.fillStyle = COLORS.goldLight;
    ctx.fillText('Iftorlik', x + colWidths.iftar / 2, headerY);
    
    y += headerHeight + 4;
    
    // Table rows
    data.forEach((row, index) => {
      const rowY = y + (index * rowHeight);
      
      // Row background
      if (row.isFriday) {
        ctx.fillStyle = COLORS.fridayBg;
        ctx.strokeStyle = COLORS.fridayBorder;
        ctx.lineWidth = 1;
        this.roundRect(tableX, rowY, tableWidth, rowHeight - 2, 8, true, true);
      } else {
        ctx.fillStyle = index % 2 === 0 ? COLORS.rowEven : COLORS.rowOdd;
        this.roundRect(tableX, rowY, tableWidth, rowHeight - 2, 6, true, false);
      }
      
      // Row content
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const cellY = rowY + rowHeight / 2 - 1;
      
      let cellX = tableX;
      
      // Day number
      ctx.font = row.isFriday ? 'bold 26px Rubik, sans-serif' : '24px Rubik, sans-serif';
      ctx.fillStyle = row.isFriday ? COLORS.gold : COLORS.textPrimary;
      ctx.fillText(row.day.toString(), cellX + colWidths.day / 2, cellY);
      cellX += colWidths.day;
      
      // Gregorian date
      ctx.font = '22px Rubik, sans-serif';
      ctx.fillStyle = row.isFriday ? COLORS.goldLight : COLORS.textSecondary;
      ctx.fillText(row.gregorian, cellX + colWidths.date / 2, cellY);
      cellX += colWidths.date;
      
      // Weekday
      ctx.font = row.isFriday ? 'bold 22px Rubik, sans-serif' : '22px Rubik, sans-serif';
      ctx.fillStyle = row.isFriday ? COLORS.gold : COLORS.textSecondary;
      ctx.fillText(row.weekday, cellX + colWidths.weekday / 2, cellY);
      cellX += colWidths.weekday;
      
      // Suhur time
      ctx.font = 'bold 26px Rubik, sans-serif';
      ctx.fillStyle = row.isFriday ? '#c4b5fd' : '#a5b4fc';
      ctx.fillText(row.suhur, cellX + colWidths.suhur / 2, cellY);
      cellX += colWidths.suhur;
      
      // Iftar time
      ctx.fillStyle = row.isFriday ? COLORS.gold : COLORS.goldLight;
      ctx.fillText(row.iftar, cellX + colWidths.iftar / 2, cellY);
    });
    
    return y + (data.length * rowHeight) + 20;
  }
  
  // Draw footer with notes and watermark
  drawFooter(startY) {
    const { ctx, canvas } = this;
    const { COLORS } = CalendarConfig;
    
    let y = startY;
    
    // Notes section
    ctx.font = '24px Rubik, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillStyle = COLORS.textMuted;
    
    ctx.fillText('💡 Saharlikni 5 daqiqa oldin yakunlang', canvas.width / 2, y + 30);
    ctx.fillText('💡 Iftorlikni 5 daqiqa keyin oching', canvas.width / 2, y + 60);
    
    y += 100;
    
    // Friday legend
    ctx.font = '22px Rubik, sans-serif';
    ctx.fillStyle = COLORS.gold;
    ctx.fillText('★ Juma kunlari sariq rang bilan belgilangan', canvas.width / 2, y);
    
    y += 50;
    
    // Watermark
    ctx.save();
    ctx.globalAlpha = 0.6;
    ctx.font = 'bold 28px Rubik, sans-serif';
    ctx.fillStyle = COLORS.textSecondary;
    ctx.fillText('@muslim_vegukin_bot', canvas.width / 2, y + 20);
    ctx.restore();
    
    // Bottom decorative elements
    y = canvas.height - 60;
    ctx.font = '40px serif';
    ctx.globalAlpha = 0.4;
    ctx.fillText('☪ 🕌 ☪', canvas.width / 2, y);
  }
  
  // Helper: Draw rounded rectangle
  roundRect(x, y, width, height, radius, fill, stroke) {
    const { ctx } = this;
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
    if (fill) ctx.fill();
    if (stroke) ctx.stroke();
  }
  
  // Generate the calendar image
  async generate(lat, lon, cityName) {
    this.lat = lat;
    this.lon = lon;
    this.cityName = cityName;
    
    // Initialize canvas
    this.initCanvas();
    
    // Fetch all prayer times
    if (window.RamadanPage) {
      window.RamadanPage.showLoading('Ma\'lumotlar yuklanmoqda...');
    }
    
    this.data = await this.fetchAllTimes(lat, lon);
    
    if (window.RamadanPage) {
      window.RamadanPage.showLoading('Taqvim yaratilmoqda...');
    }
    
    // Draw components
    this.drawBackground();
    const headerEndY = this.drawHeader();
    const tableEndY = this.drawTable(headerEndY + 20);
    this.drawFooter(tableEndY);
    
    // Convert to image
    return this.canvas.toDataURL('image/png');
  }
  
  // Download the generated image
  download(dataUrl) {
    const link = document.createElement('a');
    link.download = `Ramazon_2026_${this.cityName.replace(/\s+/g, '_')}.png`;
    link.href = dataUrl;
    link.click();
  }
  
  // Share via Telegram (if available)
  shareViaTelegram(dataUrl) {
    // Convert data URL to blob for sharing
    const byteString = atob(dataUrl.split(',')[1]);
    const mimeString = dataUrl.split(',')[0].split(':')[1].split(';')[0];
    const ab = new ArrayBuffer(byteString.length);
    const ia = new Uint8Array(ab);
    for (let i = 0; i < byteString.length; i++) {
      ia[i] = byteString.charCodeAt(i);
    }
    const blob = new Blob([ab], { type: mimeString });
    
    // Try native share if available
    if (navigator.share && navigator.canShare) {
      const file = new File([blob], `Ramazon_2026_${this.cityName}.png`, { type: 'image/png' });
      if (navigator.canShare({ files: [file] })) {
        navigator.share({
          files: [file],
          title: 'Ramazon 2026 Taqvimi',
          text: `${this.cityName} shahri uchun Ramazon 2026 taqvimi\n@muslim_vegukin_bot`
        }).catch(console.error);
        return true;
      }
    }
    
    return false;
  }
}

// ===========================================
// GLOBAL INSTANCE & FUNCTIONS
// ===========================================

const calendarGenerator = new RamadanCalendarGenerator();

// Main generation function called from ramadan.js
async function generateRamadanCalendarImage(lat, lon, cityName) {
  try {
    const dataUrl = await calendarGenerator.generate(lat, lon, cityName);
    
    if (window.RamadanPage) {
      window.RamadanPage.hideLoading();
    }
    
    // Show the generated image in a modal
    showCalendarModal(dataUrl, cityName);
    
  } catch (error) {
    console.error('Calendar generation error:', error);
    if (window.RamadanPage) {
      window.RamadanPage.hideLoading();
    }
    
    const tg = window.Telegram?.WebApp;
    if (tg) {
      tg.showAlert('Taqvim yaratishda xatolik yuz berdi. Qayta urinib ko\'ring.');
    } else {
      alert('Taqvim yaratishda xatolik yuz berdi.');
    }
  }
}

// Show modal with generated calendar
function showCalendarModal(dataUrl, cityName) {
  // Remove existing modal if any
  const existingModal = document.getElementById('calendarModal');
  if (existingModal) existingModal.remove();
  
  // Create modal HTML
  const modal = document.createElement('div');
  modal.id = 'calendarModal';
  modal.className = 'calendar-modal';
  modal.innerHTML = `
    <div class="calendar-modal-content">
      <div class="calendar-modal-header">
        <h3>Ramazon 2026 Taqvimi</h3>
        <button class="modal-close-btn" id="closeCalendarModal">✕</button>
      </div>
      <div class="calendar-modal-body">
        <img src="${dataUrl}" alt="Ramazon 2026 Taqvimi" class="calendar-preview-img" />
      </div>
      <div class="calendar-modal-footer">
        <button class="calendar-action-btn download-btn" id="downloadCalendarBtn">
          <span>📥</span> Yuklab olish
        </button>
        <button class="calendar-action-btn share-btn" id="shareCalendarBtn">
          <span>📤</span> Ulashish
        </button>
      </div>
    </div>
  `;
  
  document.body.appendChild(modal);
  
  // Add modal styles if not already added
  addModalStyles();
  
  // Show modal with animation
  requestAnimationFrame(() => {
    modal.classList.add('active');
  });
  
  // Event listeners
  document.getElementById('closeCalendarModal').addEventListener('click', () => {
    closeCalendarModal();
  });
  
  document.getElementById('downloadCalendarBtn').addEventListener('click', () => {
    calendarGenerator.download(dataUrl);
    hapticFeedback('medium');
  });
  
  document.getElementById('shareCalendarBtn').addEventListener('click', () => {
    const shared = calendarGenerator.shareViaTelegram(dataUrl);
    if (!shared) {
      // Fallback: download the image
      calendarGenerator.download(dataUrl);
    }
    hapticFeedback('medium');
  });
  
  // Close on background click
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      closeCalendarModal();
    }
  });
  
  // Handle back button
  const tg = window.Telegram?.WebApp;
  if (tg?.BackButton) {
    tg.BackButton.onClick(closeCalendarModal);
  }
}

function closeCalendarModal() {
  const modal = document.getElementById('calendarModal');
  if (modal) {
    modal.classList.remove('active');
    setTimeout(() => modal.remove(), 300);
  }
}

function hapticFeedback(type = 'light') {
  try {
    const tg = window.Telegram?.WebApp;
    if (tg?.HapticFeedback) {
      tg.HapticFeedback.impactOccurred(type);
    }
  } catch (e) {}
}

// Add modal styles
function addModalStyles() {
  if (document.getElementById('calendarModalStyles')) return;
  
  const styles = document.createElement('style');
  styles.id = 'calendarModalStyles';
  styles.textContent = `
    .calendar-modal {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.9);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      opacity: 0;
      visibility: hidden;
      transition: all 0.3s ease;
      padding: 16px;
    }
    
    .calendar-modal.active {
      opacity: 1;
      visibility: visible;
    }
    
    .calendar-modal-content {
      background: #1a2d42;
      border-radius: 16px;
      max-width: 100%;
      max-height: 90vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      transform: scale(0.9);
      transition: transform 0.3s ease;
    }
    
    .calendar-modal.active .calendar-modal-content {
      transform: scale(1);
    }
    
    .calendar-modal-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 16px 20px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .calendar-modal-header h3 {
      font-size: 1.1rem;
      font-weight: 600;
      color: #f1f5f9;
      margin: 0;
    }
    
    .modal-close-btn {
      width: 32px;
      height: 32px;
      border: none;
      background: rgba(255, 255, 255, 0.1);
      color: #94a3b8;
      border-radius: 8px;
      cursor: pointer;
      font-size: 1.2rem;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .calendar-modal-body {
      flex: 1;
      overflow: auto;
      padding: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .calendar-preview-img {
      max-width: 100%;
      max-height: 60vh;
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }
    
    .calendar-modal-footer {
      display: flex;
      gap: 12px;
      padding: 16px 20px;
      border-top: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .calendar-action-btn {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 14px 20px;
      border: none;
      border-radius: 12px;
      font-size: 1rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    
    .download-btn {
      background: linear-gradient(135deg, #059669, #047857);
      color: white;
    }
    
    .download-btn:hover {
      background: linear-gradient(135deg, #10b981, #059669);
    }
    
    .share-btn {
      background: linear-gradient(135deg, #3b82f6, #2563eb);
      color: white;
    }
    
    .share-btn:hover {
      background: linear-gradient(135deg, #60a5fa, #3b82f6);
    }
  `;
  
  document.head.appendChild(styles);
}

// Expose globally
window.generateRamadanCalendarImage = generateRamadanCalendarImage;
window.RamadanCalendarGenerator = RamadanCalendarGenerator;
