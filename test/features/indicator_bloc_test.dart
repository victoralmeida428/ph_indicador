import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/bloc/indicator_bloc.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeIndicatorRepository repository;

  final indicator = Indicator(
    id: 'ind-1',
    name: 'Papel Universal',
    ranges: [
      IndicatorRange(id: 'r1', phMin: 1.0, phMax: 3.0, colorHex: 0xFFFF0000),
    ],
  );

  setUp(() {
    repository = FakeIndicatorRepository();
  });

  IndicatorBloc buildBloc() => IndicatorBloc(repository: repository);

  group('IndicatorBloc', () {
    blocTest<IndicatorBloc, IndicatorState>(
      'estado inicial é IndicatorInitial',
      build: buildBloc,
      expect: () => [],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'carrega lista vazia',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadIndicatorsEvent()),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorLoaded>().having((s) => s.indicators, 'indicators', isEmpty),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'carrega indicadores salvos',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      act: (bloc) => bloc.add(LoadIndicatorsEvent()),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorLoaded>().having((s) => s.indicators, 'indicators', hasLength(1)),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'erro ao carregar emite IndicatorError',
      build: buildBloc,
      setUp: () => repository.throwOnLoad = true,
      act: (bloc) => bloc.add(LoadIndicatorsEvent()),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorError>(),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'adiciona indicador e recarrega a lista',
      build: buildBloc,
      act: (bloc) => bloc.add(AddIndicatorEvent(indicator)),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorSuccess>(),
        isA<IndicatorLoading>(),
        isA<IndicatorLoaded>().having((s) => s.indicators, 'indicators', hasLength(1)),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'atualiza indicador',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      act: (bloc) => bloc.add(
        UpdateIndicatorEvent(
          Indicator(id: 'ind-1', name: 'Renomeado', ranges: indicator.ranges),
        ),
      ),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorSuccess>(),
        isA<IndicatorLoading>(),
        isA<IndicatorLoaded>().having(
          (s) => s.indicators.single.name,
          'name',
          'Renomeado',
        ),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'deleta indicador',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      act: (bloc) => bloc.add(DeleteIndicatorEvent('ind-1')),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorSuccess>(),
        isA<IndicatorLoading>(),
        isA<IndicatorLoaded>().having((s) => s.indicators, 'indicators', isEmpty),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'gera o QR Code com o JSON dos indicadores',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      act: (bloc) => bloc.add(GenerateQrCodeEvent()),
      expect: () => [
        isA<IndicatorQrGenerated>().having(
          (s) => s.qrData,
          'qrData',
          contains('Papel Universal'),
        ),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'importa JSON válido e recarrega a lista',
      build: buildBloc,
      act: (bloc) => bloc.add(
        ImportIndicatorsEvent(
          '[{"id":"ind-9","name":"Importado","ranges":['
          '{"id":"r9","ph_min":4.0,"ph_max":5.0,"color_hex":4278255360}]}]',
        ),
      ),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorLoaded>()
            .having((s) => s.indicators.single.name, 'name', 'Importado'),
      ],
    );

    blocTest<IndicatorBloc, IndicatorState>(
      'importa JSON inválido e emite IndicatorError',
      build: buildBloc,
      act: (bloc) => bloc.add(ImportIndicatorsEvent('json inválido')),
      expect: () => [
        isA<IndicatorLoading>(),
        isA<IndicatorError>(),
      ],
    );
  });
}