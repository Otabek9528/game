// ============================================
// scanner.js — Barcode scanning module
// Primary:  native BarcodeDetector  (Android Chrome, Edge, desktop Chrome)
// Fallback: ZXing-js                (iOS Safari + any browser missing the native API)
// Depends on: window.Camera
// Exposes: window.Scanner
// ============================================

window.Scanner = (() => {

  const SCAN_INTERVAL = 200;          // ms between native-detector frames
  const ZXING_SCAN_INTERVAL = 150;    // ms between ZXing frames (tuned faster)
  const STABLE_COUNT_NEEDED = 2;      // 2 consecutive matches → confirm
  const STABLE_TIMEOUT = 2000;

  // ZXing UMD loaded lazily on demand
  const ZXING_URL = 'https://cdn.jsdelivr.net/npm/@zxing/library@0.21.3/umd/index.min.js';

  const FORMAT_NAMES = {
    'ean_13': 'EAN-13', 'ean_8': 'EAN-8', 'upc_a': 'UPC-A', 'upc_e': 'UPC-E',
    'code_128': 'Code 128', 'code_39': 'Code 39', 'code_93': 'Code 93',
    'codabar': 'Codabar', 'itf': 'ITF', 'qr_code': 'QR Code',
    'data_matrix': 'Data Matrix', 'unknown': "Noma'lum"
  };

  const ZXING_FORMAT_MAP = {
    'EAN_13': 'ean_13', 'EAN_8': 'ean_8', 'UPC_A': 'upc_a', 'UPC_E': 'upc_e',
    'CODE_128': 'code_128', 'CODE_39': 'code_39', 'CODE_93': 'code_93',
    'CODABAR': 'codabar', 'ITF': 'itf', 'QR_CODE': 'qr_code',
    'DATA_MATRIX': 'data_matrix',
  };

  // --- runtime state ---
  let barcodeDetector = null;
  let zxingReader = null;
  let zxingLoading = null;
  let usingZxing = false;

  let isScanning = false;
  let scanInterval = null;
  let lastScannedCode = null;

  let pendingCode = null;
  let pendingFormat = null;
  let pendingCount = 0;
  let pendingLastSeen = 0;

  let onBarcodeConfirmed = null;

  let canvas = null;
  let canvasCtx = null;

  // ============================================
  // INIT
  // ============================================
  async function init() {
    if ('BarcodeDetector' in window) {
      try {
        const formats = await BarcodeDetector.getSupportedFormats();
        barcodeDetector = new BarcodeDetector({ formats });
        usingZxing = false;
        return true;
      } catch (e) {
        // fall through to ZXing
      }
    }
    try {
      await _loadZxing();
      usingZxing = true;
      return true;
    } catch (e) {
      console.error('ZXing failed to load:', e);
      return false;
    }
  }

  function _loadZxing() {
    if (window.ZXing && zxingReader) return Promise.resolve();
    if (zxingLoading) return zxingLoading;

    zxingLoading = new Promise((resolve, reject) => {
      if (window.ZXing) {
        try { _initZxingReader(); resolve(); } catch (e) { reject(e); }
        return;
      }
      const s = document.createElement('script');
      s.src = ZXING_URL;
      s.async = true;
      s.onload = () => {
        try { _initZxingReader(); resolve(); }
        catch (e) { reject(e); }
      };
      s.onerror = () => reject(new Error('ZXing script load failed'));
      document.head.appendChild(s);
    });
    return zxingLoading;
  }

  function _initZxingReader() {
    const Z = window.ZXing;
    if (!Z) throw new Error('ZXing global not found after load');

    const formats = [
      Z.BarcodeFormat.EAN_13, Z.BarcodeFormat.EAN_8,
      Z.BarcodeFormat.UPC_A, Z.BarcodeFormat.UPC_E,
      Z.BarcodeFormat.CODE_128, Z.BarcodeFormat.CODE_39, Z.BarcodeFormat.CODE_93,
      Z.BarcodeFormat.ITF, Z.BarcodeFormat.CODABAR,
      Z.BarcodeFormat.QR_CODE, Z.BarcodeFormat.DATA_MATRIX,
    ];

    const hints = new Map();
    hints.set(Z.DecodeHintType.POSSIBLE_FORMATS, formats);
    hints.set(Z.DecodeHintType.TRY_HARDER, true);

    zxingReader = new Z.MultiFormatReader();
    zxingReader.setHints(hints);
  }

  // ============================================
  // START / STOP
  // ============================================
  function start(videoElement, callback) {
    if (isScanning) return;
    onBarcodeConfirmed = callback;
    isScanning = true;
    _resetPending();

    const interval = usingZxing ? ZXING_SCAN_INTERVAL : SCAN_INTERVAL;
    scanInterval = setInterval(() => _scanFrame(videoElement), interval);
  }

  function stop() {
    isScanning = false;
    if (scanInterval) { clearInterval(scanInterval); scanInterval = null; }
    _resetPending();
  }

  function resetLastScanned() { lastScannedCode = null; }
  function getFormatName(format) { return FORMAT_NAMES[format] || FORMAT_NAMES['unknown']; }

  // ============================================
  // FRAME PROCESSING
  // ============================================
  async function _scanFrame(videoElement) {
    if (!isScanning || !videoElement || videoElement.readyState !== 4) return;

    try {
      let hit = null;

      if (usingZxing) {
        hit = _scanWithZxing(videoElement);
      } else if (barcodeDetector) {
        hit = await _scanWithNative(videoElement);
      }

      if (hit) {
        if (hit.code === lastScannedCode) return;
        if (_checkStability(hit.code, hit.format)) {
          lastScannedCode = hit.code;
          stop();
          if (onBarcodeConfirmed) onBarcodeConfirmed(hit.code, hit.format);
        }
      }
    } catch (e) {}
  }

  // --- Native path ---
  async function _scanWithNative(videoElement) {
    let barcodes = await barcodeDetector.detect(videoElement);

    if (barcodes.length === 0) {
      const ic = Camera.getImageCapture && Camera.getImageCapture();
      if (ic) {
        try {
          const frame = await ic.grabFrame();
          if (frame) {
            barcodes = await barcodeDetector.detect(frame);
            frame.close && frame.close();
          }
        } catch (e) {}
      }
    }

    if (barcodes.length > 0) {
      const b = barcodes[0];
      return {
        code:   b.rawValue || b.data,
        format: b.format   || 'unknown',
      };
    }
    return null;
  }

  // --- ZXing path: crops to centered scan area, downscales to ≤640px ---
  function _scanWithZxing(videoElement) {
    if (!zxingReader || !window.ZXing) return null;

    const vw = videoElement.videoWidth;
    const vh = videoElement.videoHeight;
    if (!vw || !vh) return null;

    if (!canvas) {
      canvas = document.createElement('canvas');
      canvasCtx = canvas.getContext('2d', { willReadFrequently: true });
    }

    // Crop to the centered scan-frame area users are aiming at.
    // Source rect: center 70% width × 80% height of video frame.
    const sx = Math.round(vw * 0.15);
    const sy = Math.round(vh * 0.10);
    const sw = Math.round(vw * 0.70);
    const sh = Math.round(vh * 0.80);

    // Downscale crop to ≤640px max edge.
    const maxEdge = 640;
    let w = sw, h = sh;
    if (w > maxEdge || h > maxEdge) {
      if (w >= h) { h = Math.round(h * (maxEdge / w)); w = maxEdge; }
      else        { w = Math.round(w * (maxEdge / h)); h = maxEdge; }
    }
    if (canvas.width !== w || canvas.height !== h) {
      canvas.width = w; canvas.height = h;
    }

    canvasCtx.drawImage(videoElement, sx, sy, sw, sh, 0, 0, w, h);

    const Z = window.ZXing;
    let result = null;
    try {
      const source = new Z.HTMLCanvasElementLuminanceSource(canvas);
      const binaryBitmap = new Z.BinaryBitmap(new Z.HybridBinarizer(source));
      const decoded = zxingReader.decode(binaryBitmap);
      if (decoded) {
        const fmtEnum = decoded.getBarcodeFormat && decoded.getBarcodeFormat();
        const fmtName = fmtEnum != null ? Z.BarcodeFormat[fmtEnum] : null;
        result = {
          code:   decoded.getText(),
          format: (fmtName && ZXING_FORMAT_MAP[fmtName]) || 'unknown',
        };
      }
    } catch (e) {
      result = null;
    } finally {
      if (zxingReader.reset) zxingReader.reset();
    }

    return result;
  }

  // ============================================
  // STABILITY FILTER
  // ============================================
  function _resetPending() {
    pendingCode = null; pendingFormat = null;
    pendingCount = 0; pendingLastSeen = 0;
  }

  function _checkStability(code, format) {
    const now = Date.now();
    if (code !== pendingCode) {
      pendingCode = code; pendingFormat = format;
      pendingCount = 1; pendingLastSeen = now;
      return false;
    }
    if (now - pendingLastSeen > STABLE_TIMEOUT) {
      pendingCount = 1; pendingLastSeen = now;
      return false;
    }
    pendingCount++;
    pendingLastSeen = now;
    pendingFormat = format;
    return pendingCount >= STABLE_COUNT_NEEDED;
  }

  return {
    init, start, stop, resetLastScanned, getFormatName,
    isUsingFallback: () => usingZxing,
  };
})();