import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/analysis/domain/usecases/find_best_match_range_usecase.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

void main() {
  IndicatorRange range({
    String id = 'r1',
    double phMin = 4,
    double phMax = 5,
    int colorHex = 0xFF00FF00,
  }) {
    return IndicatorRange(id: id, phMin: phMin, phMax: phMax, colorHex: colorHex);
  }

  group('FindBestMatchingRangeUseCase.call', () {
    test('retorna a faixa com menor ΔE quando dentro da tolerância', () {
      final ranges = [
        range(id: 'verde', colorHex: 0xFF00FF00),
        range(id: 'azul', colorHex: 0xFF0000FF),
        range(id: 'vermelho', colorHex: 0xFFFF0000),
      ];

      final result = FindBestMatchingRangeUseCase(tolerance: 10).call(
        sampleColor: const Color(0xFF00FF00),
        ranges: ranges,
      );

      expect(result.id, 'verde');
    });

    test('desempate: cores idênticas retornam a primeira faixa da lista', () {
      final ranges = [
        range(id: 'primeira', colorHex: 0xFF112233),
        range(id: 'segunda', colorHex: 0xFF112233),
      ];

      final result = FindBestMatchingRangeUseCase(tolerance: 10).call(
        sampleColor: const Color(0xFF112233),
        ranges: ranges,
      );

      expect(result.id, 'primeira');
    });

    test('lança NoColorMatchException quando a distância excede a tolerância', () {
      final ranges = [range(colorHex: 0xFF00FF00)];

      expect(
        () => FindBestMatchingRangeUseCase(tolerance: 1).call(
          sampleColor: const Color(0xFFFF0000),
          ranges: ranges,
        ),
        throwsA(isA<NoColorMatchException>()),
      );
    });

    test('lança EmptyRangesException para lista vazia', () {
      expect(
        () => FindBestMatchingRangeUseCase().call(
          sampleColor: const Color(0xFF00FF00),
          ranges: [],
        ),
        throwsA(isA<EmptyRangesException>()),
      );
    });
  });

  group('Normalização de intensidade', () {
    // Mesmas proporções RGB, intensidade dobrada
    final dimColor = const Color(0xFF3C5A78); // (60, 90, 120)
    final brightColor = const Color(0xFF78B4F0); // (120, 180, 240)

    test('com normalização, amostra mais brilhante casa com a faixa', () {
      final ranges = [range(colorHex: dimColor.toARGB32())];

      final result = FindBestMatchingRangeUseCase(
        tolerance: 1,
        normalizeIntensity: true,
      ).call(sampleColor: brightColor, ranges: ranges);

      expect(result.id, 'r1');
    });

    test('sem normalização, a mesma amostra não casa com tolerância 1', () {
      final ranges = [range(colorHex: dimColor.toARGB32())];

      expect(
        () => FindBestMatchingRangeUseCase(tolerance: 1).call(
          sampleColor: brightColor,
          ranges: ranges,
        ),
        throwsA(isA<NoColorMatchException>()),
      );
    });
  });

  group('Modo cromaticidade', () {
    // Cinzas neutros: a* = b* = 0, diferindo apenas na luminosidade
    final gray50 = const Color(0xFF323232); // (50, 50, 50)
    final gray150 = const Color(0xFF969696); // (150, 150, 150)

    test('ignora a luminosidade: cinzas diferentes casam com tolerância 1', () {
      final ranges = [range(colorHex: gray50.toARGB32())];

      final result = FindBestMatchingRangeUseCase(
        tolerance: 1,
        matchingMode: 'chromaticity',
      ).call(sampleColor: gray150, ranges: ranges);

      expect(result.id, 'r1');
    });

    test('CIEDE2000 padrão rejeita a mesma dupla com tolerância 1', () {
      final ranges = [range(colorHex: gray50.toARGB32())];

      expect(
        () => FindBestMatchingRangeUseCase(tolerance: 1).call(
          sampleColor: gray150,
          ranges: ranges,
        ),
        throwsA(isA<NoColorMatchException>()),
      );
    });
  });
}