import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../theme/app_theme.dart';

Future<void> showHabitDialog({
  required BuildContext context,
  Habit? existing,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => HabitDialog(existing: existing),
  );
}

class HabitDialog extends StatefulWidget {
  const HabitDialog({super.key, this.existing});

  final Habit? existing;

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    final habit = Habit(
      id: widget.existing?.id ?? '',
      name: name,
      frequency: HabitFrequency.daily,
      active: widget.existing?.active ?? true,
      group: null,
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
        width: 420,
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
            const Text(
              'Nome',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              onSubmitted: (_) => _save(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Academia',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
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
              ),
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