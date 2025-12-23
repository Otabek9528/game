// prayerTimes.js - Updated with I18N support and USER'S LOCAL TIMEZONE
Telegram.WebApp.ready();
Telegram.WebApp.disableVerticalSwipes();

// ============================================
// I18N HELPER FUNCTIONS
// ============================================

// Translate prayer name using I18N system
function translatePrayer(prayerName) {
  if (window.I18N) {
    const key = `prayer.${prayerName.toLowerCase()}`;
    const trans = I18N.t(key);
    if (trans !== key) return trans;
  }
  // Fallback to original Uzbek translations
  const FALLBACK = {
    "Fajr": "Bomdod",
    "Dhuhr": "Peshin",
    "Asr": "Asr",
    "Maghrib": "Shom",
    "Isha": "Xufton",
    "Sunrise": "Quyosh chiqishi"
  };
  return FALLBACK[prayerName] || prayerName;
}

// Translate weekday using I18N system
function translateWeekday(weekdayEnglish) {
  if (window.I18N) {
    const key = `weekday.${weekdayEnglish.toLowerCase()}`;
    const trans = I18N.t(key);
    if (trans !== key) return trans;
  }
  // Fallback to original Uzbek translations
  const FALLBACK = {
    "Monday": "Dushanba",
    "Tuesday": "Seshanba",
    "Wednesday": "Chorshanba",
    "Thursday": "Payshanba",
    "Friday": "Juma",
    "Saturday": "Shanba",
    "Sunday": "Yakshanba"
  };
  return FALLBACK[weekdayEnglish] || weekdayEnglish;
}

// Get translated month name
function translateMonth(monthIndex) {
  if (window.I18N) {
    const key = `month.${monthIndex}`;
    const trans = I18N.t(key);
    if (trans !== key) return trans;
  }
  // Fallback to original Uzbek month names
  const FALLBACK = {
    0: "Yanvar", 1: "Fevral", 2: "Mart", 3: "Aprel",
    4: "May", 5: "Iyun", 6: "Iyul", 7: "Avgust",
    8: "Sentyabr", 9: "Oktyabr", 10: "Noyabr", 11: "Dekabr"
  };
  return FALLBACK[monthIndex] || '';
}

// ============================================
// PRAYER TIME CALCULATIONS
// ============================================

async function getPrayerTimes(lat, lon) {
  // Fetch Hanafi times (school=1)
  const url = `https://api.aladhan.com/v1/timings?latitude=${lat}&longitude=${lon}&method=3&school=1`;
  const res = await fetch(url);
  const data = await res.json();
  return data.data;
}

// Fetch Asr time for Shafi'i/Maliki/Hanbali (school=0)
async function getShafiiAsrTime(lat, lon) {
  try {
    const url = `https://api.aladhan.com/v1/timings?latitude=${lat}&longitude=${lon}&method=3&school=0`;
    const res = await fetch(url);
    const data = await res.json();
    return data.data.timings.Asr;
  } catch (error) {
    console.error('Error fetching Shafi\'i Asr time:', error);
    return null;
  }
}

function getCurrentPrayer(timings) {
  // CRITICAL: Use user's local time, not server time
  const now = new Date();
  const currentTime = now.getHours() * 60 + now.getMinutes();
  
  console.log('🕐 Current local time:', now.toLocaleTimeString(), '(' + currentTime + ' minutes)');

  const prayerOrder = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
  const times = prayerOrder.map((p) => {
    const [h, m] = timings[p].split(":").map(Number);
    const totalMinutes = h * 60 + m;
    console.log(`   ${p}: ${timings[p]} (${totalMinutes} minutes)`);
    return { name: p, total: totalMinutes };
  });

  let current, next;

  // Before Fajr (midnight to Fajr) = still Isha time
  if (currentTime < times[0].total) {
    current = times[times.length - 1]; // Isha
    next = times[0]; // Fajr
  } 
  // After Isha = Isha until next day's Fajr
  else if (currentTime >= times[times.length - 1].total) {
    current = times[times.length - 1]; // Isha
    next = times[0]; // Fajr
  } 
  // Normal daytime prayers
  else {
    for (let i = 0; i < times.length - 1; i++) {
      if (currentTime >= times[i].total && currentTime < times[i + 1].total) {
        current = times[i];
        next = times[i + 1];
        break;
      }
    }
  }

  console.log('✅ Current prayer:', current.name, '| Next prayer:', next.name);
  return { current, next };
}

