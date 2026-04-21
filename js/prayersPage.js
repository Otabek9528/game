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

  const methods = window.PRAYER_METHODS || {};
  const fallbackName = methods[settings.method] || 'Muslim World League';
  methodElem.textContent = t(`prayer.method.${settings.method}.name`, fallbackName);
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
  const fallbackName = methods[settings.method] || 'Muslim World League';
  const methodName = t(`prayer.method.${settings.method}.name`, fallbackName);
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

  Object.entries(methods).forEach(([key, fallbackName]) => {
    const row = document.createElement('div');
    row.className = 'option-row';
    row.dataset.methodKey = key;
    const translatedName = t(`prayer.method.${key}.name`, fallbackName);
    row.innerHTML = `
      <div class="option-row-content">
        <span class="option-row-name">${translatedName}</span>
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
  const m = ((totalMin % 60) + 60) % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function nowMinutes() {
  const now = new Date();
  return now.getHours() * 60 + now.getMinutes();
}

// Window status relative to current time.
// Handles windows that wrap past midnight (Tahajjud: e.g. 02:30 → 05:12 or 23:40 → 04:55).
function getWindowStatus(startMin, endMin) {
  if (startMin == null || endMin == null) {
    return { status: 'unknown', progress: 0 };
  }
  const now = nowMinutes();
  // If end < start, the window wraps across midnight. Normalize.
  const wraps = endMin < startMin;

  let inside;
  if (!wraps) {
    inside = now >= startMin && now < endMin;
  } else {
    // wrapped: either now >= start (same day) or now < end (after midnight)
    inside = now >= startMin || now < endMin;
  }

  if (inside) {
    // progress 0..1 through the window
    let elapsed, total;
    if (!wraps) {
      elapsed = now - startMin;
      total = endMin - startMin;
    } else {
      total = (1440 - startMin) + endMin;
      elapsed = (now >= startMin) ? (now - startMin) : (1440 - startMin + now);
    }
    const progress = Math.max(0, Math.min(1, elapsed / total));
    return { status: 'active', progress };
  }

  // Not inside. Determine upcoming vs passed.
  // Upcoming if start is later today (and window hasn't wrapped into yesterday).
  if (!wraps) {
    if (now < startMin) return { status: 'upcoming', progress: 0 };
    return { status: 'passed', progress: 1 };
  }
  // Wrapping window, not inside: "upcoming" if we're after end and before start today
  if (now >= endMin && now < startMin) return { status: 'upcoming', progress: 0 };
  return { status: 'passed', progress: 1 };
}

function computeSunnahTimes(timings) {
  const sunriseMin = parseHHMM(timings.Sunrise);
  const dhuhrMin = parseHHMM(timings.Dhuhr);
  const fajrMin = parseHHMM(timings.Fajr);
  const lastThirdRaw = timings.Lastthird || timings.LastThird;
  const lastThirdMin = lastThirdRaw ? parseHHMM(lastThirdRaw) : null;

  const result = {
    ishraq: { start: null, end: null },
    duha:   { start: null, end: null },
    tahajjud: { start: null, end: null }
  };

  if (sunriseMin != null && dhuhrMin != null) {
    result.ishraq.start = sunriseMin + ISHRAQ_START_OFFSET_MIN;
    result.ishraq.end   = result.ishraq.start + ISHRAQ_WINDOW_MIN;
    result.duha.start   = result.ishraq.end;
    result.duha.end     = dhuhrMin - DUHA_END_OFFSET_BEFORE_DHUHR_MIN;
    if (result.duha.end <= result.duha.start) {
      result.duha.end = result.duha.start + 30;
    }
  }

  // Tahajjud: preferred window = Lastthird → Fajr (wraps across midnight)
  if (lastThirdMin != null && fajrMin != null) {
    result.tahajjud.start = lastThirdMin;
    result.tahajjud.end = fajrMin;
  }

  return result;
}

function setSunnahRowUI(prefix, windowObj) {
  const startElem  = document.getElementById(`${prefix}Start`);
  const endElem    = document.getElementById(`${prefix}End`);
  const statusPill = document.getElementById(`${prefix}Status`);
  const track      = document.getElementById(`${prefix}Track`);
  const fill       = document.getElementById(`${prefix}Fill`);
  const dot        = document.getElementById(`${prefix}Dot`);

  if (!startElem || !endElem) return;

  if (windowObj.start == null || windowObj.end == null) {
    startElem.textContent = '--:--';
    endElem.textContent = '--:--';
    if (statusPill) {
      statusPill.textContent = '—';
      statusPill.classList.remove('active', 'upcoming', 'passed');
      statusPill.style.display = '';
    }
    if (track) track.className = 'sunnah-progress-track';
    if (fill) fill.style.width = '0%';
    return;
  }

  startElem.textContent = formatMinutes(windowObj.start);
  endElem.textContent = formatMinutes(windowObj.end);

  const { status, progress } = getWindowStatus(windowObj.start, windowObj.end);

  // Status pill — always visible, three states
  if (statusPill) {
    statusPill.classList.remove('active', 'upcoming', 'passed');
    if (status === 'active') {
      statusPill.textContent = t('prayer.status.activeNow', 'Hozir');
      statusPill.classList.add('active');
    } else if (status === 'upcoming') {
      statusPill.textContent = t('prayer.status.upcoming', 'Kutilmoqda');
      statusPill.classList.add('upcoming');
    } else if (status === 'passed') {
      statusPill.textContent = t('prayer.status.passed', 'O\'tdi');
      statusPill.classList.add('passed');
    } else {
      statusPill.textContent = '—';
    }
    statusPill.style.display = '';
  }

  // Progress track
  if (track && fill) {
    track.classList.remove('active', 'passed', 'upcoming');
    if (status === 'active') {
      track.classList.add('active');
      const pct = Math.round(progress * 100);
      fill.style.width = pct + '%';
      if (dot) dot.style.left = pct + '%';
    } else if (status === 'passed') {
      track.classList.add('passed');
      fill.style.width = '100%';
    } else if (status === 'upcoming') {
      track.classList.add('upcoming');
      fill.style.width = '0%';
    } else {
      fill.style.width = '0%';
    }
  }
}

function renderSunnahTimes(timings) {
  const times = computeSunnahTimes(timings);
  setSunnahRowUI('ishraq',   times.ishraq);
  setSunnahRowUI('duha',     times.duha);
  setSunnahRowUI('tahajjud', times.tahajjud);
}

// Keep a reference to the latest timings so we can re-render status periodically
let _latestTimings = null;

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

// ============================================
// INITIALIZATION
// ============================================

function initPrayersPage() {
  console.log('🔧 initPrayersPage starting');
  const tg = window.Telegram?.WebApp;

  // Translations
  try { updateUITranslations(); } catch (e) { console.error('UI translation error:', e); }

  // Back button — if sheet is open, close it first; otherwise navigate home
  try {
    if (tg?.BackButton) {
      tg.BackButton.show();
      tg.onEvent('backButtonClicked', () => {
        const sheet = document.getElementById('bottomSheet');
        if (sheet && sheet.classList.contains('visible')) {
          closeSheet();
          return;
        }
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
    _latestTimings = event.detail.timings;
    populateDetailedPrayerList(event.detail.timings, event.detail.currentPrayer);
    renderSunnahTimes(event.detail.timings);
  }
});

// Re-render sunnah status + progress every 30s so pills and bar stay live
setInterval(() => {
  if (_latestTimings) renderSunnahTimes(_latestTimings);
}, 30000);

window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

window.addEventListener('prayerSettingsChanged', () => {
  updateMethodPillLabel();
  updateInfoMethodLine();
});

document.addEventListener('DOMContentLoaded', initPrayersPage);
