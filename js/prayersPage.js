// prayersPage.js - Logic specific to the detailed prayers page with I18N support
// This file handles the prayer list display and page-specific interactions

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
      
      // Listen to the backButtonClicked event
      const handleBackButton = () => {
        console.log('🔙 Back button clicked');
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

  // Update timestamp display when location updates
  window.addEventListener('locationUpdated', (event) => {
    updateTimestampDisplay(event.detail.timestamp);
  });

  // Show initial timestamp from cached location
  const location = LocationManager.getStoredLocation();
  
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
// PRAYER LIST POPULATION (with I18N)
// ============================================

function populateDetailedPrayerList(timings, currentPrayerName) {
  const prayerListElem = document.getElementById("prayerList");
  if (!prayerListElem) return;

  // Prayer emojis for visual appeal
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
    "Dhuhr": null, // No comment under Peshin
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
    
    // Special styling for Sunrise (it's not a prayer time, just a marker)
    if (prayer === "Sunrise") {
      div.classList.add('sunrise-marker');
    }
    
    // Highlight current prayer (but not Sunrise)
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
    // Use translation function
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

// Listen for prayer data updates and populate the list
window.addEventListener('prayerDataUpdated', (event) => {
  if (event.detail && event.detail.timings && event.detail.currentPrayer) {
    populateDetailedPrayerList(event.detail.timings, event.detail.currentPrayer);
  }
});

// Listen for language changes
window.addEventListener('languageChanged', () => {
  updateUITranslations();
  
  // Re-populate prayer list if data exists
  // The prayerDataUpdated event will be re-dispatched by prayerTimes.js
});

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initPrayersPage);