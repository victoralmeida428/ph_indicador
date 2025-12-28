// -----------------------------------------------------------------------------
// WIDGET INTERNO: Modal para adicionar UMA ÚNICA FAIXA
// -----------------------------------------------------------------------------
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/ui/widget/camera_capture_widget.dart';
import 'package:ph_indicador/src/core/utils/image_color_extractor.dart';
import 'package:ph_indicador/src/features/indicador/domain/entities/indicator_ranges.dart';
import 'package:uuid/uuid.dart';

class AddRangeSheet extends StatefulWidget {
  final Function(IndicatorRange) onAdd;

  const AddRangeSheet({required this.onAdd});

  @override
  State<AddRangeSheet> createState() => _AddRangeSheetState();
}

class _AddRangeSheetState extends State<AddRangeSheet> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  Color? _selectedColor;
  bool _isProcessing = false;
  final _sheetKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_sheetKey.currentState!.validate()) {
      if (_selectedColor == null) {
        // Mostra erro localmente ou via Toast
        return;
      }

      final range = IndicatorRange(
        id: const Uuid().v4(), // ID único para a faixa
        phMin: double.parse(_minController.text),
        phMax: double.parse(_maxController.text),
        colorHex: _selectedColor!.value,
      );

      widget.onAdd(range);
    }
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraCaptureWidget(
          onPictureTaken: (file) async {
            Navigator.pop(context);
            setState(() => _isProcessing = true);

            final color = await ImageColorExtractor.extractAverageColor(file.path);

            if (mounted) {
              setState(() {
                _selectedColor = color;
                _isProcessing = false;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Altura dinâmica baseada no conteúdo
      child: Form(
        key: _sheetKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Nova Faixa de pH",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "pH Min",
                      border: OutlineInputBorder(),
                      filled: true, fillColor: Colors.white10,
                    ),
                    validator: (v) => v!.isEmpty ? "Req." : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "pH Max",
                      border: OutlineInputBorder(),
                      filled: true, fillColor: Colors.white10,
                    ),
                    validator: (v) => v!.isEmpty ? "Req." : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview da Cor / Botão Câmera
            GestureDetector(
              onTap: _openCamera,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: _selectedColor ?? Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _selectedColor == null ? Colors.redAccent : Colors.white24,
                      width: _selectedColor == null ? 1 : 1
                  ),
                ),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: _selectedColor == null ? Colors.white : Colors.white54),
                    const SizedBox(width: 10),
                    Text(
                      _selectedColor == null ? "Toque para capturar cor (Obrigatório)" : "Cor Capturada",
                      style: TextStyle(
                          color: _selectedColor == null ? Colors.white : Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
              ),
              child: const Text("Adicionar Faixa"),
            )
          ],
        ),
      ),
    );
  }
}