import 'package:flutter/material.dart';
import '../models/entities/text_box_data.dart';
import '../providers/theme_provider.dart';

// cuadro de texto flotante y arrastrable en el canvas del editor
// similar a StickerItem pero con contenido editable
class TextBoxItem extends StatelessWidget {
  final TextBoxData data;
  final BoxConstraints constraints;
  final Function(double dx, double dy) onDrag;
  // callback de edicion: cada cambio de texto se sube al estado del padre
  final Function(String) onChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TextBoxItem({
    super.key,
    required this.data,
    required this.constraints,
    required this.onDrag,
    required this.onChanged,
    this.onDelete,
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
        onLongPress: () {
          if (onDelete != null) {
            _showDeleteDialog(context);
          }
        },
        child: Transform.rotate(
          angle: data.rotation ?? 0,
          child: Transform.scale(
            scale: data.scale ?? 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.bgSoft.withValues(alpha: 0.5),
                    border: Border.all(
                      color: context.theme.blue.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IntrinsicHeight(
                    child: TextField(
                      controller: TextEditingController(text: data.content)
                        ..selection = TextSelection.collapsed(
                          offset: data.content?.length ?? 0,
                        ),
                      maxLines: null,
                      onChanged: onChanged,
                      style: TextStyle(
                        fontSize: data.fontSize ?? 16,
                        color: Color(
                          (data.colorValue == null || data.colorValue == 0xFF000000)
                              ? context.theme.fg0.toARGB32()
                              : data.colorValue!,
                        ),
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Escribe...',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: () => _showDeleteDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.theme.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.theme.bg0, width: 2),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.readTheme.bg1,
        title: Text(
          'Eliminar texto',
          style: TextStyle(color: ctx.readTheme.fg0),
        ),
        content: Text(
          '¿Deseas eliminar este cuadro de texto?',
          style: TextStyle(color: ctx.readTheme.fg1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: ctx.readTheme.fg1)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: Text('Eliminar', style: TextStyle(color: ctx.readTheme.red)),
          ),
        ],
      ),
    );
  }
}
