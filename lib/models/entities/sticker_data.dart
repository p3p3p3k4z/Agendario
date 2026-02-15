import 'package:isar/isar.dart';

part 'sticker_data.g.dart';

// @embedded: este objeto vive dentro de JournalEntry, no es una coleccion
// separada. isar lo serializa como parte del documento padre
// modela una imagen decorativa posicionada sobre el lienzo de la nota
@embedded
class StickerData {
  // ruta imagen
  String? assetPath;
  // true=imagen de galeria
  bool isCustom = false;

  String? webFix;

  // coordenadas como porcentaje (0.0 a 1.0) del lienzo:
  // asi la posicion se adapta a cualquier tamaño de pantalla
  // sin recalcular pixeles absolutos
  double? xPct;
  double? yPct;

  // ajustes de pantalla
  double? scale;
  double? rotation;

  StickerData({
    this.assetPath,
    this.isCustom = false,
    this.xPct = 0.5,
    this.yPct = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}
