import 'package:flutter/material.dart';
import '../models/entities/sticker_data.dart';
import '../providers/theme_provider.dart';

// panel de edicion de sticker: bottom sheet con sliders de escala y rotacion
// convertido a StatefulWidget para reflejar cambios locales en los sliders
class StickerCustomizer extends StatefulWidget {
  final StickerData sticker;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const StickerCustomizer({
    super.key,
    required this.sticker,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<StickerCustomizer> createState() => _StickerCustomizerState();
}

class _StickerCustomizerState extends State<StickerCustomizer> {
  late double _scale;
  late double _rotation;

  @override
  void initState() {
    super.initState();
    _scale = widget.sticker.scale ?? 1.0;
    _rotation = widget.sticker.rotation ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Personalizar Sticker',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: context.theme.fg0,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.zoom_in, color: context.theme.fg1),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: 0.5,
                  max: 3.0,
                  activeColor: context.theme.blue,
                  inactiveColor: context.theme.blue.withValues(alpha: 0.2),
                  onChanged: (val) {
                    setState(() => _scale = val);
                    widget.sticker.scale = val;
                    widget.onUpdate();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.rotate_right, color: context.theme.fg1),
              Expanded(
                child: Slider(
                  value: _rotation,
                  min: -3.14,
                  max: 3.14,
                  activeColor: context.theme.orange,
                  inactiveColor: context.theme.orange.withValues(alpha: 0.2),
                  onChanged: (val) {
                    setState(() => _rotation = val);
                    widget.sticker.rotation = val;
                    widget.onUpdate();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete_outline),
            label: Text('Eliminar Sticker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.red.withValues(alpha: 0.1),
              foregroundColor: context.theme.red,
              elevation: 0,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
