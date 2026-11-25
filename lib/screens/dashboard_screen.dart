import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/refuel_stats.dart';
import '../utils/formatters.dart';

/// Dashboard com indicadores e gráficos (fl_chart).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final stats = controller.stats;
    final summary = controller.summary;
    final theme = Theme.of(context);

    if (stats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Registre abastecimentos para ver o dashboard.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final withIndicators = stats.where((s) => s.hasIndicators).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _KpiCard(
              label: 'Total gasto',
              value: formatCurrency(summary.totalSpent),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _KpiCard(
              label: 'Litros',
              value: '${formatDecimal(summary.totalLiters)} L',
              icon: Icons.water_drop_outlined,
            ),
            _KpiCard(
              label: 'Média km/L',
              value: summary.averageKmPerLiter == null
                  ? '—'
                  : formatDecimal(summary.averageKmPerLiter!),
              icon: Icons.eco_outlined,
            ),
            _KpiCard(
              label: 'Média R\$/km',
              value: summary.averageCostPerKm == null
                  ? '—'
                  : formatCurrency(summary.averageCostPerKm!),
              icon: Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ChartCard(
          title: 'Valor de cada abastecimento (R\$)',
          child: _ValueBarChart(stats: stats),
        ),
        _ChartCard(
          title: 'Consumo (km/L)',
          child: withIndicators.isEmpty
              ? const _NeedsTwo()
              : _IndicatorLineChart(
                  stats: withIndicators,
                  valueOf: (s) => s.kmPerLiter!,
                  color: Colors.teal,
                  format: formatDecimal,
                ),
        ),
        _ChartCard(
          title: 'Custo por quilômetro (R\$/km)',
          child: withIndicators.isEmpty
              ? const _NeedsTwo()
              : _IndicatorLineChart(
                  stats: withIndicators,
                  valueOf: (s) => s.costPerKm!,
                  color: Colors.deepOrange,
                  format: formatCurrency,
                ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Indicadores por abastecimento',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 40,
                    columns: const [
                      DataColumn(label: Text('Data')),
                      DataColumn(label: Text('Valor'), numeric: true),
                      DataColumn(label: Text('km'), numeric: true),
                      DataColumn(label: Text('km/L'), numeric: true),
                      DataColumn(label: Text('R\$/km'), numeric: true),
                    ],
                    rows: [
                      for (final s in stats)
                        DataRow(cells: [
                          DataCell(Text(formatShortDate(s.refuel.dateTime))),
                          DataCell(Text(formatCurrency(s.refuel.totalPrice))),
                          DataCell(Text(s.distance == null
                              ? '—'
                              : s.distance!.toStringAsFixed(0))),
                          DataCell(Text(s.kmPerLiter == null
                              ? '—'
                              : formatDecimal(s.kmPerLiter!))),
                          DataCell(Text(s.costPerKm == null
                              ? '—'
                              : formatCurrency(s.costPerKm!))),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium),
              ),
            ]),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}

class _NeedsTwo extends StatelessWidget {
  const _NeedsTwo();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text(
          'Registre ao menos dois abastecimentos para calcular este '
          'indicador.',
          textAlign: TextAlign.center,
        ),
      );
}

String _bottomLabel(List<RefuelStats> stats, double x) {
  final i = x.toInt();
  if (i < 0 || i >= stats.length || x != i.toDouble()) return '';
  return formatShortDate(stats[i].refuel.dateTime);
}

SideTitles _bottomTitles(List<RefuelStats> stats) => SideTitles(
      showTitles: true,
      reservedSize: 28,
      interval: math.max(1, (stats.length / 6).ceilToDouble()),
      getTitlesWidget: (x, meta) => SideTitleWidget(
        meta: meta,
        child: Text(_bottomLabel(stats, x), style: const TextStyle(fontSize: 10)),
      ),
    );

class _ValueBarChart extends StatelessWidget {
  const _ValueBarChart({required this.stats});

  final List<RefuelStats> stats;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  v == meta.max ? '' : v.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: _bottomTitles(stats)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              formatCurrency(rod.toY),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < stats.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: stats[i].refuel.totalPrice,
                color: color,
                width: stats.length > 15 ? 8 : 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }
}

class _IndicatorLineChart extends StatelessWidget {
  const _IndicatorLineChart({
    required this.stats,
    required this.valueOf,
    required this.color,
    required this.format,
  });

  final List<RefuelStats> stats;
  final double Function(RefuelStats) valueOf;
  final Color color;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final values = stats.map(valueOf).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad = (maxV - minV).abs() < 1e-9 ? (maxV.abs() * 0.2 + 0.1) : (maxV - minV) * 0.2;

    return LineChart(
      LineChartData(
        minY: math.max(0, minV - pad),
        maxY: maxV + pad,
        minX: stats.length == 1 ? -0.5 : 0,
        maxX: stats.length == 1 ? 0.5 : (stats.length - 1).toDouble(),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  v == meta.max || v == meta.min ? '' : formatDecimal(v),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: _bottomTitles(stats)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  format(s.y),
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
