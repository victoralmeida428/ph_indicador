import 'dart:convert';

import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';

class GenerateIndicatorsQrCode {
  final IndicatorRepository repository;

  GenerateIndicatorsQrCode(this.repository);

  Future<String> call() async {
    final indicators = await repository.getAllIndicators();

    final List<Map<String, dynamic>> listaDeMapas = indicators.map((indicator) {
      return {
        'id': indicator.id,
        'name': indicator.name,
        'ranges': indicator.ranges
            .map(
              (e) => {
                'id': e.id,
                'ph_min': e.phMin,
                'ph_max': e.phMax,
                'color_hex': e.colorHex,
              },
            )
            .toList(),
      };
    }).toList();

    return jsonEncode(listaDeMapas);
  }
}
