import 'package:isar/isar.dart';

part 'habit_record.g.dart';

@embedded
class HabitRecord {
  // id unico del habito definido para vincular datos
  String? habitDefinitionId;

  // valor registrado (ej: 1.0 para completado, 2500.0 para ml de agua)
  double? value;

  DateTime? timestamp;

  HabitRecord({
    this.habitDefinitionId,
    this.value,
    this.timestamp,
  });
}
