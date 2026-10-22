import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'places_kit.dart';
import 'places_models.dart';
import 'places_parts.dart';

/// A sheet over the place page, lifted above the keyboard.
Future<T?> showPlaceSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: VegukinPalette.of(context).card,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
          child: child,
        ),
      ),
    );

class _Title extends StatelessWidget {
  const _Title(this.text, {this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text, style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.error)),
    );
  }
}

InputDecoration _field(BuildContext context, String hint) {
  final p = VegukinPalette.of(context);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: p.inkMuted),
    filled: true,
    fillColor: p.page,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.accent, width: 1.5)),
  );
}

/// How a review sheet ended.
enum ReviewOutcome { published, updated, deleted }

/// Stars and a few words; one's own review again, to change or delete.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.kit, required this.detail});

  final PlacesKit kit;
  final PlaceDetail detail;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  late final PlaceReview? _mine = widget.detail.ownReviews ? widget.detail.myReview : null;
  late int _rating = _mine?.rating ?? 0;
  late final _text = TextEditingController(text: _mine?.text ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    if (_rating == 0) {
      HapticFeedback.heavyImpact();
      return setState(() => _error = s.plReviewPick);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = await widget.kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      final updated = await widget.kit.source.review(auth, widget.detail.place.id, _rating, _text.text.trim());
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, updated || _mine != null ? ReviewOutcome.updated : ReviewOutcome.published);
    } on PlacesException catch (e) {
      if (mounted) setState(() => _error = placesMessage(s, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final s = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.plReviewDeleteAsk),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.plCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(s.plDelete),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final auth = await widget.kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      await widget.kit.source.deleteReview(auth, widget.detail.place.id);
      if (mounted) Navigator.pop(context, ReviewOutcome.deleted);
    } on PlacesException catch (e) {
      if (mounted) setState(() => _error = placesMessage(s, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final place = widget.detail.place;
    final labels = [s.plStar1, s.plStar2, s.plStar3, s.plStar4, s.plStar5];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(_mine == null ? s.plWriteReview : s.plEditReview, subtitle: place.name),
        Text(s.plRateQuestion, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                onPressed: _busy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _rating = star;
                          _error = null;
                        });
                      },
                tooltip: labels[star - 1],
                iconSize: 38,
                padding: const EdgeInsets.all(2),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: star <= _rating ? PlaceStars.colour(context) : p.hairlineStrong,
                ),
              ),
            const SizedBox(width: 8),
            if (_rating > 0)
              Expanded(
                child: Text(labels[_rating - 1], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.inkSoft)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          switch (place.kind) {
            PlaceKind.mosque => s.plReviewHintMosque,
            PlaceKind.restaurant => s.plReviewHintRestaurant,
            PlaceKind.shop => s.plReviewHintShop,
          },
          style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _text,
          enabled: !_busy,
          minLines: 3,
          maxLines: 7,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(context, s.plReviewPlaceholder),
        ),
        Text(s.plReviewPublic, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
        _Error(_error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text(_mine == null ? s.plReviewSend : s.plReviewSave),
        ),
        const SizedBox(height: 4),
        if (_mine != null)
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(s.plReviewDelete),
          )
        else
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(s.plCancel)),
      ],
    );
  }
}

/// The fields people can suggest, and how each is asked for.
const suggestFields = ['telegram', 'instagram', 'tiktok', 'note'];

String fieldLabel(AppLocalizations s, String field) => switch (field) {
      'telegram' => 'Telegram',
      'tiktok' => 'TikTok',
      'instagram' => 'Instagram',
      _ => s.plNoteLabel,
    };

IconData fieldIcon(String field) => switch (field) {
      'telegram' => Icons.telegram,
      'tiktok' => Icons.tiktok,
      'instagram' => Icons.camera_alt_rounded,
      _ => Icons.info_outline_rounded,
    };

Color fieldColour(BuildContext context, String field) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (field) {
    'telegram' => const Color(0xFF2AABEE),
    'tiktok' => dark ? const Color(0xFFF1F1EF) : const Color(0xFF111111),
    'instagram' => const Color(0xFFD62976),
    _ => VegukinPalette.of(context).accent,
  };
}

/// Which field to suggest, when more than one can be.
Future<String?> pickSuggestField(BuildContext context, List<String> fields) {
  final s = AppLocalizations.of(context);
  return showPlaceSheet<String>(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(s.plSuggestPick),
        for (final field in fields)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(fieldIcon(field), color: fieldColour(context, field)),
            title: Text(fieldLabel(s, field), style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pop(context, field),
          ),
      ],
    ),
  );
}

/// A link or the note, for the admin to check. Returns true when sent, or
/// when a suggestion for it was already waiting.
class SuggestSheet extends StatefulWidget {
  const SuggestSheet({super.key, required this.kit, required this.place, required this.field});

  final PlacesKit kit;
  final Place place;
  final String field;

