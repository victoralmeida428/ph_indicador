import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';

abstract class IndicatorLocalDataSource {
  Future<void> insertIndicator(IndicatorModel indicator);
  Future<List<IndicatorModel>> getIndicators();
}