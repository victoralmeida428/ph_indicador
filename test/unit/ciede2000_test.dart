import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/features/analysis/domain/usecases/find_best_match_range_usecase.dart';

/// Valida a implementação do CIEDE2000 contra os 34 pares de teste oficiais
/// de Sharma, Wu & Dalal (2005), "The CIEDE2000 color-difference formula:
/// Implementation notes, supplementary test data, and mathematical
/// observations", Color Res Appl 30(1):21-30.
///
/// Fonte do dataset: https://www.ece.rochester.edu/~gsharma/ciede2000/
void main() {
  final useCase = FindBestMatchingRangeUseCase();

  final fixture = File('test/fixtures/ciede2000_standard_test_pairs.txt')
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .toList();

  group('CIEDE2000 contra o dataset de Sharma et al. (2005)', () {
    test('o dataset oficial contém 34 pares de teste', () {
      expect(fixture.length, 34);
    });

    for (var i = 0; i < fixture.length; i++) {
      final fields = fixture[i].split('\t');
      final lab1 = [
        double.parse(fields[0]),
        double.parse(fields[1]),
        double.parse(fields[2]),
      ];
      final lab2 = [
        double.parse(fields[3]),
        double.parse(fields[4]),
        double.parse(fields[5]),
      ];
      final expected = double.parse(fields[6]);

      test('par ${i + 1}: ΔE00($lab1, $lab2) = $expected', () {
        final actual = useCase.calculateCIEDE2000(lab1, lab2);
        expect(actual, closeTo(expected, 1e-4),
            reason: 'Par ${i + 1} do dataset oficial');
      });
    }
  });

  group('CIEDE2000 - comportamento do fator kL', () {
    final lab1 = [10.0, 50.0, 50.0];
    final lab2 = [80.0, 50.0, 50.0];

    test('kL = 1 (padrão) produz o valor completo', () {
      final dE1 = useCase.calculateCIEDE2000(lab1, lab2, kL: 1.0);
      final dEDefault = useCase.calculateCIEDE2000(lab1, lab2);
      expect(dEDefault, closeTo(dE1, 1e-9));
    });

    test('kL > 1 reduz o peso da diferença de luminosidade', () {
      final dE1 = useCase.calculateCIEDE2000(lab1, lab2, kL: 1.0);
      final dE2 = useCase.calculateCIEDE2000(lab1, lab2, kL: 2.0);
      expect(dE2, lessThan(dE1));
    });

    test('kL alto converge para 0 quando apenas a luminosidade difere', () {
      final dE = useCase.calculateCIEDE2000(lab1, lab2, kL: 1000.0);
      expect(dE, lessThan(0.1));
    });
  });
}