  @override
  State<SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends State<SuggestSheet> {
  final _value = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _note => widget.field == 'note';

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    final value = _value.text.trim();
    if (value.isEmpty) return setState(() => _error = s.plTextEmpty);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = await widget.kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      await widget.kit.source.suggest(auth, widget.place.id, widget.field, value);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } on PlacesException catch (e) {
      if (!mounted) return;
      if (e.code == 'already_pending') return Navigator.pop(context, true);
      setState(() => _error = placesMessage(s, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final current = widget.place.social(widget.field);
    final label = fieldLabel(s, widget.field);
    final title = _note
        ? (current == null ? s.plSuggestAddNote : s.plSuggestEditNote)
        : (current == null ? s.plSuggestAddLink(label) : s.plSuggestEditLink(label));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(fieldIcon(widget.field), color: fieldColour(context, widget.field)),
            const SizedBox(width: 10),
            Expanded(child: _Title(title)),
          ],
        ),
        if (current != null) ...[
          Text(
            s.plSuggestCurrent(current),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, height: 1.4, color: p.inkMuted),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _value,
          enabled: !_busy,
          minLines: _note ? 4 : 1,
          maxLines: _note ? 8 : 1,
          maxLength: _note ? 500 : null,
          keyboardType: _note ? TextInputType.multiline : TextInputType.url,
          autocorrect: _note,
          enableSuggestions: _note,
          textCapitalization: _note ? TextCapitalization.sentences : TextCapitalization.none,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: _note ? null : (_) => _send(),
          decoration: _field(context, _note ? s.plNotePlaceholder : '@username'),
        ),
        const SizedBox(height: 6),
        Text(
          switch (widget.field) {
            'telegram' => s.plHintTelegram,
            'tiktok' => s.plHintTiktok,
            'instagram' => s.plHintInstagram,
            _ => s.plHintNote,
          },
          style: TextStyle(fontSize: 12.5, color: p.inkSoft),
        ),
        const SizedBox(height: 4),
        Text(s.plModeration, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
        _Error(_error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text(s.plSend),
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(s.plCancel)),
      ],
    );
  }
}

/// News for the people who watch the place: anyone's for a mosque, the
/// owner's for a restaurant or shop. Returns how many of this person's wait
/// for the admin.
class AnnounceSheet extends StatefulWidget {
  const AnnounceSheet({super.key, required this.kit, required this.place});

  final PlacesKit kit;
  final Place place;

  @override
  State<AnnounceSheet> createState() => _AnnounceSheetState();
}

class _AnnounceSheetState extends State<AnnounceSheet> {
  final _text = TextEditingController();
  int? _reach;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReach());
  }

  Future<void> _loadReach() async {
    try {
      final reach = await widget.kit.source.reach(await widget.kit.auth(), widget.place.id);
      if (mounted) setState(() => _reach = reach);
    } on PlacesException {
      // Without the number.
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    final text = _text.text.trim();
    if (text.isEmpty) return setState(() => _error = s.plTextEmpty);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = await widget.kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      final pending = await widget.kit.source.announce(auth, widget.place.id, text, widget.kit.language.code);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, pending);
    } on PlacesException catch (e) {
      if (mounted) setState(() => _error = placesMessage(s, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final mosque = widget.place.kind == PlaceKind.mosque;
    final reach = _reach;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(s.plAnnounceTitle, subtitle: widget.place.name),
        TextField(
          controller: _text,
          enabled: !_busy,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(context, mosque ? s.plAnnouncePlaceholderMosque : s.plAnnouncePlaceholderOwner),
        ),
        if (reach != null && reach > 0)
          Text(s.plAnnounceReach(reach), style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft)),
        const SizedBox(height: 4),
        Text(s.plModeration, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
        _Error(_error),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text(s.plAnnounceSend),
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(s.plCancel)),
      ],
    );
  }
}

/// The photos full screen: swipe between them, pinch or double-tap to zoom.
Future<void> showPlacePhotos(BuildContext context, List<PlacePhoto> photos, int start) =>
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _PhotoViewer(photos: photos, start: start),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.start});

  final List<PlacePhoto> photos;
  final int start;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              // A zoomed photo pans; swiping to the next waits until it's back.
              physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
              itemCount: widget.photos.length,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _index = i);
              },
              itemBuilder: (context, i) => _ZoomPhoto(
                photo: widget.photos[i],
                onZoom: (zoomed) {
                  if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                },
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
                    if (widget.photos.length > 1)
                      DecoratedBox(
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            s.plPhotoCount('${_index + 1}', '${widget.photos.length}'),
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
/// and again to fit. The copy the list already has shows at once; the
/// large one, sharp when zoomed, over it once loaded.
class _ZoomPhoto extends StatefulWidget {
  const _ZoomPhoto({required this.photo, required this.onZoom});

  final PlacePhoto photo;
  final ValueChanged<bool> onZoom;

  @override
  State<_ZoomPhoto> createState() => _ZoomPhotoState();
}

class _ZoomPhotoState extends State<_ZoomPhoto> with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  late final _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  Animation<Matrix4>? _to;
  Offset _tap = Offset.zero;

  static const _doubleTapScale = 2.6;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() => widget.onZoom(_zoom.value.getMaxScaleOnAxis() > 1.01));
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
    final s = AppLocalizations.of(context);
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
              Image(
                image: PlaceImage.full(context, widget.photo),
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white54)),
                errorBuilder: (_, _, _) =>
                    Center(child: Text(s.plPhotoFailed, style: const TextStyle(color: Colors.white70))),
              ),
              Image.network(
                '${widget.photo.full}',
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
