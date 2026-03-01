import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/vault_definition.dart';
import '../models/enums/entry_type.dart';

class JournalProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  // generador de ids universales para nuevas entradas
  final _uuid = const Uuid();

  // --- estado del diario / vaults ---
  // seccion activa actualmente (null/diario, agenda, o uuid de vault)
  String? _currentSection;
  String? get currentSection => _currentSection;

  // la lista completa de la bd (sin filtrar)
  List<JournalEntry> _allEntries = [];

  // getter modificado: retorna solo las notas de la seccion actual
  List<JournalEntry> get entries {
    return _allEntries.where((e) {
      if (_currentSection == null || _currentSection == 'diario') {
        return e.sectionId == null || e.sectionId == 'diario';
      }
      return e.sectionId == _currentSection;
    }).toList();
  }

  // Lista de vaults expuesta a la UI
  List<VaultDefinition> _vaults = [];
  List<VaultDefinition> get vaults => _vaults;

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
      _allEntries = data;
      // recarga el dia seleccionado cuando hay cambios en la bd
      _refreshDayEntries();
      notifyListeners();
    });

    // Suscripción a lista de Vaults
    _isarService.watchVaultDefinitions().listen((data) {
      _vaults = data;
      notifyListeners();
    });

    // carga inicial del mes actual para el calendario
    loadMonth(_selectedDate);
  }

  // --- Cambio de sección ---
  void setSection(String? sectionId) {
    _currentSection = sectionId;
    notifyListeners();
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
    String? sectionId,
  }) async {
    final entry = JournalEntry(
      uuid: _uuid.v4(),
      type: type,
      sectionId: sectionId ?? _currentSection,
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
    String? sectionId,
  }) async {
    final entry = JournalEntry(
      uuid: _uuid.v4(),
      type: EntryType.todo,
      sectionId: sectionId,
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
    String? sectionId,
  }) async {
    final entry = JournalEntry(
      uuid: _uuid.v4(),
      type: EntryType.event,
      sectionId: sectionId,
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
    final unfilteredDayEntries = await _isarService.getEntriesForDate(
      _selectedDate,
    );
    // Filtrar agenda para que solo aparezcan Todo y Event (y notes que sean de agenda explicita)
    _dayEntries = unfilteredDayEntries.where((e) {
      if (e.type == EntryType.event ||
          e.type == EntryType.todo ||
          e.type == EntryType.reminder) {
        return true;
      }
      return e.sectionId == 'agenda';
    }).toList();
  }

  // genera una nota de prueba para verificar el flujo de datos
  void addTestEntry() {
    saveQuickEntry(
      title: 'Nota de Prueba ${DateTime.now().second}',
      content: 'Contenido de prueba.',
      type: EntryType.note,
      sectionId: null, // pertenece al diario por defecto
    );
  }

  // --- Manejo de Baúles (Vaults) ---
  Future<void> createVault({
    required String name,
    int? iconCode,
    int? colorValue,
  }) async {
    final vault = VaultDefinition(
      uuid: _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _isarService.saveVaultDefinition(vault);
  }

  Future<void> updateVault(VaultDefinition vault) async {
    await _isarService.saveVaultDefinition(vault);
  }

  Future<void> toggleVaultPin(VaultDefinition vault) async {
    vault.isPinned = !vault.isPinned;
    await _isarService.saveVaultDefinition(vault);
  }

  Future<void> deleteVault(
    VaultDefinition vault, {
    bool deleteNotes = false,
  }) async {
    await _isarService.deleteVault(vault.id);

    if (deleteNotes) {
      // Eliminar todas las notas que pertenecen a este Vault
      final vaultNotes = _allEntries
          .where((e) => e.sectionId == vault.uuid)
          .toList();
      for (final note in vaultNotes) {
        await _isarService.deleteJournalEntry(note.id);
      }
      // recargar el calendario principal por si tenia eventos vinculados a ese baúl
      await loadMonth(_selectedDate);
    }

    if (_currentSection == vault.uuid) {
      setSection(null); // Vuelve al diario principal si borras el actual
    }
  }
}
