import 'package:flutter/material.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

class IndicatorCard extends StatelessWidget {
  final Indicator indicator;
  final VoidCallback onTap;

  const IndicatorCard({
    super.key,
    required this.indicator,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // 1. Cria uma cópia da lista e ordena pelo pH Mínimo para ficar organizado visualmente
    final sortedRanges = List.of(indicator.ranges)
      ..sort((a, b) => a.phMin.compareTo(b.phMin));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white10, // Fundo escuro
      clipBehavior: Clip.antiAlias, // Garante que o InkWell respeite as bordas arredondadas
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABEÇALHO: NOME DO INDICADOR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      indicator.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),

              // --- LISTA DE FAIXAS (Uma por linha) ---
              if (sortedRanges.isEmpty)
                const Text(
                  "Nenhuma faixa cadastrada.",
                  style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                )
              else
                ...sortedRanges.map((range) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        // 1. A Cor (Visual)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(range.colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 1),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 2. O Texto do Intervalo de pH
                        Text(
                          "pH ${range.phMin} a ${range.phMax}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}