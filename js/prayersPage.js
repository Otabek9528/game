// prayersPage.js — Prayers page logic: list, sunnah times, settings sheet

// ============================================
// I18N HELPER
// ============================================

function t(key, fallback) {
  if (window.I18N) {
    const trans = I18N.t(key);
    return trans !== key ? trans : fallback;
  }
  return fallback;
}

// ============================================
// UI TRANSLATIONS
// ============================================

function updateUITranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (window.I18N) {
      const trans = I18N.t(key);
      if (trans !== key) {
        if (trans.includes('<strong>') || trans.includes('</strong>')) {
          el.innerHTML = trans;
        } else {
          el.textContent = trans;
        }
      }
    }
  });
  document.title = t('prayer.pageTitle', 'Bugungi Namoz Vaqtlari');
  updateMethodPillLabel();
  updateInfoMethodLine();
}

// ============================================
// METHOD PILL (in meta row)
// ============================================

function updateMethodPillLabel() {
  const methodElem = document.getElementById('methodSummaryText');
  const madhabElem = document.getElementById('madhabSummaryText');
  if (!methodElem || !madhabElem) return;

  const settings = window.getPrayerSettings
    ? window.getPrayerSettings()
    : { method: '3', madhab: '1' };

  const shortLabels = {
    '3': t('prayer.method.mwl.short', 'MWL'),
    '1': t('prayer.method.karachi.short', 'Karachi'),
    '4': t('prayer.method.makkah.short', 'Makkah'),
    '5': t('prayer.method.egypt.short', 'Egypt'),
    '2': t('prayer.method.isna.short', 'ISNA')
  };
  methodElem.textContent = shortLabels[settings.method] || 'MWL';
  madhabElem.textContent = settings.madhab === '1'
    ? t('prayer.schoolHanafi', 'Hanafiy')
    : t('prayer.schoolOthers', 'Shofe\'iy');
}

function updateInfoMethodLine() {
  const infoLine = document.getElementById('infoMethodLine');
  if (!infoLine) return;
  const settings = window.getPrayerSettings
    ? window.getPrayerSettings()
    : { method: '3' };
  const methods = window.PRAYER_METHODS || {};
  const methodName = methods[settings.method] || 'Muslim World League';
  const template = t('prayer.infoMethod',
    'Namoz vaqtlari <strong>{method}</strong> usuli bilan hisoblab chiqildi.');
  infoLine.innerHTML = template.replace(/<strong>.*?<\/strong>/, `<strong>${methodName}</strong>`);
}

// ============================================
// BOTTOM SHEET
// ============================================

function buildMethodOptions() {
  const container = document.getElementById('methodOptions');
  if (!container) return;
  container.innerHTML = '';

  const methods = window.PRAYER_METHODS || {};
  const hints = {
    '3': t('prayer.method.mwl.hint', 'Ko\'pchilik musulmon davlatlarida qo\'llaniladi'),
    '1': t('prayer.method.karachi.hint', 'Pokiston, Hindiston, Bangladesh, Afg\'oniston'),
    '4': t('prayer.method.makkah.hint', 'Saudiya Arabistoni uchun'),
    '5': t('prayer.method.egypt.hint', 'Misr va Afrika qismi uchun'),
    '2': t('prayer.method.isna.hint', 'Shimoliy Amerika uchun')
  };

  Object.entries(methods).forEach(([key, name]) => {
    const row = document.createElement('div');
    row.className = 'option-row';
    row.dataset.methodKey = key;
    row.innerHTML = `
      <div class="option-row-content">
        <span class="option-row-name">${name}</span>
        <span class="option-row-hint">${hints[key] || ''}</span>
      </div>
      <div class="option-row-radio"></div>
    `;
    row.addEventListener('click', (e) => {
      e.stopPropagation();
      selectMethod(key);
    });
    container.appendChild(row);
  });
  refreshSelectedStates();
}

function buildMadhabOptions() {
  const container = document.getElementById('madhabOptions');
  if (!container) return;
  container.innerHTML = '';

  const options = [
    {
      key: '1',
      name: t('prayer.schoolHanafi', 'Hanafiy'),
      hint: t('prayer.hanafiNote', 'Soya = 2x uzunlik')
    },
    {
      key: '0',
      name: t('prayer.schoolOthers', 'Shofe\'iy / Molikiy / Hanbaliy'),
      hint: t('prayer.shafiiNote', 'Soya = 1x uzunlik')
    }
  ];

  options.forEach(opt => {
    const row = document.createElement('div');
    row.className = 'option-row';
    row.dataset.madhabKey = opt.key;
    row.innerHTML = `
      <div class="option-row-content">
        <span class="option-row-name">${opt.name}</span>
        <span class="option-row-hint">${opt.hint}</span>
      </div>
      <div class="option-row-radio"></div>
    `;
    row.addEventListener('click', (e) => {
      e.stopPropagation();
      selectMadhab(opt.key);
    });
    container.appendChild(row);
  });
  refreshSelectedStates();
}

