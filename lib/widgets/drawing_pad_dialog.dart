import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/theme_provider.dart';

// Modal de limpieza total que despliega un lienzo blanco/negro segun el modo
// Permite al usuario rayar con su dedo/stylus y devuelve la ruta de la imagen .png resultante
class DrawingPadDialog extends StatefulWidget {
  const DrawingPadDialog({super.key});

  @override
  State<DrawingPadDialog> createState() => _DrawingPadDialogState();
}

class _DrawingPadDialogState extends State<DrawingPadDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _exportDrawing(SignatureController controller) async {
    if (controller.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final bytes = await controller.toPngBytes();
    if (bytes != null) {
      final cwd = await getApplicationDocumentsDirectory();
      // Guardamos el dibujo directamente entre los stickers
      final fileName = 'draw_${Uuid().v4()}.png';
      final file = File('${cwd.path}/$fileName');
      await file.writeAsBytes(bytes);
      // Devolver la ruta absoluta
      if (mounted) Navigator.pop(context, file.path);
    } else {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos en un modo oscuro, el lienzo debe ser blanco o el lapiz blanco
    // Para simplificar: lienzo contextual (bg1) y lapiz invertido (fg0)
    final canvasColor = context.theme.bg1;
    final strokeColor = context.theme.fg0;

    final controller = SignatureController(
      penStrokeWidth: 5,
      penColor: strokeColor,
      exportBackgroundColor: Colors.transparent,
      exportPenColor: strokeColor,
    );

    return Dialog(
      backgroundColor: context.theme.bg0,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header de Herramientas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dibujo Libre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.theme.fg0,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.undo, color: context.theme.fg1),
                      onPressed: () => controller.undo(),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: context.theme.red),
                      onPressed: () => controller.clear(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lienzo central de firma alojado en un contenedor estricto
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: controller,
              height: 350,
              backgroundColor: canvasColor,
            ),
          ),

          // Acciones Guardar / Cancelar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: context.theme.fg1),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _exportDrawing(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.orange,
                    foregroundColor: context.theme.bg0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Insertar Dibujo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
