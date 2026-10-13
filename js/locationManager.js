// locationManager.js
// Shared location manager for the Telegram WebApp.
//
// A fix is cheap to keep and expensive to take: a GPS lock, a reverse geocode,
// then a prayer-times refetch for every listener. So pages read the saved
// location, and a new fix is only taken when it matters:
//   - first launch (nothing saved yet)
//   - the saved fix is older than STALE_AFTER — silently, in the background
//   - the user taps a [data-location-refresh] control
//   - a feature needs a live fix (places "near me" calls locate())
// A new fix within MOVE_THRESHOLD_KM of the saved one keeps the saved
// coordinates and city, so nothing downstream refetches.
//
// Markup hooks (all optional, on any page):
//   #cityName / .city-name      city text
//   [data-location-refresh]     tap to refresh; gets is-busy / is-error /
//                               is-stale / is-done classes
//   [data-location-meta]        "2 hours ago" / "Locating…" / error text

// Resolved now, while this script is the one executing, so assets load from
// the same place whichever page included it.
const LOCATION_SCRIPT_SRC = (document.currentScript && document.currentScript.src) || location.href;

const LocationManager = {
  // Storage keys
  STORAGE_KEY: 'userLocation',
  LAST_UPDATE_KEY: 'lastLocationUpdate',

  STALE_AFTER: 6 * 60 * 60 * 1000,      // 6 hours
  MOVE_THRESHOLD_KM: 3,                 // prayer times shift ~1 min per 20 km
  REQUEST_TIMEOUT: 15000,
  AUTO_RETRY_AFTER: 10 * 60 * 1000,     // don't re-attempt a failed silent refresh on every resume
  ERROR_VISIBLE_FOR: 4000,
  UNKNOWN_CITY: 'Noma\'lum',

  tgLocationManager: null,
  isInitialized: false,
  readyPromise: null,     // settles once the Telegram LocationManager is usable (or ruled out)
  pending: null,          // { coords, done, interactive } for the request in flight
  status: 'idle',         // idle | loading | error
  lastError: null,
  lastAutoAttempt: 0,
  statusTimer: null,
  doneTimer: null,

  // Translations
  translations: {
    uz: {
      loading: 'Yuklanmoqda...',
      placeholder: 'Joylashuv',
      locating: 'Aniqlanmoqda…',
      justNow: 'Hozirgina',
      minutesAgo: '{n} daqiqa oldin',
      hoursAgo: '{n} soat oldin',
      daysAgo: '{n} kun oldin',
      failed: 'Aniqlab bo\'lmadi',
      denied: 'Ruxsat berilmagan',
      refresh: 'Joylashuvni yangilash'
    },
    ru: {
      loading: 'Загрузка...',
      placeholder: 'Геолокация',
      locating: 'Определяем…',
      justNow: 'Только что',
      minutesAgo: '{n} мин назад',
      hoursAgo: '{n} ч назад',
      daysAgo: '{n} дн. назад',
      failed: 'Не удалось',
      denied: 'Нет доступа',
      refresh: 'Обновить местоположение'
    },
    en: {
      loading: 'Loading...',
      placeholder: 'Location',
      locating: 'Locating…',
      justNow: 'Just now',
      minutesAgo: '{n} min ago',
      hoursAgo: '{n} h ago',
      daysAgo: '{n} d ago',
      failed: 'Couldn\'t locate',
      denied: 'No access',
      refresh: 'Update location'
    }
  },

  // Get current language
  getCurrentLang() {
    if (window.I18N && typeof I18N.getLanguage === 'function') {
      return I18N.getLanguage();
    }
    return localStorage.getItem('appLanguage') || 'uz';
  },

  // Get translation
  t(key, n) {
    const lang = this.getCurrentLang();
    const s = this.translations[lang]?.[key] || this.translations['en'][key];
    return n === undefined ? s : s.replace('{n}', n);
  },

  // ============================================
  // INITIALIZATION
  // ============================================

  async init() {
    // Prevent double initialization
    if (this.isInitialized) return;
    this.isInitialized = true;

    const tg = window.Telegram && Telegram.WebApp;
    if (tg) {
      tg.ready();
      try { tg.disableVerticalSwipes(); } catch (e) {}
    }

    // Telegram LocationManager (Bot API 8.0+). Older clients still expose the
    // object, but its init() never calls back there.
    const lm = tg && tg.LocationManager;
    const supported = !!lm && (typeof tg.isVersionAtLeast !== 'function' || tg.isVersionAtLeast('8.0'));
    this.tgLocationManager = supported ? lm : null;

    this.bindControls();
    this.render();

    // Relative time only — no network.
    setInterval(() => this.render(), 30 * 1000);
    window.addEventListener('languageChanged', () => this.render());
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) return;
      this.render();
      this.refreshIfStale();
    });

    this.readyPromise = this.tgLocationManager ? this.initTelegram() : Promise.resolve();
    await this.readyPromise;

    if (!this.getStoredLocation()) {
      // First launch: nothing to show without a fix, so this one may prompt.
      this.refresh({ interactive: true });
    } else {
      this.refreshIfStale();
    }
  },

  initTelegram() {
    return new Promise((resolve) => {
      const done = () => { clearTimeout(guard); resolve(); };
      const guard = setTimeout(() => {
        console.warn('⚠️ Telegram LocationManager init timed out, using browser geolocation');
        this.tgLocationManager = null;
        resolve();
      }, 3000);
      try {
        this.tgLocationManager.init(done);
      } catch (e) {
        this.tgLocationManager = null;
        done();
      }
    });
  },

  bindControls() {
    document.querySelectorAll('[data-location-refresh]').forEach((el) => {
      el.addEventListener('click', (e) => {
        // Controls can sit inside other tappable surfaces (the home prayer card).
        e.preventDefault();
        e.stopPropagation();
        if (this.status === 'loading') return;
        this.haptic('tap');
        this.refresh({ interactive: true });
      });
    });
  },

  // ============================================
  // REQUESTS
  // ============================================

  refreshIfStale() {
    const loc = this.getStoredLocation();
    if (!loc || Date.now() - (loc.timestamp || 0) < this.STALE_AFTER) return;
    if (Date.now() - this.lastAutoAttempt < this.AUTO_RETRY_AFTER) return;
    this.lastAutoAttempt = Date.now();
    this.refresh();
  },

  // Take a new fix and save it. Resolves with the saved location, or null on
  // failure. `interactive` means the user asked: failures are shown and may
  // open the permission guide; silent ones just leave the old fix in place.
  refresh(opts = {}) {
    return this.request(opts.interactive).done.catch(() => null);
  },

  // Resolves with fresh { lat, lon } as soon as the fix lands, without waiting
  // for the city lookup (which still completes and saves in the background).
  // Rejects with an Error whose .code is 'denied' | 'unavailable' | 'timeout'.
  locate(opts = {}) {
    return this.request(opts.interactive).coords;
  },

  request(interactive) {
    // Join the request in flight rather than asking Telegram twice.
    if (this.pending) {
      if (interactive) this.pending.interactive = true;
      return this.pending;
    }

    const req = { interactive: !!interactive };
    this.pending = req;
    this.setStatus('loading');

    req.coords = this.getFreshCoords();
    req.done = req.coords
      .then((coords) => this.saveCoords(coords))
      .then((data) => {
        this.setStatus('idle');
        if (req.interactive) {
          this.haptic('success');
          this.flashDone();
        }
        return data;
      }, (err) => {
        console.warn('⚠️ Location request failed:', err.code || err.message);
        if (req.interactive) {
          this.haptic('error');
          this.setStatus('error', err);
          if (err.code === 'denied' && this.tgLocationManager) this.showTogglePrompt();
        } else {
          this.setStatus('idle');
        }
        throw err;
      })
      .finally(() => {
        if (this.pending === req) this.pending = null;
      });

    // Callers may only consume one of the two; neither should surface as unhandled.
    req.coords.catch(() => {});
    req.done.catch(() => {});
    return req;
  },

  async getFreshCoords() {
    // A tap can land before Telegram's init callback; don't fall back to the
    // browser API just because it hasn't arrived yet.
    if (this.readyPromise) await this.readyPromise;
    const lm = this.tgLocationManager;
    if (lm && lm.isInited && lm.isLocationAvailable) return this.getTelegramCoords();
    return this.getBrowserCoords();
  },

  getTelegramCoords() {
    const lm = this.tgLocationManager;
    if (lm.isAccessRequested && !lm.isAccessGranted) {
      return Promise.reject(this.error('denied'));
    }
    const fix = new Promise((resolve, reject) => {
      try {
        lm.getLocation((loc) => {
          if (loc && loc.latitude != null) {
            resolve({ lat: loc.latitude, lon: loc.longitude });
          } else {
            // null with access granted means the device couldn't get a fix (GPS off).
            reject(this.error(lm.isAccessGranted ? 'unavailable' : 'denied'));
          }
        });
      } catch (e) {
        reject(this.error('unavailable'));
      }
    });
    // Only time-box once access is settled: before that, Telegram is showing its
    // permission dialog and the user may take as long as they like to read it.
    return lm.isAccessGranted ? this.withTimeout(fix, this.REQUEST_TIMEOUT) : fix;
  },

  getBrowserCoords() {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(this.error('unavailable'));
        return;
      }
      // The API's own timeout excludes the time its permission prompt is open.
      navigator.geolocation.getCurrentPosition(
        (pos) => resolve({ lat: pos.coords.latitude, lon: pos.coords.longitude }),
        (err) => reject(this.error(err.code === 1 ? 'denied' : err.code === 3 ? 'timeout' : 'unavailable')),
        { enableHighAccuracy: true, timeout: this.REQUEST_TIMEOUT, maximumAge: 60 * 1000 }
      );
    });
  },

  withTimeout(promise, ms) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(this.error('timeout')), ms);
      promise.then(
        (v) => { clearTimeout(timer); resolve(v); },
        (e) => { clearTimeout(timer); reject(e); }
      );
    });
  },

  error(code) {
    const err = new Error('Location ' + code);
    err.code = code;
    return err;
  },

  // ============================================
  // LOCATION PROCESSING
  // ============================================

  async saveCoords(coords) {
    const prev = this.getStoredLocation();
    const dist = prev ? this.distanceKm(prev, coords) : Infinity;
    const now = Date.now();
    let data;

    if (dist <= this.MOVE_THRESHOLD_KM && prev.city && prev.city !== this.UNKNOWN_CITY) {
      // Same place. Keeping the saved coordinates keeps the prayer-times cache
      // (keyed on them) valid, so only the timestamp moves.
      data = { ...prev, timestamp: now };
    } else {
      const city = await this.getCityName(coords.lat, coords.lon);
      data = {
        lat: coords.lat,
        lon: coords.lon,
        // A failed lookup after a short move is still the same city.
        city: city || (dist <= 25 ? prev.city : this.UNKNOWN_CITY),
        timestamp: now
      };
    }

    console.log('💾 Saving location:', data.city, dist === Infinity ? '(first fix)' : `(moved ${dist.toFixed(1)} km)`);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(data));
    localStorage.setItem(this.LAST_UPDATE_KEY, String(now));

    const changed = !prev || data.lat !== prev.lat || data.lon !== prev.lon || data.city !== prev.city;
    if (changed) {
      // prayerTimes.js and prayers.html listen for this and refetch.
      window.dispatchEvent(new CustomEvent('locationUpdated', { detail: data }));
    }
    return data;
  },

  async getCityName(lat, lon) {
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&accept-language=en`
      );
      const data = await res.json();
      return this.cleanCity(
        data.address.city ||
        data.address.town ||
        data.address.village ||
        data.address.county ||
        null
      );
    } catch (error) {
      console.error('Geocoding error:', error);
      return null;
    }
  },

  // Nominatim returns Korean cities with their administrative suffix
  // ("Ansan-si"); people say "Ansan", and the chip has little room.
  cleanCity(name) {
    return name ? name.replace(/-si$/i, '') : name;
  },

  distanceKm(a, b) {
    const rad = Math.PI / 180;
    const dLat = (b.lat - a.lat) * rad;
    const dLon = (b.lon - a.lon) * rad;
    const h = Math.sin(dLat / 2) ** 2 +
      Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dLon / 2) ** 2;
    return 2 * 6371 * Math.asin(Math.sqrt(h));
  },

  // ============================================
  // UI
  // ============================================

  setStatus(status, err) {
    clearTimeout(this.statusTimer);
    this.status = status;
    this.lastError = err || null;
    // With a saved fix to fall back on, the error is a passing notice. Without
    // one it stays, since there is nothing else to show.
    if (status === 'error' && this.getStoredLocation()) {
      this.statusTimer = setTimeout(() => this.setStatus('idle'), this.ERROR_VISIBLE_FOR);
    }
    this.render();
  },

  flashDone() {
    const els = document.querySelectorAll('[data-location-refresh]');
    els.forEach((el) => el.classList.remove('is-done'));
    clearTimeout(this.doneTimer);
    requestAnimationFrame(() => {
      els.forEach((el) => el.classList.add('is-done'));
      this.doneTimer = setTimeout(() => els.forEach((el) => el.classList.remove('is-done')), 1000);
    });
  },

  formatAge(ms) {
    const min = Math.floor(ms / 60000);
    if (min < 1) return this.t('justNow');
    if (min < 60) return this.t('minutesAgo', min);
    const h = Math.floor(min / 60);
    if (h < 24) return this.t('hoursAgo', h);
    return this.t('daysAgo', Math.floor(h / 24));
  },

  render() {
    const loc = this.getStoredLocation();
    const age = loc ? Date.now() - (loc.timestamp || 0) : Infinity;
    const busy = this.status === 'loading';
    const failed = this.status === 'error';

    const city = loc && loc.city ? loc.city : this.t('placeholder');
    document.querySelectorAll('#cityName, .city-name').forEach((el) => {
      if (el.textContent !== city) el.textContent = city;
    });

    let meta = '';
    if (busy) meta = this.t('locating');
    else if (failed) meta = this.t(this.lastError && this.lastError.code === 'denied' ? 'denied' : 'failed');
    else if (loc) meta = this.formatAge(age);

    document.querySelectorAll('[data-location-meta]').forEach((el) => {
      el.textContent = meta || ' ';
    });

    const label = this.t('refresh') + ' — ' + city + (meta ? ', ' + meta : '');
    document.querySelectorAll('[data-location-refresh]').forEach((el) => {
      el.classList.toggle('is-busy', busy);
      el.classList.toggle('is-error', failed);
      el.classList.toggle('is-stale', !busy && !failed && age > this.STALE_AFTER);
      el.setAttribute('aria-busy', busy ? 'true' : 'false');
      el.setAttribute('aria-label', label);
    });
  },

  haptic(kind) {
    try {
      const h = Telegram.WebApp.HapticFeedback;
      if (!h) return;
      if (kind === 'tap') h.impactOccurred('light');
      else h.notificationOccurred(kind);
    } catch (e) {}
  },

  showTogglePrompt() {
    if (document.getElementById('location-guide-modal')) return;

    const tg = Telegram.WebApp;
    const userLang = tg.initDataUnsafe?.user?.language_code || this.getCurrentLang();

    const messages = {
      uz: '1. "Sozlamalarni ochish" tugmasini bosing\n2. "Geolokatsiya" tugmachasini yoqing\n3. Ilovani qayta oching',
      ru: '1. Нажмите кнопку "Открыть настройки"\n2. Включите переключатель "Геолокация"\n3. Откройте приложение заново',
      en: '1. Tap "Open Settings" button\n2. Turn ON the "Geolocation" toggle switch\n3. Reopen the app'
    };

    const message = messages[userLang] || messages['en'];
    const guideImage = new URL('../assets/location-toggle-guide.jpg', LOCATION_SCRIPT_SRC).href;

    // CRITICAL: Trigger the toggle to appear in bot settings
    if (this.tgLocationManager) {
      try {
        this.tgLocationManager.getLocation(() => {
          console.log('🔘 Toggle trigger called');
        });
      } catch (e) {}
    }

    // Create modal overlay
    const overlay = document.createElement('div');
    overlay.id = 'location-guide-modal';
    overlay.innerHTML = `
      <style>
        #location-guide-modal {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.7);
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 10000;
          padding: 20px;
          animation: fadeIn 0.3s ease;
        }

        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }

        .guide-modal-content {
          background: white;
          border-radius: 20px;
          padding: 24px;
          max-width: 400px;
          width: 100%;
          max-height: 80vh;
          overflow-y: auto;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          animation: slideUp 0.3s ease;
        }

        @keyframes slideUp {
          from { transform: translateY(30px); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }

        .guide-modal-title {
          font-size: 1.3rem;
          font-weight: 600;
          margin: 0 0 16px 0;
          text-align: center;
          color: #333;
        }

        .guide-modal-image {
          width: 75%;
          display: block;
          margin: 0 auto 16px auto;
          border-radius: 12px;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .guide-modal-text {
          font-size: 0.95rem;
          line-height: 1.6;
          color: #555;
          margin-bottom: 20px;
          text-align: left;
        }

        .guide-modal-button {
          width: 100%;
          padding: 14px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 1rem;
          font-weight: 600;
          cursor: pointer;
          transition: transform 0.2s;
        }

        .guide-modal-button:active {
          transform: scale(0.98);
        }

        .guide-modal-text {
          white-space: pre-line;
        }
      </style>

      <div class="guide-modal-content">
        <h2 class="guide-modal-title">📍 Enable Location Access</h2>

        <img src="${guideImage}" alt="Location Toggle Guide" class="guide-modal-image">

        <p class="guide-modal-text">${message}</p>

        <button class="guide-modal-button" id="openSettingsBtn">
          Open Settings
        </button>
      </div>
    `;

    document.body.appendChild(overlay);

    // Handle button click
    document.getElementById('openSettingsBtn').addEventListener('click', () => {
      overlay.remove();
      if (tg.LocationManager && tg.LocationManager.openSettings) {
        tg.LocationManager.openSettings();
      } else {
        tg.close();
      }
    });

    // Close on overlay click
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        overlay.remove();
      }
    });
  },

  // ============================================
  // UTILITY METHODS
  // ============================================

  getStoredLocation() {
    const stored = localStorage.getItem(this.STORAGE_KEY);
    if (stored) {
      try {
        const loc = JSON.parse(stored);
        // Also covers fixes saved before cleanCity existed.
        if (loc && loc.city) loc.city = this.cleanCity(loc.city);
        return loc;
      } catch {
        return null;
      }
    }
    return null;
  },

  getCurrentLocation() {
    return this.getStoredLocation();
  },

  clearLocation() {
    localStorage.removeItem(this.STORAGE_KEY);
    localStorage.removeItem(this.LAST_UPDATE_KEY);
    // Written by earlier versions.
    localStorage.removeItem('locationPermissionGranted');
    sessionStorage.removeItem('gpsCheckedThisSession');
    console.log('🗑️ All location data cleared');
  }
};

// Auto-initialize on page load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => LocationManager.init());
} else {
  LocationManager.init();
}

// Make available globally
window.LocationManager = LocationManager;