function refreshSelectedStates() {
  const settings = window.getPrayerSettings
    ? window.getPrayerSettings()
    : { method: '3', madhab: '1' };
  document.querySelectorAll('#methodOptions .option-row').forEach(row => {
    row.classList.toggle('selected', row.dataset.methodKey === settings.method);
  });
  document.querySelectorAll('#madhabOptions .option-row').forEach(row => {
    row.classList.toggle('selected', row.dataset.madhabKey === settings.madhab);
  });
}

function selectMethod(methodKey) {
  const current = window.getPrayerSettings();
  if (current.method === methodKey) {
    closeSheet();
    return;
  }
  window.savePrayerSettings({ method: methodKey, madhab: current.madhab });
  refreshSelectedStates();
  hapticSelection();
  window.dispatchEvent(new CustomEvent('prayerSettingsChanged'));
  setTimeout(closeSheet, 350);
}

function selectMadhab(madhabKey) {
  const current = window.getPrayerSettings();
  if (current.madhab === madhabKey) {
    closeSheet();
    return;
  }
  window.savePrayerSettings({ method: current.method, madhab: madhabKey });
  refreshSelectedStates();
  hapticSelection();
  window.dispatchEvent(new CustomEvent('prayerSettingsChanged'));
  setTimeout(closeSheet, 350);
}

function hapticSelection() {
  try {
    const tg = window.Telegram?.WebApp;
    if (tg?.HapticFeedback) tg.HapticFeedback.selectionChanged();
  } catch (e) {}
}

function openSheet() {
  console.log('🪟 openSheet called');
  const sheet = document.getElementById('bottomSheet');
  const backdrop = document.getElementById('sheetBackdrop');
  if (!sheet || !backdrop) {
    console.error('❌ Sheet elements not found');
    return;
  }
  buildMethodOptions();
  buildMadhabOptions();
  backdrop.classList.add('visible');
  requestAnimationFrame(() => sheet.classList.add('visible'));
}

function closeSheet() {
  const sheet = document.getElementById('bottomSheet');
  const backdrop = document.getElementById('sheetBackdrop');
  if (!sheet || !backdrop) return;
  sheet.classList.remove('visible');
  backdrop.classList.remove('visible');
}

function wireSheetSwipe() {
  const handle = document.getElementById('sheetHandleWrap');
  const sheet = document.getElementById('bottomSheet');
  if (!handle || !sheet) return;

  let startY = null;
  let currentY = 0;
  let dragging = false;

  const onStart = (e) => {
    dragging = true;
    startY = (e.touches ? e.touches[0].clientY : e.clientY);
    currentY = startY;
    sheet.style.transition = 'none';
  };
  const onMove = (e) => {
    if (!dragging) return;
    currentY = (e.touches ? e.touches[0].clientY : e.clientY);
    const delta = Math.max(0, currentY - startY);
    sheet.style.transform = `translateY(${delta}px)`;
  };
  const onEnd = () => {
    if (!dragging) return;
    dragging = false;
    sheet.style.transition = '';
    const delta = currentY - startY;
    sheet.style.transform = '';
    if (delta > 80) closeSheet();
  };

  handle.addEventListener('touchstart', onStart, { passive: true });
  handle.addEventListener('touchmove', onMove, { passive: true });
  handle.addEventListener('touchend', onEnd);
  handle.addEventListener('mousedown', onStart);
  window.addEventListener('mousemove', onMove);
  window.addEventListener('mouseup', onEnd);
}

// ============================================
// SUNNAH TIMES
// ============================================

const ISHRAQ_START_OFFSET_MIN = 30;
const ISHRAQ_WINDOW_MIN = 15;
const DUHA_END_OFFSET_BEFORE_DHUHR_MIN = 60;

function parseHHMM(str) {
  if (!str || typeof str !== 'string') return null;
  const clean = str.split(' ')[0];
  const [h, m] = clean.split(':').map(Number);
  if (isNaN(h) || isNaN(m)) return null;
  return h * 60 + m;
}

