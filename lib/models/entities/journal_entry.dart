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
  // id autoincrementado por isar, solo para uso interno del motor local
  Id id = Isar.autoIncrement;

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
  
  // cuerpo principal en markdown: el usuario escribe texto enriquecido
  // y el editor lo renderiza con flutter_markdown en modo preview
  String? content;

  // eje temporal principal: para notas es la fecha de creacion,
  // para eventos es la fecha programada, ordena la timeline
  @Index()
  late DateTime scheduledDate;

  // @embedded: isar guarda estos objetos inline dentro del documento
  // sin colecciones separadas ni joins, lo que acelera lecturas
  List<StickerData>? stickers;
  
  // cuadros de texto movibles del modo canvas, misma logica embedded
  List<TextBoxData>? textBoxes;

  // mediciones de habitos vinculadas a este dia especifico,
  // permite que la ia correlacione habitos con mood y contenido
  List<HabitRecord>? habitRecords;

  // valor numerico del estado de animo (1-5 o similar),
  // alimenta graficas y analisis de correlacion con habitos
  double? moodScore;

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
    this.isSynced = false,
  });
}
