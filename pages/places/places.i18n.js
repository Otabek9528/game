/* places.i18n.js — looks words up in places.text.js.

   PlacesText.t('places.searchButton')            -> "Qidirish"
   PlacesText.t('places.distanceKm', { n: 1.4 })  -> "1.4 km"
   PlacesText.apply(root)  fills elements marked with
       data-pt="key"              textContent
       data-pt-html="key"         innerHTML (only for text that carries a link)
       data-pt-placeholder="key"  placeholder attribute
       data-pt-aria="key"         aria-label attribute

   The language is the one the user picked on the home screen: from the
   shared I18N module where a page loads it, otherwise straight from
   localStorage, where I18N keeps it. Uzbek for anything not translated. */
(function () {
  'use strict';

  var LANGS = ['uz', 'ru', 'en'];
  var warned = {};

  function lang() {
    var l = null;
    try { if (window.I18N && I18N.getLanguage) l = I18N.getLanguage(); } catch (e) {}
    if (!l) {
      try { l = localStorage.getItem('vegukin_language'); } catch (e) {}
    }
    return LANGS.indexOf(l) !== -1 ? l : 'uz';
  }

  function node(key) {
    var parts = String(key).split('.');
    var cur = window.PLACES_TEXT;
    for (var i = 0; i < parts.length && cur; i++) cur = cur[parts[i]];
    return cur && typeof cur.uz === 'string' ? cur : null;
  }

  function has(key) { return !!node(key); }

  // A missing key comes back as the key itself, so it is visible on the
  // page rather than silently blank.
  function t(key, vars) {
    var n = node(key);
    if (!n) {
      if (!warned[key]) { warned[key] = true; try { console.warn('places.text.js: missing "' + key + '"'); } catch (e) {} }
      return key;
    }
    var s = n[lang()] || n.uz;
    if (vars) {
      s = s.replace(/\{(\w+)\}/g, function (m, k) {
        return Object.prototype.hasOwnProperty.call(vars, k) ? String(vars[k]) : m;
      });
    }
    return s;
  }

  function apply(root) {
    var scope = root || document;
    var i, els;
    els = scope.querySelectorAll('[data-pt]');
    for (i = 0; i < els.length; i++) els[i].textContent = t(els[i].getAttribute('data-pt'));
    els = scope.querySelectorAll('[data-pt-html]');
    for (i = 0; i < els.length; i++) els[i].innerHTML = t(els[i].getAttribute('data-pt-html'));
    els = scope.querySelectorAll('[data-pt-placeholder]');
    for (i = 0; i < els.length; i++) els[i].placeholder = t(els[i].getAttribute('data-pt-placeholder'));
    els = scope.querySelectorAll('[data-pt-aria]');
    for (i = 0; i < els.length; i++) els[i].setAttribute('aria-label', t(els[i].getAttribute('data-pt-aria')));
  }

  // Escapes a value for HTML text or a double-quoted attribute. Everything a
  // place, a review or the server supplies goes through this before it is
  // put into innerHTML.
  function esc(v) {
    return String(v == null ? '' : v)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  // Only http(s) links may become an href; anything else (javascript:,
  // data:, …) is dropped.
  function safeUrl(v) {
    var s = String(v == null ? '' : v).trim();
    return /^https?:\/\//i.test(s) ? s : '';
  }

  window.PlacesText = { t: t, has: has, apply: apply, lang: lang, esc: esc, safeUrl: safeUrl };
})();