function formatMinutes(totalMin) {
  const h = Math.floor(totalMin / 60) % 24;
  const m = totalMin % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function computeSunnahTimes(timings) {
  const sunriseMin = parseHHMM(timings.Sunrise);
  const dhuhrMin = parseHHMM(timings.Dhuhr);
  const lastThirdRaw = timings.Lastthird || timings.LastThird;
  const result = { ishraqStart: null, ishraqEnd: null, duhaStart: null, duhaEnd: null, tahajjud: null };

  if (sunriseMin != null && dhuhrMin != null) {
    result.ishraqStart = sunriseMin + ISHRAQ_START_OFFSET_MIN;
    result.ishraqEnd = result.ishraqStart + ISHRAQ_WINDOW_MIN;
    result.duhaStart = result.ishraqEnd;
    result.duhaEnd = dhuhrMin - DUHA_END_OFFSET_BEFORE_DHUHR_MIN;
    if (result.duhaEnd <= result.duhaStart) {
      result.duhaEnd = result.duhaStart + 30;
    }
  }
  if (lastThirdRaw) result.tahajjud = parseHHMM(lastThirdRaw);
  return result;
}

function renderSunnahTimes(timings) {
  const times = computeSunnahTimes(timings);
  const ishraqElem = document.getElementById('ishraqTime');
  const duhaElem = document.getElementById('duhaTime');
  const tahajjudElem = document.getElementById('tahajjudTime');

  if (ishraqElem) {
    ishraqElem.textContent = (times.ishraqStart != null)
      ? `${formatMinutes(times.ishraqStart)} → ${formatMinutes(times.ishraqEnd)}`
      : '--:-- → --:--';
  }
  if (duhaElem) {
    duhaElem.textContent = (times.duhaStart != null)
      ? `${formatMinutes(times.duhaStart)} → ${formatMinutes(times.duhaEnd)}`
      : '--:-- → --:--';
  }
  if (tahajjudElem) {
    tahajjudElem.textContent = (times.tahajjud != null)
      ? formatMinutes(times.tahajjud)
      : '--:--';
  }
}

function wireSunnahExpanders() {
  const items = document.querySelectorAll('.sunnah-item');
  console.log(`🔧 wireSunnahExpanders: found ${items.length} items`);
  items.forEach(item => {
    item.addEventListener('click', (e) => {
      e.stopPropagation();
      console.log('📖 sunnah item tapped:', item.dataset.sunnah);
      item.classList.toggle('expanded');
      hapticSelection();
    });
  });
}

// ============================================
// TIMESTAMP / STALE DISPLAY
// ============================================

function formatTimeShort(timestamp) {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now - date;
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return t('prayer.justNow', 'hozirgina');
  if (diffMin < 60) return `${diffMin} ${t('prayer.minAgo', 'daqiqa oldin')}`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr} ${t('prayer.hrAgo', 'soat oldin')}`;
  const diffDay = Math.floor(diffHr / 24);
  return `${diffDay} ${t('prayer.dayAgo', 'kun oldin')}`;
}

function updateTimestampDisplay(timestamp) {
  const elem = document.getElementById('metaTimestamp');
  if (!elem) return;
  if (!timestamp) {
    elem.textContent = t('prayer.never', 'Hech qachon');
    return;
  }
  elem.textContent = formatTimeShort(timestamp);
  elem.classList.remove('stale');
  const refreshBtn = document.getElementById('refreshLocationBtn');
  if (refreshBtn) refreshBtn.classList.remove('stale');
}

function showStaleLocationWarning() {
  const elem = document.getElementById('metaTimestamp');
  if (elem) elem.classList.add('stale');
  const refreshBtn = document.getElementById('refreshLocationBtn');
  if (refreshBtn) refreshBtn.classList.add('stale');
}

// ============================================
// INITIALIZATION
// ============================================

function initPrayersPage() {
  console.log('🔧 initPrayersPage starting');
  const tg = window.Telegram?.WebApp;

  // Translations
  try { updateUITranslations(); } catch (e) { console.error('UI translation error:', e); }

  // Back button
  try {
    if (tg?.BackButton) {
      tg.BackButton.show();
      tg.onEvent('backButtonClicked', () => {
        window.location.href = "../index.html";
      });
    }
  } catch (e) {
    console.error('BackButton setup error:', e);
  }

  // Gear + pill → open sheet
  const gear = document.getElementById('settingsGearBtn');
  const pill = document.getElementById('methodPillBtn');
  console.log('🔧 gear:', !!gear, 'pill:', !!pill);
  if (gear) {
    gear.addEventListener('click', (e) => {
      console.log('⚙️ gear clicked');
      e.preventDefault();
      e.stopPropagation();
      openSheet();
    });
  }
  if (pill) {
    pill.addEventListener('click', (e) => {
      console.log('💊 pill clicked');
      e.preventDefault();
      e.stopPropagation();
      openSheet();
    });
  }

  // Backdrop → close
  const backdrop = document.getElementById('sheetBackdrop');
  if (backdrop) backdrop.addEventListener('click', closeSheet);

  // Esc key closes sheet
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeSheet();
  });

  wireSheetSwipe();
  wireSunnahExpanders();

  // Location refresh
  const refreshBtn = document.getElementById('refreshLocationBtn');
  const refreshIcon = document.getElementById('refreshIcon');
  if (refreshBtn && refreshIcon) {
    let isRefreshing = false;
    refreshBtn.addEventListener('click', async (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (isRefreshing) return;
      isRefreshing = true;
      refreshIcon.textContent = '🔄';
      refreshIcon.classList.add('spinning');
      refreshBtn.style.opacity = '0.5';
      refreshBtn.disabled = true;
      try {
        await LocationManager.manualRefresh();
        refreshIcon.classList.remove('spinning');
        refreshIcon.textContent = '✅';
        setTimeout(() => { refreshIcon.textContent = '📍'; }, 2000);
      } catch (error) {
        console.error('Refresh error:', error);
        refreshIcon.classList.remove('spinning');
        refreshIcon.textContent = '❌';
        setTimeout(() => { refreshIcon.textContent = '📍'; }, 2000);
      } finally {
        refreshBtn.style.opacity = '1';
        refreshBtn.disabled = false;
        isRefreshing = false;
      }
    });
  }

  // Initial timestamp
  window.addEventListener('locationUpdated', (event) => {
    updateTimestampDisplay(event.detail?.timestamp);
  });
  const location = LocationManager?.getStoredLocation?.();
  if (location?.timestamp) {
    updateTimestampDisplay(location.timestamp);
  } else {
    updateTimestampDisplay(null);
  }
  if (LocationManager?.isLocationStale?.()) {
    showStaleLocationWarning();
  }

  // Refresh timestamp "x min ago" every 30s
  setInterval(() => {
    const loc = LocationManager?.getStoredLocation?.();
    if (loc?.timestamp) updateTimestampDisplay(loc.timestamp);
  }, 30000);

  console.log('✅ initPrayersPage done');
}

// ============================================
// MAIN PRAYER LIST
// ============================================

function populateDetailedPrayerList(timings, currentPrayerName) {
  const prayerListElem = document.getElementById("prayerList");
  if (!prayerListElem) return;

  const prayerEmojis = {
    "Fajr": "🌅", "Sunrise": "🌄", "Dhuhr": "☀️",
    "Asr": "🌤️", "Maghrib": "🌇", "Isha": "🌙"
  };
  const prayerComments = {
    "Fajr": t('prayer.comment.fajr', 'Xufton vaqti tugaydi'),
    "Sunrise": t('prayer.comment.sunrise', 'Bomdod vaqti tugaydi'),
    "Dhuhr": null,
    "Asr": t('prayer.comment.asr', 'Peshin vaqti tugaydi'),
    "Maghrib": t('prayer.comment.maghrib', 'Asr vaqti tugaydi'),
    "Isha": t('prayer.comment.isha', 'Shom vaqti tugaydi')
  };

  const prayerOrder = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"];
  prayerListElem.innerHTML = '';

  prayerOrder.forEach(prayer => {
    const div = document.createElement('div');
    div.className = 'prayer-item';
    if (prayer === "Sunrise") div.classList.add('sunrise-marker');
    if (prayer === currentPrayerName && prayer !== "Sunrise") {
      div.classList.add('current-prayer');
    }

    const nameContainer = document.createElement('div');
    nameContainer.className = 'prayer-name-container';

    const emoji = document.createElement('span');
    emoji.className = 'prayer-emoji';
    emoji.textContent = prayerEmojis[prayer] || '🕌';

    const nameSpan = document.createElement('span');
    nameSpan.className = 'prayer-name-text';
    const translatedName = window.translatePrayer ? window.translatePrayer(prayer) : prayer;
    nameSpan.textContent = translatedName;

    if (prayerComments[prayer]) {
      const subtitle = document.createElement('span');
      subtitle.className = 'prayer-subtitle';
      subtitle.textContent = `(${prayerComments[prayer]})`;
      nameSpan.appendChild(document.createElement('br'));
      nameSpan.appendChild(subtitle);
    }

    nameContainer.appendChild(emoji);
    nameContainer.appendChild(nameSpan);

    const timeSpan = document.createElement('span');
    timeSpan.className = 'prayer-time-text';
    timeSpan.textContent = (timings[prayer] || '--:--').split(' ')[0];

    div.appendChild(nameContainer);
    div.appendChild(timeSpan);
    prayerListElem.appendChild(div);
  });
}

// ============================================
// EVENT LISTENERS
// ============================================

window.addEventListener('prayerDataUpdated', (event) => {
  if (event.detail?.timings && event.detail?.currentPrayer) {
    populateDetailedPrayerList(event.detail.timings, event.detail.currentPrayer);
    renderSunnahTimes(event.detail.timings);
  }
});

window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

window.addEventListener('prayerSettingsChanged', () => {
  updateMethodPillLabel();
  updateInfoMethodLine();
});

document.addEventListener('DOMContentLoaded', initPrayersPage);
