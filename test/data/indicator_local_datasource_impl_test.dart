import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/features/indicador/data/datasources/indicator_local_datasource_impl.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_model.dart';
import 'package:ph_indicador/src/features/indicador/data/models/indicator_range_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late IndicatorLocalDataSourceImpl datasource;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE indicators (
              id TEXT PRIMARY KEY,
              name TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE indicator_ranges (
              id TEXT PRIMARY KEY,
              indicator_id TEXT,
              ph_min REAL,
              ph_max REAL,
              color_hex INTEGER,
              FOREIGN KEY (indicator_id) REFERENCES indicators (id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
    datasource = IndicatorLocalDataSourceImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  IndicatorModel buildIndicator({
    String id = 'ind-1',
    String name = 'Papel Universal',
    List<IndicatorRangeModel> ranges = const [],
  }) {
    return IndicatorModel(id: id, name: name, ranges: ranges);
  }

  IndicatorRangeModel buildRange({
    String id = 'r1',
    double phMin = 1.0,
    double phMax = 3.0,
    int colorHex = 0xFFFF0000,
  }) {
    return IndicatorRangeModel(
      id: id,
      phMin: phMin,
      phMax: phMax,
      colorHex: colorHex,
    );
  }

  group('IndicatorLocalDataSourceImpl', () {
    test('insere indicador com faixas em transação única', () async {
      final indicator = buildIndicator(ranges: [
        buildRange(id: 'r1'),
        buildRange(id: 'r2', phMin: 8.0, phMax: 10.0, colorHex: 0xFF0000FF),
      ]);

      await datasource.insertIndicator(indicator);

      final results = await datasource.getIndicators();
      expect(results, hasLength(1));
      expect(results.single.name, 'Papel Universal');
      expect(results.single.ranges, hasLength(2));
    });

    test('lista as faixas ordenadas por ph_min', () async {
      final indicator = buildIndicator(ranges: [
        buildRange(id: 'r-alto', phMin: 8.0, phMax: 10.0, colorHex: 0xFF0000FF),
        buildRange(id: 'r-baixo', phMin: 1.0, phMax: 3.0, colorHex: 0xFFFF0000),
      ]);

      await datasource.insertIndicator(indicator);

      final results = await datasource.getIndicators();
      final phs = results.single.ranges.map((r) => r.phMin).toList();
      expect(phs, [1.0, 8.0]);
    });

    test('salvar o mesmo id substitui indicador e faixas (update)', () async {
      await datasource.insertIndicator(
        buildIndicator(ranges: [buildRange(id: 'r1')]),
      );

      await datasource.insertIndicator(
        buildIndicator(
          name: 'Papel Universal v2',
          ranges: [buildRange(id: 'r2', phMin: 5.0, phMax: 6.0)],
        ),
      );

      final results = await datasource.getIndicators();
      expect(results, hasLength(1));
      expect(results.single.name, 'Papel Universal v2');
      expect(results.single.ranges, hasLength(1));
      expect(results.single.ranges.single.id, 'r2');
    });

    test('deletar o indicador remove as faixas em cascata', () async {
      await datasource.insertIndicator(
        buildIndicator(ranges: [buildRange(id: 'r1'), buildRange(id: 'r2')]),
      );

      await datasource.deleteIndicator('ind-1');

      final results = await datasource.getIndicators();
      expect(results, isEmpty);

      final orphanRanges = await database.query('indicator_ranges');
      expect(orphanRanges, isEmpty);
    });

    test('erro no banco lança LocalDatabaseException', () async {
      await database.close();

      await expectLater(
        datasource.insertIndicator(
          buildIndicator(ranges: [buildRange(id: 'r1')]),
        ),
        throwsA(isA<LocalDatabaseException>()),
      );
    });
  });
}