import 'package:ph_indicador/src/features/indicador/data/datasources/indicator_local_datasource.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';
import 'package:sqflite/sqflite.dart';

class IndicatorLocalDataSourceImpl implements IndicatorLocalDataSource {
  final Database database;

  IndicatorLocalDataSourceImpl(this.database);

  @override
  Future<List<IndicatorModel>> getIndicators() async {
    final List<Map<String, dynamic>> maps = await database.query('indicators');

    // Converte a lista de Maps que o banco devolve para lista de IndicatorModel
    return List.generate(maps.length, (i) {
      return IndicatorModel.fromMap(maps[i]);
    });
  }

  @override
  Future<void> insertIndicator(IndicatorModel indicator) async {
    await database.insert(
      'indicator',
      indicator.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
