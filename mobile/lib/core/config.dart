/// Addresses the app talks to.
abstract final class AppConfig {
  /// Where the web app (the Telegram Mini App pages) is served. Sections not
  /// yet rebuilt natively open from here inside the app.
  ///
  /// This is the GitHub Pages site of this repository. If the bot serves the
  /// pages from somewhere else, change it here.
  static final webBase = Uri.parse('https://otabek9528.github.io/game/');

  /// The Muslim Vegukin API (places, business directory, …).
  static final apiBase = Uri.parse('https://vegukin-api.duckdns.org/');

  /// Prayer times, same source and parameters as the web app.
  static final prayerApiBase = Uri.parse('https://api.aladhan.com/v1/');

  /// Identifies the app to free services that ask for it (OpenStreetMap).
  static const userAgent = 'MuslimVegukin/1.0 (Android; +https://t.me/MuslimVegukin)';
}
