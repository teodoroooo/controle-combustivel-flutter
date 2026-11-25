/// Veículo cadastrado pelo usuário (apenas um por vez).
class Vehicle {
  const Vehicle({
    required this.brandCode,
    required this.brandName,
    required this.modelCode,
    required this.modelName,
    required this.year,
    required this.engineDisplacement,
  });

  /// Código da marca na tabela FIPE (BrasilAPI).
  final String brandCode;
  final String brandName;

  /// Código do modelo na tabela FIPE (BrasilAPI).
  final String modelCode;
  final String modelName;

  final int year;

  /// Cilindrada do motor em litros (ex.: 1.0, 1.6, 2.0).
  final double engineDisplacement;

  String get displayName => '$brandName $modelName';

  Map<String, dynamic> toJson() => {
        'brandCode': brandCode,
        'brandName': brandName,
        'modelCode': modelCode,
        'modelName': modelName,
        'year': year,
        'engineDisplacement': engineDisplacement,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        brandCode: json['brandCode'] as String,
        brandName: json['brandName'] as String,
        modelCode: json['modelCode'] as String,
        modelName: json['modelName'] as String,
        year: json['year'] as int,
        engineDisplacement: (json['engineDisplacement'] as num).toDouble(),
      );
}
