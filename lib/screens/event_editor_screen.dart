import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/sticker_data.dart';
import '../models/enums/entry_type.dart';
import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
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
  // seccion predeterminada a asignar
  final String? initialSectionId;

  const EventEditorScreen({
    super.key,
    this.entry,
    this.initialType = EntryType.event,
    this.initialDate,
    this.initialSectionId,
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

  List<Color> get _colorOptions => [
    context.theme.blue,
    context.theme.green,
    context.theme.orange,
    context.theme.red,
    context.theme.purple,
    context.theme.aqua,
    context.theme.yellow,
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
        SnackBar(
          content: Text('El título no puede estar vacío'),
          backgroundColor: context.theme.red,
        ),
      );
      return;
    }

    final provider = context.read<JournalProvider>();
    final entry =
        widget.entry ??
        JournalEntry(
          uuid: Uuid().v4(),
          type: _selectedType,
          sectionId: widget.initialSectionId ?? provider.currentSection,
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
      builder: (context, child) {
        final isDark = context.read<ThemeProvider>().isDarkMode;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: context.theme.orange,
                    onPrimary: context.theme.bg0,
                    surface: context.theme.bg1,
                    onSurface: context.theme.fg0,
                  )
                : ColorScheme.light(
                    primary: context.theme.orange,
                    onPrimary: context.theme.bg0,
                    surface: context.theme.bg1,
                    onSurface: context.theme.fg0,
                  ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        final isDark = context.read<ThemeProvider>().isDarkMode;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: context.theme.orange,
                    onPrimary: context.theme.bg0,
                    surface: context.theme.bg1,
                    onSurface: context.theme.fg0,
                  )
                : ColorScheme.light(
                    primary: context.theme.orange,
                    onPrimary: context.theme.bg0,
                    surface: context.theme.bg1,
                    onSurface: context.theme.fg0,
                  ),
          ),
          child: child!,
        );
      },
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
      backgroundColor: context.theme.bgSoft,
      appBar: AppBar(
        backgroundColor: context.theme.bgSoft,
        elevation: 0,
        title: Text(
          widget.entry != null ? 'Editar' : 'Nuevo',
          style: TextStyle(
            color: context.theme.fg0,
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
              color: context.theme.fg0,
            ),
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          ),
          IconButton(
            icon: Icon(
              Icons.add_reaction_outlined,
              color: context.theme.orange,
            ),
            onPressed: _showStickerPicker,
          ),
          IconButton(
            icon: Icon(Icons.check_circle_rounded, color: context.theme.green),
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
                        SizedBox(height: 16),

                        // --- campo de titulo ---
                        TextField(
                          controller: _titleController,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.theme.fg0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Título...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: context.theme.fg1),
                          ),
                        ),
                        Divider(color: context.theme.bg1, height: 1),
                        SizedBox(height: 12),

                        // --- fecha y hora ---
                        _buildDateTimeSection(dateFormat, timeFormat),
                        SizedBox(height: 16),

                        // --- selector de color (solo para eventos) ---
                        if (_selectedType == EntryType.event) ...[
                          _buildColorSelector(),
                          SizedBox(height: 16),
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
                                        p: TextStyle(
                                          fontSize: 16,
                                          height: 1.6,
                                          color: context.theme.fg0,
                                        ),
                                      ),
                                )
                              : TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: 'Notas, detalles...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: context.theme.fg1,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: context.theme.fg0,
                                  ),
                                ),
                        ),
                        SizedBox(height: 100),
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
          _typeChip(EntryType.event, Icons.event, 'Evento', context.theme.blue),
          SizedBox(width: 8),
          _typeChip(
            EntryType.todo,
            Icons.check_circle_outline,
            'Pendiente',
            context.theme.green,
          ),
          SizedBox(width: 8),
          _typeChip(
            EntryType.reminder,
            Icons.notifications_outlined,
            'Recordatorio',
            context.theme.purple,
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
          SizedBox(width: 4),
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
          avatar: Icon(
            Icons.calendar_today,
            size: 16,
            color: context.theme.orange,
          ),
          label: Text(
            dateFormat.format(_scheduledDate),
            style: TextStyle(color: context.theme.fg0, fontSize: 13),
          ),
          backgroundColor: context.theme.orange.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: context.theme.orange.withValues(alpha: 0.3),
            ),
          ),
          onPressed: _pickDate,
        ),

        // hora inicio (solo para eventos)
        if (_selectedType == EntryType.event)
          ActionChip(
            avatar: Icon(
              Icons.access_time,
              size: 16,
              color: context.theme.blue,
            ),
            label: Text(
              _startTime != null
                  ? timeFormat.format(_startTime!)
                  : 'Hora inicio',
              style: TextStyle(
                color: _startTime != null
                    ? context.theme.bg0
                    : context.theme.bg1,
                fontSize: 13,
              ),
            ),
            backgroundColor: context.theme.blue.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: context.theme.blue.withValues(alpha: 0.3),
              ),
            ),
            onPressed: () => _pickTime(isStart: true),
          ),

        // hora fin (solo para eventos con hora inicio)
        if (_selectedType == EntryType.event && _startTime != null)
          ActionChip(
            avatar: Icon(
              Icons.access_time_filled,
              size: 16,
              color: context.theme.aqua,
            ),
            label: Text(
              _endTime != null ? timeFormat.format(_endTime!) : 'Hora fin',
              style: TextStyle(
                color: _endTime != null ? context.theme.bg0 : context.theme.bg1,
                fontSize: 13,
              ),
            ),
            backgroundColor: context.theme.aqua.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: context.theme.aqua.withValues(alpha: 0.3),
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
        Text(
          'Color',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.theme.fg1,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6),
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
                        ? context.theme.bg0
                        : context.theme.bg1,
                    width: _colorValue == null ? 2.5 : 1,
                  ),
                ),
                child: _colorValue == null
                    ? Icon(Icons.close, size: 14, color: context.theme.fg1)
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
                        ? Border.all(color: context.theme.fg0, width: 2.5)
                        : null,
                  ),
                  child: isActive
                      ? Icon(Icons.check, size: 14, color: Colors.white)
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
