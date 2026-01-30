/**
 * RAMADAN 2026 - Calendar Image Generator
 * Generates beautiful monthly calendar image using Canvas API
 * 
 * Features:
 * - Premium Islamic design
 * - Friday highlighting
 * - City name display
 * - Watermark: @muslim_vegukin_bot
 */

// ===========================================
// CONFIGURATION
// ===========================================

const CalendarConfig = {
  // Canvas dimensions (optimized for mobile sharing)
  WIDTH: 1080,
  HEIGHT: 1920,
  
  // Ramadan 2026 dates
  RAMADAN_START: new Date(2026, 1, 28), // February 28, 2026
  RAMADAN_DAYS: 30,
  
  // API
  API_BASE: 'https://api.aladhan.com/v1',
  METHOD: 3,
  SCHOOL: 1,
  
  // Colors - Premium Islamic Palette
  COLORS: {
    // Backgrounds
    bgGradientTop: '#0a1628',
    bgGradientBottom: '#1a3a52',
    
    // Accent colors
    gold: '#f5c842',
    goldLight: '#fde68a',
    goldDark: '#b8860b',
    emerald: '#10b981',
    emeraldDark: '#047857',
    
    // Text colors
    textPrimary: '#f1f5f9',
    textSecondary: '#94a3b8',
    textMuted: '#64748b',
    
    // Special
    fridayBg: 'rgba(245, 200, 66, 0.15)',
    fridayBorder: '#f5c842',
    headerBg: '#064e3b',
    rowEven: 'rgba(255, 255, 255, 0.03)',
    rowOdd: 'rgba(255, 255, 255, 0.06)',
    
    // Table
    tableBorder: 'rgba(255, 255, 255, 0.1)',
    tableHeaderBg: 'rgba(6, 78, 59, 0.8)',
  },
  
  // Fonts
  FONTS: {
    title: 'bold 52px "Segoe UI", Roboto, sans-serif',
    subtitle: '28px "Segoe UI", Roboto, sans-serif',
    city: 'bold 32px "Segoe UI", Roboto, sans-serif',
    tableHeader: 'bold 26px "Segoe UI", Roboto, sans-serif',
    tableCell: '28px "Segoe UI", Roboto, sans-serif',
    tableCellBold: 'bold 28px "Segoe UI", Roboto, sans-serif',
    watermark: '22px "Segoe UI", Roboto, sans-serif',
    dayNumber: 'bold 32px "Segoe UI", Roboto, sans-serif',
  },
  
  // Layout
  PADDING: 40,
  HEADER_HEIGHT: 280,
  TABLE_TOP: 320,
  ROW_HEIGHT: 52,
  
  // Uzbek translations
  MONTHS_UZ: {
    0: 'Yanvar', 1: 'Fevral', 2: 'Mart', 3: 'Aprel',
    4: 'May', 5: 'Iyun', 6: 'Iyul', 7: 'Avgust',
    8: 'Sentabr', 9: 'Oktabr', 10: 'Noyabr', 11: 'Dekabr'
  },
  
  WEEKDAYS_UZ_SHORT: ['Yak', 'Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan'],
};

// ===========================================
// CANVAS DRAWING UTILITIES
// ===========================================

function createGradient(ctx, y1, y2, color1, color2) {
  const gradient = ctx.createLinearGradient(0, y1, 0, y2);
  gradient.addColorStop(0, color1);
  gradient.addColorStop(1, color2);
  return gradient;
}

function roundRect(ctx, x, y, width, height, radius) {
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
}

function drawStar(ctx, cx, cy, spikes, outerRadius, innerRadius) {
  let rot = Math.PI / 2 * 3;
  let x = cx;
  let y = cy;
  const step = Math.PI / spikes;

  ctx.beginPath();
  ctx.moveTo(cx, cy - outerRadius);
  
  for (let i = 0; i < spikes; i++) {
    x = cx + Math.cos(rot) * outerRadius;
    y = cy - Math.sin(rot) * outerRadius;
    ctx.lineTo(x, y);
    rot += step;

    x = cx + Math.cos(rot) * innerRadius;
    y = cy - Math.sin(rot) * innerRadius;
    ctx.lineTo(x, y);
    rot += step;
  }
  
  ctx.lineTo(cx, cy - outerRadius);
  ctx.closePath();
}

