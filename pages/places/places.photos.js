/* places.photos.js — which photos a place has, without guessing filenames.

   tools/build-photos.py writes Photos/manifest.json and a WebP copy of every
   photo next to the original (see that file for the format). With it, a
   place's photos are known after one small request, shared by every place
   on the page, instead of a burst of requests for 1.jpg, 1.jpeg, 1.png, 2.jpg,
   … — on this site a missing file costs a whole page download, because the
   host answers it with index.html.

   PlacePhotos.all(path)    -> Promise<[url, …]>   full-size photos, in order
   PlacePhotos.thumb(path)  -> Promise<url | null>  a small first photo

   A folder the manifest does not list (photos added without running the
   tool), a missing manifest, or a browser without WebP falls back to the
   original files and to looking for them the old way. */
(function () {
  'use strict';

  var BASE = '../../';
  var EXTS = ['jpg', 'jpeg', 'png'];
  var CACHE_KEY = 'vegukin_photo_manifest';
  var CACHE_MS = 10 * 60 * 1000;
  var MAX = 10;

  // Pages are separate documents, so one session would fetch the manifest on
  // every page it opens; keeping it for ten minutes skips that.
  function cached() {
    try {
      var c = JSON.parse(sessionStorage.getItem(CACHE_KEY) || 'null');
      if (c && c.folders && Date.now() - c.at < CACHE_MS) return c.folders;
    } catch (e) {}
    return null;
  }

  function loadManifest() {
    var hit = cached();
    if (hit) return Promise.resolve(hit);
    if (!window.fetch) return Promise.resolve(null);
    return fetch(BASE + 'Photos/manifest.json')
      .then(function (res) { return res.ok ? res.json() : null; })
      .then(function (data) {
        var folders = data && data.version === 1 && data.folders;
        if (!folders || typeof folders !== 'object') return null;
        try { sessionStorage.setItem(CACHE_KEY, JSON.stringify({ at: Date.now(), folders: folders })); } catch (e) {}
        return folders;
      })
      // No manifest yet (the host answers with index.html): the old way.
      .catch(function () { return null; });
  }

  // Telegram on iOS 13 and older cannot show WebP. Decoding a 1-pixel
  // image answers that without a request.
  function webpWorks() {
    return new Promise(function (resolve) {
      var img = new Image();
      img.onload = function () { resolve(img.width === 1); };
      img.onerror = function () { resolve(false); };
      img.src = 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA';
    });
  }

  // Started as soon as the script runs, alongside the page's API call.
  var ready = Promise.all([loadManifest(), webpWorks()]).then(function (r) {
    return { folders: r[0], webp: r[1] };
  });

  // Photo_path from the database, e.g. "Photos/117". Anything that is not a
  // plain relative folder is ignored.
  function clean(path) {
    var p = String(path || '').trim().replace(/^\/+|\/+$/g, '');
    if (!p || !/^[\w\-./ ]+$/.test(p) || p.indexOf('..') !== -1) return '';
    return p;
  }

  function fromManifest(m, path, kind) {
    var list = m.folders && m.folders[path];
    if (!Array.isArray(list)) return null;
    return list.slice(0, MAX).map(function (entry, i) {
      var parts = String(entry).split(':');
      var n = i + 1;
      if (!m.webp) return BASE + path + '/' + n + '.' + parts[0];
      return BASE + path + '/' + n + (kind === 'thumb' ? '.thumb' : '') + '.webp?v=' + encodeURIComponent(parts[1] || '');
    });
  }

  function exists(url) {
    return new Promise(function (resolve) {
      var img = new Image();
      img.onload = function () { resolve(true); };
      img.onerror = function () { resolve(false); };
      img.src = url;
    });
  }

  // First existing extension for photo n, or null.
  function probe(path, n) {
    return Promise.all(EXTS.map(function (ext) {
      var url = BASE + path + '/' + n + '.' + ext;
      return exists(url).then(function (ok) { return ok ? url : null; });
    })).then(function (hits) {
      for (var i = 0; i < hits.length; i++) if (hits[i]) return hits[i];
      return null;
    });
  }

  // The old way, for folders the manifest does not know: photo 1 first, and
  // only if it exists the rest in batches. Numbering stays contiguous from 1.
  function discover(path) {
    return probe(path, 1).then(function (first) {
      if (!first) return [];
      var found = [first];
      function batch(start) {
        var ns = [];
        for (var n = start; n < start + 4 && n <= MAX; n++) ns.push(n);
        if (!ns.length) return Promise.resolve(found);
        return Promise.all(ns.map(function (n) { return probe(path, n); })).then(function (hits) {
          for (var i = 0; i < hits.length; i++) {
            if (!hits[i]) return found;
            found.push(hits[i]);
          }
          return batch(start + 4);
        });
      }
      return batch(2);
    });
  }

  function all(path) {
    var p = clean(path);
    if (!p) return Promise.resolve([]);
    return ready.then(function (m) {
      return fromManifest(m, p, 'full') || discover(p);
    });
  }

  function thumb(path) {
    var p = clean(path);
    if (!p) return Promise.resolve(null);
    return ready.then(function (m) {
      var listed = fromManifest(m, p, 'thumb');
      if (listed) return listed[0] || null;
      return probe(p, 1);
    });
  }

  window.PlacePhotos = { all: all, thumb: thumb };
})();
