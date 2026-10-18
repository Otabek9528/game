/// Which way the parcel goes. The API's `direction`: 0 or 1.
enum ParcelDirection {
  uzbToKor,
  korToUzb;

  int get api => index;

  ParcelDirection get other => this == uzbToKor ? korToUzb : uzbToKor;

  ParcelCountry get from => this == uzbToKor ? ParcelCountry.uzb : ParcelCountry.kor;
  ParcelCountry get to => this == uzbToKor ? ParcelCountry.kor : ParcelCountry.uzb;
}

/// The API's `country`: "uzb" or "kor".
enum ParcelCountry {
  uzb,
  kor;

  String get api => name;
  String get flag => this == uzb ? '🇺🇿' : '🇰🇷';
}

/// A day couriers fly, and how many posts there are for it.
class ParcelDate {
  const ParcelDate({required this.date, required this.key, required this.count});

  final DateTime date;

  /// "25.10.2026", as the API takes it back.
  final String key;
  final int count;

  /// Null when the API's date isn't "dd.mm.yyyy".
  static ParcelDate? fromJson(Map<String, dynamic> json) {
    final key = '${json['date_formatted'] ?? ''}'.trim();
    final parts = key.split('.');
    if (parts.length != 3) return null;
    final (d, m, y) = (int.tryParse(parts[0]), int.tryParse(parts[1]), int.tryParse(parts[2]));
    if (d == null || m == null || y == null) return null;
    return ParcelDate(date: DateTime(y, m, d), key: key, count: _int(json['count']));
  }
}

/// A city in the posts, and how many there are for it.
class ParcelCity {
  const ParcelCity({required this.name, required this.count});

  final String name;
  final int count;

  static ParcelCity? fromJson(Map<String, dynamic> json) {
    final name = '${json['city'] ?? ''}'.trim();
    return name.isEmpty ? null : ParcelCity(name: name, count: _int(json['count']));
  }
}

/// A courier's post, as they wrote it in the Telegram group.
class ParcelPost {
  const ParcelPost({required this.text, this.username, this.telegramId, this.flightTime, this.direction});

  final String text;

  /// Without the "@"; null when the courier has none.
  final String? username;
  final String? telegramId;

  /// As the API gives it: "25.10.2026 14:30" or similar.
  final String? flightTime;
  final ParcelDirection? direction;

  factory ParcelPost.fromJson(Map<String, dynamic> json) {
    String? text(Object? v) {
      final s = v == null ? '' : '$v'.trim();
      return s.isEmpty ? null : s;
    }

    final direction = json['direction'];
    final d = direction is num ? direction.toInt() : int.tryParse('${direction ?? ''}');
    return ParcelPost(
      text: (text(json['message_text']) ?? '').replaceAll(' ', ' '),
      username: text(json['username'])?.replaceAll('@', ''),
      telegramId: text(json['telegram_id']),
      flightTime: text(json['flight_time']),
      direction: d == 0 || d == 1 ? ParcelDirection.values[d!] : null,
    );
  }
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
