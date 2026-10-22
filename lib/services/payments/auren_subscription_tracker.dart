import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A manually confirmed recurring-bill record. It never triggers a payment.
class AurenSubscription {
  const AurenSubscription({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.nextDue,
    this.cadenceDays = 30,
    this.active = true,
    this.notes = '',
  });

  final String id;
  final String name;
  final int amountMinor;
  final String currency;
  final DateTime nextDue;
  final int cadenceDays;
  final bool active;
  final String notes;

  String? validate() {
    if (id.trim().isEmpty) return 'Subscription id is required.';
    if (name.trim().isEmpty || name.trim().length > 100) {
      return 'Name must contain 1–100 characters.';
    }
    if (amountMinor <= 0) return 'Amount must be positive.';
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      return 'Currency must be a three-letter uppercase code.';
    }
    if (cadenceDays < 1 || cadenceDays > 366) {
      return 'Cadence must be between 1 and 366 days.';
    }
    if (notes.length > 500) return 'Notes must be 500 characters or fewer.';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name.trim(),
        'amountMinor': amountMinor,
        'currency': currency,
        'nextDue': nextDue.toUtc().toIso8601String(),
        'cadenceDays': cadenceDays,
        'active': active,
        'notes': notes.trim(),
      };

  factory AurenSubscription.fromJson(Map<String, dynamic> json) =>
      AurenSubscription(
        id: json['id'] as String,
        name: json['name'] as String,
        amountMinor: json['amountMinor'] as int,
        currency: json['currency'] as String,
        nextDue: DateTime.parse(json['nextDue'] as String).toLocal(),
        cadenceDays: json['cadenceDays'] as int? ?? 30,
        active: json['active'] as bool? ?? true,
        notes: json['notes'] as String? ?? '',
      );
}

class AurenSubscriptionSummary {
  const AurenSubscriptionSummary({
    required this.activeCount,
    required this.upcoming,
    required this.totalsByCurrency,
  });

  final int activeCount;
  final List<AurenSubscription> upcoming;
  final Map<String, int> totalsByCurrency;
}

class AurenSubscriptionTracker {
  const AurenSubscriptionTracker();

  String _key(String uid) => 'auren.subscription_tracker.v1.$uid';

  Future<List<AurenSubscription>> load(String uid) async {
    if (uid.trim().isEmpty) throw ArgumentError.value(uid, 'uid');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => AurenSubscription.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
  }

  Future<void> save(String uid, List<AurenSubscription> records) async {
    if (uid.trim().isEmpty) throw ArgumentError.value(uid, 'uid');
    final ids = <String>{};
    for (final record in records) {
      final error = record.validate();
      if (error != null) throw ArgumentError(error);
      if (!ids.add(record.id)) throw ArgumentError('Duplicate subscription id.');
    }
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      _key(uid),
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
    if (!ok) throw StateError('Could not save subscription records locally.');
  }

  AurenSubscriptionSummary summarize(
    List<AurenSubscription> records, {
    required DateTime now,
    int dueWithinDays = 30,
  }) {
    if (dueWithinDays < 0 || dueWithinDays > 366) {
      throw ArgumentError.value(dueWithinDays, 'dueWithinDays');
    }
    final active = records.where((record) => record.active).toList();
    final cutoff = now.add(Duration(days: dueWithinDays));
    final upcoming = active
        .where((record) =>
            !record.nextDue.isBefore(DateTime(now.year, now.month, now.day)) &&
            !record.nextDue.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    final totals = <String, int>{};
    for (final record in active) {
      totals.update(
        record.currency,
        (value) => value + record.amountMinor,
        ifAbsent: () => record.amountMinor,
      );
    }
    return AurenSubscriptionSummary(
      activeCount: active.length,
      upcoming: List.unmodifiable(upcoming),
      totalsByCurrency: Map.unmodifiable(totals),
    );
  }
}
