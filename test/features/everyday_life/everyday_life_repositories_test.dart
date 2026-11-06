import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auren/features/everyday_life/data/appointment_service_request_repository.dart';
import 'package:auren/features/everyday_life/data/everyday_life_local_store.dart';
import 'package:auren/features/everyday_life/data/home_household_repository.dart';
import 'package:auren/features/everyday_life/data/local_service_directory_repository.dart';
import 'package:auren/features/everyday_life/data/personal_organizer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('organizer keeps tasks, notes, and lists as separate local kinds', () async {
    final repository = PersonalOrganizerRepository();
    await repository.saveTask(id: 'task', title: 'Pay water bill');
    await repository.saveNote(id: 'note', title: 'Reminder', details: 'Keep receipt');
    await repository.saveList(id: 'list', title: 'Shopping', items: 'Rice\nSoap');

    expect((await repository.tasks).map((item) => item.id), ['task']);
    expect((await repository.notes).map((item) => item.id), ['note']);
    expect((await repository.lists).single.details, 'Rice\nSoap');
  });

  test('household chores, supplies, and maintenance preserve entered details', () async {
    final repository = HomeHouseholdRepository();
    await repository.addChore(id: 'chore', title: 'Clean kitchen');
    await repository.addSupply(
      id: 'supply',
      name: 'Detergent',
      quantity: '2 bottles',
      notes: 'User entered',
    );
    await repository.addMaintenance(
      id: 'maintenance',
      title: 'Repair tap',
      notes: 'Kitchen sink',
      requestedWindow: 'Friday afternoon',
    );

    expect((await repository.chores).single.title, 'Clean kitchen');
    expect((await repository.supplies).single.quantity, '2 bottles');
    expect((await repository.maintenance).single.requestedWindow, 'Friday afternoon');
  });

  test('appointment requests remain drafts with no external confirmation', () async {
    final repository = AppointmentServiceRequestRepository();
    await repository.saveDraft(
      id: 'draft',
      title: 'Ask for appliance repair',
      providerName: 'User entered provider',
      requestedWindow: 'Next week (requested, not confirmed)',
    );

    final draft = (await repository.drafts).single;
    expect(draft.informationConfirmed, isFalse);
    expect(draft.requestedWindow, 'Next week (requested, not confirmed)');
    expect(draft.dueAt, isNull);
  });

  test('directory favorites remain explicitly unconfirmed until user marks them', () async {
    final repository = LocalServiceDirectoryRepository();
    await repository.addEntry(
      id: 'service',
      name: 'Local electrician',
      category: 'Repairs',
      location: 'User-entered location',
    );

    var entry = (await repository.entries).single;
    expect(entry.informationConfirmed, isFalse);
    expect(entry.category, 'Repairs');
    await repository.setFavorite(entry, true);
    entry = (await repository.favorites).single;
    expect(entry.favorite, isTrue);
    expect(entry.informationConfirmed, isFalse);

    await repository.setUserVerified(entry, true);
    expect((await repository.entries).single.informationConfirmed, isTrue);
  });
}
