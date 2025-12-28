import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

class Indicator {
  final String id;
  final String name;
  final List<IndicatorRange> ranges;

  Indicator({
    required this.id,
    required this.name,
    required this.ranges,
  });
}
