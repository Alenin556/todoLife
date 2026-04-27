import 'dart:math' as math;

import 'package:flutter/material.dart';

enum _PickerMode { hours, minutes }

/// A "reference-like" 12-hour time picker with:
/// - numeric inputs for hour/minute
/// - AM/PM toggle
/// - tappable clockface (hours / 5‑minute steps) in the active mode; mode follows focused field
/// - hand with arrowhead follows the values from inputs and taps
class RealisticTimePickerDialog extends StatefulWidget {
  const RealisticTimePickerDialog({
    super.key,
    required this.initial,
    this.minuteStep = 5,
  });

  final TimeOfDay initial;
  final int minuteStep;

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initial,
    int minuteStep = 5,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => RealisticTimePickerDialog(
        initial: initial,
        minuteStep: minuteStep,
      ),
    );
  }

  @override
  State<RealisticTimePickerDialog> createState() =>
      _RealisticTimePickerDialogState();
}

class _RealisticTimePickerDialogState extends State<RealisticTimePickerDialog> {
  late _PickerMode _mode;
  late bool _isPm;
  late int _hour12; // 1..12
  late int _minute; // 0..59

  late final TextEditingController _hCtrl;
  late final TextEditingController _mCtrl;

  final _hFocus = FocusNode();
  final _mFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _mode = _PickerMode.hours;

    final init = widget.initial;
    _isPm = init.hour >= 12;
    _hour12 = init.hour % 12;
    if (_hour12 == 0) _hour12 = 12;
    _minute = init.minute.clamp(0, 59);
    _minute = _roundToStep(_minute, widget.minuteStep);

    _hCtrl = TextEditingController(text: _pad2(_hour12));
    _mCtrl = TextEditingController(text: _pad2(_minute));

