import '../models/achievement.dart';
import 'local_db/isar_service.dart';

// servicio de calculo de estadisticas de habitos
// funciones puras: reciben datos y devuelven estadisticas
// no mantienen estado, el provider es quien cachea resultados
class StatsService {
  final IsarService _isarService = IsarService();

  // obtiene los valores diarios de un habito en el rango dado
  Future<List<DailyValue>> getDailyValues(
    String habitUuid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await _isarService.getEntriesWithHabitRecords(
      habitUuid,
      startDate,
      endDate,
    );

    final values = <DailyValue>[];
    for (final entry in entries) {
      final record = entry.habitRecords?.firstWhere(
        (r) => r.habitDefinitionId == habitUuid,
      );
      if (record != null && record.value != null) {
        values.add(DailyValue(entry.scheduledDate, record.value!));
      }
    }
    values.sort((a, b) => a.date.compareTo(b.date));
    return values;
  }

  // calcula la racha actual de dias consecutivos con registro
  Future<int> getCurrentStreak(String habitUuid) async {
    int streak = 0;
    DateTime day = DateTime.now();

    while (true) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final entries = await _isarService.getEntriesWithHabitRecords(
        habitUuid,
        start,
        end,
      );

      if (entries.isEmpty) {
        // si es hoy y no hay registro, no rompe racha: consulta ayer
        if (streak == 0 && _isToday(day)) {
          day = day.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // calcula la mejor racha historica (ultimos 90 dias)
  Future<int> getBestStreak(String habitUuid) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));
    final dailyValues = await getDailyValues(habitUuid, start, now);

    if (dailyValues.isEmpty) return 0;

    int bestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < dailyValues.length; i++) {
      final diff = dailyValues[i].date
          .difference(dailyValues[i - 1].date)
          .inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > bestStreak) bestStreak = currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    return bestStreak;
  }

  // porcentaje de dias con registro en los ultimos N dias
  Future<double> getCompletionRate(String habitUuid, int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final dailyValues = await getDailyValues(habitUuid, start, now);
    if (days == 0) return 0.0;
    return dailyValues.length / days;
  }

  // promedios semanales para graficas de barras (ultimas N semanas)
  Future<List<double>> getWeeklyAverages(String habitUuid, int weeks) async {
    final now = DateTime.now();
    final averages = <double>[];

    for (int w = weeks - 1; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: (w + 1) * 7));
      final weekEnd = now.subtract(Duration(days: w * 7));
      final values = await getDailyValues(habitUuid, weekStart, weekEnd);

      if (values.isEmpty) {
        averages.add(0.0);
      } else {
        final sum = values.fold(0.0, (acc, v) => acc + v.value);
        averages.add(sum / values.length);
      }
    }
    return averages;
  }

  // calcula todas las estadisticas de un habito en una sola llamada
  Future<HabitStats> getFullStats(String habitUuid) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final results = await Future.wait([
      getCurrentStreak(habitUuid),
      getBestStreak(habitUuid),
      getCompletionRate(habitUuid, 30),
      getDailyValues(habitUuid, thirtyDaysAgo, now),
      getWeeklyAverages(habitUuid, 4),
    ]);

    return HabitStats(
      currentStreak: results[0] as int,
      bestStreak: results[1] as int,
      completionRate: results[2] as double,
      dailyValues: results[3] as List<DailyValue>,
      weeklyAverages: results[4] as List<double>,
    );
  }

  // evalua que logros estan desbloqueados para un habito
  Future<List<Achievement>> evaluateAchievements(
    String habitUuid,
    double? goal,
  ) async {
    final achievements = Achievement.defaultAchievements();
    final currentStreak = await getCurrentStreak(habitUuid);
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final dailyValues = await getDailyValues(habitUuid, sevenDaysAgo, now);

    for (final a in achievements) {
      switch (a.id) {
        case 'first_step':
          if (dailyValues.isNotEmpty || currentStreak > 0) {
            a.isUnlocked = true;
          }
          break;
        case 'week_streak':
          if (currentStreak >= 7) a.isUnlocked = true;
          break;
        case 'two_weeks':
          if (currentStreak >= 14) a.isUnlocked = true;
          break;
        case 'month_streak':
          if (currentStreak >= 30) a.isUnlocked = true;
          break;
        case 'perfect_week':
          // 100% de 7 dias con meta cumplida
          if (goal != null && dailyValues.length >= 7) {
            final allMet = dailyValues.every((v) => v.value >= goal);
            if (allMet) a.isUnlocked = true;
          }
          break;
      }
    }
    return achievements;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