function formatCountdown(nextTime) {
  // CRITICAL: Use user's local time, not server time
  const now = new Date();
  const [h, m] = nextTime.split(":").map(Number);
  const next = new Date();
  next.setHours(h, m, 0, 0);
  
  let diff = (next - now) / 1000;
  if (diff < 0) diff += 24 * 3600; // Add 24 hours if next prayer is tomorrow
  
  const hrs = Math.floor(diff / 3600);
  const mins = Math.floor((diff % 3600) / 60);
  const secs = Math.floor(diff % 60);
  
  return `${hrs.toString().padStart(2, "0")}:${mins
    .toString()
    .padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
}

// ============================================
// UPDATE PRAYER DATA (with I18N)
// ============================================

async function updatePrayerData(lat, lon, city) {
  try {
    console.log('📿 Fetching prayer times for:', city, '(' + lat + ', ' + lon + ')');
    
    // Update city name display
    const cityNameElem = document.getElementById("cityName");
    if (cityNameElem && city) {
      cityNameElem.innerText = city;
      console.log('🏙️ City name updated to:', city);
    }
    
    const data = await getPrayerTimes(lat, lon);
    const { current, next } = getCurrentPrayer(data.timings);

    // Prayer emoji mapping
    const prayerEmojis = {
      "Fajr": "🌅",
      "Dhuhr": "☀️",
      "Asr": "🌤️",
      "Maghrib": "🌇",
      "Isha": "🌙"
    };

    // Update current prayer display with translated names
    const currentPrayerElem = document.getElementById("currentPrayer");
    const prayerTimeElem = document.getElementById("prayerTime");
    const currentEmojiElem = document.getElementById("currentEmoji");
    
    const nextPrayerElem = document.getElementById("nextPrayer");
    const countdownElem = document.getElementById("countdown");
    const nextEmojiElem = document.getElementById("nextEmoji");
    const nextPrayerTimeElem = document.getElementById("nextPrayerTime");

    if (currentPrayerElem) currentPrayerElem.innerText = translatePrayer(current.name);
    if (prayerTimeElem) prayerTimeElem.innerText = data.timings[current.name];
    if (currentEmojiElem) currentEmojiElem.innerText = prayerEmojis[current.name] || '🕌';
    
    if (nextPrayerElem) nextPrayerElem.innerText = translatePrayer(next.name);
    if (nextEmojiElem) nextEmojiElem.innerText = prayerEmojis[next.name] || '🕌';
    if (nextPrayerTimeElem) nextPrayerTimeElem.innerText = data.timings[next.name];

    // Update countdown every second (using local time)
    function updateCountdown() {
      if (countdownElem) {
        countdownElem.innerText = formatCountdown(data.timings[next.name]);
      }
    }
    updateCountdown();
    
    // Clear any existing interval to prevent duplicates
    if (window.prayerCountdownInterval) {
      clearInterval(window.prayerCountdownInterval);
    }
    window.prayerCountdownInterval = setInterval(updateCountdown, 1000);

    // Update date displays (using local time) with translated weekday
    const localDate = new Date();
    const weekdayEnglish = localDate.toLocaleDateString('en-US', { weekday: 'long' });
    const weekdayTranslated = translateWeekday(weekdayEnglish);
    
    // Translated month names
    const monthName = translateMonth(localDate.getMonth());
    const gregorianDate = `${localDate.getDate()}-${monthName}`;
    
    if (document.getElementById("weekday")) {
      // Format hijri: "day-monthName, year"
      const hijriDay = data.date.hijri.day;
      const hijriMonthName = data.date.hijri.month.en; // API provides month name
      const hijriYear = data.date.hijri.year;
      const hijriFormatted = `${parseInt(hijriDay)}-${hijriMonthName}, ${hijriYear}`;
      
      document.getElementById("weekday").innerText = `${weekdayTranslated}, ${gregorianDate}`;
      
      const hijriElem = document.getElementById("hijri");
      if (hijriElem) {
        hijriElem.innerText = hijriFormatted;
      }
    }

    // Update detailed page elements if they exist
    const todayDateElem = document.getElementById("todayDate");
    if (todayDateElem) {
      const hijriDay = data.date.hijri.day;
      const hijriMonthName = data.date.hijri.month.en;
      const hijriYear = data.date.hijri.year;
      const hijriFormatted = `${parseInt(hijriDay)}-${hijriMonthName}, ${hijriYear}`;
      todayDateElem.innerHTML = `${weekdayTranslated}, ${gregorianDate} <br> ${hijriFormatted}`;
    }

    const nextPrayerNameElem = document.getElementById("nextPrayerName");
    if (nextPrayerNameElem) {
      nextPrayerNameElem.innerText = translatePrayer(next.name);
    }

    // Fetch Shafi'i/Maliki/Hanbali Asr time (they use the same calculation)
    const shafiiAsrTime = await getShafiiAsrTime(lat, lon);
    
    // Update Asr schools comparison section if it exists
    updateAsrSchoolsDisplay(data.timings.Asr, shafiiAsrTime);

    // Dispatch event with prayer data for detailed page
    window.dispatchEvent(new CustomEvent('prayerDataUpdated', {
      detail: {
        timings: data.timings,
        currentPrayer: current.name,
        nextPrayer: next.name,
        date: data.date,
        shafiiAsr: shafiiAsrTime
      }
    }));

  } catch (error) {
    console.error("Error updating prayer data:", error);
  }
}

// ============================================
// EVENT LISTENERS
// ============================================

// Listen for location updates from LocationManager
window.addEventListener('locationUpdated', (event) => {
  const { lat, lon, city } = event.detail;
  updatePrayerData(lat, lon, city);
});

// Listen for language changes and re-render
window.addEventListener('languageChanged', () => {
  // Re-trigger prayer data update if we have location
  if (window.LocationManager) {
    const location = LocationManager.getCurrentLocation();
    if (location && location.lat && location.lon) {
      updatePrayerData(location.lat, location.lon, location.city);
    }
  }
});

// Make updatePrayerData available globally for LocationManager
window.updatePrayerData = updatePrayerData;

// ============================================
// ASR SCHOOLS DISPLAY
// ============================================

function updateAsrSchoolsDisplay(hanafiAsr, shafiiAsr) {
  const asrSchoolsSection = document.getElementById('asrSchoolsSection');
  if (!asrSchoolsSection) return;
  
  // Show the section
  asrSchoolsSection.style.display = 'block';
  
  // Update Hanafi time
  const hanafiTimeElem = document.getElementById('hanafiAsrTime');
  if (hanafiTimeElem) {
    hanafiTimeElem.textContent = hanafiAsr || '--:--';
  }
  
  // Update Shafi'i/Maliki/Hanbali time
  const shafiiTimeElem = document.getElementById('shafiiAsrTime');
  if (shafiiTimeElem) {
    shafiiTimeElem.textContent = shafiiAsr || '--:--';
  }
  
  console.log('🕌 Asr times updated - Hanafi:', hanafiAsr, '| Shafi\'i/Maliki/Hanbali:', shafiiAsr);
}

// Make translation functions available globally
window.translatePrayer = translatePrayer;
window.translateWeekday = translateWeekday;
window.translateMonth = translateMonth;
