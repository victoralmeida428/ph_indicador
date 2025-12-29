import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/core/errors/failures.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';
import 'package:ph_indicador/src/features/indicador/domain/usecases/generate_indicators_qrcode.dart';
import 'package:ph_indicador/src/features/indicador/domain/usecases/import_indicators_from_json.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';

class IndicatorBloc extends Bloc<IndicatorEvent, IndicatorState> {
  final IndicatorRepository repository;
  final GenerateIndicatorsQrCode generateQrCode;

  IndicatorBloc({
    required this.repository,
    // 2. Injete ou instancie o usecase (se for simples, pode instanciar aqui msm)
  }) : generateQrCode = GenerateIndicatorsQrCode(repository),
       super(IndicatorInitial()) {
    // Registramos o que fazer quando o evento 'LoadIndicatorsEvent' chegar
    on<LoadIndicatorsEvent>(_onLoadIndicators);
    on<AddIndicatorEvent>(_onAddIndicator);
    on<UpdateIndicatorEvent>(_onUpdateIndicator);
    on<DeleteIndicatorEvent>(_onDeleteIndicator);
    on<GenerateQrCodeEvent>(_onGenerateQrCode);
    on<ImportIndicatorsEvent>(_onImportIndicators);
  }

  Future<void> _onImportIndicators(ImportIndicatorsEvent event, Emitter<IndicatorState> emit) async {
    emit(IndicatorLoading());
    try {
      final useCase  = ImportIndicatorsFromJson(repository);
      await useCase.call(event.jsonString);

      add(LoadIndicatorsEvent());
    } on QRCodeInvalid catch (e) {
      const failure = QrCodeInvalidFailure();
      emit(IndicatorError(failure.message));

    } catch (e) {
      emit(IndicatorError("Erro desconhecido ao importar: ${e.toString()}"));
    }
  }

  Future<void> _onGenerateQrCode(
    GenerateQrCodeEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    // Mantemos o estado atual ou emitimos loading se quiser
    try {
      final jsonString = await generateQrCode();
      emit(IndicatorQrGenerated(jsonString));
    } catch (e) {
      emit(const IndicatorError("Erro ao gerar QR Code."));
    }
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
    } catch (e) {
      emit(const IndicatorError("Erro ao salvar o indicador."));
    }
  }

  Future<void> _onUpdateIndicator(
    UpdateIndicatorEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(IndicatorLoading());
    try {
      // Como estamos usando SQLite com conflictAlgorithm: replace,
      // o saveIndicator funciona tanto para criar quanto atualizar.
      await repository.saveIndicador(event.indicator);
      add(LoadIndicatorsEvent());
      emit(IndicatorSuccess());
    } catch (e) {
      emit(IndicatorError(e.toString()));
    }
  }

  Future<void> _onDeleteIndicator(
    DeleteIndicatorEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(IndicatorLoading());
    try {
      // Você precisará criar o método deleteIndicator no seu repositório
      await repository.deleteIndicator(event.id);
      add(LoadIndicatorsEvent());
      emit(IndicatorSuccess());
    } catch (e) {
      emit(IndicatorError(e.toString()));
    }
  }
}
