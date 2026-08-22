import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/settings/settings_service.dart';
import 'package:ph_indicador/src/core/ui/widget/app_drawer.dart';
import 'package:ph_indicador/src/core/ui/widget/app_scaffold.dart';

class AnalysisConfigPage extends StatefulWidget {
  const AnalysisConfigPage({super.key});

  @override
  State<AnalysisConfigPage> createState() => _AnalysisConfigPageState();
}

class _AnalysisConfigPageState extends State<AnalysisConfigPage> {
  late double _tolerance;
  late double _kL;
  late bool _normalizeIntensity;
  late String _matchingMode;

  @override
  void initState() {
    super.initState();
    final settings = SettingsService.instance;
    _tolerance = settings.getAnalysisTolerance();
    _kL = settings.getAnalysisKL();
    _normalizeIntensity = settings.getColorNormalization();
    _matchingMode = settings.getMatchingMode();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Configurações",
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Parâmetros de Análise",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildToleranceCard(),
          const SizedBox(height: 16),
          _buildKLWeightCard(),
          const SizedBox(height: 16),
          _buildNormalizationCard(),
          const SizedBox(height: 16),
          _buildMatchingModeCard(),
        ],
      ),
    );
  }

  Widget _buildToleranceCard() {
    return Card(
      color: const Color(0xFF1B263B),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tolerância de Cor",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Distância máxima (Delta E) para considerar que uma cor "
              "amostrada corresponde a uma faixa do indicador. "
              "Valores menores = mais precisão, valores maiores = mais flexibilidade.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("1.0", style: TextStyle(color: Colors.white54, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _tolerance,
                    min: 1.0,
                    max: 50.0,
                    divisions: 98,
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.white24,
                    label: _tolerance.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() => _tolerance = v);
                      SettingsService.instance.setAnalysisTolerance(v);
                    },
                  ),
                ),
                const Text("50.0", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_tolerance.toStringAsFixed(1)} ΔE",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKLWeightCard() {
    return Card(
      color: const Color(0xFF1B263B),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Peso da Luminosidade (kL)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Controla o quanto a diferença de brilho influencia na "
              "comparação. kL = 1 (padrão) considera brilho normalmente. "
              "kL > 2 reduz o impacto de iluminação diferente entre "
              "as fotos (casa vs sala de aula).",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("0.5", style: TextStyle(color: Colors.white54, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _kL,
                    min: 0.5,
                    max: 10.0,
                    divisions: 38,
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.white24,
                    label: _kL.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() => _kL = v);
                      SettingsService.instance.setAnalysisKL(v);
                    },
                  ),
                ),
                const Text("10.0", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "kL = ${_kL.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _kL >= 3 ? "Alto: ignora bastante a luminosidade, bom para ambientes com iluminação diferente." :
              _kL >= 2 ? "Médio: reduz sensibilidade a brilho sem perder precisão." :
              "Baixo: considera brilho normalmente (padrão CIEDE2000).",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalizationCard() {
    return Card(
      color: const Color(0xFF1B263B),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Normalizar Intensidade",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Remove completamente a diferença de brilho entre "
                        "as cores, mantendo apenas a proporção entre os "
                        "canais RGB. Recomendado para ambientes com "
                        "iluminação muito diferente.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _normalizeIntensity,
                  activeColor: Colors.blueAccent,
                  onChanged: (v) {
                    setState(() => _normalizeIntensity = v);
                    SettingsService.instance.setColorNormalization(v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingModeCard() {
    return Card(
      color: const Color(0xFF1B263B),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Modo de Comparação",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Define o algoritmo usado para comparar as cores.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _matchingMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white10,
              ),
              dropdownColor: const Color(0xFF1B263B),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: 'ciede2000',
                  child: Text("CIEDE2000 (Padrão)"),
                ),
                DropdownMenuItem(
                  value: 'chromaticity',
                  child: Text("Somente Cromaticidade (ignora brilho)"),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _matchingMode = v);
                  SettingsService.instance.setMatchingMode(v);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _matchingMode == 'chromaticity'
                  ? "Compara apenas a cromaticidade (a* e b* do Lab), "
                    "ignorando completamente a luminosidade. "
                    "Ideal para identificar a cor independente da iluminação."
                  : "CIEDE2000 completo: considera luminosidade, "
                    "croma e matiz. Use com kL > 1 para reduzir "
                    "sensibilidade a iluminação.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
