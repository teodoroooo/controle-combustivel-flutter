import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/refuel.dart';
import '../models/vehicle.dart';

/// Persistência local do veículo e dos abastecimentos.
///
/// Usa `shared_preferences` (SharedPreferences no Android, NSUserDefaults no
/// iOS, localStorage na Web), guardando os dados como JSON.
class StorageService {
  static const _vehicleKey = 'vehicle';
  static const _refuelsKey = 'refuels';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Vehicle?> loadVehicle() async {
    final raw = (await _prefs).getString(_vehicleKey);
    if (raw == null) return null;
    return Vehicle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    await (await _prefs).setString(_vehicleKey, jsonEncode(vehicle.toJson()));
  }

  Future<List<Refuel>> loadRefuels() async {
    final raw = (await _prefs).getString(_refuelsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Refuel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRefuels(List<Refuel> refuels) async {
    await (await _prefs).setString(
      _refuelsKey,
      jsonEncode(refuels.map((r) => r.toJson()).toList()),
    );
  }

  /// Remove o veículo e todos os abastecimentos associados.
  Future<void> deleteVehicleAndRefuels() async {
    final prefs = await _prefs;
    await prefs.remove(_vehicleKey);
    await prefs.remove(_refuelsKey);
  }
}
