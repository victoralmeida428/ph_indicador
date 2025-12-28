import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'overlay_with_hole_painter.dart'; // Importe seu painter aqui

typedef OnPictureTaken = void Function(XFile picture);

class CameraCaptureWidget extends StatefulWidget {
  final OnPictureTaken onPictureTaken;

  const CameraCaptureWidget({super.key, required this.onPictureTaken});

  @override
  State<CameraCaptureWidget> createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;

  // Estado para controlar a lanterna
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // Tenta pegar a traseira, se não tiver, pega a primeira
      final firstCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();

      // Define o flash como desligado inicialmente para garantir consistência
      if (mounted) {
        await _initializeControllerFuture;
        await _controller!.setFlashMode(FlashMode.off);
        setState(() {});
      }
    } catch (e) {
      debugPrint("Erro ao inicializar câmera: $e");
    }
  }

  // Alterna entre Lanterna (Torch) e Desligado
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() => _isTorchOn = false);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        setState(() => _isTorchOn = true);
      }
    } catch (e) {
      debugPrint("Erro ao alternar flash: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final image = await _controller!.takePicture();

      // Desliga a lanterna antes de sair, para economizar bateria
      if (_isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
      }

      widget.onPictureTaken(image);
    } catch (e) {
      debugPrint("Erro ao tirar foto: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Quadrado de 280px ou 80% da tela (o que for menor)
    final double squareSize = size.width * 0.8 > 280 ? 280 : size.width * 0.8;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || _controller == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. PREVIEW DA CÂMERA
              Center(
                child: CameraPreview(_controller!),
              ),

              // 2. MÁSCARA ESCURA COM MIRA CENTRAL 28x28
              // (Certifique-se que o OverlayWithHolePainter tem o código atualizado da mira)
              CustomPaint(
                painter: OverlayWithHolePainter(
                  holeSize: squareSize,
                  overlayColor: Colors.black.withOpacity(0.7),
                ),
              ),

              // 3. BOTÃO FECHAR (Topo Esquerdo)
              Positioned(
                top: SafeArea(child: Container()).minimum.top + 20,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // 4. BOTÃO FLASH/LANTERNA (Topo Direito)
              Positioned(
                top: SafeArea(child: Container()).minimum.top + 20,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: _isTorchOn ? Colors.yellow.withOpacity(0.8) : Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.black : Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
              ),

              // 5. INSTRUÇÃO
              Positioned(
                top: size.height / 2 - (squareSize / 2) - 60,
                left: 0,
                right: 0,
                child: const Text(
                  "Centralize a amostra na mira",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)]
                  ),
                ),
              ),

              // 6. BOTÃO DE CAPTURA (Rodapé)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: _isTakingPicture
                      ? const CircularProgressIndicator(color: Colors.white)
                      : GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}