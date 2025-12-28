import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/features/indicador/data/datasources/indicator_local_datasource_impl.dart';
import 'package:ph_indicador/src/features/indicador/data/repositories/indicator_repository_impl.dart';

// Core Imports
import 'src/core/database/database_helper.dart';
import 'src/core/routes/app_routes.dart';
import 'src/core/routes/route_generator.dart';

void main() async {
  // 1. Garante que a engine do Flutter está pronta (necessário para o SQFlite)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialização do Banco de Dados (Singleton)
  final database = await DatabaseHelper.instance.database;

  // 3. Injeção de Dependência (Setup Inicial)
  // Criamos as implementações aqui e passamos para baixo
  final localDataSource = IndicatorLocalDataSourceImpl(database);
  final indicatorRepository = IndicatorRepositoryImpl(db:localDataSource);

  // 4. Configuração das Rotas
  // Passamos o repositório para o gerador de rotas
  final routeGenerator = RouteGenerator(indicatorRepository: indicatorRepository);

  runApp(MyApp(routeGenerator: routeGenerator));
}

class MyApp extends StatelessWidget {
  final RouteGenerator routeGenerator;

  const MyApp({super.key, required this.routeGenerator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pH Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Avisa o Flutter que é tema escuro

      // Esta é a cor que aparece "por trás" das animações
      scaffoldBackgroundColor: AppScaffold.backgroundColor,

      // Esta é a cor de fundo de Drawers e BottomSheets
      canvasColor: AppScaffold.backgroundColor,

      // Configura a AppBar globalmente (opcional, já que vc tem no AppScaffold)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppScaffold.appBarColor,
        foregroundColor: Color(0xFFE0E1DD),
        elevation: 0,
      ), dialogTheme: DialogThemeData(backgroundColor: AppScaffold.appBarColor),
    ),

      // CONFIGURAÇÃO DE ROTAS AQUI:
      initialRoute: AppRoutes.home, // Rota inicial
      onGenerateRoute: routeGenerator.generateRoute, // Quem gerencia a navegação
    );
  }
}