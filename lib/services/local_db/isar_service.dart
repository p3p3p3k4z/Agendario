import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/entities/journal_entry.dart';
import '../../models/entities/habit_definition.dart';
import '../../models/entities/sticker_data.dart';
import '../../models/entities/habit_record.dart';
import '../../models/entities/text_box_data.dart'; // Importante para la generacion

// punto unico de acceso a la base de datos local
// patron singleton garantizado por el static _db y el guard en init()
// todas las operaciones crud pasan por aqui para mantener una fuente de verdad
class IsarService {
  // instancia unica de isar compartida en toda la app
  static late Isar _db;

  // abre la bd solo si no hay instancia previa: evita el error
  // "instance already opened" al hacer hot restart en desarrollo
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    
    if (Isar.instanceNames.isEmpty) {
      _db = await Isar.open(
        // registra todas las colecciones que la app usa,
        // si se agrega un nuevo @Collection debe ir aqui tambien
        [
          JournalEntrySchema,
          HabitDefinitionSchema,
        ],
        directory: dir.path,
        // inspector: true habilita el debug browser de isar en dev
        inspector: true,
      );
    } else {
      _db = Isar.getInstance()!;
    }
  }

  Isar get db => _db;

  // toda escritura en isar requiere una transaccion explicita (writeTxn)
  // put() inserta si el id es nuevo, o actualiza si ya existe
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _db.writeTxn(() async {
      await _db.journalEntrys.put(entry);
    });
  }

  Future<List<JournalEntry>> getRecentEntries({int limit = 20}) async {
    return await _db.journalEntrys
        .where()
        .sortByScheduledDateDesc()
        .limit(limit)
        .findAll();
  }

  // stream reactivo: emite la lista completa cada vez que la coleccion cambia
  // fireImmediately=true dispara el primer evento al suscribirse,
  // asi el provider tiene datos desde el primer frame sin esperar cambios
  Stream<List<JournalEntry>> watchJournalEntries() {
    return _db.journalEntrys
        .where()
        .sortByScheduledDateDesc()
        .watch(fireImmediately: true);
  }

  Future<void> deleteJournalEntry(Id id) async {
    await _db.writeTxn(() async {
      await _db.journalEntrys.delete(id);
    });
  }

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

  // borra todo el contenido de todas las colecciones
  // util para debug o reset de la app, no para produccion
  Future<void> clearAll() async {
    await _db.writeTxn(() => _db.clear());
  }
}
