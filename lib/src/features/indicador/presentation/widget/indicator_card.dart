import 'package:flutter/material.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator.dart';

class IndicatorCard extends StatelessWidget {
  final Indicator indicator;
  final VoidCallback? onTap; // 1. Agora é opcional (pode ser nulo)

  const IndicatorCard({
    super.key,
    required this.indicator,
    this.onTap, // 2. Removemos o 'required'
  });

  @override
  Widget build(BuildContext context) {
    final sortedRanges = List.of(indicator.ranges)
      ..sort((a, b) => a.phMin.compareTo(b.phMin));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white10,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Se onTap for null, o InkWell desativa automaticamente o efeito de clique (ripple)
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

                  // 3. Só exibe a seta se tiver ação de clique
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),

              // --- LISTA DE FAIXAS ---
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