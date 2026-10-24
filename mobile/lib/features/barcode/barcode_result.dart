import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../support/support_parts.dart';
import 'barcode_controller.dart';
import 'barcode_models.dart';
import 'barcode_parts.dart';

/// The web page's article on doubtful products.
final doubtfulArticle = Uri.parse('https://telegra.ph/Koreyada-non-halol-emasmi-04-20');

/// The check of a scanned or typed code, over the paused camera: "checking",
/// then the product, "not found" or "no connection". Returns when closed.
Future<void> showLookupSheet(BuildContext context, AppServices services, BarcodeController checks) =>
    _showSheet(
      context,
      (context, scroll) => ListenableBuilder(
        listenable: checks,
        builder: (context, _) => switch (checks.lookup) {
          Found(:final product, :final saved) =>
            ProductView(product: product, services: services, scroll: scroll, saved: saved, onNext: () => Navigator.pop(context)),
          NotFound(:final code) => _NotFoundView(code: code, scroll: scroll),
          Offline(:final code) => _OfflineView(code: code, scroll: scroll, onRetry: () => checks.check(code)),
          Checking(:final code) => _CheckingView(code: code, scroll: scroll),
          null => const SizedBox.shrink(),
        },
      ),
    );

/// A product from a store's list.
Future<void> showProductSheet(BuildContext context, AppServices services, Product product) => _showSheet(
      context,
      (context, scroll) => ProductView(product: product, services: services, scroll: scroll),
    );

Future<void> _showSheet(BuildContext context, Widget Function(BuildContext, ScrollController) builder) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: VegukinPalette.of(context).card,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 1,
        snap: true,
        builder: builder,
      ),
    );

/// Everything known about a product: the verdict first, big, in its colour.
class ProductView extends StatefulWidget {
  const ProductView({
    super.key,
    required this.product,
    required this.services,
    required this.scroll,
    this.saved = false,
    this.onNext,
  });

  final Product product;
  final AppServices services;
  final ScrollController scroll;

  /// From the phone's history, the server being out of reach.
  final bool saved;

  /// Back to the camera; null when browsing a store.
  final VoidCallback? onNext;

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  bool _ingredients = false;

  Product get _product => widget.product;

  void _openPhoto() {
    final url = _product.imageUrl;
    if (url == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _PhotoScreen(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final verdict = VerdictStyle.of(context, _product.verdict);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final next = widget.onNext;
    final list = ListView(
      controller: widget.scroll,
      padding: EdgeInsets.fromLTRB(18, 0, 18, next == null ? 20 + bottom : 16),
      children: [
        if (widget.saved) ...[
          _Note(icon: Icons.cloud_off_rounded, text: s.barcodeSaved, color: p.inkMuted),
          const SizedBox(height: 10),
        ],
        // The answer.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: verdict.solid, borderRadius: BorderRadius.circular(22)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(verdict.icon, color: Colors.white, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VerdictStyle.label(s, _product.verdict),
                      style: const TextStyle(fontSize: 24, height: 1.15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      VerdictStyle.description(s, _product.verdict),
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // The product.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _openPhoto,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_product.imageUrl case final url?)
                        Hero(tag: '$url', child: ProductPhoto(_product))
                      else
                        ProductPhoto(_product),
                      // Opens full screen.
                      if (_product.imageUrl != null)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                            child: const Icon(Icons.zoom_out_map_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                  if (_product.name != null && _product.nameEnglish != null && _product.name != _product.nameEnglish)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _product.nameEnglish!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: p.inkMuted),
                      ),
                    ),
                  const SizedBox(height: 6),
                  CodeChip(code: _product.barcode),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _WhereFound(product: _product),
        const SizedBox(height: 14),
        // Pork, alcohol, other meat, seafood.
        _ChecksGrid(product: _product),
        if (_product.ambiguous) ...[
          const SizedBox(height: 10),
          _Note(icon: Icons.science_rounded, text: s.barcodeAmbiguous, color: VerdictStyle.of(context, Verdict.shubhali).color),
        ],
        if (_product.sameFactory case final same?) ...[
          const SizedBox(height: 10),
          _Note(
            icon: same ? Icons.factory_rounded : Icons.verified_rounded,
            text: same ? s.barcodeFactoryWarn : s.barcodeFactoryOk,
            color: VerdictStyle.of(context, same ? Verdict.shubhali : Verdict.joiz).color,
          ),
        ],
        if (_product.hasIngredients) ...[
          const SizedBox(height: 12),
          _Ingredients(
            text: _product.ingredients!,
            open: _ingredients,
            onToggle: () => setState(() => _ingredients = !_ingredients),
          ),
        ],
        if (_product.verdict == Verdict.shubhali) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => widget.services.openLink(doubtfulArticle),
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              label: Text(s.barcodeDoubtfulLink),
            ),
          ),
        ],
      ],
    );
    if (next == null) return list;
    return Column(
      children: [
        Expanded(child: list),
        _NextBar(onNext: next),
      ],
    );
  }
}

