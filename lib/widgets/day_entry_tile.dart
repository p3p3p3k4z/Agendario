import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entities/journal_entry.dart';
import '../models/enums/entry_type.dart';
import '../providers/theme_provider.dart';

// lista diaria de la agenda
// su apariencia cambia segun la entrada: todo muestra checkbox,
// evento muestra barra de color + hora, recordatorio muestra campana
class DayEntryTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const DayEntryTile({
    super.key,
    required this.entry,
    this.onToggleCompleted,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.uuid),
      // deslizar a la izquierda para eliminar
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: context.theme.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: context.theme.red),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: Card(
        elevation: 0,
        color: _cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // indicador lateral: icono o checkbox segun tipo
                _buildLeading(context),
                SizedBox(width: 12),
                // contenido principal: titulo + hora o subtitulo
                Expanded(child: _buildContent(context)),
                // badge de stickers si la entrada tiene stickers
                if ((entry.stickers?.isNotEmpty ?? false))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.theme.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_emotions_outlined,
                          size: 14,
                          color: context.theme.orange,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${entry.stickers!.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.theme.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // color de fondo del card segun tipo, crea separacion visual
  Color _cardColor(BuildContext context) {
    switch (entry.type) {
      case EntryType.event:
        // si tiene color personalizado lo usa con baja opacidad
        if (entry.colorValue != null) {
          return Color(entry.colorValue!).withValues(alpha: 0.08);
        }
        return context.theme.blue.withValues(alpha: 0.06);
      case EntryType.todo:
        return entry.isCompleted
            ? context.theme.green.withValues(alpha: 0.06)
            : context.theme.bg1;
      case EntryType.reminder:
        return context.theme.purple.withValues(alpha: 0.06);
      default:
        return context.theme.bg1;
    }
  }

  // icono o checkbox de la izquierda segun EntryType
  Widget _buildLeading(BuildContext context) {
    switch (entry.type) {
      case EntryType.todo:
        // checkbox circular para marcar como completado
        return GestureDetector(
          onTap: onToggleCompleted,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isCompleted
                  ? context.theme.green
                  : Colors.transparent,
              border: Border.all(
                color: entry.isCompleted
                    ? context.theme.green
                    : context.theme.bg1,
                width: 2,
              ),
            ),
            child: entry.isCompleted
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        );
      case EntryType.event:
        // barra de color vertical como indicador visual del evento
        return Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: entry.colorValue != null
                ? Color(entry.colorValue!)
                : context.theme.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case EntryType.reminder:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.purple.withValues(alpha: 0.15),
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: 16,
            color: context.theme.purple,
          ),
        );
      default:
        return Icon(Icons.note_outlined, size: 20, color: context.theme.yellow);
    }
  }

  // titulo + subtitulo con formato segun tipo
  Widget _buildContent(BuildContext context) {
    final timeFormat = DateFormat.Hm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title ?? 'Sin título',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.theme.fg0,
            // tachado si el todo esta completado
            decoration: (entry.type == EntryType.todo && entry.isCompleted)
                ? TextDecoration.lineThrough
                : null,
            decorationColor: context.theme.bg1,
          ),
        ),
        // hora de inicio/fin para eventos con horario
        if (entry.type == EntryType.event && entry.startTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              entry.endTime != null
                  ? '${timeFormat.format(entry.startTime!)} - ${timeFormat.format(entry.endTime!)}'
                  : timeFormat.format(entry.startTime!),
              style: TextStyle(fontSize: 12, color: context.theme.fg1),
            ),
          ),
        // extracto del contenido si existe
        if (entry.content != null && entry.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              entry.content!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.theme.fg1),
            ),
          ),
      ],
    );
  }
}
