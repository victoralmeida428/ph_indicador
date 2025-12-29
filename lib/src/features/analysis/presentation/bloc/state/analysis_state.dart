import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';

abstract class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

class AnalysisInitial extends AnalysisState {}

class AnalysisLoadingIndicators extends AnalysisState {}

class AnalysisReady extends AnalysisState {
  final List<Indicator> indicators;
  final Indicator? selectedIndicator; // O indicador escolhido no dropdown

  const AnalysisReady({
    required this.indicators,
    this.selectedIndicator,
  });

  AnalysisReady copyWith({
    List<Indicator>? indicators,
    Indicator? selectedIndicator,
  }) {
    return AnalysisReady(
      indicators: indicators ?? this.indicators,
      selectedIndicator: selectedIndicator ?? this.selectedIndicator,
    );
  }

  @override
  List<Object?> get props => [indicators, selectedIndicator];
}

// Processando a imagem (extraindo cor e calculando pH)
class AnalysisAnalyzing extends AnalysisState {}

// Sucesso na análise
class AnalysisSuccess extends AnalysisState {
  final IndicatorRange matchedRange; // A faixa vencedora
  final Color sampledColor;          // A cor que a câmera leu

  const AnalysisSuccess({
    required this.matchedRange,
    required this.sampledColor
  });

  @override
  List<Object?> get props => [matchedRange, sampledColor];
}

// Erro
class AnalysisError extends AnalysisState {
  final String message;
  const AnalysisError(this.message);
  @override
  List<Object?> get props => [message];
}