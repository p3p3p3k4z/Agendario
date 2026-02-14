import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/journal_entry.dart';
import '../models/enums/entry_type.dart';

class JournalProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  final _uuid = const Uuid();

  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  JournalProvider() {
    // escucha cambios en la base de datos de forma reactiva
    _isarService.watchJournalEntries().listen((data) {
      _entries = data;
      notifyListeners();
    });
  }

  // --- ACCIONES ---

  Future<void> saveEntry({
    required String title,
    required String content,
    required EntryType type,
  }) async {
    final entry = JournalEntry(
      uuid: _uuid.v4(),
      type: type,
      title: title,
      content: content,
      scheduledDate: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await _isarService.saveJournalEntry(entry);
  }

  Future<void> deleteEntry(int id) async {
    await _isarService.deleteJournalEntry(id);
  }

  // metodo de prueba para el FAB del main
  void addTestEntry() {
    saveEntry(
      title: 'Nota de Prueba ${DateTime.now().second}',
      content: 'Este es un contenido generado automáticamente para probar Isar.',
      type: EntryType.note,
    );
  }
}
