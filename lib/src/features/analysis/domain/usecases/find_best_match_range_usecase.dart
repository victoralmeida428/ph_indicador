import 'dart:math';
import 'dart:ui';

import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

class FindBestMatchingRangeUseCase {

  final double tolerance;

  FindBestMatchingRangeUseCase({this.tolerance = 100.0});

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
        bestRange = range;
      }
    }

    if (minDistance > tolerance) {
      throw NoColorMatchException();
    }

    return bestRange!;
  }

  double _calculateDistance(Color sampleColor, Color rangeColor) {
    final double rDiff = (sampleColor.r * 255.0).round().clamp(0, 255).toDouble() - (rangeColor.r * 255.0).round().clamp(0, 255).toDouble();
    final double gDiff = (sampleColor.g * 255.0).round().clamp(0, 255).toDouble() - (rangeColor.g * 255.0).round().clamp(0, 255).toDouble();
    final double bDiff = (sampleColor.b * 255.0).round().clamp(0, 255).toDouble() - (rangeColor.b * 255.0).round().clamp(0, 255).toDouble();

    final double distance = sqrt(pow(rDiff, 2) + pow(gDiff, 2) + pow(bDiff, 2));
    print(distance);
    return distance;
  }
}
