/// Tipos de combustível aceitos no registro de abastecimento.
enum FuelType {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  const FuelType(this.label);
  final String label;
}

/// Um abastecimento (sempre considerado tanque cheio).
class Refuel {
  const Refuel({
    required this.id,
    required this.fuelType,
    required this.pricePerLiter,
    required this.odometer,
    required this.liters,
    required this.dateTime,
  });

  final String id;
  final FuelType fuelType;

  /// Preço por litro em reais.
  final double pricePerLiter;

  /// Quilometragem do veículo no momento do abastecimento.
  final double odometer;

  /// Quantidade de litros abastecidos.
  final double liters;

  final DateTime dateTime;

  /// Valor total = preço por litro × litros.
  double get totalPrice => pricePerLiter * liters;

  Refuel copyWith({
    FuelType? fuelType,
    double? pricePerLiter,
    double? odometer,
    double? liters,
    DateTime? dateTime,
  }) =>
      Refuel(
        id: id,
        fuelType: fuelType ?? this.fuelType,
        pricePerLiter: pricePerLiter ?? this.pricePerLiter,
        odometer: odometer ?? this.odometer,
        liters: liters ?? this.liters,
        dateTime: dateTime ?? this.dateTime,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fuelType': fuelType.name,
        'pricePerLiter': pricePerLiter,
        'odometer': odometer,
        'liters': liters,
        'dateTime': dateTime.toIso8601String(),
      };

  factory Refuel.fromJson(Map<String, dynamic> json) => Refuel(
        id: json['id'] as String,
        fuelType: FuelType.values.byName(json['fuelType'] as String),
        pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
        odometer: (json['odometer'] as num).toDouble(),
        liters: (json['liters'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime'] as String),
      );
}
