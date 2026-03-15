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
import '../providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/drawing_pad_dialog.dart';
import '../widgets/audio_player_widget.dart';

// editor multimodal principal: combina texto markdown con elementos
// flotantes (stickers + cuadros de texto) en un lienzo tipo canvas
// gestiona controladores de texto y listas mutables locales
class EditorNotaScreen extends StatefulWidget {
  // null = crear nueva nota, con valor = editar nota existente
  final JournalEntry? entry;
  // seccion predeterminada a asignar (si es null se usa el actual del provider)
  final String? initialSectionId;

  const EditorNotaScreen({super.key, this.entry, this.initialSectionId});

  @override
  State<EditorNotaScreen> createState() => _EditorNotaScreenState();
}

class _EditorNotaScreenState extends State<EditorNotaScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // Variables for Auto-Save
  JournalEntry? _currentEntry;
  Timer? _autoSaveTimer;
  bool _isDirty = false;

  // listas locales mutables: se trabajan en memoria y solo se
  // persisten al presionar guardar, evitando escrituras parciales a isar
  List<StickerData> _stickers = [];
  List<TextBoxData> _textBoxes = [];
  List<String> _audioPaths = [];
  List<String> _tags = [];

  // motor de grabacion local
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

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

    _audioPaths = List.from(widget.entry?.audioPaths ?? []);
    _tags = List.from(widget.entry?.tags ?? []);
  }

  // Configura el temporizador para autoguardar despues de 2 segundos de inactividad
  void _scheduleAutoSave() {
    _isDirty = true;
    if (_autoSaveTimer?.isActive ?? false) {
      _autoSaveTimer!.cancel();
    }
    _autoSaveTimer = Timer(Duration(seconds: 2), () {
      _performSave(isAutoSave: true);
    });
  }

  // persiste la nota en la base de datos local
  // isAutoSave: si es trueno no cierra la pantalla
  void _performSave({bool isAutoSave = false}) {
    if (!mounted) return;

    // Si es un autoguardado y no hay cambios reales desde la última persistencia, ignorar
    if (isAutoSave && !_isDirty) return;

    final provider = context.read<JournalProvider>();
    final entry =
        _currentEntry ??
        JournalEntry(
          uuid: Uuid().v4(),
          type: EntryType.journal,
          sectionId: widget.initialSectionId ?? provider.currentSection,
          scheduledDate: DateTime.now(),
          lastModified: DateTime.now(),
        );

    entry.title = _titleController.text;
    entry.content = _contentController.text;
    entry.stickers = _stickers;
    entry.textBoxes = _textBoxes;
    entry.audioPaths = _audioPaths;
    entry.tags = _tags;
    entry.lastModified = DateTime.now();

    // Guardar referencia si fue creacion nueva para evitar duplicados en prox autosave
    _currentEntry = entry;

    provider.saveJournalEntry(entry);
    _isDirty = false; // Reset dirty flag after save

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

  Future<void> _pickImage(ImageSource source) async {
    final snackbarColor = context.theme.red;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _stickers.add(
            StickerData(
              assetPath: image.path,
              isCustom: true,
              xPct: 0.5,
              yPct: 0.3,
            ),
          );
        });
        _scheduleAutoSave();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Característica no disponible en este dispositivo.'),
          backgroundColor: snackbarColor,
        ),
      );
    }
  }

  Future<void> _openDrawingPad() async {
    final drawnImagePath = await showDialog<String>(
      context: context,
      builder: (_) => DrawingPadDialog(),
    );
    if (drawnImagePath != null) {
      setState(() {
        _stickers.add(
          StickerData(
            assetPath: drawnImagePath,
            isCustom: true,
            xPct: 0.5,
            yPct: 0.2,
          ),
        );
      });
      _scheduleAutoSave();
    }
  }

  Future<void> _toggleAudioRecording() async {
    final snackbarColor = context.theme.red;
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          if (path != null) {
            _audioPaths.add(path);
            _scheduleAutoSave();
          }
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          final cwd = await getApplicationDocumentsDirectory();
          final path = '${cwd.path}/audio_${Uuid().v4()}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() {
            _isRecording = true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grabación no soportada en esta plataforma.'),
          backgroundColor: snackbarColor,
        ),
      );
    }
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

  void _showTagEditor() {
    final theme = context.theme;
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bgSoft,
        title: Text('Gestionar Etiquetas', style: TextStyle(color: theme.fg0)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagController,
                style: TextStyle(color: theme.fg0),
                decoration: InputDecoration(
                  hintText: 'Nueva etiqueta...',
                  hintStyle: TextStyle(color: theme.fg1.withValues(alpha: 0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add_circle, color: theme.orange),
                    onPressed: () {
                      if (tagController.text.isNotEmpty) {
                        setState(() {
                          if (!_tags.contains(tagController.text)) {
                            _tags.add(tagController.text);
                          }
                        });
                        tagController.clear();
                        Navigator.pop(context);
                        _showTagEditor(); // Reopen to see updated list
                        _scheduleAutoSave();
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  if (val.isNotEmpty) {
                    setState(() {
                      if (!_tags.contains(val)) {
                        _tags.add(val);
                      }
                    });
                    Navigator.pop(context);
                    _showTagEditor();
                    _scheduleAutoSave();
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: TextStyle(color: theme.fg0, fontSize: 12)),
                  backgroundColor: theme.fg1.withValues(alpha: 0.1),
                  deleteIcon: Icon(Icons.close, size: 14, color: theme.red),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                    Navigator.pop(context);
                    _showTagEditor();
                    _scheduleAutoSave();
                  },
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: theme.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // capturamos los colores precompilados de Provider.of para evitar que los
    // sub-widgets como PopopMenu traten de acceder al Theme desfasadamente
    // en su etapa lazy-build provocando errores (Provider assertion errors)
    final themeFg0 = context.theme.fg0;
    final themeBlue = context.theme.blue;

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
        backgroundColor: context.theme.bgSoft,
        appBar: AppBar(
          backgroundColor: context.theme.bgSoft,
          title: TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Título...',
              border: InputBorder.none,
            ),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: context.theme.fg0,
            ),
          ),
          actions: [
            // Voice Record Handle
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic_none_outlined,
                color: _isRecording ? context.theme.red : context.theme.fg0,
              ),
              onPressed: _toggleAudioRecording,
            ),
            // Camera & Gallery Dropdown
            PopupMenuButton<ImageSource>(
              icon: Icon(Icons.camera_alt_outlined, color: themeBlue),
              onSelected: (source) => _pickImage(source),
              itemBuilder: (popupContext) => [
                PopupMenuItem(
                  value: ImageSource.camera,
                  child: Row(
                    children: [
                      Icon(Icons.camera, color: themeFg0, size: 20),
                      SizedBox(width: 12),
                      Text('Cámara'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ImageSource.gallery,
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, color: themeFg0, size: 20),
                      SizedBox(width: 12),
                      Text('Galería'),
                    ],
                  ),
                ),
              ],
            ),
            // Freehand Drawing
            IconButton(
              icon: Icon(Icons.draw_outlined, color: context.theme.purple),
              onPressed: _openDrawingPad,
            ),
            IconButton(
              icon: Icon(Icons.text_fields_rounded, color: context.theme.blue),
              onPressed: _addTextBox,
            ),
            IconButton(
              icon: Icon(
                Icons.add_reaction_outlined,
                color: context.theme.orange,
              ),
              onPressed: _showStickerPicker,
            ),
            IconButton(
              icon: Icon(Icons.tag_rounded, color: context.theme.orange),
              onPressed: _showTagEditor,
            ),
            IconButton(
              icon: Icon(
                _isPreviewMode
                    ? Icons.edit_note_rounded
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
            ),
            IconButton(
              icon: Icon(
                Icons.check_circle_rounded,
                color: context.theme.green,
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
                      // CAPA 1: texto markdown como fondo del lienzo y reproductor de audio
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Render Audio Tracks
                            ..._audioPaths.asMap().entries.map((entry) {
                              return AudioPlayerWidget(
                                audioPath: entry.value,
                                onDelete: () {
                                  setState(() {
                                    final file = File(_audioPaths[entry.key]);
                                    if (file.existsSync()) file.deleteSync();
                                    _audioPaths.removeAt(entry.key);
                                  });
                                  _scheduleAutoSave();
                                },
                              );
                            }),
                            SizedBox(height: _audioPaths.isEmpty ? 0 : 16),
                            // Markdown / Editor
                            _isPreviewMode
                                ? MarkdownBody(
                                    data: _contentController.text,
                                    styleSheet:
                                        MarkdownStyleSheet.fromTheme(
                                          Theme.of(context),
                                        ).copyWith(
                                          p: TextStyle(
                                            fontSize: 17,
                                            height: 1.6,
                                            color: context.theme.fg0,
                                          ),
                                        ),
                                  )
                                : TextField(
                                    controller: _contentController,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      hintText: 'Empieza a escribir...',
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.6,
                                      color: context.theme.fg0,
                                    ),
                                  ),
                          ],
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
                      }),

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
                      }),
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
