import 'package:flutter/material.dart';

// modelo para logros/medallas desbloqueables por constancia
// no se persiste en isar: se recalcula cada vez que se consulta
// basandose en los datos reales de HabitRecord
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredDays;
  bool isUnlocked;
  DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredDays,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  // fabrica de logros predefinidos para cada habito
  static List<Achievement> defaultAchievements() => [
    Achievement(
      id: 'first_step',
      title: 'Primer Paso',
      description: 'Registra un hábito por primera vez',
      icon: Icons.eco,
      color: const Color(0xFF98971A),
      requiredDays: 1,
    ),
    Achievement(
      id: 'week_streak',
      title: 'Primera Semana',
      description: '7 días seguidos',
      icon: Icons.local_fire_department,
      color: const Color(0xFFD65D0E),
      requiredDays: 7,
    ),
    Achievement(
      id: 'two_weeks',
      title: 'Dos Semanas',
      description: '14 días seguidos',
      icon: Icons.star,
      color: const Color(0xFFD79921),
      requiredDays: 14,
    ),
    Achievement(
      id: 'month_streak',
      title: 'Un Mes',
      description: '30 días seguidos',
      icon: Icons.emoji_events,
      color: const Color(0xFFB16286),
      requiredDays: 30,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfecto',
      description: '100% cumplimiento en 7 días con meta',
      icon: Icons.verified,
      color: const Color(0xFF458588),
      requiredDays: 7,
    ),
  ];
}

// datos calculados de un habito para el dashboard
class HabitStats {
  final int currentStreak;
  final int bestStreak;
  final double completionRate; // 0.0 a 1.0
  final List<DailyValue> dailyValues; // ultimos 30 dias
  final List<double> weeklyAverages; // ultimas 4 semanas

  const HabitStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completionRate = 0.0,
    this.dailyValues = const [],
    this.weeklyAverages = const [],
  });
}

// un punto de dato diario para las graficas
class DailyValue {
  final DateTime date;
  final double value;
  const DailyValue(this.date, this.value);
}
