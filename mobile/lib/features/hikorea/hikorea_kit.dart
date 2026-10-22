import 'dart:async';
import 'dart:convert';

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

  static const _officesKey = 'hikorea_offices';

  /// The offices: those kept on the phone at once, then the server's. Offline
  /// with some kept, those stay.
  Future<List<HkOffice>> loadOffices() async {
    if (_offices case final offices?) return offices;
    final kept = _readOffices();
    if (kept != null) {
      _offices = kept;
      notifyListeners();
    }
    try {
      final fresh = await source.offices();
      _offices = fresh;
      unawaited(services.store.write(_officesKey, jsonEncode([for (final o in fresh) o.toJson()])));
    } on HkException {
      if (kept == null) rethrow;
    }
    _keepOutlooks();
    notifyListeners();
    return _offices!;
  }

  List<HkOffice>? _readOffices() {
    try {
      final json = jsonDecode(services.store.read(_officesKey) ?? '');
      if (json is! List) return null;
      final offices = [for (final o in json) ?HkOffice.fromJson(o)];
      return offices.isEmpty ? null : offices;
    } on FormatException {
      return null;
    }
  }

  // Every counter's calendar in one request (update 7 on). While it runs
  // the leaves wait for it; when it fails they ask counter by counter.
  Future<void>? _all;
  bool _allLoading = false;

  /// Asks for every counter's calendar at once; [again] even when asked.
  Future<void> loadAllCalendars({bool again = false}) {
    if (again) _all = null;
    return _all ??= () async {
      _allLoading = true;
      try {
        final all = await source.calendars();
        _calendars.addAll(all);
        _failed.removeAll(all.keys);
        _keepOutlooks();
      } on HkException {
        // Counter by counter, then.
      } finally {
        _allLoading = false;
        notifyListeners();
      }
    }();
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

  // Without the one request, the office list's calendars a few at a time:
  // a screen of offices would otherwise ask for twenty at once.
  final _queue = <int>[];
  var _running = 0;

  /// Fetches a counter's calendar soon, unless it is in or failed already,
  /// or the request for them all is on its way.
  void prefetch(int desk) {
    if (_allLoading ||
        _calendars.containsKey(desk) ||
        _loading.containsKey(desk) ||
        _failed.contains(desk) ||
        _queue.contains(desk)) {
      return;
    }
    _queue.add(desk);
    _pump();
  }

  void _pump() {
    while (_running < 6 && _queue.isNotEmpty && !_disposed) {
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
    if (waiting || (failed && soonest == null)) {
      // What it was last time, until the calendars come (or while they can't).
      final kept = _keptOutlooks[office.id];
      if (kept != null && (kept.day == null || !kept.day!.isBefore(today))) return kept;
      if (waiting) return (kind: HkOutlook.loading, day: null);
    }
    if (soonest != null) return (kind: HkOutlook.free, day: soonest);
    // A counter not heard from may have room.
    if (failed) return (kind: HkOutlook.unknown, day: null);
    return (kind: live ? HkOutlook.full : HkOutlook.retired, day: null);
  }

  static const _outlookKey = 'hikorea_outlook';
  Map<String, ({HkOutlook kind, DateTime? day})>? _kept;

  /// Each office's leaf as last shown, kept on the phone for three days: the
  /// next visit shows them at once, and the fresh ones replace them.
  Map<String, ({HkOutlook kind, DateTime? day})> get _keptOutlooks => _kept ??= _readOutlooks();

  Map<String, ({HkOutlook kind, DateTime? day})> _readOutlooks() {
    try {
      final json = jsonDecode(services.store.read(_outlookKey) ?? '');
      if (json is! Map || json['at'] is! int) return {};
      final at = DateTime.fromMillisecondsSinceEpoch(json['at'] as int);
      if (services.clock().difference(at) > const Duration(days: 3)) return {};
      return {
        for (final MapEntry(:key, :value) in ((json['o'] as Map?) ?? const {}).entries)
          if (value is List && value.length == 2 && value[0] is int && (value[0] as int) < HkOutlook.values.length)
            '$key': (kind: HkOutlook.values[value[0] as int], day: parseYmd(value[1] as String?)),
      };
    } on FormatException {
      return {};
    }
  }

  void _keepOutlooks() {
    final offices = _offices;
    if (offices == null) return;
    final known = <String, List<Object?>>{};
    for (final office in offices) {
      final o = outlookOf(office);
      if (o.kind != HkOutlook.loading) known[office.id] = [o.kind.index, o.day == null ? null : ymdOf(o.day!)];
    }
    if (known.isEmpty) return;
    _kept = null;
    unawaited(services.store.write(_outlookKey, jsonEncode({'at': services.clock().millisecondsSinceEpoch, 'o': known})));
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
