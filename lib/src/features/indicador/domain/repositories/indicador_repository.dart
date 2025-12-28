import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

abstract class IndicatorRepository {
  Future<void> saveIndicador(Indicator indicador);
  Future<List<Indicator>> getAllIndicators();
}