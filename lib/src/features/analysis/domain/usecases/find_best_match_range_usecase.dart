import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' hide Color;
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

class FindBestMatchingRangeUseCase {

  final double tolerance;

  FindBestMatchingRangeUseCase({this.tolerance = 5});

  IndicatorRange call({
    required Color sampleColor,
    required List<IndicatorRange> ranges,
  }) {
    if (ranges.isEmpty) {
        throw EmptyRangesException();
    }
    IndicatorRange? bestRange;
    double minDistance = double.infinity;

    for (var range in ranges) {
      final Color rangeColor = Color(range.colorHex);
      final double distance = _calculateDistance(sampleColor, rangeColor);
      if (distance < minDistance) {
        minDistance = distance;
        print("Distancia: "+distance.toStringAsFixed(2));
        print("Cor Lida da Câmera -> R: ${sampleColor.red}, G: ${sampleColor.green}, B: ${sampleColor.blue}");
        bestRange = range;
      }
    }

    if (minDistance > tolerance) {
      throw NoColorMatchException();
    }

    print("--- RESULTADO ---");
    print("Cor Lida: R${sampleColor.red} G${sampleColor.green} B${sampleColor.blue}");
    print("Range Vencedor (Nome/ID): ${bestRange?.id!}"); // ou .name
    print("Hex do Vencedor: 0x${bestRange?.colorHex.toRadixString(16).toUpperCase()}");
    print("Distância: $minDistance");
    print("-----------------");

    return bestRange!;
  }


  double _calculateDistance(Color sampleColor, Color rangeColor) {
    var labAmostra = rgbToLab(
        sampleColor.r * 255,
        sampleColor.g * 255,
        sampleColor.b * 255
    );

    var labPadrao = rgbToLab(
        rangeColor.r * 255,
        rangeColor.g * 255,
        rangeColor.b * 255
    );
    return calculateCIEDE2000(labAmostra, labPadrao);
  }

  /// Calcula a diferença de cor CIEDE2000 entre duas cores LAB.
  ///
  /// [lab1] e [lab2] devem ser listas de 3 elementos [L, a, b].
  /// Retorna o Delta E (double).
  double calculateCIEDE2000(List<num> lab1, List<num> lab2) {
    // Extraindo L, a, b
    double L1 = lab1[0].toDouble();
    double a1 = lab1[1].toDouble();
    double b1 = lab1[2].toDouble();

    double L2 = lab2[0].toDouble();
    double a2 = lab2[1].toDouble();
    double b2 = lab2[2].toDouble();

    // Constantes de peso (geralmente 1 para aplicações padrão)
    const double kL = 1.0;
    const double kC = 1.0;
    const double kH = 1.0;

    // 1. Calcular C (Chroma) e G (fator de ajuste para o eixo a)
    double C1 = sqrt(pow(a1, 2) + pow(b1, 2));
    double C2 = sqrt(pow(a2, 2) + pow(b2, 2));
    double C_bar = (C1 + C2) / 2.0;

    double G = 0.5 * (1 - sqrt(pow(C_bar, 7) / (pow(C_bar, 7) + pow(25, 7))));

    // 2. Calcular a', C' e h'
    double a1_prime = (1 + G) * a1;
    double a2_prime = (1 + G) * a2;

    double C1_prime = sqrt(pow(a1_prime, 2) + pow(b1, 2));
    double C2_prime = sqrt(pow(a2_prime, 2) + pow(b2, 2));

    // Calcular ângulos de matiz (hue) h'
    double h1_prime = _getHueAngle(a1_prime, b1);
    double h2_prime = _getHueAngle(a2_prime, b2);

    // 3. Calcular diferenças Delta L', Delta C' e Delta H'
    double deltaL_prime = L2 - L1;
    double deltaC_prime = C2_prime - C1_prime;

    double deltah_prime;
    if (C1_prime * C2_prime == 0) {
      deltah_prime = 0;
    } else {
      if ((h2_prime - h1_prime).abs() <= 180) {
        deltah_prime = h2_prime - h1_prime;
      } else {
        if (h2_prime - h1_prime > 180) {
          deltah_prime = h2_prime - h1_prime - 360;
        } else {
          deltah_prime = h2_prime - h1_prime + 360;
        }
      }
    }

    double deltaH_prime = 2 * sqrt(C1_prime * C2_prime) * sin(_degreesToRadians(deltah_prime / 2));

    // 4. Calcular médias para as funções de peso
    double L_bar_prime = (L1 + L2) / 2;
    double C_bar_prime = (C1_prime + C2_prime) / 2;

    double h_bar_prime;
    if (C1_prime * C2_prime == 0) {
      h_bar_prime = h1_prime + h2_prime;
    } else {
      if ((h1_prime - h2_prime).abs() <= 180) {
        h_bar_prime = (h1_prime + h2_prime) / 2;
      } else {
        if ((h1_prime + h2_prime) < 360) {
          h_bar_prime = (h1_prime + h2_prime + 360) / 2;
        } else {
          h_bar_prime = (h1_prime + h2_prime - 360) / 2;
        }
      }
    }

    // 5. Calcular Funções de Peso (SL, SC, SH) e T
    double T = 1 -
        0.17 * cos(_degreesToRadians(h_bar_prime - 30)) +
        0.24 * cos(_degreesToRadians(2 * h_bar_prime)) +
        0.32 * cos(_degreesToRadians(3 * h_bar_prime + 6)) -
        0.20 * cos(_degreesToRadians(4 * h_bar_prime - 63));

    double SL = 1 + ((0.015 * pow(L_bar_prime - 50, 2)) / sqrt(20 + pow(L_bar_prime - 50, 2)));
    double SC = 1 + 0.045 * C_bar_prime;
    double SH = 1 + 0.015 * C_bar_prime * T;

    // 6. Calcular termo de rotação RT (correção para a região azul)
    double deltaTheta = 30 * exp(-pow((h_bar_prime - 275) / 25, 2));
    double RC = 2 * sqrt(pow(C_bar_prime, 7) / (pow(C_bar_prime, 7) + pow(25, 7)));
    double RT = -sin(_degreesToRadians(2 * deltaTheta)) * RC;

    // 7. Fórmula Final CIEDE2000
    return sqrt(
        pow(deltaL_prime / (kL * SL), 2) +
            pow(deltaC_prime / (kC * SC), 2) +
            pow(deltaH_prime / (kH * SH), 2) +
            RT * (deltaC_prime / (kC * SC)) * (deltaH_prime / (kH * SH))
    );
  }

// --- Funções Auxiliares ---

  double _getHueAngle(double a, double b) {
    if (a == 0 && b == 0) return 0;
    double angle = _radiansToDegrees(atan2(b, a));
    if (angle < 0) angle += 360;
    return angle;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double _radiansToDegrees(double radians) {
    return radians * 180 / pi;
  }
}
