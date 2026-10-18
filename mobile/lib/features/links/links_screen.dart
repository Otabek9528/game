import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/prayer_models.dart';
import 'links_controller.dart';
import 'links_data.dart';

/// The web page's useful links (pages/links/) on one screen: a search that
/// knows every spelling of a city, the job groups nearest the user first
/// (or by part of Korea), the "Korea life" links by topic and in the app's
/// language, the community groups, and favourites on top. A long press on
/// a link copies or shares it.
class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  late final LinksController _c = LinksController(store: widget.services.store, script: widget.services.linksScript);
  final _search = TextEditingController();
  String _query = '';
  bool _locating = false;

  AppServices get _services => widget.services;
  AppLanguage get _language => _services.locale.language ?? AppLanguage.uz;

  @override
  void initState() {
    super.initState();
    _c.start();
  }

  @override
  void dispose() {
    _c.dispose();
    _search.dispose();
    super.dispose();
  }

  void _open(UsefulLink link) {
    HapticFeedback.lightImpact();
    _services.openLink(Uri.parse(link.url));
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    await _services.prayer.locate(userAsked: true);
    if (mounted) setState(() => _locating = false);
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  Future<void> _menu(UsefulLink link) async {
    HapticFeedback.mediumImpact();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final favorite = _c.isFavorite(link);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: p.card,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _Badge(link: link, size: 44),
              title: Text(link.title(_language), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
              subtitle: Text(link.url.replaceFirst('https://', ''), style: TextStyle(color: p.inkMuted)),
            ),
            const Divider(height: 8),
            for (final (value, icon, label) in [
              ('open', Icons.send_rounded, s.linksOpen),
              ('copy', Icons.copy_rounded, s.linksCopy),
              ('share', Icons.share_rounded, s.linksShare),
              ('favorite', favorite ? Icons.star_rounded : Icons.star_border_rounded,
                  favorite ? s.linksUnfavorite : s.linksFavorite),
            ])
              ListTile(
                leading: Icon(icon, color: value == 'favorite' && favorite ? Brand.gold500 : p.accent),
                title: Text(label, style: TextStyle(color: p.ink)),
                onTap: () => Navigator.pop(context, value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'open':
        _open(link);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: link.url));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(s.linksCopied), behavior: SnackBarBehavior.floating));
      case 'share':
        await _services.shareText('${link.title(_language)}\n${link.url}');
      case 'favorite':
        await _c.toggleFavorite(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: ListenableBuilder(
          listenable: Listenable.merge([_c, _services.prayer]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(
                title: s.linksTitle,
                subtitle: s.linksSubtitle(_c.all.length),
                search: _SearchBox(
                  controller: _search,
                  hint: s.linksSearch,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: _clearSearch,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + bottom),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: normalizeQuery(_query).isNotEmpty ? _results(context) : _browse(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final found = _c.search(_query);
    if (found.isEmpty) {
      return [
        const SizedBox(height: 24),
        Icon(Icons.search_off_rounded, size: 44, color: p.inkMuted),
        const SizedBox(height: 10),
        Text(s.linksNothing, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.inkSoft)),
        const SizedBox(height: 24),
        _Suggest(onTap: () => _services.openLink(Uri.parse(suggestGroupUrl))),
      ];
    }
    final place = _services.prayer.place;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(s.linksResults(found.length), style: TextStyle(fontSize: 13, color: p.inkMuted)),
      ),
      for (final (kind, title) in [
        (LinkKind.job, s.linksJobs),
        (LinkKind.life, s.linksLife),
        (LinkKind.group, s.linksGroups),
      ])
        if (found.any((l) => l.kind == kind))
          _section(context, title, [
            for (final link in found.where((l) => l.kind == kind)) _row(context, link, place, highlight: _query),
          ]),
    ];
  }

  List<Widget> _browse(BuildContext context) {
    final s = AppLocalizations.of(context);
    final favorites = _c.favorites;
    return [
      if (favorites.isNotEmpty) ...[
        _Label(icon: Icons.star_rounded, text: s.linksFavorites, color: Brand.gold500),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _FavoriteChip(
              title: favorites[i].title(_language),
              onTap: () => _open(favorites[i]),
              onLongPress: () => _menu(favorites[i]),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      _Tabs(
        tab: _c.tab,
        labels: [s.linksJobs, s.linksLife, s.linksGroups],
        onChanged: (t) {
          HapticFeedback.selectionClick();
          _c.setTab(t);
        },
      ),
      const SizedBox(height: 14),
      ...switch (_c.tab) {
        LinksTab.jobs => _jobs(context),
        LinksTab.life => _life(context),
        LinksTab.groups => [
            _section(context, null, [for (final link in _c.groups) _row(context, link, null)]),
          ],
      },
      const SizedBox(height: 6),
      _Suggest(onTap: () => _services.openLink(Uri.parse(suggestGroupUrl))),
    ];
  }

  List<Widget> _jobs(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final place = _services.prayer.place;
    final inKorea = LinksController.inKorea(place);
    final nearest = inKorea && _c.order == JobOrder.nearest;
    final jobs = _c.jobs;
    Widget rows(Iterable<UsefulLink> links) => _section(context, null, [for (final l in links) _row(context, l, place)]);

    final header = <Widget>[
      if (inKorea)
        Row(
          children: [
            for (final (order, icon, label) in [
              (JobOrder.nearest, Icons.near_me_rounded, s.linksNearest),
              (JobOrder.regions, Icons.map_rounded, s.linksByRegion),
            ]) ...[
              ChoiceChip(
                avatar: Icon(icon, size: 17, color: _c.order == order ? Colors.white : p.accent),
                label: Text(label),
                selected: _c.order == order,
                showCheckmark: false,
                selectedColor: p.action,
                labelStyle: TextStyle(
                  color: _c.order == order ? Colors.white : p.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: p.card,
                side: BorderSide(color: _c.order == order ? p.action : p.hairline),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  _c.setOrder(order);
                },
              ),
              const SizedBox(width: 8),
            ],
            if (nearest && place?.city != null)
              Expanded(
                child: Text(
                  s.linksYourPlace(place!.city!),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                ),
              ),
          ],
        )
      else if (place == null)
        _LocateCard(busy: _locating, onLocate: _locate),
      const SizedBox(height: 12),
    ];

    if (nearest) {
      double km(UsefulLink l) => LinksController.distanceKm(l, place) ?? double.infinity;
      final placed = jobs.where((l) => l.placed && l.cities.isNotEmpty).toList()
        ..sort((a, b) => km(a).compareTo(km(b)));
      final near = placed.where((l) => km(l) <= 50).toList();
      final far = placed.where((l) => km(l) > 50).toList();
      final nationwide = jobs.where((l) => l.region == LinkRegion.nationwide);
      final unknown = jobs.where((l) => !l.placed);
      return [
        ...header,
        if (nationwide.isNotEmpty) ...[
          _Label(icon: Icons.public_rounded, text: s.linksNationwide),
          rows(nationwide),
        ],
        if (near.isNotEmpty) ...[_Label(icon: Icons.near_me_rounded, text: s.linksNearby), rows(near)],
        if (far.isNotEmpty) ...[_Label(icon: Icons.location_city_rounded, text: s.linksFarther), rows(far)],
        if (unknown.isNotEmpty) ...[_Label(icon: Icons.more_horiz_rounded, text: s.linksOther), rows(unknown)],
      ];
    }

    final regions = [
      (LinkRegion.nationwide, Icons.public_rounded, s.linksNationwide),
      (LinkRegion.capital, Icons.location_city_rounded, s.linksRegionCapital),
      (LinkRegion.chungcheong, Icons.landscape_rounded, s.linksRegionChungcheong),
      (LinkRegion.jeolla, Icons.agriculture_rounded, s.linksRegionJeolla),
      (LinkRegion.gyeongsang, Icons.sailing_rounded, s.linksRegionGyeongsang),
      (LinkRegion.other, Icons.more_horiz_rounded, s.linksOther),
    ];
    return [
      ...header,
      for (final (region, icon, title) in regions)
        if (jobs.any((l) => l.region == region)) ...[
          _Label(icon: icon, text: title),
          rows(jobs.where((l) => l.region == region).toList()
            ..sort((a, b) => normalizeQuery(a.name).compareTo(normalizeQuery(b.name)))),
        ],
    ];
  }

  List<Widget> _life(BuildContext context) {
    final s = AppLocalizations.of(context);
    final topics = [
      (LifeTopic.official, Icons.account_balance_rounded, s.linksTopicOfficial),
      (LifeTopic.news, Icons.newspaper_rounded, s.linksTopicNews),
      (LifeTopic.legal, Icons.gavel_rounded, s.linksTopicLegal),
      (LifeTopic.insurance, Icons.health_and_safety_rounded, s.linksTopicInsurance),
      (LifeTopic.work, Icons.work_rounded, s.linksTopicWork),
      (LifeTopic.everyday, Icons.local_cafe_rounded, s.linksTopicEveryday),
      (LifeTopic.other, Icons.more_horiz_rounded, s.linksOther),
    ];
    LifeTopic topic(UsefulLink l) => l.life?.topic ?? LifeTopic.other;
    return [
      for (final (t, icon, title) in topics)
        if (_c.life.any((l) => topic(l) == t)) ...[
          _Label(icon: icon, text: title),
          _section(context, null, [
            for (final link in _c.life.where((l) => topic(l) == t)) _row(context, link, null),
          ]),
        ],
    ];
  }

  Widget _section(BuildContext context, String? title, List<Widget> rows) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) _Label(text: title),
          Material(
            color: p.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
            child: Column(
              children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) Divider(height: 1, indent: 66, color: p.hairline),
                  row,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, UsefulLink link, SavedLocation? place, {String highlight = ''}) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final km = LinksController.distanceKm(link, place);
    final city = LinksController.nearestCity(link, place);
    final subtitle = switch (link.kind) {
      LinkKind.job => link.region == LinkRegion.nationwide
          ? s.linksNationwide
          : city == null
              ? (link.handle ?? '')
              : '${city.name} · ${city.hangul}',
      LinkKind.life => link.handle ?? '',
      LinkKind.group => switch (link.group) {
          GroupFor.women => s.linksForWomen,
          GroupFor.ours => s.linksOurs,
          _ => s.linksForEveryone,
        },
    };
    final favorite = _c.isFavorite(link);
    return InkWell(
      onTap: () => _open(link),
      onLongPress: () => _menu(link),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            _Badge(link: link),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    _highlighted(link.title(_language), highlight, p),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (km != null) _Distance(km: km),
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _c.toggleFavorite(link);
              },
              tooltip: favorite ? s.linksUnfavorite : s.linksFavorite,
              icon: Icon(
                favorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: favorite ? Brand.gold500 : p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [text] with the part matching the search in bold.
  TextSpan _highlighted(String text, String query, VegukinPalette p) {
    final q = query.trim().toLowerCase();
    final at = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (at < 0) return TextSpan(text: text);
    return TextSpan(children: [
      TextSpan(text: text.substring(0, at)),
      TextSpan(
        text: text.substring(at, at + q.length),
        style: TextStyle(color: p.accent, fontWeight: FontWeight.w800),
      ),
      TextSpan(text: text.substring(at + q.length)),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle, required this.search});

  final String title;
  final String subtitle;
  final Widget search;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero.sublist(1)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: Brand.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(14, 2, 14, 16), child: search),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.hint, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: p.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.inkMuted),
          prefixIcon: Icon(Icons.search_rounded, color: p.inkMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: Icon(Icons.close_rounded, color: p.inkMuted),
                ),
          filled: true,
          fillColor: p.card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

/// Jobs, Korea life, groups.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.labels, required this.onChanged});

  final LinksTab tab;
  final List<String> labels;
  final ValueChanged<LinksTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return SegmentedButton<LinksTab>(
      segments: [
        for (final (i, t) in LinksTab.values.indexed)
          ButtonSegment(value: t, label: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
      selected: {tab},
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      onSelectionChanged: (v) => onChanged(v.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.action,
        selectedForegroundColor: Colors.white,
        foregroundColor: p.inkSoft,
        backgroundColor: p.card,
        side: BorderSide(color: p.hairline),
      ),
    );
  }
}

/// A section's heading.
class _Label extends StatelessWidget {
  const _Label({required this.text, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 17, color: color ?? p.gold), const SizedBox(width: 6)],
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: p.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// The link's picture: its topic for "Korea life", a briefcase or the
/// globe for job groups, people for groups; "bot" marked.
class _Badge extends StatelessWidget {
  const _Badge({required this.link, this.size = 40});

  final UsefulLink link;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final icon = switch (link.kind) {
      LinkKind.life => link.life?.icon ?? Icons.link_rounded,
      LinkKind.group => link.group == GroupFor.ours ? Icons.mosque_rounded : Icons.groups_rounded,
      LinkKind.job => link.region == LinkRegion.nationwide ? Icons.public_rounded : Icons.work_rounded,
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(size * 0.32)),
          child: Icon(icon, size: size * 0.5, color: p.accent),
        ),
        if (link.isBot)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, size: 14, color: Brand.gold500),
            ),
          ),
      ],
    );
  }
}

