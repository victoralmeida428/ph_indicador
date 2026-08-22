import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_indicador/src/core/errors/failures.dart';
import 'package:ph_indicador/src/core/utils/image_color_extractor.dart';

import '../helpers/test_image_factory.dart';

void main() {
  group('ImageColorExtractor.extractAverageColor', () {
    test('imagem uniforme: retorna exatamente a cor da imagem', () async {
      final path = await TestImageFactory.createImage(
        width: 100,
        height: 100,
        centerColor: const Color.fromARGB(255, 200, 100, 50),
      );

      final color = await ImageColorExtractor.extractAverageColor(path);

      expect(color, const Color.fromARGB(255, 200, 100, 50));
    });

    test('centro 28x28 distinto do fundo: retorna a cor central', () async {
      final path = await TestImageFactory.createImage(
        width: 200,
        height: 200,
        centerColor: const Color.fromARGB(255, 10, 20, 30),
        borderColor: const Color.fromARGB(255, 250, 250, 250),
      );

      final color = await ImageColorExtractor.extractAverageColor(path);

      expect(color, const Color.fromARGB(255, 10, 20, 30));
    });

    test('imagem menor que 28px: lança ImageProcessingFailure', () async {
      final path = await TestImageFactory.createImage(
        width: 20,
        height: 20,
        centerColor: const Color.fromARGB(255, 0, 255, 0),
      );

      await expectLater(
        ImageColorExtractor.extractAverageColor(path),
        throwsA(isA<ImageProcessingFailure>()),
      );
    });

    test('arquivo corrompido: lança ImageProcessingFailure', () async {
      final path = await TestImageFactory.createCorruptFile();

      await expectLater(
        ImageColorExtractor.extractAverageColor(path),
        throwsA(isA<ImageProcessingFailure>()),
      );
    });

    test('arquivo inexistente: lança ImageProcessingFailure', () async {
      await expectLater(
        ImageColorExtractor.extractAverageColor('/nao/existe/imagem.png'),
        throwsA(isA<ImageProcessingFailure>()),
      );
    });
  });
}