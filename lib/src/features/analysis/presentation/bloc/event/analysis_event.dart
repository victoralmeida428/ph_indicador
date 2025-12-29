import 'package:equatable/equatable.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();
  @override
  List<Object> get props => [];
}

// Evento: Tela abriu, carregar indicadores disponíveis
class LoadAvailableIndicatorsEvent extends AnalysisEvent {}

// Evento: Usuário selecionou um item no dropdown
class SelectIndicatorEvent extends AnalysisEvent {
  final Indicator indicator;
  const SelectIndicatorEvent(this.indicator);
}

// Evento: Foto tirada, iniciar análise
class AnalyzeImageEvent extends AnalysisEvent {
  final String imagePath;
  const AnalyzeImageEvent(this.imagePath);
}