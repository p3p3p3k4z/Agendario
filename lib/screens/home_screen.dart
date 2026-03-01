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
    // consumer escucha a JournalProvider: cuando llegan datos nuevos
    // del stream de isar, este builder se ejecuta automaticamente
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
                SizedBox(height: 16),
                Text(
                  'Tu tablero está listo para tus ideas',
                  style: TextStyle(color: context.theme.fg1, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // masonry grid: layout tipo pinterest donde cada tarjeta puede
        // tener altura diferente segun la longitud del contenido,
        // mas organico que un grid rigido para notas de diario
        return MasonryGridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _NoteCard(entry: entry);
          },
        );
      },
    );
  }
}

// tarjeta privada del home: renderiza un preview compacto de la nota
// al tocarla navega al editor pasando la entry para editarla in-place
class _NoteCard extends StatelessWidget {
  final JournalEntry entry;
  const _NoteCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditorNotaScreen(entry: entry)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.fg1.withValues(alpha: 0.2), // Tono suave gruvbox
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.bg1.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icono indicador: avisa visualmente que esta nota
            // tiene stickers sin necesidad de abrirla
            if (entry.stickers != null && entry.stickers!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: context.theme.yellow,
                ),
              ),
            Text(
              entry.title ?? 'Sin título',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.theme.fg0,
              ),
            ),
            if (entry.content != null && entry.content!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                entry.content!,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.theme.fg1,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            SizedBox(height: 12),
            Text(
              DateFormat('dd MMM').format(entry.scheduledDate),
              style: TextStyle(
                color: context.theme.blue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
