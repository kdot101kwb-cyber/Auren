import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small, device-local store for NOVA's offline task and income-planning data.
/// This is intended for lightweight records, not large files or AI model weights.
class NovaOfflineStore {
  NovaOfflineStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _tasksKey = 'nova.offline.tasks.v1';
  static const _plansKey = 'nova.offline.income_plans.v1';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<NovaOfflineTask>> loadTasks() async {
    final raw = (await _store).getString(_tasksKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              NovaOfflineTask.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> saveTask(NovaOfflineTask task) async {
    final tasks = (await loadTasks()).toList();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
    final store = await _store;
    await store.setString(
      _tasksKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteTask(String id) async {
    final tasks = (await loadTasks()).where((item) => item.id != id).toList();
    await (await _store).setString(
      _tasksKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<NovaIncomePlan>> loadIncomePlans() async {
    final raw = (await _store).getString(_plansKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              NovaIncomePlan.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> saveIncomePlan(NovaIncomePlan plan) async {
    final plans = (await loadIncomePlans()).toList();
    final index = plans.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      plans.add(plan);
    } else {
      plans[index] = plan;
    }
    await (await _store).setString(
      _plansKey,
      jsonEncode(plans.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteIncomePlan(String id) async {
    final plans =
        (await loadIncomePlans()).where((item) => item.id != id).toList();
    await (await _store).setString(
      _plansKey,
      jsonEncode(plans.map((item) => item.toJson()).toList()),
    );
  }
}

class NovaOfflineTask {
  const NovaOfflineTask({
    required this.id,
    required this.title,
    this.notes = '',
    this.isComplete = false,
    this.updatedAtEpochMs = 0,
  });

  final String id;
  final String title;
  final String notes;
  final bool isComplete;
  final int updatedAtEpochMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'isComplete': isComplete,
        'updatedAtEpochMs': updatedAtEpochMs,
      };

  factory NovaOfflineTask.fromJson(Map<String, dynamic> json) =>
      NovaOfflineTask(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        isComplete: json['isComplete'] as bool? ?? false,
        updatedAtEpochMs: json['updatedAtEpochMs'] as int? ?? 0,
      );
}

class NovaIncomePlan {
  const NovaIncomePlan({
    required this.id,
    required this.name,
    required this.startupCost,
    required this.monthlyRevenue,
    required this.monthlyCosts,
    this.currency = 'USD',
    this.notes = '',
  });

  final String id;
  final String name;
  final double startupCost;
  final double monthlyRevenue;
  final double monthlyCosts;
  final String currency;
  final String notes;

  double get estimatedMonthlyProfit => monthlyRevenue - monthlyCosts;

  /// Number of months to recover the initial cost; null if profit is not positive.
  double? get estimatedBreakEvenMonths {
    final profit = estimatedMonthlyProfit;
    if (profit <= 0) return null;
    return startupCost / profit;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startupCost': startupCost,
        'monthlyRevenue': monthlyRevenue,
        'monthlyCosts': monthlyCosts,
        'currency': currency,
        'notes': notes,
      };

  factory NovaIncomePlan.fromJson(Map<String, dynamic> json) =>
      NovaIncomePlan(
        id: json['id'] as String,
        name: json['name'] as String,
        startupCost: (json['startupCost'] as num).toDouble(),
        monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
        monthlyCosts: (json['monthlyCosts'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        notes: json['notes'] as String? ?? '',
      );
}
