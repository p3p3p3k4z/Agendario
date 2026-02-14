import 'package:isar/isar.dart';

part 'text_box_data.g.dart';

// cuadro de texto flotante en el lienzo: el usuario puede moverlo,
// rotarlo y redimensionarlo de forma independiente al contenido markdown
// se persiste embebido dentro de JournalEntry
@embedded
class TextBoxData {
  String? content;
  
  // misma logica de coordenadas porcentuales que StickerData:
  // permite reposicionar elementos sin depender de pixeles
  double? xPct;
  double? yPct;
  double? scale;
  double? rotation;
  
  // cada cuadro puede tener su propio tamaño de fuente,
  // util para titulos vs anotaciones pequeñas
  double? fontSize;

  // color almacenado como int argb (ej: 0xFF000000 = negro)
  // se reconstruye con Color(colorValue) en el widget
  int? colorValue;

  TextBoxData({
    this.content = 'Escribe aquí...',
    this.xPct = 0.5,
    this.yPct = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.fontSize = 16.0,
    this.colorValue = 0xFF000000,
  });
}
