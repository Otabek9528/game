import 'dart:async';

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
  final _failed = <int>{};

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
      _failed.remove(desk);
      notifyListeners();
      return calendar;
    } on HkException {
      _failed.add(desk);
      notifyListeners();
      return null;
    }
  }

  // The office list's calendars, a few at a time: a screen of offices
  // would otherwise ask for twenty at once.
  final _queue = <int>[];
  var _running = 0;

  /// Fetches a counter's calendar soon, unless it is in or failed already.
  void prefetch(int desk) {
    if (_calendars.containsKey(desk) || _loading.containsKey(desk) || _failed.contains(desk) || _queue.contains(desk)) {
      return;
    }
    _queue.add(desk);
    _pump();
  }

  void _pump() {
    while (_running < 3 && _queue.isNotEmpty && !_disposed) {
      final desk = _queue.removeAt(0);
      if (_calendars.containsKey(desk) || _loading.containsKey(desk)) continue;
      _running++;
      unawaited(loadCalendar(desk).whenComplete(() {
        _running--;
        _pump();
      }));
    }
  }

  /// Lets the calendars that failed be asked for again.
  void retryFailed() {
    if (_failed.isEmpty) return;
    _failed.clear();
    notifyListeners();
  }

  /// How soon [office] takes someone: the earliest free day of its counters.
  ({HkOutlook kind, DateTime? day}) outlookOf(HkOffice office) {
    if (office.desks.isEmpty) return (kind: HkOutlook.unknown, day: null);
    DateTime? soonest;
    var waiting = false, failed = false, live = false;
    for (final desk in office.desks) {
      final calendar = _calendars[desk.seq];
      if (calendar == null) {
        if (_failed.contains(desk.seq)) {
          failed = true;
        } else {
          waiting = true;
        }
        continue;
      }
      if (calendar.dormant) continue;
      live = true;
      final day = calendar.earliestOpen(today);
      if (day != null && (soonest == null || day.isBefore(soonest))) soonest = day;
    }
    if (waiting) return (kind: HkOutlook.loading, day: null);
    if (soonest != null) return (kind: HkOutlook.free, day: soonest);
    // A counter not heard from may have room.
    if (failed) return (kind: HkOutlook.unknown, day: null);
    return (kind: live ? HkOutlook.full : HkOutlook.retired, day: null);
  }

  /// Whether one of this person's watches is at [office].
  bool watching(HkOffice office) => (_watches ?? const <HkWatch>[]).any((w) => office.desk(w.deskSeq) != null);

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
