import 'package:controle_combustivel/controllers/app_controller.dart';
import 'package:controle_combustivel/models/refuel.dart';
import 'package:controle_combustivel/models/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const vehicle = Vehicle(
  brandCode: '21',
  brandName: 'Fiat',
  modelCode: '1',
  modelName: 'Uno',
  year: 2020,
  engineDisplacement: 1.0,
);

Refuel refuel(String id, double km, DateTime d) => Refuel(
      id: id,
      fuelType: FuelType.etanol,
      pricePerLiter: 4,
      odometer: km,
      liters: 30,
      dateTime: d,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persiste veículo e abastecimentos entre instâncias', () async {
    final c1 = AppController();
    await c1.load();
    await c1.saveVehicle(vehicle);
    await c1.upsertRefuel(refuel('1', 1000, DateTime(2026, 1, 1)));

    final c2 = AppController();
    await c2.load();
    expect(c2.vehicle?.modelName, 'Uno');
    expect(c2.refuels, hasLength(1));
  });

  test('permite apenas um veículo por vez', () async {
    final c = AppController();
    await c.load();
    await c.saveVehicle(vehicle);
    expect(() => c.saveVehicle(vehicle), throwsStateError);
  });

  test('excluir veículo remove os abastecimentos', () async {
    final c = AppController();
    await c.load();
    await c.saveVehicle(vehicle);
    await c.upsertRefuel(refuel('1', 1000, DateTime(2026, 1, 1)));
    await c.deleteVehicle();

    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.hasVehicle, isFalse);
    expect(reloaded.refuels, isEmpty);
  });

  test('rejeita quilometragem incoerente', () async {
    final c = AppController();
    await c.load();
    await c.saveVehicle(vehicle);
    await c.upsertRefuel(refuel('1', 1000, DateTime(2026, 1, 1)));
    expect(c.validateOdometer(refuel('2', 900, DateTime(2026, 1, 2))),
        isNotNull);
    expect(c.validateOdometer(refuel('2', 1300, DateTime(2026, 1, 2))),
        isNull);
  });
}
