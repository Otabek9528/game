import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../support/support_data.dart';
import '../support/support_parts.dart';
import 'barcode_camera.dart';
import 'barcode_controller.dart';
import 'barcode_models.dart';
import 'barcode_parts.dart';
import 'barcode_result.dart';
import 'barcode_store_screen.dart';

/// The web page (pages/barcode/) rebuilt around the camera: it opens
/// scanning, and a code read is checked in a sheet over it; closing the sheet
/// scans the next one, so a whole shelf takes no extra taps. Below the
/// camera: the codes checked on this phone, the stores' lists, the call for
/// contributors and the disclaimer.
class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> with WidgetsBindingObserver {
  late final ScannerCamera _camera = widget.services.barcodeCamera();
  late final ScanHistory _history = ScanHistory(widget.services.store);
  late final BarcodeController _checks = BarcodeController(
    source: widget.services.barcodes,
    history: _history,
    activity: widget.services.activity,
  );
  late Future<List<StoreSummary>> _stores = widget.services.barcodes.stores();
  final _scroll = ScrollController();

  /// The camera runs only while it can be seen: not under a sheet or
  /// another page, not scrolled away, not in the background.
  bool _covered = false;
  bool _away = false;
  bool _background = false;

  double _cameraHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera.onCode = _onCode;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _camera.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    _checks.dispose();
    _history.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// [retry]: start even a camera that was refused, when coming back from
  /// the background (perhaps from the settings, with it now allowed).
  /// Otherwise a refusal stands: asking again after every sheet would nag.
  void _sync({bool retry = false}) {
    if (_covered || _away || _background) {
      _camera.pause();
    } else if (retry || _camera.status != CameraStatus.denied) {
      _camera.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = switch (state) {
      AppLifecycleState.resumed => false,
      AppLifecycleState.paused || AppLifecycleState.hidden || AppLifecycleState.detached => true,
      // A system dialog (the camera permission) passes through inactive
      // only: the camera's own start is under way, leave it be.
      AppLifecycleState.inactive => _background,
    };
    if (background == _background) return;
    _background = background;
    _sync(retry: !background);
  }

  void _onScroll() {
    final away = _scroll.offset > _cameraHeight * 0.45;
    if (away == _away) return;
    setState(() => _away = away);
    _sync();
  }

  /// Runs [body] with the camera held.
  Future<void> _over(Future<void> Function() body) async {
    if (_covered) return;
    setState(() => _covered = true);
    _sync();
    try {
      await body();
    } finally {
      if (mounted) {
        setState(() => _covered = false);
        _sync();
      }
    }
  }

  Future<void> _lookup(String code, {bool scanned = true}) async {
    unawaited(_checks.check(code, scanned: scanned));
    await showLookupSheet(context, widget.services, _checks);
    _checks.clear();
  }

  void _onCode(String code) {
    if (_covered) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    _over(() => _lookup(code));
  }

  void _typeCode() => _over(() async {
        final code = await askForCode(context);
        if (code != null && mounted) await _lookup(code);
      });

  void _openRecent(ScanRecord record) => _over(() => _lookup(record.code, scanned: false));

  void _openStore(StoreSummary store) => _over(() async {
        widget.services.activity.log('store_opened', store.store);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => StoreScreen(services: widget.services, store: store)),
        );
      });

  void _backToCamera() =>
      _scroll.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final media = MediaQuery.of(context);
    // On a whole device pixel: a fraction leaves a hairline seam under it.
    _cameraHeight = (math.min(media.size.height * 0.62, 600) * media.devicePixelRatio).roundToDouble() /
        media.devicePixelRatio;
    return Scaffold(
      backgroundColor: p.page,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _cameraHeight - media.padding.top,
            backgroundColor: p.hero.first,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
            titleTextStyle: const TextStyle(
              fontFamily: Brand.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
            title: Text(s.barcodeTitle),
            actions: [
              if (_away)
                IconButton(
                  onPressed: _backToCamera,
                  tooltip: s.barcodeBackToCamera,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _CameraArea(
                camera: _camera,
                onTypeCode: _typeCode,
                onOpenSettings: widget.services.permissions.openAppSettings,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 28 + media.padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListenableBuilder(
                    listenable: _history,
                    builder: (context, _) => _Recent(
                      items: _history.items,
                      language: widget.services.locale.language ?? AppLanguage.uz,
                      onOpen: _openRecent,
                      onClear: _history.clear,
                    ),
                  ),
                  SupportLabel(s.barcodeStores),
                  _Stores(
                    stores: _stores,
                    onOpen: _openStore,
                    onRetry: () => setState(() => _stores = widget.services.barcodes.stores()),
                  ),
                  const SizedBox(height: 18),
                  SupportCard(
                    color: p.gold.withValues(alpha: 0.08),
                    edge: p.gold.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IconLine(
                          icon: Icons.handshake_rounded,
                          tint: p.gold,
                          title: s.barcodeContribTitle,
                          body: s.barcodeContribBody,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => widget.services.openLink(Uri.parse(CommunityGroup.url)),
                          icon: const Icon(Icons.send_rounded, size: 19),
                          label: Text(s.barcodeContribCta),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SupportCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: p.inkMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            starredText(s.barcodeDisclaimer, TextStyle(fontSize: 13, height: 1.5, color: p.inkSoft)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The camera with its frame, hint and buttons; or why it isn't showing.
class _CameraArea extends StatelessWidget {
  const _CameraArea({required this.camera, required this.onTypeCode, required this.onOpenSettings});

  final ScannerCamera camera;
  final VoidCallback onTypeCode;
  final Future<void> Function() onOpenSettings;

  /// The page's rounded top edge, drawn over the camera's foot.
  static const _lip = 22.0;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Between the bar and the buttons; wide and low, the shape of the
        // bars on a packet.
        final bottom = size.height - _lip - 84;
        final width = math.min(size.width * 0.8, 340.0);
        final window = Rect.fromCenter(
          center: Offset(size.width / 2, (top + bottom) / 2 - 8),
          width: width,
          height: width * 0.5,
        );
        return ListenableBuilder(
          listenable: camera,
          builder: (context, _) {
            final status = camera.status;
            final problem = status == CameraStatus.denied || status == CameraStatus.failed;
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                // Always in the tree: the plugin starts only once it is.
                camera.preview(window),
                if (!problem) ...[
                  IgnorePointer(child: CustomPaint(painter: _FramePainter(window))),
                  if (status == CameraStatus.starting)
                    Positioned.fromRect(
                      rect: window,
                      child: const Center(
                        child: SizedBox.square(
                          dimension: 30,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    top: window.bottom + 14,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.barcodeHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ] else
                  Positioned.fill(
                    child: _CameraProblem(
                      top: top,
                      bottom: _lip + 84,
                      denied: status == CameraStatus.denied,
                      onRetry: camera.start,
                      onOpenSettings: onOpenSettings,
                    ),
                  ),
                // Keeps the title readable over a bright picture.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: top + 24,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: _lip + 16,
                  child: Row(
                    children: [
                      _RoundButton(
                        icon: camera.torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                        tooltip: s.barcodeTorch,
                        active: camera.torchOn,
                        onTap: camera.hasTorch && !problem ? camera.toggleTorch : null,
                      ),
                      Expanded(
                        child: Center(
                          child: Material(
                            color: Colors.white,
                            shape: const StadiumBorder(),
                            child: InkWell(
                              onTap: onTypeCode,
                              customBorder: const StadiumBorder(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.dialpad_rounded, size: 20, color: Brand.emerald800),
                                    const SizedBox(width: 8),
                                    Text(
                                      s.barcodeTypeCode,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Brand.emerald800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _RoundButton(
                        icon: Icons.cameraswitch_rounded,
                        tooltip: s.barcodeSwitchCamera,
                        onTap: camera.canSwitch && !problem ? camera.switchCamera : null,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  height: _lip + 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.page,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(_lip)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Dims all but the window, marks its corners, and draws the reading line.
class _FramePainter extends CustomPainter {
  _FramePainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(window, const Radius.circular(18));
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(frame)),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );
    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 26.0;
    const r = 18.0;
    for (final (x, y, dx, dy) in [
      (window.left, window.top, 1.0, 1.0),
      (window.right, window.top, -1.0, 1.0),
      (window.left, window.bottom, 1.0, -1.0),
      (window.right, window.bottom, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * arm)
          ..lineTo(x, y + dy * r)
          ..arcToPoint(Offset(x + dx * r, y), radius: const Radius.circular(r), clockwise: dx * dy > 0)
          ..lineTo(x + dx * arm, y),
        corner,
      );
    }
    final y = window.center.dy;
    canvas.drawLine(
      Offset(window.left + 16, y),
      Offset(window.right - 16, y),
      Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: 0.35)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawLine(
      Offset(window.left + 16, y),
      Offset(window.right - 16, y),
      Paint()
        ..color = const Color(0xFFFF5252)
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.window != window;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap, this.active = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: active ? Colors.white : Colors.black.withValues(alpha: 0.45),
          shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.35))),
          child: IconButton(
            onPressed: onTap,
            tooltip: tooltip,
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            icon: Icon(icon, color: active ? Brand.emerald800 : Colors.white),
          ),
        ),
      );
}

/// No camera: why, and the way around it.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({
    required this.top,
    required this.bottom,
    required this.denied,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final double top;
  final double bottom;
  final bool denied;
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, top, 28, bottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(denied ? Icons.no_photography_rounded : Icons.videocam_off_rounded, size: 46, color: Brand.gold300),
            const SizedBox(height: 12),
            Text(
              denied ? s.barcodeCameraOffTitle : s.barcodeCameraError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              s.barcodeCameraOffBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: denied ? onOpenSettings : onRetry,
              icon: Icon(denied ? Icons.settings_rounded : Icons.refresh_rounded, size: 19),
              label: Text(denied ? s.barcodeOpenSettings : s.barcodeRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The codes checked on this phone, newest first.
class _Recent extends StatelessWidget {
  const _Recent({required this.items, required this.language, required this.onOpen, required this.onClear});

  final List<ScanRecord> items;
  final AppLanguage language;
  final ValueChanged<ScanRecord> onOpen;
  final VoidCallback onClear;

  static const _shown = 5;

  String _when(DateTime at) {
    final now = DateTime.now();
    final today = at.year == now.year && at.month == now.month && at.day == now.day;
    return today ? DateFormat.Hm(language.code).format(at) : DateFormat.MMMd(language.code).format(at);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 0, 4),
          child: Row(
            children: [
              Expanded(child: Text(s.barcodeRecent, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink))),
              TextButton(onPressed: onClear, child: Text(s.barcodeClear)),
            ],
          ),
        ),
        SupportCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (i, item) in items.take(_shown).indexed) ...[
                if (i > 0) Divider(height: 1, indent: 64, color: p.hairline),
                _RecentRow(item: item, when: _when(item.at), onTap: () => onOpen(item)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item, required this.when, required this.onTap});

  final ScanRecord item;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final product = item.product;
    final style = product == null ? null : VerdictStyle.of(context, product.verdict);
    final color = style?.color ?? p.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
              child: Icon(style?.icon ?? Icons.search_off_rounded, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.title ?? s.barcodeNotFound,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (product != null) VerdictStyle.label(s, product.verdict),
                      item.code,
                      when,
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: p.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// The stores with checked lists, as tiles with their logos.
class _Stores extends StatelessWidget {
  const _Stores({required this.stores, required this.onOpen, required this.onRetry});

  final Future<List<StoreSummary>> stores;
  final ValueChanged<StoreSummary> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return FutureBuilder<List<StoreSummary>>(
      future: stores,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SupportCard(
            child: Column(
              children: [
                Text(s.barcodeStoresError, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 2),
                Text(s.barcodeCheckConnection, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.inkMuted)),
                const SizedBox(height: 8),
                TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(s.barcodeRetry)),
              ],
            ),
          );
        }
        final list = snapshot.data;
        final tiles = list == null
            ? [for (var i = 0; i < 6; i++) const _StoreTile.loading()]
            : [for (final store in list) _StoreTile(store: store, onTap: () => onOpen(store))];
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final width = (constraints.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
            );
          },
        );
      },
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({required StoreSummary this.store, required VoidCallback this.onTap});

  const _StoreTile.loading()
      : store = null,
        onTap = null;

  final StoreSummary? store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final store = this.store;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 124,
          child: store == null
              ? Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(15)),
                  ),
                )
              : Opacity(
                  opacity: store.isSoon ? 0.55 : 1,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
                          child: Column(
                            children: [
                              StoreEmblem(store.store, size: 52, padding: 7),
                              const SizedBox(height: 8),
                              Text(
                                store.store,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.ink),
                              ),
                              Text(
                                s.barcodeProducts(store.count),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: p.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (store.isSoon)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              s.barcodeSoon,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
