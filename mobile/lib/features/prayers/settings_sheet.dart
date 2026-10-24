import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/prayer_controller.dart';
import '../prayer/prayer_models.dart';

/// Aladhan's method codes, in the web page's order.
const methodCodes = ['3', '1', '4', '5', '2'];

String methodName(AppLocalizations s, String code) => switch (code) {
      '1' => s.methodKarachi,
      '4' => s.methodMakkah,
      '5' => s.methodEgypt,
      '2' => s.methodIsna,
      _ => s.methodMwl,
    };

/// For the header pill, where "Muslim World League" doesn't fit.
String methodShort(AppLocalizations s, String code) => code == '3' ? 'MWL' : methodName(s, code);

String methodHint(AppLocalizations s, String code) => switch (code) {
      '1' => s.methodKarachiHint,
      '4' => s.methodMakkahHint,
      '5' => s.methodEgyptHint,
      '2' => s.methodIsnaHint,
      _ => s.methodMwlHint,
    };

/// Calculation method and Asr school, as in the web page's sheet. A choice
/// applies at once and the sheet closes a moment later.
Future<void> showSettingsSheet(BuildContext context, PrayerController prayer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: VegukinPalette.of(context).card,
    builder: (context) => _SettingsSheet(prayer: prayer),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.prayer});

  final PrayerController prayer;

  void _apply(BuildContext context, PrayerSettings value) {
    if (value == prayer.settings) {
      Navigator.pop(context);
      return;
    }
    HapticFeedback.selectionClick();
    prayer.applySettings(value);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (context.mounted) Navigator.maybePop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return ListenableBuilder(
      listenable: prayer,
      builder: (context, _) {
        final current = prayer.settings;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 20 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.settingsTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 4),
                Text(s.settingsSubtitle, style: TextStyle(fontSize: 13, color: p.inkSoft)),
                const SizedBox(height: 14),
                Divider(height: 1, color: p.hairline),
                _Label(icon: Icons.tune_rounded, text: s.methodLabel),
                for (final code in methodCodes)
                  _Option(
                    name: methodName(s, code),
                    hint: methodHint(s, code),
                    selected: current.method == code,
                    onTap: () => _apply(context, PrayerSettings(method: code, madhab: current.madhab)),
                  ),
                _Label(icon: Icons.mosque_outlined, text: s.madhabLabel),
                _Option(
                  name: s.schoolHanafi,
                  hint: s.hanafiNote,
                  selected: current.madhab == '1',
                  onTap: () => _apply(context, PrayerSettings(method: current.method, madhab: '1')),
                ),
                _Option(
                  name: s.schoolShafii,
                  hint: s.shafiiNote,
                  selected: current.madhab == '0',
                  onTap: () => _apply(context, PrayerSettings(method: current.method, madhab: '0')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: p.inkSoft),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.inkSoft)),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.name, required this.hint, required this.selected, required this.onTap});

  final String name;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? p.cardSelected : p.page,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? p.accent : p.hairline, width: selected ? 1.4 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.ink)),
                      const SizedBox(height: 2),
                      Text(hint, style: TextStyle(fontSize: 12, color: p.inkMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? p.accent : p.hairlineStrong,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
