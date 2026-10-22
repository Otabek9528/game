import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../barcode/barcode_screen.dart';
import '../business/business_screen.dart';
import '../hikorea/hikorea_screen.dart';
import '../hikorea/hikorea_watches.dart';
import '../links/links_screen.dart';
import '../parcel/parcel_screen.dart';
import '../places/place_detail.dart';
import '../places/places_models.dart';
import '../places/places_screen.dart';
import '../qibla/qibla_screen.dart';
import '../qna/qna_screen.dart';
import '../support/community_screen.dart';
import '../support/donation_screen.dart';
import 'feature_catalog.dart';

/// Opens a section: rebuilt natively, or its web page inside the app. From
/// the home screen, a tapped notification and an inbox message alike.
void openSection(BuildContext context, Feature feature, AppServices services) {
  HapticFeedback.lightImpact();
  // Each opening counted, as the web home page counts its cards.
  services.activity.log(feature.id);
  if (PlaceKind.fromKey(feature.id) case final kind?) {
    // A notification about one place opens it; its own type decides how it looks.
    final link = Uri.tryParse(feature.path);
    final id = int.tryParse(link?.queryParameters['id'] ?? '');
    if (id != null && (link?.path.endsWith('places-detail.html') ?? false)) return openPlaceById(context, services, id);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlacesScreen(services: services, kind: kind),
      settings: RouteSettings(name: feature.id),
    ));
    return;
  }
  final native = switch (feature.id) {
    // The phone's full sensors and camera.
    'qibla' => (BuildContext _) => QiblaScreen(services: services),
    'barcode' => (BuildContext _) => BarcodeScreen(services: services),
    'qna' => (BuildContext _) => QnaScreen(services: services),
    'business' => (BuildContext _) => BusinessScreen(services: services),
    'parcel' => (BuildContext _) => ParcelScreen(services: services),
    'links' => (BuildContext _) => LinksScreen(services: services),
    'donation' => (BuildContext _) => DonationScreen(services: services),
    'community' => (BuildContext _) => CommunityScreen(services: services),
    'hikorea' => (BuildContext _) => HikoreaScreen(services: services),
    _ => null,
  };
  if (native != null) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: native,
      settings: RouteSettings(name: feature.id == 'hikorea' ? hikoreaRouteName : feature.id),
    ));
    return;
  }
  services.openFeature(context, feature, services);
}
