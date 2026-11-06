import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AurenDirectoryProvider = Future<Directory> Function();

class AurenHelpTopic {
  const AurenHelpTopic({
    required this.id,
    required this.title,
    required this.body,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String body;
  final List<String> keywords;
}

class AurenFeedbackDraft {
  const AurenFeedbackDraft({
    required this.id,
    required this.kind,
    required this.title,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String details;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        'title': title,
        'details': details,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory AurenFeedbackDraft.fromMap(Map<String, dynamic> map) =>
      AurenFeedbackDraft(
        id: map['id'] as String? ?? '',
        kind: map['kind'] as String? ?? 'feedback',
        title: map['title'] as String? ?? '',
        details: map['details'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

class AurenStorageSnapshot {
  const AurenStorageSnapshot({
    required this.fileCount,
    required this.bytes,
  });

  final int fileCount;
  final int bytes;
}

class AurenConnectivityReport {
  const AurenConnectivityReport({
    required this.types,
    required this.summary,
    required this.internetVerified,
  });

  final List<ConnectivityResult> types;
  final String summary;

  /// Connectivity type does not prove that internet access works.
  final bool internetVerified;
}

/// Local-first support utilities. Feedback stays on-device and is never sent
/// automatically. Cache cleanup is restricted to this service's own directory.
class AurenPlatformToolsService {
  AurenPlatformToolsService({
    SharedPreferences? preferences,
    AurenDirectoryProvider? temporaryDirectoryProvider,
    Connectivity? connectivity,
  })  : _preferences = preferences,
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory,
        _connectivity = connectivity ?? Connectivity();

  static const _feedbackKey = 'auren.platform_tools.feedback.v1';
  static const maxFeedbackDrafts = 100;
  static const maxCacheBytes = 50 * 1024 * 1024;

  SharedPreferences? _preferences;
  final AurenDirectoryProvider _temporaryDirectoryProvider;
  final Connectivity _connectivity;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  static const helpTopics = <AurenHelpTopic>[
    AurenHelpTopic(
      id: 'offline',
      title: 'استخدام AUREN دون إنترنت',
      body: 'بعض البيانات المحفوظة محلياً تظل متاحة دون اتصال. '
          'المحتوى الذي لم يُحفظ على الجهاز قد يحتاج إلى الإنترنت.',
      keywords: ['offline', 'internet', 'اتصال', 'إنترنت'],
    ),
    AurenHelpTopic(
      id: 'privacy',
      title: 'الخصوصية والبيانات',
      body: 'راجع إعدادات كل ميزة قبل مشاركة المعلومات. '
          'مسودات الملاحظات والأعطال في هذه الصفحة تبقى على الجهاز ولا تُرسل تلقائياً.',
      keywords: ['privacy', 'data', 'خصوصية', 'بيانات'],
    ),
    AurenHelpTopic(
      id: 'troubleshooting',
      title: 'حل المشكلات الشائعة',
      body: 'جرّب إعادة فتح الصفحة، وتحقق من الاتصال، ثم أعد المحاولة. '
          'إذا استمرت المشكلة، احفظ وصفها في مركز الملاحظات.',
      keywords: ['error', 'bug', 'problem', 'مشكلة', 'خطأ'],
    ),
    AurenHelpTopic(
      id: 'storage',
      title: 'إدارة مساحة التخزين',
      body: 'يمكنك مسح الملفات المؤقتة التي ينشئها مركز أدوات AUREN فقط. '
          'لن نحذف الصور أو المستندات أو التنزيلات التابعة للميزات الأخرى.',
      keywords: ['storage', 'cache', 'مساحة', 'تخزين'],
    ),
  ];

  Future<List<AurenFeedbackDraft>> feedbackDrafts() async {
    final raw = (await _store).getString(_feedbackKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((row) => AurenFeedbackDraft.fromMap(
              Map<String, dynamic>.from(row)))
          .where((draft) =>
              draft.id.isNotEmpty &&
              draft.title.isNotEmpty &&
              const {'feedback', 'bug'}.contains(draft.kind))
          .take(maxFeedbackDrafts)
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> saveFeedback({
    required String id,
    required String kind,
    required String title,
    required String details,
    DateTime? createdAt,
  }) async {
    final safeId = id.trim();
    final safeKind = kind.trim();
    final safeTitle = title.trim();
    final safeDetails = details.trim();
    if (safeId.isEmpty ||
        safeId.length > 80 ||
        !const {'feedback', 'bug'}.contains(safeKind) ||
        safeTitle.isEmpty ||
        safeTitle.length > 120 ||
        safeDetails.isEmpty ||
        safeDetails.length > 2000) {
      throw ArgumentError('Feedback draft is invalid.');
    }
    final store = await _store;
    final drafts = await feedbackDrafts();
    drafts.removeWhere((draft) => draft.id == safeId);
    if (drafts.length >= maxFeedbackDrafts) {
      throw StateError('Feedback draft limit reached.');
    }
    drafts.insert(
      0,
      AurenFeedbackDraft(
        id: safeId,
        kind: safeKind,
        title: safeTitle,
        details: safeDetails,
        createdAt: createdAt ?? DateTime.now().toUtc(),
      ),
    );
    await store.setString(
      _feedbackKey,
      jsonEncode(drafts.map((draft) => draft.toMap()).toList()),
    );
  }

  Future<void> removeFeedback(String id) async {
    final safeId = id.trim();
    if (safeId.isEmpty) throw ArgumentError('Feedback ID is required.');
    final store = await _store;
    final drafts = await feedbackDrafts();
    drafts.removeWhere((draft) => draft.id == safeId);
    await store.setString(
      _feedbackKey,
      jsonEncode(drafts.map((draft) => draft.toMap()).toList()),
    );
  }

  Future<Directory> _cacheDirectory() async {
    final temporary = await _temporaryDirectoryProvider();
    return Directory(
      '${temporary.path}${Platform.pathSeparator}auren_platform_tools_cache',
    );
  }

  Future<AurenStorageSnapshot> inspectCache() async {
    final directory = await _cacheDirectory();
    if (!await directory.exists()) {
      return const AurenStorageSnapshot(fileCount: 0, bytes: 0);
    }
    var count = 0;
    var bytes = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          bytes += await entity.length();
          count++;
        } on FileSystemException {
          // Ignore files that disappear while inspecting the cache.
        }
      }
    }
    return AurenStorageSnapshot(fileCount: count, bytes: bytes);
  }

  Future<void> clearOwnedCache() async {
    final directory = await _cacheDirectory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      await entity.delete(recursive: true);
    }
  }

  Future<AurenConnectivityReport> connectivityReport() async {
    final results = await _connectivity.checkConnectivity();
    return reportFor(results);
  }

  static AurenConnectivityReport reportFor(List<ConnectivityResult> results) {
    final unique = results.toSet().toList();
    if (unique.isEmpty || unique.every((item) => item == ConnectivityResult.none)) {
      return AurenConnectivityReport(
        types: const [ConnectivityResult.none],
        summary: 'لا يوجد اتصال شبكة مُبلغ عنه على الجهاز.',
        internetVerified: false,
      );
    }
    final labels = unique.map((result) {
      switch (result) {
        case ConnectivityResult.wifi:
          return 'Wi-Fi';
        case ConnectivityResult.mobile:
          return 'بيانات الهاتف';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.satellite:
          return 'Satellite';
        case ConnectivityResult.other:
          return 'اتصال آخر';
        case ConnectivityResult.none:
          return 'لا اتصال';
      }
    }).toList();
    return AurenConnectivityReport(
      types: unique,
      summary: 'نوع الاتصال المُبلغ عنه: ${labels.join('، ')}. '
          'هذا لا يؤكد إمكانية الوصول إلى الإنترنت.',
      internetVerified: false,
    );
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
