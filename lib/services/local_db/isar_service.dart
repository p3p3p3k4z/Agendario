import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/entities/journal_entry.dart';
import '../../models/entities/habit_definition.dart';
import '../../models/entities/vault_definition.dart';
import '../../models/entities/store_sticker.dart';

// punto unico de acceso a la base de datos local
// en nativo usa Isar, en web usa almacenamiento en memoria
class IsarService {
  static Isar? _db;

  // --- almacenamiento en memoria para Web ---
  // isar 3.x no soporta web, asi que se simula
  static final List<JournalEntry> _webEntries = [];
  static final List<HabitDefinition> _webHabits = [];
  static final List<VaultDefinition> _webVaults = [];
  static final List<StoreSticker> _webStickers = [];
  static int _webNextId = 1;
  static int _webNextHabitId = 1;
  static int _webNextVaultId = 1;
  static int _webNextStickerId = 1;
  // controladores para emitir cambios reactivos en web
  static final StreamController<List<JournalEntry>> _webEntriesController =
      StreamController<List<JournalEntry>>.broadcast();
  static final StreamController<List<HabitDefinition>> _webHabitsController =
      StreamController<List<HabitDefinition>>.broadcast();
  static final StreamController<List<VaultDefinition>> _webVaultsController =
      StreamController<List<VaultDefinition>>.broadcast();
  static final StreamController<List<StoreSticker>> _webStickersController =
      StreamController<List<StoreSticker>>.broadcast();

  static Future<void> init() async {
    if (kIsWeb) {
      // en web no se abre isar, se usa la lista en memoria
      // ignore: avoid_print
      print('Web detectado: usando almacenamiento en memoria');
      return;
    }

    // plataformas nativas: isar normal con SQLite
    final dir = (await getApplicationDocumentsDirectory()).path;

    if (Isar.instanceNames.isEmpty) {
      _db = await Isar.open(
        [
          JournalEntrySchema,
          HabitDefinitionSchema,
          VaultDefinitionSchema,
          StoreStickerSchema,
        ],
        directory: dir,
        inspector: true,
      );
    } else {
      _db = Isar.getInstance()!;
    }
  }

  // --- Journal Entries ---

