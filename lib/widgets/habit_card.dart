import 'package:flutter/material.dart';
import '../models/entities/habit_definition.dart';
import '../models/enums/habit_type.dart';
import '../config/theme.dart';

// card de habito con progreso visual e input rapido
// el tipo de input cambia segun HabitType:
//   boolean -> checkbox animado
//   counter -> botones +/-
//   scale_1_5 -> slider discreto
//   time -> display de minutos
class HabitCard extends StatelessWidget {
  final HabitDefinition habit;
  final double? todayValue;
  final VoidCallback onTap;
  final ValueChanged<double> onRecord;

  const HabitCard({
    super.key,
    required this.habit,
    required this.todayValue,
    required this.onTap,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final icon = habit.iconCodePoint != null
        ? IconData(habit.iconCodePoint!, fontFamily: 'MaterialIcons')
        : Icons.check_circle_outline;

    final progress = _calculateProgress();
    final color = _habitColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: todayValue != null
                ? color.withValues(alpha: 0.4)
                : GruvboxColors.bg1.withValues(alpha: 0.2),
            width: todayValue != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // icono con progreso circular
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: GruvboxColors.bg1.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(width: 16),
            // titulo y estado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GruvboxColors.bg0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusText(),
                    style: TextStyle(
                      fontSize: 13,
                      color: GruvboxColors.bg1.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // input rapido segun tipo
            _buildQuickInput(color),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInput(Color color) {
    switch (habit.type) {
      case HabitType.boolean:
        return _BooleanInput(
          value: todayValue == 1.0,
          color: color,
          onChanged: (v) => onRecord(v ? 1.0 : 0.0),
        );
      case HabitType.counter:
        return _CounterInput(
          value: todayValue ?? 0,
          color: color,
          onChanged: onRecord,
        );
      case HabitType.scale_1_5:
        return _ScaleDisplay(
          value: todayValue ?? 0,
          color: color,
          onChanged: onRecord,
        );
      case HabitType.time:
        return _TimeDisplay(
          value: todayValue ?? 0,
          color: color,
          onChanged: onRecord,
        );
    }
  }

  double _calculateProgress() {
    if (todayValue == null) return 0.0;
    if (habit.goal != null && habit.goal! > 0) {
      return (todayValue! / habit.goal!).clamp(0.0, 1.0);
    }
    if (habit.type == HabitType.boolean) return todayValue!;
    return todayValue! > 0 ? 0.5 : 0.0; // sin meta, solo indica actividad
  }

  String _statusText() {
    if (todayValue == null) return 'Sin registrar hoy';
    switch (habit.type) {
      case HabitType.boolean:
        return todayValue == 1.0 ? '✓ Completado' : 'Sin registrar hoy';
      case HabitType.counter:
        final goalStr = habit.goal != null ? ' / ${habit.goal!.toInt()}' : '';
        return '${todayValue!.toInt()}$goalStr';
      case HabitType.scale_1_5:
        return '${todayValue!.toInt()} de 5';
      case HabitType.time:
        return '${todayValue!.toInt()} min';
    }
  }

  Color _habitColor() {
    switch (habit.type) {
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

// --- Sub-widgets de input rapido ---

class _BooleanInput extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _BooleanInput({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: value ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: value
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _CounterInput extends StatelessWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _CounterInput({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniButton(
          Icons.remove,
          () => onChanged((value - 1).clamp(0, 9999)),
          color,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        _miniButton(Icons.add, () => onChanged(value + 1), color),
      ],
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _ScaleDisplay extends StatelessWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _ScaleDisplay({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = (i + 1).toDouble();
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              starValue <= value ? Icons.star : Icons.star_border,
              color: starValue <= value
                  ? color
                  : GruvboxColors.bg1.withValues(alpha: 0.3),
              size: 22,
            ),
          ),
        );
      }),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _TimeDisplay({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniButton(
          Icons.remove,
          () => onChanged((value - 5).clamp(0, 1440)),
          color,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${value.toInt()}m',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        _miniButton(Icons.add, () => onChanged(value + 5), color),
      ],
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
