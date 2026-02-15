import 'package:isar/isar.dart';

part 'habit_record.g.dart';

// registro concreto de una medicion: almacena CUANTO y CUANDO
// vive embebido dentro de JournalEntry, vinculado a un dia especifico
@embedded
class HabitRecord {
  String? webFix;

  // referencia al uuid de HabitDefinition (no su Id de isar)
  // se usa uuid porque los ids autoincrementados pueden cambiar entre sync
  String? habitDefinitionId;

  // valor flexible: 1.0=completado (boolean), 2500.0=ml (counter)
  double? value;

  DateTime? timestamp;

  HabitRecord({this.habitDefinitionId, this.value, this.timestamp});
}
