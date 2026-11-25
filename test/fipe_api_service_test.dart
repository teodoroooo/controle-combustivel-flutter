import 'dart:convert';

import 'package:controle_combustivel/services/fipe_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('busca marcas e modelos (ordenados e sem duplicados)', () async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/marcas/v1/carros')) {
        return http.Response.bytes(
            utf8.encode(jsonEncode([
              {'nome': 'Volkswagen', 'valor': '59'},
              {'nome': 'Citroën', 'valor': '13'},
            ])),
            200);
      }
      expect(req.url.path, endsWith('/veiculos/v1/carros/59'));
      return http.Response(
          jsonEncode([
            {'modelo': 'Gol 1.0', 'valor': '2'},
            {'modelo': 'Fox 1.6', 'valor': '1'},
            {'modelo': 'Gol 1.0', 'valor': '2'},
          ]),
          200);
    });
    final api = FipeApiService(client: client);

    final brands = await api.fetchBrands();
    expect(brands.map((b) => b.name), ['Citroën', 'Volkswagen']);

    final models = await api.fetchModels('59');
    expect(models.map((m) => m.name), ['Fox 1.6', 'Gol 1.0']);
  });

  test('lança FipeApiException em erro HTTP', () async {
    final api =
        FipeApiService(client: MockClient((_) async => http.Response('', 500)));
    expect(api.fetchBrands(), throwsA(isA<FipeApiException>()));
  });
}
