import '../domain/everyday_life_item.dart';
import 'everyday_life_local_store.dart';

/// Draft-only requests. This repository intentionally has no send, book,
/// call, or confirmation operation.
class AppointmentServiceRequestRepository {
  AppointmentServiceRequestRepository({EverydayLifeLocalStore? store})
      : _store = store ?? EverydayLifeLocalStore();

  final EverydayLifeLocalStore _store;

  Future<List<EverydayLifeItem>> get drafts async =>
      (await _store.readAll())
          .where((item) => item.kind == EverydayLifeKind.appointmentDraft)
          .toList(growable: false);

  Future<void> saveDraft({
    required String id,
    required String title,
    String details = '',
    String providerName = '',
    String contact = '',
    String location = '',
    String requestedWindow = '',
  }) {
    final normalized = title.trim();
    if (normalized.isEmpty) throw ArgumentError('A title is required.');
    return _store.save(EverydayLifeItem(
      id: id,
      kind: EverydayLifeKind.appointmentDraft,
      title: normalized,
      details: details.trim(),
      providerName: providerName.trim(),
      contact: contact.trim(),
      location: location.trim(),
      requestedWindow: requestedWindow.trim(),
      informationConfirmed: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }
}
