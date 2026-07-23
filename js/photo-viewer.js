/* ============================================================
   photo-viewer.js — shared fullscreen photo viewer
   Used by places.html and places-detail.html.

   Architecture is ported from the Avto Bozor viewer: a horizontal
   track of slides, one zoom wrapper per slide, a single Pointer
   Events state machine (pinch | pan | swipe).

   Three fixes over the Avto Bozor version:
     1. clampPan() bounds the *rendered* image box, not the container,
        so a letterboxed photo can no longer be dragged into the void.
     2. Pinch tracks the live finger midpoint, so two-finger drag works.
     3. resize / orientationchange / Telegram viewportChanged relayout.
   Plus a distance gate on double-tap.

   Public API (window.PhotoViewer):
     PhotoViewer.open(photos, startIndex)   photos: string[] | string
     PhotoViewer.close()
     PhotoViewer.isOpen()
     PhotoViewer.configure({ onOpen, onClose })
   ============================================================ */
(function () {
  'use strict';

  var MAX_SCALE  = 5;      // pinch ceiling
  var DBL_SCALE  = 2.6;    // double-tap zoom level
  var DBL_MS     = 320;    // double-tap time window
  var DBL_DIST   = 40;     // max px between the two taps of a double-tap
  var SWIPE_FRAC = 0.18;   // fraction of width needed to commit a slide change
  var EDGE_DRAG  = 0.35;   // rubber-band factor at the first/last photo

  var hooks = { onOpen: null, onClose: null };
  var root = null, track = null, counter = null, prevBtn = null, nextBtn = null;

  var V = {
    photos: [], i: 0, open: false,
    scale: 1, tx: 0, ty: 0,
    pointers: new Map(), pinchIds: null,
    mode: null,
    startDist: 0, startScale: 1, startTx: 0, startTy: 0,
    startMid: { x: 0, y: 0 },
    panStart: null, swipeX: 0, trackBase: 0,
    lastTap: 0, lastTapX: 0, lastTapY: 0
  };

  /* ---------- small helpers ---------- */

  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
  function vW() { return (root && root.clientWidth) || window.innerWidth; }
  function vH() { return (root && root.clientHeight) || window.innerHeight; }
  function dist(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }

  function haptic() {
    try { window.Telegram.WebApp.HapticFeedback.impactOccurred('light'); } catch (e) {}
  }

  function zoomEl(k) {
    var slide = track && track.children[k];
    return slide ? slide.firstElementChild : null;
  }
  function imgEl(k) {
    var z = zoomEl(k);
    return z ? z.querySelector('.pv-img') : null;
  }

  /* ---------- DOM ---------- */

  function build() {
    if (root) return;

    root = document.createElement('div');
    root.className = 'pv';
    root.innerHTML =
      '<div class="pv-top">' +
        '<button class="pv-btn pv-close" type="button" aria-label="Yopish">&#10005;</button>' +
        '<div class="pv-count"></div>' +
      '</div>' +
      '<div class="pv-track"></div>' +
      '<button class="pv-btn pv-nav pv-prev" type="button" aria-label="Oldingi">&#8249;</button>' +
      '<button class="pv-btn pv-nav pv-next" type="button" aria-label="Keyingi">&#8250;</button>';
    document.body.appendChild(root);

    track   = root.querySelector('.pv-track');
    counter = root.querySelector('.pv-count');
    prevBtn = root.querySelector('.pv-prev');
    nextBtn = root.querySelector('.pv-next');

    root.querySelector('.pv-close').addEventListener('click', function (e) {
      e.stopPropagation(); close();
    });
    prevBtn.addEventListener('click', function (e) { e.stopPropagation(); goSlide(V.i - 1); });
    nextBtn.addEventListener('click', function (e) { e.stopPropagation(); goSlide(V.i + 1); });

    // Gestures: down on the root, move/up on the window so a finger that
    // drifts over the chrome (or off the edge) never strands the state machine.
    // No setPointerCapture — capturing on a container retargets `click`
    // and would swallow taps on the close / nav buttons.
    root.addEventListener('pointerdown', onDown);
    window.addEventListener('pointermove', onMove, { passive: false });
    window.addEventListener('pointerup', onUp);
    window.addEventListener('pointercancel', onUp);

    // FIX 3 — geometry is stored in pixels, so it must be recomputed
    // whenever the viewport changes size.
    window.addEventListener('resize', relayout);
    window.addEventListener('orientationchange', function () { setTimeout(relayout, 150); });
    try { window.Telegram.WebApp.onEvent('viewportChanged', relayout); } catch (e) {}

    document.addEventListener('keydown', onKey);

    // iOS Safari still page-zooms on pinch even with touch-action:none.
    ['gesturestart', 'gesturechange', 'gestureend'].forEach(function (t) {
      root.addEventListener(t, function (e) { e.preventDefault(); });
    });
  }

  function slideHTML() {
    return '<div class="pv-slide"><div class="pv-zoom">' +
             '<div class="pv-spin"></div>' +
             '<img class="pv-img" draggable="false" alt="">' +
             '<div class="pv-fail">Rasmni yuklab bo\'lmadi</div>' +
           '</div></div>';
  }

  // Only fetch the current photo and its immediate neighbours.
  function loadNear() {
    for (var k = V.i - 1; k <= V.i + 1; k++) {
      if (k < 0 || k >= V.photos.length) continue;
      var img = imgEl(k), z = zoomEl(k);
      if (!img || !z || img.getAttribute('src')) continue;
      (function (img, z) {
        img.onload  = function () { z.classList.add('pv-ready'); };
        img.onerror = function () { z.classList.add('pv-error'); };
      })(img, z);
      img.setAttribute('src', V.photos[k]);
    }
  }

  /* ---------- transforms ---------- */

  function setTrackX(px) { track.style.transform = 'translateX(' + px + 'px)'; }

  function applyZoom() {
    var z = zoomEl(V.i);
    if (z) z.style.transform =
      'translate(' + V.tx + 'px,' + V.ty + 'px) scale(' + V.scale + ')';
  }

  function zAnim(on) { var z = zoomEl(V.i); if (z) z.classList.toggle('pv-anim', !!on); }

  // will-change is toggled per gesture instead of left on permanently:
  // a permanently promoted layer stays visibly soft when scaled up on
  // some Android WebViews.
  function zLive(on) {
    var z = zoomEl(V.i);
    if (z) z.style.willChange = on ? 'transform' : '';
  }

  /* FIX 1 ----------------------------------------------------------
     .pv-img is object-fit:contain inside a full-viewport .pv-zoom, so
     the element box and the painted photo are not the same rectangle.
     Clamping against the element lets a letterboxed photo be dragged
     clean off screen. Clamp against the fitted content box instead.
     ---------------------------------------------------------------- */
  function fitBox() {
    var img = imgEl(V.i), W = vW(), H = vH();
    if (!img || !img.naturalWidth || !img.naturalHeight) return { w: W, h: H };
    var r = Math.min(W / img.naturalWidth, H / img.naturalHeight);
    return { w: img.naturalWidth * r, h: img.naturalHeight * r };
  }

  function clampPan() {
    var f  = fitBox();
    var mx = Math.max(0, (f.w * V.scale - vW()) / 2);
    var my = Math.max(0, (f.h * V.scale - vH()) / 2);
    V.tx = clamp(V.tx, -mx, mx);
    V.ty = clamp(V.ty, -my, my);
  }

  function resetZoom(animate) {
    V.scale = 1; V.tx = 0; V.ty = 0;
    if (animate) zAnim(true);
    applyZoom();
    if (animate) setTimeout(function () { zAnim(false); }, 280);
  }

  function updateChrome() {
    var many = V.photos.length > 1;
    counter.textContent = (V.i + 1) + ' / ' + V.photos.length;
    counter.style.display = many ? '' : 'none';
    prevBtn.style.display = (many && V.i > 0) ? '' : 'none';
    nextBtn.style.display = (many && V.i < V.photos.length - 1) ? '' : 'none';
  }

  function goSlide(i) {
    i = clamp(i, 0, V.photos.length - 1);

    // Clear the transform on the slide we are leaving, otherwise a
    // zoomed slide keeps its scale and reappears zoomed later.
    if (i !== V.i) {
      var old = zoomEl(V.i);
      if (old) { old.classList.remove('pv-anim'); old.style.transform = ''; old.style.willChange = ''; }
      haptic();
    }

    V.i = i; V.scale = 1; V.tx = 0; V.ty = 0;
    track.classList.add('pv-anim');
    setTrackX(-V.i * vW());
    applyZoom();
    updateChrome();
    loadNear();
    setTimeout(function () { track.classList.remove('pv-anim'); }, 300);
  }

  /* FIX 3 ---------------------------------------------------------- */
  function relayout() {
    if (!V.open || !track) return;
    track.classList.remove('pv-anim');
    setTrackX(-V.i * vW());
    clampPan();
    applyZoom();
  }

  /* ---------- gesture state machine ---------- */

  function pinchPair() {
    if (V.pinchIds &&
        V.pointers.has(V.pinchIds[0]) &&
        V.pointers.has(V.pinchIds[1])) {
      return [V.pointers.get(V.pinchIds[0]), V.pointers.get(V.pinchIds[1])];
    }
    var vals = Array.from(V.pointers.values());
    return [vals[0], vals[1]];
  }

  function onDown(e) {
    if (!V.open) return;
    if (e.target && e.target.closest && e.target.closest('.pv-btn')) return;

    V.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (V.pointers.size === 2) {
      // Pin the two pointer IDs so a third finger can't silently swap the pair.
      V.pinchIds = Array.from(V.pointers.keys()).slice(0, 2);
      var p = pinchPair();
      V.startDist  = dist(p[0], p[1]) || 1;
      V.startScale = V.scale;
      V.startTx    = V.tx;
      V.startTy    = V.ty;
      V.startMid   = { x: (p[0].x + p[1].x) / 2, y: (p[0].y + p[1].y) / 2 };
      V.mode = 'pinch';
      zAnim(false);
      zLive(true);
      return;
    }

    if (V.pointers.size === 1) {
      var now = Date.now();
      // Double-tap now needs both a time window and a distance gate.
      if (now - V.lastTap < DBL_MS &&
          Math.hypot(e.clientX - V.lastTapX, e.clientY - V.lastTapY) < DBL_DIST) {
        doubleTap(e);
        V.lastTap = 0;
        V.mode = null;
        return;
      }
      V.lastTap = now; V.lastTapX = e.clientX; V.lastTapY = e.clientY;

      V.panStart  = { x: e.clientX, y: e.clientY, tx: V.tx, ty: V.ty };
      V.swipeX    = e.clientX;
      V.trackBase = -V.i * vW();
      V.mode      = V.scale > 1 ? 'pan' : 'swipe';
      track.classList.remove('pv-anim');
      zLive(true);
    }
  }

  function onMove(e) {
    if (!V.open || !V.pointers.has(e.pointerId)) return;
    V.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (V.mode === 'pinch' && V.pointers.size >= 2) {
      if (e.cancelable) e.preventDefault();
      var p = pinchPair();
      if (!p[0] || !p[1]) return;

      var s   = clamp(V.startScale * dist(p[0], p[1]) / V.startDist, 1, MAX_SCALE);
      var mid = { x: (p[0].x + p[1].x) / 2, y: (p[0].y + p[1].y) / 2 };
      var cx  = vW() / 2, cy = vH() / 2;

      // focal point, in unscaled content coordinates relative to centre
      var fx = (V.startMid.x - cx - V.startTx) / V.startScale;
      var fy = (V.startMid.y - cy - V.startTy) / V.startScale;

      V.scale = s;
      // FIX 2 — focal-anchored zoom PLUS the live midpoint delta, so the
      // image follows two fingers dragging together.
      V.tx = V.startTx - fx * (s - V.startScale) + (mid.x - V.startMid.x);
      V.ty = V.startTy - fy * (s - V.startScale) + (mid.y - V.startMid.y);

      clampPan(); applyZoom();
      return;
    }

    if (V.mode === 'pan' && V.panStart) {
      if (e.cancelable) e.preventDefault();
      V.tx = V.panStart.tx + (e.clientX - V.panStart.x);
      V.ty = V.panStart.ty + (e.clientY - V.panStart.y);
      clampPan(); applyZoom();
      return;
    }

    if (V.mode === 'swipe') {
      if (e.cancelable) e.preventDefault();
      var dx = e.clientX - V.swipeX;
      if ((V.i === 0 && dx > 0) || (V.i === V.photos.length - 1 && dx < 0)) dx *= EDGE_DRAG;
      setTrackX(V.trackBase + dx);
    }
  }

  function onUp(e) {
    if (!V.open) return;
    V.pointers.delete(e.pointerId);

    if (V.mode === 'pinch') {
      if (V.pointers.size < 2) {
        V.pinchIds = null;
        if (V.scale < 1.03) {
          resetZoom(true);
          V.mode = null;
        } else if (V.pointers.size === 1) {
          var p = Array.from(V.pointers.values())[0];
          V.mode = 'pan';
          V.panStart = { x: p.x, y: p.y, tx: V.tx, ty: V.ty };
        } else {
          V.mode = null;
        }
      }
      if (V.pointers.size === 0) zLive(false);
      return;
    }

    if (V.mode === 'swipe' && V.pointers.size === 0) {
      var dx = e.clientX - V.swipeX, th = vW() * SWIPE_FRAC;
      if (dx <= -th)     goSlide(V.i + 1);
      else if (dx >= th) goSlide(V.i - 1);
      else               goSlide(V.i);
      V.mode = null;
      zLive(false);
      return;
    }

    if (V.pointers.size === 0) { V.mode = null; zLive(false); }
  }

  function doubleTap(e) {
    var cx = vW() / 2, cy = vH() / 2;
    if (V.scale > 1.05) {
      V.scale = 1; V.tx = 0; V.ty = 0;
    } else {
      V.scale = DBL_SCALE;
      // keep the tapped point stationary: tx = p * (1 - s)
      V.tx = -(e.clientX - cx) * (V.scale - 1);
      V.ty = -(e.clientY - cy) * (V.scale - 1);
      clampPan();
    }
    zAnim(true); applyZoom(); haptic();
    setTimeout(function () { zAnim(false); }, 280);
  }

  function onKey(e) {
    if (!V.open) return;
    if (e.key === 'Escape') close();
    else if (e.key === 'ArrowLeft')  goSlide(V.i - 1);
    else if (e.key === 'ArrowRight') goSlide(V.i + 1);
  }

  /* ---------- open / close ---------- */

  function open(photos, startIndex) {
    build();

    var list = (Array.isArray(photos) ? photos.slice() : [photos])
      .filter(function (u) { return !!u; });
    if (!list.length) return;

    V.photos = list;
    V.i      = clamp(startIndex || 0, 0, list.length - 1);
    V.scale  = 1; V.tx = 0; V.ty = 0;
    V.pointers.clear();
    V.pinchIds = null; V.mode = null; V.lastTap = 0;
    V.open = true;

    track.innerHTML = list.map(slideHTML).join('');
    track.classList.remove('pv-anim');

    root.classList.add('pv-on');
    document.body.classList.add('pv-locked');

    // width is only measurable once the root is displayed
    setTrackX(-V.i * vW());
    applyZoom();
    updateChrome();
    loadNear();

    if (hooks.onOpen) { try { hooks.onOpen(); } catch (err) {} }
  }

  function close() {
    if (!V.open) return;
    V.open = false;
    V.pointers.clear();
    V.pinchIds = null; V.mode = null;
    V.scale = 1; V.tx = 0; V.ty = 0;

    root.classList.remove('pv-on');
    document.body.classList.remove('pv-locked');
    track.innerHTML = '';   // release the decoded bitmaps
    V.photos = [];

    if (hooks.onClose) { try { hooks.onClose(); } catch (err) {} }
  }

  window.PhotoViewer = {
    open: open,
    close: close,
    isOpen: function () { return V.open; },
    configure: function (o) {
      if (!o) return;
      if (o.onOpen)  hooks.onOpen  = o.onOpen;
      if (o.onClose) hooks.onClose = o.onClose;
    }
  };
})();
