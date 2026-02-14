import 'package:isar/isar.dart';

part 'sticker_data.g.dart';

// @embedded: este objeto vive dentro de JournalEntry, no es una coleccion
// separada. isar lo serializa como parte del documento padre
// modela una imagen decorativa posicionada sobre el lienzo de la nota
@embedded
class StickerData {
  // ruta a la imagen: puede ser un path de assets/ (interno) o del
  // filesystem del dispositivo si el usuario eligio de su galeria
  String? assetPath;
  
  // distingue la fuente: false=asset incluido en el apk,
  // true=imagen de galeria (se carga con File en vez de Asset)
  bool isCustom = false;

  // coordenadas como porcentaje (0.0 a 1.0) del lienzo:
  // asi la posicion se adapta a cualquier tamaño de pantalla
  // sin recalcular pixeles absolutos
  double? xPct;
  double? yPct;

  // multiplicador de tamaño sobre la base de 100px
  double? scale;

  // inclinacion visual, rango tipico de -pi a pi
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
