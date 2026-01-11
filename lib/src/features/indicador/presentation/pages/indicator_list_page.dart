import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/ui/widget/app_drawer.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/bloc/indicator_bloc.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/event/indicator_event.dart';
import 'package:ph_indicador/src/features/indicador/presentation/bloc/state/indicator_state.dart';
import 'package:ph_indicador/src/features/indicador/presentation/pages/indicator_detailed_page.dart';
import 'package:ph_indicador/src/features/indicador/presentation/widget/indicator_card.dart';
import 'package:ph_indicador/src/features/indicador/presentation/widget/qr_scanner_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IndicatorListPage extends StatelessWidget {
  const IndicatorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Indicadores",
      drawer: const AppDrawer(),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert), // Os 3 pontinhos
          tooltip: "Mais opções",
          onSelected: (value) {
            switch (value) {
              case 'import': _openScanner(context);
              case 'export': context.read<IndicatorBloc>().add(GenerateQrCodeEvent());
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Exportar Indicadores"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Importar Indicadores"),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
      // 1. Botão LER (Importar)
      // IconButton(
      //   icon: const Icon(Icons.qr_code_scanner),
      //   tooltip: "Ler QR Code (Importar)",
      //   onPressed: () => _openScanner(context),
      // ),
      //
      // // 2. Botão GERAR (Exportar)
      // IconButton(
      //   icon: const Icon(Icons.qr_code_2),
      //   tooltip: "Gerar QR Code (Exportar)",
      //   onPressed: () {
      //     context.read<IndicatorBloc>().add(GenerateQrCodeEvent());
      //   },
      // ),
      // O BlocBuilder escuta as mudanças de estado emitidas pelo IndicatorBloc
      body: BlocBuilder<IndicatorBloc, IndicatorState>(
        builder: (context, state) {
          if (state is IndicatorLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state is IndicatorQrGenerated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 1. Abre o Dialog
              _showQrDialog(context, state.qrData);

              // 2. Recarrega a lista para tirar o estado de "Gerado" e voltar ao "Loaded"
              // (Isso fará a lista aparecer de volta no fundo do dialog)
              context.read<IndicatorBloc>().add(LoadIndicatorsEvent());
            });
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
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              // Espaço p/ FAB
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
                  ),
                ],
              ),
            );
          }

          if (state is IndicatorQrGenerated) {
            return const Center(child: CircularProgressIndicator()); // Ou nada
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

  void _showQrDialog(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        // QR Code precisa de contraste (fundo branco)
        title: const Text(
          "Exportar Padrões",
          style: TextStyle(color: Colors.black),
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 280.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  void _openScanner(BuildContext context) async {
    // Navega para a tela de scanner e aguarda o resultado (String do QR)
    final String? jsonResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );

    if (jsonResult != null && context.mounted) {
      // Se leu algo, dispara o evento de importação
      context.read<IndicatorBloc>().add(ImportIndicatorsEvent(jsonResult));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Processando QR Code...")));
    }
  }
}
