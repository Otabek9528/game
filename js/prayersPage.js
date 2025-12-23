// prayersPage.js - Detailed prayers page with I18N support
// Handles prayer list display and page-specific interactions

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
// UI TRANSLATIONS UPDATE
// ============================================

function updateUITranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (window.I18N) {
      const trans = I18N.t(key);
      if (trans !== key) {
        // Preserve HTML structure for items with <strong> tags
        if (trans.includes('<strong>') || trans.includes('</strong>')) {
          el.innerHTML = trans;
        } else {
          el.textContent = trans;
        }
      }
    }
  });
  
  // Update page title
  document.title = t('prayer.pageTitle', 'Bugungi Namoz Vaqtlari');
}

// ============================================
// INITIALIZE PRAYERS PAGE
// ============================================

function initPrayersPage() {
  const tg = window.Telegram.WebApp;
  
  console.log('🔧 Initializing prayers page...');
  
  // Update UI translations
  updateUITranslations();
  
  // Show and configure Telegram's BackButton
  try {
    if (tg.BackButton) {
      console.log('✅ Telegram BackButton API available');
      
      tg.BackButton.show();
      console.log('👁️ BackButton.show() called');
      
      const handleBackButton = () => {
        console.log('🔙 Back button clicked!');
        window.location.href = "../index.html";
      };
      
      tg.onEvent('backButtonClicked', handleBackButton);
      
      console.log('✅ BackButton event listener registered');
    } else {
      console.warn('⚠️ BackButton not available in this Telegram version');
    }
  } catch (e) {
    console.error('❌ Error setting up BackButton:', e);
  }

  // Handle manual location refresh button
  const refreshBtn = document.getElementById('refreshLocationBtn');
  const refreshIcon = document.getElementById('refreshIcon');
  
  if (refreshBtn && refreshIcon) {
    let isRefreshing = false;
    
    refreshBtn.addEventListener('click', async (e) => {
      console.log('🖱️ Refresh button clicked!');
      e.preventDefault();
      e.stopPropagation();
      
      if (isRefreshing) {
        console.log('⏳ Already refreshing...');
        return;
      }
      
      isRefreshing = true;
      
      // Visual feedback
      console.log('🔄 Starting animation...');
      refreshIcon.innerText = '🔄';
      refreshIcon.classList.add('spinning');
      refreshBtn.style.opacity = '0.5';
      refreshBtn.disabled = true;
      
      try {
        console.log('📞 Calling manualRefresh...');
        const result = await LocationManager.manualRefresh();
        console.log('✅ Refresh completed:', result);
        
        // Success feedback
        refreshIcon.classList.remove('spinning');
        refreshIcon.innerText = '✅';
        setTimeout(() => {
          refreshIcon.innerText = '📍';
        }, 2000);
      } catch (error) {
        console.error('❌ Refresh error:', error);
        
        // Error feedback
        refreshIcon.classList.remove('spinning');
        refreshIcon.innerText = '❌';
        setTimeout(() => {
          refreshIcon.innerText = '📍';
        }, 2000);
      } finally {
        // Re-enable button
        refreshBtn.style.opacity = '1';
        refreshBtn.disabled = false;
        isRefreshing = false;
        console.log('🔓 Button re-enabled');
      }
    });
    
    console.log('✅ Click listener added');
  }

  // Update timestamp display when location updates
  window.addEventListener('locationUpdated', (event) => {
    updateTimestampDisplay(event.detail.timestamp);
  });

  // Show initial timestamp from cached location
  const location = LocationManager.getCurrentLocation();
  
  if (location && location.timestamp) {
    updateTimestampDisplay(location.timestamp);
  } else {
    const timestampElem = document.getElementById('locationTimestamp');
    if (timestampElem) {
      const lastUpdateText = t('prayer.lastUpdate', 'Oxirgi yangilanish');
      const neverText = t('prayer.never', 'Hech qachon');
      timestampElem.innerText = `${lastUpdateText}: ${neverText}`;
    }
  }

  // Check if location is stale and show warning
  if (LocationManager.isLocationStale()) {
    showStaleLocationWarning();
  }
}

