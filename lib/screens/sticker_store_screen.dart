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

class _StickerStoreScreenState extends State<StickerStoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['Todos', 'Gatos', 'Perros', 'Editadas'];
  String _activeCategory = 'Todos';
  final Set<int> _selectedStickerIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeCategory = _categories[_tabController.index];
        _selectedStickerIds.clear();
      });
    });
    // Inicializar stickers por defecto si es necesario
    Future.microtask(() => context.read<JournalProvider>().checkDefaultStickers());
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedStickerIds.contains(id)) {
        _selectedStickerIds.remove(id);
      } else {
        _selectedStickerIds.add(id);
      }
    });
  }

  Future<void> _showGroupDialog() async {
    final theme = context.theme;
    final categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bg1,
        title: Text('Agrupar Stickers', style: TextStyle(color: theme.fg0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingresa la categoría para los ${_selectedStickerIds.length} stickers seleccionados:', style: TextStyle(color: theme.fg1)),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              style: TextStyle(color: theme.fg0),
              decoration: InputDecoration(
                hintText: 'Ej: Gatos, Anime, Vacaciones...',
                hintStyle: TextStyle(color: theme.fg1.withValues(alpha: 0.5)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.fg1)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: theme.fg1)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (categoryController.text.isNotEmpty) {
                final provider = context.read<JournalProvider>();
                await provider.updateStickersCategory(_selectedStickerIds.toList(), categoryController.text);
                setState(() => _selectedStickerIds.clear());
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.purple),
            child: const Text('Agrupar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBulkDelete() async {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bg1,
        title: Text('Eliminar Stickers', style: TextStyle(color: theme.fg0)),
        content: Text('¿Estás seguro de que deseas eliminar los ${_selectedStickerIds.length} stickers seleccionados?', style: TextStyle(color: theme.fg1)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: theme.fg1)),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<JournalProvider>();
              await provider.deleteMultipleStickersFromStore(_selectedStickerIds.toList());
              setState(() => _selectedStickerIds.clear());
              if (mounted) Navigator.pop(context);
            },
            child: Text('Eliminar', style: TextStyle(color: theme.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        leading: _selectedStickerIds.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedStickerIds.clear()))
            : null,
        title: Text(_selectedStickerIds.isNotEmpty ? '${_selectedStickerIds.length} seleccionados' : 'Tienda de Stickers'),
        actions: [
          if (_selectedStickerIds.isEmpty)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: _addFromGallery,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.purple,
          labelColor: theme.purple,
          unselectedLabelColor: theme.fg1,
          tabs: _categories.map((cat) => Tab(text: cat)).toList(),
        ),
      ),
      body: stickers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                final filteredStickers = stickers.where((s) {
                  if (_activeCategory == 'Todos') return true;
                  return s.category == _activeCategory;
                }).toList();

                if (filteredStickers.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay stickers en esta categoría',
                      style: TextStyle(color: theme.fg1),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredStickers.length,
                  itemBuilder: (context, index) {
                    final sticker = filteredStickers[index];
                    final isSelected = _selectedStickerIds.contains(sticker.id);
                    
                    return GestureDetector(
                      onTap: () {
                        if (_selectedStickerIds.isNotEmpty) {
                          _toggleSelection(sticker.id);
                        } else {
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
                        }
                      },
                      onLongPress: () => _toggleSelection(sticker.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? theme.purple.withValues(alpha: 0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? theme.purple : theme.fg0.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: sticker.isCustom
                                  ? Image.file(File(sticker.imagePath), fit: BoxFit.contain)
                                  : Image.asset(sticker.imagePath, fit: BoxFit.contain),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: theme.purple, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: _selectedStickerIds.isNotEmpty 
          ? Container(
              color: theme.bg1,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _showGroupDialog,
                    icon: Icon(Icons.group_work_rounded, color: theme.purple),
                    label: Text('Agrupar', style: TextStyle(color: theme.purple)),
                  ),
                  TextButton.icon(
                    onPressed: _confirmBulkDelete,
                    icon: Icon(Icons.delete_outline, color: theme.red),
                    label: Text('Borrar', style: TextStyle(color: theme.red)),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
