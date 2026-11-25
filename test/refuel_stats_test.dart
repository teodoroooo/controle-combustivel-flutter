import 'package:controle_combustivel/models/refuel.dart';
import 'package:controle_combustivel/models/refuel_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Refuel r(String id, double km, double liters, double price, DateTime d) =>
    Refuel(
      id: id,
      fuelType: FuelType.gasolina,
      pricePerLiter: price,
      odometer: km,
      liters: liters,
      dateTime: d,
    );

void main() {
  test('valor total = preço por litro × litros', () {
    expect(r('a', 0, 40, 5.5, DateTime(2026)).totalPrice, closeTo(220, 1e-9));
  });

  test('primeiro abastecimento não possui indicadores', () {
    final stats = RefuelStats.compute([r('a', 1000, 40, 5, DateTime(2026))]);
    expect(stats.single.hasIndicators, isFalse);
    expect(stats.single.kmPerLiter, isNull);
    expect(stats.single.costPerKm, isNull);
  });

  test('calcula distância, km/L e R\$/km a partir do segundo', () {
    final stats = RefuelStats.compute([
      // fora de ordem de propósito
      r('b', 1400, 32, 6, DateTime(2026, 1, 10)),
      r('a', 1000, 40, 5, DateTime(2026, 1, 1)),
    ]);
    expect(stats.first.refuel.id, 'a');
    final s = stats[1];
    expect(s.distance, 400);
    expect(s.kmPerLiter, closeTo(400 / 32, 1e-9)); // 12,5 km/L
    expect(s.costPerKm, closeTo(32 * 6 / 400, 1e-9)); // R$ 0,48/km
  });

  test('resumo do dashboard', () {
    final stats = RefuelStats.compute([
      r('a', 1000, 40, 5, DateTime(2026, 1, 1)),
      r('b', 1400, 40, 5, DateTime(2026, 1, 2)),
      r('c', 1900, 50, 5, DateTime(2026, 1, 3)),
    ]);
    final sum = DashboardSummary.fromStats(stats);
    expect(sum.refuelCount, 3);
    expect(sum.totalSpent, 650);
    expect(sum.totalLiters, 130);
    expect(sum.averageKmPerLiter, closeTo((10 + 10) / 2, 1e-9));
    expect(sum.averageCostPerKm, closeTo((0.5 + 0.5) / 2, 1e-9));
  });

  test('serialização JSON ida e volta', () {
    final original = r('x', 123, 10, 4.99, DateTime(2026, 5, 4, 13, 30));
    final copy = Refuel.fromJson(original.toJson());
    expect(copy.toJson(), original.toJson());
  });
}
