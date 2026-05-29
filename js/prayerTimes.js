// prayerTimes.js - Updated with I18N, LOCAL TIMEZONE, and USER-CONFIGURABLE method + madhab
Telegram.WebApp.ready();
Telegram.WebApp.disableVerticalSwipes();

// ============================================
// PRAYER SETTINGS (method + madhab)
// ============================================

const PRAYER_METHODS = {
  '3': 'Muslim World League',
  '1': 'Karachi, Islamic Sciences Univ',
  '4': 'Umm Al-Qura, Makkah',
  '5': 'Egyptian General Authority',
  '2': 'Islamic Society of North America'
};

// Defaults: MWL + Hanafi (as requested)
const DEFAULT_METHOD = '3';
const DEFAULT_MADHAB = '1'; // 1 = Hanafi, 0 = Shafi'i/Maliki/Hanbali

const SETTINGS_STORAGE_KEY = 'prayerSettings';

function getPrayerSettings() {
  try {
    const raw = localStorage.getItem(SETTINGS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      return {
        method: PRAYER_METHODS[parsed.method] ? parsed.method : DEFAULT_METHOD,
        madhab: (parsed.madhab === '0' || parsed.madhab === '1') ? parsed.madhab : DEFAULT_MADHAB
      };
    }
  } catch (e) {
    console.warn('⚠️ Failed to read prayer settings, using defaults:', e);
  }
  return { method: DEFAULT_METHOD, madhab: DEFAULT_MADHAB };
}

function savePrayerSettings(settings) {
  try {
    localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify({
      method: settings.method,
      madhab: settings.madhab
    }));
  } catch (e) {
    console.error('❌ Failed to save prayer settings:', e);
  }
}

// Expose globally so prayersPage.js can read/write settings
window.PRAYER_METHODS = PRAYER_METHODS;
window.getPrayerSettings = getPrayerSettings;
window.savePrayerSettings = savePrayerSettings;

// ============================================
// I18N HELPER FUNCTIONS
// ============================================

