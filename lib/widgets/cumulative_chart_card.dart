import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class CumulativeChartCard extends StatelessWidget {
  const CumulativeChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labels,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v != 0);

    return AppCard(
      title: title,
      subtitle: subtitle,
      child: hasData
          ? SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(),
                  lineTouchData: _touchData(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < values.length; i++)
                          FlSpot(i.toDouble(), values[i]),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.22,
                      color: AppColors.accent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.22),
                            AppColors.accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const EmptyHint(message: 'Sem movimento registrado'),
    );
  }

  LineTouchData _touchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => AppColors.surfaceRaised,
        tooltipRoundedRadius: AppRadius.field,
        getTooltipItems: (spots) {
          return spots.map((spot) {
            final index = spot.x.toInt();
            return LineTooltipItem(
              '${index < labels.length ? labels[index] : ''}\n',
              const TextStyle(fontSize: 11, color: AppColors.textMuted),
              children: [
                TextSpan(
                  text: formatMoney(spot.y),
                  style: AppText.money(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  FlTitlesData _titles() {
    final step = values.length > 20 ? 5 : 1;

    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 62,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                formatMoneyPlain(value),
                textAlign: TextAlign.right,
                style: AppText.money(size: 10, color: AppColors.textMuted),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: 1,
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