import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/routes/app_routes.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';
import 'package:ph_indicador/src/features/indicador/presentation/pages/home_page.dart';
import 'package:ph_indicador/src/features/indicador/presentation/pages/indicator_list_page.dart';

class RouteGenerator {
  final IndicatorRepository indicatorRepository;

  RouteGenerator({required this.indicatorRepository});

  Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case AppRoutes.indicators:
        return MaterialPageRoute(
          builder: (_) => IndicatorListPage(
            // Injeção de Dependência Manual:
            // A tela recebe o repositório pronto para usar
            repository: indicatorRepository,
          ),
        );

      case AppRoutes.addIndicator:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text("Tela de Adicionar (TODO)"))));

      case AppRoutes.analysis:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text("Tela de Câmera (TODO)"))));

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Rota não encontrada')),
      );
    });
  }
}