import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/sticker_data.dart';
import '../models/enums/entry_type.dart';
import '../providers/journal_provider.dart';
import '../config/theme.dart';
import '../widgets/sticker_picker.dart';
import '../widgets/sticker_item.dart';
import '../widgets/sticker_customizer.dart';

// editor unificado para crear/editar eventos, todos y recordatorios
// reutiliza el sistema de stickers del editor de notas para consistencia
// stateful porque gestiona formulario local + stickers mutables
class EventEditorScreen extends StatefulWidget {
  // null = crear nueva entrada, con valor = editar existente
  final JournalEntry? entry;
  // tipo predeterminado al crear, default evento
  final EntryType initialType;
  // fecha predeterminada al crear, default la del provider
  final DateTime? initialDate;

  const EventEditorScreen({
    super.key,
    this.entry,
    this.initialType = EntryType.event,
    this.initialDate,
  });

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late EntryType _selectedType;
  late DateTime _scheduledDate;
  DateTime? _startTime;
  DateTime? _endTime;
  int? _colorValue;
  List<StickerData> _stickers = [];
  bool _isPreviewMode = false;

  static const List<Color> _colorOptions = [
    GruvboxColors.blue,
    GruvboxColors.green,
    GruvboxColors.orange,
    GruvboxColors.red,
    GruvboxColors.purple,
    GruvboxColors.aqua,
    GruvboxColors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _contentController = TextEditingController(text: entry?.content ?? '');
    _selectedType = entry?.type ?? widget.initialType;
    _scheduledDate =
        entry?.scheduledDate ?? widget.initialDate ?? DateTime.now();
    _startTime = entry?.startTime;
    _endTime = entry?.endTime;
    _colorValue = entry?.colorValue;

    // copia profunda de stickers para no mutar la entry original
    _stickers =
        entry?.stickers
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
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título no puede estar vacío'),
          backgroundColor: GruvboxColors.red,
        ),
      );
      return;
    }

    final provider = context.read<JournalProvider>();
    final entry =
        widget.entry ??
        JournalEntry(
          uuid: const Uuid().v4(),
          type: _selectedType,
          scheduledDate: _scheduledDate,
          lastModified: DateTime.now(),
        );

    entry.title = _titleController.text.trim();
    entry.content = _contentController.text.isEmpty
        ? null
        : _contentController.text;
    entry.type = _selectedType;
    entry.scheduledDate = _scheduledDate;
    entry.startTime = _startTime;
    entry.endTime = _endTime;
    entry.colorValue = _colorValue;
    entry.stickers = _stickers;
    entry.lastModified = DateTime.now();

    provider.saveJournalEntry(entry);
    Navigator.pop(context);
  }

  // abre el date picker nativo
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: GruvboxColors.orange,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  // abre el time picker para hora de inicio o fin
  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime != null
              ? TimeOfDay.fromDateTime(_startTime!)
              : TimeOfDay.now())
        : (_endTime != null
              ? TimeOfDay.fromDateTime(_endTime!)
              : TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: GruvboxColors.orange,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        final dt = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          picked.hour,
          picked.minute,
        );
        if (isStart) {
          _startTime = dt;
        } else {
          _endTime = dt;
        }
      });
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
                yPct: 0.3,
              ),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMEd('es');
    final timeFormat = DateFormat.Hm();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: GruvboxColors.bg_soft,
      appBar: AppBar(
        backgroundColor: GruvboxColors.bg_soft,
        elevation: 0,
        title: Text(
          widget.entry != null ? 'Editar' : 'Nuevo',
          style: const TextStyle(
            color: GruvboxColors.bg0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // toggle preview para el campo markdown
          IconButton(
            icon: Icon(
              _isPreviewMode
                  ? Icons.edit_note_rounded
                  : Icons.visibility_outlined,
              color: GruvboxColors.bg0,
            ),
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
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
                  maxWidth: isLandscape ? 700 : constraints.maxWidth,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- selector de tipo ---
                        _buildTypeSelector(),
                        const SizedBox(height: 16),

                        // --- campo de titulo ---
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: GruvboxColors.bg0,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Título...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: GruvboxColors.bg1),
                          ),
                        ),
                        const Divider(color: GruvboxColors.bg1, height: 1),
                        const SizedBox(height: 12),

                        // --- fecha y hora ---
                        _buildDateTimeSection(dateFormat, timeFormat),
                        const SizedBox(height: 16),

                        // --- selector de color (solo para eventos) ---
                        if (_selectedType == EntryType.event) ...[
                          _buildColorSelector(),
                          const SizedBox(height: 16),
                        ],

                        // --- campo de contenido markdown ---
                        Container(
                          constraints: BoxConstraints(
                            minHeight: _stickers.isEmpty ? 300 : 500,
                          ),
                          child: _isPreviewMode
                              ? MarkdownBody(
                                  data: _contentController.text.isEmpty
                                      ? '*Sin contenido*'
                                      : _contentController.text,
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        p: const TextStyle(
                                          fontSize: 16,
                                          height: 1.6,
                                          color: GruvboxColors.bg0,
                                        ),
                                      ),
                                )
                              : TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: 'Notas, detalles...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: GruvboxColors.bg1,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: GruvboxColors.bg0,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),

                    // capa de stickers sobre el contenido
                    ..._stickers.asMap().entries.map((entry) {
                      return StickerItem(
                        sticker: entry.value,
                        constraints: BoxConstraints(
                          maxWidth: isLandscape ? 700 : constraints.maxWidth,
                          maxHeight: 1500,
                        ),
                        onDrag: (dx, dy) {
                          setState(() {
                            double canvasWidth = isLandscape
                                ? 700
                                : constraints.maxWidth;
                            const double canvasHeight = 1500;
                            entry.value.xPct =
                                ((entry.value.xPct ?? 0.5) * canvasWidth + dx) /
                                canvasWidth;
                            entry.value.yPct =
                                ((entry.value.yPct ?? 0.5) * canvasHeight +
                                    dy) /
                                canvasHeight;
                          });
                        },
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => StickerCustomizer(
                              sticker: entry.value,
                              onUpdate: () => setState(() {}),
                              onDelete: () {
                                setState(() => _stickers.removeAt(entry.key));
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
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _typeChip(EntryType.event, Icons.event, 'Evento', GruvboxColors.blue),
          const SizedBox(width: 8),
          _typeChip(
            EntryType.todo,
            Icons.check_circle_outline,
            'Pendiente',
            GruvboxColors.green,
          ),
          const SizedBox(width: 8),
          _typeChip(
            EntryType.reminder,
            Icons.notifications_outlined,
            'Recordatorio',
            GruvboxColors.purple,
          ),
        ],
      ),
    );
  }

  Widget _typeChip(EntryType type, IconData icon, String label, Color color) {
    final isActive = _selectedType == type;
    return FilterChip(
      selected: isActive,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
      backgroundColor: color.withValues(alpha: 0.08),
      selectedColor: color,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive ? color : color.withValues(alpha: 0.3),
        ),
      ),
      onSelected: (_) => setState(() => _selectedType = type),
    );
  }

  Widget _buildDateTimeSection(DateFormat dateFormat, DateFormat timeFormat) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // boton de fecha
        ActionChip(
          avatar: const Icon(
            Icons.calendar_today,
            size: 16,
            color: GruvboxColors.orange,
          ),
          label: Text(
            dateFormat.format(_scheduledDate),
            style: const TextStyle(color: GruvboxColors.bg0, fontSize: 13),
          ),
          backgroundColor: GruvboxColors.orange.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: GruvboxColors.orange.withValues(alpha: 0.3),
            ),
          ),
          onPressed: _pickDate,
        ),

        // hora inicio (solo para eventos)
        if (_selectedType == EntryType.event)
          ActionChip(
            avatar: const Icon(
              Icons.access_time,
              size: 16,
              color: GruvboxColors.blue,
            ),
            label: Text(
              _startTime != null
                  ? timeFormat.format(_startTime!)
                  : 'Hora inicio',
              style: TextStyle(
                color: _startTime != null
                    ? GruvboxColors.bg0
                    : GruvboxColors.bg1,
                fontSize: 13,
              ),
            ),
            backgroundColor: GruvboxColors.blue.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: GruvboxColors.blue.withValues(alpha: 0.3),
              ),
            ),
            onPressed: () => _pickTime(isStart: true),
          ),

        // hora fin (solo para eventos con hora inicio)
        if (_selectedType == EntryType.event && _startTime != null)
          ActionChip(
            avatar: const Icon(
              Icons.access_time_filled,
              size: 16,
              color: GruvboxColors.aqua,
            ),
            label: Text(
              _endTime != null ? timeFormat.format(_endTime!) : 'Hora fin',
              style: TextStyle(
                color: _endTime != null ? GruvboxColors.bg0 : GruvboxColors.bg1,
                fontSize: 13,
              ),
            ),
            backgroundColor: GruvboxColors.aqua.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: GruvboxColors.aqua.withValues(alpha: 0.3),
              ),
            ),
            onPressed: () => _pickTime(isStart: false),
          ),
      ],
    );
  }

  // eleccion rapida
  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GruvboxColors.bg1,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // opcion sin color
            GestureDetector(
              onTap: () => setState(() => _colorValue = null),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorValue == null
                        ? GruvboxColors.bg0
                        : GruvboxColors.bg1,
                    width: _colorValue == null ? 2.5 : 1,
                  ),
                ),
                child: _colorValue == null
                    ? const Icon(
                        Icons.close,
                        size: 14,
                        color: GruvboxColors.bg1,
                      )
                    : null,
              ),
            ),
            // colores predefinidos
            ...List.generate(_colorOptions.length, (index) {
              final color = _colorOptions[index];
              final isActive = _colorValue == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _colorValue = color.toARGB32()),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: isActive
                        ? Border.all(color: GruvboxColors.bg0, width: 2.5)
                        : null,
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
