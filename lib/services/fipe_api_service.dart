import 'dart:convert';

import 'package:http/http.dart' as http;

/// Item simples (código + nome) retornado pela API FIPE.
class FipeItem {
  const FipeItem({required this.code, required this.name});

  final String code;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FipeItem && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);
}

class FipeApiException implements Exception {
  FipeApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Consulta marcas e modelos de carros na BrasilAPI (tabela FIPE).
///
/// Documentação: https://brasilapi.com.br/docs#tag/FIPE
class FipeApiService {
  FipeApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://brasilapi.com.br/api/fipe';

  final http.Client _client;

  /// GET /marcas/v1/carros
  Future<List<FipeItem>> fetchBrands() async {
    final data = await _get('$_baseUrl/marcas/v1/carros');
    return _sortedUnique(data.map((e) => FipeItem(
          code: e['valor'].toString(),
          name: e['nome'].toString(),
        )));
  }

  /// GET /veiculos/v1/carros/{codigoMarca}
  Future<List<FipeItem>> fetchModels(String brandCode) async {
    final data = await _get('$_baseUrl/veiculos/v1/carros/$brandCode');
    return _sortedUnique(data.map((e) => FipeItem(
          code: (e['valor'] ?? e['codigo'] ?? e['modelo']).toString(),
          name: e['modelo'].toString(),
        )));
  }

  Future<List<Map<String, dynamic>>> _get(String url) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw FipeApiException('Falha de conexão com a BrasilAPI.');
    }
    if (response.statusCode != 200) {
      throw FipeApiException(
          'BrasilAPI respondeu com status ${response.statusCode}.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw FipeApiException('Resposta inesperada da BrasilAPI.');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  List<FipeItem> _sortedUnique(Iterable<FipeItem> items) {
    final seen = <String>{};
    final list = items.where((i) => seen.add(i.name)).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