function drawCrescent(ctx, cx, cy, radius) {
  ctx.beginPath();
  ctx.arc(cx, cy, radius, 0, Math.PI * 2);
  ctx.fill();
  
  // Cut out inner circle to create crescent
  ctx.globalCompositeOperation = 'destination-out';
  ctx.beginPath();
  ctx.arc(cx + radius * 0.35, cy - radius * 0.1, radius * 0.8, 0, Math.PI * 2);
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';
}

// ===========================================
// API FUNCTIONS
// ===========================================

async function fetchMonthlyPrayerTimes(lat, lon) {
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
        weekday: date.getDay(),
        suhur: data.data.timings.Fajr.slice(0, 5),
        iftar: data.data.timings.Maghrib.slice(0, 5),
        isFriday: date.getDay() === 5
      });
      
      // Small delay to avoid rate limiting
      if (i < CalendarConfig.RAMADAN_DAYS - 1) {
        await new Promise(resolve => setTimeout(resolve, 50));
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
        weekday: date.getDay(),
        suhur: '--:--',
        iftar: '--:--',
        isFriday: date.getDay() === 5
      });
    }
  }
  
  return times;
}

// ===========================================
// MAIN DRAWING FUNCTION
// ===========================================

function drawCalendarImage(ctx, times, cityName) {
  const { WIDTH, HEIGHT, COLORS, FONTS, PADDING } = CalendarConfig;
  
  // === BACKGROUND ===
  const bgGradient = createGradient(ctx, 0, HEIGHT, COLORS.bgGradientTop, COLORS.bgGradientBottom);
  ctx.fillStyle = bgGradient;
  ctx.fillRect(0, 0, WIDTH, HEIGHT);
  
  // Background decorative elements
  drawBackgroundDecorations(ctx);
  
  // === HEADER SECTION ===
  drawHeader(ctx, cityName);
  
  // === TABLE ===
  drawTable(ctx, times);
  
  // === WATERMARK ===
  drawWatermark(ctx);
  
  // === DECORATIVE BORDER ===
  drawBorder(ctx);
}

function drawBackgroundDecorations(ctx) {
  const { WIDTH, HEIGHT, COLORS } = CalendarConfig;
  
  // Subtle radial glow at top
  const glowGradient = ctx.createRadialGradient(WIDTH / 2, 0, 0, WIDTH / 2, 0, 400);
  glowGradient.addColorStop(0, 'rgba(245, 200, 66, 0.1)');
  glowGradient.addColorStop(1, 'transparent');
  ctx.fillStyle = glowGradient;
  ctx.fillRect(0, 0, WIDTH, 500);
  
  // Decorative stars
  ctx.fillStyle = 'rgba(245, 200, 66, 0.3)';
  const starPositions = [
    { x: 80, y: 120, size: 8 },
    { x: WIDTH - 80, y: 100, size: 6 },
    { x: 150, y: 200, size: 5 },
    { x: WIDTH - 150, y: 180, size: 7 },
    { x: 60, y: HEIGHT - 100, size: 6 },
    { x: WIDTH - 60, y: HEIGHT - 120, size: 5 },
  ];
  
  starPositions.forEach(star => {
    drawStar(ctx, star.x, star.y, 4, star.size, star.size / 2);
    ctx.fill();
  });
}

