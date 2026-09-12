import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../models/month_budget.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class BalancesCard extends StatelessWidget {
  const BalancesCard({
    super.key,
    required this.month,
    required this.accountId,
    required this.budget,
  });

  final DateTime month;
  final String accountId;
  final MonthBudget budget;

  @override
  Widget build(BuildContext context) {
    final isGeneral = accountId == kGeneralAccountId;

    final opening = isGeneral
        ? realAccountIds.fold<double>(0, (sum, id) => sum + budget.opening(id))
        : budget.opening(accountId);

    final closing = isGeneral
        ? realAccountIds.fold<double>(0, (sum, id) => sum + budget.closing(id))
        : budget.closing(accountId);

    final key = '$accountId-${monthKey(month)}';

    return AppCard(
      title: 'Saldos do mês',
      trailing: isGeneral
          ? const Text(
              'Somatório das contas',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: _BalanceField(
              key: ValueKey('$key-opening'),
              label: 'Saldo inicial',
              value: opening,
              readOnly: isGeneral,
              onSubmit: (value) => FinanceService.setOpeningBalance(
                month: month,
                accountId: accountId,
                value: value,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _BalanceField(
              key: ValueKey('$key-closing'),
              label: 'Saldo final',
              value: closing,
              readOnly: isGeneral,
              onSubmit: (value) => FinanceService.setClosingBalance(
                month: month,
                accountId: accountId,
                value: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceField extends StatefulWidget {
  const _BalanceField({
    super.key,
    required this.label,
    required this.value,
    required this.readOnly,
    required this.onSubmit,
  });

  final String label;
  final double value;
  final bool readOnly;
  final ValueChanged<double> onSubmit;

  @override
  State<_BalanceField> createState() => _BalanceFieldState();
}

class _BalanceFieldState extends State<_BalanceField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value == 0 ? '' : formatMoneyPlain(widget.value),
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void didUpdateWidget(_BalanceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.value != oldWidget.value) {
      _controller.text =
          widget.value == 0 ? '' : formatMoneyPlain(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.readOnly) return;
    final parsed = parseMoney(_controller.text);
    if (parsed != widget.value) widget.onSubmit(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textMuted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _controller,
          focusNode: _focus,
          readOnly: widget.readOnly,
          onSubmitted: (_) => _save(),
          inputFormatters: [CurrencyInputFormatter()],
          style: AppText.money(
            size: 15,
            weight: FontWeight.w600,
            color: widget.readOnly
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            prefixStyle: AppText.money(size: 14, color: AppColors.textMuted),
            hintText: '0,00',
            hintStyle: AppText.money(size: 15, color: AppColors.textMuted),
            filled: true,
            fillColor: widget.readOnly ? AppColors.surface : AppColors.bg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
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
      ],
    );
  }
}