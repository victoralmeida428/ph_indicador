import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/routes/app_routes.dart';
import 'package:ph_indicador/src/core/ui/widget/app_drawer.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Indicador de pH",
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("Meus Indicadores"),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.indicators),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Nova Análise"),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.analysis),
            ),
          ],
        ),
      ),
    );
  }
}