import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/journal_entry.dart';
import '../models/enums/entry_type.dart';

// capa de logica de negocio reactiva: conecta la ui con isar
// extiende ChangeNotifier para que Consumer/Provider reconstruya
// automaticamente los widgets cuando los datos cambian
class JournalProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  // generador de ids universales para nuevas entradas
  final _uuid = const Uuid();

  // cache local de entradas: la ui lee esta lista,
  // nunca hace queries directos a isar
  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  JournalProvider() {
    // suscripcion al stream reactivo de isar: cada vez que alguien
    // escribe en la coleccion (desde cualquier parte de la app),
    // este listener recibe la lista actualizada y refresca la ui
    _isarService.watchJournalEntries().listen((data) {
      _entries = data;
      notifyListeners();
    });
  }

  // inserta o actualiza una nota completa en el almacenamiento
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _isarService.saveJournalEntry(entry);
  }

  // atajo para crear entradas desde la ui con datos minimos
  // genera uuid automaticamente y asigna la fecha actual
  // util para el fab de creacion rapida en el home
  Future<void> saveQuickEntry({
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

  // elimina por id de isar (no uuid), porque localmente
  // el id autoincrementado es mas rapido para buscar
  Future<void> deleteEntry(int id) async {
    await _isarService.deleteJournalEntry(id);
  }

  // genera una nota de prueba para verificar el flujo de datos
  void addTestEntry() {
    saveQuickEntry(
      title: 'Nota de Prueba ${DateTime.now().second}',
      content: 'Contenido de prueba.',
      type: EntryType.note,
    );
  }
}
