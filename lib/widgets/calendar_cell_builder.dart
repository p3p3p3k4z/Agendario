import 'dart:io';
import 'package:flutter/material.dart';
import '../models/entities/journal_entry.dart';
import '../models/enums/entry_type.dart';
import '../config/theme.dart';

// builder personalizado para las celdas del calendario de table_calendar
// muestra el numero del dia, dot indicators por tipo de entrada,
// y mini thumbnails de stickers si hay stickers asociados al dia
class CalendarCellBuilder extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  // entradas de este dia especifico, puede ser null si no hay ninguna
  final List<JournalEntry>? entries;

  const CalendarCellBuilder({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isToday,
    this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final hasEntries = entries != null && entries!.isNotEmpty;

    // recolecta los primeros 2 stickers del dia para mini thumbnails
    final dayStickers = <_StickerRef>[];
    if (hasEntries) {
      for (final entry in entries!) {
        if (entry.stickers != null) {
          for (final s in entry.stickers!) {
            if (dayStickers.length < 2 && s.assetPath != null) {
              dayStickers.add(_StickerRef(s.assetPath!, s.isCustom));
            }
          }
        }
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // fondo segun estado: seleccionado > hoy > normal
        color: isSelected
            ? GruvboxColors.orange
            : isToday
            ? GruvboxColors.orange.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        // borde sutil para el dia actual
        border: isToday && !isSelected
            ? Border.all(
                color: GruvboxColors.orange.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // numero del dia
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? GruvboxColors.orange
                      : GruvboxColors.bg0,
                ),
              ),
              // dots indicators debajo del numero
              if (hasEntries)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildDots(),
                  ),
                ),
            ],
          ),
          // mini stickers en la esquina superior derecha de la celda
          if (dayStickers.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Row(
                children: dayStickers.map((ref) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: ref.isCustom
                            ? Image.file(
                                File(ref.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              )
                            : Image.asset(
                                ref.path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // genera dots de color segun los tipos presentes en el dia
  // maximo 3 dots para no saturar la celda
  List<Widget> _buildDots() {
    if (entries == null) return [];

    // set de tipos presentes para no duplicar dots
    final types = entries!.map((e) => e.type).toSet();
    final dots = <Widget>[];

    for (final type in types) {
      if (dots.length >= 3) break;
      dots.add(
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : _dotColor(type),
          ),
        ),
      );
    }
    return dots;
  }

  // mapea cada tipo de entrada a un color para su dot
  Color _dotColor(EntryType type) {
    switch (type) {
      case EntryType.event:
        return GruvboxColors.blue;
      case EntryType.todo:
        return GruvboxColors.green;
      case EntryType.reminder:
        return GruvboxColors.purple;
      case EntryType.journal:
        return GruvboxColors.yellow;
      case EntryType.note:
        return GruvboxColors.aqua;
    }
  }
}

// referencia ligera a un sticker para evitar pasar objetos pesados
class _StickerRef {
  final String path;
  final bool isCustom;
  _StickerRef(this.path, this.isCustom);
}
