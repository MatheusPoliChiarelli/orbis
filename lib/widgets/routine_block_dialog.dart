import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/routine_block.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';

Future<void> showRoutineBlockDialog({
  required BuildContext context,
  required DayType dayType,
  RoutineBlock? existing,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => RoutineBlockDialog(
      dayType: dayType,
      existing: existing,
    ),
  );
}

class RoutineBlockDialog extends StatefulWidget {
  const RoutineBlockDialog({
    super.key,
    required this.dayType,
    this.existing,
  });

  final DayType dayType;
  final RoutineBlock? existing;

  @override
  State<RoutineBlockDialog> createState() => _RoutineBlockDialogState();
}

class _RoutineBlockDialogState extends State<RoutineBlockDialog> {
  final _labelController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _labelFocus = FocusNode();

  final Set<int> _weekdays = {};
  late DayType _dayType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dayType = widget.existing?.dayType ?? widget.dayType;
    final existing = widget.existing;
    if (existing != null) {
      _labelController.text = existing.label;
      _startController.text = existing.startLabel;
      _endController.text = existing.endLabel;
      _weekdays.addAll(existing.weekdays);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _labelFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _startController.dispose();
    _endController.dispose();
    _labelFocus.dispose();
    super.dispose();
  }

  int? _parseTime(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3) return null;
    final padded = digits.padLeft(4, '0');
    final hour = int.parse(padded.substring(0, 2));
    final minute = int.parse(padded.substring(2, 4));
    if (hour > 24 || minute > 59) return null;
    return hour * 60 + minute;
  }

  Future<void> _save() async {
    if (_saving) return;

    final label = _labelController.text.trim();
    final start = _parseTime(_startController.text);
    final end = _parseTime(_endController.text);

    if (label.isEmpty || start == null || end == null) {
      _labelFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);

    final block = RoutineBlock(
      id: widget.existing?.id ?? '',
      dayType: _dayType,
      startMinutes: start,
      endMinutes: end,
      label: label,
      weekdays: _weekdays.toList()..sort(),
      order: widget.existing?.order ?? start,
    );

    try {
      if (widget.existing == null) {
        await RoutineService.addBlock(block);
      } else {
        await RoutineService.updateBlock(block);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: Container(
        width: 460,
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.border,
            width: AppBorders.normal,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Novo bloco' : 'Editar bloco',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const _Label('Tipo de dia'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in DayType.values)
                  _WeekdayChip(
                    label: type.label,
                    selected: _dayType == type,
                    onTap: () => setState(() {
                      _dayType = type;
                      if (type != DayType.weekday) _weekdays.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            const _Label('Atividade'),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              focusNode: _labelFocus,
              onSubmitted: (_) => _save(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: _decoration('Concurso'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Começa'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _startController,
                        inputFormatters: [_TimeFormatter()],
                        style: AppText.money(
                          size: 15,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _decoration('04:00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Termina'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _endController,
                        inputFormatters: [_TimeFormatter()],
                        onSubmitted: (_) => _save(),
                        style: AppText.money(
                          size: 15,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _decoration('06:00'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_dayType == DayType.weekday) ...[
              const SizedBox(height: 16),
              const _Label('Dias da semana'),
              const SizedBox(height: 4),
              const Text(
                'Deixe vazio para valer de segunda a sexta',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  for (var day = 1; day <= 5; day++) ...[
                    _WeekdayChip(
                      label: const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'][day - 1],
                      selected: _weekdays.contains(day),
                      onTap: () => setState(() {
                        if (!_weekdays.remove(day)) _weekdays.add(day);
                      }),
                    ),
                    if (day != 5) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _SaveButton(loading: _saving, onPressed: _save),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: AppBorders.normal,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: AppBorders.normal,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(
          color: AppColors.accent,
          width: AppBorders.selected,
        ),
      ),
    );
  }
}

class _TimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = trimmed.length <= 2
        ? trimmed
        : '${trimmed.substring(0, trimmed.length - 2)}:${trimmed.substring(trimmed.length - 2)}';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.borderAccent : AppColors.border,
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: _hover ? AppColors.accentHover : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onAccent,
                  ),
                )
              : const Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onAccent,
                  ),
                ),
        ),
      ),
    );
  }
}