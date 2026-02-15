import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/journal_entry.dart';
import '../models/enums/entry_type.dart';

class JournalProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  // generador de ids universales para nuevas entradas
  final _uuid = const Uuid();

  // --- estado del diario ---
  // cache local de entradas: la ui lee esta lista,
  // nunca hace queries directos a isar
  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  // --- estado de la agenda ---
  // fecha seleccionada en el calendario, default hoy
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // entradas del dia seleccionado, alimenta la lista debajo del calendario
  List<JournalEntry> _dayEntries = [];
  List<JournalEntry> get dayEntries => _dayEntries;

  // mapa dia->entradas para pintar y uso de tiempo
  Map<DateTime, List<JournalEntry>> _monthEntries = {};
  Map<DateTime, List<JournalEntry>> get monthEntries => _monthEntries;

  JournalProvider() {
    // suscripcion al stream reactivo de isar: cada vez que alguien
    // escribe en la coleccion (desde cualquier parte de la app),
    // este listener recibe la lista actualizada y refresca la ui
    _isarService.watchJournalEntries().listen((data) {
      _entries = data;
      // recarga el dia seleccionado cuando hay cambios en la bd
      _refreshDayEntries();
      notifyListeners();
    });
    // carga inicial del mes actual para el calendario
    loadMonth(_selectedDate);
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _isarService.saveJournalEntry(entry);
    await loadMonth(_selectedDate);
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
    await loadMonth(_selectedDate);
  }

  // AGENDA
  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    await _refreshDayEntries();
    notifyListeners();
  }

  Future<void> loadMonth(DateTime month) async {
    final entries = await _isarService.getEntriesForMonth(month);
    _monthEntries = {};
    for (final entry in entries) {
      final key = DateTime(
        entry.scheduledDate.year,
        entry.scheduledDate.month,
        entry.scheduledDate.day,
      );
      _monthEntries.putIfAbsent(key, () => []).add(entry);
    }
    notifyListeners();
  }

  // toggle de completado
  Future<void> toggleTodoCompleted(int id) async {
    await _isarService.toggleCompleted(id);
    await loadMonth(_selectedDate);
  }

  // tareas
  Future<void> saveTodo({
    required String title,
    required DateTime scheduledDate,
  }) async {
    final entry = JournalEntry(
      uuid: _uuid.v4(),
      type: EntryType.todo,
      title: title,
      scheduledDate: scheduledDate,
      lastModified: DateTime.now(),
    );
    await _isarService.saveJournalEntry(entry);
    await loadMonth(_selectedDate);
  }

  Future<void> saveEvent({
    required String title,
    String? content,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    int? colorValue,
  }) async {
    final entry = JournalEntry(
      uuid: _uuid.v4(),
      type: EntryType.event,
      title: title,
      content: content,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      colorValue: colorValue,
      lastModified: DateTime.now(),
    );
    await _isarService.saveJournalEntry(entry);
    await loadMonth(_selectedDate);
  }

  Future<void> _refreshDayEntries() async {
    _dayEntries = await _isarService.getEntriesForDate(_selectedDate);
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