  Future<void> saveJournalEntry(JournalEntry entry) async {
    if (kIsWeb) {
      // si no tiene id asignado, asignar uno nuevo
      if (entry.id == Isar.autoIncrement) {
        entry.id = _webNextId++;
      } else {
        // actualizar: remover el existente
        _webEntries.removeWhere((e) => e.id == entry.id);
      }
      _webEntries.add(entry);
      _notifyWebListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.journalEntrys.put(entry);
    });
  }

  Future<List<JournalEntry>> getRecentEntries({int limit = 20}) async {
    if (kIsWeb) {
      final sorted = List<JournalEntry>.from(_webEntries)
        ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      return sorted.take(limit).toList();
    }
    return await _db!.journalEntrys
        .where()
        .sortByScheduledDateDesc()
        .limit(limit)
        .findAll();
  }

  Stream<List<JournalEntry>> watchJournalEntries() {
    if (kIsWeb) {
      // emite la lista actual inmediatamente, luego escucha cambios
      Future.microtask(() => _notifyWebListeners());
      return _webEntriesController.stream;
    }
    return _db!.journalEntrys.where().sortByScheduledDateDesc().watch(
      fireImmediately: true,
    );
  }

  Future<void> deleteJournalEntry(Id id) async {
    if (kIsWeb) {
      _webEntries.removeWhere((e) => e.id == id);
      _notifyWebListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.journalEntrys.delete(id);
    });
  }

  Future<List<JournalEntry>> getEntriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(Duration(days: 1));
    if (kIsWeb) {
      return _webEntries
          .where(
            (e) =>
                !e.scheduledDate.isBefore(start) &&
                e.scheduledDate.isBefore(end),
          )
          .toList();
    }
    return await _db!.journalEntrys
        .where()
        .scheduledDateBetween(start, end, includeUpper: false)
        .findAll();
  }

  Future<List<JournalEntry>> getEntriesForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    if (kIsWeb) {
      return _webEntries
          .where(
            (e) =>
                !e.scheduledDate.isBefore(start) &&
                e.scheduledDate.isBefore(end),
          )
          .toList();
    }
    return await _db!.journalEntrys
        .where()
        .scheduledDateBetween(start, end, includeUpper: false)
        .findAll();
  }

  Future<void> toggleCompleted(Id id) async {
    if (kIsWeb) {
      final entry = _webEntries.where((e) => e.id == id).firstOrNull;
      if (entry != null) {
        entry.isCompleted = !entry.isCompleted;
        entry.lastModified = DateTime.now();
        _notifyWebListeners();
      }
      return;
    }
    await _db!.writeTxn(() async {
      final entry = await _db!.journalEntrys.get(id);
      if (entry != null) {
        entry.isCompleted = !entry.isCompleted;
        entry.lastModified = DateTime.now();
        await _db!.journalEntrys.put(entry);
      }
    });
  }

  // --- Habit Definitions ---

  Future<void> saveHabitDefinition(HabitDefinition habit) async {
    if (kIsWeb) {
      if (habit.id == Isar.autoIncrement) {
        habit.id = _webNextHabitId++;
      } else {
        _webHabits.removeWhere((h) => h.id == habit.id);
      }
      _webHabits.add(habit);
      _notifyWebHabitsListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.habitDefinitions.put(habit);
    });
  }

  Future<List<HabitDefinition>> getAllHabits() async {
    if (kIsWeb) {
      return List.from(_webHabits);
    }
    return await _db!.habitDefinitions.where().findAll();
  }

  Future<void> deleteHabit(Id id) async {
    if (kIsWeb) {
      _webHabits.removeWhere((h) => h.id == id);
      _notifyWebHabitsListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.habitDefinitions.delete(id);
    });
  }

  // --- Vault Definitions ---

  Future<void> saveVaultDefinition(VaultDefinition vault) async {
    if (kIsWeb) {
      if (vault.id == Isar.autoIncrement) {
        vault.id = _webNextVaultId++;
      } else {
        _webVaults.removeWhere((v) => v.id == vault.id);
      }
      _webVaults.add(vault);
      _notifyWebVaultsListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.vaultDefinitions.put(vault);
    });
  }

  Future<List<VaultDefinition>> getAllVaults() async {
    if (kIsWeb) {
      return List.from(_webVaults);
    }
    return await _db!.vaultDefinitions.where().findAll();
  }

  Future<void> deleteVault(Id id) async {
    if (kIsWeb) {
      _webVaults.removeWhere((v) => v.id == id);
      _notifyWebVaultsListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.vaultDefinitions.delete(id);
    });
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      _webEntries.clear();
      _webHabits.clear();
      _webVaults.clear();
      _webStickers.clear();
      _webNextId = 1;
      _webNextHabitId = 1;
      _webNextVaultId = 1;
      _webNextStickerId = 1;
      _notifyWebListeners();
      _notifyWebHabitsListeners();
      _notifyWebVaultsListeners();
      _notifyWebStickersListeners();
      return;
    }
    await _db!.writeTxn(() => _db!.clear());
  }

  // --- Store Stickers ---

  Future<void> saveStoreSticker(StoreSticker sticker) async {
    if (kIsWeb) {
      if (sticker.id == Isar.autoIncrement) {
        sticker.id = _webNextStickerId++;
      } else {
        _webStickers.removeWhere((s) => s.id == sticker.id);
      }
      _webStickers.add(sticker);
      _notifyWebStickersListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.storeStickers.put(sticker);
    });
  }

  Future<List<StoreSticker>> getAllStoreStickers() async {
    if (kIsWeb) {
      return List.from(_webStickers);
    }
    return await _db!.storeStickers.where().findAll();
  }

  Future<void> deleteStoreSticker(Id id) async {
    if (kIsWeb) {
      _webStickers.removeWhere((s) => s.id == id);
      _notifyWebStickersListeners();
      return;
    }
    await _db!.writeTxn(() async {
      await _db!.storeStickers.delete(id);
    });
  }

  Stream<List<StoreSticker>> watchStoreStickers() {
    if (kIsWeb) {
      Future.microtask(() => _notifyWebStickersListeners());
      return _webStickersController.stream;
    }
    return _db!.storeStickers.where().watch(fireImmediately: true);
  }

  // emite una copia ordenada de las entradas de web
  static void _notifyWebListeners() {
    final sorted = List<JournalEntry>.from(_webEntries)
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    _webEntriesController.add(sorted);
  }

  static void _notifyWebHabitsListeners() {
    _webHabitsController.add(List<HabitDefinition>.from(_webHabits));
  }

  static void _notifyWebVaultsListeners() {
    _webVaultsController.add(List<VaultDefinition>.from(_webVaults));
  }

  static void _notifyWebStickersListeners() {
    _webStickersController.add(List<StoreSticker>.from(_webStickers));
  }

  // obtiene entradas que contienen registros de un habito especifico
  Future<List<JournalEntry>> getEntriesWithHabitRecords(
    String habitUuid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    List<JournalEntry> entries;
    if (kIsWeb) {
      entries = _webEntries
          .where(
            (e) =>
                !e.scheduledDate.isBefore(startDate) &&
                e.scheduledDate.isBefore(endDate),
          )
          .toList();
    } else {
      entries = await _db!.journalEntrys
          .where()
          .scheduledDateBetween(startDate, endDate, includeUpper: false)
          .findAll();
    }
    // filtra solo las que tengan registros del habito buscado
    return entries
        .where(
          (e) =>
              e.habitRecords != null &&
              e.habitRecords!.any((r) => r.habitDefinitionId == habitUuid),
        )
        .toList();
  }

  Stream<List<HabitDefinition>> watchHabitDefinitions() {
    if (kIsWeb) {
      Future.microtask(() => _notifyWebHabitsListeners());
      return _webHabitsController.stream;
    }
    return _db!.habitDefinitions.where().watch(fireImmediately: true);
  }

  Stream<List<VaultDefinition>> watchVaultDefinitions() {
    if (kIsWeb) {
      Future.microtask(() => _notifyWebVaultsListeners());
      return _webVaultsController.stream;
    }
    return _db!.vaultDefinitions.where().watch(fireImmediately: true);
  }

  // obtiene la entrada del dia actual, o null si no existe
  Future<JournalEntry?> getEntryForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(Duration(days: 1));
    if (kIsWeb) {
      final matches = _webEntries
          .where(
            (e) =>
                !e.scheduledDate.isBefore(start) &&
                e.scheduledDate.isBefore(end),
          )
          .toList();
      return matches.isEmpty ? null : matches.first;
    }
    final results = await _db!.journalEntrys
        .where()
        .scheduledDateBetween(start, end, includeUpper: false)
        .findAll();
    return results.isEmpty ? null : results.first;
  }
}
