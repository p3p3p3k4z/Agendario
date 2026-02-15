import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums/habit_type.dart';
import '../providers/habit_provider.dart';
import '../config/theme.dart';

// formulario para crear o editar un habito
class HabitEditorScreen extends StatefulWidget {
  const HabitEditorScreen({super.key});

  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  HabitType _selectedType = HabitType.boolean;
  int? _selectedIconCode;

  static final List<IconData> _availableIcons = [
    Icons.fitness_center,
    Icons.water_drop,
    Icons.menu_book,
    Icons.bedtime,
    Icons.self_improvement,
    Icons.directions_run,
    Icons.restaurant,
    Icons.code,
    Icons.music_note,
    Icons.brush,
    Icons.local_cafe,
    Icons.smoking_rooms,
    Icons.phone_android,
    Icons.pets,
    Icons.favorite,
    Icons.star,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Hábito')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // nombre del habito
            const Text(
              'Nombre',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: GruvboxColors.bg0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej: Beber agua, Leer, Ejercicio...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: GruvboxColors.green,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // tipo de medicion
            const Text(
              'Tipo de Medición',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: GruvboxColors.bg0,
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // meta diaria
            if (_selectedType == HabitType.counter ||
                _selectedType == HabitType.time) ...[
              const Text(
                'Meta Diaria (opcional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: GruvboxColors.bg0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _selectedType == HabitType.counter
                      ? 'Ej: 8 (vasos)'
                      : 'Ej: 30 (minutos)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: GruvboxColors.green,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // selector de icono
            const Text(
              'Ícono',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: GruvboxColors.bg0,
              ),
            ),
            const SizedBox(height: 12),
            _buildIconSelector(),
            const SizedBox(height: 40),

            // boton guardar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GruvboxColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Crear Hábito',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HabitType.values.map((type) {
        final selected = type == _selectedType;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? _typeColor(type).withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? _typeColor(type)
                    : GruvboxColors.bg1.withValues(alpha: 0.2),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _typeIcon(type),
                  color: selected
                      ? _typeColor(type)
                      : GruvboxColors.bg1.withValues(alpha: 0.5),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  _typeLabel(type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? _typeColor(type) : GruvboxColors.bg1,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableIcons.map((icon) {
        final selected = icon.codePoint == _selectedIconCode;
        return GestureDetector(
          onTap: () => setState(() => _selectedIconCode = icon.codePoint),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? GruvboxColors.green.withValues(alpha: 0.12)
                  : GruvboxColors.bg1.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? GruvboxColors.green
                    : GruvboxColors.bg1.withValues(alpha: 0.15),
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: selected
                  ? GruvboxColors.green
                  : GruvboxColors.bg1.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para el hábito')),
      );
      return;
    }

    final goal = double.tryParse(_goalController.text.trim());
    context.read<HabitProvider>().createHabit(
      title: title,
      type: _selectedType,
      iconCodePoint: _selectedIconCode,
      goal: goal,
    );
    Navigator.pop(context);
  }

  IconData _typeIcon(HabitType type) {
    switch (type) {
      case HabitType.boolean:
        return Icons.check_box;
      case HabitType.counter:
        return Icons.add_circle_outline;
      case HabitType.scale_1_5:
        return Icons.star_half;
      case HabitType.time:
        return Icons.timer;
    }
  }

  String _typeLabel(HabitType type) {
    switch (type) {
      case HabitType.boolean:
        return 'Sí/No';
      case HabitType.counter:
        return 'Contador';
      case HabitType.scale_1_5:
        return 'Escala 1-5';
      case HabitType.time:
        return 'Tiempo';
    }
  }

  Color _typeColor(HabitType type) {
    switch (type) {
      case HabitType.boolean:
        return GruvboxColors.green;
      case HabitType.counter:
        return GruvboxColors.blue;
      case HabitType.scale_1_5:
        return GruvboxColors.purple;
      case HabitType.time:
        return GruvboxColors.aqua;
    }
  }
}
