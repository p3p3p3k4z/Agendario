import 'package:flutter_test/flutter_test.dart';
import 'package:agendario/models/entities/vault_definition.dart';
import 'package:agendario/models/entities/journal_entry.dart';
import 'package:agendario/models/enums/entry_type.dart';

void main() {
  group('Vault Management & Integrations Tests', () {
    test('Notes explicitly defined inside a Vault do not bleed into Dario', () {
      final vaultId = 'poemas-uuid';

      final entry = JournalEntry(
        uuid: 'note-1',
        type: EntryType.note,
        scheduledDate: DateTime.now(),
        lastModified: DateTime.now(),
        sectionId: vaultId,
      );

      // El diario filtra por null o 'diario'
      final isDiario = entry.sectionId == null || entry.sectionId == 'diario';

      expect(entry.sectionId, equals(vaultId));
      expect(isDiario, isFalse);
    });

    test('Vault pinning toggles correctly', () {
      final vault = VaultDefinition(
        uuid: 'vault-2',
        name: 'Ideas',
        createdAt: DateTime.now(),
      );

      expect(vault.isPinned, isFalse);

      vault.isPinned = true;
      expect(vault.isPinned, isTrue);

      vault.isPinned = false;
      expect(vault.isPinned, isFalse);
    });

    test('Filtered pinned vaults logic from Drawer', () {
      final vaults = [
        VaultDefinition(
          uuid: 'v1',
          name: 'Work',
          isPinned: true,
          createdAt: DateTime.now(),
        ),
        VaultDefinition(
          uuid: 'v2',
          name: 'Personal',
          isPinned: false,
          createdAt: DateTime.now(),
        ),
        VaultDefinition(
          uuid: 'v3',
          name: 'Ideas',
          isPinned: true,
          createdAt: DateTime.now(),
        ),
      ];

      final pinnedVaults = vaults.where((v) => v.isPinned).toList();

      expect(pinnedVaults.length, equals(2));
      expect(pinnedVaults[0].uuid, equals('v1'));
      expect(pinnedVaults[1].uuid, equals('v3'));
    });
  });
}
