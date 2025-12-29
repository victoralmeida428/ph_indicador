import 'dart:convert';

import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';

class ImportIndicatorsFromJson {
  final IndicatorRepository repository;

  ImportIndicatorsFromJson(this.repository);

  Future<void> call(String jsonString) async {
    try {
      // 1. Decodifica o JSON para uma Lista de Mapas
      final List<dynamic> decodedList = jsonDecode(jsonString);

      // 2. Percorre cada item e converte para Entidade
      for (var item in decodedList) {
        final rangesMap = item['ranges'] as List<dynamic>;

        // Reconstrói as faixas
        final List<IndicatorRange> ranges = rangesMap.map((r) {
          return IndicatorRange(
            id: r['id'],
            phMin: (r['ph_min'] as num).toDouble(), // num garante int ou double
            phMax: (r['ph_max'] as num).toDouble(),
            colorHex: r['color_hex'],
          );
        }).toList();

        // Reconstrói o Indicador
        final indicator = Indicator(
          id: item['id'],
          name: item['name'],
          ranges: ranges,
        );

        // 3. Salva no repositório
        await repository.saveIndicador(indicator);
      }
    } catch (e) {
      throw QRCodeInvalid();
    }
  }
}