import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/errors/failures.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';

class IndicatorBloc extends Bloc<IndicatorEvent, IndicatorState> {
  final IndicatorRepository repository;

  IndicatorBloc({required this.repository}) : super(IndicatorInitial()) {

    // Registramos o que fazer quando o evento 'LoadIndicatorsEvent' chegar
    on<LoadIndicatorsEvent>(_onLoadIndicators);
    on<AddIndicatorEvent>(_onAddIndicator);
  }

  Future<void> _onLoadIndicators(event, emit) async {
    emit(IndicatorLoading());
    try {
      final indicators = await repository.getAllIndicators();
      emit(IndicatorLoaded(indicators));
    } on DatabaseFailure catch (e) {
      emit(IndicatorError(e.message));
    } on Failure catch (e) {
      // Outros erros de negócio
      emit(IndicatorError(e.message));
    } catch (e) {
      emit(const IndicatorError("Ocorreu um erro inesperado."));
    }
  }

  Future<void> _onAddIndicator(event, emit) async {
    emit(IndicatorLoading());
    try {
      await repository.saveIndicador(event.indicator);
      add(LoadIndicatorsEvent());
      emit(IndicatorSuccess());
    } catch(e) {
      emit(const IndicatorError("Erro ao salvar o indicador."));
    }
  }
}