    _hFocus.addListener(() {
      if (_hFocus.hasFocus) setState(() => _mode = _PickerMode.hours);
      if (!_hFocus.hasFocus) _syncTextFromState();
    });
    _mFocus.addListener(() {
      if (_mFocus.hasFocus) setState(() => _mode = _PickerMode.minutes);
      if (!_mFocus.hasFocus) _syncTextFromState();
    });
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _mCtrl.dispose();
    _hFocus.dispose();
    _mFocus.dispose();
    super.dispose();
  }

  int _roundToStep(int v, int step) {
    if (step <= 1) return v.clamp(0, 59);
    final nearest = (v / step).round() * step;
    return nearest.clamp(0, 59);
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  void _syncTextFromState() {
    _hCtrl.text = _pad2(_hour12);
    _mCtrl.text = _pad2(_minute);
  }

  void _onHourTextChanged(String raw) {
    final v = int.tryParse(raw);
    if (v == null) return;
    if (v < 1 || v > 12) return;
    setState(() => _hour12 = v);
  }

  void _onMinuteTextChanged(String raw) {
    final v = int.tryParse(raw);
    if (v == null) return;
    if (v < 0 || v > 59) return;
    setState(() => _minute = v);
  }

  TimeOfDay _currentTimeOfDay() {
    var h24 = _hour12 % 12;
    if (_isPm) h24 += 12;
    final mm = _roundToStep(_minute, widget.minuteStep);
    return TimeOfDay(hour: h24, minute: mm);
  }

  void _accept() {
    final tod = _currentTimeOfDay();
    Navigator.of(context).pop(tod);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _onClockValueSelected(int v) {
    setState(() {
      if (_mode == _PickerMode.hours) {
        _hour12 = v.clamp(1, 12);
        _hCtrl.text = _pad2(_hour12);
        _hCtrl.selection =
            TextSelection.collapsed(offset: _hCtrl.text.length);
        _mFocus.requestFocus();
      } else {
        _minute = v.clamp(0, 59);
        _minute = _roundToStep(_minute, widget.minuteStep);
        _mCtrl.text = _pad2(_minute);
        _mCtrl.selection =
            TextSelection.collapsed(offset: _mCtrl.text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final surface = t.colorScheme.surface;
    final onSurface = t.colorScheme.onSurface;
    final primary = t.colorScheme.primary;

    final hourSelected = _mode == _PickerMode.hours;
    final minuteSelected = _mode == _PickerMode.minutes;

    final preview = _currentTimeOfDay();
    final previewText =
        '${preview.hour.toString().padLeft(2, '0')}:${preview.minute.toString().padLeft(2, '0')}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _cancel,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Выберите время',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeBox(
                    selected: hourSelected,
                    child: TextField(
                      controller: _hCtrl,
                      focusNode: _hFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: _onHourTextChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      ':',
                      style: t.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  _TimeBox(
                    selected: minuteSelected,
                    child: TextField(
                      controller: _mCtrl,
                      focusNode: _mFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: _onMinuteTextChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AmPmToggle(
                    isPm: _isPm,
                    onChanged: (v) => setState(() => _isPm = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                previewText,
                style: t.textTheme.bodySmall?.copyWith(
                  letterSpacing: 2.0,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: _ClockFace(
                  mode: _mode,
                  hour12: _hour12,
                  minute: _roundToStep(_minute, widget.minuteStep),
                  minuteStep: widget.minuteStep,
                  primary: primary,
                  onSurface: onSurface,
                  surface: surface,
                  onSelect: _onClockValueSelected,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _cancel, child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _accept, child: const Text('ОК')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bg = selected
        ? t.colorScheme.primary.withValues(alpha: 0.12)
        : t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    return Container(
      width: 82,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  const _AmPmToggle({required this.isPm, required this.onChanged});

  final bool isPm;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmPmButton(
            label: 'AM',
            selected: !isPm,
            onTap: () => onChanged(false),
          ),
          _AmPmButton(
            label: 'PM',
            selected: isPm,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _AmPmButton extends StatelessWidget {
  const _AmPmButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bg = selected ? t.colorScheme.primary.withValues(alpha: 0.12) : null;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected
                ? t.colorScheme.primary
                : t.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _ClockFace extends StatelessWidget {
  const _ClockFace({
    required this.mode,
    required this.hour12,
    required this.minute,
    required this.minuteStep,
    required this.primary,
    required this.onSurface,
    required this.surface,
    required this.onSelect,
  });

  final _PickerMode mode;
  final int hour12;
  final int minute;
  final int minuteStep;
  final Color primary;
  final Color onSurface;
  final Color surface;
  final ValueChanged<int> onSelect;

  List<int> _minuteMarks() {
    final step = minuteStep <= 0 ? 5 : minuteStep;
    final list = <int>[];
    for (int m = 0; m < 60; m += step) {
      list.add(m);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final p = box.globalToLocal(d.globalPosition);
            final size = box.size;
            final center = Offset(size.width / 2, size.height / 2);
            final dx = p.dx - center.dx;
            final dy = p.dy - center.dy;
            final dist = math.sqrt(dx * dx + dy * dy);
            final radius = math.min(size.width, size.height) * 0.42;
            if (dist < radius * 0.55 || dist > radius * 1.2) return;

            // Angle: 12 o'clock = -pi/2, clockwise increases.
            var ang = math.atan2(dy, dx);
            ang = ang - (-math.pi / 2);
            while (ang < 0) {
              ang += math.pi * 2;
            }
            while (ang >= math.pi * 2) {
              ang -= math.pi * 2;
            }

            if (mode == _PickerMode.hours) {
              final idx = ((ang / (math.pi * 2)) * 12).round() % 12;
              final h = idx == 0 ? 12 : idx;
              onSelect(h);
            } else {
              final marks = _minuteMarks();
              final steps = marks.length;
              final idx = ((ang / (math.pi * 2)) * steps).round() % steps;
              onSelect(marks[idx]);
            }
          },
          child: CustomPaint(
            painter: _ClockPainter(
              mode: mode,
              hour12: hour12,
              minute: minute,
              minuteStep: minuteStep,
              primary: primary,
              onSurface: onSurface,
              surface: surface,
            ),
          ),
        );
      },
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.mode,
    required this.hour12,
    required this.minute,
    required this.minuteStep,
    required this.primary,
    required this.onSurface,
    required this.surface,
  });

  final _PickerMode mode;
  final int hour12;
  final int minute;
  final int minuteStep;
  final Color primary;
  final Color onSurface;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    final bgPaint = Paint()
      ..color = surface.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = onSurface.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Labels
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    List<String> labels;
    if (mode == _PickerMode.hours) {
      labels = List.generate(12, (i) => '${i == 0 ? 12 : i}');
    } else {
      final step = minuteStep <= 0 ? 5 : minuteStep;
      labels = List.generate(60 ~/ step, (i) => (i * step).toString().padLeft(2, '0'));
    }

    final count = labels.length;
    for (int i = 0; i < count; i++) {
      final ang = (i / count) * math.pi * 2 - math.pi / 2;
      final p = Offset(
        center.dx + math.cos(ang) * radius * 0.82,
        center.dy + math.sin(ang) * radius * 0.82,
      );
      final isSelected = mode == _PickerMode.hours
          ? (labels[i] == '$hour12')
          : (labels[i] == minute.toString().padLeft(2, '0'));

      final style = TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? primary : onSurface.withValues(alpha: 0.78),
      );
      textPainter.text = TextSpan(text: labels[i], style: style);
      textPainter.layout();
      final off = Offset(p.dx - textPainter.width / 2, p.dy - textPainter.height / 2);
      textPainter.paint(canvas, off);
    }

    // Hand: shaft + filled arrowhead at the tip
    final angle = mode == _PickerMode.hours
        ? ((hour12 % 12) + (minute / 60.0)) * (math.pi * 2 / 12) - math.pi / 2
        : (minute / 60.0) * (math.pi * 2) - math.pi / 2;

    final ux = math.cos(angle);
    final uy = math.sin(angle);
    final handLen = radius * 0.62;
    final arrowLen = (radius * 0.10).clamp(7.0, 14.0);
    final baseMid = Offset(
      center.dx + ux * (handLen - arrowLen),
      center.dy + uy * (handLen - arrowLen),
    );
    final tip = Offset(
      center.dx + ux * handLen,
      center.dy + uy * handLen,
    );
    final perp = Offset(-uy, ux);
    final halfW = arrowLen * 0.48;
    final b1 = baseMid + perp * halfW;
    final b2 = baseMid - perp * halfW;

    final handPaint = Paint()
      ..color = primary
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, baseMid, handPaint);

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();
    final fillPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);

    // Hub + rim for a more clock-like look
    final hubR = 6.0;
    final hubRim = Paint()
      ..color = primary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, hubR + 0.5, hubRim);
    final dotPaint = Paint()..color = primary;
    canvas.drawCircle(center, hubR, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.hour12 != hour12 ||
        oldDelegate.minute != minute ||
        oldDelegate.minuteStep != minuteStep ||
        oldDelegate.primary != primary ||
        oldDelegate.onSurface != onSurface ||
        oldDelegate.surface != surface;
  }
}

