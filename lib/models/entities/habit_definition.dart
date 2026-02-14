import 'package:isar/isar.dart';
import '../enums/habit_type.dart';

part 'habit_definition.g.dart';

// plantilla de habito: define QUE medir (ej: "Agua", "Lectura")
// es una coleccion propia porque su ciclo de vida es independiente
// de las entradas de diario (un habito puede existir sin notas)
@Collection()
class HabitDefinition {
  Id id = Isar.autoIncrement;

  // uuid para sincronizar la definicion con firestore,
  // misma estrategia que JournalEntry
  @Index(unique: true, replace: true)
  late String uuid;

  late String title;

  // truco: guarda el codePoint del icono (ej: Icons.water_drop.codePoint)
  // porque isar no puede serializar IconData directamente
  // se reconstruye con Icon(IconData(codePoint, fontFamily: 'MaterialIcons'))
  int? iconCodePoint;

  // tipo de medicion: define como la ui renderiza el input
  // boolean=checkbox, counter=+1/-1, scale_1_5=slider, time=minutos
  @enumerated
  late HabitType type;

  // meta diaria opcional para mostrar progreso (ej: 8 vasos de agua)
  // null = sin meta, el habito solo se registra sin porcentaje
  double? goal;

  bool isActive = true;

  HabitDefinition({
    required this.uuid,
    required this.title,
    required this.type,
    this.iconCodePoint,
    this.goal,
    this.isActive = true,
  });
}
