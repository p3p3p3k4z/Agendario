import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/achievement.dart';
import '../config/theme.dart';

// wrapper de fl_chart con estilo Gruvbox para graficas de habitos
// expone dos constructores: linea (30 dias) y barras (semanas)

class StatsLineChart extends StatelessWidget {
  final List<DailyValue> values;
  final Color color;
  final double? goal;

  const StatsLineChart({
    super.key,
    required this.values,
    required this.color,
    this.goal,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos aún',
          style: TextStyle(color: GruvboxColors.bg1, fontSize: 14),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i].value));
    }

    final maxY =
        values.map((v) => v.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return AspectRatio(
      aspectRatio: 1.8,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: GruvboxColors.bg1.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: GruvboxColors.bg1.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (values.length / 5).ceilToDouble().clamp(1, 30),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= values.length)
                      return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('d/M').format(values[idx].date),
                        style: TextStyle(
                          fontSize: 9,
                          color: GruvboxColors.bg1.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: maxY.clamp(1, double.infinity),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: color,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.1),
                ),
              ),
            ],
            // linea de meta si existe
            extraLinesData: goal != null
                ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal!,
                        color: GruvboxColors.yellow.withValues(alpha: 0.6),
                        strokeWidth: 2,
                        dashArray: [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (_) => 'Meta: ${goal!.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: GruvboxColors.yellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class StatsBarChart extends StatelessWidget {
  final List<double> weeklyAverages;
  final Color color;

  const StatsBarChart({
    super.key,
    required this.weeklyAverages,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyAverages.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos aún',
          style: TextStyle(color: GruvboxColors.bg1, fontSize: 14),
        ),
      );
    }

    final maxY = weeklyAverages.reduce((a, b) => a > b ? a : b) * 1.3;

    return AspectRatio(
      aspectRatio: 2.0,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 12),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: GruvboxColors.bg1.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: GruvboxColors.bg1.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final labels = ['Sem 4', 'Sem 3', 'Sem 2', 'Sem 1'];
                    final idx = value.toInt();
                    if (idx < 0 || idx >= labels.length)
                      return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          fontSize: 10,
                          color: GruvboxColors.bg1.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            maxY: maxY.clamp(1, double.infinity),
            barGroups: weeklyAverages.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: color.withValues(alpha: 0.8),
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: GruvboxColors.bg1.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
