import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_controller.dart';
import '../prayers/prayer_timeline.dart' show reminderIcon;
import 'reminder_controller.dart';
import 'reminders.dart';

/// One time's reminder: how it arrives, and when — on time, or minutes
/// before or after, never past the next time. Changes apply as they are
/// made.
Future<void> showReminderSheet(
  BuildContext context, {
  required ReminderSlot slot,
  required ReminderController reminders,
  required PrayerController prayer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: VegukinPalette.of(context).card,
    builder: (context) => _ReminderSheet(slot: slot, reminders: reminders, prayer: prayer),
  );
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.slot, required this.reminders, required this.prayer});

  final ReminderSlot slot;
  final ReminderController reminders;
  final PrayerController prayer;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late Reminder _draft = widget.reminders.settings[widget.slot];

  /// Today's window, for the times shown and the slider's ends.
  SlotWindow? get _window {
    final days = widget.prayer.days;
    final today = widget.prayer.day;
    if (today == null) return null;
    final i = days.indexWhere((d) => d.key == today.key);
    final next = i >= 0 && i + 1 < days.length ? days[i + 1] : null;
    return slotWindow(today, widget.slot, nextDay: next);
  }

  void _set(Reminder value, {bool save = true}) {
    setState(() => _draft = value);
    if (save) widget.reminders.set(widget.slot, value);
  }

  void _pickMode(ReminderMode mode) {
    HapticFeedback.selectionClick();
    _set(_draft.copyWith(mode: mode));
    if (mode == ReminderMode.sound || mode == ReminderMode.vibrate) {
      widget.reminders.preview(mode);
    }
  }

  void _setOffset(int offset, {bool save = true}) {
    final range = _window?.range ?? (before: 60, after: 60);
    final value = offset.clamp(-range.before, range.after);
    if ((value == 0) != (_draft.offset == 0)) HapticFeedback.selectionClick();
    _set(_draft.copyWith(offset: value), save: save);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final window = _window;
    final range = window?.range ?? (before: 60, after: 60);
    final on = _draft.isOn;
    final offset = _draft.offset.clamp(-range.before, range.after);

    return ListenableBuilder(
      listenable: widget.reminders,
      builder: (context, _) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.cardSelected,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(reminderIcon(_draft.mode), color: p.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slotName(s, widget.slot),
                          style: TextStyle(
                            fontFamily: Brand.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: p.ink,
                          ),
                        ),
                        if (window != null)
                          Text(
                            s.reminderToday('${hhmm(window.start)} – ${hhmm(window.end)}'),
                            style: TextStyle(
                              fontSize: 13,
                              color: p.inkMuted,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!widget.reminders.notificationsAllowed) ...[
                const SizedBox(height: 14),
                _Blocked(onTurnOn: widget.reminders.openNotificationSettings),
              ],
              _Section(s.reminderHow),
              Row(
                children: [
                  Expanded(child: _modeTile(ReminderMode.off)),
                  const SizedBox(width: 10),
                  Expanded(child: _modeTile(ReminderMode.silent)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _modeTile(ReminderMode.vibrate)),
                  const SizedBox(width: 10),
                  Expanded(child: _modeTile(ReminderMode.sound)),
                ],
              ),
              _Section(s.reminderWhen),
              AnimatedOpacity(
                opacity: on ? 1 : 0.38,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !on,
                  child: _When(
                    offset: offset,
                    range: range,
                    at: window?.at(offset),
                    onChanged: (v) => _setOffset(v, save: false),
                    onChangeEnd: _setOffset,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.reminderDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTile(ReminderMode mode) {
    final s = AppLocalizations.of(context);
    final (String name, String hint) = switch (mode) {
      ReminderMode.off => (s.reminderOff, s.reminderOffHint),
      ReminderMode.silent => (s.reminderSilent, s.reminderSilentHint),
      ReminderMode.vibrate => (s.reminderVibrate, s.reminderVibrateHint),
      ReminderMode.sound => (s.reminderSound, s.reminderSoundHint),
    };
    return _ModeTile(
      icon: reminderIcon(mode),
      name: name,
      hint: hint,
      selected: _draft.mode == mode,
      onTap: () => _pickMode(mode),
      onPlay: mode == ReminderMode.sound ? () => widget.reminders.preview(mode) : null,
      playLabel: s.reminderPlay,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 0, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: p.inkMuted),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.name,
    required this.hint,
    required this.selected,
    required this.onTap,
    required this.playLabel,
    this.onPlay,
  });

  final IconData icon;
  final String name;
  final String hint;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final String playLabel;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.cardSelected : p.page,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? p.accent : p.hairline, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected ? p.action : p.card,
                        shape: BoxShape.circle,
                        border: selected ? null : Border.all(color: p.hairline),
                      ),
                      child: Icon(icon, size: 19, color: selected ? Colors.white : p.inkSoft),
                    ),
                    const Spacer(),
                    if (onPlay != null)
                      IconButton(
                        onPressed: onPlay,
                        tooltip: playLabel,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.play_circle_fill_rounded, color: p.accent, size: 30),
                      )
                    else if (selected)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.check_circle_rounded, color: p.accent, size: 22),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink)),
                const SizedBox(height: 1),
                Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The reminder's moment: today's time large, nudged a minute at a time,
