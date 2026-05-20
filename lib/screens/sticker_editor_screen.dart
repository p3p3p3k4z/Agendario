import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/store_provider.dart';
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

enum EditorMode { none, brushEraser, magicEraser, hue, crop, brightness, contrast, saturation }

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

  // Control de concurrencia para el procesamiento asíncrono de tono (Hue)
  bool _isHueProcessing = false;
  double? _pendingHueValue;

  // Control de concurrencia para brillo, contraste y saturación
  bool _isAdjustProcessing = false;
  double? _pendingBrightnessValue;
  double? _pendingContrastValue;
  double? _pendingSaturationValue;
  img.Image? _imageBeforeAdjustment;
  double _brightnessValue = 1.0;
  double _contrastValue = 1.0;
  double _saturationValue = 1.0;

  // Área seleccionada para el recorte (Photoshop style)
  Rect _cropRect = const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0);

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
    // Usamos encodeBmp para previsualización interactiva rápida (<5ms en lugar de >100ms de PNG)
    _displayBytes = Uint8List.fromList(img.encodeBmp(_processedImage!));
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

  void _flipImageHorizontal() {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() {
      _processedImage = img.copyFlip(
        _processedImage!,
        direction: img.FlipDirection.horizontal,
      );
      _updateDisplayBytes();
    });
  }

  void _flipImageVertical() {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() {
      _processedImage = img.copyFlip(
        _processedImage!,
        direction: img.FlipDirection.vertical,
      );
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

  Future<void> _applyMagicEraser(Offset globalPos) async {
    if (_processedImage == null || _activeMode != EditorMode.magicEraser)
      return;

    final pixel = _getPixelFromOffset(globalPos);
    if (pixel == null) return;

    _saveToUndo();
    setState(() => _isLoading = true);

    final imageCopy = _processedImage!.clone();
    final toleranceValue = _tolerance;
    final px = pixel.x;
    final py = pixel.y;

    try {
      final processed = await compute(
        applyMagicEraserStatic,
        MagicEraserParams(
          image: imageCopy,
          tolerance: toleranceValue,
          px: px,
          py: py,
        ),
      );

      setState(() {
        _processedImage = processed;
        _updateDisplayBytes();
        _imageVersion++;
      });
    } catch (e) {
      debugPrint('Error en borrador mágico: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _removeBackgroundAuto() async {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() => _isLoading = true);

    final imageCopy = _processedImage!.clone();
    final toleranceValue = _tolerance;

    try {
      final processed = await compute(
        removeBackgroundStatic,
        RemoveBgParams(image: imageCopy, tolerance: toleranceValue),
      );

      setState(() {
        _processedImage = processed;
        _updateDisplayBytes();
        _imageVersion++;
      });
    } catch (e) {
      debugPrint('Error en eliminación automática: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBrightness(double value) async {
    _brightnessValue = value;
    _applyAdjustment(_brightnessValue, _contrastValue, _saturationValue);
  }

  Future<void> _updateContrast(double value) async {
    _contrastValue = value;
    _applyAdjustment(_brightnessValue, _contrastValue, _saturationValue);
  }

  Future<void> _updateSaturation(double value) async {
    _saturationValue = value;
    _applyAdjustment(_brightnessValue, _contrastValue, _saturationValue);
  }

  Future<void> _applyAdjustment(double b, double c, double s) async {
    if (_imageBeforeAdjustment == null) return;

    if (_isAdjustProcessing) {
      _pendingBrightnessValue = b;
      _pendingContrastValue = c;
      _pendingSaturationValue = s;
      return;
    }

    _isAdjustProcessing = true;
    final original = _imageBeforeAdjustment!.clone();

    try {
      final processed = await compute(
        applyFiltersStatic,
        FilterParams(
          image: original,
          brightness: b,
          contrast: c,
          saturation: s,
        ),
      );

      if (mounted) {
        setState(() {
          _processedImage = processed;
          _updateDisplayBytes();
        });
      }
    } catch (e) {
      debugPrint('Error aplicando ajustes: $e');
    } finally {
      _isAdjustProcessing = false;
      if (_pendingBrightnessValue != null ||
          _pendingContrastValue != null ||
          _pendingSaturationValue != null) {
        final nextB = _pendingBrightnessValue ?? _brightnessValue;
        final nextC = _pendingContrastValue ?? _contrastValue;
        final nextS = _pendingSaturationValue ?? _saturationValue;
        _pendingBrightnessValue = null;
        _pendingContrastValue = null;
        _pendingSaturationValue = null;
        _applyAdjustment(nextB, nextC, nextS);
      }
    }
  }

  Future<void> _updateHue(double value) async {
    if (_imageBeforeHue == null) return;

    _hueValue = value;

    // Si ya hay un procesamiento en curso, guardar este valor como pendiente
    if (_isHueProcessing) {
      _pendingHueValue = value;
      return;
    }

    _isHueProcessing = true;
    final original = _imageBeforeHue!.clone();
    final shift = value;

    try {
      final processed = await compute(
        updateHueStatic,
        HueParams(image: original, shift: shift),
      );

      if (mounted) {
        setState(() {
          _processedImage = processed;
          _updateDisplayBytes();
        });
      }
    } catch (e) {
      debugPrint('Error en cambio de tono: $e');
    } finally {
      _isHueProcessing = false;
      // Si hay un valor pendiente que entró mientras procesábamos, ejecutarlo
      if (_pendingHueValue != null) {
        final nextValue = _pendingHueValue!;
        _pendingHueValue = null;
        _updateHue(nextValue);
      }
    }
  }

  Future<void> _cropImage() async {
    if (_processedImage == null) return;
    _saveToUndo();
    setState(() => _isLoading = true);

    final imageCopy = _processedImage!.clone();
    final rect = _cropRect; // normalized crop rect

    try {
      final cropped = await compute(
        cropImageStatic,
        CropParams(image: imageCopy, rect: rect),
      );

      setState(() {
        _processedImage = cropped;
        _updateDisplayBytes();
        _imageVersion++;
        // Reset crop rect after cropping
        _cropRect = const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0);
        _activeMode = EditorMode.none; // exit crop mode
      });
    } catch (e) {
      debugPrint('Error recortando imagen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Superposición (Overlays) ---
  final List<StickerLayer> _layers = [];
  int? _selectedLayerIndex;

  void _addOverlay(img.Image image) {
    _saveToUndo();
    final bmpBytes = Uint8List.fromList(img.encodeBmp(image));
    setState(() {
      _layers.add(StickerLayer(image: image, displayBytes: bmpBytes));
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

    final imageCopy = _processedImage!.clone();
    final scaleValue = _exportScale;

    try {
      final bytes = await compute(
        encodePngStatic,
        EncodeParams(image: imageCopy, scale: scaleValue),
      );

      await File(path).writeAsBytes(bytes);

      if (mounted) {
        await context.read<StoreProvider>().saveStickerToStore(
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
    } catch (e) {
      debugPrint('Error guardando sticker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

      final imageCopy = _processedImage!.clone();
      final scaleValue = _exportScale;

      final bytes = await compute(
        encodePngStatic,
        EncodeParams(image: imageCopy, scale: scaleValue),
      );

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
    final stickers = context.read<StoreProvider>().stickers;

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
                                cacheWidth: 200,
                              )
                            : Image.asset(
                                sticker.imagePath,
                                fit: BoxFit.contain,
                                cacheWidth: 200,
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
                                    _activeMode != EditorMode.crop, // Bloquear zoom durante recorte
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
                                              layer.displayBytes,
                                              width:
                                                  100 *
                                                  layer.scale, // Escala básica
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),

                                    // Crop Bounding Box overlay
                                    if (_activeMode == EditorMode.crop)
                                      Positioned.fill(
                                        child: CropOverlayWidget(
                                          initialRect: _cropRect,
                                          onRectChanged: (newRect) {
                                            _cropRect = newRect;
                                          },
                                        ),
                                      ),
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
          if (_activeMode == EditorMode.crop)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _cropImage,
                  icon: const Icon(Icons.crop, size: 24),
                  label: const Text(
                    'APLICAR RECORTE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
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
          if (_activeMode == EditorMode.brightness)
            _buildControlBar(
              theme,
              icon: Icons.wb_sunny_outlined,
              value: _brightnessValue,
              min: 0.5,
              max: 2.0,
              onChanged: _updateBrightness,
              label: '${((_brightnessValue - 1.0) * 100).toInt() > 0 ? '+' : ''}${((_brightnessValue - 1.0) * 100).toInt()}%',
            ),
          if (_activeMode == EditorMode.contrast)
            _buildControlBar(
              theme,
              icon: Icons.contrast,
              value: _contrastValue,
              min: 0.5,
              max: 2.0,
              onChanged: _updateContrast,
              label: '${((_contrastValue - 1.0) * 100).toInt() > 0 ? '+' : ''}${((_contrastValue - 1.0) * 100).toInt()}%',
            ),
          if (_activeMode == EditorMode.saturation)
            _buildControlBar(
              theme,
              icon: Icons.palette_outlined,
              value: _saturationValue,
              min: 0.0,
              max: 2.0,
              onChanged: _updateSaturation,
              label: '${((_saturationValue - 1.0) * 100).toInt() > 0 ? '+' : ''}${((_saturationValue - 1.0) * 100).toInt()}%',
            ),
          // Intensidad para Auto
          if (_activeMode == EditorMode.none)
            _buildControlBar(
              theme,
              icon: Icons.tune,
              value: _tolerance,
              min: 1,
              max: 150,
              onChanged: (v) => setState(() => _tolerance = v),
              label: 'Intensidad Auto: ${_tolerance.toInt()}',
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
          if (_selectedLayerIndex != null && _selectedLayerIndex! < _layers.length) ...[
            _buildControlBar(
              theme,
              icon: Icons.zoom_in,
              value: _layers[_selectedLayerIndex!].scale,
              min: 0.2,
              max: 5.0,
              onChanged: (v) => setState(() => _layers[_selectedLayerIndex!].scale = v),
              label: 'Escala Capa: ${(_layers[_selectedLayerIndex!].scale * 100).toInt()}%',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.red.withValues(alpha: 0.15),
                        foregroundColor: theme.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _layers.removeAt(_selectedLayerIndex!);
                          _selectedLayerIndex = null;
                        });
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Eliminar Capa'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.purple.withValues(alpha: 0.15),
                        foregroundColor: theme.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() => _selectedLayerIndex = null);
                      },
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Deseleccionar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _bakeOverlays,
                      icon: const Icon(Icons.layers, size: 20),
                      label: const Text('Fusionar Capas'),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                  icon: Icons.crop,
                  label: 'Recortar',
                  isActive: _activeMode == EditorMode.crop,
                  onTap: () => setState(
                    () => _activeMode = _activeMode == EditorMode.crop
                        ? EditorMode.none
                        : EditorMode.crop,
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
                  label: 'Brillo',
                  isActive: _activeMode == EditorMode.brightness,
                  onTap: () {
                    if (_activeMode != EditorMode.brightness) {
                      _saveToUndo();
                      _imageBeforeAdjustment = _processedImage?.clone();
                      _brightnessValue = 1.0;
                      _contrastValue = 1.0;
                      _saturationValue = 1.0;
                    }
                    setState(
                      () => _activeMode = _activeMode == EditorMode.brightness
                          ? EditorMode.none
                          : EditorMode.brightness,
                    );
                  },
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.contrast,
                  label: 'Contraste',
                  isActive: _activeMode == EditorMode.contrast,
                  onTap: () {
                    if (_activeMode != EditorMode.contrast) {
                      _saveToUndo();
                      _imageBeforeAdjustment = _processedImage?.clone();
                      _brightnessValue = 1.0;
                      _contrastValue = 1.0;
                      _saturationValue = 1.0;
                    }
                    setState(
                      () => _activeMode = _activeMode == EditorMode.contrast
                          ? EditorMode.none
                          : EditorMode.contrast,
                    );
                  },
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.palette_outlined,
                  label: 'Saturación',
                  isActive: _activeMode == EditorMode.saturation,
                  onTap: () {
                    if (_activeMode != EditorMode.saturation) {
                      _saveToUndo();
                      _imageBeforeAdjustment = _processedImage?.clone();
                      _brightnessValue = 1.0;
                      _contrastValue = 1.0;
                      _saturationValue = 1.0;
                    }
                    setState(
                      () => _activeMode = _activeMode == EditorMode.saturation
                          ? EditorMode.none
                          : EditorMode.saturation,
                    );
                  },
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
                  icon: Icons.flip,
                  label: 'Espejo H',
                  onTap: _flipImageHorizontal,
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _buildToolButton(
                  icon: Icons.flip_camera_android,
                  label: 'Espejo V',
                  onTap: _flipImageVertical,
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
  final Uint8List displayBytes;
  Offset offset;
  double scale;
  StickerLayer({
    required this.image,
    required this.displayBytes,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });
}

class CropPainter extends CustomPainter {
  final Rect cropRect; // in screen coordinates

  CropPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paintOuter = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Draw the 4 outer shaded regions (Photoshop dim effect)
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cropRect.top), paintOuter);
    canvas.drawRect(Rect.fromLTRB(0, cropRect.bottom, size.width, size.height), paintOuter);
    canvas.drawRect(Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom), paintOuter);
    canvas.drawRect(Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom), paintOuter);

    // Draw crop border
    final paintBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, paintBorder);

    // Draw Rule of Thirds Grid (Photoshop grid)
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    // Vertical lines
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth, cropRect.top),
      Offset(cropRect.left + thirdWidth, cropRect.bottom),
      paintGrid,
    );
    canvas.drawLine(
      Offset(cropRect.left + 2 * thirdWidth, cropRect.top),
      Offset(cropRect.left + 2 * thirdWidth, cropRect.bottom),
      paintGrid,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight),
      Offset(cropRect.right, cropRect.top + thirdHeight),
      paintGrid,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + 2 * thirdHeight),
      Offset(cropRect.right, cropRect.top + 2 * thirdHeight),
      paintGrid,
    );

    // Draw thick premium corner handles (Photoshop corner styles)
    final paintCorner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    const cornerLen = 24.0;

    // Top-Left corner
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLen, 0), paintCorner);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, cornerLen), paintCorner);

    // Top-Right corner
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-cornerLen, 0), paintCorner);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, cornerLen), paintCorner);

    // Bottom-Left corner
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLen, 0), paintCorner);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -cornerLen), paintCorner);

    // Bottom-Right corner
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLen, 0), paintCorner);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -cornerLen), paintCorner);
  }

  @override
  bool shouldRepaint(covariant CropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

class CropOverlayWidget extends StatefulWidget {
  final Rect initialRect;
  final ValueChanged<Rect> onRectChanged;

  const CropOverlayWidget({
    super.key,
    required this.initialRect,
    required this.onRectChanged,
  });

  @override
  State<CropOverlayWidget> createState() => _CropOverlayWidgetState();
}

class _CropOverlayWidgetState extends State<CropOverlayWidget> {
  late Rect _normalizedRect;

  @override
  void initState() {
    super.initState();
    _normalizedRect = widget.initialRect;
  }

  @override
  void didUpdateWidget(covariant CropOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRect != widget.initialRect) {
      _normalizedRect = widget.initialRect;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Screen space rect
        final screenRect = Rect.fromLTRB(
          _normalizedRect.left * w,
          _normalizedRect.top * h,
          _normalizedRect.right * w,
          _normalizedRect.bottom * h,
        );

        const handleSize = 40.0;
        const halfHandle = handleSize / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Custom Painter to paint outer transparent dims and grid
            Positioned.fill(
              child: CustomPaint(
                painter: CropPainter(cropRect: screenRect),
              ),
            ),

            // Top-Left corner handle
            Positioned(
              left: screenRect.left - halfHandle,
              top: screenRect.top - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaX = details.delta.dx / w;
                  final deltaY = details.delta.dy / h;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      (_normalizedRect.left + deltaX).clamp(0.0, _normalizedRect.right - 0.1),
                      (_normalizedRect.top + deltaY).clamp(0.0, _normalizedRect.bottom - 0.1),
                      _normalizedRect.right,
                      _normalizedRect.bottom,
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Top-Right corner handle
            Positioned(
              left: screenRect.right - halfHandle,
              top: screenRect.top - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaX = details.delta.dx / w;
                  final deltaY = details.delta.dy / h;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      _normalizedRect.left,
                      (_normalizedRect.top + deltaY).clamp(0.0, _normalizedRect.bottom - 0.1),
                      (_normalizedRect.right + deltaX).clamp(_normalizedRect.left + 0.1, 1.0),
                      _normalizedRect.bottom,
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Bottom-Left corner handle
            Positioned(
              left: screenRect.left - halfHandle,
              top: screenRect.bottom - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaX = details.delta.dx / w;
                  final deltaY = details.delta.dy / h;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      (_normalizedRect.left + deltaX).clamp(0.0, _normalizedRect.right - 0.1),
                      _normalizedRect.top,
                      _normalizedRect.right,
                      (_normalizedRect.bottom + deltaY).clamp(_normalizedRect.top + 0.1, 1.0),
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Bottom-Right corner handle
            Positioned(
              left: screenRect.right - halfHandle,
              top: screenRect.bottom - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaX = details.delta.dx / w;
                  final deltaY = details.delta.dy / h;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      _normalizedRect.left,
                      _normalizedRect.top,
                      (_normalizedRect.right + deltaX).clamp(_normalizedRect.left + 0.1, 1.0),
                      (_normalizedRect.bottom + deltaY).clamp(_normalizedRect.top + 0.1, 1.0),
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Top Edge handle
            Positioned(
              left: screenRect.left + halfHandle,
              top: screenRect.top - halfHandle,
              width: screenRect.width - handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaY = details.delta.dy / h;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      _normalizedRect.left,
                      (_normalizedRect.top + deltaY).clamp(0.0, _normalizedRect.bottom - 0.1),
                      _normalizedRect.right,
                      _normalizedRect.bottom,
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Bottom Edge handle
            Positioned(
              left: screenRect.left + halfHandle,
              top: screenRect.bottom - halfHandle,
              width: screenRect.width - handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaY = details.delta.dy / h;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      _normalizedRect.left,
                      _normalizedRect.top,
                      _normalizedRect.right,
                      (_normalizedRect.bottom + deltaY).clamp(_normalizedRect.top + 0.1, 1.0),
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Left Edge handle
            Positioned(
              left: screenRect.left - halfHandle,
              top: screenRect.top + halfHandle,
              width: handleSize,
              height: screenRect.height - handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaX = details.delta.dx / w;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      (_normalizedRect.left + deltaX).clamp(0.0, _normalizedRect.right - 0.1),
                      _normalizedRect.top,
                      _normalizedRect.right,
                      _normalizedRect.bottom,
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Right Edge handle
            Positioned(
              left: screenRect.right - halfHandle,
              top: screenRect.top + halfHandle,
              width: handleSize,
              height: screenRect.height - handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final deltaX = details.delta.dx / w;
                  setState(() {
                    _normalizedRect = Rect.fromLTRB(
                      _normalizedRect.left,
                      _normalizedRect.top,
                      (_normalizedRect.right + deltaX).clamp(_normalizedRect.left + 0.1, 1.0),
                      _normalizedRect.bottom,
                    );
                    widget.onRectChanged(_normalizedRect);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Parameter Classes for Isolate/Compute tasks ---
class CropParams {
  final img.Image image;
  final Rect rect;
  CropParams({required this.image, required this.rect});
}

class MagicEraserParams {
  final img.Image image;
  final double tolerance;
  final int px;
  final int py;
  MagicEraserParams({
    required this.image,
    required this.tolerance,
    required this.px,
    required this.py,
  });
}

class RemoveBgParams {
  final img.Image image;
  final double tolerance;
  RemoveBgParams({required this.image, required this.tolerance});
}

class FilterParams {
  final img.Image image;
  final double brightness;
  final double contrast;
  final double saturation;
  FilterParams({
    required this.image,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });
}

class HueParams {
  final img.Image image;
  final double shift;
  HueParams({required this.image, required this.shift});
}

class EncodeParams {
  final img.Image image;
  final double scale;
  EncodeParams({required this.image, required this.scale});
}

// --- Static functions for compute() to prevent capturing instance/lexical context ---
img.Image cropImageStatic(CropParams params) {
  final imageCopy = params.image;
  final rect = params.rect;
  final x = (rect.left * imageCopy.width).toInt().clamp(0, imageCopy.width - 1);
  final y = (rect.top * imageCopy.height).toInt().clamp(0, imageCopy.height - 1);
  final w = (rect.width * imageCopy.width).toInt().clamp(1, imageCopy.width - x);
  final h = (rect.height * imageCopy.height).toInt().clamp(1, imageCopy.height - y);

  return img.copyCrop(imageCopy, x: x, y: y, width: w, height: h);
}

img.Image applyMagicEraserStatic(MagicEraserParams params) {
  final imageCopy = params.image;
  final targetColor = imageCopy.getPixel(params.px, params.py).clone();
  final thresholdSquared = params.tolerance * params.tolerance * 3;

  for (var y = 0; y < imageCopy.height; y++) {
    for (var x = 0; x < imageCopy.width; x++) {
      final current = imageCopy.getPixel(x, y);
      if (current.a == 0) continue;

      final dr = current.r - targetColor.r;
      final dg = current.g - targetColor.g;
      final db = current.b - targetColor.b;
      final da = current.a - targetColor.a;
      final distance = (dr * dr + dg * dg + db * db + da * da).toDouble();

      if (distance < thresholdSquared) {
        imageCopy.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return imageCopy;
}

img.Image removeBackgroundStatic(RemoveBgParams params) {
  final imageCopy = params.image;
  final List<img.Color> samples = [
    imageCopy.getPixel(0, 0).clone(),
    imageCopy.getPixel(imageCopy.width - 1, 0).clone(),
    imageCopy.getPixel(0, imageCopy.height - 1).clone(),
    imageCopy.getPixel(imageCopy.width - 1, imageCopy.height - 1).clone(),
  ];

  final thresholdSquared = (params.tolerance * params.tolerance * 4);

  for (var sample in samples) {
    if (sample.a == 0) continue;

    for (var y = 0; y < imageCopy.height; y++) {
      for (var x = 0; x < imageCopy.width; x++) {
        final current = imageCopy.getPixel(x, y);
        if (current.a == 0) continue;

        final dr = current.r - sample.r;
        final dg = current.g - sample.g;
        final db = current.b - sample.b;
        final da = current.a - sample.a;
        final distance = (dr * dr + dg * dg + db * db + da * da).toDouble();

        if (distance < thresholdSquared) {
          imageCopy.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
  }
  return imageCopy;
}

img.Image applyFiltersStatic(FilterParams params) {
  final imageCopy = params.image;
  img.adjustColor(
    imageCopy,
    brightness: params.brightness,
    contrast: params.contrast,
    saturation: params.saturation,
  );
  return imageCopy;
}

img.Image updateHueStatic(HueParams params) {
  final original = params.image;
  final shift = params.shift;

  for (var pixel in original) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();

    // RGB a HSV inline para máximo rendimiento en isolate
    double rf = r / 255;
    double gf = g / 255;
    double bf = b / 255;
    double max = rf > gf ? (rf > bf ? rf : bf) : (gf > bf ? gf : bf);
    double min = rf < gf ? (rf < bf ? rf : bf) : (gf < bf ? gf : bf);
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

    // Aplicar cambio de tono
    h = (h + shift) % 1.0;

    // HSV a RGB inline
    double rfNew = 0, gfNew = 0, bfNew = 0;
    if (s == 0) {
      rfNew = gfNew = bfNew = v;
    } else {
      double hAngle = h * 6;
      int i = hAngle.floor();
      double f = hAngle - i;
      double p = v * (1 - s);
      double q = v * (1 - s * f);
      double t = v * (1 - s * (1 - f));
      switch (i) {
        case 0:
          rfNew = v;
          gfNew = t;
          bfNew = p;
          break;
        case 1:
          rfNew = q;
          gfNew = v;
          bfNew = p;
          break;
        case 2:
          rfNew = p;
          gfNew = v;
          bfNew = t;
          break;
        case 3:
          rfNew = p;
          gfNew = q;
          bfNew = v;
          break;
        case 4:
          rfNew = t;
          gfNew = p;
          bfNew = v;
          break;
        case 5:
          rfNew = v;
          gfNew = p;
          bfNew = q;
          break;
      }
    }
    pixel.r = (rfNew * 255).round();
    pixel.g = (gfNew * 255).round();
    pixel.b = (bfNew * 255).round();
  }
  return original;
}

Uint8List encodePngStatic(EncodeParams params) {
  img.Image finalImage = params.image;
  if (params.scale != 1.0) {
    finalImage = img.copyResize(
      params.image,
      width: (params.image.width * params.scale).toInt(),
      height: (params.image.height * params.scale).toInt(),
      interpolation: img.Interpolation.linear,
    );
  }
  return Uint8List.fromList(img.encodePng(finalImage));
}


