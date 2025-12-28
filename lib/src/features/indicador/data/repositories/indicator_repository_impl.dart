import 'package:ph_indicador/src/features/indicador/data/datasources/indicator_local_datasource.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';

class IndicatorRepositoryImpl implements IndicatorRepository {
  final IndicatorLocalDataSource db;

  IndicatorRepositoryImpl({required this.db});


  @override
  Future<List<Indicator>> getAllIndicators() async {
    final models = await db.getIndicators();
    return models.map((e)=>e.toEntity()).toList();
  }

  @override
  Future<void> saveIndicador(Indicator indicator) async {
    return db.insertIndicator(IndicatorModel.fromEntity(indicator));
  }


}