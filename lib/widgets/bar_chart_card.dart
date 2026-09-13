import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

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

    return AppCard(
      title: title,
      subtitle: subtitle,
      child: hasData
          ? SizedBox(
              height: height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: _touchData(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(),
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

  FlTitlesData _titles() {
    final step = values.length > 20 ? 5 : 1;

    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length) {
              return const SizedBox.shrink();
            }
            if (step > 1 && index % step != 0 && index != labels.length - 1) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                labels[index],
                style: AppText.money(size: 10, color: AppColors.textMuted),
              ),
            );
          },
        ),
      ),
    );
  }
}