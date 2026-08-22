import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:ph_indicador/src/features/indicador/domain/usecases/generate_indicators_qrcode.dart';
import 'package:ph_indicador/src/features/indicador/domain/usecases/import_indicators_from_json.dart';

import '../helpers/fakes.dart';

void main() {
  final indicator = Indicator(
    id: 'ind-1',
    name: 'Papel Universal',
    ranges: [
      IndicatorRange(id: 'r1', phMin: 1.0, phMax: 3.0, colorHex: 0xFFFF0000),
      IndicatorRange(id: 'r2', phMin: 8.0, phMax: 10.0, colorHex: 0xFF0000FF),
    ],
  );

  group('GenerateIndicatorsQrCode', () {
    test('gera JSON com a estrutura esperada para exportação', () async {
      final repository = FakeIndicatorRepository();
      await repository.saveIndicador(indicator);

      final json = await GenerateIndicatorsQrCode(repository).call();
      final decoded = jsonDecode(json) as List<dynamic>;

      expect(decoded, hasLength(1));
      final item = decoded.first as Map<String, dynamic>;
      expect(item['id'], 'ind-1');
      expect(item['name'], 'Papel Universal');

      final ranges = item['ranges'] as List<dynamic>;
      expect(ranges, hasLength(2));
      final first = ranges.first as Map<String, dynamic>;
      expect(first['id'], 'r1');
      expect(first['ph_min'], 1.0);
      expect(first['ph_max'], 3.0);
      expect(first['color_hex'], 0xFFFF0000);
    });

    test('gera lista vazia quando não há indicadores', () async {
      final json = await GenerateIndicatorsQrCode(FakeIndicatorRepository()).call();
      expect(jsonDecode(json), isEmpty);
    });
  });

  group('ImportIndicatorsFromJson', () {
    test('importa indicadores válidos e persiste no repositório', () async {
      final repository = FakeIndicatorRepository();
      final json = jsonEncode([
        {
          'id': 'ind-1',
          'name': 'Papel Universal',
          'ranges': [
            {'id': 'r1', 'ph_min': 1.0, 'ph_max': 3.0, 'color_hex': 0xFFFF0000},
            {'id': 'r2', 'ph_min': 8.0, 'ph_max': 10.0, 'color_hex': 0xFF0000FF},
          ],
        },
      ]);

      await ImportIndicatorsFromJson(repository).call(json);

      expect(repository.stored, hasLength(1));
      final saved = repository.stored.single;
      expect(saved.id, 'ind-1');
      expect(saved.name, 'Papel Universal');
      expect(saved.ranges, hasLength(2));
      expect(saved.ranges.first.phMin, 1.0);
      expect(saved.ranges.last.colorHex, 0xFF0000FF);
    });

    test('round-trip: exportar e importar preserva os dados', () async {
      final source = FakeIndicatorRepository();
      await source.saveIndicador(indicator);

      final json = await GenerateIndicatorsQrCode(source).call();

      final target = FakeIndicatorRepository();
      await ImportIndicatorsFromJson(target).call(json);

      expect(target.stored, hasLength(1));
      expect(target.stored.single.name, 'Papel Universal');
      expect(target.stored.single.ranges, hasLength(2));
    });

    test('JSON inválido lança QRCodeInvalid', () async {
      await expectLater(
        ImportIndicatorsFromJson(FakeIndicatorRepository()).call('isto não é json'),
        throwsA(isA<QRCodeInvalid>()),
      );
    });

    test('JSON sem o campo ranges lança QRCodeInvalid', () async {
      await expectLater(
        ImportIndicatorsFromJson(FakeIndicatorRepository()).call('[{"id": "1"}]'),
        throwsA(isA<QRCodeInvalid>()),
      );
    });
  });
}