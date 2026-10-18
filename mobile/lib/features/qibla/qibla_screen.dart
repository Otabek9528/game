import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'calibration_view.dart';
import 'camera_view.dart';
import 'compass_dial.dart';
import 'qibla_controller.dart';
import 'qibla_panels.dart';
import 'qibla_sensors.dart';

/// The Qibla page: a compass corrected to true north with the place's
/// magnetic declination (WMM-2025), calibration when the sensor needs it,
/// and a camera view that marks the Qibla on the horizon. Everything the web
/// page (pages/qibla/) does, with the phone's full sensors.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  late final QiblaController _c = QiblaController(
    device: widget.services.qiblaDevice,
    prayer: widget.services.prayer,
  );
  QiblaDevice get _device => widget.services.qiblaDevice;

  Facing? _lastFacing;
  int _titleTaps = 0;
  CameraFeed? _feed;
  CameraProblem? _cameraProblem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The sensor maths assume portrait.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _c.addListener(_haptics);
    _c.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_haptics);
    _c.dispose();
    if (_c.cameraMode) _device.stopCamera();
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _c.pause();
      if (_c.cameraMode) {
        _device.stopCamera();
        setState(() => _feed = null);
      }
    } else if (state == AppLifecycleState.resumed) {
      _c.resume();
      if (_c.cameraMode) _startCamera();
    }
  }

  /// A firm tap when the Qibla is reached; a light one when it gets close.
  void _haptics() {
    if (_c.phase != QiblaPhase.compass) return;
    final f = _c.facing;
    if (f != _lastFacing) {
      if (f == Facing.aligned) {
        HapticFeedback.heavyImpact();
      } else if (f == Facing.close && _lastFacing != Facing.aligned) {
        HapticFeedback.selectionClick();
      }
      _lastFacing = f;
    }
  }

  void _titleTap() {
    if (++_titleTaps >= 7) {
      _titleTaps = 0;
      showDiagnostics(context, _c);
    }
  }

  Future<void> _setCamera(bool on) async {
    HapticFeedback.selectionClick();
    _c.setCameraMode(on);
    if (on) {
      await _startCamera();
    } else {
      await _device.stopCamera();
      setState(() {
        _feed = null;
        _cameraProblem = null;
      });
    }
  }

  Future<void> _startCamera() async {
    setState(() {
      _feed = null;
      _cameraProblem = null;
    });
    try {
      final feed = await _device.startCamera();
      if (mounted && _c.cameraMode) setState(() => _feed = feed);
    } on CameraException catch (e) {
      if (mounted) setState(() => _cameraProblem = e.problem);
    }
  }

  Future<void> _locate() async {
    await widget.services.prayer.locate(userAsked: true);
    if (mounted) await _c.start();
  }

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final s = AppLocalizations.of(context);
    final language = widget.services.locale.language ?? AppLanguage.uz;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(title: s.qiblaTitle, onTitleTap: _titleTap),
            Expanded(
              child: ListenableBuilder(
                listenable: _c,
                builder: (context, _) => switch (_c.phase) {
                  QiblaPhase.loading => _Message(
                      icon: Icons.explore_rounded,
                      title: s.qiblaPreparing,
                      body: s.qiblaHoldFlat,
                      busy: true,
                    ),
                  QiblaPhase.noLocation => _Message(
                      icon: Icons.location_off_rounded,
                      title: s.locationNeededTitle,
                      body: s.qiblaNoLocation,
                      action: s.useMyLocation,
                      onAction: _locate,
                    ),
                  QiblaPhase.noCompass => _Message(
                      icon: Icons.explore_off_rounded,
                      title: s.qiblaNoCompassTitle,
                      body: s.qiblaNoCompass,
                    ),
                  QiblaPhase.calibrating => ListView(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                      children: [
                        CalibrationView(controller: _c),
                        const SizedBox(height: 14),
                        const TipsCard(),
                      ],
                    ),
                  QiblaPhase.compass => _compass(context, language),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compass(BuildContext context, AppLanguage language) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final toggle = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, label: Text(s.qiblaModeCompass), icon: const Icon(Icons.explore_rounded)),
          ButtonSegment(value: true, label: Text(s.qiblaModeCamera), icon: const Icon(Icons.photo_camera_rounded)),
        ],
        selected: {_c.cameraMode},
        showSelectedIcon: false,
        onSelectionChanged: (v) => _setCamera(v.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.action,
          selectedForegroundColor: Colors.white,
          foregroundColor: p.inkSoft,
          backgroundColor: p.card,
          side: BorderSide(color: p.hairline),
        ),
      ),
    );

    if (_c.cameraMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toggle,
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + bottom),
              child: CameraQiblaView(
                controller: _c,
                feed: _feed,
                problem: _cameraProblem,
                onOpenSettings: widget.services.permissions.openAppSettings,
                instruction: turnInstruction(s, _c),
                markerLabel: _c.qibla == null
                    ? s.featureQibla
                    : '${s.featureQibla} · ${NumberFormat.decimalPattern(language.code).format(_c.qibla!.distanceKm.round())} km',
              ),
            ),
          ),
        ],
      );
    }

    final sun = _c.sun;
    final accuracy = _c.reading?.accuracy ?? -1;
    return ListView(
      padding: EdgeInsets.only(bottom: 24 + bottom),
      children: [
        toggle,
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TurnBanner(controller: _c),
              const SizedBox(height: 10),
              AnglesCard(controller: _c),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: CompassDial(
                    heading: _c.heading,
                    qibla: _c.qibla?.bearing ?? 0,
                    aligned: _c.facing == Facing.aligned,
                    cardinals: [s.qiblaNorth, s.qiblaEast, s.qiblaSouth, s.qiblaWest],
                    headingLabel: s.qiblaDirection,
                    accuracy: accuracy >= 0 ? s.qiblaAccuracy(accuracy.round()) : null,
                    sunAzimuth: sun != null && sun.up ? sun.azimuth : null,
                    levelX: _c.reading?.levelX ?? 0,
                    levelY: _c.reading?.levelY ?? 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PlaceCard(controller: _c, language: language),
              const SizedBox(height: 10),
              SignalCard(controller: _c),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _c.recalibrate();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(s.qiblaRecalibrate),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.accent,
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SunCard(controller: _c, language: language),
              const SizedBox(height: 10),
              const TipsCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onTitleTap});

  final String title;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero.sublist(1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTitleTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: Brand.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'القِبْلَة',
                        style: TextStyle(fontFamily: Brand.arabicFont, fontSize: 20, color: Brand.gold300),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (busy) SizedBox.square(dimension: 88, child: CircularProgressIndicator(color: p.accent, strokeWidth: 3)),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
                    child: Icon(icon, size: 32, color: p.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
            if (action != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
