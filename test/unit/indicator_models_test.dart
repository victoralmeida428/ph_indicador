import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_range_model.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

void main() {
  const indicatorId = 'ind-1';
  final range = IndicatorRange(
    id: 'range-1',
    phMin: 4.0,
    phMax: 6.5,
    colorHex: 0xFFAABBCC,
  );

  group('IndicatorRangeModel', () {
    test('toMap inclui a chave estrangeira indicator_id', () {
      final model = IndicatorRangeModel.fromEntity(range);

      final map = model.toMap(indicatorId);

      expect(map, {
        'id': 'range-1',
        'indicator_id': indicatorId,
        'ph_min': 4.0,
        'ph_max': 6.5,
        'color_hex': 0xFFAABBCC,
      });
    });

    test('fromMap reconstrói o modelo a partir do banco', () {
      final model = IndicatorRangeModel.fromMap({
        'id': 'range-1',
        'indicator_id': indicatorId,
        'ph_min': 4.0,
        'ph_max': 6.5,
        'color_hex': 0xFFAABBCC,
      });

      expect(model.id, 'range-1');
      expect(model.phMin, 4.0);
      expect(model.phMax, 6.5);
      expect(model.colorHex, 0xFFAABBCC);
    });
  });

  group('IndicatorModel', () {
    final indicator = Indicator(
      id: indicatorId,
      name: 'Azul de Bromotimol',
      ranges: [range],
    );

    test('toMap persiste apenas id e nome', () {
      final map = IndicatorModel.fromEntity(indicator).toMap();

      expect(map, {'id': indicatorId, 'name': 'Azul de Bromotimol'});
    });

    test('fromMap injeta as faixas lidas do banco', () {
      final model = IndicatorModel.fromMap(
        {'id': indicatorId, 'name': 'Azul de Bromotimol'},
        [IndicatorRangeModel.fromEntity(range)],
      );

      expect(model.id, indicatorId);
      expect(model.name, 'Azul de Bromotimol');
      expect(model.ranges, hasLength(1));
      expect(model.ranges.first.phMin, 4.0);
    });

    test('toEntity preserva id, nome e faixas', () {
      final entity = IndicatorModel.fromEntity(indicator).toEntity();

      expect(entity.id, indicatorId);
      expect(entity.name, 'Azul de Bromotimol');
      expect(entity.ranges.single.colorHex, 0xFFAABBCC);
    });
  });
}