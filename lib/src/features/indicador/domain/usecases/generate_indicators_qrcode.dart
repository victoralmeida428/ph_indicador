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
          'ph_min': indicator.phMin,
          'ph_max': indicator.phMax,
          'color': indicator.colorHex,
        };
      }).toList();


      return jsonEncode(listaDeMapas);
    }
}