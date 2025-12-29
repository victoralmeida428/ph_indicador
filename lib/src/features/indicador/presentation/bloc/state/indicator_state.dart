import 'package:equatable/equatable.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

abstract class IndicatorState extends Equatable {
  const IndicatorState();

  @override
  List<Object> get props => [];
}

class IndicatorInitial extends IndicatorState {}

class IndicatorLoading extends IndicatorState {}

class IndicatorLoaded extends IndicatorState {
  final List<Indicator> indicators;

  const IndicatorLoaded(this.indicators);

  @override
  List<Object> get props => [indicators];
}

class IndicatorError extends IndicatorState {
  final String message;
  const IndicatorError(this.message);

  @override
  // TODO: implement props
  List<Object> get props => [message];
}

class IndicatorSuccess extends IndicatorState {}

// Estado para mostrar o QR Code
class IndicatorQrGenerated extends IndicatorState {
  final String qrData;
  const IndicatorQrGenerated(this.qrData);

  @override
  List<Object> get props => [qrData];
}
