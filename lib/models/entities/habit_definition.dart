import 'package:isar/isar.dart';
import '../enums/habit_type.dart';

part 'habit_definition.g.dart';

@Collection()
class HabitDefinition {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String title;

  // icono guardado como codePoint de MaterialIcons
  int? iconCodePoint;

  @enumerated
  late HabitType type;

  // meta diaria opcional (ej: 8 si son vasos de agua)
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
