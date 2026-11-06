import '../domain/everyday_life_item.dart';
import 'everyday_life_local_store.dart';

/// User-maintained local directory. No providers, prices, opening hours, or
/// contact details are populated automatically.
class LocalServiceDirectoryRepository {
  LocalServiceDirectoryRepository({EverydayLifeLocalStore? store})
      : _store = store ?? EverydayLifeLocalStore();

  final EverydayLifeLocalStore _store;

  Future<List<EverydayLifeItem>> get entries async =>
      (await _store.readAll())
          .where((item) => item.kind == EverydayLifeKind.localService)
          .toList(growable: false);

  Future<List<EverydayLifeItem>> get favorites async =>
      (await entries).where((item) => item.favorite).toList(growable: false);

  Future<List<EverydayLifeItem>> get unconfirmed async =>
      (await entries)
          .where((item) => !item.informationConfirmed)
          .toList(growable: false);

  Future<void> addEntry({
    required String id,
    required String name,
    String category = '',
    String details = '',
    String contact = '',
    String location = '',
  }) {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError('A service name is required.');
    return _store.save(EverydayLifeItem(
      id: id,
      kind: EverydayLifeKind.localService,
      title: normalized,
      category: category.trim(),
      details: details.trim(),
      contact: contact.trim(),
      location: location.trim(),
      informationConfirmed: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }

  Future<void> setUserVerified(EverydayLifeItem item, bool verified) {
    if (item.kind != EverydayLifeKind.localService) {
      throw ArgumentError('Only local directory entries can be verified.');
    }
    return _store.save(item.copyWith(informationConfirmed: verified));
  }

  Future<void> setFavorite(EverydayLifeItem item, bool favorite) {
    if (item.kind != EverydayLifeKind.localService) {
      throw ArgumentError('Only local directory entries can be favorited.');
    }
    return _store.save(item.copyWith(favorite: favorite));
  }
}
