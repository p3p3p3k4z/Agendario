import 'package:isar/isar.dart';
import '../enums/entry_type.dart';
import 'sticker_data.dart';
import 'habit_record.dart';
import 'text_box_data.dart';

part 'journal_entry.g.dart';

// modelo central de la app: cada entrada del diario/agenda es un documento
// autocontenido que lleva dentro sus stickers, textos y habitos como objetos
// embebidos en vez de usar relaciones, asi isar los serializa en un solo bloque
@Collection()
class JournalEntry {
  Id id = Isar.autoIncrement;
  String? webFix;

  // uuid v4 como clave de negocio: permite identificar la misma entrada
  // entre isar local y firestore remoto sin colisiones
  // unique+replace: si llega un duplicado del sync lo sobreescribe
  @Index(unique: true, replace: true)
  late String uuid;

  // discriminador que determina como la ui renderiza esta entrada:
  // nota libre, evento con hora, recordatorio con alerta, etc
  @enumerated
  late EntryType type;

  String? title;

  //markdown
  String? content;

  // para notas es la fecha de creacion,
  // para eventos es la fecha programada, ordena la timeline
  @Index()
  late DateTime scheduledDate;

  List<StickerData>? stickers;
  List<TextBoxData>? textBoxes;
  List<HabitRecord>? habitRecords;

  // valor numerico del estado de animo (1-5 o similar),
  // alimenta graficas y analisis de correlacion con habitos
  double? moodScore;

  // para entradas tipo todo: indica si la tarea fue completada
  bool isCompleted = false;

  // para permitir fecha sin hora y viceversa
  DateTime? startTime;
  DateTime? endTime;

  int? colorValue;

  // flag de sincronizacion: false=pendiente de subir a firestore
  // indexado para que el servicio de sync consulte rapidamente los pendientes
  @Index()
  bool isSynced = false;

  // timestamp de la ultima edicion, el sync compara esta marca
  // entre local y remoto para resolver conflictos (gana la mas reciente)
  late DateTime lastModified;

  JournalEntry({
    required this.uuid,
    required this.type,
    required this.scheduledDate,
    required this.lastModified,
    this.title,
    this.content,
    this.stickers = const [],
    this.textBoxes = const [],
    this.habitRecords = const [],
    this.moodScore,
    this.isCompleted = false,
    this.startTime,
    this.endTime,
    this.colorValue,
    this.isSynced = false,
  });
}
