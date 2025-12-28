import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_range_model.dart';
import 'package:sqflite/sqflite.dart';
import 'indicator_local_datasource.dart';

class IndicatorLocalDataSourceImpl implements IndicatorLocalDataSource {
  final Database database;

  IndicatorLocalDataSourceImpl(this.database);

  @override
  Future<void> insertIndicator(IndicatorModel indicator) async {
    try {
      // Usamos 'transaction' para garantir que tudo salva ou nada salva
      await database.transaction((txn) async {

        // 1. Salva o Pai (Tabela indicators)
        await txn.insert(
          'indicators',
          indicator.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          'indicator_ranges',
          where: 'indicator_id=?',
          whereArgs: [indicator.id]
        );

        // 2. Salva os Filhos (Tabela indicator_ranges)
        final batch = txn.batch(); // Batch otimiza inserções múltiplas
        for (var range in indicator.ranges) {
          // Precisamos converter o Model passando o ID do Pai
          final rangeMap = (range as IndicatorRangeModel).toMap(indicator.id);
          batch.insert(
            'indicator_ranges',
            rangeMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw LocalDatabaseException("Erro ao salvar indicador com faixas: $e");
    }
  }

  @override
  Future<List<IndicatorModel>> getIndicators() async {
    try {
      // 1. Busca todos os Indicadores (Pais)
      final List<Map<String, dynamic>> indicatorMaps = await database.query('indicators');

      List<IndicatorModel> resultList = [];

      // 2. Para cada indicador, busca suas faixas (Filhos)
      for (var iMap in indicatorMaps) {
        final String indicatorId = iMap['id'];

        // Busca as faixas deste ID específico
        final List<Map<String, dynamic>> rangeMaps = await database.query(
          'indicator_ranges',
          where: 'indicator_id = ?',
          whereArgs: [indicatorId],
          orderBy: 'ph_min ASC',
        );

        // Converte as faixas
        final rangesList = rangeMaps
            .map((rMap) => IndicatorRangeModel.fromMap(rMap))
            .toList();

        // Cria o objeto completo
        resultList.add(IndicatorModel.fromMap(iMap, rangesList));
      }

      return resultList;
    } catch (e) {
      throw LocalDatabaseException("Erro ao listar indicadores: $e");
    }
  }

  @override
  Future<void> deleteIndicator(String id) async {
    try {
      await database.delete(
        'indicators',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException("Erro ao deletar indicador: $e");
    }
  }
}
