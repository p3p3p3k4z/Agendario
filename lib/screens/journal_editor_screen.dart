import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/sticker_data.dart';
import '../models/enums/entry_type.dart';
import '../providers/journal_provider.dart';
import '../widgets/sticker_picker.dart';
import '../widgets/markdown_field.dart';
import '../widgets/sticker_item.dart';
import '../widgets/sticker_customizer.dart';

// version anterior del editor: solo soporta stickers
// usa MarkdownField como widget separado en lugar del TextField inline
// de EditorNotaScreen. se conserva como referencia o editor alternativo
class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? entry;
  const JournalEditorScreen({super.key, this.entry});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<StickerData> _stickers = [];
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _stickers =
        widget.entry?.stickers
            ?.map(
              (s) => StickerData(
                assetPath: s.assetPath,
                xPct: s.xPct,
                yPct: s.yPct,
                scale: s.scale,
                rotation: s.rotation,
              ),
            )
            .toList() ??
        [];
  }

  void _save() {
    final provider = context.read<JournalProvider>();
    final entry =
        widget.entry ??
        JournalEntry(
          uuid: const Uuid().v4(),
          type: EntryType.journal,
          scheduledDate: DateTime.now(),
          lastModified: DateTime.now(),
        );

    entry.title = _titleController.text;
    entry.content = _contentController.text;
    entry.stickers = _stickers;
    entry.lastModified = DateTime.now();

    provider.saveJournalEntry(entry);
    Navigator.pop(context);
  }

  // abre una hoja inferior con un callback de un solo argumento (path)
  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StickerPicker(
        onStickerSelected: (path, isCustom) {
          setState(() {
            _stickers.add(
              StickerData(
                assetPath: path,
                isCustom: isCustom,
                xPct: 0.5,
                yPct: 0.4,
              ),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // abre el customizer para un sticker especifico por indice
  // permite ajustar escala, rotacion o eliminar
  void _editSticker(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StickerCustomizer(
        sticker: _stickers[index],
        onUpdate: () => setState(() {}),
        onDelete: () {
          setState(() => _stickers.removeAt(index));
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.entry == null ? 'Nueva Nota' : 'Editar Nota'),
        actions: [
          IconButton(
            icon: Icon(
              _isPreviewMode ? Icons.edit_note : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              MarkdownField(
                titleController: _titleController,
                contentController: _contentController,
                isPreviewMode: _isPreviewMode,
              ),
              ..._stickers.asMap().entries.map((entry) {
                return StickerItem(
                  sticker: entry.value,
                  constraints: constraints,
                  onDrag: (dx, dy) {
                    setState(() {
                      entry.value.xPct =
                          ((entry.value.xPct ?? 0.5) * constraints.maxWidth +
                              dx) /
                          constraints.maxWidth;
                      entry.value.yPct =
                          ((entry.value.yPct ?? 0.5) * constraints.maxHeight +
                              dy) /
                          constraints.maxHeight;
                    });
                  },
                  onTap: () => _editSticker(entry.key),
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStickerPicker,
        label: const Text('Añadir Sticker'),
        icon: const Icon(Icons.add_reaction_outlined),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
