import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/journal_provider.dart';
import '../providers/theme_provider.dart';
import '../config/app_colors.dart';
import 'package:gal/gal.dart';

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
  int _imageVersion = 0;
  double _exportScale = 1.0;
  double _tolerance = 20.0; // Intensidad/Tolerancia (0-100)
  Uint8List? _displayBytes; // Cache para evitar re-codificar en cada frame

  String _selectedCategory = 'Editadas';
  late TextEditingController _categoryController;

  // Para mapeo de coordenadas
  final GlobalKey _imageKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: _selectedCategory);
    _loadImage();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<Uint8List> _loadBytes(String path) async {
    if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } else {
      return await File(path).readAsBytes();
    }
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _loadBytes(widget.imagePath);
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        _processedImage = decoded;
        _updateDisplayBytes();
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    setState(() => _isLoading = false);
  }

  void _updateDisplayBytes() {
    if (_processedImage == null) return;
    _displayBytes = Uint8List.fromList(img.encodePng(_processedImage!));
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
      _updateDisplayBytes();
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
        _updateDisplayBytes();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_processedImage!.clone());
      setState(() {
        _processedImage = _redoStack.removeLast();
        _updateDisplayBytes();
      });
    }
  }

  Point? _getPixelFromOffset(Offset globalPos) {
    if (_processedImage == null) return null;
    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(globalPos);
    final size = box.size;

    if (size.width <= 0 ||
        size.height <= 0 ||
        localPos.dx.isNaN ||
        localPos.dy.isNaN)
      return null;

    final double imgW = _processedImage!.width.toDouble();
    final double imgH = _processedImage!.height.toDouble();
    final double containerW = size.width;
    final double containerH = size.height;

    final double imgAR = imgW / imgH;
    final double containerAR = containerW / containerH;

    double displayedW, displayedH, offsetX, offsetY;

    if (imgAR > containerAR) {
      displayedW = containerW;
      displayedH = containerW / imgAR;
      offsetX = 0;
      offsetY = (containerH - displayedH) / 2;
    } else {
      displayedH = containerH;
      displayedW = containerH * imgAR;
      offsetY = 0;
      offsetX = (containerW - displayedW) / 2;
    }

    final double xInImage = (localPos.dx - offsetX) * (imgW / displayedW);
    final double yInImage = (localPos.dy - offsetY) * (imgH / displayedH);

    // Account for InteractiveViewer transformation
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final transformedPoint = MatrixUtils.transformPoint(
      inverseMatrix,
      Offset(xInImage, yInImage),
    );

    if (transformedPoint.dx < 0 ||
        transformedPoint.dx >= imgW ||
        transformedPoint.dy < 0 ||
        transformedPoint.dy >= imgH)
      return null;

    return Point(transformedPoint.dx.toInt(), transformedPoint.dy.toInt());
  }

  void _applyBrush(Offset globalPos) {
    if (_processedImage == null || _activeMode != EditorMode.brushEraser)
      return;

    final pixel = _getPixelFromOffset(globalPos);
    if (pixel == null) return;

    // Radius mapping also needs scale adjustment
    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    // Better scale calculation:
    final double imgW = _processedImage!.width.toDouble();
    final double imgAR = imgW / _processedImage!.height.toDouble();
    final double containerAR = box.size.width / box.size.height;
    final double displayedW = imgAR > containerAR
        ? box.size.width
        : box.size.height * imgAR;
    final double pixelScale = imgW / displayedW;

    final centerX = pixel.x;
    final centerY = pixel.y;
    final radius = (_brushSize * pixelScale / 2).toInt();

    for (int y = centerY - radius; y < centerY + radius; y++) {
      for (int x = centerX - radius; x < centerX + radius; x++) {
        if (x >= 0 &&
            x < _processedImage!.width &&
            y >= 0 &&
            y < _processedImage!.height) {
          final dx = x - centerX;
          final dy = y - centerY;
          if (dx * dx + dy * dy <= radius * radius) {
            _processedImage!.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }
    }
    setState(() {
      final RenderBox box =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      _cursorPos = box.globalToLocal(globalPos);
      _updateDisplayBytes();
      _imageVersion++;
    });
  }

  void _applyMagicEraser(Offset globalPos) {
    if (_processedImage == null || _activeMode != EditorMode.magicEraser)
      return;

    _saveToUndo();
    final pixel = _getPixelFromOffset(globalPos);
    if (pixel == null) return;

    final targetColor = _processedImage!.getPixel(pixel.x, pixel.y).clone();
    final thresholdSquared = _tolerance * _tolerance * 3; // Escalado para RGB

    // Global color removal as requested
    for (var y = 0; y < _processedImage!.height; y++) {
      for (var x = 0; x < _processedImage!.width; x++) {
        final current = _processedImage!.getPixel(x, y);
        if (current.a == 0) continue;
        if (_getColorDistance(current, targetColor) < thresholdSquared) {
          _processedImage!.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    setState(() {
      _updateDisplayBytes();
      _imageVersion++;
    });
  }

  double _getColorDistance(img.Color c1, img.Color c2) {
    // Simple Euclidean distance in RGB
    final dr = c1.r - c2.r;
    final dg = c1.g - c2.g;
    final db = c1.b - c2.b;
    final da = c1.a - c2.a;
    return (dr * dr + dg * dg + db * db + da * da).toDouble();
  }

  Future<void> _removeBackgroundAuto() async {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() => _isLoading = true);

    // Sample multiple points to catch backgrounds
    final List<img.Color> samples = [
      _processedImage!.getPixel(0, 0).clone(),
      _processedImage!.getPixel(_processedImage!.width - 1, 0).clone(),
      _processedImage!.getPixel(0, _processedImage!.height - 1).clone(),
      _processedImage!
          .getPixel(_processedImage!.width - 1, _processedImage!.height - 1)
          .clone(),
    ];

    final thresholdSquared =
        (_tolerance * _tolerance * 4); // Usar el slider de intensidad

    for (var sample in samples) {
      if (sample.a == 0) continue;

      for (var y = 0; y < _processedImage!.height; y++) {
        for (var x = 0; x < _processedImage!.width; x++) {
          final current = _processedImage!.getPixel(x, y);
          if (current.a == 0) continue;
          if (_getColorDistance(current, sample) < thresholdSquared) {
            _processedImage!.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
      _updateDisplayBytes();
      _imageVersion++;
    });
  }

  Future<void> _applyFilters({
    double brightness = 1.0,
    double contrast = 1.0,
    double saturation = 1.0,
  }) async {
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
      _updateDisplayBytes();
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
      case 0:
        r = v;
        g = t;
        b = p;
        break;
      case 1:
        r = q;
        g = v;
        b = p;
        break;
      case 2:
        r = p;
        g = v;
        b = t;
        break;
      case 3:
        r = p;
        g = q;
        b = v;
        break;
      case 4:
        r = t;
        g = p;
        b = v;
        break;
      case 5:
        r = v;
        g = p;
        b = q;
        break;
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
    final RenderBox box =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
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

    final theme = context.readTheme;

    // Si no es un sticker existente o no es custom (es asset default), forzar copia
    bool canOverwrite =
        widget.existingSticker != null && widget.existingSticker!.isCustom;
    _categoryController.text =
        widget.existingSticker?.category ?? _selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bg1,
        title: Text('Guardar cambios', style: TextStyle(color: theme.fg0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              canOverwrite
                  ? '¿Deseas guardar los cambios en este sticker o crear una copia nueva?'
                  : 'Se guardará como un nuevo sticker en tu galería.',
              style: TextStyle(color: theme.fg1),
            ),
            const SizedBox(height: 16),
            Text(
              'Categoría:',
              style: TextStyle(color: theme.fg0, fontSize: 12),
            ),
            TextField(
              controller: _categoryController,
              style: TextStyle(color: theme.fg0),
              decoration: InputDecoration(
                hintText: 'Ej: Gatos, Perros, Editadas...',
                hintStyle: TextStyle(color: theme.fg1.withValues(alpha: 0.5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.fg1),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: theme.fg1)),
          ),
          if (canOverwrite)
            ElevatedButton(
              onPressed: () {
                _selectedCategory = _categoryController.text;
                Navigator.pop(context);
                _performSave(overwrite: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.blue),
              child: const Text(
                'Sobrescribir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              _selectedCategory = _categoryController.text;
              Navigator.pop(context);
              _performSave(overwrite: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.purple),
            child: const Text(
              'Guardar Copia',
              style: TextStyle(color: Colors.white),
            ),
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

    img.Image finalImage = _processedImage!;
    if (_exportScale != 1.0) {
      finalImage = img.copyResize(
        _processedImage!,
        width: (_processedImage!.width * _exportScale).toInt(),
        height: (_processedImage!.height * _exportScale).toInt(),
        interpolation: img.Interpolation.linear,
      );
    }

    final bytes = img.encodePng(finalImage);
    await File(path).writeAsBytes(bytes);

    if (mounted) {
      await context.read<JournalProvider>().saveStickerToStore(
        imagePath: path,
        name: overwrite
            ? widget.existingSticker!.name
            : 'Copia de ${widget.existingSticker?.name ?? "Sticker"}',
        category: _selectedCategory,
        isCustom: true,
        id: overwrite ? widget.existingSticker!.id : null,
        uuid: overwrite ? widget.existingSticker!.uuid : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sticker guardado en la tienda')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveToGallery() async {
    if (_processedImage == null) return;
    setState(() => _isLoading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Permiso de galería denegado');
        }
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/export_${const Uuid().v4()}.png';

      img.Image finalImage = _processedImage!;
      if (_exportScale != 1.0) {
        finalImage = img.copyResize(
          _processedImage!,
          width: (_processedImage!.width * _exportScale).toInt(),
          height: (_processedImage!.height * _exportScale).toInt(),
        );
      }

      final bytes = img.encodePng(finalImage);
      await File(path).writeAsBytes(bytes);

      await Gal.putImage(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado en la galería con éxito')),
        );
      }
    } catch (e) {
      debugPrint('Error exportando a galería: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showStickerPicker() async {
    final theme = context.readTheme;
    final stickers = context.read<JournalProvider>().stickers;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Selecciona un sticker para superponer',
              style: TextStyle(color: theme.fg0, fontWeight: FontWeight.bold),
            ),
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
                      try {
                        final bytes = await _loadBytes(sticker.imagePath);
                        final decoded = img.decodeImage(bytes);
                        if (decoded != null) {
                          _addOverlay(decoded);
                        }
                      } catch (e) {
                        debugPrint('Error loading sticker overlay: $e');
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
                            ? Image.file(
                                File(sticker.imagePath),
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                sticker.imagePath,
                                fit: BoxFit.contain,
                              ),
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
            icon: const Icon(Icons.download),
            onPressed: _saveToGallery,
            tooltip: 'Guardar en Galería',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
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
          ? Center(child: CircularProgressIndicator(color: theme.purple))
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.8,
                    ), // Fondo oscuro Photoshop
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
                                  setState(
                                    () => _cursorPos = details.globalPosition,
                                  );
                                } else if (_selectedLayerIndex != null) {
                                  // Seleccionar capa para mover
                                }
                              },
                              onPanUpdate: (details) {
                                if (_activeMode == EditorMode.brushEraser) {
                                  _applyBrush(details.globalPosition);
                                } else if (_selectedLayerIndex != null) {
                                  setState(() {
                                    _layers[_selectedLayerIndex!].offset +=
                                        details.delta;
                                  });
                                }
                              },
                              onPanEnd: (_) =>
                                  setState(() => _cursorPos = null),
                              onTapDown: (details) {
                                if (_activeMode == EditorMode.magicEraser) {
                                  _applyMagicEraser(details.globalPosition);
                                }
                              },
                              child: InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                minScale: 0.5,
                                maxScale: 20.0, // Más zoom
                                boundaryMargin: const EdgeInsets.all(
                                  400,
                                ), // Margen para mover libremente
                                panEnabled: _activeMode == EditorMode.none,
                                scaleEnabled:
                                    true, // Siempre permitir zoom con dos dedos
                                interactionEndFrictionCoefficient:
                                    0.001, // Más fluido
                                child: Stack(
                                  children: [
                                    if (_displayBytes != null)
                                      Container(
                                        key: _imageKey,
                                        child: Image.memory(
                                          _displayBytes!,
                                          key: ValueKey(
                                            'processed_$_imageVersion',
                                          ),
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true,
                                        ),
                                      )
                                    else if (_processedImage != null)
                                      const CircularProgressIndicator()
                                    else
                                      const Text('Error al cargar imagen'),

                                    // Capas de superposición
                                    ...List.generate(_layers.length, (index) {
                                      final layer = _layers[index];
                                      return Positioned(
                                        left: layer.offset.dx,
                                        top: layer.offset.dy,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedLayerIndex = index,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border:
                                                  _selectedLayerIndex == index
                                                  ? Border.all(
                                                      color: theme.purple,
                                                      width: 2,
                                                    )
                                                  : null,
                                            ),
                                            child: Image.memory(
                                              img.encodePng(layer.image)
                                                  as dynamic,
                                              width:
                                                  100 *
                                                  layer.scale, // Escala básica
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            if (_cursorPos != null &&
                                _activeMode == EditorMode.brushEraser)
                              Positioned(
                                left: _cursorPos!.dx - _brushSize / 2,
                                top: _cursorPos!.dy - _brushSize / 2,
                                child: IgnorePointer(
                                  child: Container(
                                    width: _brushSize,
                                    height: _brushSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.purple,
                                        width: 2,
                                      ),
                                      color: theme.purple.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
        color: theme.bg1.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
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
              label: '${_brushSize.toInt()}px',
            ),
          if (_activeMode == EditorMode.magicEraser)
            _buildControlBar(
              theme,
              icon: Icons.auto_fix_high,
              value: _tolerance,
              min: 1,
              max: 150,
              onChanged: (v) => setState(() => _tolerance = v),
              label: 'Intensidad: ${_tolerance.toInt()}',
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
          // Intensidad para Mágico y Auto
          if (_activeMode == EditorMode.magicEraser ||
              _activeMode == EditorMode.none)
            _buildControlBar(
              theme,
              icon: Icons.tune,
              value: _tolerance,
              min: 1,
              max: 150,
              onChanged: (v) => setState(() => _tolerance = v),
              label: 'Intensidad: ${_tolerance.toInt()}',
            ),
          _buildControlBar(
            theme,
            icon: Icons.zoom_in,
            value: _exportScale,
            min: 0.1,
            max: 2.0,
            onChanged: (v) => setState(() => _exportScale = v),
            label: 'Calidad: ${(_exportScale * 100).toInt()}%',
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
                  onTap: () => setState(
                    () => _activeMode = _activeMode == EditorMode.brushEraser
                        ? EditorMode.none
                        : EditorMode.brushEraser,
                  ),
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.color_lens,
                  label: 'Mágico',
                  isActive: _activeMode == EditorMode.magicEraser,
                  onTap: () => setState(
                    () => _activeMode = _activeMode == EditorMode.magicEraser
                        ? EditorMode.none
                        : EditorMode.magicEraser,
                  ),
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
                    setState(
                      () => _activeMode = _activeMode == EditorMode.hue
                          ? EditorMode.none
                          : EditorMode.hue,
                    );
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
        color: theme.bgSoft.withValues(alpha: 0.5),
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
          Text(
            label,
            style: TextStyle(color: theme.purple, fontWeight: FontWeight.bold),
          ),
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
            color: isActive
                ? theme.purple.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? theme.purple : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? theme.purple : theme.fg1, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? theme.purple : theme.fg1,
                ),
              ),
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
  StickerLayer({
    required this.image,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });
}
