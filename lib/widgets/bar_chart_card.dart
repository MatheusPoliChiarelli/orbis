import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'dart:math' as math;

/// Arredonda o máximo para o próximo valor redondo, em passos de
/// 1, 2, 2.5, 5 e 10 vezes a magnitude.
double _roundedMax(double value) {
  if (value <= 0) return 10;

  final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
  final normalized = value / magnitude;

  final step = switch (normalized) {
    <= 1 => 1.0,
    <= 2 => 2.0,
    <= 2.5 => 2.5,
    <= 5 => 5.0,
    _ => 10.0,
  };

  return step * magnitude;
}

class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.color,
    required this.labels,
    this.height = 190,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final Color color;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v != 0);
    final maxY = _roundedMax(
      values.fold<double>(0, (a, v) => v > a ? v : a),
    );

    return AppCard(
      title: title,
      subtitle: subtitle,
      child: hasData
          ? SizedBox(
              height: height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: _touchData(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(maxY),
                  barGroups: [
                    for (var i = 0; i < values.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            color: color,
                            width: values.length > 20 ? 8 : 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            )
          : EmptyHint(message: 'Sem dados para $subtitle'),
    );
  }

  BarTouchData _touchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => AppColors.surfaceRaised,
        tooltipRoundedRadius: AppRadius.field,
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${labels[group.x]}\n',
            const TextStyle(fontSize: 11, color: AppColors.textMuted),
            children: [
              TextSpan(
                text: formatMoney(rod.toY),
                style: AppText.money(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FlTitlesData _titles(double maxY) {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 56,
          interval: maxY / 4,
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                formatMoneyPlain(value),
                textAlign: TextAlign.right,
                style: AppText.money(size: 9.5, color: AppColors.textMuted),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                labels[index],
                style: AppText.money(size: 9, color: AppColors.textMuted),
              ),
            );
          },
        ),
      ),
    );
  }
}