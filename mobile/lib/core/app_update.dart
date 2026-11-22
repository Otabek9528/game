import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'activity_log.dart';
import 'key_value_store.dart';

/// What Google Play says about a newer version of the app.
@immutable
class PlayUpdate {
  const PlayUpdate({this.versionCode, this.downloaded = false, this.downloading = false, this.flexibleAllowed = true});

  final int? versionCode;

  /// Fetched in an earlier session, not installed yet.
  final bool downloaded;

  /// Being fetched, started in an earlier session.
  final bool downloading;

  /// Whether Play lets it be fetched in the background (it may not, for
  /// instance with too little storage).
  final bool flexibleAllowed;
}

/// Google Play's in-app updates. Faked in tests.
abstract interface class UpdateSource {
  /// The newer version on Play; null when there is none, or no Play to ask:
  /// a debug build, one not installed from Play, an iPhone.
  Future<PlayUpdate?> check();

  /// Play's own dialog ("Update available"); on yes, the download, in the
  /// background. [onAccepted] runs when the download starts. True once it is
  /// downloaded; false when declined or failed.
  Future<bool> download({required VoidCallback onAccepted});

  /// Installs what was downloaded: the app closes and opens again. Called
  /// while the app is in the background, Play does it without a screen.
  void install();
}

/// [UpdateSource] backed by the Play Core library (Android only).
class PlayUpdateSource implements UpdateSource {
  const PlayUpdateSource();

  @override
  Future<PlayUpdate?> check() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final info = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 20));
      final code = info.availableVersionCode;
      return switch ((info.updateAvailability, info.installStatus)) {
        (_, InstallStatus.downloaded) => PlayUpdate(versionCode: code, downloaded: true),
        (UpdateAvailability.developerTriggeredUpdateInProgress, _) ||
        (_, InstallStatus.pending || InstallStatus.downloading) => PlayUpdate(versionCode: code, downloading: true),
        (UpdateAvailability.updateAvailable, _) => PlayUpdate(versionCode: code, flexibleAllowed: info.flexibleUpdateAllowed),
        _ => null,
      };
    } catch (e) {
      // Not installed from Play (debug, a shared APK), no Play services,
      // offline: there is nothing to offer.
      debugPrint('Update check: $e');
      return null;
    }
  }

  @override
  Future<bool> download({required VoidCallback onAccepted}) async {
    // The download's own progress: its first sign means "yes" was tapped.
    final progress = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.pending || status == InstallStatus.downloading) onAccepted();
    }, onError: (Object _) {});
    try {
      // Completes when the download has finished, not when "yes" is tapped.
      return await InAppUpdate.startFlexibleUpdate() == AppUpdateResult.success;
    } catch (e) {
      debugPrint('Update download: $e');
      return false;
    } finally {
      unawaited(progress.cancel());
    }
  }

  @override
  void install() {
    // Never completes: the app restarts during it.
    unawaited(InAppUpdate.completeFlexibleUpdate().catchError((Object e) => debugPrint('Update install: $e')));
  }
}

/// Where the newer version is: [none] on Play (or no Play), [available] but
/// not taken, [downloading] in the background, [ready] to install, or
/// [installing] (the app is about to restart).
enum UpdateStage { none, available, downloading, ready, installing }

