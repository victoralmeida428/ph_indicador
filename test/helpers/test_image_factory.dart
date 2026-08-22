import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Gera um PNG temporário com uma cor central conhecida (quadrado 28x28)
/// e um fundo opcional, espelhando a geometria usada pelo
/// [ImageColorExtractor].
class TestImageFactory {
  static Future<String> createImage({
    required int width,
    required int height,
    required Color centerColor,
    Color? borderColor,
    String? fileName,
  }) async {
    final image = img.Image(width: width, height: height);
    final border = borderColor ?? const Color(0xFF000000);

    img.fill(
      image,
      color: img.ColorRgb8(
        (border.r * 255).round(),
        (border.g * 255).round(),
        (border.b * 255).round(),
      ),
    );

    final x = (width - 28) ~/ 2;
    final y = (height - 28) ~/ 2;
    img.fillRect(
      image,
      x1: x,
      y1: y,
      x2: x + 28,
      y2: y + 28,
      color: img.ColorRgb8(
        (centerColor.r * 255).round(),
        (centerColor.g * 255).round(),
        (centerColor.b * 255).round(),
      ),
    );

    final bytes = img.encodePng(image);
    final dir = await Directory.systemTemp.createTemp('ph_indicador_test');
    final file = File('${dir.path}/${fileName ?? 'sample.png'}');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<String> createCorruptFile() async {
    final dir = await Directory.systemTemp.createTemp('ph_indicador_test');
    final file = File('${dir.path}/corrupt.png');
    await file.writeAsBytes(List.filled(64, 0xAB));
    return file.path;
  }
}