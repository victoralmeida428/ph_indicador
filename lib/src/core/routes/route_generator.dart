import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/routes/app_routes.dart';
import 'package:ph_indicador/src/features/indicador/domain/repositories/indicador_repository.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/bloc/indicator_bloc.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/pages/add_indicator_page.dart';
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
            builder: (_) =>
                BlocProvider<IndicatorBloc>(
                  create: (context) =>
                  IndicatorBloc(repository: indicatorRepository)
                    ..add(LoadIndicatorsEvent()),
                  child: const IndicatorListPage(),
                )
        );

      case AppRoutes.addIndicator:
        return MaterialPageRoute(
            builder: (_) =>
                BlocProvider<IndicatorBloc>(
                  create: (context) => IndicatorBloc(repository: indicatorRepository),
                  child: const AddIndicatorPage(),
                )
        );

      case AppRoutes.analysis:
        return MaterialPageRoute(
            builder: (_) =>
            const Scaffold(body: Center(child: Text("Tela de Câmera (TODO)"))));

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