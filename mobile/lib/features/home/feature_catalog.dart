import '../../l10n/app_localizations.dart';

/// A section of the app. Until a section is rebuilt natively, it opens its
/// web page ([path], relative to the web app's address) inside the app.
class Feature {
  const Feature({
    required this.id,
    required this.emoji,
    required this.path,
    this.isNew = false,
    this.uzbekOnly = false,
  });

  /// Same ids as the web app's FEATURE_CARDS.
  final String id;
  final String emoji;
  final String path;
  final bool isNew;

  /// The web page exists only in Uzbek. Shown to everyone, with a UZ tag for
  /// people using the app in another language.
  final bool uzbekOnly;

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
        'prayers' => s.featurePrayers,
        _ => id,
      };
}

/// The prayer times page, opened from the prayer card.
const prayersFeature = Feature(id: 'prayers', emoji: '🕌', path: 'pages/prayers.html');

/// The business directory, shown as the gold band above the grid.
const businessFeature = Feature(
  id: 'business',
  emoji: '🏬',
  path: 'pages/business/business.html',
  isNew: true,
  uzbekOnly: true,
);

/// The grid, in the web app's order.
const featureGrid = [
  Feature(id: 'mosque', emoji: '🕌', path: 'pages/places/places.html?type=mosque'),
  Feature(id: 'restaurant', emoji: '🍽️', path: 'pages/places/places.html?type=restaurant'),
  Feature(id: 'shop', emoji: '🏪', path: 'pages/places/places.html?type=shop'),
  Feature(id: 'notifications', emoji: '🔔', path: 'pages/notifications/notifications.html', isNew: true),
  Feature(id: 'qibla', emoji: '🕋', path: 'pages/qibla/qibla.html'),
  Feature(id: 'qna', emoji: '🌐', path: 'pages/questions/qna.html', uzbekOnly: true),
  Feature(id: 'barcode', emoji: '🧪', path: 'pages/barcode/barcode.html', isNew: true),
  Feature(id: 'housing', emoji: '🏠', path: 'pages/housing/housing.html', isNew: true, uzbekOnly: true),
  Feature(id: 'cars', emoji: '🚘', path: 'pages/cars/cars.html', isNew: true, uzbekOnly: true),
  Feature(id: 'hikorea', emoji: '🛂', path: 'pages/hikorea/hikorea.html', isNew: true),
  Feature(id: 'jobs', emoji: '💼', path: 'pages/job-group/job-group.html', uzbekOnly: true),
  Feature(id: 'parcel', emoji: '📦', path: 'pages/parcel/parcel.html', uzbekOnly: true),
  Feature(id: 'links', emoji: '🔗', path: 'pages/links/links.html', uzbekOnly: true),
  Feature(id: 'donation', emoji: '🤝', path: 'pages/donation/donation.html'),
  Feature(id: 'community', emoji: '👥', path: 'pages/community/community.html'),
];
