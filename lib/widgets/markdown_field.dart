import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// widget reutilizable que encapsula el patron edit/preview
// usado en JournalEditorScreen (el editor legacy)
// recibe los controllers del padre para no duplicar estado
class MarkdownField extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  // el padre controla cuando alternar entre modos
  final bool isPreviewMode;

  const MarkdownField({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.isPreviewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration.collapsed(
              hintText: 'Título de la entrada...',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            // alterna entre: Markdown widget (renderiza .md a rich text)
            // y TextField crudo donde el usuario escribe con sintaxis markdown
            child: isPreviewMode
                ? Markdown(
                    data: contentController.text,
                    padding: EdgeInsets.zero,
                  )
                : TextField(
                    controller: contentController,
                    maxLines: null,
                    autofocus: true,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Escribe tu historia, tus ideas...',
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
          ),
        ],
      ),
    );
  }
}
