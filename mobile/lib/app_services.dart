import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'core/config.dart';
import 'core/locale_controller.dart';
import 'features/home/feature_catalog.dart';
import 'features/prayer/prayer_controller.dart';

/// Opens a section: for now, its web page inside the app.
typedef FeatureOpener = void Function(
  BuildContext context,
  Feature feature,
  AppServices services,
);

/// Live numbers for the business directory band.
class BusinessStats {
  const BusinessStats({required this.businesses, required this.categories});

  final int businesses;
  final int categories;

  /// From the same endpoint the web home page uses. Null when unavailable;
  /// the band then shows its tagline instead.
  static Future<BusinessStats?> fetch() async {
    try {
      final response = await http
          .get(AppConfig.apiBase.resolve('api/business/categories'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final categories = (body['categories'] as List).cast<Map<String, dynamic>>();
      final total = categories.fold<int>(0, (n, c) => n + ((c['count'] as num?)?.toInt() ?? 0));
      if (total == 0) return null;
      return BusinessStats(businesses: total, categories: categories.length);
    } catch (_) {
      return null;
    }
  }
}

/// Everything the screens need, created once in main().
class AppServices {
  const AppServices({
    required this.locale,
    required this.prayer,
    required this.openFeature,
    this.businessStats = BusinessStats.fetch,
  });

  final LocaleController locale;
  final PrayerController prayer;
  final FeatureOpener openFeature;
  final Future<BusinessStats?> Function() businessStats;
}
