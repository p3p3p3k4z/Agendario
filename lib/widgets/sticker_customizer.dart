import 'package:flutter/material.dart';
import '../models/entities/sticker_data.dart';

// panel de edicion de sticker: bottom sheet con sliders de escala y rotacion
// patron de mutacion directa: modifica el objeto StickerData que recibe
// por referencia y llama onUpdate para que el padre haga setState
class StickerCustomizer extends StatelessWidget {
  // referencia directa al sticker que se esta editando,
  // los cambios del slider se reflejan inmediatamente en el canvas
  final StickerData sticker;
  final VoidCallback onDelete;
  // trigger para que el padre reconstruya el canvas con los nuevos valores
  final VoidCallback onUpdate;

  const StickerCustomizer({
    super.key,
    required this.sticker,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Personalizar Sticker',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.zoom_in),
              Expanded(
                // rango 0.5x a 3x: evita que el sticker sea invisible
                // o desproporcionadamente grande
                child: Slider(
                  value: sticker.scale ?? 1.0,
                  min: 0.5,
                  max: 3.0,
                  onChanged: (val) {
                    sticker.scale = val;
                    onUpdate();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.rotate_right),
              Expanded(
                // -pi a pi: giro completo de 360 grados
                child: Slider(
                  value: sticker.rotation ?? 0.0,
                  min: -3.14,
                  max: 3.14,
                  onChanged: (val) {
                    sticker.rotation = val;
                    onUpdate();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline),
            label: Text('Eliminar Sticker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
