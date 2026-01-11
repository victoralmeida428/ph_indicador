import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'overlay_with_hole_painter.dart';

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
  bool _isTorchOn = false;

  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Carrega todas as câmeras disponíveis apenas uma vez
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint("Nenhuma câmera encontrada");
        return;
      }

      // Tenta encontrar a câmera traseira para iniciar
      int backCameraIndex = _cameras.indexWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back
      );

      // Se achou a traseira usa ela, senão usa a primeira (índice 0)
      _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;

      await _startCameraConfig();
    } catch (e) {
      debugPrint("Erro ao inicializar lista de câmeras: $e");
    }
  }

  // ALTERAÇÃO 2: Função separada para iniciar o controlador (reusada na troca)
  Future<void> _startCameraConfig() async {
    final camera = _cameras[_selectedCameraIndex];

    // 1. Guardamos a referência do controller antigo para descartar depois
    final oldController = _controller;

    // 2. Atualizamos a UI IMEDIATAMENTE para remover o CameraPreview antigo.
    // Ao definir _controller como null, o seu build vai cair no "if (_controller == null)"
    // e mostrar o CircularProgressIndicator em vez de tentar renderizar uma câmera morta.
    if (mounted) {
      setState(() {
        _controller = null;
        _initializeControllerFuture = null;
      });
    }

    // 3. Agora é seguro descartar o antigo, pois ele não está mais na árvore de widgets
    await oldController?.dispose();

    // 4. Inicializa o novo controller
    final newController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    // Inicializa a conexão com o hardware
    final initFuture = newController.initialize();

    // Atualiza as variáveis de estado
    _controller = newController;
    _initializeControllerFuture = initFuture;

    try {
      await initFuture;

      // Configurações pós-inicialização
      if (mounted) {
        setState(() {
          _isTorchOn = false;
        });

        // Tenta garantir flash off (seguro ignorar erro aqui)
        try {
          await newController.setFlashMode(FlashMode.off);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Erro ao inicializar câmera: $e");
    }
  }

  // ALTERAÇÃO 3: Função para alternar entre as câmeras
  void _onSwitchCamera() {
    if (_cameras.length < 2) return;

    setState(() {
      // Alterna para a próxima câmera na lista
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    _startCameraConfig();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Câmeras frontais muitas vezes não suportam modo 'torch', então é bom envolver em try/catch
      if (_isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() => _isTorchOn = false);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        setState(() => _isTorchOn = true);
      }
    } catch (e) {
      debugPrint("Erro ao alternar flash (pode não ser suportado nesta câmera): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Flash não disponível nesta câmera")),
      );
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
      // Para fotos selfie, as vezes queremos desabilitar o espelhamento manual,
      // mas o padrão do plugin costuma ser ok.
      final image = await _controller!.takePicture();

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

              // 2. MÁSCARA
              CustomPaint(
                painter: OverlayWithHolePainter(
                  holeSize: squareSize,
                  overlayColor: Colors.black.withOpacity(0.7),
                ),
              ),

              // 3. BOTÃO FECHAR
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

              // 4. BOTÃO FLASH (Esconde se a câmera atual não tiver flash, opcional, aqui mantive visível)
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

              // ALTERAÇÃO 4: BOTÃO DE TROCAR CÂMERA (Novo botão adicionado)
              if (_cameras.length > 1) // Só mostra se tiver mais de 1 câmera
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 25,
                    child: IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                      onPressed: _onSwitchCamera,
                    ),
                  ),
                ),

              // 6. BOTÃO DE CAPTURA
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