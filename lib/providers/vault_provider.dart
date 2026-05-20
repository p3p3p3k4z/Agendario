import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db/isar_service.dart';
import '../models/entities/vault_definition.dart';

class VaultProvider extends ChangeNotifier {
  final IsarService _isarService = IsarService();
  final _uuid = Uuid();

  List<VaultDefinition> _vaults = [];
  List<VaultDefinition> get vaults => _vaults;

  VaultProvider() {
    _isarService.watchVaultDefinitions().listen((data) {
      _vaults = data;
      notifyListeners();
    });
  }

  Future<void> createVault({
    required String name,
    int? iconCode,
    int? colorValue,
    String? password,
  }) async {
    final vault = VaultDefinition(
      uuid: _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
      password: password,
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
      await _isarService.deleteEntriesBySection(vault.uuid);
    }
  }
}
