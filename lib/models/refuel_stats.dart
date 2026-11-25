import 'refuel.dart';

/// Indicadores calculados para um abastecimento.
///
/// O primeiro abastecimento é a referência inicial: [distance], [kmPerLiter]
/// e [costPerKm] ficam nulos.
class RefuelStats {
  const RefuelStats({
    required this.refuel,
    this.distance,
    this.kmPerLiter,
    this.costPerKm,
  });

  final Refuel refuel;

  /// Quilometragem atual − quilometragem do abastecimento anterior.
  final double? distance;

  /// Distância percorrida ÷ litros do abastecimento atual.
  final double? kmPerLiter;

  /// Valor total do abastecimento atual ÷ distância percorrida.
  final double? costPerKm;

  bool get hasIndicators => kmPerLiter != null && costPerKm != null;

  /// Ordena os abastecimentos cronologicamente e calcula os indicadores.
  static List<RefuelStats> compute(List<Refuel> refuels) {
    final sorted = sortRefuels(refuels);
    final result = <RefuelStats>[];
    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      if (i == 0) {
        result.add(RefuelStats(refuel: current));
        continue;
      }
      final distance = current.odometer - sorted[i - 1].odometer;
      if (distance <= 0 || current.liters <= 0) {
        result.add(RefuelStats(refuel: current));
        continue;
      }
      result.add(RefuelStats(
        refuel: current,
        distance: distance,
        kmPerLiter: distance / current.liters,
        costPerKm: current.totalPrice / distance,
      ));
    }
    return result;
  }

  /// Ordena por data/hora e, em caso de empate, pela quilometragem.
  static List<Refuel> sortRefuels(List<Refuel> refuels) {
    final sorted = [...refuels];
    sorted.sort((a, b) {
      final byDate = a.dateTime.compareTo(b.dateTime);
      return byDate != 0 ? byDate : a.odometer.compareTo(b.odometer);
    });
    return sorted;
  }
}

/// Resumo geral exibido no topo do dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.totalSpent,
    required this.totalLiters,
    required this.refuelCount,
    this.averageKmPerLiter,
    this.averageCostPerKm,
  });

  final double totalSpent;
  final double totalLiters;
  final int refuelCount;
  final double? averageKmPerLiter;
  final double? averageCostPerKm;

  factory DashboardSummary.fromStats(List<RefuelStats> stats) {
    final withIndicators = stats.where((s) => s.hasIndicators).toList();
    double? avg(Iterable<double> values) => values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
    return DashboardSummary(
      totalSpent: stats.fold(0, (sum, s) => sum + s.refuel.totalPrice),
      totalLiters: stats.fold(0, (sum, s) => sum + s.refuel.liters),
      refuelCount: stats.length,
      averageKmPerLiter: avg(withIndicators.map((s) => s.kmPerLiter!)),
      averageCostPerKm: avg(withIndicators.map((s) => s.costPerKm!)),
    );
  }
}
