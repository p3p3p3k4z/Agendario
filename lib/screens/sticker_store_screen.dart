import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
import 'sticker_editor_screen.dart';
import 'dart:io';

class StickerStoreScreen extends StatefulWidget {
  const StickerStoreScreen({super.key});

  @override
  State<StickerStoreScreen> createState() => _StickerStoreScreenState();
}

class _StickerStoreScreenState extends State<StickerStoreScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar stickers por defecto si es necesario
    Future.microtask(() => context.read<JournalProvider>().checkDefaultStickers());
  }

  Future<void> _addFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StickerEditorScreen(
              imagePath: image.path,
              isCustom: true,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final stickers = context.watch<JournalProvider>().stickers;

    return Scaffold(
      backgroundColor: theme.bgSoft,
      appBar: AppBar(
        title: const Text('Tienda de Stickers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _addFromGallery,
          ),
        ],
      ),
      body: stickers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                final sticker = stickers[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StickerEditorScreen(
                          imagePath: sticker.imagePath,
                          isCustom: sticker.isCustom,
                          existingSticker: sticker,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.fg0.withOpacity(0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: sticker.isCustom
                          ? Image.file(File(sticker.imagePath), fit: BoxFit.contain)
                          : Image.asset(sticker.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
