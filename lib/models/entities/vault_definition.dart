import 'package:isar/isar.dart';

part 'vault_definition.g.dart';

// The Vault Definition entity represents a user-created 'baul' (folder/context)
// to separate notes intelligently.
@Collection()
class VaultDefinition {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;

  // Icon reference mapped to a visual representation
  int? iconCode;

  // Color reference for UI presentation
  int? colorValue;

  // Si esta fijado a la barra principal
  @Index()
  bool isPinned;

  // Contraseña para bloquear acceso al baúl (opcional)
  String? password;

  // Si está oculto hasta que se agite el dispositivo
  @Index()
  bool isHidden;

  late DateTime createdAt;

  VaultDefinition({
    required this.uuid,
    required this.name,
    this.iconCode,
    this.colorValue,
    this.isPinned = false,
    this.password,
    this.isHidden = false,
    required this.createdAt,
  });
}
