/// Specialized AI capability catalog for every AUREN Talent category.
///
/// These are talent-development tools. Employment, business operations,
/// agriculture sectors and skilled-service work remain outside Talent.
class AurenTalentSpecializedCapability {
  final String id;
  final String name;
  final String prompt;
  const AurenTalentSpecializedCapability({
    required this.id,
    required this.name,
    required this.prompt,
  });
}

class AurenTalentSpecializedCatalog {
  static const byCategory = <String, List<AurenTalentSpecializedCapability>>{
    'sports': [
      AurenTalentSpecializedCapability(id:'sports_performance_lab',name:'Performance Lab',prompt:'حلّل بيانات أدائي الرياضي التي أقدمها وحدد نقاط القوة ومجالات التطوير والخطوة التالية بدون تشخيص طبي.'),
      AurenTalentSpecializedCapability(id:'sports_training_plan',name:'Training Plan',prompt:'أنشئ لي خطة تدريب رياضية تدريجية حسب رياضتي ومستواي وهدفي ووقتي، مع مؤشرات متابعة واضحة.'),
      AurenTalentSpecializedCapability(id:'sports_video_review',name:'Video Review',prompt:'راجع فيديو أدائي الرياضي عند إرفاقه وحدد الملاحظات الفنية الظاهرة وما يمكن تحسينه دون ادعاء قياسات غير متاحة.'),
      AurenTalentSpecializedCapability(id:'sports_highlights',name:'Highlight Builder',prompt:'حوّل أفضل لقطات وإنجازات أدائي الرياضي إلى تصور Highlight مرتب ومناسب لملف الموهبة.'),
      AurenTalentSpecializedCapability(id:'sports_tryout',name:'Tryout Coach',prompt:'جهزني لاختبار أداء رياضي عبر قائمة تحضير ومهام ونقاط أركز عليها قبل التجربة.'),
      AurenTalentSpecializedCapability(id:'sports_progress',name:'Progress Tracker',prompt:'حوّل سجلات أدائي الرياضي إلى قصة تطور تقارنني بنفسي عبر الزمن وتحدد الخطوة التالية.'),
    ],
    'music': [
      AurenTalentSpecializedCapability(id:'music_song_lab',name:'Song Creation Lab',prompt:'ساعدني في صناعة أغنية من الفكرة إلى الكلمات والبناء واللحن والـKey والـBPM والترتيب والتجهيز للتسجيل.'),
      AurenTalentSpecializedCapability(id:'music_demo_lab',name:'Demo Lab',prompt:'ساعدني في تخطيط Demo لأغنيتي: التسجيل، الطبقات، الترتيب، الملاحظات والنسخ التي أحتاج الاحتفاظ بها.'),
      AurenTalentSpecializedCapability(id:'music_vocal_coach',name:'Vocal Coach',prompt:'ابنِ لي خطة تدريب صوتي مناسبة لمستواي، وإذا قدمت تسجيلًا افصل بين الملاحظات المسموعة والقياسات التي تحتاج أداة تحليل.'),
      AurenTalentSpecializedCapability(id:'music_arrangement',name:'Arrangement Lab',prompt:'حوّل فكرة أغنيتي إلى Arrangement واضح من Intro وVerse وChorus وBridge وOutro مع اقتراحات مناسبة للنوع الموسيقي.'),
      AurenTalentSpecializedCapability(id:'music_release',name:'Release Builder',prompt:'حوّل أغنيتي الجاهزة إلى خطة إصدار تشمل الهوية والوصف والمحتوى والتجهيز والـcredits والمتابعة.'),
      AurenTalentSpecializedCapability(id:'music_collab',name:'Music Collaboration',prompt:'حدد الأدوار الموسيقية التي أحتاجها لإكمال الأغنية واقترح نوع الموهبة المكملة لي للتعاون.'),
    ],
    'arts_design': [
      AurenTalentSpecializedCapability(id:'art_critique',name:'Creative Critique',prompt:'راجع العمل الفني أو التصميم الذي أقدمه وحدد نقاط القوة والتكوين والوضوح ومجالات التطوير بشكل عملي.'),
      AurenTalentSpecializedCapability(id:'art_idea_lab',name:'Idea Lab',prompt:'طوّر فكرتي الفنية إلى مفهوم واضح، أسلوب بصري، مراجع إبداعية وخطوات تنفيذ.'),
      AurenTalentSpecializedCapability(id:'design_portfolio',name:'Design Portfolio',prompt:'رتب أفضل أعمالي في Portfolio تصميم يوضح المهارات والمشاريع ودوري في كل مشروع.'),
      AurenTalentSpecializedCapability(id:'visual_style',name:'Style Builder',prompt:'استخرج أسلوبي البصري من الأعمال التي أقدمها واقترح طريقة متماسكة لتطوير هويتي الفنية.'),
      AurenTalentSpecializedCapability(id:'art_challenge',name:'Creative Challenge',prompt:'أنشئ لي تحديًا فنيًا عمليًا مناسبًا لمستواي يطور مهارة محددة وينتج عملًا جديدًا.'),
      AurenTalentSpecializedCapability(id:'art_showcase',name:'Art Showcase',prompt:'حوّل أفضل أعمالي الفنية إلى Showcase قصير ومقنع لملف Talent.'),
    ],
    'film_acting': [
      AurenTalentSpecializedCapability(id:'acting_coach',name:'Acting Coach',prompt:'أنشئ لي تمرين تمثيل عملي لتطوير التعبير والحضور وفهم الشخصية حسب مستواي.'),
      AurenTalentSpecializedCapability(id:'audition_prep',name:'Audition Prep',prompt:'جهزني لاختبار أداء تمثيلي عبر تحليل المشهد وقائمة تحضير وأسئلة وتمارين قبل التسجيل.'),
      AurenTalentSpecializedCapability(id:'scene_lab',name:'Scene Lab',prompt:'طوّر فكرة مشهد إلى شخصيات وصراع وبنية وحوار واتجاه إخراجي مناسب.'),
      AurenTalentSpecializedCapability(id:'showreel_builder',name:'Showreel Builder',prompt:'رتب أفضل أعمالي التمثيلية في Showreel يبرز تنوع الأداء وأقوى اللحظات.'),
      AurenTalentSpecializedCapability(id:'film_portfolio',name:'Film Portfolio',prompt:'أنشئ Portfolio سينمائي من أعمالي وأدواري واعتماداتي وأدلة أدائي بدون اختلاق معلومات.'),
      AurenTalentSpecializedCapability(id:'performance_review',name:'Performance Review',prompt:'راجع أداء تمثيلي مرفق وحدد الملاحظات الظاهرة ونقاط القوة ومجالات التحسين دون ادعاء قياسات غير متاحة.'),
    ],
    'photography': [
      AurenTalentSpecializedCapability(id:'photo_critique',name:'Photo Critique',prompt:'راجع الصورة التي أقدمها من ناحية التكوين والإضاءة والتركيز والقصة البصرية واقترح تحسينات عملية.'),
      AurenTalentSpecializedCapability(id:'photo_project',name:'Photo Project Lab',prompt:'حوّل فكرة تصوير إلى مشروع متكامل بموضوع وقائمة لقطات وأسلوب بصري وخطة تنفيذ.'),
      AurenTalentSpecializedCapability(id:'photo_story',name:'Photo Story',prompt:'رتب مجموعة صوري في قصة بصرية متماسكة مع عنوان وتسلسل ووصف.'),
      AurenTalentSpecializedCapability(id:'photo_portfolio',name:'Photo Portfolio',prompt:'ابنِ Portfolio تصوير يبرز أفضل أعمالي وتخصصي وتطوري.'),
      AurenTalentSpecializedCapability(id:'photo_challenge',name:'Photo Challenge',prompt:'أنشئ لي تحديًا تصويريًا يطور مهارة محددة وينتج سلسلة صور قابلة للعرض.'),
      AurenTalentSpecializedCapability(id:'photo_style',name:'Visual Style',prompt:'حلل نمط أعمالي التصويرية واقترح طريقة لتطوير هوية بصرية مميزة ومتسقة.'),
    ],
    'technology': [
      AurenTalentSpecializedCapability(id:'tech_project_lab',name:'Project Lab',prompt:'حوّل فكرة تقنية إلى مشروع عملي بمشكلة وحل وميزات ومراحل تنفيذ واختبار.'),
      AurenTalentSpecializedCapability(id:'tech_skill_plan',name:'Coding Skill Plan',prompt:'أنشئ خطة تطوير برمجة عملية حسب مستواي والهدف والمشاريع التي أريد بناءها.'),
      AurenTalentSpecializedCapability(id:'tech_code_review',name:'Code Review',prompt:'راجع الكود الذي أقدمه وحدد الأخطاء والمخاطر والتحسينات بشكل واضح، ولا تفترض كودًا غير موجود.'),
      AurenTalentSpecializedCapability(id:'tech_portfolio',name:'Tech Portfolio',prompt:'حوّل مشاريعي البرمجية إلى Portfolio يوضح المشكلة والحل ودوري والنتائج والتقنيات.'),
      AurenTalentSpecializedCapability(id:'tech_build_challenge',name:'Build Challenge',prompt:'أعطني تحديًا برمجيًا عمليًا يناسب مستواي ويجبرني على بناء شيء حقيقي.'),
      AurenTalentSpecializedCapability(id:'tech_showcase',name:'Project Showcase',prompt:'أنشئ صفحة عرض مختصرة لمشروع تقني تبرز القيمة والميزات والدليل على التنفيذ.'),
    ],
    'ai_innovation': [
      AurenTalentSpecializedCapability(id:'innovation_lab',name:'Innovation Lab',prompt:'طوّر فكرتي الابتكارية إلى مشكلة وحل وتجربة أولية ومؤشرات نجاح.'),
      AurenTalentSpecializedCapability(id:'ai_prototype',name:'AI Prototype',prompt:'حوّل فكرتي إلى تصور Prototype للذكاء الاصطناعي مع المدخلات والمخرجات والمخاطر.'),
      AurenTalentSpecializedCapability(id:'idea_validator',name:'Idea Validator',prompt:'اختبر فكرتي منطقيًا وحدد الفرضيات والمخاطر والتجارب التي يمكن تنفيذها قبل البناء.'),
      AurenTalentSpecializedCapability(id:'innovation_portfolio',name:'Innovation Portfolio',prompt:'رتب مشاريعي وأفكاري وتجارب النماذج الأولية في Portfolio ابتكار واضح.'),
      AurenTalentSpecializedCapability(id:'pitch_builder',name:'Innovation Pitch',prompt:'حوّل فكرتي إلى عرض Pitch مختصر يشرح المشكلة والحل والميزة والدليل والخطوة التالية.'),
      AurenTalentSpecializedCapability(id:'experiment_plan',name:'Experiment Plan',prompt:'أنشئ تجربة عملية لاختبار فرضية ابتكارية مع نتيجة متوقعة ومعيار نجاح واضح.'),
    ],
    'writing': [
      AurenTalentSpecializedCapability(id:'writing_lab',name:'Writing Lab',prompt:'طوّر نصي أو فكرتي الكتابية مع الحفاظ على صوتي وأسلوب الكتابة، وحدد التحسينات بوضوح.'),
      AurenTalentSpecializedCapability(id:'story_builder',name:'Story Builder',prompt:'حوّل فكرتي إلى قصة بشخصيات وصراع وبنية ونهاية مناسبة للنوع الذي أختاره.'),
      AurenTalentSpecializedCapability(id:'writing_review',name:'Writing Review',prompt:'راجع النص الذي أقدمه من ناحية البناء والوضوح والأسلوب والإيقاع واللغة، مع اقتراحات عملية.'),
      AurenTalentSpecializedCapability(id:'author_portfolio',name:'Writer Portfolio',prompt:'أنشئ Portfolio للكاتب من أفضل الأعمال والأنواع والإنجازات والروابط.'),
      AurenTalentSpecializedCapability(id:'writing_challenge',name:'Writing Challenge',prompt:'أنشئ لي تحديًا كتابيًا يطور مهارة محددة وينتج نصًا جديدًا قابلًا للعرض.'),
      AurenTalentSpecializedCapability(id:'publishing_prep',name:'Publishing Prep',prompt:'جهز عملي الكتابي للنشر عبر مراجعة البنية والوصف والعنوان والملف التعريفي دون اختلاق بيانات.'),
    ],
    'creator': [
      AurenTalentSpecializedCapability(id:'content_lab',name:'Content Lab',prompt:'حوّل فكرتي إلى خطة محتوى عملية تشمل الفكرة والـHook والسيناريو والتصوير والنشر.'),
      AurenTalentSpecializedCapability(id:'script_builder',name:'Script Builder',prompt:'اكتب مخطط Script لمحتوى قصير أو طويل مع Hook وتسلسل واضح وCTA مناسب.'),
      AurenTalentSpecializedCapability(id:'creator_brand',name:'Creator Brand',prompt:'ابنِ هوية Creator واضحة تشمل المجال والجمهور والرسالة ونمط المحتوى.'),
      AurenTalentSpecializedCapability(id:'content_series',name:'Series Builder',prompt:'حوّل فكرة محتوى إلى سلسلة حلقات مترابطة مع أفكار لكل حلقة.'),
      AurenTalentSpecializedCapability(id:'creator_portfolio',name:'Creator Portfolio',prompt:'رتب أفضل محتواي في Creator Portfolio يوضح التخصص وأفضل الأعمال والإنجازات.'),
      AurenTalentSpecializedCapability(id:'creator_challenge',name:'Creator Challenge',prompt:'أنشئ تحديًا لصناعة المحتوى لمدة محددة يطور مهارة ويقيس التقدم.'),
    ],
    'science_academic': [
      AurenTalentSpecializedCapability(id:'research_lab',name:'Research Lab',prompt:'حوّل فكرتي إلى سؤال بحث وفرضية ومنهجية ومخرجات قابلة للقياس مع مراعاة حدود البيانات.'),
      AurenTalentSpecializedCapability(id:'study_plan',name:'Study Plan',prompt:'أنشئ خطة دراسة عملية حسب مستواي وهدفي ووقتي مع مهام ومراجعة دورية.'),
      AurenTalentSpecializedCapability(id:'research_review',name:'Research Review',prompt:'راجع المادة العلمية التي أقدمها وحدد نقاط القوة والفجوات والأسئلة التي تحتاج مصادر أو تحقق.'),
      AurenTalentSpecializedCapability(id:'academic_portfolio',name:'Academic Portfolio',prompt:'أنشئ Academic Portfolio من المشاريع والأبحاث والإنجازات والأدلة التي أقدمها.'),
      AurenTalentSpecializedCapability(id:'science_project',name:'Science Project',prompt:'صمم لي مشروعًا علميًا عمليًا مناسبًا لمستواي مع سؤال وتجربة ونتائج متوقعة.'),
      AurenTalentSpecializedCapability(id:'research_showcase',name:'Research Showcase',prompt:'حوّل مشروعًا أو بحثًا إلى عرض مبسط يوضح المشكلة والمنهجية والنتائج والحدود.'),
    ],
    'gaming_esports': [
      AurenTalentSpecializedCapability(id:'gaming_review',name:'Gameplay Review',prompt:'راجع بيانات أو فيديو لعب أقدمه وحدد القرارات ونقاط القوة ومجالات التحسين دون ادعاء بيانات غير موجودة.'),
      AurenTalentSpecializedCapability(id:'gaming_training',name:'Training Plan',prompt:'أنشئ خطة تدريب للألعاب التنافسية حسب اللعبة ومستواي والمهارة التي أريد تطويرها.'),
      AurenTalentSpecializedCapability(id:'gaming_strategy',name:'Strategy Lab',prompt:'حلل أسلوبي في اللعبة واقترح استراتيجيات وتمارين لتحسين اتخاذ القرار.'),
      AurenTalentSpecializedCapability(id:'esports_profile',name:'Esports Profile',prompt:'أنشئ ملف Esports يوضح اللعبة والدور والإحصائيات والإنجازات والأدلة التي أقدمها.'),
      AurenTalentSpecializedCapability(id:'gaming_highlights',name:'Gaming Highlights',prompt:'رتب أفضل لحظات لعبي إلى تصور Highlight مناسب لملف Gaming Talent.'),
      AurenTalentSpecializedCapability(id:'gaming_challenge',name:'Skill Challenge',prompt:'أنشئ تحديًا تدريبيًا داخل اللعبة يطور مهارة محددة ويمكن قياس تقدمه.'),
    ],
    'fashion_beauty': [
      AurenTalentSpecializedCapability(id:'fashion_style_lab',name:'Style Lab',prompt:'طوّر أسلوبي في الموضة أو الجمال من الأعمال والصور التي أقدمها مع الحفاظ على هويتي.'),
      AurenTalentSpecializedCapability(id:'lookbook',name:'Lookbook Builder',prompt:'حوّل أعمالي وإطلالاتي إلى Lookbook منظم يوضح الأسلوب والتنوع.'),
      AurenTalentSpecializedCapability(id:'fashion_portfolio',name:'Fashion Portfolio',prompt:'أنشئ Portfolio للموضة أو الجمال يبرز أفضل الأعمال والأدوار والهوية البصرية.'),
      AurenTalentSpecializedCapability(id:'beauty_content',name:'Beauty Content Lab',prompt:'أنشئ أفكار محتوى تعليمية أو إبداعية في الجمال والموضة مناسبة لهويتي.'),
      AurenTalentSpecializedCapability(id:'style_challenge',name:'Style Challenge',prompt:'أنشئ تحديًا إبداعيًا يطور مهارة محددة في الموضة أو الجمال وينتج أعمالًا قابلة للعرض.'),
      AurenTalentSpecializedCapability(id:'fashion_showcase',name:'Style Showcase',prompt:'حوّل أفضل أعمالي إلى Showcase قصير يوضح أسلوبي وتميزي.'),
    ],
    'food': [
      AurenTalentSpecializedCapability(id:'recipe_lab',name:'Recipe Lab',prompt:'طوّر وصفتي أو فكرتي إلى وصفة واضحة مع مكونات وخطوات وبدائل مناسبة، دون افتراض معلومات غير معروفة.'),
      AurenTalentSpecializedCapability(id:'chef_profile',name:'Chef Profile',prompt:'أنشئ ملف موهبة للطهي يوضح التخصص والوصفات والأعمال والإنجازات التي أقدمها.'),
      AurenTalentSpecializedCapability(id:'food_portfolio',name:'Food Portfolio',prompt:'رتب وصفاتي وأعمالي وصور أطباقي في Food Portfolio جذاب وقابل للمشاركة.'),
      AurenTalentSpecializedCapability(id:'food_story',name:'Food Story',prompt:'حوّل وصفة أو طبقًا إلى قصة محتوى قصيرة توضّح الفكرة والمكونات وطريقة التقديم.'),
      AurenTalentSpecializedCapability(id:'cooking_challenge',name:'Cooking Challenge',prompt:'أنشئ تحديًا في الطبخ يطور مهارة محددة وينتج طبقًا جديدًا قابلًا للعرض.'),
      AurenTalentSpecializedCapability(id:'menu_creative',name:'Menu Creative Lab',prompt:'ساعدني في بناء فكرة قائمة أطباق إبداعية متماسكة حول نوع أو موضوع أختاره.'),
    ],
    'languages': [
      AurenTalentSpecializedCapability(id:'speaking_coach',name:'Speaking Coach',prompt:'أنشئ لي خطة لتحسين التحدث والوضوح والثقة في اللغة التي أحددها مع تمارين قابلة للمتابعة.'),
      AurenTalentSpecializedCapability(id:'pronunciation_lab',name:'Pronunciation Lab',prompt:'ساعدني في تدريب النطق من الكلمات أو التسجيل الذي أقدمه، وميّز بين الملاحظة والقياس الفعلي.'),
      AurenTalentSpecializedCapability(id:'writing_language',name:'Language Writing Lab',prompt:'راجع كتابتي باللغة التي أحددها وحسن القواعد والوضوح مع الحفاظ على المعنى والأسلوب.'),
      AurenTalentSpecializedCapability(id:'language_challenge',name:'Language Challenge',prompt:'أنشئ تحديًا يوميًا أو أسبوعيًا يطور مهارة محددة في اللغة مع طريقة قياس بسيطة.'),
      AurenTalentSpecializedCapability(id:'communication_portfolio',name:'Communication Portfolio',prompt:'أنشئ ملفًا يوضح اللغات ومستوياتها وأعمال الترجمة أو الكتابة أو التحدث التي أقدمها.'),
      AurenTalentSpecializedCapability(id:'presentation_coach',name:'Presentation Coach',prompt:'جهزني لتقديم عرض أو حديث عام عبر هيكل ورسالة وتمارين وأسئلة متوقعة.'),
    ],
    'leadership_impact': [
      AurenTalentSpecializedCapability(id:'leadership_lab',name:'Leadership Lab',prompt:'حلل هدفي القيادي وساعدني في تطوير مهارات التواصل واتخاذ القرار وبناء الفريق.'),
      AurenTalentSpecializedCapability(id:'impact_project',name:'Impact Project Lab',prompt:'حوّل فكرة أثر اجتماعي إلى مشروع بمشكلة وأهداف ومهام ومؤشرات أثر قابلة للمتابعة.'),
      AurenTalentSpecializedCapability(id:'impact_portfolio',name:'Impact Portfolio',prompt:'أنشئ Impact Portfolio من المشاريع والنتائج والأدوار والأدلة التي أقدمها.'),
      AurenTalentSpecializedCapability(id:'leadership_challenge',name:'Leadership Challenge',prompt:'أنشئ لي تحديًا عمليًا يطور مهارة قيادية محددة خلال فترة أختارها.'),
      AurenTalentSpecializedCapability(id:'community_story',name:'Impact Story',prompt:'حوّل مشروع أو إنجاز اجتماعي إلى قصة أثر واضحة تبرز المشكلة والفعل والنتيجة والدليل.'),
      AurenTalentSpecializedCapability(id:'team_builder',name:'Team Builder',prompt:'حدد المهارات المكملة التي أحتاجها لبناء فريق لمشروع أثر اجتماعي مع توضيح أدوار كل نوع من المواهب.'),
    ],
    'other': [
      AurenTalentSpecializedCapability(id:'other_skill_lab',name:'Skill Lab',prompt:'ساعدني في تطوير موهبتي المتخصصة عبر تقييم ما أقدمه وبناء تمارين ومهام مناسبة لمستواي.'),
      AurenTalentSpecializedCapability(id:'other_project_lab',name:'Project Lab',prompt:'حوّل مهارتي إلى مشروع عملي يمكنني تنفيذه وعرضه كدليل على الموهبة.'),
      AurenTalentSpecializedCapability(id:'other_portfolio',name:'Portfolio Builder',prompt:'أنشئ Portfolio لموهبتي من الأعمال والإنجازات والأدلة التي أقدمها.'),
      AurenTalentSpecializedCapability(id:'other_challenge',name:'Talent Challenge',prompt:'أنشئ تحديًا عمليًا يطور مهارتي ويخرج منه عمل جديد قابل للعرض.'),
      AurenTalentSpecializedCapability(id:'other_showcase',name:'Showcase Builder',prompt:'حوّل أفضل أعمالي إلى Showcase مختصر يوضح موهبتي وتميزي.'),
      AurenTalentSpecializedCapability(id:'other_growth',name:'Growth Roadmap',prompt:'أنشئ خارطة طريق لتطوير موهبتي حسب مستواي الحالي وهدفي ووقتي.'),
    ],
  };
}
