import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

enum TxFilter { all, income, expense }

class TransactionListCard extends StatefulWidget {
  const TransactionListCard({
    super.key,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
    this.showAccountBadge = false,
    this.showDate = false,
    this.bare = false,
  });

  final List<Tx> transactions;
  final ValueChanged<Tx> onEdit;
  final ValueChanged<Tx> onDelete;
  final bool showAccountBadge;
  final bool showDate;
  final bool bare;


  @override
  State<TransactionListCard> createState() => _TransactionListCardState();
}

class _TransactionListCardState extends State<TransactionListCard> {
  TxFilter _filter = TxFilter.all;

  @override
  Widget build(BuildContext context) {
    final list = widget.transactions.where((tx) {
      return switch (_filter) {
        TxFilter.all => true,
        TxFilter.income => tx.isIncome,
        TxFilter.expense => tx.isExpense,
      };
    }).toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? a.date;
        final bTime = b.createdAt ?? b.date;
        return bTime.compareTo(aTime);
      });

    final filters = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final filter in TxFilter.values) ...[
          _FilterChip(
            label: switch (filter) {
              TxFilter.all => 'Todas',
              TxFilter.income => 'Entradas',
              TxFilter.expense => 'Saídas',
            },
            selected: _filter == filter,
            onTap: () => setState(() => _filter = filter),
          ),
          if (filter != TxFilter.values.last) const SizedBox(width: 6),
        ],
      ],
    );

    final content = list.isEmpty
        ? const EmptyHint(message: 'Nenhum lançamento neste período')
        : Column(
            children: [
              for (final tx in list) ...[
                _TxRow(
                  tx: tx,
                  showAccountBadge: widget.showAccountBadge,
                  showDate: widget.showDate,
                  onEdit: () => widget.onEdit(tx),
                  onDelete: () => widget.onDelete(tx),
                ),
                if (tx != list.last)
                  const Divider(
                    height: 18,
                    thickness: AppBorders.normal,
                    color: AppColors.border,
                  ),
              ],
            ],
          );

    if (widget.bare) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 16),
          content,
        ],
      );
    }

    return AppCard(
      title: 'Lançamentos do dia',
      trailing: filters,
      child: content,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.borderAccent : AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class AccountBadge extends StatelessWidget {
  const AccountBadge({super.key, required this.accountId, this.dense = false});

  final String accountId;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final account = accountById(accountId);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: account.color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: account.color.withValues(alpha: 0.40),
          width: AppBorders.normal,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: account.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            account.name,
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: account.color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatefulWidget {
  const _TxRow({
    required this.tx,
    required this.showAccountBadge,
    required this.showDate,
    required this.onEdit,
    required this.onDelete,
  });

  final Tx tx;
  final bool showAccountBadge;
  final bool showDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_TxRow> createState() => _TxRowState();
}

class _TxRowState extends State<_TxRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;

    final amountColor = tx.isTransfer
        ? AppColors.textSecondary
        : (tx.isIncome ? AppColors.income : AppColors.expense);

    final prefix = tx.isTransfer ? '' : (tx.isIncome ? '+' : '-');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tx.categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: tx.categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description.isEmpty ? tx.categoryName : tx.description,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        widget.showDate
                            ? '${tx.date.day.toString().padLeft(2, '0')} ${monthLabel(tx.date).substring(0, 3).toLowerCase()}'
                            : tx.categoryName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (widget.showAccountBadge) ...[
                        const SizedBox(width: 8),
                        AccountBadge(accountId: tx.accountId, dense: true),
                        if (tx.isTransfer && tx.toAccountId != null) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          AccountBadge(
                            accountId: tx.toAccountId!,
                            dense: true,
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${formatMoney(tx.amount)}',
              style: AppText.money(
                size: 13.5,
                color: amountColor,
                weight: FontWeight.w600,
              ),
            ),
            SizedBox(
              width: 34,
              child: _hover
                  ? IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      splashRadius: 16,
                      tooltip: 'Excluir',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}