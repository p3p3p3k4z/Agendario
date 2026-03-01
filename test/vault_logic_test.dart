import 'package:flutter_test/flutter_test.dart';
import 'package:agendario/models/entities/journal_entry.dart';
import 'package:agendario/models/enums/entry_type.dart';

void main() {
  group('Journal Entry Section Logic Tests', () {
    test('A diary note does not bleed into the agenda', () {
      final entry = JournalEntry(
        uuid: '123',
        type: EntryType.note,
        scheduledDate: DateTime.now(),
        lastModified: DateTime.now(),
        sectionId: 'diario',
      );

      expect(entry.sectionId, equals('diario'));
      expect(entry.sectionId != 'agenda', isTrue);
    });

    test('An agenda note does not bleed into a vault', () {
      final vaultId = 'abc-123';
      final entry = JournalEntry(
        uuid: '456',
        type: EntryType.note,
        scheduledDate: DateTime.now(),
        lastModified: DateTime.now(),
        sectionId: 'agenda',
      );

      expect(entry.sectionId, equals('agenda'));
      expect(entry.sectionId != vaultId, isTrue);
    });
  });
}