/// dragged along the window, or picked from the usual choices.
class _When extends StatelessWidget {
  const _When({
    required this.offset,
    required this.range,
    required this.at,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int offset;
  final ({int before, int after}) range;
  final DateTime? at;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final min = -range.before;
    final max = range.after;
    const presets = [-15, -5, 0, 10, 30];

    Widget nudge(IconData icon, int by) => IconButton.filledTonal(
          onPressed: (offset + by < min || offset + by > max) ? null : () => onChangeEnd(offset + by),
          style: IconButton.styleFrom(backgroundColor: p.card, foregroundColor: p.accent),
          icon: Icon(icon),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: p.page,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.hairline),
          ),
          child: Row(
            children: [
              nudge(Icons.remove_rounded, -1),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      s.reminderAt,
                      style: TextStyle(fontSize: 11.5, color: p.inkMuted),
                    ),
                    Text(
                      at == null ? '--:--' : hhmm(at!),
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      offsetText(s, offset),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.inkSoft),
                    ),
                  ],
                ),
              ),
              nudge(Icons.add_rounded, 1),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (max > min)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: p.accent,
              inactiveTrackColor: p.hairline,
              thumbColor: p.accent,
              overlayColor: p.accent.withValues(alpha: 0.12),
              trackHeight: 4,
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Where "on time" sits on the track.
                if (min < 0)
                  Positioned.fill(
                    child: Padding(
                      // The slider's own inset to the track's ends.
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment(-1 + 2 * (-min / (max - min)), 0),
                        child: Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: p.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                Slider(
                  value: offset.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  onChanged: (v) => onChanged(v.round()),
                  onChangeEnd: (v) => onChangeEnd(v.round()),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Text(
                min < 0 ? offsetText(s, min) : s.offsetOnTime,
                style: TextStyle(fontSize: 11, color: p.inkMuted),
              ),
              const Spacer(),
              Text(
                offsetText(s, max),
                style: TextStyle(fontSize: 11, color: p.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in presets)
              if (preset >= min && preset <= max)
                ChoiceChip(
                  label: Text(offsetText(s, preset)),
                  selected: offset == preset,
                  showCheckmark: false,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onChangeEnd(preset);
                  },
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: offset == preset ? Colors.white : p.inkSoft,
                  ),
                  selectedColor: p.action,
                  backgroundColor: p.page,
                  side: BorderSide(color: offset == preset ? p.action : p.hairline),
                  shape: const StadiumBorder(),
                ),
          ],
        ),
      ],
    );
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: p.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_rounded, size: 20, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(s.notificationsOff, style: TextStyle(fontSize: 13, color: p.ink))),
          TextButton(
            onPressed: onTurnOn,
            style: TextButton.styleFrom(foregroundColor: p.accent),
            child: Text(s.notificationsTurnOn),
          ),
        ],
      ),
    );
  }
}