/// The way back to the camera, always in reach under a long sheet.
class _NextBar extends StatelessWidget {
  const _NextBar({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.hairline))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + MediaQuery.paddingOf(context).bottom),
        child: FilledButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text(s.barcodeScanNext),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ),
    );
  }
}

/// The code, in figures, with a copy button.
class CodeChip extends StatelessWidget {
  const CodeChip({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: p.cardSelected,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => copyWithNote(context, code, s.barcodeCopied),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.barcode_reader, size: 16, color: p.inkMuted),
              const SizedBox(width: 6),
              Text(
                code,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: p.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(message: s.barcodeCopyCode, child: Icon(Icons.copy_rounded, size: 16, color: p.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which store's list it was checked in, and where else it is sold.
class _WhereFound extends StatelessWidget {
  const _WhereFound({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final store = product.store;
    final inStore = product.source == 'store_products' && store != null;
    final general = !inStore && product.source == 'general';
    if (!inStore && !general && product.otherStores.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.page, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inStore)
            Row(
              children: [
                StoreEmblem(store, height: 32, maxWidth: 84),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${s.barcodeFoundIn} '),
                      TextSpan(text: store, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    style: TextStyle(fontSize: 14, color: p.ink),
                  ),
                ),
              ],
            )
          else if (general)
            Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 22, color: p.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${s.barcodeGeneralDb} · ${s.barcodeStoreUnknown}',
                    style: TextStyle(fontSize: 13.5, color: p.inkSoft),
                  ),
                ),
              ],
            ),
          if (product.otherStores.isNotEmpty) ...[
            if (inStore || general) const SizedBox(height: 10),
            Text(s.barcodeAlsoAt, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final other in product.otherStores)
                  Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StoreEmblem(other, height: 24, maxWidth: 62),
                        const SizedBox(width: 6),
                        Text(other, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.ink)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecksGrid extends StatelessWidget {
  const _ChecksGrid({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final checks = [
      ('🐖', s.barcodePork, product.pork),
      ('🍷', s.barcodeAlcohol, product.alcohol),
      ('🍗', s.barcodeMeat, product.meat),
      ('🦐', s.barcodeSeafood, product.seafood),
    ];
    Widget tile((String, String, bool) check) {
      final (emoji, label, present) = check;
      final color = VerdictStyle.of(context, present ? Verdict.nojoiz : Verdict.joiz).color;
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VegukinPalette.of(context).ink),
                  ),
                  Row(
                    children: [
                      Icon(present ? Icons.close_rounded : Icons.check_rounded, size: 15, color: color),
                      const SizedBox(width: 3),
                      Text(
                        present ? s.barcodePresent : s.barcodeAbsent,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget row(int first) => Row(
          children: [
            Expanded(child: tile(checks[first])),
            const SizedBox(width: 8),
            Expanded(child: tile(checks[first + 1])),
          ],
        );
    return Column(children: [row(0), const SizedBox(height: 8), row(2)]);
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: VegukinPalette.of(context).inkSoft)),
            ),
          ],
        ),
      );
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.text, required this.open, required this.onToggle});

  final String text;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      decoration: BoxDecoration(color: p.page, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, size: 20, color: p.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.barcodeIngredients, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: SelectableText(text, style: TextStyle(fontSize: 13.5, height: 1.55, color: p.inkSoft)),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A round icon over a title, a code and a line: "checking", "not found",
/// "no connection".
class _StateHead extends StatelessWidget {
  const _StateHead({required this.icon, required this.title, required this.code, this.body});

  final Widget icon;
  final String title;
  final String code;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 8),
        CodeChip(code: code),
        if (body case final body?) ...[
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
        ],
      ],
    );
  }
}

