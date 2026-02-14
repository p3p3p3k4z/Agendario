import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/entities/journal_entry.dart';
import '../../models/entities/habit_definition.dart';
import '../../models/entities/sticker_data.dart';
import '../../models/entities/habit_record.dart';

class IsarService {
  static late Isar _db;

  // inicializacion asincrona del singleton
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    
    if (Isar.instanceNames.isEmpty) {
      _db = await Isar.open(
        [
          JournalEntrySchema,
          HabitDefinitionSchema,
        ],
        directory: dir.path,
        inspector: true,
      );
    } else {
      _db = Isar.getInstance()!;
    }
  }

  Isar get db => _db;

  // --- CRUD JOURNAL ENTRIES ---

  // guarda o actualiza una entrada
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _db.writeTxn(() async {
      await _db.journalEntrys.put(entry);
    });
  }

  // obtiene las entradas mas recientes
  Future<List<JournalEntry>> getRecentEntries({int limit = 20}) async {
    return await _db.journalEntrys
        .where()
        .sortByScheduledDateDesc()
        .limit(limit)
        .findAll();
  }

  // stream reactivo para la UI
  Stream<List<JournalEntry>> watchJournalEntries() {
    return _db.journalEntrys
        .where()
        .sortByScheduledDateDesc()
        .watch(fireImmediately: true);
  }

  // eliminar por id
  Future<void> deleteJournalEntry(Id id) async {
    await _db.writeTxn(() async {
      await _db.journalEntrys.delete(id);
    });
  }

  // --- CRUD HABIT DEFINITIONS ---

  Future<void> saveHabitDefinition(HabitDefinition habit) async {
    await _db.writeTxn(() async {
      await _db.habitDefinitions.put(habit);
    });
  }

  Future<List<HabitDefinition>> getAllHabits() async {
    return await _db.habitDefinitions.where().findAll();
  }

  Future<void> deleteHabit(Id id) async {
    await _db.writeTxn(() async {
      await _db.habitDefinitions.delete(id);
    });
  }

  Future<void> clearAll() async {
    await _db.writeTxn(() => _db.clear());
  }
}
