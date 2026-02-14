import 'package:isar/isar.dart';
import '../enums/entry_type.dart';
import 'sticker_data.dart';
import 'habit_record.dart';

part 'journal_entry.g.dart';

@Collection()
class JournalEntry {
  // id autoincremental para uso local de Isar
  Id id = Isar.autoIncrement;

  // uuid unico para vinculacion con Firestore y evitar duplicados en sync
  @Index(unique: true, replace: true)
  late String uuid;

  // tipo de entrada para filtrado rapido en UI
  @enumerated
  late EntryType type;

  String? title;

  // contenido principal en formato Markdown
  String? content;

  // fecha programada para la agenda/diario (indexada para calendarios)
  @Index()
  late DateTime scheduledDate;

  // coleccion anidada de stickers con posiciones relativas
  // @embedded permite que Isar los guarde en el mismo documento
  List<StickerData>? stickers;

  // registros de habitos realizados en esta entrada especifica
  List<HabitRecord>? habitRecords;

  // puntaje de animo (0.0 a 1.0) analizado por IA o manual
  double? moodScore;

  // bandera para el gestor de sincronizacion
  @Index()
  bool isSynced = false;

  // timestamp para resolver conflictos de escritura (Last Write Wins)
  late DateTime lastModified;

  JournalEntry({
    required this.uuid,
    required this.type,
    required this.scheduledDate,
    required this.lastModified,
    this.title,
    this.content,
    this.stickers = const [],
    this.habitRecords = const [],
    this.moodScore,
    this.isSynced = false,
  });
}
