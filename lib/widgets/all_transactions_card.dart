import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'transaction_list_card.dart';

class AllTransactionsCard extends StatefulWidget {
  const AllTransactionsCard({
    super.key,
    required this.transactions,
    required this.balance,
    required this.showAccountBadge,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Tx> transactions;
  final double balance;
  final bool showAccountBadge;
  final ValueChanged<Tx> onEdit;
  final ValueChanged<Tx> onDelete;

  @override
  State<AllTransactionsCard> createState() => _AllTransactionsCardState();
}

class _AllTransactionsCardState extends State<AllTransactionsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.transactions.length;

    return AppCard(
      title: 'Todos os lançamentos',
      subtitle:
          '$count no período, movimento de ${formatSigned(widget.balance)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ToggleButton(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            TransactionListCard(
              transactions: widget.transactions,
              showAccountBadge: widget.showAccountBadge,
              showDate: true,
              bare: true,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleButton extends StatefulWidget {
  const _ToggleButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: _hover ? AppColors.surfaceRaised : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.expanded ? Icons.expand_less : Icons.expand_more,
                size: 17,
                color: AppColors.accent,
              ),
              const SizedBox(width: 9),
              Text(
                widget.expanded ? 'Ocultar lançamentos' : 'Ver lançamentos',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}