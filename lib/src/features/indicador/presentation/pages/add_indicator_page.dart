import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/core/ui/widget/camera_capture_widget.dart';
import 'package:ph_indicador/src/core/utils/image_color_extractor.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/bloc/indicator_bloc.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';
import 'package:ph_indicador/src/features/indicador/presentation/widget/add_range_widget.dart';
import 'package:uuid/uuid.dart';

class AddIndicatorPage extends StatefulWidget {
  const AddIndicatorPage({super.key});

  @override
  State<AddIndicatorPage> createState() => _AddIndicatorPageState();
}

class _AddIndicatorPageState extends State<AddIndicatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Lista local temporária para armazenar as faixas antes de salvar no banco
  final List<IndicatorRange> _addedRanges = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Ação Final: Salvar o Indicador e todas as suas faixas
  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_addedRanges.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Adicione pelo menos uma faixa de pH/Cor."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final newIndicator = Indicator(
        id: const Uuid().v4(),
        name: _nameController.text,
        ranges: List.from(_addedRanges), // Passa a lista de faixas
      );

      // Envia evento para o BLoC
      context.read<IndicatorBloc>().add(AddIndicatorEvent(newIndicator));
    }
  }

  // Remove uma faixa da lista temporária
  void _removeRange(int index) {
    setState(() {
      _addedRanges.removeAt(index);
    });
  }

  // Abre o modal para criar UMA NOVA FAIXA
  void _showAddRangeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite ocupar a tela toda se precisar
      backgroundColor: const Color(0xFF1B263B),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom, // Ajuste teclado
        ),
        child: AddRangeSheet(
          onAdd: (range) {
            setState(() {
              _addedRanges.add(range);
              // Ordena a lista por pH Minimo para ficar organizado
              _addedRanges.sort((a, b) => a.phMin.compareTo(b.phMin));
            });
            Navigator.pop(ctx); // Fecha o modal
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Novo Padrão",
      body: BlocListener<IndicatorBloc, IndicatorState>(
        listener: (context, state) {
          if (state is IndicatorLoaded) {
            Navigator.pop(context); // Fecha a tela de cadastro
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Indicador salvo com sucesso!")),
            );
          }
          if (state is IndicatorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // PARTE 1: NOME DO INDICADOR (FIXO)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Indicador (Ex: Azul de Bromotimol)",
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
                  ),
                ),
              ),
          
              const Divider(color: Colors.white24),
          
              // PARTE 2: LISTA DE FAIXAS ADICIONADAS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Faixas de Cor",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _showAddRangeModal,
                      icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
                      tooltip: "Adicionar Faixa",
                    )
                  ],
                ),
              ),
          
              Expanded(
                child: _addedRanges.isEmpty
                    ? Center(
                  child: Text(
                    "Nenhuma faixa adicionada.\nClique no + para começar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                )
                    : ListView.builder(
                  itemCount: _addedRanges.length,
                  itemBuilder: (context, index) {
                    final range = _addedRanges[index];
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(range.colorHex),
                          radius: 16,
                        ),
                        title: Text(
                          "pH ${range.phMin} - ${range.phMax}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _removeRange(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
          
              // PARTE 3: BOTÃO SALVAR GERAL
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Salvar Padrão Completo", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
