import 'dart:io';
import 'package:flutter/material.dart';
import '../models/entities/sticker_data.dart';

// elemento visual de sticker posicionado absolutamente en el canvas
// usa Positioned + porcentajes para ser responsive
// recibe callbacks de drag y tap del padre para actualizar posicion
class StickerItem extends StatelessWidget {
  final StickerData sticker;
  // constraints del canvas padre: necesario para convertir porcentaje a px
  final BoxConstraints constraints;
  // callback que devuelve delta en pixeles al arrastrar
  final Function(double dx, double dy) onDrag;
  final VoidCallback? onTap;

  const StickerItem({
    super.key,
    required this.sticker,
    required this.constraints,
    required this.onDrag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // convierte porcentaje a pixeles, -50 centra el sticker de 100px
      // sobre el punto exacto del toque (sin offset saldria esquinado)
      left: (sticker.xPct ?? 0.5) * constraints.maxWidth - 50,
      top: (sticker.yPct ?? 0.5) * constraints.maxHeight - 50,
      child: GestureDetector(
        // onPanUpdate dispara en cada frame del arrastre,
        // el padre convierte estos deltas a porcentaje y hace setState
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        onTap: onTap,
        child: Transform.rotate(
          angle: sticker.rotation ?? 0,
          child: Transform.scale(
            scale: sticker.scale ?? 1.0,
            // bifurca la carga: assets del apk vs archivos del filesystem
            // errorBuilder evita crash si el archivo fue borrado externamente
            child: sticker.isCustom 
              ? Image.file(
                  File(sticker.assetPath!),
                  width: 100,
                  height: 100,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.red),
                )
              : Image.asset(
                  sticker.assetPath!,
                  width: 100,
                  height: 100,
                  errorBuilder: (_, __, ___) => const Icon(Icons.error_outline, color: Colors.red),
                ),
          ),
        ),
      ),
    );
  }
}
