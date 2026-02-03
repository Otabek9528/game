/**
 * RAMADAN 2026 - Calendar Image Generator (Client-Side)
 * Generates calendar image directly in browser using html2canvas
 * NO SERVER REQUIRED - runs entirely on user's device
 */

const CalendarGenerator = {
  
  RAMADAN_START: new Date(2026, 1, 28),
  RAMADAN_DAYS: 30,
  API_BASE: 'https://api.aladhan.com/v1/timings',
  METHOD: 3,
  SCHOOL: 1,
  MONTHS_UZ: {0:'Yan',1:'Fev',2:'Mar',3:'Apr',4:'May',5:'Iyn',6:'Iyl',7:'Avg',8:'Sen',9:'Okt',10:'Noy',11:'Dek'},
  WEEKDAYS_UZ: ['Yak','Dush','Sesh','Chor','Pay','Juma','Shan'],
  generatedImageBase64: null,

  async generate(lat, lon, cityName) {
    try {
      this.showLoading('Vaqtlar yuklanmoqda...');
      const prayerTimes = await this.fetchPrayerTimes(lat, lon);
      if (!prayerTimes || prayerTimes.length === 0) throw new Error("Vaqtlarni yuklashda xatolik");
      this.showLoading('Taqvim yaratilmoqda...');
      const html = this.generateHTML(cityName, prayerTimes);
      const imageBase64 = await this.renderToImage(html);
      this.generatedImageBase64 = imageBase64;
      this.hideLoading();
      this.showResultPage(imageBase64, cityName);
      return imageBase64;
    } catch (error) {
      console.error('❌ Calendar generation failed:', error);
      this.hideLoading();
      this.showError(error.message);
      return null;
    }
  },

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
      const progress = Math.round((times.length / this.RAMADAN_DAYS) * 100);
      this.showLoading(`Vaqtlar yuklanmoqda... ${progress}%`);
      if (i + batchSize < this.RAMADAN_DAYS) await new Promise(r => setTimeout(r, 100));
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
        day: dayNum, date: date,
        dateStr: `${date.getDate()}-${this.MONTHS_UZ[date.getMonth()]}`,
        weekday: this.WEEKDAYS_UZ[date.getDay()],
        isFriday: date.getDay() === 5,
        suhur: timings.Fajr.slice(0, 5),
        iftar: timings.Maghrib.slice(0, 5)
      };
    } catch (e) {
      return {
        day: dayNum, date: date,
        dateStr: `${date.getDate()}-${this.MONTHS_UZ[date.getMonth()]}`,
        weekday: this.WEEKDAYS_UZ[date.getDay()],
        isFriday: date.getDay() === 5,
        suhur: '--:--', iftar: '--:--'
      };
    }
  },

  generateHTML(cityName, prayerTimes) {
    const generateTableRows = (startIdx, endIdx) => {
      let rows = '';
      for (let i = startIdx; i < endIdx; i++) {
        const day = prayerTimes[i];
        const fridayClass = day.isFriday ? ' class="friday"' : '';
        rows += `<tr${fridayClass}><td>${day.day}</td><td class="date">${day.dateStr}</td><td class="weekday">${day.weekday}</td><td class="time-suhur">${day.suhur}</td><td class="time-iftar">${day.iftar}</td></tr>`;
      }
      return rows;
    };
    
    return `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>@import url('https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Rubik:wght@400;500;600;700&display=swap');*{box-sizing:border-box;margin:0;padding:0}body{font-family:'Rubik',sans-serif;background:transparent;margin:0;padding:0}.calendar{width:540px;background:linear-gradient(180deg,#0a0a0f 0%,#12100a 30%,#1a1510 50%,#12100a 70%,#0a0a0f 100%);border-radius:16px;overflow:hidden;position:relative;padding:14px 14px 16px 14px}.calendar::before{content:'';position:absolute;top:0;left:50%;transform:translateX(-50%);width:100%;height:180px;background:radial-gradient(ellipse at top center,rgba(244,197,66,0.12) 0%,transparent 70%);pointer-events:none}.calendar::after{content:'';position:absolute;top:8px;left:8px;right:8px;bottom:8px;border:1px solid rgba(244,197,66,0.15);border-radius:12px;pointer-events:none}.lanterns{position:absolute;top:12px;left:0;right:0;display:flex;justify-content:space-between;padding:0 16px;font-size:28px;z-index:2;filter:drop-shadow(0 0 8px rgba(244,197,66,0.5))}.header{text-align:center;position:relative;z-index:1;padding-top:12px;margin-bottom:16px}.arabic{font-family:'Amiri',serif;font-size:32px;color:#f4c542;text-shadow:0 0 20px rgba(244,197,66,0.4);margin-bottom:2px}.title{font-size:18px;font-weight:700;color:#fff;letter-spacing:2px;text-transform:uppercase}.subtitle{font-size:11px;color:#f4c542;margin-top:2px;letter-spacing:0.5px}.subtitle .by-bot{color:#94a3b8;font-size:10px;margin-left:4px}.subtitle .bot-name{color:#10b981;font-weight:500}.city{display:inline-flex;align-items:center;gap:4px;margin-top:8px;padding:4px 12px;background:rgba(244,197,66,0.1);border:1px solid rgba(244,197,66,0.2);border-radius:16px;font-size:12px;color:#f4c542}.ashara-section{position:relative;z-index:1;margin-bottom:12px}.ashara-section:last-of-type{margin-bottom:0}.ashara-title{text-align:center;font-size:13px;font-weight:600;color:#f4c542;margin-bottom:8px;padding:6px 16px;background:linear-gradient(90deg,transparent,rgba(244,197,66,0.2),transparent)}.days-table{width:100%;border-collapse:collapse;font-size:11px;background:rgba(0,0,0,0.3);border-radius:10px;overflow:hidden;border:1px solid rgba(244,197,66,0.1)}.days-table thead th{background:linear-gradient(180deg,rgba(244,197,66,0.2),rgba(244,197,66,0.1));padding:8px 4px;text-align:center;font-weight:600;font-size:9px;text-transform:uppercase;letter-spacing:0.5px;color:#f4c542;border-bottom:1px solid rgba(244,197,66,0.2)}.days-table tbody tr{border-bottom:1px solid rgba(255,255,255,0.04)}.days-table tbody tr:nth-child(odd){background:rgba(255,255,255,0.02)}.days-table tbody tr:nth-child(even){background:rgba(0,0,0,0.1)}.days-table tbody tr:last-child{border-bottom:none}.days-table tbody tr.friday{background:linear-gradient(90deg,rgba(244,197,66,0.15),rgba(245,158,11,0.1),rgba(244,197,66,0.15));border-left:3px solid #f4c542}.days-table tbody tr.friday td{color:#fff}.days-table tbody tr.friday td:first-child{color:#f4c542}.days-table tbody tr.friday .weekday{color:#f4c542;font-weight:600}.days-table tbody td{padding:7px 4px;text-align:center;color:#cbd5e1}.days-table tbody td:first-child{font-weight:700;color:#f4c542;font-size:12px}.days-table .date{color:#94a3b8;font-size:10px}.days-table .weekday{color:#64748b;font-size:10px}.days-table .time-suhur{color:#a5b4fc;font-weight:600;font-size:11px}.days-table .time-iftar{color:#fcd34d;font-weight:600;font-size:11px}.stars{position:absolute;top:0;left:0;right:0;bottom:0;pointer-events:none;overflow:hidden}.star{position:absolute;color:#f4c542;font-size:8px;opacity:0.3}.star:nth-child(1){top:15%;left:5%}.star:nth-child(2){top:8%;left:20%}.star:nth-child(3){top:12%;right:15%}.star:nth-child(4){top:20%;right:8%}.star:nth-child(5){top:25%;left:10%}.star:nth-child(6){top:5%;left:40%}</style></head><body><div class="calendar"><div class="stars"><span class="star">✦</span><span class="star">✧</span><span class="star">✦</span><span class="star">✧</span><span class="star">✦</span><span class="star">✧</span></div><div class="lanterns"><span>🏮</span><span>🏮</span></div><div class="header"><div class="arabic">رمضان مبارك</div><div class="title">Ramazon Taqvimi</div><div class="subtitle">1447 Hijriy / 2026 Milodiy <span class="by-bot">by <span class="bot-name">@muslim_vegukin_bot</span></span></div><div class="city">📍 ${cityName}</div></div><div class="ashara-section"><div class="ashara-title">═══ 1-ASHARA • Rahmat ═══</div><table class="days-table"><thead><tr><th>Kun</th><th>Sana</th><th>Hafta</th><th>Saharlik</th><th>Iftorlik</th></tr></thead><tbody>${generateTableRows(0, 10)}</tbody></table></div><div class="ashara-section"><div class="ashara-title">═══ 2-ASHARA • Mag'firat ═══</div><table class="days-table"><tbody>${generateTableRows(10, 20)}</tbody></table></div><div class="ashara-section"><div class="ashara-title">═══ 3-ASHARA • Najot ═══</div><table class="days-table"><tbody>${generateTableRows(20, 30)}</tbody></table></div></div></body></html>`;
  },

  async renderToImage(html) {
    const container = document.createElement('div');
    container.id = 'calendar-render-container';
    container.style.cssText = 'position:fixed;left:-9999px;top:0;z-index:-1;background:transparent;';
    const iframe = document.createElement('iframe');
    iframe.style.cssText = 'width:600px;height:1600px;border:none;background:transparent;';
    container.appendChild(iframe);
    document.body.appendChild(container);
    iframe.contentDocument.open();
    iframe.contentDocument.write(html);
    iframe.contentDocument.close();
    await new Promise(resolve => setTimeout(resolve, 500));
    if (iframe.contentDocument.fonts) await iframe.contentDocument.fonts.ready;
    await new Promise(resolve => setTimeout(resolve, 300));
    const calendar = iframe.contentDocument.querySelector('.calendar');
    if (!calendar) { container.remove(); throw new Error('Calendar element not found'); }
    const canvas = await html2canvas(calendar, { backgroundColor: null, scale: 2, useCORS: true, allowTaint: true, logging: false });
    container.remove();
    return canvas.toDataURL('image/png', 1.0);
  },

  showLoading(text) { if (window.RamadanPage) window.RamadanPage.showLoading(text); },
  hideLoading() { if (window.RamadanPage) window.RamadanPage.hideLoading(); },

  showResultPage(imageBase64, cityName) {
    const tg = window.Telegram?.WebApp;
    this.injectResultPageStyles();
    const resultPage = document.createElement('div');
    resultPage.className = 'result-page';
    resultPage.id = 'calendarResultPage';
    resultPage.innerHTML = `
      <div class="result-page-inner">
        <header class="result-header">
          <button class="result-back-btn" id="resultBackBtn">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
          </button>
          <div class="result-header-title"><span class="result-header-icon">✨</span><h1>Taqvim tayyor!</h1></div>
          <div class="result-header-spacer"></div>
        </header>
        <div class="success-badge">
          <div class="success-icon"><svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg></div>
          <div class="success-text"><span class="success-title">Muvaffaqiyatli yaratildi!</span><span class="success-subtitle">${cityName} uchun Ramazon 2026</span></div>
        </div>
        <div class="image-preview-container">
          <div class="image-preview-wrapper" id="previewWrapper"><img src="${imageBase64}" alt="Ramazon 2026 Taqvimi - ${cityName}" class="preview-image" id="previewImage" /></div>
          <p class="preview-hint"><span class="hint-icon">👆</span>Rasmni kattalashtirish uchun bosing</p>
        </div>
        <div class="result-actions">
          <button class="action-btn primary-btn" id="saveImageBtn">
            <div class="btn-icon-wrap"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg></div>
            <div class="btn-text-wrap"><span class="btn-main-text">Rasmni saqlash</span><span class="btn-sub-text">Galereyaga yuklab olish</span></div>
          </button>
          <button class="action-btn secondary-btn" id="regenerateBtn">
            <div class="btn-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg></div>
            <span class="btn-main-text">Qaytadan yaratish</span>
          </button>
        </div>
        <div class="info-card"><div class="info-card-icon">💡</div><div class="info-card-content"><p><strong>Maslahat:</strong> Rasmni do'stlaringizga Telegram orqali yuboring yoki ijtimoiy tarmoqlarda ulashing!</p></div></div>
        <div class="bot-promo"><span class="promo-text">@muslim_vegukin_bot orqali yaratildi</span><span class="promo-heart">💚</span></div>
      </div>
      <div class="fullscreen-viewer" id="fullscreenViewer">
        <div class="fullscreen-backdrop"></div>
        <div class="fullscreen-content">
          <button class="fullscreen-close" id="fullscreenClose"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
          <div class="fullscreen-image-wrap"><img src="${imageBase64}" alt="Ramazon 2026 Taqvimi" class="fullscreen-image" id="fullscreenImage" /></div>
        </div>
      </div>`;
    document.body.appendChild(resultPage);
    requestAnimationFrame(() => resultPage.classList.add('active'));
    if (tg?.HapticFeedback) tg.HapticFeedback.notificationOccurred('success');
    this.setupResultPageEvents(resultPage, imageBase64, cityName);
  },

  setupResultPageEvents(resultPage, imageBase64, cityName) {
    const tg = window.Telegram?.WebApp;
    
    // Back button
    resultPage.querySelector('#resultBackBtn').addEventListener('click', () => {
      this.haptic('light');
      this.closeResultPage(resultPage);
    });
    
    
    
    
    
    // Save button - Open HTML page in external browser
    resultPage.querySelector('#saveImageBtn').addEventListener('click', async () => {
      this.haptic('medium');
      
      const tg = window.Telegram?.WebApp;
      const userId = tg?.initDataUnsafe?.user?.id;
      
      if (!userId) {
        tg?.showAlert('Telegram user topilmadi');
        return;
      }
      
      const btn = resultPage.querySelector('#saveImageBtn');
      const mainText = btn.querySelector('.btn-main-text');
      const subText = btn.querySelector('.btn-sub-text');
      btn.disabled = true;
      
      try {
        // Step 1
        mainText.textContent = '1/3 imgbb...';
        subText.textContent = 'Rasm yuklanmoqda';
        
        const base64Data = imageBase64.split(',')[1];
        const formData = new FormData();
        formData.append('image', base64Data);
        
        const imgbbResponse = await fetch('https://api.imgbb.com/1/upload?key=eefabc00819da88747fb75efee14a80c', {
          method: 'POST',
          body: formData
        });
        
        const imgbbResult = await imgbbResponse.json();
        
        if (!imgbbResult.success) {
          mainText.textContent = 'imgbb xato';
          subText.textContent = JSON.stringify(imgbbResult).substring(0, 30);
          return;
        }
        
        const imageUrl = imgbbResult.data.url;
        
        // Step 2
        mainText.textContent = '2/3 Lambda...';
        subText.textContent = 'Telegramga yuborilmoqda';
        
        const lambdaResponse = await fetch('https://3jvo6d2sqini7jmro7x2q4lvti0hfhyh.lambda-url.ap-southeast-2.on.aws/', {
          method: 'POST',
          mode: 'cors',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            user_id: userId,
            image_url: imageUrl,
            city: cityName
          })
        });
        
        // Step 3
        mainText.textContent = '3/3 Tekshirish...';
        subText.textContent = 'Status: ' + lambdaResponse.status;
        
        const lambdaResult = await lambdaResponse.json();
        
        if (lambdaResult.error) {
          mainText.textContent = 'Lambda xato';
          subText.textContent = lambdaResult.error.substring(0, 30);
          return;
        }
        
        mainText.textContent = '✓ Yuborildi!';
        subText.textContent = 'Chatni tekshiring';
        tg?.showAlert('✅ Rasm chatga yuborildi!');
        
      } catch (err) {
        mainText.textContent = 'Xatolik';
        subText.textContent = err.name + ': ' + err.message.substring(0, 25);
        btn.disabled = false;
      }
    });    
    
    
    // Regenerate button
    resultPage.querySelector('#regenerateBtn').addEventListener('click', () => {
      this.haptic('light');
      this.closeResultPage(resultPage);
      setTimeout(() => window.generateRamadanCalendarImage(), 400);
    });
    
    // Preview click - fullscreen
    resultPage.querySelector('#previewWrapper').addEventListener('click', () => {
      this.haptic('light');
      this.openFullscreenViewer(resultPage);
    });
    
    // Fullscreen close
    const fullscreenViewer = resultPage.querySelector('#fullscreenViewer');
    const closeFullscreen = () => { this.haptic('light'); fullscreenViewer.classList.remove('active'); };
    resultPage.querySelector('#fullscreenClose').addEventListener('click', closeFullscreen);
    resultPage.querySelector('.fullscreen-backdrop').addEventListener('click', closeFullscreen);
    
    // Telegram back button
    if (tg?.BackButton) {
      tg.BackButton.show();
      const backHandler = () => {
        if (fullscreenViewer.classList.contains('active')) closeFullscreen();
        else { this.closeResultPage(resultPage); tg.BackButton.offClick(backHandler); }
      };
      tg.BackButton.onClick(backHandler);
    }
  },

  openFullscreenViewer(resultPage) {
    resultPage.querySelector('#fullscreenViewer').classList.add('active');
    if (window.Telegram?.WebApp?.HapticFeedback) window.Telegram.WebApp.HapticFeedback.impactOccurred('light');
  },

  closeResultPage(resultPage) {
    resultPage.classList.remove('active');
    setTimeout(() => resultPage.remove(), 400);
  },

  haptic(type = 'light') {
    try { if (window.Telegram?.WebApp?.HapticFeedback) window.Telegram.WebApp.HapticFeedback.impactOccurred(type); } catch (e) {}
  },

  injectResultPageStyles() {
    if (document.getElementById('result-page-styles')) return;
    const styles = document.createElement('style');
    styles.id = 'result-page-styles';
    styles.textContent = `.result-page{position:fixed;top:0;left:0;right:0;bottom:0;z-index:1000;background:linear-gradient(180deg,#0a1628 0%,#132743 50%,#1a3a52 100%);opacity:0;transform:translateY(20px);transition:all 0.4s cubic-bezier(0.16,1,0.3,1);overflow:hidden}.result-page.active{opacity:1;transform:translateY(0)}.result-page-inner{height:100%;overflow-y:auto;padding:0 16px 32px;-webkit-overflow-scrolling:touch}.result-header{display:flex;align-items:center;padding:16px 0;position:sticky;top:0;background:linear-gradient(180deg,#0a1628 0%,rgba(10,22,40,0.95) 100%);z-index:10;margin:0 -16px;padding-left:16px;padding-right:16px}.result-back-btn{width:44px;height:44px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.08);border:1px solid rgba(255,255,255,0.1);border-radius:12px;color:#f1f5f9;cursor:pointer;transition:all 0.2s}.result-back-btn:active{transform:scale(0.95);background:rgba(255,255,255,0.15)}.result-header-title{flex:1;display:flex;align-items:center;justify-content:center;gap:8px}.result-header-icon{font-size:1.3rem}.result-header-title h1{font-size:1.1rem;font-weight:600;color:#f1f5f9;margin:0}.result-header-spacer{width:44px}.success-badge{display:flex;align-items:center;gap:14px;padding:16px 20px;background:linear-gradient(135deg,rgba(16,185,129,0.15),rgba(52,211,153,0.08));border:1px solid rgba(16,185,129,0.25);border-radius:16px;margin-bottom:20px}.success-icon{width:52px;height:52px;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,#10b981,#059669);border-radius:14px;color:white;box-shadow:0 4px 16px rgba(16,185,129,0.3);flex-shrink:0}.success-text{display:flex;flex-direction:column;gap:2px}.success-title{font-size:1rem;font-weight:600;color:#10b981}.success-subtitle{font-size:0.85rem;color:#94a3b8}.image-preview-container{margin-bottom:24px}.image-preview-wrapper{background:rgba(0,0,0,0.3);border-radius:16px;padding:12px;border:1px solid rgba(244,197,66,0.15);cursor:pointer;transition:all 0.2s}.image-preview-wrapper:active{transform:scale(0.98);border-color:rgba(244,197,66,0.4)}.preview-image{width:100%;border-radius:10px;display:block;box-shadow:0 4px 20px rgba(0,0,0,0.3)}.preview-hint{display:flex;align-items:center;justify-content:center;gap:6px;margin-top:12px;font-size:0.8rem;color:#64748b}.hint-icon{font-size:1rem}.result-actions{display:flex;flex-direction:column;gap:12px;margin-bottom:24px}.action-btn{display:flex;align-items:center;gap:14px;width:100%;padding:16px 20px;border:none;border-radius:14px;cursor:pointer;font-family:inherit;text-align:left;transition:all 0.2s}.action-btn:active{transform:scale(0.98)}.primary-btn{background:linear-gradient(135deg,#10b981,#059669);box-shadow:0 4px 20px rgba(16,185,129,0.35)}.primary-btn:active{box-shadow:0 2px 10px rgba(16,185,129,0.3)}.primary-btn .btn-icon-wrap{width:48px;height:48px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.2);border-radius:12px;color:white;flex-shrink:0}.primary-btn .btn-text-wrap{display:flex;flex-direction:column;gap:2px}.primary-btn .btn-main-text{font-size:1rem;font-weight:600;color:white}.primary-btn .btn-sub-text{font-size:0.8rem;color:rgba(255,255,255,0.75)}.secondary-btn{background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1)}.secondary-btn:active{background:rgba(255,255,255,0.1)}.secondary-btn .btn-icon-wrap{width:44px;height:44px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.08);border-radius:10px;color:#94a3b8;flex-shrink:0}.secondary-btn .btn-main-text{font-size:0.95rem;font-weight:500;color:#cbd5e1}.info-card{display:flex;gap:12px;padding:14px 16px;background:rgba(250,204,21,0.08);border:1px solid rgba(250,204,21,0.15);border-radius:12px;margin-bottom:20px}.info-card-icon{font-size:1.3rem;flex-shrink:0}.info-card-content p{font-size:0.85rem;color:#94a3b8;line-height:1.5;margin:0}.info-card-content strong{color:#f4c542}.bot-promo{display:flex;align-items:center;justify-content:center;gap:6px;padding:12px}.promo-text{font-size:0.8rem;color:#64748b}.promo-heart{font-size:0.9rem}.fullscreen-viewer{position:fixed;top:0;left:0;right:0;bottom:0;z-index:2000;display:flex;flex-direction:column;opacity:0;visibility:hidden;transition:all 0.3s ease}.fullscreen-viewer.active{opacity:1;visibility:visible}.fullscreen-backdrop{position:absolute;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.97)}.fullscreen-content{position:relative;flex:1;display:flex;flex-direction:column;padding:16px;padding-top:calc(16px + env(safe-area-inset-top,0px));padding-bottom:calc(16px + env(safe-area-inset-bottom,0px))}.fullscreen-close{position:absolute;top:calc(16px + env(safe-area-inset-top,0px));right:16px;width:48px;height:48px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.15);border:none;border-radius:50%;color:white;cursor:pointer;z-index:10;transition:all 0.2s}.fullscreen-close:active{transform:scale(0.9);background:rgba(255,255,255,0.25)}.fullscreen-image-wrap{flex:1;display:flex;align-items:center;justify-content:center;overflow:auto;padding:60px 0 20px;-webkit-overflow-scrolling:touch}.fullscreen-image{max-width:100%;max-height:100%;border-radius:12px;box-shadow:0 8px 40px rgba(0,0,0,0.5)}@supports (padding-top:env(safe-area-inset-top)){.result-header{padding-top:calc(16px + env(safe-area-inset-top))}.result-page-inner{padding-bottom:calc(32px + env(safe-area-inset-bottom))}}`;
    document.head.appendChild(styles);
  },

  showError(message) {
    const tg = window.Telegram?.WebApp;
    if (tg) tg.showAlert(`Xatolik: ${message}\n\nIltimos, qaytadan urinib ko'ring.`);
    else alert(`Xatolik: ${message}`);
  }
};

window.generateRamadanCalendarImage = function() {
  const state = window.RamadanPage?.getState?.();
  if (!state?.location) { CalendarGenerator.showError("Joylashuv topilmadi"); return; }
  const { lat, lon, city } = state.location;
  return CalendarGenerator.generate(lat, lon, city || 'Noma\'lum');
};
