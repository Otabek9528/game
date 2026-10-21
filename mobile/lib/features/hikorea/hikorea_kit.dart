import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import 'hikorea_models.dart';
import 'hikorea_source.dart';

/// What the HiKorea pages share while open: the offices (fetched once), this
/// person's watches, the counter they looked at last (kept on the phone), and
/// the calendars seen, so the first page can say how those counters stand.
class HikoreaKit extends ChangeNotifier {
  HikoreaKit(this.services);

  final AppServices services;

  HikoreaSource get source => services.hikorea;
  AppLanguage get language => services.locale.language ?? AppLanguage.uz;
  DateTime get today => DateUtils.dateOnly(services.clock());

  static const _lastKey = 'hikorea_last';

  List<HkOffice>? _offices;
  List<HkWatch>? _watches;
  final _calendars = <int, HkCalendar>{};
  final _loading = <int, Future<HkCalendar?>>{};

  List<HkOffice>? get offices => _offices;

  /// Active ones; null until known.
  List<HkWatch>? get watches => _watches;

  Future<List<HkOffice>> loadOffices() async {
    final offices = _offices ??= await source.offices();
    notifyListeners();
    return offices;
  }

  /// The office and counter of a desk number, once the offices are in.
  (HkOffice, HkDesk)? deskOf(int seq) {
    for (final office in _offices ?? const <HkOffice>[]) {
      if (office.desk(seq) case final desk?) return (office, desk);
    }
    return null;
  }

  HkOffice? officeOf(String id) => _offices?.where((o) => o.id == id).firstOrNull;

  /// The account's header for the server; the account is made if missing.
  Future<Map<String, String>> auth() async {
    await services.account.ensure();
    final headers = services.account.authHeaders;
    if (headers.isEmpty) throw const HkException('offline');
    return headers;
  }

  /// Quietly keeps the old list when offline.
  Future<void> refreshWatches() async {
    try {
      _watches = await source.watches(await auth());
      notifyListeners();
    } on HkException {
      // As it was.
    }
  }

  /// A counter's calendar as last fetched; null until it has been.
  HkCalendar? calendarOf(int desk) => _calendars[desk];

  /// Fetches a counter's calendar (once at a time); null when offline, the
  /// one fetched before staying.
  Future<HkCalendar?> loadCalendar(int desk) =>
      // A block: an arrow would hand back the removed future, and this one would wait on itself.
      _loading[desk] ??= _fetchCalendar(desk).whenComplete(() {
        _loading.remove(desk);
      });

  Future<HkCalendar?> _fetchCalendar(int desk) async {
    try {
      final calendar = _calendars[desk] = await source.calendar(desk);
      notifyListeners();
      return calendar;
    } on HkException {
      return null;
    }
  }

  int? get lastDesk => int.tryParse(services.store.read(_lastKey) ?? '');

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Answers arriving after the pages closed change nothing.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void remember(HkDesk desk) {
    services.store.write(_lastKey, '${desk.seq}');
    notifyListeners();
  }
}
