import 'package:flutter/material.dart';
import '../models/entities/text_box_data.dart';

// cuadro de texto flotante y arrastrable en el canvas del editor
// similar a StickerItem pero con contenido editable
class TextBoxItem extends StatelessWidget {
  final TextBoxData data;
  final BoxConstraints constraints;
  final Function(double dx, double dy) onDrag;
  // callback de edicion: cada cambio de texto se sube al estado del padre
  final Function(String) onChanged;
  final VoidCallback? onTap;

  const TextBoxItem({
    super.key,
    required this.data,
    required this.constraints,
    required this.onDrag,
    required this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // -100 y -20 centran el container de 200px de ancho y ~40px de alto
      // sobre el punto porcentual, similar al -50 de StickerItem
      left: (data.xPct ?? 0.5) * constraints.maxWidth - 100,
      top: (data.yPct ?? 0.5) * constraints.maxHeight - 20,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        onTap: onTap,
        child: Transform.rotate(
          angle: data.rotation ?? 0,
          child: Transform.scale(
            scale: data.scale ?? 1.0,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              // intrinsicheight permite que el container crezca
              // segun las lineas de texto sin necesidad de altura fija
              child: IntrinsicHeight(
                child: TextField(
                  // atencion: crea un nuevo controller en cada rebuild
                  // lo que puede causar perdida de posicion del cursor
                  // en ediciones rapidas (area de mejora futura)
                  controller: TextEditingController(text: data.content)..selection = TextSelection.collapsed(offset: data.content?.length ?? 0),
                  maxLines: null,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: data.fontSize ?? 16,
                    // reconstruye el Color a partir del int almacenado en isar
                    color: Color(data.colorValue ?? 0xFF000000),
                  ),
                  decoration: const InputDecoration.collapsed(hintText: 'Escribe...'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
