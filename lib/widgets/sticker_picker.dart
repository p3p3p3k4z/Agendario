import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';

// hoja inferior que presenta la galeria de stickers disponibles
// ofrece dos fuentes: assets predefinidos en AppConstants y
// fotos del dispositivo via image_picker
class StickerPicker extends StatelessWidget {
  // callback con dos args: la ruta y si es custom (de galeria)
  // el padre usa isCustom para decidir entre Image.asset e Image.file
  final Function(String path, bool isCustom) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  // abre la galeria nativa del dispositivo y retorna la ruta
  // del archivo elegido, marcado como custom=true para persistencia
  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      onStickerSelected(image.path, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ocupa 60% de la pantalla para dar espacio al grid
    // sin cubrir la nota completamente
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stickers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _pickCustomImage,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Personalizado'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: AppConstants.defaultStickers.length,
              itemBuilder: (context, index) {
                final path = AppConstants.defaultStickers[index];
                return GestureDetector(
                  onTap: () => onStickerSelected(path, false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(path, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