class _CheckingView extends StatelessWidget {
  const _CheckingView({required this.code, required this.scroll});

  final String code;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) => _Centred(
        scroll: scroll,
        children: [
          _StateHead(
            icon: const SizedBox.square(dimension: 34, child: CircularProgressIndicator(strokeWidth: 3)),
            title: AppLocalizations.of(context).barcodeChecking,
            code: code,
          ),
        ],
      );
}

/// [children] in the middle of the sheet, scrolling if they outgrow it.
class _Centred extends StatelessWidget {
  const _Centred({required this.scroll, required this.children});

  final ScrollController scroll;
  final List<Widget> children;

  static const _padding = EdgeInsets.fromLTRB(20, 0, 20, 24);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          controller: scroll,
          padding: _padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (constraints.maxHeight - _padding.vertical).clamp(0, double.infinity)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
}

/// As on the web page: not in the database yet, and the way back to the
/// camera.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.code, required this.scroll});

  final String code;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Column(
      children: [
        Expanded(
          child: _Centred(
            scroll: scroll,
            children: [
              _StateHead(
                icon: Icon(Icons.search_off_rounded, size: 36, color: p.inkMuted),
                title: s.barcodeNotFound,
                code: code,
                body: s.barcodeNotFoundDesc,
              ),
            ],
          ),
        ),
        _NextBar(onNext: () => Navigator.pop(context)),
      ],
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.code, required this.scroll, required this.onRetry});

  final String code;
  final ScrollController scroll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return _Centred(
      scroll: scroll,
      children: [
        _StateHead(
          icon: Icon(Icons.wifi_off_rounded, size: 34, color: p.inkMuted),
          title: s.barcodeOfflineTitle,
          code: code,
          body: s.barcodeOfflineBody,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(s.barcodeRetry),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}

/// The photo, full screen, to read the small print: pinch to zoom.
class _PhotoScreen extends StatelessWidget {
  const _PhotoScreen({required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: Colors.black,
          // Expand: a stack sizes itself to its loose children otherwise, and
          // the photo was squeezed into the close button's corner.
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                maxScale: 5,
                child: Hero(
                  tag: '$url',
                  child: NetworkPhoto(
                    url,
                    size: PhotoSize.full,
                    fit: BoxFit.contain,
                    // The card's photo, already loaded: shown at once, and
                    // sharpened when the full one arrives.
                    loading: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetworkPhoto(
                          url,
                          size: PhotoSize.card,
                          fit: BoxFit.contain,
                          placeholder: const SizedBox.expand(),
                        ),
                        const Align(
                          alignment: Alignment(0, 0.9),
                          child: SizedBox.square(
                            dimension: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    placeholder: const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54)),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Asks for a code typed by hand; null when closed.
Future<String?> askForCode(BuildContext context) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: VegukinPalette.of(context).card,
      builder: (context) => const _TypeCodeSheet(),
    );

class _TypeCodeSheet extends StatefulWidget {
  const _TypeCodeSheet();

  @override
  State<_TypeCodeSheet> createState() => _TypeCodeSheetState();
}

class _TypeCodeSheetState extends State<_TypeCodeSheet> {
  final _text = TextEditingController();
  CodeProblem? _problem;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final problem = checkTypedCode(_text.text);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    Navigator.pop(context, _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final code = _text.text;
    final complete = checkTypedCode(code) == null && (code.length == 8 || code.length == 12 || code.length == 13);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.barcodeTypeTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(height: 4),
          Text(s.barcodeTypeHint, style: TextStyle(fontSize: 13.5, color: p.inkSoft)),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
            onChanged: (_) => setState(() => _problem = null),
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: p.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: '8801234567890',
              prefixIcon: const Icon(Icons.barcode_reader),
              suffixIcon: complete ? Icon(Icons.check_circle_rounded, color: VerdictStyle.of(context, Verdict.joiz).color) : null,
              errorText: switch (_problem) {
                CodeProblem.empty => s.barcodeErrEmpty,
                CodeProblem.nonDigit => s.barcodeErrNonDigit,
                CodeProblem.length => s.barcodeErrLength,
                CodeProblem.checksum => s.barcodeErrChecksum,
                null => null,
              },
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.search_rounded),
            label: Text(s.barcodeSearch),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
