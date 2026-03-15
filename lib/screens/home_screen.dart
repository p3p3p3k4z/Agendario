import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/journal_provider.dart';
import 'editor_nota_screen.dart';
import '../models/entities/journal_entry.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';

// pantalla principal del diario: muestra todas las entradas como tarjetas
// stateless porque Consumer se encarga de reconstruir cuando el provider cambia
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, child) {
        final entries = provider.entries;

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_motion_outlined,
                  size: 64,
                  color: context.theme.fg1.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu tablero está listo para tus ideas',
                  style: TextStyle(color: context.theme.fg1, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return MasonryGridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isSelected = provider.selectedIds.contains(entry.id);
            return _NoteCard(
              entry: entry,
              isSelected: isSelected,
              isSelectionMode: provider.isSelectionMode,
              onTap: () {
                if (provider.isSelectionMode) {
                  provider.toggleSelection(entry.id);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditorNotaScreen(entry: entry)),
                  );
                }
              },
              onLongPress: () => provider.toggleSelection(entry.id),
            );
          },
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final JournalEntry entry;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard({
    required this.entry,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.purple.withValues(alpha: 0.2) 
              : theme.fg1.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.purple : theme.bg1.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.stickers != null && entry.stickers!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Icon(Icons.auto_awesome, size: 16, color: theme.yellow),
                  ),
                Text(
                  entry.title ?? 'Sin título',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.fg0,
                  ),
                ),
                if (entry.content != null && entry.content!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.content!,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.fg1, fontSize: 14, height: 1.4),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  DateFormat('dd MMM').format(entry.scheduledDate),
                  style: TextStyle(color: theme.blue, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isSelectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedScale(
                  scale: isSelectionMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? theme.purple : theme.fg1.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
