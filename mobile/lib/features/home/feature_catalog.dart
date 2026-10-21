import '../../core/app_language.dart';
import '../../l10n/app_localizations.dart';

/// A section of the app. Until a section is rebuilt natively, it opens its
/// web page ([path], relative to the web app's address) inside the app.
class Feature {
  const Feature({
    required this.id,
    required this.emoji,
    required this.path,
    this.isNew = false,
  });

  /// Same ids as the web app's FEATURE_CARDS.
  final String id;
  final String emoji;
  final String path;
  final bool isNew;

  String label(AppLocalizations s) => switch (id) {
        'mosque' => s.featureMosques,
        'restaurant' => s.featureRestaurants,
        'shop' => s.featureShops,
        'notifications' => s.featureNotifications,
        'qibla' => s.featureQibla,
        'qna' => s.featureQna,
        'barcode' => s.featureBarcode,
        'housing' => s.featureHousing,
        'cars' => s.featureCars,
        'hikorea' => s.featureHikorea,
        'jobs' => s.featureJobs,
        'parcel' => s.featureParcel,
        'links' => s.featureLinks,
        'donation' => s.featureDonation,
        'community' => s.featureCommunity,
        'business' => s.featureBusiness,
        _ => id,
      };
}

/// The business directory, shown as the gold band above the grid.
const businessFeature = Feature(
  id: 'business',
  emoji: '🏬',
  path: 'pages/business/business.html',
  isNew: true,
);

/// The grid in Uzbek, in the web app's order.
const featureGrid = [
  Feature(id: 'mosque', emoji: '🕌', path: 'pages/places/places.html?type=mosque'),
  Feature(id: 'restaurant', emoji: '🍽️', path: 'pages/places/places.html?type=restaurant'),
  Feature(id: 'shop', emoji: '🏪', path: 'pages/places/places.html?type=shop'),
  Feature(id: 'notifications', emoji: '🔔', path: 'pages/notifications/notifications.html', isNew: true),
  Feature(id: 'qibla', emoji: '🕋', path: 'pages/qibla/qibla.html'),
  Feature(id: 'qna', emoji: '🌐', path: 'pages/questions/qna.html'),
  Feature(id: 'barcode', emoji: '🧪', path: 'pages/barcode/barcode.html', isNew: true),
  Feature(id: 'housing', emoji: '🏠', path: 'pages/housing/housing.html', isNew: true),
  Feature(id: 'cars', emoji: '🚘', path: 'pages/cars/cars.html', isNew: true),
  Feature(id: 'hikorea', emoji: '🛂', path: 'pages/hikorea/hikorea.html', isNew: true),
  Feature(id: 'jobs', emoji: '💼', path: 'pages/job-group/job-group.html'),
  Feature(id: 'parcel', emoji: '📦', path: 'pages/parcel/parcel.html'),
  Feature(id: 'links', emoji: '🔗', path: 'pages/links/links.html'),
  Feature(id: 'donation', emoji: '🤝', path: 'pages/donation/donation.html'),
  Feature(id: 'community', emoji: '👥', path: 'pages/community/community.html'),
];

/// What the web app offers people using it in Russian or English (js/i18n.js
/// availableFeatures), in its order. Those languages are for people who
/// aren't Uzbek; the sections only Uzbeks use are not shown to them.
const _otherLanguages = ['mosque', 'restaurant', 'shop', 'notifications', 'qibla', 'barcode', 'donation', 'community', 'hikorea'];

/// The grid for [language].
List<Feature> featuresFor(AppLanguage language) => language == AppLanguage.uz
    ? featureGrid
    : [for (final id in _otherLanguages) featureGrid.firstWhere((f) => f.id == id)];

/// The business directory band is for Uzbeks, as on the web.
bool showsBusiness(AppLanguage language) => language == AppLanguage.uz;

/// The page a tapped notification is about, titled like its section: a
/// place (by its type), the notifications page, HiKorea. Null when there is
/// nothing to open.
Feature? featureForPush(Map<String, String> data) {
  final url = Uri.tryParse(data['url'] ?? '');
  final at = url?.path.indexOf('/pages/') ?? -1;
  if (url != null && at != -1) {
    final path = url.path.substring(at + 1) + (url.hasQuery ? '?${url.query}' : '');
    final folder = url.pathSegments.skipWhile((s) => s != 'pages').skip(1).firstOrNull;
    final type = url.queryParameters['type'];
    final section = featureGrid.where((f) => f.id == type).firstOrNull ??
        featureGrid.where((f) => f.path.startsWith('pages/$folder/')).firstOrNull;
    return Feature(id: section?.id ?? 'notifications', emoji: section?.emoji ?? '🔔', path: path);
  }
  if (data['kind'] == 'hikorea') return featureGrid.firstWhere((f) => f.id == 'hikorea');
  return null;
}
