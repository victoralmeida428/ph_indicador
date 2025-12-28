import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverlayWithHolePainter extends CustomPainter {
  final double holeSize;
  final Color overlayColor;

  OverlayWithHolePainter({required this.holeSize, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    // --- CÓDIGO ORIGINAL (Overlay e Buraco Grande) ---
    final paint = Paint()..color = overlayColor;

    // 1. Cria o caminho do retângulo da tela inteira
    final Path screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);

    // 2. Cria o caminho do quadrado central grande (o buraco)
    final Path holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: holeSize,
          height: holeSize,
        ),
        const Radius.circular(12), // Cantos arredondados opcionais
      ));

    // 3. Combina os caminhos usando "Diferença" (Tela - Buraco)
    final Path overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      holePath,
    );

    // Desenha o resultado
    canvas.drawPath(overlayPath, paint);

    // Opcional: Desenha uma borda branca fina ao redor do buraco grande
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: holeSize,
        height: holeSize,
      ),
      const Radius.circular(12),
    ), borderPaint);


    // --- MIRA CENTRAL 28x28 ---

    // Definindo o tamanho fixo de 28x28
    const double targetSize = 28.0;

    // Definindo o estilo da linha fina branca
    final targetPaint = Paint()
      ..color = Colors.white // Cor branca sólida para destaque
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Linha fina

    // Criando o retângulo centralizado
    final targetRect = Rect.fromCenter(
      center: center, // Usa o mesmo centro calculado anteriormente
      width: targetSize,
      height: targetSize,
    );

    // Desenhando o quadrado (drawRect faz cantos retos)
    canvas.drawRect(targetRect, targetPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}