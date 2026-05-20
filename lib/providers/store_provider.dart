import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/store_sticker.dart';
import '../config/constants.dart';
import 'package:isar/isar.dart';

class StoreProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  final _uuid = Uuid();

  List<StoreSticker> _stickers = [];
  List<StoreSticker> get stickers => _stickers;

  StoreProvider() {
    _isarService.watchStoreStickers().listen((data) {
      _stickers = data;
      notifyListeners();
    });
  }

  Future<void> saveStickerToStore({
    required String imagePath,
    String? name,
    String? category,
    bool isCustom = true,
    int? id,
    String? uuid,
  }) async {
    final sticker = StoreSticker(
      id: id ?? Isar.autoIncrement,
      uuid: uuid ?? _uuid.v4(),
      imagePath: imagePath,
      name: name,
      category: category,
      isCustom: isCustom,
      addedAt: DateTime.now(),
    );
    await _isarService.saveStoreSticker(sticker);
  }

  Future<void> deleteStickerFromStore(int id) async {
    await _isarService.deleteStoreSticker(id);
  }

  Future<void> deleteMultipleStickersFromStore(List<int> ids) async {
    for (final id in ids) {
      await _isarService.deleteStoreSticker(id);
    }
  }

  Future<void> updateStickersCategory(List<int> ids, String category) async {
    for (final id in ids) {
      final sticker = _stickers.firstWhere((s) => s.id == id);
      sticker.category = category;
      await _isarService.saveStoreSticker(sticker);
    }
  }

  Future<void> checkDefaultStickers() async {
    final current = await _isarService.getAllStoreStickers();
    if (current.isEmpty) {
      for (final path in AppConstants.defaultStickers) {
        await saveStickerToStore(
          imagePath: path,
          isCustom: false,
          name: 'Default',
          category: 'Gatos',
        );
      }
    }
  }
}
