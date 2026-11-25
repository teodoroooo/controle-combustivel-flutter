import 'package:flutter/widgets.dart';

import '../models/refuel.dart';
import '../models/refuel_stats.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

/// Estado global do app: veículo atual e seus abastecimentos.
class AppController extends ChangeNotifier {
  AppController({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;

  Vehicle? _vehicle;
  List<Refuel> _refuels = [];
  bool _loading = true;

  Vehicle? get vehicle => _vehicle;
  bool get hasVehicle => _vehicle != null;
  bool get loading => _loading;

  /// Abastecimentos em ordem cronológica.
  List<Refuel> get refuels => RefuelStats.sortRefuels(_refuels);

  /// Indicadores calculados (ordem cronológica).
  List<RefuelStats> get stats => RefuelStats.compute(_refuels);

  DashboardSummary get summary => DashboardSummary.fromStats(stats);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _vehicle = await _storage.loadVehicle();
    _refuels = _vehicle == null ? [] : await _storage.loadRefuels();
    _loading = false;
    notifyListeners();
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    if (_vehicle != null) {
      throw StateError('Exclua o veículo atual antes de cadastrar outro.');
    }
    await _storage.saveVehicle(vehicle);
    _vehicle = vehicle;
    _refuels = [];
    await _storage.saveRefuels(_refuels);
    notifyListeners();
  }

  /// Exclui o veículo e, junto, todos os abastecimentos dele.
  Future<void> deleteVehicle() async {
    await _storage.deleteVehicleAndRefuels();
    _vehicle = null;
    _refuels = [];
    notifyListeners();
  }

  /// Verifica se a quilometragem é coerente com os abastecimentos
  /// anteriores/posteriores. Retorna mensagem de erro ou `null`.
  String? validateOdometer(Refuel candidate) {
    final others = _refuels.where((r) => r.id != candidate.id).toList();
    final ordered = RefuelStats.sortRefuels([...others, candidate]);
    final index = ordered.indexWhere((r) => r.id == candidate.id);
    if (index > 0 && candidate.odometer <= ordered[index - 1].odometer) {
      return 'A quilometragem deve ser maior que '
          '${ordered[index - 1].odometer.toStringAsFixed(0)} km '
          '(abastecimento anterior).';
    }
    if (index < ordered.length - 1 &&
        candidate.odometer >= ordered[index + 1].odometer) {
      return 'A quilometragem deve ser menor que '
          '${ordered[index + 1].odometer.toStringAsFixed(0)} km '
          '(abastecimento seguinte).';
    }
    return null;
  }

  /// Adiciona ou atualiza um abastecimento.
  Future<void> upsertRefuel(Refuel refuel) async {
    if (_vehicle == null) {
      throw StateError('Cadastre um veículo antes de registrar abastecimentos.');
    }
    final error = validateOdometer(refuel);
    if (error != null) throw ArgumentError(error);
    _refuels = [..._refuels.where((r) => r.id != refuel.id), refuel];
    await _storage.saveRefuels(_refuels);
    notifyListeners();
  }

  Future<void> deleteRefuel(String id) async {
    _refuels = _refuels.where((r) => r.id != id).toList();
    await _storage.saveRefuels(_refuels);
    notifyListeners();
  }
}

/// Disponibiliza o [AppController] para a árvore de widgets.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
