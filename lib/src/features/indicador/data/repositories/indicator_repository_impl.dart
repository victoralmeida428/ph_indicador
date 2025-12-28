import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/core/errors/failures.dart';
import 'package:ph_indicador/src/features/indicador/data/datasources/indicator_local_datasource.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';

class IndicatorRepositoryImpl implements IndicatorRepository {
  final IndicatorLocalDataSource db;

  IndicatorRepositoryImpl({required this.db});


  @override
  Future<List<Indicator>> getAllIndicators() async {
    try {
      final models = await db.getIndicators();
      return models.map((e)=>e.toEntity()).toList();
    } on LocalDatabaseException catch (e) {
      throw DatabaseFailure(message: e.message);
    } catch (e) {
      throw DatabaseFailure(message: "Erro desconhecido ao carregar indicador");
    }
  }

  @override
  Future<void> saveIndicador(Indicator indicator) async {
    try {
      return db.insertIndicator(IndicatorModel.fromEntity(indicator));
    } on LocalDatabaseException catch(e) {
      throw DatabaseFailure(message: "Não foi possível salvar: ${e.message}");
    }
  }


}