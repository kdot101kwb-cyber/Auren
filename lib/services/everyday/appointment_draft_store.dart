import 'package:shared_preferences/shared_preferences.dart';
import 'appointment_draft_service.dart';
import 'uid_scoped_json_list_store.dart';

class AurenAppointmentDraftStore {
  AurenAppointmentDraftStore({SharedPreferences? preferences})
      : _store = AurenUidScopedJsonListStore<AurenAppointmentDraft>(
          keyPrefix: 'auren_appointment_drafts_v1_',
          preferences: preferences,
        );

  final AurenUidScopedJsonListStore<AurenAppointmentDraft> _store;

  Future<List<AurenAppointmentDraft>> loadDrafts(String uid) async {
    final drafts = (await _store.load(uid, decode: _fromJson, validate: (v) => v.validate())).toList();
    drafts.sort((a, b) {
      final byTime = a.startsAt.compareTo(b.startsAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return List.unmodifiable(drafts);
  }

  Future<void> saveDraft(String uid, AurenAppointmentDraft draft) async {
    final issue = draft.validate();
    if (issue != null) throw ArgumentError(issue);
    final drafts = (await loadDrafts(uid)).toList();
    final index = drafts.indexWhere((existing) => existing.id == draft.id);
    if (index < 0) {
      if (draft.status != AppointmentDraftStatus.planned) {
        throw ArgumentError('A new appointment draft must start as planned.');
      }
      drafts.add(draft);
    } else {
      final previous = drafts[index];
      if (!AurenAppointmentDraftPolicy.canTransition(previous.status, draft.status)) {
        throw StateError('Invalid appointment status transition.');
      }
      drafts[index] = draft;
    }
    await _store.saveAll(uid, drafts, encode: _toJson, validate: (v) => v.validate());
  }

  Future<AurenAppointmentDraft> transitionDraft(String uid, String draftId, AppointmentDraftStatus next) async {
    final drafts = await loadDrafts(uid);
    final index = drafts.indexWhere((draft) => draft.id == draftId);
    if (index < 0) throw ArgumentError('Appointment draft was not found.');
    final updated = AurenAppointmentDraftPolicy.transition(drafts[index], next);
    await saveDraft(uid, updated);
    return updated;
  }

  static Map<String, dynamic> _toJson(AurenAppointmentDraft draft) => {
    'id': draft.id,
    'title': draft.title,
    'providerName': draft.providerName,
    'location': draft.location,
    'startsAt': draft.startsAt.toUtc().toIso8601String(),
    'endsAt': draft.endsAt?.toUtc().toIso8601String(),
    'notes': draft.notes,
    'status': draft.status.name,
  };

  static AurenAppointmentDraft _fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'planned';
    final status = switch (statusName) {
      'planned' => AppointmentDraftStatus.planned,
      'completed' => AppointmentDraftStatus.completed,
      'cancelled' => AppointmentDraftStatus.cancelled,
      _ => throw const FormatException('Unknown appointment draft status.'),
    };
    return AurenAppointmentDraft(
      id: json['id'] as String,
      title: json['title'] as String,
      providerName: json['providerName'] as String?,
      location: json['location'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null ? null : DateTime.parse(json['endsAt'] as String),
      notes: json['notes'] as String? ?? '',
      status: status,
    );
  }
}