import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/journal_entry.dart';
import '../models/entities/vault_definition.dart';
import '../models/entities/store_sticker.dart';
import '../models/enums/entry_type.dart';
import '../config/constants.dart';

class JournalProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  // generador de ids universales para nuevas entradas
  final _uuid = Uuid();

  // --- estado del diario / vaults ---
  // seccion activa actualmente (null/diario, agenda, o uuid de vault)
  String? _currentSection;
  String? get currentSection => _currentSection;

  // Historial de navegación simple para permitir retrocesos lógicos
  final List<String?> _sectionHistory = [];

  // la lista renderizada actualmente (viene ya filtrada desde isar)
  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  StreamSubscription<List<JournalEntry>>? _entriesSubscription;
  StreamSubscription<List<JournalEntry>>? _allEntriesSubscription;

  // Actualiza la suscripción a Isar cuando cambian los filtros
  void _updateEntriesStream() {
    _entriesSubscription?.cancel();
    _entriesSubscription = _isarService.watchFilteredJournalEntries(
      sectionId: _currentSection,
      searchQuery: _searchQuery,
      filterTags: _filterTags,
    ).listen((data) {
      _entries = data;
      notifyListeners();
    });
  }

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

  // --- estado de selección múltiple ---
  final Set<int> _selectedIds = {};
  Set<int> get selectedIds => _selectedIds;
  bool get isSelectionMode => _selectedIds.isNotEmpty;

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  // --- estado de búsqueda y filtros ---
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  final Set<String> _filterTags = {};
  Set<String> get filterTags => _filterTags;

  // Mantenemos una lista paralela ligera solo para extraer etiquetas y para eliminaciones en lote
  List<JournalEntry> _allEntriesForTags = [];
  List<String> get allUniqueTags {
    final tags = <String>{};
    for (final entry in _allEntriesForTags) {
      if (entry.tags != null) tags.addAll(entry.tags!);
    }
    return tags.toList()..sort();
  }

  JournalProvider() {
    // Iniciamos el stream filtrado por primera vez
    _updateEntriesStream();

    // Mantener suscripcion paralela solo para calcular etiquetas globales y dia
    _allEntriesSubscription = _isarService.watchJournalEntries().listen((data) {
      _allEntriesForTags = data;
      _refreshDayEntries();
      notifyListeners();
    });

    // carga inicial del mes actual para el calendario
    loadMonth(_selectedDate);
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _allEntriesSubscription?.cancel();
    super.dispose();
  }

  // --- Cambio de sección ---
  void setSection(String? sectionId, {bool saveToHistory = true}) {
    if (_currentSection == sectionId) return;

    if (saveToHistory) {
      // Solo guardar en el historial si es una sección diferente a la última
      if (_sectionHistory.isEmpty || _sectionHistory.last != _currentSection) {
        _sectionHistory.add(_currentSection);
      }
      // Limitar el historial para no consumir memoria excesiva
      if (_sectionHistory.length > 20) {
        _sectionHistory.removeAt(0);
      }
    }

    _currentSection = sectionId;
    clearSelection(); // Limpiar selección al cambiar de página
    _updateEntriesStream(); // Refrescar stream con nueva sección
    notifyListeners();
  }

  bool popSection() {
    if (_sectionHistory.isEmpty) return false;

    final lastSection = _sectionHistory.removeLast();
    setSection(lastSection, saveToHistory: false);
    return true;
  }

  // --- Búsqueda y Filtros ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    _updateEntriesStream();
    notifyListeners();
  }

  void toggleFilterTag(String tag) {
    if (_filterTags.contains(tag)) {
      _filterTags.remove(tag);
    } else {
      _filterTags.add(tag);
    }
    _updateEntriesStream();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterTags.clear();
    _updateEntriesStream();
    notifyListeners();
  }

  // --- Gestión de Etiquetas en Notas ---
  Future<void> addTagToEntry(JournalEntry entry, String tag) async {
    final tags = List<String>.from(entry.tags ?? []);
    if (!tags.contains(tag)) {
      tags.add(tag);
      entry.tags = tags;
      entry.lastModified = DateTime.now();
      await saveJournalEntry(entry);
    }
  }

  Future<void> removeTagFromEntry(JournalEntry entry, String tag) async {
    final tags = List<String>.from(entry.tags ?? []);
    if (tags.contains(tag)) {
      tags.remove(tag);
      entry.tags = tags;
      entry.lastModified = DateTime.now();
      await saveJournalEntry(entry);
    }
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

  Future<void> deleteMultipleEntries(List<int> ids) async {
    await _isarService.deleteJournalEntries(ids);
    await loadMonth(_selectedDate);
  }

  // AGENDA
  Future<void> selectDate(DateTime date) async {
    // TableCalendar envía fechas en UTC, las convertimos a locales
    // para evitar que Isar las asigne al día anterior por la diferencia horaria
    _selectedDate = DateTime(date.year, date.month, date.day);
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
      return e.sectionId == AppConstants.sectionAgenda;
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

  Future<void> moveMultipleToVault(List<int> ids, String? vaultUuid) async {
    await _isarService.moveEntriesToSection(ids, vaultUuid);
    await loadMonth(_selectedDate);
  }
}
