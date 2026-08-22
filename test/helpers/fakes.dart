import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';

class FakeIndicatorRepository implements IndicatorRepository {
  final Map<String, Indicator> _store = {};

  int saveCalls = 0;
  int loadCalls = 0;
  int deleteCalls = 0;

  bool throwOnSave = false;
  bool throwOnLoad = false;
  bool throwOnDelete = false;

  @override
  Future<void> saveIndicador(Indicator indicador) async {
    saveCalls++;
    if (throwOnSave) throw Exception('falha ao salvar');
    _store[indicador.id] = indicador;
  }

  @override
  Future<List<Indicator>> getAllIndicators() async {
    loadCalls++;
    if (throwOnLoad) throw Exception('falha ao carregar');
    return _store.values.toList();
  }

  @override
  Future<void> deleteIndicator(String id) async {
    deleteCalls++;
    if (throwOnDelete) throw Exception('falha ao deletar');
    _store.remove(id);
  }

  List<Indicator> get stored => _store.values.toList();
}