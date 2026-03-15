import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportUtils {
  static Future<void> exportToImage({
    required GlobalKey boundaryKey,
    required BuildContext context,
    required Color snackbarColor,
    required Function(bool) onLoading,
  }) async {
    try {
      onLoading(true);
      RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      
      await Gal.putImage(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nota guardada en la galería'),
            backgroundColor: snackbarColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      onLoading(false);
    }
  }

  static Future<void> exportToPdf({
    required GlobalKey boundaryKey,
    required BuildContext context,
    required Function(bool) onLoading,
  }) async {
    try {
      onLoading(true);
      RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Nota_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      onLoading(false);
    }
  }
}
