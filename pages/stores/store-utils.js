// ============================================
// store-utils.js — Shared helpers
// - compressImage: resize + re-encode JPEG to cut base64 payload
// - fetchJson: unified fetch with timeout + JSON parsing + error shape
// - isOnline / onConnectionChange: offline awareness
// Exposes: window.StoreUtils
// ============================================

window.StoreUtils = (() => {

  // ============================================
  // IMAGE COMPRESSION
  // Phone cameras produce 2–5MB JPEGs. Base64-encoded, that's 3–7MB
  // over the wire, which is painful on Korean cell data. This downsizes
  // to a max edge of 1280px and re-encodes at 0.8 quality.
  // ============================================
  async function compressImage(blob, opts) {
    opts = opts || {};
    const maxEdge = opts.maxEdge || 1280;
    const quality = opts.quality != null ? opts.quality : 0.8;

    if (!blob || blob.size <= 200 * 1024) return blob;  // skip tiny ones

    try {
      const src = await _loadImageSource(blob);
      const { w, h } = _scaleDims(src.width, src.height, maxEdge);

      const canvas = ('OffscreenCanvas' in window)
        ? new OffscreenCanvas(w, h)
        : Object.assign(document.createElement('canvas'), { width: w, height: h });

      const ctx = canvas.getContext('2d');
      ctx.drawImage(src.drawable, 0, 0, w, h);
      if (src.close) { try { src.close(); } catch (e) {} }

      const out = canvas.convertToBlob
        ? await canvas.convertToBlob({ type: 'image/jpeg', quality })
        : await new Promise(res => canvas.toBlob(res, 'image/jpeg', quality));

      if (out && out.size < blob.size) return out;
      return blob;
    } catch (e) {
      console.warn('compressImage failed, using original:', e);
      return blob;
    }
  }

  // Returns { drawable, width, height, close? }
  async function _loadImageSource(blob) {
    if ('createImageBitmap' in window) {
      try {
        const bm = await createImageBitmap(blob);
        return { drawable: bm, width: bm.width, height: bm.height, close: () => bm.close && bm.close() };
      } catch (e) {}
    }
    // Fallback: HTMLImageElement
    return new Promise((resolve, reject) => {
      const url = URL.createObjectURL(blob);
      const img = new Image();
      img.onload = () => {
        resolve({
          drawable: img,
          width: img.naturalWidth,
          height: img.naturalHeight,
          close: () => URL.revokeObjectURL(url),
        });
      };
      img.onerror = (e) => { URL.revokeObjectURL(url); reject(e); };
      img.src = url;
    });
  }

  function _scaleDims(w, h, maxEdge) {
    if (w <= maxEdge && h <= maxEdge) return { w, h };
    if (w >= h) {
      return { w: maxEdge, h: Math.round(h * (maxEdge / w)) };
    }
    return { w: Math.round(w * (maxEdge / h)), h: maxEdge };
  }

  // ============================================
  // FETCH WITH TIMEOUT + JSON
  // Returns { ok, status, data, error }
  // ============================================
  async function fetchJson(url, opts) {
    opts = opts || {};
    const timeoutMs = opts.timeoutMs || 20000;

    if (!isOnline()) {
      return { ok: false, status: 0, data: null, error: 'offline' };
    }

    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), timeoutMs);

    try {
      const resp = await fetch(url, Object.assign({ signal: ctrl.signal }, opts));
      clearTimeout(t);
      let data = null;
      try { data = await resp.json(); } catch (e) {}
      return { ok: resp.ok, status: resp.status, data, error: null };
    } catch (e) {
      clearTimeout(t);
      if (e.name === 'AbortError') {
        return { ok: false, status: 0, data: null, error: 'timeout' };
      }
      return { ok: false, status: 0, data: null, error: 'network' };
    }
  }

  // ============================================
  // ONLINE STATE
  // ============================================
  function isOnline() {
    return typeof navigator === 'undefined' ? true : navigator.onLine !== false;
  }

  const _onlineListeners = new Set();
  function onConnectionChange(fn) {
    _onlineListeners.add(fn);
    return () => _onlineListeners.delete(fn);
  }

  if (typeof window !== 'undefined') {
    window.addEventListener('online',  () => _onlineListeners.forEach(fn => { try { fn(true);  } catch (e) {} }));
    window.addEventListener('offline', () => _onlineListeners.forEach(fn => { try { fn(false); } catch (e) {} }));
  }

  return {
    compressImage,
    fetchJson,
    isOnline,
    onConnectionChange,
  };
})();
