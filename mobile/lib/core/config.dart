/// Addresses the app talks to.
abstract final class AppConfig {
  /// Where the web app (the Telegram Mini App pages) is served: the links
  /// page's list, and a section the app doesn't know, in the browser.
  ///
  /// This is the GitHub Pages site of this repository. If the bot serves the
  /// pages from somewhere else, change it here.
  static final webBase = Uri.parse('https://otabek9528.github.io/game/');

  /// The live web app on Cloudflare Pages, built from the main repository:
  /// where the places' photos are (Photos/, ~1 GB). The GitHub Pages copy
  /// above has only a few.
  static final photosBase = Uri.parse('https://vegukin-twa.pages.dev/');

  /// The same live web app, for what the app follows from it (the home
  /// page's "NEW" marks).
  static final liveWebBase = Uri.parse('https://vegukin-twa.pages.dev/');

  /// The Muslim Vegukin API (places, business directory, …).
  static final apiBase = Uri.parse('https://vegukin-api.duckdns.org/');

  /// Shrinks the ingredient check's product photos for the phone: resized,
  /// sent as WebP, cached on Cloudflare (wsrv.nl, free). The originals on
  /// the API stay as they are, and are fetched directly when this can't
  /// help.
  static final photoService = Uri.parse('https://wsrv.nl/');

  /// Prayer times, same source and parameters as the web app.
  static final prayerApiBase = Uri.parse('https://api.aladhan.com/v1/');

  /// Identifies the app to free services that ask for it (OpenStreetMap).
  static const userAgent = 'MuslimVegukin/1.0 (Android; +https://t.me/MuslimVegukin)';
}
