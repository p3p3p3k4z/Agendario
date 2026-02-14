import 'package:isar/isar.dart';

part 'sticker_data.g.dart';

@embedded
class StickerData {
  String? assetPath;

  // posicion relativa horizontal 0.0-1.0
  double? xPct;

  // posicion relativa vertical 0.0-1.0
  double? yPct;

  double? scale;

  double? rotation;

  StickerData({
    this.assetPath,
    this.xPct = 0.5,
    this.yPct = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}
