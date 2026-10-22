import '../domain/everyday_life_item.dart';
import 'everyday_life_local_store.dart';

/// Local-first task, list, and note operations. This repository does not
/// depend on Calendar or Universal Search.
class PersonalOrganizerRepository {
  PersonalOrganizerRepository({EverydayLifeLocalStore? store})
      : _store = store ?? EverydayLifeLocalStore();

  final EverydayLifeLocalStore _store;

  Future<List<EverydayLifeItem>> get tasks async =>
      _ofKind(EverydayLifeKind.task);

  Future<List<EverydayLifeItem>> get notes async =>
      _ofKind(EverydayLifeKind.note);

  Future<List<EverydayLifeItem>> get lists async =>
      _ofKind(EverydayLifeKind.taskList);

  Future<List<EverydayLifeItem>> _ofKind(EverydayLifeKind kind) async =>
      (await _store.readAll())
          .where((item) => item.kind == kind)
          .toList(growable: false);

  Future<void> saveTask({
    required String id,
    required String title,
    String details = '',
  }) => _save(id, EverydayLifeKind.task, title, details);

  Future<void> saveNote({
    required String id,
    required String title,
    String details = '',
  }) => _save(id, EverydayLifeKind.note, title, details);

  Future<void> saveList({
    required String id,
    required String title,
    String items = '',
  }) => _save(id, EverydayLifeKind.taskList, title, items);

  Future<void> _save(
    String id,
    EverydayLifeKind kind,
    String title,
    String details,
  ) {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('A title is required.');
    }
    return _store.save(EverydayLifeItem(
      id: id,
      kind: kind,
      title: normalized,
      details: details.trim(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }

  Future<void> setCompleted(EverydayLifeItem item, bool completed) =>
      _store.save(item.copyWith(completed: completed));
}