function drawHeader(ctx, cityName) {
  const { WIDTH, COLORS, FONTS, PADDING } = CalendarConfig;
  
  const centerX = WIDTH / 2;
  
  // Crescent moon with star
  ctx.fillStyle = COLORS.gold;
  
  // Draw crescent
  ctx.save();
  ctx.beginPath();
  ctx.arc(centerX - 40, 80, 35, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = CalendarConfig.COLORS.bgGradientTop;
  ctx.beginPath();
  ctx.arc(centerX - 25, 70, 28, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
  
  // Star next to crescent
  ctx.fillStyle = COLORS.gold;
  drawStar(ctx, centerX + 20, 65, 5, 15, 7);
  ctx.fill();
  
  // Title: RAMAZON 2026
  ctx.fillStyle = COLORS.textPrimary;
  ctx.font = FONTS.title;
  ctx.textAlign = 'center';
  ctx.fillText('RAMAZON 2026', centerX, 170);
  
  // Subtitle: Saharlik va Iftorlik vaqtlari
  ctx.fillStyle = COLORS.textSecondary;
  ctx.font = FONTS.subtitle;
  ctx.fillText('Saharlik va Iftorlik vaqtlari', centerX, 210);
  
  // City name with location icon
  ctx.fillStyle = COLORS.emerald;
  ctx.font = FONTS.city;
  
  // Location pin icon (simplified)
  const cityWidth = ctx.measureText(cityName).width;
  const iconX = centerX - cityWidth / 2 - 25;
  
  ctx.beginPath();
  ctx.arc(iconX, 255, 8, Math.PI, 0, false);
  ctx.lineTo(iconX, 270);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.arc(iconX, 255, 3, 0, Math.PI * 2);
  ctx.fillStyle = CalendarConfig.COLORS.bgGradientTop;
  ctx.fill();
  
  ctx.fillStyle = COLORS.emerald;
  ctx.fillText(cityName, centerX + 10, 265);
  
  // Decorative line under header
  const lineY = 295;
  const lineWidth = 300;
  const gradient = ctx.createLinearGradient(centerX - lineWidth, lineY, centerX + lineWidth, lineY);
  gradient.addColorStop(0, 'transparent');
  gradient.addColorStop(0.3, COLORS.gold);
  gradient.addColorStop(0.5, COLORS.goldLight);
  gradient.addColorStop(0.7, COLORS.gold);
  gradient.addColorStop(1, 'transparent');
  
  ctx.strokeStyle = gradient;
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(centerX - lineWidth, lineY);
  ctx.lineTo(centerX + lineWidth, lineY);
  ctx.stroke();
  
  // Small diamond in center of line
  ctx.fillStyle = COLORS.gold;
  ctx.save();
  ctx.translate(centerX, lineY);
  ctx.rotate(Math.PI / 4);
  ctx.fillRect(-5, -5, 10, 10);
  ctx.restore();
}

function drawTable(ctx, times) {
  const { WIDTH, COLORS, FONTS, PADDING, TABLE_TOP, ROW_HEIGHT } = CalendarConfig;
  
  const tableX = PADDING;
  const tableY = TABLE_TOP;
  const tableWidth = WIDTH - PADDING * 2;
  
  // Column widths
  const colWidths = {
    day: 80,        // Ramadan day
    date: 180,      // Gregorian date
    weekday: 120,   // Weekday
    suhur: 200,     // Suhur time
    iftar: 200,     // Iftar time
  };
  
  // Adjust to fit
  const totalColWidth = Object.values(colWidths).reduce((a, b) => a + b, 0);
  const scale = (tableWidth - 40) / totalColWidth;
  Object.keys(colWidths).forEach(key => colWidths[key] *= scale);
  
  // Column positions
  const cols = {
    day: tableX + 20,
    date: tableX + 20 + colWidths.day,
    weekday: tableX + 20 + colWidths.day + colWidths.date,
    suhur: tableX + 20 + colWidths.day + colWidths.date + colWidths.weekday,
    iftar: tableX + 20 + colWidths.day + colWidths.date + colWidths.weekday + colWidths.suhur,
  };
  
  // === TABLE HEADER ===
  const headerHeight = 55;
  
  // Header background
  roundRect(ctx, tableX, tableY, tableWidth, headerHeight, 12);
  ctx.fillStyle = COLORS.tableHeaderBg;
  ctx.fill();
  
  // Header text
  ctx.fillStyle = COLORS.goldLight;
  ctx.font = FONTS.tableHeader;
  ctx.textAlign = 'center';
  
  const headerY = tableY + 38;
  ctx.fillText('Kun', cols.day + colWidths.day / 2, headerY);
  ctx.fillText('Sana', cols.date + colWidths.date / 2, headerY);
  ctx.fillText('Hafta', cols.weekday + colWidths.weekday / 2, headerY);
  ctx.fillText('Saharlik', cols.suhur + colWidths.suhur / 2, headerY);
  ctx.fillText('Iftorlik', cols.iftar + colWidths.iftar / 2, headerY);
  
  // === TABLE ROWS ===
  let rowY = tableY + headerHeight + 5;
  
  times.forEach((time, index) => {
    const isEven = index % 2 === 0;
    const isFriday = time.isFriday;
    
    // Row background
    roundRect(ctx, tableX, rowY, tableWidth, ROW_HEIGHT - 2, 8);
    
    if (isFriday) {
      // Friday special styling
      ctx.fillStyle = COLORS.fridayBg;
      ctx.fill();
      ctx.strokeStyle = COLORS.fridayBorder;
      ctx.lineWidth = 1.5;
      ctx.stroke();
    } else {
      ctx.fillStyle = isEven ? COLORS.rowEven : COLORS.rowOdd;
      ctx.fill();
    }
    
    // Row text
    const textY = rowY + 35;
    ctx.textAlign = 'center';
    
    // Day number (Ramadan day)
    ctx.fillStyle = isFriday ? COLORS.gold : COLORS.textPrimary;
    ctx.font = FONTS.dayNumber;
    ctx.fillText(time.day.toString(), cols.day + colWidths.day / 2, textY);
    
    // Gregorian date
    ctx.fillStyle = isFriday ? COLORS.goldLight : COLORS.textSecondary;
    ctx.font = FONTS.tableCell;
    ctx.fillText(time.gregorian, cols.date + colWidths.date / 2, textY);
    
    // Weekday
    const weekdayText = CalendarConfig.WEEKDAYS_UZ_SHORT[time.weekday];
    ctx.fillStyle = isFriday ? COLORS.gold : COLORS.textMuted;
    ctx.font = isFriday ? FONTS.tableCellBold : FONTS.tableCell;
    ctx.fillText(weekdayText, cols.weekday + colWidths.weekday / 2, textY);
    
    // Suhur time
    ctx.fillStyle = isFriday ? COLORS.goldLight : COLORS.textPrimary;
    ctx.font = FONTS.tableCellBold;
    ctx.fillText(time.suhur, cols.suhur + colWidths.suhur / 2, textY);
    
    // Iftar time
    ctx.fillStyle = isFriday ? COLORS.gold : COLORS.emerald;
    ctx.font = FONTS.tableCellBold;
    ctx.fillText(time.iftar, cols.iftar + colWidths.iftar / 2, textY);
    
    rowY += ROW_HEIGHT;
  });
  
  // Legend for Friday
  const legendY = rowY + 20;
  ctx.fillStyle = COLORS.fridayBorder;
  roundRect(ctx, WIDTH / 2 - 100, legendY, 200, 30, 6);
  ctx.fillStyle = COLORS.fridayBg;
  ctx.fill();
  ctx.strokeStyle = COLORS.fridayBorder;
  ctx.lineWidth = 1;
  ctx.stroke();
  
  ctx.fillStyle = COLORS.gold;
  ctx.font = '20px "Segoe UI", sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('★ Juma kuni', WIDTH / 2, legendY + 21);
}

function drawWatermark(ctx) {
  const { WIDTH, HEIGHT, COLORS, FONTS } = CalendarConfig;
  
  // Watermark at bottom
  ctx.fillStyle = 'rgba(148, 163, 184, 0.6)';
  ctx.font = FONTS.watermark;
  ctx.textAlign = 'center';
  ctx.fillText('@muslim_vegukin_bot', WIDTH / 2, HEIGHT - 40);
  
  // Small crescent icon
  ctx.fillStyle = 'rgba(148, 163, 184, 0.4)';
  ctx.beginPath();
  ctx.arc(WIDTH / 2 - 130, HEIGHT - 45, 10, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = CalendarConfig.COLORS.bgGradientBottom;
  ctx.beginPath();
  ctx.arc(WIDTH / 2 - 126, HEIGHT - 48, 8, 0, Math.PI * 2);
  ctx.fill();
}

function drawBorder(ctx) {
  const { WIDTH, HEIGHT, COLORS } = CalendarConfig;
  
  // Decorative corner elements
  const cornerSize = 40;
  ctx.strokeStyle = COLORS.gold;
  ctx.lineWidth = 2;
  
  // Top-left corner
  ctx.beginPath();
  ctx.moveTo(20, 20 + cornerSize);
  ctx.lineTo(20, 20);
  ctx.lineTo(20 + cornerSize, 20);
  ctx.stroke();
  
  // Top-right corner
  ctx.beginPath();
  ctx.moveTo(WIDTH - 20 - cornerSize, 20);
  ctx.lineTo(WIDTH - 20, 20);
  ctx.lineTo(WIDTH - 20, 20 + cornerSize);
  ctx.stroke();
  
  // Bottom-left corner
  ctx.beginPath();
  ctx.moveTo(20, HEIGHT - 20 - cornerSize);
  ctx.lineTo(20, HEIGHT - 20);
  ctx.lineTo(20 + cornerSize, HEIGHT - 20);
  ctx.stroke();
  
  // Bottom-right corner
  ctx.beginPath();
  ctx.moveTo(WIDTH - 20 - cornerSize, HEIGHT - 20);
  ctx.lineTo(WIDTH - 20, HEIGHT - 20);
  ctx.lineTo(WIDTH - 20, HEIGHT - 20 - cornerSize);
  ctx.stroke();
}

// ===========================================
// MAIN EXPORT FUNCTION
// ===========================================

async function generateRamadanCalendarImage(lat, lon, cityName) {
  console.log('🎨 Starting calendar generation...');
  
  try {
    // Show loading
    if (window.RamadanPage) {
      window.RamadanPage.showLoading('Ma\'lumotlar yuklanmoqda...');
    }
    
    // Fetch all prayer times
    const times = await fetchMonthlyPrayerTimes(lat, lon);
    
    if (window.RamadanPage) {
      window.RamadanPage.showLoading('Taqvim yaratilmoqda...');
    }
    
    // Create canvas
    const canvas = document.createElement('canvas');
    canvas.width = CalendarConfig.WIDTH;
    canvas.height = CalendarConfig.HEIGHT;
    const ctx = canvas.getContext('2d');
    
    // Draw the calendar
    drawCalendarImage(ctx, times, cityName);
    
    // Convert to blob and download
    canvas.toBlob(async (blob) => {
      if (blob) {
        // Create download link
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `Ramazon_2026_${cityName.replace(/\s+/g, '_')}.png`;
        
        // Try to use Telegram's share if available
        const tg = window.Telegram?.WebApp;
        if (tg) {
          // For Telegram, we'll download the file
          link.click();
          
          setTimeout(() => {
            URL.revokeObjectURL(url);
            if (window.RamadanPage) {
              window.RamadanPage.hideLoading();
            }
            tg.showAlert('Taqvim muvaffaqiyatli saqlandi! 📅');
          }, 500);
        } else {
          link.click();
          setTimeout(() => {
            URL.revokeObjectURL(url);
            if (window.RamadanPage) {
              window.RamadanPage.hideLoading();
            }
          }, 500);
        }
      }
    }, 'image/png', 1.0);
    
    console.log('✅ Calendar generation complete!');
    
  } catch (error) {
    console.error('❌ Calendar generation error:', error);
    if (window.RamadanPage) {
      window.RamadanPage.hideLoading();
    }
    
    const tg = window.Telegram?.WebApp;
    if (tg) {
      tg.showAlert('Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.');
    } else {
      alert('Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.');
    }
  }
}

// Make available globally
window.generateRamadanCalendarImage = generateRamadanCalendarImage;
