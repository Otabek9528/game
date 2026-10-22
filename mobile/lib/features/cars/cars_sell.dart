import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import 'car_detail.dart';
import 'cars_kit.dart';
import 'cars_models.dart';
import 'cars_parts.dart';

/// One's own listings (with where each stands with the admin) and a new
/// one, as the Mini App's Sotish page. Needs someone signed in.
class CarsSellTab extends StatefulWidget {
  const CarsSellTab({super.key, required this.kit});

  final CarsKit kit;

  @override
  State<CarsSellTab> createState() => _CarsSellTabState();
}

class _CarsSellTabState extends State<CarsSellTab> with AutomaticKeepAliveClientMixin {
  CarsKit get _kit => widget.kit;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!_kit.signedIn) return;
    setState(() => _error = null);
    try {
      await _kit.loadOwn();
    } on CarsException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _signIn() async {
    if (await askToSignIn(context, _kit.services) && mounted) await _load();
  }

  Future<void> _form([OwnCar? car]) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CarPostForm(kit: _kit, car: car),
      ),
    );
    if (done == true && mounted) await _load();
  }

  Future<void> _sold(OwnCar car) async {
    final s = AppLocalizations.of(context);
    if (!await _confirm(s.carSoldConfirmTitle, s.carSoldConfirmBody, s.carSoldConfirmYes)) return;
    await _act(() => _kit.source.markSold(_kitAuth, car.id), s.carMarkedSold);
  }

  Future<void> _delete(OwnCar car) async {
    final s = AppLocalizations.of(context);
    if (!await _confirm(s.carDeleteConfirmTitle, s.carDeleteConfirmBody, s.carDelete)) return;
    await _act(() => _kit.source.withdrawPost(_kitAuth, car.id), s.carDeleted);
  }

  Map<String, String> get _kitAuth => _kit.services.account.authHeaders;

  Future<void> _act(Future<void> Function() call, String done) async {
    final s = AppLocalizations.of(context);
    try {
      await call();
      HapticFeedback.mediumImpact();
      if (mounted) showCarsSnack(context, done);
      await _load();
    } on CarsException {
      if (mounted) showCarsSnack(context, s.carErrorGeneric);
    }
  }

  Future<bool> _confirm(String title, String body, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).carCancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(yes)),
          ],
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_kit, _kit.services.account]),
      builder: (context, _) {
        final own = _kit.ownCars;
        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              CarsTabBar(title: s.carMyPosts, subtitle: Text(s.carNewPostSub)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (!_kit.signedIn)
                      SignInCard(
                        icon: Icons.sell_rounded,
                        title: s.carSignInSellTitle,
                        body: s.carSignInSellBody,
                        action: s.carSignInButton,
                        onAction: _signIn,
                      )
                    else ...[
                      Material(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _form();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.carNewPost,
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                      Text(s.carNewPostSub, style: const TextStyle(fontSize: 13, color: Color(0xDDFFFFFF))),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null && own == null)
                        CarsMessage(
                          emoji: '⚠️',
                          title: s.carLoadFailed,
                          body: s.carCheckInternet,
                          action: s.retry,
                          onAction: _load,
                        )
                      else if (own == null)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (own.isEmpty)
                        CarsMessage(emoji: '🚘', title: s.carNoPostsTitle, body: s.carNoPostsBody)
                      else
                        for (final car in own) ...[
                          _OwnCard(
                            car: car,
                            onOpen: car.moderation == CarModeration.approved && !car.sold
                                ? () => openCar(context, _kit, car.id)
                                : () => _form(car),
                            onEdit: car.sold ? null : () => _form(car),
                            onSold: !car.sold && car.moderation == CarModeration.approved ? () => _sold(car) : null,
                            onDelete: () => _delete(car),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OwnCard extends StatelessWidget {
  const _OwnCard({required this.car, required this.onOpen, required this.onEdit, required this.onSold, required this.onDelete});

  final OwnCar car;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onSold;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final (label, colour) = car.sold
        ? (s.carSold, dealColour(context, null, sold: true))
        : switch (car.moderation) {
            CarModeration.approved => (s.carStateApproved, dealColour(context, Deal.low)),
            CarModeration.pending => (s.carStatePending, dealColour(context, Deal.mid)),
            CarModeration.changesRequested => (s.carStateChanges, dealColour(context, Deal.mid)),
            CarModeration.rejected => (s.carStateRejected, dealColour(context, Deal.high)),
            CarModeration.draft => (s.carStateDraft, p.inkMuted),
          };
    final meta = [
      if (car.mileageKm != null) '${groupDigits(car.mileageKm!)} km',
      ?fuelLabel(s, car.fuel),
      if (car.views > 0) '👁 ${car.views}',
    ].join(' · ');
    final note = car.reviewNote;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 92,
                      height: 72,
                      child: car.thumb == null
                          ? CarPlaceholder(id: car.id)
                          : Image.network(
                              '${car.thumb}',
                              fit: BoxFit.cover,
                              cacheWidth: 240,
                              errorBuilder: (_, _, _) => CarPlaceholder(id: car.id),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colour.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Text(
                              label,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: colour),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [car.brand ?? '', car.model ?? '', if (car.year != null) '· ${car.year}'].join(' ').trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink),
                        ),
                        Text(
                          won(car.priceKrw),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.inkSoft),
                        ),
                        if (meta.isNotEmpty) Text(meta, style: TextStyle(fontSize: 12, color: p.inkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              if (note != null &&
                  (car.moderation == CarModeration.rejected || car.moderation == CarModeration.changesRequested)) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colour.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${car.moderation == CarModeration.rejected ? '⚠️' : '✏️'}  $note',
                    style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onEdit != null)
                    TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: Text(s.carEdit)),
                  if (onSold != null)
                    TextButton.icon(
                      onPressed: onSold,
                      style: TextButton.styleFrom(foregroundColor: dealColour(context, Deal.low)),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(s.carMarkSold),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: dealColour(context, Deal.high)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(s.carDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ the form

/// A picked photo or video, not sent yet.
typedef _Picked = ({XFile file, bool video});

/// Writing a listing (or changing one): photos and video first (the first
/// the cover), the car, the price and papers, how to reach the seller, a
/// description. Sent for the admin's review; a duplicate is said so.
class CarPostForm extends StatefulWidget {
  const CarPostForm({super.key, required this.kit, this.car});

  final CarsKit kit;

  /// One's own listing to change; null for a new one.
  final OwnCar? car;

  /// Picks photos and videos instead of the phone's picker, in tests.
  @visibleForTesting
  static Future<List<XFile>> Function(int limit)? debugPickMedia;

  @override
  State<CarPostForm> createState() => _CarPostFormState();
}

class _CarPostFormState extends State<CarPostForm> {
  CarsKit get _kit => widget.kit;
  OwnCar? get _car => widget.car;
  bool get _editing => _car != null;

  late String? _brand = _car?.brand;
  late String? _model = _car?.model;
  late int? _year = _car?.year;
  late final _generation = TextEditingController(text: _car?.generation ?? '');
  late final _mileage = TextEditingController(text: _car?.mileageKm == null ? '' : groupDigits(_car!.mileageKm!));
  late final _price = TextEditingController(text: _car?.priceKrw == null ? '' : groupDigits(_car!.priceKrw!));
  late final _phone = TextEditingController(text: _car?.phone ?? '');
  late final _handle = TextEditingController(text: _car?.handle == null ? '' : '@${_car!.handle}');
  late final _description = TextEditingController(text: _car?.description ?? '');
  late String? _transmission = _car?.transmission;
  late String? _fuel = _car?.fuel;
  late bool _negotiable = _car?.negotiable ?? false;
  late String? _legal = _car?.legalStatus;
  late bool? _registration = _car?.registrationRequired;
  final _media = <_Picked>[];

  /// The draft made by a send that stopped halfway, to go on with.
  int? _draftId;
  bool _busy = false;
  String? _progress;
  final _missing = <String>{};

  static const _maxMedia = 10;
  static const _maxVideo = 50 * 1024 * 1024;

  @override
  void dispose() {
    for (final c in [_generation, _mileage, _price, _phone, _handle, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final s = AppLocalizations.of(context);
    final room = _maxMedia - _media.length;
    if (room <= 0) return showCarsSnack(context, s.carMediaLimit);
    final picked =
        await (CarPostForm.debugPickMedia ??
            (limit) => ImagePicker().pickMultipleMedia(limit: limit, maxWidth: 1600, maxHeight: 1600, imageQuality: 85))(room);
    for (final f in picked.take(room)) {
      final video =
          (f.mimeType ?? '').startsWith('video') || RegExp(r'\.(mp4|mov|3gp|mkv|webm)$', caseSensitive: false).hasMatch(f.path);
      if (video && await f.length() > _maxVideo) {
        if (mounted) showCarsSnack(context, s.carVideoTooBig);
        continue;
      }
      _media.add((file: f, video: video));
    }
    if (mounted) setState(() => _missing.remove('media'));
  }

  Future<void> _chooseBrand() async {
    final s = AppLocalizations.of(context);
    await _kit.loadCatalog();
    if (!mounted) return;
    final brands = [for (final b in _kit.catalog ?? const <CarBrand>[]) b.brand];
    final brand = await _choose(s.carBrand, brands, logos: true);
    if (brand == null || !mounted) return;
    setState(() {
      if (brand != _brand) _model = null;
      _brand = brand;
      _missing.remove('brand');
    });
  }

  Future<void> _chooseModel() async {
    final s = AppLocalizations.of(context);
    final brand = _brand;
    if (brand == null) return showCarsSnack(context, s.carPickBrandFirst);
    final models = [
      for (final b in _kit.catalog ?? const <CarBrand>[])
        if (b.brand == brand)
          for (final m in b.models) m.model,
    ];
    final model = await _choose(s.carPickModelTitle, models, other: s.carOtherModel);
    if (model == null || !mounted) return;
    setState(() {
      _model = model;
      _missing.remove('model');
    });
  }

  Future<void> _chooseYear() async {
    final s = AppLocalizations.of(context);
    final now = _kit.thisYear;
    final year = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: VegukinPalette.of(context).page,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.carPickYear, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.9,
                children: [
                  for (var y = now + 1; y >= 1990; y--)
                    CarChip(label: '$y', on: y == _year, onTap: () => Navigator.pop(context, y)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (year != null && mounted) {
      setState(() {
        _year = year;
        _missing.remove('year');
      });
    }
  }

  /// One of [options], searched; [other] lets one type it in.
  Future<String?> _choose(String title, List<String> options, {bool logos = false, String? other}) async {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: p.page,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: _OptionList(title: title, options: options, logos: logos, other: other),
      ),
    );
    if (chosen != '\u0000' || other == null || !mounted) return chosen;
    final typed = TextEditingController(text: _model ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.carModel),
        content: TextField(
          controller: typed,
          autofocus: true,
          decoration: InputDecoration(hintText: s.carModelHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.carCancel)),
          TextButton(onPressed: () => Navigator.pop(context, typed.text.trim()), child: Text(s.carOk)),
        ],
      ),
    );
    typed.dispose();
    return name == null || name.isEmpty ? null : name;
  }

  static int? _number(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), ''));

  /// The form as a post, or null with what's missing marked.
  CarPost? _collect() {
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    final handle = _handle.text.trim().replaceFirst(RegExp(r'^@'), '');
    _missing
      ..clear()
      ..addAll([
        if (_brand == null) 'brand',
        if (_model == null) 'model',
        if (_year == null) 'year',
        if ((_number(_price) ?? 0) == 0) 'price',
        if (!_editing && _media.isEmpty) 'media',
        if ((phone.isEmpty && handle.isEmpty) || (phone.isNotEmpty && phone.length < 9)) 'contact',
      ]);
    setState(() {});
    if (_missing.isNotEmpty) return null;
    return CarPost(
      brand: _brand!,
      model: _model!,
      year: _year!,
      priceKrw: _number(_price)!,
      generation: _generation.text.trim().isEmpty ? null : _generation.text.trim(),
      mileageKm: _number(_mileage),
      transmission: _transmission,
      fuel: _fuel,
      negotiable: _negotiable,
      legalStatus: _legal,
      registrationRequired: _registration,
      phone: phone.isEmpty ? null : phone,
      handle: handle.isEmpty ? null : handle,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
    );
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final post = _collect();
    if (post == null) {
      HapticFeedback.heavyImpact();
      return showCarsSnack(context, _missing.contains('media') && _missing.length == 1 ? s.carNeedPhoto : s.carRequiredMissing);
    }
    setState(() => _busy = true);
    try {
      final auth = await _kit.auth();
      if (_editing) {
        await _kit.source.editPost(auth, _car!.id, post);
        if (!mounted) return;
        showCarsSnack(context, s.carChangesSaved);
        Navigator.pop(context, true);
        return;
      }
      final matches = await _kit.source.duplicates(auth, post, except: _draftId);
      if (matches.isNotEmpty) return await _duplicates(matches);
      final int id;
      if (_draftId case final draft?) {
        id = draft;
        await _kit.source.editPost(auth, id, post);
      } else {
        id = _draftId = await _kit.source.createPost(auth, post);
      }
      for (final (i, m) in _media.toList().indexed) {
        if (mounted) setState(() => _progress = s.carUploading('${i + 1}', '${_media.length}'));
        await _kit.source.addMedia(auth, id, await m.file.readAsBytes(), m.file.name, video: m.video, order: i);
        _media.remove(m);
      }
      await _kit.source.submitPost(auth, id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showCarsSnack(context, s.carSubmitted);
      Navigator.pop(context, true);
    } on CarsException catch (e) {
      if (!mounted) return;
      if (e.code == 'duplicate') return _duplicates(e.matches);
      showCarsSnack(context, switch (e.code) {
        'offline' => s.carCheckInternet,
        'no_media' => s.carNeedPhoto,
        'video_too_large' => s.carVideoTooBig,
        'media_limit' => s.carMediaLimit,
        'validation_failed' => s.carRequiredMissing,
        _ => s.carErrorGeneric,
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _duplicates(List<CarDuplicate> matches) async {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    HapticFeedback.heavyImpact();
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.carDupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.carDupBody, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
            const SizedBox(height: 12),
            for (final m in matches)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: m.thumb == null
                        ? CarPlaceholder(id: m.id)
                        : Image.network(
                            '${m.thumb}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => CarPlaceholder(id: m.id),
                          ),
                  ),
                ),
                title: Text([m.brand, m.model, if (m.year != null) '${m.year}'].whereType<String>().join(' ')),
                subtitle: Text(m.own ? s.carDupOwn : won(m.priceKrw)),
                onTap: m.viewable
                    ? () {
                        Navigator.pop(context);
                        openCar(this.context, _kit, m.id);
                      }
                    : null,
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s.carOk))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final legalOptions = [('legal', s.carLegalOk), ('nolegal', s.carLegalNo)];
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
        title: Text(_editing ? s.carEditPostTitle : s.carNewPostTitle),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.card,
          border: Border(top: BorderSide(color: p.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: FilledButton(
              onPressed: _busy ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: _busy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        ),
                        if (_progress != null) ...[const SizedBox(width: 10), Text(_progress!)],
                      ],
                    )
                  : Text(
                      _editing ? s.carSaveChanges : s.carSubmit,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _FormSection(
            icon: Icons.photo_library_outlined,
            title: s.carPhotos,
            error: _missing.contains('media'),
            children: [
              if (_editing)
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _car!.media.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _Thumb(
                      image: _car!.media[i].thumb == null ? null : NetworkImage('${_car!.media[i].thumb}'),
                      video: _car!.media[i].video,
                      cover: i == 0,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, m) in _media.indexed)
                      _Thumb(
                        image: m.video ? null : FileImage(File(m.file.path)),
                        video: m.video,
                        cover: i == 0,
                        onRemove: _busy ? null : () => setState(() => _media.removeAt(i)),
                      ),
                    if (_media.length < _maxMedia)
                      InkWell(
                        onTap: _busy ? null : _pickMedia,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: p.cardSelected,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.accent.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: p.accent),
                              const SizedBox(height: 4),
                              Text(
                                s.carAddMedia,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(_editing ? s.carPhotosLocked : s.carPhotosHint, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
            ],
          ),
          _FormSection(
            icon: Icons.directions_car_outlined,
            title: s.carCarSection,
            children: [
              _Select(
                label: '${s.carBrand} *',
                value: _brand,
                logo: _brand,
                error: _missing.contains('brand'),
                onTap: _chooseBrand,
              ),
              const SizedBox(height: 12),
              _Select(label: '${s.carModel} *', value: _model, error: _missing.contains('model'), onTap: _chooseModel),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Select(
                      label: '${s.carYear} *',
                      value: _year?.toString(),
                      error: _missing.contains('year'),
                      onTap: _chooseYear,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Text(label: s.carGenerationOptional, controller: _generation, hint: 'DN8'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CarNumberField(label: s.carMileageLabel, controller: _mileage, hint: '150 000', grouped: true, onChanged: () {}),
              const SizedBox(height: 12),
              CarFieldLabel(s.carGearbox),
              _Choice(
                options: [('automatic', s.carAutomatic), ('manual', s.carManual)],
                value: _transmission,
                onChanged: (v) => setState(() => _transmission = v),
              ),
              const SizedBox(height: 12),
              CarFieldLabel(s.carFuelType),
              _Choice(
                options: [for (final f in carFuels) (f, fuelLabel(s, f)!)],
                value: _fuel,
                onChanged: (v) => setState(() => _fuel = v),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.payments_outlined,
            title: s.carPriceSection,
            children: [
              CarNumberField(
                label: '${s.carPriceLabel} *',
                controller: _price,
                hint: '7 000 000',
                grouped: true,
                onChanged: () {
                  if (_missing.remove('price')) setState(() {});
                },
              ),
              if (_missing.contains('price')) _ErrorLine(s.carRequiredMissing),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _negotiable,
                onChanged: (v) => setState(() => _negotiable = v),
                title: Text(
                  s.carNegotiable,
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                ),
                subtitle: Text(s.carNegotiableSub),
              ),
              CarFieldLabel(s.carLegalLabel),
              _Choice(options: legalOptions, value: _legal, onChanged: (v) => setState(() => _legal = v)),
              const SizedBox(height: 12),
              CarFieldLabel(s.carRegQuestion),
              _Choice(
                options: [('1', s.carRegYes), ('0', s.carNotRequired)],
                value: _registration == null ? null : (_registration! ? '1' : '0'),
                onChanged: (v) => setState(() => _registration = v == null ? null : v == '1'),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.call_outlined,
            title: s.carContact,
            error: _missing.contains('contact'),
            children: [
              _Text(label: s.carPhoneLabel, controller: _phone, hint: '010 1234 5678', phone: true),
              const SizedBox(height: 12),
              _Text(label: 'Telegram', controller: _handle, hint: '@username'),
              const SizedBox(height: 6),
              Text(
                s.carContactHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _missing.contains('contact') ? dealColour(context, Deal.high) : p.inkMuted,
                ),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.notes_rounded,
            title: s.carDescription,
            children: [_Text(label: null, controller: _description, hint: s.carDescriptionHint, lines: 5, maxLength: 2000)],
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.icon, required this.title, required this.children, this.error = false});

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: error ? dealColour(context, Deal.high) : p.hairline, width: error ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: p.accent),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, left: 4),
    child: Text(text, style: TextStyle(fontSize: 12.5, color: dealColour(context, Deal.high))),
  );
}

/// A choice opened from a sheet: its label above, the value or a dash.
class _Select extends StatelessWidget {
  const _Select({required this.label, required this.value, required this.onTap, this.logo, this.error = false});

  final String label;
  final String? value;
  final String? logo;
  final VoidCallback onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarFieldLabel(label),
        Material(
          color: p.page,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: error ? dealColour(context, Deal.high) : p.hairline, width: error ? 1.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  if (logo != null) ...[BrandLogo(logo!, size: 26), const SizedBox(width: 10)],
                  Expanded(
                    child: Text(
                      value ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: value == null ? p.inkMuted : p.ink),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, color: p.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required this.label,
    required this.controller,
    required this.hint,
    this.lines = 1,
    this.maxLength,
    this.phone = false,
  });

  final String? label;
  final TextEditingController controller;
  final String hint;
  final int lines;
  final int? maxLength;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.hairline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) CarFieldLabel(label!),
        TextField(
          controller: controller,
          minLines: lines,
          maxLines: lines,
          maxLength: maxLength,
          keyboardType: phone ? TextInputType.phone : null,
          inputFormatters: phone
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d +\-]')), LengthLimitingTextInputFormatter(16)]
              : null,
          style: TextStyle(fontSize: 15.5, color: p.ink),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: p.page,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// One of a few, or none (tapping the chosen one again).
class _Choice extends StatelessWidget {
  const _Choice({required this.options, required this.value, required this.onChanged});

  final List<(String, String)> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (key, label) in options)
        CarChip(label: label, on: value == key, onTap: () => onChanged(value == key ? null : key)),
    ],
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.video, required this.cover, this.onRemove});

  final ImageProvider? image;
  final bool video;
  final bool cover;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return SizedBox.square(
      dimension: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: image == null
                ? ColoredBox(
                    color: p.ink,
                    child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
                  )
                : Image(
                    image: ResizeImage(image!, width: 240),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: p.badge),
                  ),
          ),
          if (video && image != null) const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28)),
          if (cover)
            Positioned(
              left: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  child: Text(
                    s.carCover,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              right: 2,
              top: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A searchable list of [options]; [other]: a last row to type one in
/// (returns "\u0000").
class _OptionList extends StatefulWidget {
  const _OptionList({required this.title, required this.options, required this.logos, this.other});

  final String title;
  final List<String> options;
  final bool logos;
  final String? other;

  @override
  State<_OptionList> createState() => _OptionListState();
}

class _OptionListState extends State<_OptionList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final shown = [
      for (final o in widget.options)
        if (o.toLowerCase().contains(_query.toLowerCase())) o,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            widget.title,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(hintText: s.carSearchHint, prefixIcon: const Icon(Icons.search_rounded), isDense: true),
          ),
        ),
        Expanded(
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              children: [
                for (final o in shown)
                  ListTile(
                    leading: widget.logos ? BrandLogo(o, size: 34) : null,
                    title: Text(
                      o,
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                    ),
                    onTap: () => Navigator.pop(context, o),
                  ),
                if (widget.other != null)
                  ListTile(
                    leading: Icon(Icons.edit_outlined, color: p.accent),
                    title: Text(
                      widget.other!,
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.accent),
                    ),
                    onTap: () => Navigator.pop(context, '\u0000'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
