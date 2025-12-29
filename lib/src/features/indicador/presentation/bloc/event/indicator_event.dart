import 'package:equatable/equatable.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

abstract class IndicatorEvent extends Equatable {
  const IndicatorEvent();

  @override
  List<Object> get props => [];
}

// Evento: Usuário pediu para carregar a lista
class LoadIndicatorsEvent extends IndicatorEvent {}

// Evento: Usuário adicionou um novo indicador (exemplo futuro)
class AddIndicatorEvent extends IndicatorEvent {
  final Indicator indicator;
  const AddIndicatorEvent(this.indicator);
}

class UpdateIndicatorEvent extends IndicatorEvent {
  final Indicator indicator;
  const UpdateIndicatorEvent(this.indicator);
}

class DeleteIndicatorEvent extends IndicatorEvent {
  final String id;
  const DeleteIndicatorEvent(this.id);
}

class GenerateQrCodeEvent extends IndicatorEvent {}

class ImportIndicatorsEvent extends IndicatorEvent {
  final String jsonString;
  const ImportIndicatorsEvent(this.jsonString);
}