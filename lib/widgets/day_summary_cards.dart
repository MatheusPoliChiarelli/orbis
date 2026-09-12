import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class DaySummaryCards extends StatelessWidget {
  const DaySummaryCards({super.key, required this.transactions});

  final List<Tx> transactions;

  @override
  Widget build(BuildContext context) {
    var income = 0.0;
    var expense = 0.0;
    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    final balance = income - expense;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Entradas',
            value: income,
            color: AppColors.income,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            label: 'Saídas',
            value: expense,
            color: AppColors.expense,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            label: 'Balanço',
            value: balance,
            color: balance < 0 ? AppColors.expense : AppColors.income,
            icon: Icons.swap_vert,
            signed: true,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.signed = false,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            signed ? formatSigned(value) : formatMoney(value),
            style: AppText.money(size: 20, color: color, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}