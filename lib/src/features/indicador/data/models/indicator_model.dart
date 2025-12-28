import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

class IndicatorModel extends Indicator {
  IndicatorModel({
    required super.id,
    required super.name,
    required super.phMin,
    required super.phMax,
    required super.colorHex,
  });

  factory IndicatorModel.fromMap(Map<String, dynamic> map) {
    return IndicatorModel(
      id: map['id'],
      name: map['name'],
      phMin: map['phMin'],
      phMax: map['phMax'],
      colorHex: map['colorHex'],
    );
  }

  factory IndicatorModel.fromEntity(Indicator indicator) {
    return IndicatorModel(
      id: indicator.id,
      name: indicator.name,
      phMin: indicator.phMin,
      phMax: indicator.phMax,
      colorHex: indicator.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "name": this.name,
      "phMin": this.phMin,
      "phMax": this.phMax,
      "colorHex": this.colorHex,
    };
  }

  Indicator toEntity() {
    return Indicator(
      id: id,
      name: name,
      colorHex: colorHex,
      phMax: phMax,
      phMin: phMin,
    );
  }
}
