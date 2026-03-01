import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/sticker_data.dart';
import '../models/entities/text_box_data.dart';
import '../models/enums/entry_type.dart';
import '../providers/journal_provider.dart';
import '../widgets/sticker_picker.dart';
import '../widgets/sticker_item.dart';
import '../widgets/sticker_customizer.dart';
import '../widgets/text_box_item.dart';
import '../config/theme.dart';

// editor multimodal principal: combina texto markdown con elementos
// flotantes (stickers + cuadros de texto) en un lienzo tipo canvas
// gestiona controladores de texto y listas mutables locales
class EditorNotaScreen extends StatefulWidget {
  // null = crear nueva nota, con valor = editar existente
  final JournalEntry? entry;
  const EditorNotaScreen({super.key, this.entry});

  @override
  State<EditorNotaScreen> createState() => _EditorNotaScreenState();
}

class _EditorNotaScreenState extends State<EditorNotaScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // Variables for Auto-Save
  JournalEntry? _currentEntry;
  Timer? _autoSaveTimer;

  // listas locales mutables: se trabajan en memoria y solo se
  // persisten al presionar guardar, evitando escrituras parciales a isar
  List<StickerData> _stickers = [];
  List<TextBoxData> _textBoxes = [];
  // alterna entre editor de texto plano y renderizado markdown
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );

    // Listeners for Auto-Save
    _titleController.addListener(_scheduleAutoSave);
    _contentController.addListener(_scheduleAutoSave);

    // copia profunda: crea nuevas instancias de StickerData para no
    // mutar los objetos originales del provider mientras se edita
    // si el usuario cancela, la entry original queda intacta
    _stickers =
        widget.entry?.stickers
            ?.map(
              (s) => StickerData(
                assetPath: s.assetPath,
                isCustom: s.isCustom,
                xPct: s.xPct,
                yPct: s.yPct,
                scale: s.scale,
                rotation: s.rotation,
              ),
            )
            .toList() ??
        [];

    // misma copia profunda para cuadros de texto
    _textBoxes =
        widget.entry?.textBoxes
            ?.map(
              (t) => TextBoxData(
                content: t.content,
                xPct: t.xPct,
                yPct: t.yPct,
                scale: t.scale,
                rotation: t.rotation,
                fontSize: t.fontSize,
                colorValue: t.colorValue,
              ),
            )
            .toList() ??
        [];
  }

  // Configura el temporizador para autoguardar despues de 2 segundos de inactividad
  void _scheduleAutoSave() {
    if (_autoSaveTimer?.isActive ?? false) {
      _autoSaveTimer!.cancel();
    }
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _performSave(isAutoSave: true);
    });
  }

  // persiste la nota en la base de datos local
  // isAutoSave: si es trueno no cierra la pantalla
  void _performSave({bool isAutoSave = false}) {
    if (!mounted) return;

    final provider = context.read<JournalProvider>();
    final entry =
        _currentEntry ??
        JournalEntry(
          uuid: const Uuid().v4(),
          type: EntryType.journal,
          scheduledDate: DateTime.now(),
          lastModified: DateTime.now(),
        );

    entry.title = _titleController.text;
    entry.content = _contentController.text;
    entry.stickers = _stickers;
    entry.textBoxes = _textBoxes;
    entry.lastModified = DateTime.now();

    // Guardar referencia si fue creacion nueva para evitar duplicados en prox autosave
    _currentEntry = entry;

    provider.saveJournalEntry(entry);

    if (!isAutoSave) {
      Navigator.pop(context);
    }
  }

  // Guarda y cierra la pantalla (manualmente por el boton verde)
  void _save() {
    if (_autoSaveTimer?.isActive ?? false) {
      _autoSaveTimer!.cancel();
    }
    _performSave(isAutoSave: false);
  }

  void _addTextBox() {
    setState(() {
      _textBoxes.add(TextBoxData(content: 'Nuevo texto', xPct: 0.5, yPct: 0.2));
    });
    _scheduleAutoSave();
  }

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
                yPct: 0.2,
              ),
            );
          });
          _scheduleAutoSave();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // detecta orientacion para limitar el ancho del canvas en landscape
    // evita que el contenido se estire demasiado
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Save on exit
        if (_autoSaveTimer?.isActive ?? false) {
          _autoSaveTimer!.cancel();
        }
        _performSave(isAutoSave: true);
      },
      child: Scaffold(
        backgroundColor: GruvboxColors.bg_soft,
        appBar: AppBar(
          backgroundColor: GruvboxColors.bg_soft,
          title: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Título...',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: GruvboxColors.bg0,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPreviewMode
                    ? Icons.edit_note_rounded
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
            ),
            IconButton(
              icon: const Icon(
                Icons.text_fields_rounded,
                color: GruvboxColors.blue,
              ),
              onPressed: _addTextBox,
            ),
            IconButton(
              icon: const Icon(
                Icons.add_reaction_outlined,
                color: GruvboxColors.orange,
              ),
              onPressed: _showStickerPicker,
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: GruvboxColors.green,
              ),
              onPressed: _save,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 800 : constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // CAPA 1: texto markdown como fondo del lienzo
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 100),
                        child: _isPreviewMode
                            ? MarkdownBody(
                                data: _contentController.text,
                                styleSheet:
                                    MarkdownStyleSheet.fromTheme(
                                      Theme.of(context),
                                    ).copyWith(
                                      p: const TextStyle(
                                        fontSize: 17,
                                        height: 1.6,
                                        color: GruvboxColors.bg0,
                                      ),
                                    ),
                              )
                            : TextField(
                                controller: _contentController,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  hintText: 'Empieza a escribir...',
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.6,
                                  color: GruvboxColors.bg0,
                                ),
                              ),
                      ),

                      // CAPA 2: cuadros de texto flotantes sobre el markdown
                      // cada elemento calcula su posicion convirtiendo porcentaje a pixeles
                      // segun el tamaño real del canvas
                      ..._textBoxes.asMap().entries.map((entry) {
                        return TextBoxItem(
                          data: entry.value,
                          constraints: BoxConstraints(
                            maxWidth: isLandscape ? 800 : constraints.maxWidth,
                            maxHeight: 2000,
                          ),
                          // convierte el delta del gesto (pixeles) de vuelta a porcentaje
                          // para mantener la posicion independiente de la pantalla
                          onDrag: (dx, dy) {
                            setState(() {
                              double canvasWidth = isLandscape
                                  ? 800
                                  : constraints.maxWidth;
                              double canvasHeight = constraints.maxHeight > 1000
                                  ? constraints.maxHeight
                                  : 1000;
                              entry.value.xPct =
                                  ((entry.value.xPct ?? 0.5) * canvasWidth +
                                      dx) /
                                  canvasWidth;
                              entry.value.yPct =
                                  ((entry.value.yPct ?? 0.5) * canvasHeight +
                                      dy) /
                                  canvasHeight;
                            });
                            _scheduleAutoSave();
                          },
                          onChanged: (val) {
                            entry.value.content = val;
                            _scheduleAutoSave();
                          },
                        );
                      }).toList(),

                      // CAPA 3: stickers decorativos, misma logica de posicionamiento
                      // al tocar un sticker abre el customizer para escala/rotacion/borrar
                      ..._stickers.asMap().entries.map((entry) {
                        return StickerItem(
                          sticker: entry.value,
                          constraints: BoxConstraints(
                            maxWidth: isLandscape ? 800 : constraints.maxWidth,
                            maxHeight: 2000,
                          ),
                          onDrag: (dx, dy) {
                            setState(() {
                              double canvasWidth = isLandscape
                                  ? 800
                                  : constraints.maxWidth;
                              double canvasHeight = constraints.maxHeight > 1000
                                  ? constraints.maxHeight
                                  : 1000;
                              entry.value.xPct =
                                  ((entry.value.xPct ?? 0.5) * canvasWidth +
                                      dx) /
                                  canvasWidth;
                              entry.value.yPct =
                                  ((entry.value.yPct ?? 0.5) * canvasHeight +
                                      dy) /
                                  canvasHeight;
                            });
                            _scheduleAutoSave();
                          },
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => StickerCustomizer(
                                sticker: entry.value,
                                onUpdate: () {
                                  setState(() {});
                                  _scheduleAutoSave();
                                },
                                onDelete: () {
                                  setState(() => _stickers.removeAt(entry.key));
                                  _scheduleAutoSave();
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
