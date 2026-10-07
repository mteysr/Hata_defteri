import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class StudyDurationChart extends ConsumerWidget {
  const StudyDurationChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final box = Hive.box('academy_settings_box');
    final rawSessions = box.get('study_sessions', defaultValue: []);
    
    // Parse sessions
    final List<Map<String, dynamic>> sessions = List<dynamic>.from(rawSessions)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Generate last 7 days list
    final List<DateTime> last7Days = List.generate(7, (index) {
      return DateUtils.dateOnly(DateTime.now().subtract(Duration(days: 6 - index)));
    });

    final List<_DailyStudy> dailyData = last7Days.map((day) {
      final daySessions = sessions.where((s) {
        final parsedDate = DateTime.tryParse(s['timestamp'] ?? '');
        return parsedDate != null && DateUtils.dateOnly(parsedDate).isAtSameMomentAs(day);
      }).toList();

      int tarihMin = 0;
      int cografyaMin = 0;
      int vatandaslikMin = 0;

      for (var s in daySessions) {
        final cat = s['category'] as String?;
        final duration = s['durationMinutes'] as int? ?? 0;
        if (cat == 'Tarih') tarihMin += duration;
        if (cat == 'Coğrafya') cografyaMin += duration;
        if (cat == 'Vatandaşlık') vatandaslikMin += duration;
      }

      return _DailyStudy(
        date: day,
        tarihMinutes: tarihMin,
        cografyaMinutes: cografyaMin,
        vatandaslikMinutes: vatandaslikMin,
      );
    }).toList();

    // Determine max Y limit for chart height scaling
    final int maxDailyTotal = dailyData.map((d) => d.totalMinutes).reduce((a, b) => a > b ? a : b);
    final double maxY = maxDailyTotal > 30 ? maxDailyTotal.toDouble() + 10 : 40.0;
    final double yInterval = maxY / 4;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Çalışma Süresi Analizi (Son 7 Gün)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Legend
                Row(
                  children: [
                    _buildLegendItem('Trh', theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    _buildLegendItem('Coğ', Colors.orange),
                    const SizedBox(width: 6),
                    _buildLegendItem('Vat', Colors.teal),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dayData = dailyData[groupIndex];
                        return BarTooltipItem(
                          '${DateFormat('EEEE', 'tr_TR').format(dayData.date)}\n'
                          'Tarih: ${dayData.tarihMinutes} dk\n'
                          'Coğrafya: ${dayData.cografyaMinutes} dk\n'
                          'Vatandaşlık: ${dayData.vatandaslikMinutes} dk\n'
                          'Toplam: ${dayData.totalMinutes} dk',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()} dk',
                            style: const TextStyle(fontSize: 8),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dailyData.length) return const SizedBox.shrink();
                          final date = dailyData[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd.MM').format(date),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(dailyData.length, (index) {
                    final day = dailyData[index];
                    final double tVal = day.tarihMinutes.toDouble();
                    final double cVal = day.cografyaMinutes.toDouble();
                    final double vVal = day.vatandaslikMinutes.toDouble();

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: day.totalMinutes.toDouble(),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: [
                            if (tVal > 0)
                              BarChartRodStackItem(0, tVal, theme.colorScheme.primary),
                            if (cVal > 0)
                              BarChartRodStackItem(tVal, tVal + cVal, Colors.orange),
                            if (vVal > 0)
                              BarChartRodStackItem(tVal + cVal, tVal + cVal + vVal, Colors.teal),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DailyStudy {
  final DateTime date;
  final int tarihMinutes;
  final int cografyaMinutes;
  final int vatandaslikMinutes;

  _DailyStudy({
    required this.date,
    required this.tarihMinutes,
    required this.cografyaMinutes,
    required this.vatandaslikMinutes,
  });

  int get totalMinutes => tarihMinutes + cografyaMinutes + vatandaslikMinutes;
}
