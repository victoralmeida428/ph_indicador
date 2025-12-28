import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';
import '../../domain/entities/indicator.dart';

class IndicatorListPage extends StatelessWidget {
  final IndicatorRepository repository;

  // Recebe o repositório via construtor (Injeção feita no RouteGenerator)
  const IndicatorListPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Indicadores Salvos",
      body: FutureBuilder<List<Indicator>>(
        future: repository.getAllIndicators(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum indicador salvo."));
          }

          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text("pH ${item.phMin} - ${item.phMax}"),
                leading: CircleAvatar(
                  backgroundColor: Color(item.colorHex),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Navegar para criar novo
          Navigator.pushNamed(context, '/add-indicator');
        },
      ),
    );
  }
}