import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/auren_core_five_repository.dart';

class AurenNextMove {
  final String title;
  final String action;
  final String reason;
  final String module;
  final int confidence;
  final List<String> alternatives;

  const AurenNextMove({
    required this.title,
    required this.action,
    required this.reason,
    required this.module,
    required this.confidence,
    required this.alternatives,
  });

  String toPrompt() => 'أنا أريد تنفيذ الخطوة التالية المقترحة في AUREN. '
      'المهمة: $action. الوحدة: $module. السبب: $reason. '
      'نفّذ ما يمكن بأمان، وأي إجراء حساس اطلب موافقتي قبل تنفيذه.';
}

class NextMoveService {
  final FirebaseFirestore _db;
  final AurenCoreFiveRepository _core;

  NextMoveService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _core = AurenCoreFiveRepository(firestore: firestore);

  Future<AurenNextMove> build(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) throw ArgumentError('uid is required');

    final results = await Future.wait([
      _db.collection('users').doc(cleanUid).collection('goals').limit(50).get(),
      _core.load(cleanUid),
    ]);

    final goals = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final core = results[1] as AurenCoreFiveSnapshot;
    final active = goals.docs
        .where((d) => (d.data()['status']?.toString() ?? 'active') == 'active')
        .toList();

    if (active.isEmpty) {
      return const AurenNextMove(
        title: 'ابدأ بهدف واحد',
        action: 'أنشئ هدفًا واضحًا وقابلًا للقياس في Goal → Reality.',
        reason: 'لا يوجد هدف نشط يمكن لـ AUREN أن يبني عليه خطوة تالية.',
        module: 'Personal AI',
        confidence: 98,
        alternatives: ['أضف ذاكرة شخصية مفيدة', 'استكشف فرصة مرتبطة بمهاراتك'],
      );
    }

    active.sort((a, b) {
      final ap = (a.data()['progress'] as num?)?.toInt() ?? 0;
      final bp = (b.data()['progress'] as num?)?.toInt() ?? 0;
      if (ap != bp) return ap.compareTo(bp);
      return (b.data()['updatedAt']?.toString() ?? '')
          .compareTo(a.data()['updatedAt']?.toString() ?? '');
    });

    final goal = active.first.data();
    final goalTitle = goal['title']?.toString().trim() ?? 'هدفك الحالي';
    final progress = ((goal['progress'] as num?)?.toInt() ?? 0).clamp(0, 100);

    if (!core.hasBusiness) {
      return AurenNextMove(
        title: 'اربط هدفك بعمل',
        action: 'أنشئ Business أو خدمة مرتبطة بالهدف: $goalTitle.',
        reason: 'هدفك موجود، لكن لا يوجد Business مرتبط به داخل Core 5.',
        module: 'Business',
        confidence: 92,
        alternatives: ['حوّل الهدف إلى محتوى', 'ابحث عن فرصة مناسبة'],
      );
    }
    if (!core.hasProduct) {
      return AurenNextMove(
        title: 'حوّل الهدف إلى عرض',
        action: 'أضف منتجًا أو خدمة مرتبطة بالهدف: $goalTitle.',
        reason: 'يوجد Business لكن لا يوجد منتج أو خدمة في Marketplace.',
        module: 'Marketplace',
        confidence: 90,
        alternatives: ['أنشئ مسودة Creator', 'ابحث عن شريك أو عميل'],
      );
    }
    if (!core.hasCreatorDraft) {
      return AurenNextMove(
        title: 'حوّل تقدمك إلى محتوى',
        action: 'أنشئ مسودة محتوى من هدفك: $goalTitle.',
        reason: 'لديك هدف وBusiness/Marketplace، لكن لا توجد مسودة Creator تربط القصة بالفرصة.',
        module: 'Creator Studio',
        confidence: 89,
        alternatives: ['انشر تحديثًا في Pulse', 'ابحث عن فرصة'],
      );
    }
    if (!core.hasPulse) {
      return AurenNextMove(
        title: 'شارك ما تبنيه',
        action: 'انشر تحديثًا قصيرًا عن تقدمك في الهدف: $goalTitle.',
        reason: 'مشاركة التقدم تضيف إشارة اجتماعية يمكن ربطها بفرص ومجتمع.',
        module: 'Pulse',
        confidence: 86,
        alternatives: ['طوّر مسودة Creator', 'ابحث عن شريك'],
      );
    }

    final action = progress < 50
        ? 'نفّذ خطوة صغيرة اليوم ترفع تقدم الهدف "$goalTitle" بنسبة واضحة.'
        : 'اربط الهدف "$goalTitle" بفرصة واحدة: عميل أو شريك أو منتج أو محتوى.';
    return AurenNextMove(
      title: progress < 50 ? 'حرّك الهدف للأمام' : 'حوّل التقدم إلى فرصة',
      action: action,
      reason: 'Core 5 يحتوي إشارات كافية، والأولوية الآن هي تحويلها إلى نتيجة عملية.',
      module: progress < 50 ? 'Goal → Reality' : 'Opportunity',
      confidence: progress < 50 ? 84 : 81,
      alternatives: ['راجع Personal Brief', 'افتح Opportunity Radar'],
    );
  }
}