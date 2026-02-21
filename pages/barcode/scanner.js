// scanner.js — Barcode scanning module
// Handles: detection, stability filter, scan loop
// Depends on: window.Camera
// Exposes: window.Scanner
// ============================================

window.Scanner = (() => {

  const SCAN_INTERVAL = 200;
  const STABLE_COUNT_NEEDED = 3;
  const STABLE_TIMEOUT = 2000;

  const FORMAT_NAMES = {
    'ean_13': 'EAN-13', 'ean_8': 'EAN-8', 'upc_a': 'UPC-A', 'upc_e': 'UPC-E',
    'code_128': 'Code 128', 'code_39': 'Code 39', 'code_93': 'Code 93',
    'codabar': 'Codabar', 'itf': 'ITF', 'qr_code': 'QR Code',
    'data_matrix': 'Data Matrix', 'unknown': "Noma'lum"
  };

  let barcodeDetector = null;
  let isScanning = false;
  let scanInterval = null;
  let lastScannedCode = null;

  let pendingCode = null;
  let pendingFormat = null;
  let pendingCount = 0;
  let pendingLastSeen = 0;

  let onBarcodeConfirmed = null;

  async function init() {
    if ('BarcodeDetector' in window) {
      try {
        const formats = await BarcodeDetector.getSupportedFormats();
        barcodeDetector = new BarcodeDetector({ formats });
        return true;
      } catch (e) {}
    }
    return false;
  }

  function start(videoElement, callback) {
    if (isScanning) return;
    onBarcodeConfirmed = callback;
    isScanning = true;
    _resetPending();
    scanInterval = setInterval(() => _scanFrame(videoElement), SCAN_INTERVAL);
  }

  function stop() {
    isScanning = false;
    if (scanInterval) { clearInterval(scanInterval); scanInterval = null; }
    _resetPending();
  }

  function resetLastScanned() { lastScannedCode = null; }

  function getFormatName(format) {
    return FORMAT_NAMES[format] || FORMAT_NAMES['unknown'];
  }

  async function _scanFrame(videoElement) {
    if (!isScanning || !videoElement || videoElement.readyState !== 4) return;

    try {
      let barcodes = [];

      if (barcodeDetector) {
        barcodes = await barcodeDetector.detect(videoElement);
      }

      if (barcodes.length === 0) {
        const ic = Camera.getImageCapture();
        if (ic) {
          try {
            const frame = await ic.grabFrame();
            if (frame && barcodeDetector) {
              barcodes = await barcodeDetector.detect(frame);
              frame.close();
            }
          } catch (e) {}
        }
      }

      if (barcodes.length > 0) {
        const b = barcodes[0];
        const code = b.rawValue || b.data;
        const format = b.format || 'unknown';

        if (code === lastScannedCode) return;

        if (_checkStability(code, format)) {
          lastScannedCode = code;
          stop();
          if (onBarcodeConfirmed) onBarcodeConfirmed(code, format);
        }
      }
    } catch (e) {}
  }

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

  return { init, start, stop, resetLastScanned, getFormatName };
})();
