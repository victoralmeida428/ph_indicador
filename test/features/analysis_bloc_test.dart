import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/core/settings/settings_keys.dart';
import 'package:ph_indicador/src/core/settings/settings_service.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/bloc/analysis_bloc.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/event/analysis_event.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/state/analysis_state.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/test_image_factory.dart';

void main() {
  late FakeIndicatorRepository repository;

  final range = IndicatorRange(
    id: 'r1',
    phMin: 6.0,
    phMax: 8.0,
    colorHex: const Color.fromARGB(255, 200, 100, 50).toARGB32(),
  );
  final indicator = Indicator(
    id: 'ind-1',
    name: 'Teste',
    ranges: [range],
  );
  final noRangesIndicator = Indicator(id: 'ind-2', name: 'Vazio', ranges: []);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      SettingsKeys.analysisTolerance: 10.0,
      SettingsKeys.analysisKL: 1.0,
      SettingsKeys.colorNormalization: false,
      SettingsKeys.matchingMode: 'ciede2000',
    });
    await SettingsService.init();
  });

  setUp(() {
    repository = FakeIndicatorRepository();
  });

  AnalysisBloc buildBloc() {
    return AnalysisBloc(
      indicatorRepository: repository,
      settingsService: SettingsService.instance,
    );
  }

  group('AnalysisBloc', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'estado inicial é AnalysisInitial',
      build: buildBloc,
      expect: () => [],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'carrega os indicadores disponíveis',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      act: (bloc) => bloc.add(LoadAvailableIndicatorsEvent()),
      expect: () => [
        isA<AnalysisLoadingIndicators>(),
        isA<AnalysisReady>()
            .having((s) => s.indicators, 'indicators', hasLength(1)),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'falha ao carregar emite AnalysisError',
      build: buildBloc,
      setUp: () => repository.throwOnLoad = true,
      act: (bloc) => bloc.add(LoadAvailableIndicatorsEvent()),
      expect: () => [
        isA<AnalysisLoadingIndicators>(),
        isA<AnalysisError>(),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'selecionar indicador atualiza o estado pronto',
      build: buildBloc,
      seed: () => AnalysisReady(indicators: [indicator]),
      act: (bloc) => bloc.add(SelectIndicatorEvent(indicator)),
      expect: () => [
        isA<AnalysisReady>()
            .having((s) => s.selectedIndicator?.id, 'selected', 'ind-1'),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'analisa a imagem e retorna a faixa correspondente',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      seed: () => AnalysisReady(
        indicators: [indicator],
        selectedIndicator: indicator,
      ),
      act: (bloc) async {
        final path = await TestImageFactory.createImage(
          width: 100,
          height: 100,
          centerColor: const Color.fromARGB(255, 200, 100, 50),
        );
        bloc.add(AnalyzeImageEvent(path));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<AnalysisAnalyzing>(),
        isA<AnalysisSuccess>()
            .having((s) => s.matchedRange.id, 'range', 'r1')
            .having(
              (s) => s.sampledColor,
              'sampledColor',
              const Color.fromARGB(255, 200, 100, 50),
            ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'sem correspondência emite erro e volta ao estado pronto',
      build: buildBloc,
      setUp: () async {
        await repository.saveIndicador(indicator);
      },
      seed: () => AnalysisReady(
        indicators: [indicator],
        selectedIndicator: indicator,
      ),
      act: (bloc) async {
        final path = await TestImageFactory.createImage(
          width: 100,
          height: 100,
          centerColor: const Color.fromARGB(255, 0, 0, 0),
        );
        bloc.add(AnalyzeImageEvent(path));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<AnalysisAnalyzing>(),
        isA<AnalysisError>(),
        isA<AnalysisReady>()
            .having((s) => s.selectedIndicator?.id, 'selected', 'ind-1'),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'indicador sem faixas emite erro sem entrar em AnalysisAnalyzing',
      build: buildBloc,
      seed: () => AnalysisReady(
        indicators: [noRangesIndicator],
        selectedIndicator: noRangesIndicator,
      ),
      act: (bloc) => bloc.add(AnalyzeImageEvent('/caminho/foto.png')),
      expect: () => [
        isA<AnalysisError>(),
        isA<AnalysisReady>(),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'sem indicador selecionado emite erro',
      build: buildBloc,
      seed: () => AnalysisReady(indicators: [indicator]),
      act: (bloc) => bloc.add(AnalyzeImageEvent('/caminho/foto.png')),
      expect: () => [
        isA<AnalysisError>(),
        isA<AnalysisReady>(),
      ],
    );
  });
}