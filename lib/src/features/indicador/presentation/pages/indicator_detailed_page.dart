import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/bloc/indicator_bloc.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';
import 'package:ph_indicador/src/features/indicador/presentation/widget/add_range_widget.dart';

class IndicatorDetailsPage extends StatefulWidget {
  final Indicator indicator;

  const IndicatorDetailsPage({super.key, required this.indicator});

  @override
  State<IndicatorDetailsPage> createState() => _IndicatorDetailsPageState();
}

class _IndicatorDetailsPageState extends State<IndicatorDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController; // Late para iniciar no initState

  // Lista local
  late List<IndicatorRange> _addedRanges;

  @override
  void initState() {
    super.initState();
    // 2. Preenchemos os dados iniciais com base no indicador recebido
    _nameController = TextEditingController(text: widget.indicator.name);

    // Criamos uma cópia da lista para não alterar o objeto original antes de salvar
    _addedRanges = List.from(widget.indicator.ranges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

      final updatedIndicator = Indicator(
        id: widget.indicator.id, // 3. IMPORTANTE: Mantém o ID original para atualizar
        name: _nameController.text,
        ranges: List.from(_addedRanges),
      );

      // Dispara evento de Atualizar (Você precisa ter esse evento no Bloc, veja abaixo)
      // Se seu AddIndicatorEvent usar "INSERT OR REPLACE" no banco, pode usar ele mesmo,
      // mas o ideal é ter um UpdateIndicatorEvent semanticamente.
      context.read<IndicatorBloc>().add(UpdateIndicatorEvent(updatedIndicator));
    }
  }

  // Função para deletar o indicador inteiro (Opcional, mas útil na tela de detalhes)
  void _deleteIndicator() {
    context.read<IndicatorBloc>().add(DeleteIndicatorEvent(widget.indicator.id));
  }

  void _removeRange(int index) {
    setState(() {
      _addedRanges.removeAt(index);
    });
  }

  void _showAddRangeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B263B),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AddRangeSheet(
          onAdd: (range) {
            setState(() {
              _addedRanges.add(range);
              _addedRanges.sort((a, b) => a.phMin.compareTo(b.phMin));
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Editar Padrão",
      // Adicionamos um botão de lixeira na AppBar
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            // Diálogo de confirmação antes de excluir
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text("Excluir Padrão?"),
              content: const Text("Essa ação não pode ser desfeita."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Fecha dialog
                    _deleteIndicator();
                  },
                  child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                ),
              ],
            ));
          },
        )
      ],
      body: BlocListener<IndicatorBloc, IndicatorState>(
        listener: (context, state) {
          if (state is IndicatorLoaded) {
            Navigator.pop(context); // Fecha a tela e volta para a lista
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Alterações salvas com sucesso!")),
            );
          }
          if (state is IndicatorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nome do Indicador",
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
                    tooltip: "Adicionar Nova Faixa",
                  )
                ],
              ),
            ),

            Expanded(
              child: _addedRanges.isEmpty
                  ? Center(
                child: Text(
                  "Nenhuma faixa cadastrada.",
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
                child: const Text("Salvar Alterações", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}