import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/ui/widget/app_drawer.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/bloc/indicator_bloc.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';
import 'package:ph_indicador/src/features/indicador/presentation/pages/indicator_detailed_page.dart';
import 'package:ph_indicador/src/features/indicador/presentation/widget/indicator_card.dart';

class IndicatorListPage extends StatelessWidget {

  const IndicatorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Indicadores Salvos",
      drawer: const AppDrawer(),

      // O BlocBuilder escuta as mudanças de estado emitidas pelo IndicatorBloc
      body: BlocBuilder<IndicatorBloc, IndicatorState>(
        builder: (context, state) {

          // 1. ESTADO DE CARREGAMENTO
          if (state is IndicatorLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // 2. ESTADO DE SUCESSO (CARREGADO)
          if (state is IndicatorLoaded) {
            if (state.indicators.isEmpty) {
              return const Center(
                child: Text(
                  "Nenhum indicador salvo.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80), // Espaço p/ FAB
              itemCount: state.indicators.length,
              itemBuilder: (context, index) {
                final indicator = state.indicators[index];

                // Usamos o Widget separado para manter o código limpo
                return IndicatorCard(
                  indicator: indicator,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          // IMPORTANTE: Repassa o BLoC existente para a nova tela
                          value: context.read<IndicatorBloc>(),
                          child: IndicatorDetailsPage(indicator: indicator),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          // 3. ESTADO DE ERRO
          if (state is IndicatorError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  TextButton(
                    onPressed: () {
                      // Tenta carregar novamente
                      context.read<IndicatorBloc>().add(LoadIndicatorsEvent());
                    },
                    child: const Text("Tentar Novamente"),
                  )
                ],
              ),
            );
          }

          // 4. ESTADO INICIAL (Ou desconhecido)
          return const SizedBox.shrink();
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          // Navega para a tela de adicionar
          Navigator.pushNamed(context, '/add-indicator').then((_) {
            if (context.mounted) {
              context.read<IndicatorBloc>().add(LoadIndicatorsEvent());
            }
          });
        },
      ),
    );
  }
}