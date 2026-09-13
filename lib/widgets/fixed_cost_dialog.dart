import 'package:flutter/material.dart';

import '../models/fixed_cost.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

Future<void> showFixedCostDialog({
  required BuildContext context,
  required int year,
  FixedCost? existing,
  String? parentId,
  String? parentName,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => FixedCostDialog(
      year: year,
      existing: existing,
      parentId: parentId,
      parentName: parentName,
    ),
  );
}

class FixedCostDialog extends StatefulWidget {
  const FixedCostDialog({
    super.key,
    required this.year,
    this.existing,
    this.parentId,
    this.parentName,
  });

  final int year;
  final FixedCost? existing;
  final String? parentId;
  final String? parentName;

  @override
  State<FixedCostDialog> createState() => _FixedCostDialogState();
}

class _FixedCostDialogState extends State<FixedCostDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _nameFocus = FocusNode();
  final _amountFocus = FocusNode();

  String? _startMonth;
  String? _endMonth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = formatMoneyPlain(existing.amount);
      _startMonth = existing.startMonth;
      _endMonth = existing.endMonth;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    _amountFocus.dispose();
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

    final item = FixedCost(
      id: widget.existing?.id ?? '',
      name: name,
      amount: parseMoney(_amountController.text),
      startMonth: _startMonth,
      endMonth: _endMonth,
      parentId: widget.existing?.parentId ?? widget.parentId,
      order: widget.existing?.order ?? DateTime.now().millisecondsSinceEpoch,
    );

    try {
      if (widget.existing == null) {
        await FinanceService.addFixedCost(item);
      } else {
        await FinanceService.updateFixedCost(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChild = (widget.existing?.parentId ?? widget.parentId) != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: Container(
        width: 480,
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
            Row(
              children: [
                Text(
                  widget.existing == null
                      ? (isChild ? 'Nova assinatura' : 'Novo item fixo')
                      : 'Editar item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (widget.parentName != null)
                  Text(
                    'dentro de ${widget.parentName}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _Label('Nome'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              onSubmitted: (_) => _amountFocus.requestFocus(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: _decoration(hint: 'Corte de cabelo'),
            ),
            const SizedBox(height: 16),
            const _Label('Valor mensal'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              inputFormatters: [CurrencyInputFormatter()],
              onSubmitted: (_) => _save(),
              style: AppText.money(
                size: 18,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: _decoration(hint: '0,00', prefix: 'R\$ '),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MonthPicker(
                    label: 'Começa em',
                    value: _startMonth,
                    year: widget.year,
                    emptyLabel: 'Desde sempre',
                    onChanged: (value) => setState(() => _startMonth = value),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MonthPicker(
                    label: 'Termina em',
                    value: _endMonth,
                    year: widget.year,
                    emptyLabel: 'Sem fim',
                    onChanged: (value) => setState(() => _endMonth = value),
                  ),
                ),
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

  InputDecoration _decoration({required String hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      prefixIcon: prefix == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  prefix.trim(),
                  style: AppText.money(size: 15, color: AppColors.textMuted),
                ),
              ),
            ),
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

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.value,
    required this.year,
    required this.emptyLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final int year;
  final String emptyLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.field),
              icon: const Icon(
                Icons.expand_more,
                size: 17,
                color: AppColors.textMuted,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    emptyLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                for (var i = 1; i <= 12; i++)
                  DropdownMenuItem<String?>(
                    value: '$year-${i.toString().padLeft(2, '0')}',
                    child: Text(
                      '${monthNames[i - 1]} de $year',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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