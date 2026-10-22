import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'cars_kit.dart';
import 'cars_models.dart';
import 'cars_parts.dart';

/// Picks a make, then one of its models or all of them; [allowAny] adds
/// "any make". Null when dismissed; `(pick: null)` for any.
Future<({CarPick? pick})?> pickCar(BuildContext context, CarsKit kit, {bool allowAny = false}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<({CarPick? pick})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: VegukinPalette.of(context).page,
    builder: (_) => FractionallySizedBox(heightFactor: 0.88, child: _Picker(kit: kit, allowAny: allowAny)),
  );
}

class _Picker extends StatefulWidget {
  const _Picker({required this.kit, required this.allowAny});

  final CarsKit kit;
  final bool allowAny;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final _query = TextEditingController();
  CarBrand? _brand;

  @override
  void initState() {
    super.initState();
    widget.kit.loadCatalog();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(CarBrand? brand) {
    HapticFeedback.selectionClick();
    _query.clear();
    setState(() => _brand = brand);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final brand = _brand;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.kit, _query]),
      builder: (context, _) {
        final q = _query.text.trim().toLowerCase();
        final catalog = widget.kit.catalog;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              child: Row(
                children: [
                  if (brand != null)
                    IconButton(onPressed: () => _open(null), icon: const Icon(Icons.arrow_back_rounded), tooltip: MaterialLocalizations.of(context).backButtonTooltip)
                  else
                    const SizedBox(width: 8),
                  if (brand != null) ...[BrandLogo(brand.brand, size: 30), const SizedBox(width: 10)],
                  Expanded(
                    child: Text(brand?.brand ?? s.carPickBrand, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: s.carSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: p.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline)),
                ),
              ),
            ),
            Expanded(
              child: catalog == null
                  ? FutureBuilder(
                      future: widget.kit.loadCatalog(),
                      builder: (context, snap) => snap.connectionState == ConnectionState.done
                          ? CarsMessage(emoji: '⚠️', title: s.carCatalogFailed)
                          : const Center(child: CircularProgressIndicator()),
                    )
                  : brand == null
                      ? _brands(context, catalog, q)
                      : _models(context, brand, q),
            ),
          ],
        );
      },
    );
  }

  Widget _brands(BuildContext context, List<CarBrand> catalog, String q) {
    final s = AppLocalizations.of(context);
    final items = [for (final b in catalog) if (q.isEmpty || b.brand.toLowerCase().contains(q)) b];
    final any = widget.allowAny && q.isEmpty;
    if (items.isEmpty && !any) return CarsMessage(emoji: '🔍', title: s.carNothingFound);
    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.paddingOf(context).bottom),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: [
        if (any)
          _BrandTile(
            logo: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: VegukinPalette.of(context).accent, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.apps_rounded, color: Colors.white),
            ),
            name: s.carAnyBrand,
            count: s.carAllBrands,
            onTap: () => Navigator.pop(context, (pick: null)),
          ),
        for (final b in items)
          _BrandTile(
            logo: BrandLogo(b.brand, size: 46),
            name: b.brand,
            count: s.carBrandListings('${b.total}'),
            onTap: () => _open(b),
          ),
      ],
    );
  }

  Widget _models(BuildContext context, CarBrand brand, String q) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final items = [for (final m in brand.models) if (q.isEmpty || m.model.toLowerCase().contains(q)) m];
    Widget row(String name, int count, CarPick pick, {bool strong = false}) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: BrandLogo(brand.brand, size: 36),
          title: Text(name, style: TextStyle(fontSize: 15.5, fontWeight: strong ? FontWeight.w800 : FontWeight.w700, color: p.ink)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.carBrandListings('$count'), style: TextStyle(fontSize: 13, color: p.inkMuted)),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, (pick: pick));
          },
        );
    return ListView(
      padding: EdgeInsets.only(bottom: 16 + MediaQuery.paddingOf(context).bottom),
      children: [
        if (q.isEmpty) ...[
          row(s.carAllOf(brand.brand), brand.total, (brand: brand.brand, model: null), strong: true),
          Divider(height: 1, indent: 18, endIndent: 18, color: p.hairline),
        ],
        for (final m in items) row(m.model, m.count, (brand: brand.brand, model: m.model)),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.logo, required this.name, required this.count, required this.onTap});

  final Widget logo;
  final String name;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.hairline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logo,
              const SizedBox(height: 8),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.ink)),
              Text(count, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
