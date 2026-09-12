import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({super.key, required this.transactions});

  final List<Tx> transactions;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    final colors = <String, Color>{};
    var grandTotal = 0.0;

    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      totals[tx.categoryName] = (totals[tx.categoryName] ?? 0) + tx.amount;
      colors[tx.categoryName] = tx.categoryColor;
      grandTotal += tx.amount;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      title: 'Despesas por categoria',
      child: entries.isEmpty
          ? const EmptyHint(message: 'Nenhuma saída neste dia')
          : Column(
              children: [
                for (final entry in entries) ...[
                  _CategoryRow(
                    name: entry.key,
                    value: entry.value,
                    share: grandTotal == 0 ? 0 : entry.value / grandTotal,
                    color: colors[entry.key] ?? AppColors.textMuted,
                  ),
                  if (entry != entries.last) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.value,
    required this.share,
    required this.color,
  });

  final String name;
  final double value;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${(share * 100).toStringAsFixed(0)}%',
              style: AppText.money(size: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Text(
              formatMoney(value),
              style: AppText.money(size: 12.5, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}