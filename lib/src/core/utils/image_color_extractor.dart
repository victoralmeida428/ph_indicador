import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:ph_indicador/src/core/errors/exceptions.dart';
import 'package:ph_indicador/src/core/errors/failures.dart';

class ImageColorExtractor {

  /// Calcula a cor média de um quadrado de 28x28 pixels no centro da imagem
  static Future<Color?> extractAverageColor(String imagePath) async {
    try {
      // 1. Lê os bytes do arquivo
      final bytes = await File(imagePath).readAsBytes();

      // 2. Decodifica para um objeto manipulável
      final img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage == null) {
        throw ImageProcessingException("Nenhuma cor identificada");
      }

      // --- ALTERAÇÃO AQUI ---
      const int sampleSize = 28; // Tamanho fixo (28x28)

      // Verificação de segurança: A imagem é menor que 28px? (Raro, mas possível)
      if (capturedImage.width < sampleSize || capturedImage.height < sampleSize) {
        throw ImageProcessingException("Erro: Imagem muito pequena para a amostra de 28px.");
      }

      // 3. Calcula a posição X e Y para que o quadrado fique EXATAMENTE no centro
      final int x = (capturedImage.width - sampleSize) ~/ 2;
      final int y = (capturedImage.height - sampleSize) ~/ 2;

      // 4. Recorta apenas o quadrado de 28x28
      final img.Image centerCrop = img.copyCrop(
          capturedImage,
          x: x,
          y: y,
          width: sampleSize,
          height: sampleSize
      );

      // 5. Calcula a média (Percorre os 784 pixels)
      int r = 0, g = 0, b = 0;
      int totalPixels = sampleSize * sampleSize; // 784 pixels

      for (var pixel in centerCrop) {
        r += pixel.r.toInt();
        g += pixel.g.toInt();
        b += pixel.b.toInt();
      }

      // Retorna a cor média
      return Color.fromARGB(
          255,
          r ~/ totalPixels,
          g ~/ totalPixels,
          b ~/ totalPixels
      );

    } on ImageProcessingException catch (e) {
      throw ImageProcessingFailure(message: e.message);
    } catch(e) {
      throw const ImageProcessingFailure(message: "Erro de análise desconhecido");
    }
  }
}