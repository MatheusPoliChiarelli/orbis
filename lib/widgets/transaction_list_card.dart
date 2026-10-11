import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../data/categories.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'bank_logo.dart';

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
    this.showFilters = true,
    this.amountColor,
    this.amountAtEnd = false,
    this.borderColor,
  });

  final List<Tx> transactions;
  final ValueChanged<Tx> onEdit;
  final ValueChanged<Tx> onDelete;
  final bool showAccountBadge;
  final bool showDate;
  final bool bare;
  final bool showFilters;

  /// Força uma cor no valor, ignorando o tipo do lançamento.
  final Color? amountColor;

  /// Move o valor para o fim da linha, depois dos badges.
  final bool amountAtEnd;

  /// Cor da borda quando uma conta está selecionada.
  final Color? borderColor;

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
                  forcedColor: widget.amountColor,
                  amountAtEnd: widget.amountAtEnd,
                  onEdit: () => widget.onEdit(tx),
                  onDelete: () => widget.onDelete(tx),
                ),
                if (tx != list.last)
                  const Divider(
                    height: 14,
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
          if (widget.showFilters) ...[
            filters,
            const SizedBox(height: 16),
          ],
          content,
        ],
      );
    }

    return AppCard(
      title: 'Lançamentos do dia',
      trailing: widget.showFilters ? filters : null,
      borderColor: widget.borderColor,
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
      padding: EdgeInsets.fromLTRB(
        dense ? 3 : 4,
        dense ? 2 : 3,
        dense ? 8 : 10,
        dense ? 2 : 3,
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
          BankLogo(accountId: accountId, size: dense ? 13 : 16),
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
    required this.forcedColor,
    required this.amountAtEnd,
    required this.onEdit,
    required this.onDelete,
  });

  final Tx tx;
  final bool showAccountBadge;
  final bool showDate;
  final Color? forcedColor;
  final bool amountAtEnd;
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

    final amountColor = widget.forcedColor ??
        (tx.isTransfer
            ? AppColors.textSecondary
            : (tx.isIncome ? AppColors.income : AppColors.expense));

    final prefix = widget.forcedColor != null
        ? ''
        : (tx.isTransfer ? '' : (tx.isIncome ? '+' : '-'));

    final showDescription = (tx.categoryId == 'outros' ||
            tx.categoryId == 'outras-entradas') &&
        tx.description.isNotEmpty;

    final date =
        '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';

    final subtitleParts = <String>[
      if (widget.showDate) date,
      if (showDescription) tx.description,
    ];

    final amount = Text(
      '$prefix ${formatMoney(tx.amount)}',
      style: AppText.money(
        size: 13.5,
        color: amountColor,
        weight: FontWeight.w500,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tx.categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  categoryById(tx.categoryId)?.icon ?? Icons.circle,
                  size: 16,
                  color: tx.categoryColor,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tx.categoryName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join('  ·  '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!widget.amountAtEnd) ...[
                const SizedBox(width: 20),
                amount,
              ],
              const Spacer(),
              if (widget.showAccountBadge) ...[
                AccountBadge(accountId: tx.accountId),
                if (tx.isTransfer && tx.toAccountId != null) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  AccountBadge(accountId: tx.toAccountId!),
                ],
                if (widget.amountAtEnd) const SizedBox(width: 16),
              ],
              if (widget.amountAtEnd) amount,
              SizedBox(
                width: 36,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hover ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_hover,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}