
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

class IndicatorRangeModel extends IndicatorRange {
  IndicatorRangeModel({
    required String id,
    required double phMin,
    required double phMax,
    required int colorHex,
  }) : super(id: id, phMin: phMin, phMax: phMax, colorHex: colorHex);

  // Mapa para o banco (inclui a chave estrangeira indicator_id)
  Map<String, dynamic> toMap(String indicatorId) {
    return {
      'id': id,
      'indicator_id': indicatorId, // Chave estrangeira
      'ph_min': phMin,
      'ph_max': phMax,
      'color_hex': colorHex,
    };
  }

  factory IndicatorRangeModel.fromMap(Map<String, dynamic> map) {
    return IndicatorRangeModel(
      id: map['id'],
      phMin: map['ph_min'],
      phMax: map['ph_max'],
      colorHex: map['color_hex'],
    );
  }

  factory IndicatorRangeModel.fromEntity(IndicatorRange entity) {
    return IndicatorRangeModel(
      id: entity.id,
      phMin: entity.phMin,
      phMax: entity.phMax,
      colorHex: entity.colorHex,
    );
  }
}