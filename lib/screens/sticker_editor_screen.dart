import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
import '../config/app_colors.dart';

import '../models/entities/store_sticker.dart';

class StickerEditorScreen extends StatefulWidget {
  final String imagePath;
  final bool isCustom;
  final StoreSticker? existingSticker;

  const StickerEditorScreen({
    super.key,
    required this.imagePath,
    required this.isCustom,
    this.existingSticker,
  });

  @override
  State<StickerEditorScreen> createState() => _StickerEditorScreenState();
}

enum EditorMode { none, brushEraser, magicEraser, hue }

class _StickerEditorScreenState extends State<StickerEditorScreen> {
  img.Image? _processedImage;
  img.Image? _imageBeforeHue; // Para previsualización en tiempo real
  final List<img.Image> _undoStack = [];
  final List<img.Image> _redoStack = [];
  bool _isLoading = true;

  EditorMode _activeMode = EditorMode.none;
  double _brushSize = 20.0;
  double _hueValue = 0.0;
  
  Offset? _cursorPos;
  
  // Para mapeo de coordenadas
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    final bytes = await File(widget.imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      _processedImage = decoded;
    }
    setState(() => _isLoading = false);
  }

  void _resetImage() {
    _saveToUndo();
    _loadImage();
  }

  void _rotateImage() {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() {
      _processedImage = img.copyRotate(_processedImage!, angle: 90);
    });
  }

  void _saveToUndo() {
    if (_processedImage != null) {
      _undoStack.add(_processedImage!.clone());
      if (_undoStack.length > 20) _undoStack.removeAt(0);
      _redoStack.clear(); // Reset redo on new action
    }
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_processedImage!.clone());
      setState(() {
        _processedImage = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_processedImage!.clone());
      setState(() {
        _processedImage = _redoStack.removeLast();
      });
    }
  }

  void _applyBrush(Offset localPos) {
    if (_processedImage == null || _activeMode != EditorMode.brushEraser) return;

    final RenderBox box = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;

    // Mapear coordenadas de pantalla a píxeles de imagen
    final ratioX = _processedImage!.width / size.width;
    final ratioY = _processedImage!.height / size.height;

    final centerX = (localPos.dx * ratioX).toInt();
    final centerY = (localPos.dy * ratioY).toInt();
    final radius = (_brushSize * ratioX / 2).toInt();

    for (int y = centerY - radius; y < centerY + radius; y++) {
      for (int x = centerX - radius; x < centerX + radius; x++) {
        if (x >= 0 && x < _processedImage!.width && y >= 0 && y < _processedImage!.height) {
          // Circular brush
          final dx = x - centerX;
          final dy = y - centerY;
          if (dx * dx + dy * dy <= radius * radius) {
            _processedImage!.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }
    }
    setState(() {
      _cursorPos = localPos;
    });
  }

  void _applyMagicEraser(Offset localPos) {
    if (_processedImage == null || _activeMode != EditorMode.magicEraser) return;

    _saveToUndo();
    final RenderBox box = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;

    final ratioX = _processedImage!.width / size.width;
    final ratioY = _processedImage!.height / size.height;

    final startX = (localPos.dx * ratioX).toInt();
    final startY = (localPos.dy * ratioY).toInt();

    if (startX < 0 || startX >= _processedImage!.width || startY < 0 || startY >= _processedImage!.height) return;

    final targetPixel = _processedImage!.getPixel(startX, startY).clone();
    
    // Flood fill algorithm
    _floodFill(_processedImage!, startX, startY, targetPixel);
    
    setState(() {});
  }

  void _floodFill(img.Image image, int x, int y, img.Color targetPixel) {
    final List<Point> queue = [Point(x, y)];
    final visited = <int>{};
    
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      if (p.x < 0 || p.x >= image.width || p.y < 0 || p.y >= image.height) continue;
      
      final key = p.y * image.width + p.x;
      if (visited.contains(key)) continue;
      visited.add(key);

      final currentPixel = image.getPixel(p.x, p.y);
      if (currentPixel.r == targetPixel.r && 
          currentPixel.g == targetPixel.g && 
          currentPixel.b == targetPixel.b && 
          currentPixel.a == targetPixel.a) {
        
        image.setPixelRgba(p.x, p.y, 0, 0, 0, 0);
        
        queue.add(Point(p.x + 1, p.y));
        queue.add(Point(p.x - 1, p.y));
        queue.add(Point(p.x, p.y + 1));
        queue.add(Point(p.x, p.y - 1));
      }
    }
  }

  Future<void> _removeBackgroundAuto() async {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() => _isLoading = true);

    final firstPixel = _processedImage!.getPixel(0, 0).clone();
    for (var y = 0; y < _processedImage!.height; y++) {
      for (var x = 0; x < _processedImage!.width; x++) {
        final current = _processedImage!.getPixel(x, y);
        if (current.r == firstPixel.r && 
            current.g == firstPixel.g && 
            current.b == firstPixel.b && 
            current.a == firstPixel.a) {
          _processedImage!.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _applyFilters({double brightness = 1.0, double contrast = 1.0, double saturation = 1.0}) async {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() => _isLoading = true);

    // En image 4.x se usa adjustColor
    img.adjustColor(
      _processedImage!,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
    );
    
    setState(() => _isLoading = false);
  }

  Future<void> _updateHue(double value) async {
    if (_imageBeforeHue == null) return;
    
    // Guardar el valor para la UI
    _hueValue = value;

    // Aplicar rotación de tono (Hue)
    final original = _imageBeforeHue!;
    final result = original.clone();
    
    for (var pixel in result) {
      final hsv = _rgbToHsv(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
      var h = hsv[0] + value;
      while (h > 360) h -= 360;
      while (h < 0) h += 360;
      
      final rgb = _hsvToRgb(h, hsv[1], hsv[2]);
      pixel.r = rgb[0];
      pixel.g = rgb[1];
      pixel.b = rgb[2];
    }

    setState(() {
      _processedImage = result;
    });
  }

  // Helpers para conversión HSV (necesarios para Hue)
  List<double> _rgbToHsv(int r, int g, int b) {
    double rf = r / 255;
    double gf = g / 255;
    double bf = b / 255;
    double max = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    double min = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    double h = 0, s, v = max;
    double d = max - min;
    s = max == 0 ? 0 : d / max;
    if (max != min) {
      if (max == rf) {
        h = (gf - bf) / d + (gf < bf ? 6 : 0);
      } else if (max == gf) {
        h = (bf - rf) / d + 2;
      } else if (max == bf) {
        h = (rf - gf) / d + 4;
      }
      h /= 6;
    }
    return [h * 360, s, v];
  }

  List<int> _hsvToRgb(double h, double s, double v) {
    double r = 0, g = 0, b = 0;
    int i = (h / 60).floor() % 6;
    double f = h / 60 - (h / 60).floor();
    double p = v * (1 - s);
    double q = v * (1 - f * s);
    double t = v * (1 - (1 - f) * s);
    switch (i) {
      case 0: r = v; g = t; b = p; break;
      case 1: r = q; g = v; b = p; break;
      case 2: r = p; g = v; b = t; break;
      case 3: r = p; g = q; b = v; break;
      case 4: r = t; g = p; b = v; break;
      case 5: r = v; g = p; b = q; break;
    }
    return [(r * 255).round(), (g * 255).round(), (b * 255).round()];
  }

  // --- Superposición (Overlays) ---
  final List<StickerLayer> _layers = [];
  int? _selectedLayerIndex;

  void _addOverlay(img.Image image) {
    _saveToUndo();
    setState(() {
      _layers.add(StickerLayer(image: image));
      _selectedLayerIndex = _layers.length - 1;
    });
  }

  void _bakeOverlays() {
    if (_processedImage == null || _layers.isEmpty) return;
    _saveToUndo();
    
    var result = _processedImage!;
    final RenderBox box = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;

    // Ratios para mapear de pantalla a píxeles de imagen
    final ratioX = result.width / size.width;
    final ratioY = result.height / size.height;

    for (var layer in _layers) {
      // Escalar la imagen de la capa según el ratio y el factor de escala del sticker
      final baseSize = 150; // Tamaño base en pantalla
      final targetWidth = (baseSize * layer.scale * ratioX).toInt();
      final scaledLayer = img.copyResize(layer.image, width: targetWidth);

      // Componer en la posición mapeada
      img.compositeImage(
        result,
        scaledLayer,
        dstX: (layer.offset.dx * ratioX).toInt(),
        dstY: (layer.offset.dy * ratioY).toInt(),
      );
    }
    
    setState(() {
      _processedImage = result;
      _layers.clear();
      _selectedLayerIndex = null;
    });
  }

  Future<void> _showSaveDialog() async {
    if (_processedImage == null) return;

    final theme = context.theme;
    
    // Si no es un sticker existente o no es custom (es asset default), forzar copia
    bool canOverwrite = widget.existingSticker != null && widget.existingSticker!.isCustom;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bg1,
        title: Text('Guardar cambios', style: TextStyle(color: theme.fg0)),
        content: Text(
          canOverwrite 
              ? '¿Deseas guardar los cambios en este sticker o crear una copia nueva?' 
              : 'Se guardará como un nuevo sticker en tu galería.',
          style: TextStyle(color: theme.fg1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: theme.fg1)),
          ),
          if (canOverwrite)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSave(overwrite: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.blue),
              child: const Text('Sobrescribir', style: TextStyle(color: Colors.white)),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSave(overwrite: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.purple),
            child: const Text('Guardar Copia', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performSave({required bool overwrite}) async {
    setState(() => _isLoading = true);

    final directory = await getApplicationDocumentsDirectory();
    final path = overwrite 
        ? widget.existingSticker!.imagePath 
        : '${directory.path}/sticker_${const Uuid().v4()}.png';
    
    final bytes = img.encodePng(_processedImage!);
    await File(path).writeAsBytes(bytes);

    if (mounted) {
      await context.read<JournalProvider>().saveStickerToStore(
        imagePath: path,
        name: overwrite ? widget.existingSticker!.name : 'Copia de ${widget.existingSticker?.name ?? "Sticker"}',
        isCustom: true,
        id: overwrite ? widget.existingSticker!.id : null,
        uuid: overwrite ? widget.existingSticker!.uuid : null,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showStickerPicker() async {
    final theme = context.theme;
    final stickers = context.read<JournalProvider>().stickers;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Selecciona un sticker para superponer', style: TextStyle(color: theme.fg0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  final sticker = stickers[index];
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      final bytes = await File(sticker.imagePath).readAsBytes();
                      final decoded = img.decodeImage(bytes);
                      if (decoded != null) {
                        _addOverlay(decoded);
                      }
                      setState(() => _isLoading = false);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: sticker.isCustom 
                          ? Image.file(File(sticker.imagePath), fit: BoxFit.contain)
                          : Image.asset(sticker.imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      backgroundColor: theme.bgSoft,
      appBar: AppBar(
        title: const Text('Editor de Sticker'),
        actions: [
          if (_undoStack.isNotEmpty)
            IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          if (_redoStack.isNotEmpty)
            IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_layers.isNotEmpty) {
                _bakeOverlays();
              } else {
                _showSaveDialog();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onPanStart: (details) {
                              if (_activeMode == EditorMode.brushEraser) {
                                _saveToUndo();
                                setState(() => _cursorPos = details.localPosition);
                              } else if (_selectedLayerIndex != null) {
                                // Seleccionar capa para mover
                              }
                            },
                            onPanUpdate: (details) {
                              if (_activeMode == EditorMode.brushEraser) {
                                _applyBrush(details.localPosition);
                              } else if (_selectedLayerIndex != null) {
                                setState(() {
                                  _layers[_selectedLayerIndex!].offset += details.delta;
                                });
                              }
                            },
                            onPanEnd: (_) => setState(() => _cursorPos = null),
                            onTapDown: (details) {
                              if (_activeMode == EditorMode.magicEraser) {
                                _applyMagicEraser(details.localPosition);
                              }
                            },
                            child: Stack(
                              children: [
                                if (_processedImage != null)
                                  Image.memory(
                                    img.encodePng(_processedImage!) as dynamic,
                                    key: _imageKey,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  )
                                else 
                                  const Text('Error al cargar imagen'),
                                
                                // Capas de superposición
                                ...List.generate(_layers.length, (index) {
                                  final layer = _layers[index];
                                  return Positioned(
                                    left: layer.offset.dx,
                                    top: layer.offset.dy,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedLayerIndex = index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: _selectedLayerIndex == index 
                                            ? Border.all(color: theme.purple, width: 2)
                                            : null,
                                        ),
                                        child: Image.memory(
                                          img.encodePng(layer.image) as dynamic,
                                          width: 100 * layer.scale, // Escala básica
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          if (_cursorPos != null && _activeMode == EditorMode.brushEraser)
                            Positioned(
                              left: _cursorPos!.dx - _brushSize / 2,
                              top: _cursorPos!.dy - _brushSize / 2,
                              child: IgnorePointer(
                                child: Container(
                                  width: _brushSize,
                                  height: _brushSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.purple, width: 2),
                                    color: theme.purple.withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildToolbar(theme),
              ],
            ),
    );
  }

  Widget _buildToolbar(AppColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.bg1.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_activeMode == EditorMode.brushEraser)
            _buildControlBar(
              theme,
              icon: Icons.brush,
              value: _brushSize,
              min: 5,
              max: 150,
              onChanged: (v) => setState(() => _brushSize = v),
              label: '${_brushSize.toInt()}',
            ),
          if (_activeMode == EditorMode.hue)
            _buildControlBar(
              theme,
              icon: Icons.palette,
              value: _hueValue,
              min: -180,
              max: 180,
              onChanged: _updateHue,
              label: '${_hueValue.toInt()}°',
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.auto_fix_high,
                  label: 'Auto',
                  onTap: _removeBackgroundAuto,
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.brush,
                  label: 'Borrador',
                  isActive: _activeMode == EditorMode.brushEraser,
                  onTap: () => setState(() => _activeMode = _activeMode == EditorMode.brushEraser ? EditorMode.none : EditorMode.brushEraser),
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.color_lens,
                  label: 'Mágico',
                  isActive: _activeMode == EditorMode.magicEraser,
                  onTap: () => setState(() => _activeMode = _activeMode == EditorMode.magicEraser ? EditorMode.none : EditorMode.magicEraser),
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.layers_outlined,
                  label: 'Decorar',
                  onTap: _showStickerPicker,
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.invert_colors,
                  label: 'Tono',
                  isActive: _activeMode == EditorMode.hue,
                  onTap: () {
                    if (_activeMode != EditorMode.hue) {
                      _imageBeforeHue = _processedImage?.clone();
                      _hueValue = 0.0;
                    }
                    setState(() => _activeMode = _activeMode == EditorMode.hue ? EditorMode.none : EditorMode.hue);
                  },
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Brillo+',
                  onTap: () => _applyFilters(brightness: 1.1),
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.contrast,
                  label: 'Contr+',
                  onTap: () => _applyFilters(contrast: 1.2),
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.palette_outlined,
                  label: 'Satur+',
                  onTap: () => _applyFilters(saturation: 1.2),
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.rotate_right,
                  label: 'Rotar',
                  onTap: _rotateImage,
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.restore,
                  label: 'Reset',
                  onTap: _resetImage,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(
    AppColors theme, {
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.bgSoft.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.purple),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: theme.purple,
              onChanged: onChanged,
            ),
          ),
          Text(label, style: TextStyle(color: theme.purple, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColors theme,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? theme.purple.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? theme.purple : Colors.transparent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? theme.purple : theme.fg1, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(
                fontSize: 11, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.purple : theme.fg1,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

class StickerLayer {
  final img.Image image;
  Offset offset;
  double scale;
  StickerLayer({required this.image, this.offset = Offset.zero, this.scale = 1.0});
}
