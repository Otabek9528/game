import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'parcel_models.dart';

/// The parcel posts, from the same endpoints the web page uses
/// (pages/parcel/parcel.js).
abstract interface class ParcelSource {
  Future<List<ParcelDate>> dates(ParcelDirection direction);
  Future<List<ParcelPost>> postsByDate(String date, ParcelDirection direction);
  Future<List<ParcelCity>> cities(ParcelCountry country, ParcelDirection direction);
  Future<List<ParcelPost>> postsByCity(String city, ParcelCountry country, ParcelDirection direction);
}

class ParcelException implements Exception {
  const ParcelException(this.message);

  final String message;

  @override
  String toString() => 'ParcelException: $message';
}

class HttpParcelSource implements ParcelSource {
  const HttpParcelSource();

  /// As long as the web page waits: the server may be waking up.
  static const _timeout = Duration(seconds: 30);

  @override
  Future<List<ParcelDate>> dates(ParcelDirection direction) async => [
        for (final json in await _get('api/parcels/dates', {'direction': '${direction.api}'}, 'dates'))
          ?ParcelDate.fromJson(json),
      ];

  @override
  Future<List<ParcelPost>> postsByDate(String date, ParcelDirection direction) async => [
        for (final json in await _get('api/parcels/by-date', {'date': date, 'direction': '${direction.api}'}, 'posts'))
          ParcelPost.fromJson(json),
      ];

  @override
  Future<List<ParcelCity>> cities(ParcelCountry country, ParcelDirection direction) async => [
        for (final json
            in await _get('api/parcels/cities', {'country': country.api, 'direction': '${direction.api}'}, 'cities'))
          ?ParcelCity.fromJson(json),
      ];

  @override
  Future<List<ParcelPost>> postsByCity(String city, ParcelCountry country, ParcelDirection direction) async => [
        for (final json in await _get(
          'api/parcels/by-city',
          {'city': city, 'country': country.api, 'direction': '${direction.api}'},
          'posts',
        ))
          ParcelPost.fromJson(json),
      ];

  Future<List<Map<String, dynamic>>> _get(String path, Map<String, String> query, String field) async {
    final url = AppConfig.apiBase.resolve(path).replace(queryParameters: query);
    final response = await http.get(url).timeout(_timeout);
    if (response.statusCode != 200) throw ParcelException('$path: ${response.statusCode}');
    // Uzbek, Russian and emoji: always UTF-8, whatever the headers say.
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ParcelException('$path: ${body is Map ? body['error'] : 'not JSON'}');
    }
    final list = body[field];
    return list is List ? list.whereType<Map<String, dynamic>>().toList() : const [];
  }
}
