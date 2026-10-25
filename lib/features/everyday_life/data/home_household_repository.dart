import '../domain/everyday_life_item.dart';
import 'everyday_life_local_store.dart';

/// Local household chores, supply records, and maintenance reminders.
/// Quantities and service details are user-entered; none are inferred.
class HomeHouseholdRepository {
  HomeHouseholdRepository({EverydayLifeLocalStore? store})
      : _store = store ?? EverydayLifeLocalStore();

  final EverydayLifeLocalStore _store;

  Future<List<EverydayLifeItem>> get chores async =>
      _byKind(EverydayLifeKind.household);

  Future<List<EverydayLifeItem>> get supplies async =>
      _byKind(EverydayLifeKind.householdSupply);

  Future<List<EverydayLifeItem>> get maintenance async =>
      _byKind(EverydayLifeKind.householdMaintenance);

  Future<List<EverydayLifeItem>> _byKind(EverydayLifeKind kind) async =>
      (await _store.readAll())
          .where((item) => item.kind == kind)
          .toList(growable: false);

  Future<void> addChore({
    required String id,
    required String title,
    String details = '',
  }) => _save(id, EverydayLifeKind.household, title, details);

  Future<void> addSupply({
    required String id,
    required String name,
    String quantity = '',
    String notes = '',
  }) {
    final details = <String>[
      if (quantity.trim().isNotEmpty) 'الكمية المدخلة: ${quantity.trim()}',
      if (notes.trim().isNotEmpty) notes.trim(),
    ].join('\n');
    return _save(id, EverydayLifeKind.householdSupply, name, details,
        quantity: quantity.trim());
  }

  Future<void> addMaintenance({
    required String id,
    required String title,
    String notes = '',
    String requestedWindow = '',
  }) => _store.save(EverydayLifeItem(
    id: id,
    kind: EverydayLifeKind.householdMaintenance,
    title: _validate(title),
    details: notes.trim(),
    requestedWindow: requestedWindow.trim(),
    createdAt: DateTime.now().toUtc().toIso8601String(),
  ));

  Future<void> _save(
    String id,
    EverydayLifeKind kind,
    String title,
    String details, {
    String quantity = '',
  }) => _store.save(EverydayLifeItem(
    id: id,
    kind: kind,
    title: _validate(title),
    details: details,
    quantity: quantity,
    createdAt: DateTime.now().toUtc().toIso8601String(),
  ));

  String _validate(String title) {
    final value = title.trim();
    if (value.isEmpty) throw ArgumentError('A title is required.');
    return value;
  }
}
