import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class CategoryRankingCard extends StatelessWidget {
  const CategoryRankingCard({
    super.key,
    required this.byCategory,
    required this.categoryColors,
    required this.categoryIds,
    required this.total,
    required this.subtitle,
    this.title = 'Gastos por categoria',
    this.emptyMessage = 'Sem gastos registrados neste período',
    this.action,
    this.borderColor,
  });

  final Map<String, double> byCategory;
  final Map<String, int> categoryColors;
  final Map<String, String> categoryIds;
  final double total;
  final String subtitle;
  final String title;
  final String emptyMessage;
  final Widget? action;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      title: title,
      subtitle: subtitle,
      trailing: action,
      borderColor: borderColor,
      child: entries.isEmpty
          ? EmptyHint(message: emptyMessage)
          : Column(
              children: [
                for (final entry in entries) ...[
                  _Row(
                    name: entry.key,
                    value: entry.value,
                    share: total == 0 ? 0 : entry.value / total,
                    color: Color(categoryColors[entry.key] ?? 0xFF9AA1A8),
                    icon: categoryById(categoryIds[entry.key] ?? '')?.icon,
                  ),
                  if (entry != entries.last) const SizedBox(height: 15),
                ],
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.value,
    required this.share,
    required this.color,
    required this.icon,
  });

  final String name;
  final double value;
  final double share;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              icon ?? Icons.circle,
              size: 15,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              formatMoney(value),
              style: AppText.money(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 34,
              child: Text(
                '${(share * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: AppText.money(size: 11.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}