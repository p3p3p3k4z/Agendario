import 'package:isar/isar.dart';

part 'store_sticker.g.dart';

@Collection()
class StoreSticker {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  String? name;
  
  // path al archivo (si es custom) o ruta de asset
  late String imagePath;
  
  bool isCustom = false;

  late DateTime addedAt;

  StoreSticker({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.imagePath,
    this.name,
    this.isCustom = false,
    required this.addedAt,
  });
}