class _Distance extends StatelessWidget {
  const _Distance({required this.km});

  final double km;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final text = km < 1 ? '<1 km' : '${km < 100 ? km.round() : (km / 10).round() * 10} km';
    final near = km <= 50;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: near ? p.cardSelected : p.page,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: near ? p.accent : p.inkMuted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({required this.title, required this.onTap, required this.onLongPress});

  final String title;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      shape: StadiumBorder(side: BorderSide(color: Brand.gold400.withValues(alpha: 0.6))),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 17, color: Brand.gold500),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No place yet: one tap to find it, then the nearest groups come first.
class _LocateCard extends StatelessWidget {
  const _LocateCard({required this.busy, required this.onLocate});

  final bool busy;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: p.cardSelected,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.near_me_rounded, color: p.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(s.linksLocate, style: TextStyle(fontSize: 13.5, height: 1.35, color: p.inkSoft))),
          const SizedBox(width: 6),
          busy
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: p.accent),
                  ),
                )
              : TextButton(
                  onPressed: onLocate,
                  style: TextButton.styleFrom(foregroundColor: p.accent),
                  child: Text(s.linksLocateButton),
                ),
        ],
      ),
    );
  }
}

/// The web page's note: a missing group can be suggested in the bot's group.
class _Suggest extends StatelessWidget {
  const _Suggest({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: p.gold.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.gold.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.add_link_rounded, color: p.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.linksSuggestTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(s.linksSuggestBody, style: TextStyle(fontSize: 13, color: p.inkSoft)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