// ============================================
// TIMESTAMP DISPLAY
// ============================================

function updateTimestampDisplay(timestamp) {
  const timestampElem = document.getElementById('locationTimestamp');
  
  if (timestampElem && timestamp) {
    const date = new Date(timestamp);
    const timeString = date.toLocaleTimeString();
    const dateString = date.toLocaleDateString();
    const lastUpdateText = t('prayer.lastUpdate', 'Oxirgi yangilanish');
    const newText = `${lastUpdateText}: ${timeString}, ${dateString}`;
    
    // Update the text
    timestampElem.innerText = newText;
    
    // Reset to normal styling
    timestampElem.style.color = '#888';
    timestampElem.style.fontWeight = 'normal';
    
    console.log('✅ Timestamp updated to:', newText);
  }
}

// ============================================
// STALE LOCATION WARNING
// ============================================

function showStaleLocationWarning() {
  const timestampElem = document.getElementById('locationTimestamp');
  if (timestampElem) {
    timestampElem.style.color = '#ff9800';
    const warningText = t('prayer.staleWarning', 'Yangilashni maslahat beramiz');
    timestampElem.innerHTML += ` ⚠️ <small>(${warningText})</small>`;
  }

  // Add pulse animation to refresh button
  const refreshBtn = document.getElementById('refreshLocationBtn');
  if (refreshBtn) {
    refreshBtn.classList.add('stale');
  }
}

// ============================================
// PRAYER LIST POPULATION (with I18N)
// ============================================

function populateDetailedPrayerList(timings, currentPrayerName) {
  const prayerListElem = document.getElementById("prayerList");
  if (!prayerListElem) return;

  // Prayer emojis
  const prayerEmojis = {
    "Fajr": "🌅",
    "Sunrise": "🌄",
    "Dhuhr": "☀️",
    "Asr": "🌤️",
    "Maghrib": "🌇",
    "Isha": "🌙"
  };

  // Prayer comments - use I18N
  const prayerComments = {
    "Fajr": t('prayer.comment.fajr', 'Xufton vaqti tugaydi'),
    "Sunrise": t('prayer.comment.sunrise', 'Bomdod vaqti tugaydi'),
    "Dhuhr": null,
    "Asr": t('prayer.comment.asr', 'Peshin vaqti tugaydi'),
    "Maghrib": t('prayer.comment.maghrib', 'Asr vaqti tugaydi'),
    "Isha": t('prayer.comment.isha', 'Shom vaqti tugaydi')
  };

  // Include Sunrise between Fajr and Dhuhr
  const prayerOrder = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"];
  prayerListElem.innerHTML = '';

  prayerOrder.forEach(prayer => {
    const div = document.createElement('div');
    div.className = 'prayer-item';
    
    // Special styling for Sunrise
    if (prayer === "Sunrise") {
      div.classList.add('sunrise-marker');
    }
    
    // Highlight current prayer
    if (prayer === currentPrayerName && prayer !== "Sunrise") {
      div.classList.add('current-prayer');
    }

    // Create emoji + name container
    const nameContainer = document.createElement('div');
    nameContainer.className = 'prayer-name-container';
    
    const emoji = document.createElement('span');
    emoji.className = 'prayer-emoji';
    emoji.textContent = prayerEmojis[prayer] || '🕌';
    
    const nameSpan = document.createElement('span');
    nameSpan.className = 'prayer-name-text';
    const translatedName = window.translatePrayer ? window.translatePrayer(prayer) : prayer;
    nameSpan.textContent = translatedName;
    
    // Add subtitle/comment if exists
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
    timeSpan.textContent = timings[prayer] || '--:--';

    div.appendChild(nameContainer);
    div.appendChild(timeSpan);
    prayerListElem.appendChild(div);
  });
}

// ============================================
// EVENT LISTENERS
// ============================================

// Listen for prayer data updates
window.addEventListener('prayerDataUpdated', (event) => {
  if (event.detail && event.detail.timings && event.detail.currentPrayer) {
    populateDetailedPrayerList(event.detail.timings, event.detail.currentPrayer);
  }
});

// Listen for language changes
window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initPrayersPage);
