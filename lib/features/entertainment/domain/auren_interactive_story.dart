enum AurenStoryEnding { creator, explorer, connector, guardian }

class AurenStoryChoice {
  final String id;
  final String title;
  final String description;
  final String nextNodeId;

  const AurenStoryChoice({
    required this.id,
    required this.title,
    required this.description,
    required this.nextNodeId,
  });
}

class AurenStoryNode {
  final String id;
  final String title;
  final String narration;
  final List<AurenStoryChoice> choices;
  final AurenStoryEnding? ending;

  const AurenStoryNode({
    required this.id,
    required this.title,
    required this.narration,
    this.choices = const [],
    this.ending,
  });
}

/// Small deterministic branching-story engine. The story is local-first:
/// choices are evaluated on-device and no personal data is required.
class AurenInteractiveStory {
  AurenInteractiveStory._();

  static const startNodeId = 'arrival';

  static const Map<String, AurenStoryNode> nodes = {
    'arrival': AurenStoryNode(
      id: 'arrival',
      title: 'البوابة التي لا تظهر مرتين',
      narration: 'تستيقظ في مدينة تتغير مع كل قرار. أمامك ثلاث بوابات؛ '
          'كل واحدة تقود إلى نسخة مختلفة من حياتك.',
      choices: [
        AurenStoryChoice(
          id: 'build',
          title: 'أبني شيئًا لم يوجد',
          description: 'اتبع فضولك وصمّم أداة جديدة.',
          nextNodeId: 'workshop',
        ),
        AurenStoryChoice(
          id: 'wander',
          title: 'أستكشف المجهول',
          description: 'ادخل الأزقة التي لا تظهر على الخريطة.',
          nextNodeId: 'wilds',
        ),
        AurenStoryChoice(
          id: 'meet',
          title: 'أبحث عن رفاق',
          description: 'اكتشف من يشاركك هذه الرحلة.',
          nextNodeId: 'plaza',
        ),
      ],
    ),
    'workshop': AurenStoryNode(
      id: 'workshop',
      title: 'ورشة الاحتمالات',
      narration: 'وجدت آلة تحول الأفكار إلى نماذج أولية. لديك فرصة لصنع شيء يفيد المدينة.',
      choices: [
        AurenStoryChoice(
          id: 'prototype',
          title: 'أصنع نموذجًا أوليًا',
          description: 'حوّل الفكرة إلى شيء قابل للتجربة.',
          nextNodeId: 'ending_creator',
        ),
        AurenStoryChoice(
          id: 'share',
          title: 'أدعو الآخرين للمشاركة',
          description: 'اجعل الاختراع مشروعًا مشتركًا.',
          nextNodeId: 'ending_connector',
        ),
      ],
    ),
    'wilds': AurenStoryNode(
      id: 'wilds',
      title: 'حديقة الاحتمالات',
      narration: 'كل مسار يكشف لغزًا جديدًا، لكن الخريطة لا تكتمل إلا إذا اخترت طريقك.',
      choices: [
        AurenStoryChoice(
          id: 'map',
          title: 'أرسم خريطة جديدة',
          description: 'حوّل الاكتشاف إلى معرفة.',
          nextNodeId: 'ending_explorer',
        ),
        AurenStoryChoice(
          id: 'return',
          title: 'أعود ومعي اكتشافاتي',
          description: 'شارك ما تعلمته مع المدينة.',
          nextNodeId: 'ending_connector',
        ),
        AurenStoryChoice(
          id: 'mirror',
          title: 'أدخل مرآة المشاعر',
          description: 'اكتشف كيف يمكن لمشاعرك أن تغيّر العالم حولك.',
          nextNodeId: 'emotion_realm',
        ),
      ],
    ),
    'emotion_realm': AurenStoryNode(
      id: 'emotion_realm',
      title: 'العالم الذي يسمع مشاعرك',
      narration: 'تتحول الألوان والأصوات حولك مع كل شعور. لا يوجد شعور خاطئ؛ '
          'السؤال هو كيف تستخدم ما تشعر به لتفهم العالم.',
      choices: [
        AurenStoryChoice(
          id: 'turn_emotion_into_art',
          title: 'أحوّل الشعور إلى فن',
          description: 'اصنع أثرًا يعبّر عن تجربتك.',
          nextNodeId: 'ending_creator',
        ),
        AurenStoryChoice(
          id: 'understand_others',
          title: 'أحاول فهم مشاعر الآخرين',
          description: 'ابنِ جسرًا بين عوالم مختلفة.',
          nextNodeId: 'ending_connector',
        ),
      ],
    ),
    'plaza': AurenStoryNode(
      id: 'plaza',
      title: 'ساحة الغرباء',
      narration: 'تجد أشخاصًا لديهم مهارات وأحلام مختلفة. يمكنكم بناء شيء أكبر معًا.',
      choices: [
        AurenStoryChoice(
          id: 'team',
          title: 'أكوّن فريقًا',
          description: 'اجمع المهارات حول هدف واحد.',
          nextNodeId: 'ending_connector',
        ),
        AurenStoryChoice(
          id: 'solo',
          title: 'أتابع رحلتي الخاصة',
          description: 'ابدأ مغامرتك باستقلالية.',
          nextNodeId: 'ending_explorer',
        ),
        AurenStoryChoice(
          id: 'secret',
          title: 'أكشف سر المدينة',
          description: 'افتح الأرشيف الذي ظل مخفيًا عن الجميع.',
          nextNodeId: 'city_archive',
        ),
      ],
    ),
    'city_archive': AurenStoryNode(
      id: 'city_archive',
      title: 'الأرشيف المخفي',
      narration: 'تكتشف أن المدينة تحفظ قصصًا لم تُروَ ووعودًا لم تُنفّذ. '
          'يمكنك حماية خصوصية أصحابها أو مشاركة الدروس التي لا تكشف هوياتهم.',
      choices: [
        AurenStoryChoice(
          id: 'protect_stories',
          title: 'أحمي القصص وأصحابها',
          description: 'اجعل الثقة أهم من الفضول.',
          nextNodeId: 'ending_guardian',
        ),
        AurenStoryChoice(
          id: 'share_lessons',
          title: 'أشارك الدروس دون كشف الأسرار',
          description: 'حوّل الماضي إلى معرفة نافعة للجميع.',
          nextNodeId: 'ending_explorer',
        ),
      ],
    ),
    'ending_creator': AurenStoryNode(
      id: 'ending_creator',
      title: 'نهاية: صانع الاحتمالات',
      narration: 'لم تكتفِ بتخيّل المستقبل؛ صنعت أول نسخة منه. هذه النهاية تفتح بابًا لقصة جديدة.',
      ending: AurenStoryEnding.creator,
    ),
    'ending_explorer': AurenStoryNode(
      id: 'ending_explorer',
      title: 'نهاية: مكتشف العوالم',
      narration: 'أصبحت المدينة أكبر لأنك رأيت ما لم يره الآخرون. كل اكتشاف بداية لمسار جديد.',
      ending: AurenStoryEnding.explorer,
    ),
    'ending_connector': AurenStoryNode(
      id: 'ending_connector',
      title: 'نهاية: صانع الروابط',
      narration: 'حوّلت اختلاف الناس إلى قوة مشتركة. العالم الموازي صار أفضل لأنكم بنيتموه معًا.',
      ending: AurenStoryEnding.connector,
    ),
    'ending_guardian': AurenStoryNode(
      id: 'ending_guardian',
      title: 'نهاية: حارس الثقة',
      narration: 'اخترت أن تكون الثقة أساس المدينة. ليس كل سر يجب كشفه كي نتعلم منه.',
      ending: AurenStoryEnding.guardian,
    ),
  };

  static AurenStoryNode node(String id) {
    final value = nodes[id];
    if (value == null) {
      throw ArgumentError.value(id, 'id', 'Unknown story node');
    }
    return value;
  }

  static AurenStoryNode choose(String currentNodeId, String choiceId) {
    final current = node(currentNodeId);
    final matches = current.choices.where((choice) => choice.id == choiceId);
    if (matches.isEmpty) {
      throw ArgumentError.value(
        choiceId,
        'choiceId',
        'Choice is not available at this node',
      );
    }
    return node(matches.first.nextNodeId);
  }

  static List<String> get nodeIds => List.unmodifiable(nodes.keys);
}
