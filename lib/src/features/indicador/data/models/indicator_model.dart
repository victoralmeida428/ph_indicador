import 'package:ph_indicador/src/features/indicador/data/models/indicator_range_model.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

class IndicatorModel extends Indicator {
  IndicatorModel({
    required String id,
    required String name,
    required List<IndicatorRangeModel> ranges,
  }) : super(id: id, name: name, ranges: ranges);

  // Mapa para salvar na tabela 'indicators' (só tem id e nome)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Ao ler do banco, precisamos injetar a lista de ranges manualmente depois
  factory IndicatorModel.fromMap(Map<String, dynamic> map, List<IndicatorRangeModel> ranges) {
    return IndicatorModel(
      id: map['id'],
      name: map['name'],
      ranges: ranges,
    );
  }

  factory IndicatorModel.fromEntity(Indicator entity) {
    return IndicatorModel(
      id: entity.id,
      name: entity.name,
      ranges: entity.ranges.map((e) => IndicatorRangeModel.fromEntity(e)).toList(),
    );
  }

  Indicator toEntity() {
    return Indicator(id: id, name: name, ranges: ranges);
  }


}
