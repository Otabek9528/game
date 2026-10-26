import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../places/places_models.dart';
import '../places/places_parts.dart' show kindColour;
import '../places/places_source.dart';
import 'notify_models.dart';

/// What went wrong, in the person's words.
String notifyError(AppLocalizations s, Object e) => switch (e is PlacesException ? e.code : 'offline') {
  'address_not_exact' => s.ntErrAddressNotExact,
  'address_not_found' => s.ntErrAddressNotFound,
  'rate_limited' => s.ntErrRateLimited,
  'too_many_areas' => s.ntErrTooManyAreas,
  'area_budget' => s.ntErrAreaBudget,
  'too_many_changes' => s.ntErrTooManyChanges,
  'too_many_previews' => s.ntErrTooManyPreviews,
  'offline' => s.ntErrOffline,
  _ => s.ntErrGeneric,
};

/// Adds an area, or changes [area]: a point (where one stands now) or an
/// address in Korean, a radius, the types of place; a map of what falls
/// inside as it is chosen. Returns the saved area.
Future<NotifyArea?> showAreaSheet(
  BuildContext context,
  AppServices services,
  Future<Map<String, String>> Function() auth, {
  NotifyArea? area,
}) => showModalBottomSheet<NotifyArea>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: VegukinPalette.of(context).page,
  builder: (_) => _AreaSheet(services: services, auth: auth, area: area),
);

typedef _Center = ({double lat, double lon, String? label, bool fresh});

class _AreaSheet extends StatefulWidget {
  const _AreaSheet({required this.services, required this.auth, this.area});

  final AppServices services;
  final Future<Map<String, String>> Function() auth;
  final NotifyArea? area;

  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  AppServices get _services => widget.services;
  PlacesSource get _source => _services.places;
  String get _lang => _services.locale.language?.code ?? 'uz';

  late bool _here = widget.area?.fromLocation ?? true;
  late int _radius = widget.area?.radiusKm ?? 3;
  late final Set<PlaceKind> _types = {
    ...(widget.area != null && widget.area!.types.isNotEmpty ? widget.area!.types : PlaceKind.values),
  };
  late final _address = TextEditingController(text: widget.area?.fromLocation == false ? widget.area?.label ?? '' : '');

  // A centre per tab, so switching back and forth keeps both.
  _Center? _location;
  _Center? _found;
  String _foundFor = '';
  final _points = <bool, RadiusPreview?>{};

