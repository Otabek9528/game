import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'hikorea_kit.dart';
import 'hikorea_models.dart';
import 'hikorea_parts.dart';
import 'hikorea_screen.dart';
import 'hikorea_source.dart';
import 'hikorea_text.dart';

/// Which office serves a home address: the province, then the address in
/// Korean; the server matches its city or district (-시, -구, -군).
class HkAddressScreen extends StatefulWidget {
  const HkAddressScreen({super.key, required this.kit});

  final HikoreaKit kit;

  @override
  State<HkAddressScreen> createState() => _HkAddressScreenState();
}

class _HkAddressScreenState extends State<HkAddressScreen> {
  final _address = TextEditingController();
  List<String>? _provinces;
  String? _province;
  bool _busy = false;
  List<HkMatch>? _matches;

  HikoreaKit get _kit => widget.kit;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProvinces());
    if (_kit.offices == null) unawaited(_kit.loadOffices().then((_) {}, onError: (Object _) {}));
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await _kit.source.provinces();
      if (mounted) setState(() => _provinces = provinces);
    } on HkException {
      // Fall back to the provinces the app knows.
      if (mounted) setState(() => _provinces = provincesInEnglish.keys.toList());
    }
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  Future<void> _find() async {
    final s = AppLocalizations.of(context);
    final province = _province;
    final address = _address.text.trim();
    if (province == null) return _say(s.hkNeedProvince);
    if (address.isEmpty) return _say(s.hkNeedAddress);
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final matches = await _kit.source.resolve(province, address);
      if (mounted) setState(() => _matches = matches);
    } on HkException {
      if (mounted) _say(s.hkLoadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final provinces = _provinces;
    final matches = _matches;
    Widget label(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
          child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
        );
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(title: Text(s.hkAddressTitle), backgroundColor: p.page, surfaceTintColor: Colors.transparent),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
        children: [
          Text(s.hkAddressLede, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          label(s.hkProvince),
          if (provinces == null)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ko in provinces)
                  ChoiceChip(
                    label: Text(
                      [ko, ?provincesInEnglish[ko]].join(' · '),
                    ),
                    selected: _province == ko,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _province = ko);
                    },
                  ),
              ],
            ),
          label(s.hkAddress),
          TextField(
            controller: _address,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _find(),
            decoration: InputDecoration(
              hintText: '예: 경기도 안산시 단원구 원곡동 123',
              helperText: s.hkAddressHint,
              helperMaxLines: 3,
              filled: true,
              fillColor: p.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _find,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.search_rounded),
            label: Text(s.hkFindOffice),
          ),
          if (matches != null) ...[
            const SizedBox(height: 22),
            if (matches.isEmpty)
              HkCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: p.inkMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.hkAddressNoMatch, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft))),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                child: Text(
                  matches.length == 1 ? s.hkYourOffice : s.hkPickOne,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink),
                ),
              ),
              for (final m in matches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OfficeRow(
                    kit: _kit,
                    office: _kit.officeOf(m.officeId) ?? HkOffice(id: m.officeId, nameEn: m.nameEn, nameKo: m.nameKo),
                    subtitle: [if (m.nameKo case final ko? when ko.isNotEmpty) ko, if (m.district.isNotEmpty) m.district]
                        .join(' · '),
                    onTap: () {
                      final office = _kit.officeOf(m.officeId);
                      if (office != null) openOffice(context, _kit, office);
                    },
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
