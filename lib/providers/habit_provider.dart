import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../services/stats_service.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/habit_definition.dart';
import '../models/entities/habit_record.dart';
import '../models/enums/habit_type.dart';
import '../models/enums/entry_type.dart';
import '../models/achievement.dart';

// provider de habitos: gestiona CRUD, registro diario,
// estadisticas y logros de cada habito definido
class HabitProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  final StatsService _statsService = StatsService();
  final _uuid = const Uuid();

  // lista de habitos definidos por el usuario
  List<HabitDefinition> _habits = [];
  List<HabitDefinition> get habits => _habits;

  // estadisticas cacheadas por uuid de habito
  final Map<String, HabitStats> _statsCache = {};

  // logros por uuid de habito
  final Map<String, List<Achievement>> _achievementsCache = {};

  // registros del dia actual, indexados por habitUuid
  final Map<String, double> _todayRecords = {};
  Map<String, double> get todayRecords => _todayRecords;

  HabitProvider() {
    _init();
  }

  Future<void> _init() async {
    _habits = await _isarService.getAllHabits();
    await _loadTodayRecords();
    notifyListeners();
  }

  // carga los registros de hoy para mostrar progreso actual
  Future<void> _loadTodayRecords() async {
    _todayRecords.clear();
    final entries = await _isarService.getEntriesForDate(DateTime.now());
    for (final entry in entries) {
      if (entry.habitRecords != null) {
        for (final record in entry.habitRecords!) {
          if (record.habitDefinitionId != null && record.value != null) {
            _todayRecords[record.habitDefinitionId!] = record.value!;
          }
        }
      }
    }
  }

  // --- CRUD de habitos ---

  Future<void> createHabit({
    required String title,
    required HabitType type,
    int? iconCodePoint,
    double? goal,
  }) async {
    final habit = HabitDefinition(
      uuid: _uuid.v4(),
      title: title,
      type: type,
      iconCodePoint: iconCodePoint,
      goal: goal,
    );
    await _isarService.saveHabitDefinition(habit);
    _habits = await _isarService.getAllHabits();
    notifyListeners();
  }

  Future<void> updateHabit(HabitDefinition habit) async {
    await _isarService.saveHabitDefinition(habit);
    _habits = await _isarService.getAllHabits();
    notifyListeners();
  }

  Future<void> deleteHabit(int id) async {
    await _isarService.deleteHabit(id);
    _habits = await _isarService.getAllHabits();
    notifyListeners();
  }

  // --- Registro diario ---

  // registra un valor para un habito en el dia actual
  // busca o crea la JournalEntry del dia, agrega/actualiza el HabitRecord
  Future<void> recordHabit(String habitUuid, double value) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // buscar entrada existente del dia
    var entries = await _isarService.getEntriesForDate(today);
    JournalEntry entry;

    if (entries.isNotEmpty) {
      entry = entries.first;
    } else {
      // crear nueva entrada para hoy
      entry = JournalEntry(
        uuid: _uuid.v4(),
        type: EntryType.note,
        title: 'Registro de hábitos',
        scheduledDate: today,
        lastModified: now,
        habitRecords: [],
      );
    }

    // buscar o crear el record del habito
    final records = List<HabitRecord>.from(entry.habitRecords ?? []);
    final existingIndex = records.indexWhere(
      (r) => r.habitDefinitionId == habitUuid,
    );

    final record = HabitRecord(
      habitDefinitionId: habitUuid,
      value: value,
      timestamp: now,
    );

    if (existingIndex >= 0) {
      records[existingIndex] = record;
    } else {
      records.add(record);
    }
    entry.habitRecords = records;
    entry.lastModified = now;

    await _isarService.saveJournalEntry(entry);

    // actualizar cache local
    _todayRecords[habitUuid] = value;
    notifyListeners();
  }

  // --- Estadisticas ---

  // obtiene stats (con cache) para un habito
  Future<HabitStats> getStats(String habitUuid) async {
    if (!_statsCache.containsKey(habitUuid)) {
      _statsCache[habitUuid] = await _statsService.getFullStats(habitUuid);
    }
    return _statsCache[habitUuid]!;
  }

  // fuerza recarga de stats
  Future<HabitStats> refreshStats(String habitUuid) async {
    _statsCache[habitUuid] = await _statsService.getFullStats(habitUuid);
    notifyListeners();
    return _statsCache[habitUuid]!;
  }

  // --- Logros ---

  Future<List<Achievement>> getAchievements(String habitUuid) async {
    if (!_achievementsCache.containsKey(habitUuid)) {
      final habit = _habits.firstWhere((h) => h.uuid == habitUuid);
      _achievementsCache[habitUuid] = await _statsService.evaluateAchievements(
        habitUuid,
        habit.goal,
      );
    }
    return _achievementsCache[habitUuid]!;
  }

  // limpia caches al cambiar de dia o despues de registrar
  void invalidateCache(String habitUuid) {
    _statsCache.remove(habitUuid);
    _achievementsCache.remove(habitUuid);
  }
}
