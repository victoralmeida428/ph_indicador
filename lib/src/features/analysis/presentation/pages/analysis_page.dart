import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ph_indicador/src/core/ui/widget/app_drawer.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';
import 'package:ph_indicador/src/core/ui/widget/camera_capture_widget.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/bloc/analysis_bloc.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/event/analysis_event.dart';
import 'package:ph_indicador/src/features/analysis/presentation/bloc/state/analysis_state.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';
import 'package:ph_indicador/src/features/indicador/presentation/widget/indicator_card.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // Controlador para o dropdown (opcional, mas útil para validação)
  Indicator? _localSelectedIndicator;

  @override
  void initState() {
    super.initState();
    // Carrega os indicadores assim que a tela abre
    context.read<AnalysisBloc>().add(LoadAvailableIndicatorsEvent());
  }

  Widget _buildColorPreview(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // Função para abrir a câmera
  void _openCamera(BuildContext context) {
    if (_localSelectedIndicator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, selecione um indicador acima."))
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraCaptureWidget(
          onPictureTaken: (file) {
            Navigator.pop(context); // Fecha a câmera
            // Envia a foto para o BLoC analisar
            context.read<AnalysisBloc>().add(AnalyzeImageEvent(file.path));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Nova Análise",
      drawer: AppDrawer(),
      // Usamos BlocConsumer para escutar mudanças (erros/sucesso) e reconstruir a tela
      body: BlocConsumer<AnalysisBloc, AnalysisState>(
        listener: (context, state) {
          if (state is AnalysisError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }

          if (state is AnalysisSuccess) {
            // Exibe o resultado da análise
            showDialog(
                context: context,
                barrierDismissible: false, // Obriga a clicar no botão para fechar
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1B263B),
                  title: const Text("Resultado da Análise", style: TextStyle(color: Colors.white)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Valor do pH Encontrado
                      Text(
                        "pH ${state.matchedRange.phMin} - ${state.matchedRange.phMax}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Comparação Visual
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildColorPreview("Amostra", state.sampledColor),
                          const Icon(Icons.arrow_forward, color: Colors.white54),
                          _buildColorPreview("Padrão", Color(state.matchedRange.colorHex)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Faixa mais próxima encontrada.",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Fecha o Dialog
                          context.read<AnalysisBloc>().add(LoadAvailableIndicatorsEvent());
                        },
                        child: const Text("Nova Análise")
                    )
                  ],
                )
            );
          }
        },
        builder: (context, state) {
          // 1. Estado de Carregamento Inicial
          if (state is AnalysisLoadingIndicators || state is AnalysisInitial) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          // 2. Estado de Processamento (Analisando a foto)
          if (state is AnalysisAnalyzing) {
            return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text("Processando imagem e calculando pH...", style: TextStyle(color: Colors.white))
                  ],
                )
            );
          }

          // 3. Estado Pronto (Mostra o formulário)
          if (state is AnalysisReady) {
            if (state.indicators.isEmpty) {
              return const Center(
                  child: Text("Nenhum indicador cadastrado. Cadastre um primeiro.",
                      style: TextStyle(color: Colors.white70)));
            }

            // Atualiza a seleção local caso o estado tenha mudado externamente
            _localSelectedIndicator = state.selectedIndicator;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "1. Selecione o Indicador Usado:",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // --- DROPDOWN ---
                  DropdownButtonFormField<Indicator>(
                    value: _localSelectedIndicator,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white10,
                      prefixIcon: Icon(Icons.science, color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF1B263B), // Cor do menu dropdown
                    style: const TextStyle(color: Colors.white),
                    hint: const Text("Toque para selecionar", style: TextStyle(color: Colors.white54)),
                    items: state.indicators.map((indicator) {
                      return DropdownMenuItem(
                        value: indicator,
                        child: Text(indicator.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _localSelectedIndicator = value);
                        // Avisa o BLoC da seleção
                        context.read<AnalysisBloc>().add(SelectIndicatorEvent(value));
                      }
                    },
                  ),

                  // --- AQUI ESTÁ A ADIÇÃO ---
                  if (_localSelectedIndicator != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Resumo do Padrão:",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    IndicatorCard(
                      indicator: _localSelectedIndicator!,
                    ),
                  ],
                  // -------------------------

                  const Spacer(), // Empurra o botão para baixo

                  const Text(
                    "2. Prepare a amostra e tire a foto:",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // --- BOTÃO DA CÂMERA ---
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => _openCamera(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text("TIRAR FOTO DA AMOSTRA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}