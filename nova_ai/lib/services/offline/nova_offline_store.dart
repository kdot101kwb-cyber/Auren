import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small, device-local store for NOVA tasks and income plans.
/// No network or Firebase dependency is required for these operations.
class NovaOfflineStore {
  NovaOfflineStore({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;

  static const _tasksKey = 'nova.offline.tasks.v1';
  static const _plansKey = 'nova.offline.income_plans.v1';

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<NovaOfflineTask>> getTasks() async {
    final raw = (await _prefs).getString(_tasksKey);
    if (raw == null || raw.isEmpty) return <NovaOfflineTask>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              NovaOfflineTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return <NovaOfflineTask>[];
    } on TypeError {
      return <NovaOfflineTask>[];
    }
  }

  Future<void> saveTask(NovaOfflineTask task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
    await (await _prefs).setString(
      _tasksKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteTask(String id) async {
    final tasks = await getTasks()
      ..removeWhere((item) => item.id == id);
    await (await _prefs).setString(
      _tasksKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<NovaIncomePlan>> getIncomePlans() async {
    final raw = (await _prefs).getString(_plansKey);
    if (raw == null || raw.isEmpty) return <NovaIncomePlan>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              NovaIncomePlan.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return <NovaIncomePlan>[];
    } on TypeError {
      return <NovaIncomePlan>[];
    }
  }

  Future<void> saveIncomePlan(NovaIncomePlan plan) async {
    final plans = await getIncomePlans();
    final index = plans.indexWhere((item) => item.id == plan.id);
    if (index < 0) {
      plans.add(plan);
    } else {
      plans[index] = plan;
    }
    await (await _prefs).setString(
      _plansKey,
      jsonEncode(plans.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteIncomePlan(String id) async {
    final plans = await getIncomePlans()
      ..removeWhere((item) => item.id == id);
    await (await _prefs).setString(
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
    this.updatedAtMillis = 0,
  });

  final String id;
  final String title;
  final String notes;
  final bool isComplete;
  final int updatedAtMillis;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'notes': notes,
        'isComplete': isComplete,
        'updatedAtMillis': updatedAtMillis,
      };

  factory NovaOfflineTask.fromJson(Map<String, dynamic> json) =>
      NovaOfflineTask(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        isComplete: json['isComplete'] as bool? ?? false,
        updatedAtMillis: json['updatedAtMillis'] as int? ?? 0,
      );
}

class NovaIncomePlan {
  const NovaIncomePlan({
    required this.id,
    required this.name,
    required this.monthlyRevenue,
    required this.monthlyCosts,
    this.initialInvestment = 0,
    this.currency = 'USD',
    this.updatedAtMillis = 0,
  });

  final String id;
  final String name;
  final double monthlyRevenue;
  final double monthlyCosts;
  final double initialInvestment;
  final String currency;
  final int updatedAtMillis;

  double get estimatedMonthlyProfit => monthlyRevenue - monthlyCosts;

  /// Estimated months to recover initial investment, or null when there is
  /// no positive monthly profit. This is a simple estimate, not a guarantee.
  double? get estimatedBreakEvenMonths {
    final profit = estimatedMonthlyProfit;
    if (profit <= 0) return null;
    return initialInvestment <= 0 ? 0 : initialInvestment / profit;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'monthlyRevenue': monthlyRevenue,
        'monthlyCosts': monthlyCosts,
        'initialInvestment': initialInvestment,
        'currency': currency,
        'updatedAtMillis': updatedAtMillis,
      };

  factory NovaIncomePlan.fromJson(Map<String, dynamic> json) =>
      NovaIncomePlan(
        id: json['id'] as String,
        name: json['name'] as String,
        monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
        monthlyCosts: (json['monthlyCosts'] as num).toDouble(),
        initialInvestment:
            (json['initialInvestment'] as num? ?? 0).toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        updatedAtMillis: json['updatedAtMillis'] as int? ?? 0,
      );
}
