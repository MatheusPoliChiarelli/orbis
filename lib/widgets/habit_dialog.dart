import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../theme/app_theme.dart';

Future<void> showHabitDialog({
  required BuildContext context,
  Habit? existing,
  List<String> groups = const [],
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => HabitDialog(existing: existing, groups: groups),
  );
}

class HabitDialog extends StatefulWidget {
  const HabitDialog({super.key, this.existing, this.groups = const []});

  final Habit? existing;
  final List<String> groups;

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  final _nameController = TextEditingController();
  final _groupController = TextEditingController();
  final _nameFocus = FocusNode();

  HabitFrequency _frequency = HabitFrequency.daily;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _groupController.text = existing.group ?? '';
      _frequency = existing.frequency;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);

    final group = _groupController.text.trim();

    final habit = Habit(
      id: widget.existing?.id ?? '',
      name: name,
      frequency: _frequency,
      active: widget.existing?.active ?? true,
      group: group.isEmpty ? null : group,
      order: widget.existing?.order ?? DateTime.now().millisecondsSinceEpoch,
    );

    try {
      if (widget.existing == null) {
        await HabitService.addHabit(habit);
      } else {
        await HabitService.updateHabit(habit);
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
              widget.existing == null ? 'Novo hábito' : 'Editar hábito',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const _Label('Nome'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              onSubmitted: (_) => _save(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: _decoration('Academia'),
            ),
            const SizedBox(height: 16),
            const _Label('Grupo'),
            const SizedBox(height: 8),
            TextField(
              controller: _groupController,
              onSubmitted: (_) => _save(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: _decoration('Opcional, por exemplo Concurso'),
            ),
            if (widget.groups.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final group in widget.groups)
                    _GroupChip(
                      label: group,
                      onTap: () => setState(
                        () => _groupController.text = group,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const _Label('Frequência'),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final frequency in HabitFrequency.values) ...[
                  _FrequencyChip(
                    label: switch (frequency) {
                      HabitFrequency.daily => 'Diário',
                      HabitFrequency.weekly => 'Semanal',
                      HabitFrequency.monthly => 'Mensal',
                    },
                    selected: _frequency == frequency,
                    onTap: () => setState(() => _frequency = frequency),
                  ),
                  if (frequency != HabitFrequency.values.last)
                    const SizedBox(width: 9),
                ],
              ],
            ),
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

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              fontSize: 12.5,
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