  bool _locating = false;
  bool _locateFailed = false;
  bool _finding = false;
  String? _addressError;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final area = widget.area;
    if (area != null) {
      final c = (lat: area.lat, lon: area.lon, label: area.label, fresh: false);
      if (area.fromLocation) {
        _location = c;
      } else {
        _found = c;
        _foundFor = _address.text.trim();
      }
      unawaited(_preview(area.fromLocation, c));
    } else {
      // Where the phone was last seen, at once; the fresh fix (seconds,
      // sometimes) replaces it when it comes.
      if (_services.prayer.place case final saved?) {
        final c = (lat: saved.lat, lon: saved.lon, label: saved.city, fresh: false);
        _location = c;
        unawaited(_preview(true, c));
      }
      unawaited(_locate());
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  _Center? get _center => _here ? _location : (_address.text.trim() == _foundFor ? _found : null);

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locateFailed = false;
    });
    final fix = await _services.prayer.freshFix(userAsked: true);
    if (!mounted) return;
    if (fix == null) {
      return setState(() {
        _locating = false;
        _locateFailed = true;
      });
    }
    final before = _location;
    final c = (lat: fix.lat, lon: fix.lon, label: _services.prayer.place?.city ?? before?.label, fresh: true);
    // Within a couple of hundred metres the preview already shown stands.
    final moved = before == null || (before.lat - c.lat).abs() > 0.002 || (before.lon - c.lon).abs() > 0.002;
    setState(() {
      _locating = false;
      _location = c;
    });
    if (moved) {
      await _preview(true, c);
    } else if (_points[true] case final kept?) {
      setState(() => _points[true] = (lat: c.lat, lon: c.lon, label: kept.label, points: kept.points));
    }
  }

  Future<void> _preview(bool here, _Center c) async {
    try {
      final found = await _source.inRadius(await widget.auth(), lat: c.lat, lon: c.lon);
      if (mounted) setState(() => _points[here] = found);
    } on PlacesException {
      // The preview is a nicety; saving works without it.
      if (mounted) setState(() => _points[here] = (lat: c.lat, lon: c.lon, label: null, points: const []));
    }
  }

  Future<void> _find() async {
    final s = AppLocalizations.of(context);
    final text = _address.text.trim();
    if (text.isEmpty || (_found != null && _foundFor == text)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _finding = true;
      _addressError = null;
    });
    try {
      final found = await _source.inRadius(await widget.auth(), address: text);
      if (!mounted) return;
      setState(() {
        _found = (lat: found.lat, lon: found.lon, label: found.label ?? text, fresh: true);
        _foundFor = text;
        _points[false] = found;
      });
    } on PlacesException catch (e) {
      if (mounted) setState(() => _addressError = notifyError(s, e));
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  // Around where one stands: the fresh fix, not the last one seen (it may be
  // kilometres off), unless no fix can be had.
  bool get _canSave =>
      !_saving &&
      _types.isNotEmpty &&
      (_here ? _location != null && (_location!.fresh || !_locating) : _address.text.trim().isNotEmpty);

  Future<void> _save() async {
    final s = AppLocalizations.of(context);
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final c = _location;
    final AreaDraft draft = _here
        ? (lat: c!.lat, lon: c.lon, label: c.label, address: null, radiusKm: _radius, types: _types)
        : (lat: null, lon: null, label: null, address: _address.text.trim(), radiusKm: _radius, types: _types);
    try {
      final saved = await _source.saveArea(await widget.auth(), draft, id: widget.area?.id, lang: _lang);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, saved);
    } on PlacesException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _saving = false;
        if (e.code == 'address_not_found' || e.code == 'address_not_exact') {
          _addressError = notifyError(s, e);
        } else {
          _error = notifyError(s, e);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final center = _center;
    final preview = _points[_here];
    final inside = [
      for (final point in preview?.points ?? const <({double lat, double lon, PlaceKind kind, double km})>[])
        if (point.km <= _radius && _types.contains(point.kind)) point,
    ];
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  widget.area == null ? s.ntSheetAdd : s.ntSheetEdit,
                  style: const TextStyle(fontFamily: Brand.displayFont, fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(s.ntMyLocation),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.place_outlined, size: 18),
                      label: Text(s.ntAddress),
                    ),
                  ],
                  selected: {_here},
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  onSelectionChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _here = v.first);
                    if (_here && _location == null && !_locating) unawaited(_locate());
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: p.action,
                    selectedForegroundColor: Colors.white,
                    backgroundColor: p.card,
                    side: BorderSide(color: p.hairline),
                  ),
                ),
                const SizedBox(height: 12),
                if (_here) _locationPanel(s, p) else _addressPanel(s, p),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 210,
                    child: center == null
                        ? ColoredBox(
                            color: p.cardSelected,
                            child: Center(
                              child: _locating || _finding
                                  ? const CircularProgressIndicator()
                                  : Icon(Icons.radar_rounded, size: 40, color: p.accent.withValues(alpha: 0.5)),
                            ),
                          )
                        : AreaMap(
                            lat: center.lat,
                            lon: center.lon,
                            radiusKm: _radius,
                            points: [
                              for (final x in inside) (lat: x.lat, lon: x.lon, colour: kindColour(context, x.kind)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (center != null && preview != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: inside.isEmpty
                        ? [Text(s.ntNothingInside, style: TextStyle(fontSize: 13, color: p.inkMuted))]
                        : [
                            for (final kind in PlaceKind.values)
                              if (inside.any((x) => x.kind == kind))
                                _Count(
                                  kind: kind,
                                  text: switch (kind) {
                                    PlaceKind.mosque => s.ntCountMosque(inside.where((x) => x.kind == kind).length),
                                    PlaceKind.restaurant => s.ntCountRestaurant(
                                      inside.where((x) => x.kind == kind).length,
                                    ),
                                    PlaceKind.shop => s.ntCountShop(inside.where((x) => x.kind == kind).length),
                                  },
                                ),
                          ],
                  ),
                label(s.ntRadius),
                SegmentedButton<int>(
                  segments: [for (final km in notifyRadii) ButtonSegment(value: km, label: Text('$km km'))],
                  selected: {_radius},
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  onSelectionChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _radius = v.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: p.action,
                    selectedForegroundColor: Colors.white,
                    backgroundColor: p.card,
                    side: BorderSide(color: p.hairline),
                  ),
                ),
                label(s.ntWhich),
                Row(
                  children: [
                    for (final (i, kind) in PlaceKind.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _TypeTile(
                          kind: kind,
                          label: switch (kind) {
                            PlaceKind.mosque => s.ntTypesMosque,
                            PlaceKind.restaurant => s.ntTypesRestaurant,
                            PlaceKind.shop => s.ntTypesShop,
                          },
                          on: _types.contains(kind),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _types.contains(kind) ? _types.remove(kind) : _types.add(kind));
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                if (_types.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(s.ntPickOne, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 14),
                Text(s.ntNote, style: TextStyle(fontSize: 12.5, height: 1.4, color: p.inkMuted)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ListenableBuilder(
                    listenable: _address,
                    builder: (context, _) => FilledButton(
                      onPressed: _canSave ? _save : null,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(s.ntSave, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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

  Widget _locationPanel(AppLocalizations s, VegukinPalette p) {
    final c = _location;
    final failed = !_locating && _locateFailed && c == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        children: [
          Icon(
            failed ? Icons.location_disabled_rounded : Icons.my_location_rounded,
            color: failed ? Theme.of(context).colorScheme.error : p.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c != null
                      ? (c.label ?? '${c.lat.toStringAsFixed(4)}, ${c.lon.toStringAsFixed(4)}')
                      : failed
                      ? s.ntLocationFailed
                      : s.ntLocating,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
                if (c != null)
                  Text(
                    _locating
                        ? s.ntLocating
                        : c.fresh
                        ? s.ntLocated
                        : s.ntSavedCenter,
                    style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                  ),
              ],
            ),
          ),
          if (_locating)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
            )
          else if (c == null || !c.fresh)
            TextButton(onPressed: _locate, child: Text(s.ntRelocate)),
        ],
      ),
    );
  }

  Widget _addressPanel(AppLocalizations s, VegukinPalette p) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.hairlineStrong),
    );
    final text = _address.text.trim();
    final found = _found != null && _foundFor == text;
    final hint =
        _addressError ??
        (_finding
            ? s.ntFinding
            : found && _found!.label != null && _found!.label != text
            ? _found!.label!
            : s.ntAddressHint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _address,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _find(),
                onChanged: (_) => setState(() => _addressError = null),
                decoration: InputDecoration(
                  hintText: '서울 동대문구 회기로 56',
                  prefixIcon: Icon(found ? Icons.check_circle_rounded : Icons.place_outlined, color: p.accent),
                  isDense: true,
                  filled: true,
                  fillColor: p.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // "Topish" until the address is found, then "✓ Topildi", as on the web.
            FilledButton.tonal(
              onPressed: _finding || found ? null : _find,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              child: found
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [const Icon(Icons.check_rounded, size: 18), const SizedBox(width: 4), Text(s.ntFound)],
                    )
                  : Text(s.ntFind),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Text(
            hint,
            style: TextStyle(
              fontSize: 12.5,
              color: _addressError != null ? Theme.of(context).colorScheme.error : p.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.kind, required this.text});

  final PlaceKind kind;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colour = kindColour(context, kind);
    return DecoratedBox(
      decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '${kind.emoji} $text',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colour),
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.kind, required this.label, required this.on, required this.onTap});

  final PlaceKind kind;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: on ? p.cardSelected : p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: on ? p.accent : p.hairline, width: on ? 1.8 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(kind.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? p.ink : p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The area on OpenStreetMap: the circle filling most of the frame, the
/// places inside as dots, the centre pinned. Tiles at the zoom that fits the
/// radius, scaled between whole zoom levels; no map library.
class AreaMap extends StatelessWidget {
  const AreaMap({super.key, required this.lat, required this.lon, required this.radiusKm, this.points = const []});

  final double lat;
  final double lon;
  final int radiusKm;
  final List<({double lat, double lon, Color colour})> points;

  static ({double x, double y}) _world(double lat, double lon, int zoom) {
    final n = math.pow(2, zoom) * 256.0;
    final rad = lat * math.pi / 180;
    return (x: (lon + 180) / 360 * n, y: (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n);
  }

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        // Metres per pixel so the circle's width is 78% of the shorter side.
        final mpp = radiusKm * 2000 / (0.78 * math.min(w, h));
        final zoom = math.log(156543.03392 * math.cos(lat * math.pi / 180) / mpp) / math.ln2;
        final whole = zoom.floor().clamp(1, 18);
        final scale = math.pow(2, zoom - whole).toDouble();
        final tile = 256 * scale;
        final c = _world(lat, lon, whole);
        final left = c.x * scale - w / 2, top = c.y * scale - h / 2;
        Offset at(double plat, double plon) {
          final q = _world(plat, plon, whole);
          return Offset(q.x * scale - left, q.y * scale - top);
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: ColoredBox(color: p.cardSelected)),
            for (var ty = (top / tile).floor(); ty * tile < top + h; ty++)
              for (var tx = (left / tile).floor(); tx * tile < left + w; tx++)
                Positioned(
                  left: tx * tile - left,
                  top: ty * tile - top,
                  width: tile,
                  height: tile,
                  child: Image.network(
                    'https://tile.openstreetmap.org/$whole/$tx/$ty.png',
                    headers: const {'User-Agent': AppConfig.userAgent},
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
            Positioned.fill(
              child: CustomPaint(
                painter: _AreaPainter(
                  center: Offset(w / 2, h / 2),
                  radius: radiusKm * 1000 / mpp,
                  points: [for (final x in points) (at(x.lat, x.lon), x.colour)],
                  accent: p.accent,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9.5, color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({required this.center, required this.radius, required this.points, required this.accent});

  final Offset center;
  final double radius;
  final List<(Offset, Color)> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(center, radius, Paint()..color = accent.withValues(alpha: 0.12));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = accent,
    );
    for (final (at, colour) in points) {
      canvas.drawCircle(at, 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(at, 4.5, Paint()..color = colour);
    }
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(center, 6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_AreaPainter old) => true;
}
