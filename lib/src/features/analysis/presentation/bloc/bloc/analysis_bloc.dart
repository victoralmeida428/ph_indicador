import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/core/errors/failures.dart';
import 'package:ph_indicador/src/core/settings/settings_service.dart';
import 'package:ph_indicador/src/core/utils/image_color_extractor.dart';
import 'package:ph_indicador/src/features/analysis/domain/usecases/find_best_match_range_usecase.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/event/analysis_event.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/state/analysis_state.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final IndicatorRepository indicatorRepository;
  final SettingsService settingsService;

  AnalysisBloc({required this.indicatorRepository, required this.settingsService})
      : super(AnalysisInitial()) {
    on<LoadAvailableIndicatorsEvent>(_onLoadIndicators);
    on<SelectIndicatorEvent>(_onSelectIndicator);
    on<AnalyzeImageEvent>(_onAnalyzeImage);
  }

  Future<void> _onLoadIndicators(event, emit) async {
    emit(AnalysisLoadingIndicators());
    try {
      final indicators = await indicatorRepository.getAllIndicators();
      emit(AnalysisReady(indicators: indicators));
    } catch (e) {
      emit(const AnalysisError("Erro ao carregar indicadores disponíveis."));
    }
  }

  void _onSelectIndicator(
    SelectIndicatorEvent event,
    Emitter<AnalysisState> emit,
  ) {
    if (state is AnalysisReady) {
      final currentState = state as AnalysisReady;
      emit(currentState.copyWith(selectedIndicator: event.indicator));
    }
  }

  Future<void> _onAnalyzeImage(
    AnalyzeImageEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    if (state is! AnalysisReady) return;

    final currentState = state as AnalysisReady;
    final selectedIndicator = currentState.selectedIndicator;

    if (selectedIndicator == null || selectedIndicator.ranges.isEmpty) {
      emit(
        const AnalysisError("Indicador inválido ou sem faixas cadastradas."),
      );
      emit(currentState);
      return;
    }

    emit(AnalysisAnalyzing());

    try {
      final Color? sampledColor = await ImageColorExtractor.extractAverageColor(
        event.imagePath,
      );

      if (sampledColor == null) throw ImageExtractionException();

      final tolerance = settingsService.getAnalysisTolerance();
      final kL = settingsService.getAnalysisKL();
      final normalizeIntensity = settingsService.getColorNormalization();
      final matchingMode = settingsService.getMatchingMode();

      final findBestMatchRange = FindBestMatchingRangeUseCase(
        tolerance: tolerance,
        kL: kL,
        normalizeIntensity: normalizeIntensity,
        matchingMode: matchingMode,
      );
      final IndicatorRange closestRange = findBestMatchRange.call(
        sampleColor: sampledColor,
        ranges: selectedIndicator.ranges,
      );

      emit(
        AnalysisSuccess(matchedRange: closestRange, sampledColor: sampledColor),
      );

    } on NoColorMatchException catch (e) {
      const failure = NoColorMatchFailure();
      emit(AnalysisError(failure.message));
      emit(currentState);

    } on EmptyRangesException catch (e) {
      emit(AnalysisError("O padrão selecionado não possui faixas cadastradas."));
      emit(currentState);

    } on ImageExtractionException catch (e) {
      emit(AnalysisError("Erro ao ler imagem: ${e.message}"));
      emit(currentState);

    } catch (e) {
      emit(AnalysisError("Erro inesperado: $e"));
      emit(currentState);
    }
  }
}
