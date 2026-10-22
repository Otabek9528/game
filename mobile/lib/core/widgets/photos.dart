import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'khatam.dart';

/// One picture full screen: [quick] (small, most likely loaded already)
/// under [screen], and [sharp] fetched only once zoomed in. A video has
/// [onPlay] (and its size as [caption]): it plays in the phone's player.
class ViewerPicture {
  const ViewerPicture({this.quick, required this.screen, this.sharp, this.onPlay, this.caption});

  final ImageProvider? quick;
  final ImageProvider screen;
  final ImageProvider? sharp;
  final VoidCallback? onPlay;
  final String? caption;
}

/// [url] for zooming into, without decoding a camera's full size.
ImageProvider sharpImage(Uri url) =>
    ResizeImage(NetworkImage('$url'), width: 2560, height: 2560, policy: ResizeImagePolicy.fit);

/// Pictures full screen: swipe between them, pinch or double-tap to zoom;
/// "2 / 5" by [counter], [failed] for one that can't be had.
Future<void> showPhotoViewer(
  BuildContext context,
  List<ViewerPicture> pictures,
  int start, {
  required String Function(int index, int count) counter,
  required String failed,
}) =>
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _PhotoViewer(pictures: pictures, start: start, counter: counter, failed: failed),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));

/// A photo on its way: a spinner, and after a moment why it may take a
/// while. On [colour] in a card, or on nothing (black) full screen.
class PhotoLoading extends StatelessWidget {
  const PhotoLoading({super.key, this.colour});

  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colour = this.colour;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: colour == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(colour, Colors.black, 0.6)!, Color.lerp(colour, Colors.black, 0.35)!],
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (colour != null) CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.06))),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.plPhotoLoading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  // Only once it's taking a moment.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1600),
                    curve: const Interval(0.55, 1),
                    builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
                    child: Text(
                      s.plPhotoLoadingSpeed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.white70),
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

/// Photo layers over each other, each faded in when it arrives, and
/// whether one is on screen yet ([shown]) or all failed ([failed]).
mixin PhotoLayers<T extends StatefulWidget> on State<T> {
  bool shown = false;
  bool failed = false;

  void _mark({bool shown = false, bool failed = false}) {
    if (!(shown && !this.shown) && !(failed && !this.failed)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        this.shown |= shown;
        this.failed |= failed;
      });
    });
  }

  /// [image], faded in; [onError] in its place if it can't be had.
  Widget layer(ImageProvider image, BoxFit fit, Widget Function() onError) => Image(
        image: image,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => onError(),
        frameBuilder: (_, child, frame, sync) {
          if (frame != null) _mark(shown: true);
          return sync
              ? child
              : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 220), child: child);
        },
      );

  /// None of the layers could be had: [instead] unless one is shown.
  Widget layersFailed(Widget instead) {
    _mark(failed: true);
    return shown ? const SizedBox.shrink() : instead;
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.pictures, required this.start, required this.counter, required this.failed});

  final List<ViewerPicture> pictures;
  final int start;
  final String Function(int index, int count) counter;
  final String failed;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;
  bool _zoomed = false;

  /// Fingers on the screen: with two, it's a pinch, not a swipe.
  int _fingers = 0;

  void _finger(int change) {
    final pinching = _fingers >= 2;
    _fingers = (_fingers + change).clamp(0, 10);
    if ((_fingers >= 2) != pinching) setState(() {});
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Listener(
              onPointerDown: (_) => _finger(1),
              onPointerUp: (_) => _finger(-1),
              onPointerCancel: (_) => _finger(-1),
              child: PageView.builder(
                controller: _pages,
                // A pinch zooms from its first moment, and a zoomed photo
                // pans: no swipe to the next until it's back.
                physics: _zoomed || _fingers >= 2 ? const NeverScrollableScrollPhysics() : null,
                itemCount: widget.pictures.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) => _ZoomPhoto(
                  picture: widget.pictures[i],
                  failed: widget.failed,
                  onZoom: (zoomed) {
                    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                  },
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      style: IconButton.styleFrom(backgroundColor: Colors.black38),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    if (widget.pictures.length > 1)
                      DecoratedBox(
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            widget.counter(_index + 1, widget.pictures.length),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One photo, fitted: pinch to zoom, double-tap to zoom in where tapped
/// and again to fit. Zoomable at once: the small copy the list already has
/// shows straight away, the screen-sized one over it; the original, sharp
/// up close, is fetched only once zoomed in (no megabytes for a look).
class _ZoomPhoto extends StatefulWidget {
  const _ZoomPhoto({required this.picture, required this.failed, required this.onZoom});

  final ViewerPicture picture;
  final String failed;
  final ValueChanged<bool> onZoom;

  @override
  State<_ZoomPhoto> createState() => _ZoomPhotoState();
}

class _ZoomPhotoState extends State<_ZoomPhoto> with SingleTickerProviderStateMixin, PhotoLayers {
  final _zoom = TransformationController();
  late final _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  Animation<Matrix4>? _to;
  Offset _tap = Offset.zero;
  bool _sharp = false;

  static const _doubleTapScale = 2.6;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
      widget.onZoom(zoomed);
      if (zoomed && !_sharp) setState(() => _sharp = true);
    });
    _animation.addListener(() => _zoom.value = _to!.value);
  }

  @override
  void dispose() {
    _animation.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _toggle() {
    final Matrix4 end;
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      end = Matrix4.identity();
    } else {
      end = Matrix4.identity()
        ..translateByDouble(-_tap.dx * (_doubleTapScale - 1), -_tap.dy * (_doubleTapScale - 1), 0, 1)
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    _to = Matrix4Tween(begin: _zoom.value, end: end).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final picture = widget.picture;
    final sharp = picture.sharp;
    Widget none() => layersFailed(Center(child: Text(widget.failed, style: const TextStyle(color: Colors.white70))));
    if (picture.onPlay != null) return _Video(picture: picture, none: none, layer: layer, shown: shown);
    return GestureDetector(
      onDoubleTapDown: (d) => _tap = d.localPosition,
      onDoubleTap: _toggle,
      child: InteractiveViewer(
        transformationController: _zoom,
        maxScale: 5,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!shown && !failed) const PhotoLoading(),
              if (picture.quick case final quick?) layer(quick, BoxFit.contain, () => const SizedBox.shrink()),
              layer(picture.screen, BoxFit.contain, () => sharp == null ? none() : layer(sharp, BoxFit.contain, none)),
              if (_sharp && sharp != null) layer(sharp, BoxFit.contain, () => const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// A video: its picture, and a play button (it plays in the phone's
/// player) with its size.
class _Video extends StatelessWidget {
  const _Video({required this.picture, required this.none, required this.layer, required this.shown});

  final ViewerPicture picture;
  final Widget Function() none;
  final Widget Function(ImageProvider, BoxFit, Widget Function()) layer;
  final bool shown;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: picture.onPlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (picture.quick case final quick?) layer(quick, BoxFit.contain, () => const SizedBox.shrink()),
            layer(picture.screen, BoxFit.contain, () => const SizedBox.shrink()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 18)],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 46, color: Colors.black87),
                  ),
                  if (picture.caption case final caption?) ...[
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(caption, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
