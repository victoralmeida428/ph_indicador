import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WhiteCornerGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 20.0; // Comprimento das linhas dos cantos

    // Canto Superior Esquerdo
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Canto Superior Direito
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Canto Inferior Esquerdo
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Canto Inferior Direito
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);

    // Opcional: Cruz central pequena
    final centerPaint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(center.translate(-10, 0), center.translate(10, 0), centerPaint);
    canvas.drawLine(center.translate(0, -10), center.translate(0, 10), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}