/// Newer versions from Google Play, fetched while the app keeps working.
///
/// After the start, Play is asked once; a newer version is offered with Play's
/// own dialog, at most once every three days for the same version (it can
/// always be taken from the account page). Taken, it downloads in the
/// background. Then it installs when "Restart" is tapped, or by itself when
/// the app is left from its home screen ([installQuietly]), where nothing is
/// lost by restarting.
class UpdateController extends ChangeNotifier {
  UpdateController({
    required this._source,
    required this._store,
    this._activity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final UpdateSource _source;
  final KeyValueStore _store;
  final ActivityLog? _activity;
  final DateTime Function() _clock;

  /// How long a declined version waits before it is offered again.
  static const askAgainAfter = Duration(days: 3);

  /// How often coming back to the app asks Play again.
  static const checkAgainAfter = Duration(hours: 6);

  static const _askedKey = 'update_asked';

  UpdateStage _stage = UpdateStage.none;
  UpdateStage get stage => _stage;

  /// The version on offer, when Play said.
  int? get versionCode => _versionCode;
  int? _versionCode;

  DateTime? _checkedAt;
  bool _started = false;
  bool _checking = false;
  bool _asking = false;

  void _set(UpdateStage stage) {
    if (_stage == stage) return;
    _stage = stage;
    notifyListeners();
  }

  /// Asks Play, and offers what it has (subject to the three days). Called
  /// once the home screen has asked its own questions (permissions), so
  /// Play's dialog never lands on top of them.
  Future<void> start() {
    _started = true;
    return _check(offer: true);
  }

  /// Back to the app: Play again, at most every six hours; a download from an
  /// earlier session may have finished meanwhile.
  Future<void> resumed() async {
    // Not before [start]: the app's own first questions come first.
    if (!_started || _asking) return;
    // Still running after an install was asked for: it didn't happen; what
    // Play says now (most likely: still downloaded) shows again.
    if (_stage == UpdateStage.installing) return _check(offer: false);
    final last = _checkedAt;
    final due = last == null || _clock().difference(last) >= checkAgainAfter;
    if (due || _stage == UpdateStage.downloading) await _check(offer: due);
  }

  Future<void> _check({required bool offer}) async {
    if (_checking || _asking) return;
    _checking = true;
    final PlayUpdate? update;
    try {
      update = await _source.check();
    } finally {
      _checking = false;
    }
    _checkedAt = _clock();
    if (update == null) {
      // Nothing newer, or nothing to ask. A download in flight stays shown.
      if (_stage != UpdateStage.downloading) _set(UpdateStage.none);
      return;
    }
    _versionCode = update.versionCode;
    if (update.downloaded) {
      _set(UpdateStage.ready);
    } else if (update.downloading) {
      _set(UpdateStage.downloading);
    } else {
      _set(UpdateStage.available);
      if (offer && update.flexibleAllowed && _due(update.versionCode)) await _offer();
    }
  }

  /// Whether [code] may be offered now: never offered, or not in three days.
  bool _due(int? code) {
    final asked = _store.read(_askedKey)?.split(':');
    if (asked == null || asked.length != 2 || asked[0] != '$code') return true;
    final at = int.tryParse(asked[1]);
    if (at == null) return true;
    return _clock().difference(DateTime.fromMillisecondsSinceEpoch(at)) >= askAgainAfter;
  }

  /// "Update" tapped in the app: Play's dialog, whatever was answered before.
  Future<void> update() async {
    if (_stage != UpdateStage.available) return;
    await _offer();
  }

  Future<void> _offer() async {
    if (_asking) return;
    _asking = true;
    unawaited(_store.write(_askedKey, '$_versionCode:${_clock().millisecondsSinceEpoch}'));
    var accepted = false;
    try {
      final done = await _source.download(
        onAccepted: () {
          if (accepted) return;
          accepted = true;
          _activity?.log('update', 'accepted');
          _set(UpdateStage.downloading);
        },
      );
      if (done) {
        _activity?.log('update', 'downloaded');
        _set(UpdateStage.ready);
      } else {
        // Declined, or the download failed: it stays on offer.
        _activity?.log('update', accepted ? 'failed' : 'declined');
        _set(UpdateStage.available);
      }
    } finally {
      _asking = false;
    }
  }

  /// "Restart" tapped: installs now.
  void restart() {
    if (_stage != UpdateStage.ready) return;
    _activity?.log('update', 'restart');
    _set(UpdateStage.installing);
    _source.install();
  }

  /// The app was left from its home screen with a version waiting: installed
  /// while nobody is looking; the next opening is the new version.
  void installQuietly() {
    if (_stage != UpdateStage.ready) return;
    _activity?.log('update', 'quiet');
    _set(UpdateStage.installing);
    _source.install();
  }
}