function translatePrayer(prayerName) {
  if (window.I18N) {
    const key = `prayer.${prayerName.toLowerCase()}`;
    const trans = I18N.t(key);
    if (trans !== key) return trans;
  }
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

function translateWeekday(weekdayEnglish) {
  if (window.I18N) {
    const key = `weekday.${weekdayEnglish.toLowerCase()}`;
    const trans = I18N.t(key);
    if (trans !== key) return trans;
  }
  const FALLBACK = {
    "Monday": "Dushanba", "Tuesday": "Seshanba", "Wednesday": "Chorshanba",
    "Thursday": "Payshanba", "Friday": "Juma", "Saturday": "Shanba", "Sunday": "Yakshanba"
  };
  return FALLBACK[weekdayEnglish] || weekdayEnglish;
}

function translateMonth(monthIndex) {
  if (window.I18N) {
    const key = `month.${monthIndex}`;
    const trans = I18N.t(key);
    if (trans !== key) return trans;
  }
  const FALLBACK = {
    0: "Yanvar", 1: "Fevral", 2: "Mart", 3: "Aprel",
    4: "May", 5: "Iyun", 6: "Iyul", 7: "Avgust",
    8: "Sentyabr", 9: "Oktyabr", 10: "Noyabr", 11: "Dekabr"
  };
  return FALLBACK[monthIndex] || '';
}

// ============================================
// HIJRI DATE ADJUSTMENT
// ============================================
const HIJRI_ADJUSTMENT = 0;

const HIJRI_MONTHS = {
  1:  { en: "Muḥarram",        days: 30 },
  2:  { en: "Ṣafar",           days: 29 },
  3:  { en: "Rabīʿ al-Awwal",  days: 30 },
  4:  { en: "Rabīʿ al-Thānī",  days: 29 },
  5:  { en: "Jumādá al-Ūlá",   days: 30 },
  6:  { en: "Jumādá al-Ākhirah",days: 29 },
  7:  { en: "Rajab",            days: 30 },
  8:  { en: "Shaʿbān",          days: 29 },
  9:  { en: "Ramaḍān",          days: 30 },
  10: { en: "Shawwāl",          days: 29 },
  11: { en: "Dhū al-Qaʿdah",   days: 30 },
  12: { en: "Dhū al-Ḥijjah",   days: 29 }
};

function adjustHijriDate(hijriObj) {
  if (HIJRI_ADJUSTMENT === 0) return hijriObj;
  let day = parseInt(hijriObj.day);
  let monthNum = parseInt(hijriObj.month.number);
  let year = parseInt(hijriObj.year);
  day += HIJRI_ADJUSTMENT;
  if (day < 1) {
    monthNum -= 1;
    if (monthNum < 1) { monthNum = 12; year -= 1; }
    day = HIJRI_MONTHS[monthNum].days + day;
  }
  const maxDays = HIJRI_MONTHS[monthNum].days;
  if (day > maxDays) {
    day = day - maxDays;
    monthNum += 1;
    if (monthNum > 12) { monthNum = 1; year += 1; }
  }
  return {
    ...hijriObj,
    day: String(day).padStart(2, '0'),
    month: { ...hijriObj.month, number: monthNum, en: HIJRI_MONTHS[monthNum].en },
    year: String(year)
  };
}

// ============================================
// PRAYER TIME CALCULATIONS
// ============================================

async function getPrayerTimes(lat, lon) {
  const { method, madhab } = getPrayerSettings();
  const url = `https://api.aladhan.com/v1/timings?latitude=${lat}&longitude=${lon}&method=${method}&school=${madhab}&adjustment=${HIJRI_ADJUSTMENT}`;
  console.log('📿 Aladhan URL:', url);
  const res = await fetch(url);
  const data = await res.json();
  return data.data;
}

function getCurrentPrayer(timings) {
  const now = new Date();
  const currentTime = now.getHours() * 60 + now.getMinutes();
  const prayerOrder = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
  const times = prayerOrder.map((p) => {
    const [h, m] = timings[p].split(":").map(Number);
    return { name: p, total: h * 60 + m };
  });

  let current, next;
  if (currentTime < times[0].total) {
    current = times[times.length - 1];
    next = times[0];
  } else if (currentTime >= times[times.length - 1].total) {
    current = times[times.length - 1];
    next = times[0];
  } else {
    for (let i = 0; i < times.length - 1; i++) {
      if (currentTime >= times[i].total && currentTime < times[i + 1].total) {
        current = times[i];
        next = times[i + 1];
        break;
      }
    }
  }
  return { current, next };
}

function formatCountdown(nextTime) {
  const now = new Date();
  const [h, m] = nextTime.split(":").map(Number);
  const next = new Date();
  next.setHours(h, m, 0, 0);
  let diff = (next - now) / 1000;
  if (diff < 0) diff += 24 * 3600;
  const hrs = Math.floor(diff / 3600);
  const mins = Math.floor((diff % 3600) / 60);
  const secs = Math.floor(diff % 60);
  return `${hrs.toString().padStart(2, "0")}:${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
}

// Update the home-page progress line: fill % = elapsed(curStart→now) / total(curStart→nextStart).
// Badge slides along the line at the fill's leading edge.
function updateProgressLine(timings, currentName, nextName) {
  const track = document.querySelector('.progress-line');
  if (!track) return;

  const toMin = (str) => {
    if (!str) return null;
    const clean = str.split(' ')[0];
    const [h, m] = clean.split(':').map(Number);
    return h * 60 + m;
  };

  const curStart = toMin(timings[currentName]);
  const nextStart = toMin(timings[nextName]);
  if (curStart == null || nextStart == null) return;

  const now = new Date();
  const nowMin = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;

  let total, elapsed;
  if (nextStart > curStart) {
    total = nextStart - curStart;
    elapsed = nowMin >= curStart ? nowMin - curStart : 0;
  } else {
    total = (1440 - curStart) + nextStart;
    elapsed = nowMin >= curStart ? nowMin - curStart : (1440 - curStart) + nowMin;
  }

  const pct = Math.max(0, Math.min(1, elapsed / total));
  track.style.setProperty('--progress', (pct * 100).toFixed(2) + '%');
}

// ============================================
// UPDATE PRAYER DATA
// ============================================

async function updatePrayerData(lat, lon, city) {
  try {
    console.log('📿 Fetching prayer times for:', city, '(' + lat + ', ' + lon + ')');
    const cityNameElem = document.getElementById("cityName");
    if (cityNameElem && city) cityNameElem.innerText = city;

    const data = await getPrayerTimes(lat, lon);
    const { current, next } = getCurrentPrayer(data.timings);

    const prayerEmojis = {
      "Fajr": "🌅", "Dhuhr": "☀️", "Asr": "🌤️",
      "Maghrib": "🌇", "Isha": "🌙"
    };

    // Home page elements (if present)
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

    // Date / Hijri setup (used inside tick when rollover dispatches event)
    const localDate = new Date();
    const weekdayEnglish = localDate.toLocaleDateString('en-US', { weekday: 'long' });
    const weekdayTranslated = translateWeekday(weekdayEnglish);
    const monthName = translateMonth(localDate.getMonth());
    const gregorianDate = `${localDate.getDate()}-${monthName}`;
    const hijri = adjustHijriDate(data.date.hijri);
    const hijriFormatted = `${parseInt(hijri.day)}-${hijri.month.en}, ${hijri.year}`;
    const correctedDate = { ...data.date, hijri };

    if (document.getElementById("weekday")) {
      document.getElementById("weekday").innerText = `${weekdayTranslated}, ${gregorianDate}`;
      const hijriElem = document.getElementById("hijri");
      if (hijriElem) hijriElem.innerText = hijriFormatted;
    }

    const todayDateElem = document.getElementById("todayDate");
    if (todayDateElem) {
      todayDateElem.innerHTML = `${weekdayTranslated}, ${gregorianDate} | ${hijriFormatted}`;
    }

    const nextPrayerNameElem = document.getElementById("nextPrayerName");
    if (nextPrayerNameElem) nextPrayerNameElem.innerText = translatePrayer(next.name);

    // -------- Stateful tick: handles countdown + prayer rollover + progress line --------
    // The tick is idempotent — it recomputes current/next from `data.timings` every second
    // based on the wall clock, so when a prayer time passes, labels and countdown flip
    // automatically. When the day rolls over (Isha → Fajr of next day), it refetches.
    let _lastPrayerName = current.name;
    let _refetchInFlight = false;

    async function tick() {
      const { current: curNow, next: nextNow } = getCurrentPrayer(data.timings);

      // Prayer boundary crossed — update names, emojis, times on both index.html and prayers.html
      if (curNow.name !== _lastPrayerName) {
        if (currentPrayerElem) currentPrayerElem.innerText = translatePrayer(curNow.name);
        if (prayerTimeElem)   prayerTimeElem.innerText   = data.timings[curNow.name];
        if (currentEmojiElem) currentEmojiElem.innerText = prayerEmojis[curNow.name] || '🕌';
        if (nextPrayerElem)   nextPrayerElem.innerText   = translatePrayer(nextNow.name);
        if (nextEmojiElem)    nextEmojiElem.innerText    = prayerEmojis[nextNow.name] || '🕌';
        if (nextPrayerTimeElem) nextPrayerTimeElem.innerText = data.timings[nextNow.name];
        if (nextPrayerNameElem) nextPrayerNameElem.innerText = translatePrayer(nextNow.name);

        // Re-dispatch so prayers.html list re-renders its "current prayer" highlight
        window.dispatchEvent(new CustomEvent('prayerDataUpdated', {
          detail: {
            timings: data.timings,
            currentPrayer: curNow.name,
            nextPrayer: nextNow.name,
            date: correctedDate
          }
        }));

        _lastPrayerName = curNow.name;

        // Detect true day-rollover: transition into Fajr means yesterday's `data.timings`
        // is stale for today. Refetch to pick up new Hijri date, DST changes, new times.
        if (curNow.name === 'Fajr' && !_refetchInFlight) {
          _refetchInFlight = true;
          console.log('🔄 Entered Fajr — refetching timings for new day');
          try {
            await updatePrayerData(lat, lon, city);
          } catch (e) {
            console.error('Rollover refetch failed:', e);
          }
          return; // updatePrayerData restarts the interval with fresh data
        }
      }

      // Countdown text
      if (countdownElem) {
        countdownElem.innerText = formatCountdown(data.timings[nextNow.name]);
      }

      // Progress line: fraction elapsed from curNow start to nextNow start
      updateProgressLine(data.timings, curNow.name, nextNow.name);
    }

    tick();
    if (window.prayerCountdownInterval) clearInterval(window.prayerCountdownInterval);
    window.prayerCountdownInterval = setInterval(tick, 1000);

    // Dispatch event with prayer data for detailed page
    window.dispatchEvent(new CustomEvent('prayerDataUpdated', {
      detail: {
        timings: data.timings,
        currentPrayer: current.name,
        nextPrayer: next.name,
        date: correctedDate
      }
    }));

  } catch (error) {
    console.error("Error updating prayer data:", error);
  }
}

// ============================================
// EVENT LISTENERS
// ============================================

window.addEventListener('locationUpdated', (event) => {
  const { lat, lon, city } = event.detail;
  updatePrayerData(lat, lon, city);
});

window.addEventListener('languageChanged', () => {
  if (window.LocationManager) {
    const location = LocationManager.getCurrentLocation();
    if (location && location.lat && location.lon) {
      updatePrayerData(location.lat, location.lon, location.city);
    }
  }
});

// Listen for settings changes (dispatched by prayersPage.js)
window.addEventListener('prayerSettingsChanged', () => {
  console.log('⚙️ Prayer settings changed — refetching times');
  if (window.LocationManager) {
    const location = LocationManager.getCurrentLocation();
    if (location && location.lat && location.lon) {
      updatePrayerData(location.lat, location.lon, location.city);
    }
  }
});

window.updatePrayerData = updatePrayerData;
window.translatePrayer = translatePrayer;
window.translateWeekday = translateWeekday;
window.translateMonth = translateMonth;
