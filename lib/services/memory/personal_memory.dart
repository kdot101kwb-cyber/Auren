class PersonalMemoryItem {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool enabled;
  const PersonalMemoryItem({required this.id, required this.text, required this.createdAt, this.enabled = true});
}

abstract interface class PersonalMemoryStore {
  Future<List<PersonalMemoryItem>> list();
  Future<void> save(PersonalMemoryItem item);
  Future<void> delete(String id);
}

class LocalPersonalMemoryStore implements PersonalMemoryStore {
  final List<PersonalMemoryItem> _items = [];
  @override Future<List<PersonalMemoryItem>> list() async => List.unmodifiable(_items);
  @override Future<void> save(PersonalMemoryItem item) async => _items.add(item);
  @override Future<void> delete(String id) async => _items.removeWhere((item) => item.id == id);
}
