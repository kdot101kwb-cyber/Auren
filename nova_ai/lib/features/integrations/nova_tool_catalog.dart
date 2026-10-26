import 'package:flutter/material.dart';

/// A curated directory only. Entries are not proof of a live integration.
class NovaTool {
  const NovaTool({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.setupNote,
    required this.url,
    required this.icon,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final String setupNote;
  final String url;
  final IconData icon;
}

const novaToolCatalog = <NovaTool>[
  NovaTool(id: 1, name: 'n8n', category: 'الأتمتة والوكلاء', description: 'ربط التطبيقات عبر تدفقات عمل وwebhooks وإعادة المحاولة.', setupNote: 'مجاني عند الاستضافة الذاتية؛ الاستضافة تحتاج جهازاً أو خادماً.', url: 'https://n8n.io/', icon: Icons.account_tree_outlined),
  NovaTool(id: 2, name: 'LangGraph', category: 'الأتمتة والوكلاء', description: 'تنسيق مهام الوكيل ذات الحالة والمسارات البديلة.', setupNote: 'مكتبة برمجية؛ يلزم اختيار نموذج وتشغيل الكود.', url: 'https://www.langchain.com/langgraph', icon: Icons.route_outlined),
  NovaTool(id: 3, name: 'CrewAI', category: 'الأتمتة والوكلاء', description: 'تنظيم أدوار بحث وبرمجة ومراجعة ضمن سير عمل.', setupNote: 'تكلفة النموذج والاستضافة تعتمد على طريقة التشغيل.', url: 'https://www.crewai.com/', icon: Icons.groups_outlined),
  NovaTool(id: 4, name: 'Dify', category: 'الأتمتة والوكلاء', description: 'بناء تطبيقات AI وتدفقات وقواعد معرفة.', setupNote: 'يمكن الاستضافة الذاتية؛ مزود النموذج قد يفرض تكلفة.', url: 'https://dify.ai/', icon: Icons.hub_outlined),
  NovaTool(id: 5, name: 'Flowise', category: 'الأتمتة والوكلاء', description: 'تصميم تدفقات الذكاء الاصطناعي بصرياً.', setupNote: 'الاستضافة الذاتية أو السحابية تحتاج إعداداً.', url: 'https://flowiseai.com/', icon: Icons.schema_outlined),
  NovaTool(id: 6, name: 'OpenAI Agents SDK', category: 'الأتمتة والوكلاء', description: 'بناء وكلاء بالكود مع أدوات وتسليم مهام.', setupNote: 'استخدام API قد يحتاج رصيداً مدفوعاً؛ لا نفترض أنه مجاني.', url: 'https://openai.github.io/openai-agents-python/', icon: Icons.smart_toy_outlined),
  NovaTool(id: 7, name: 'Microsoft AutoGen', category: 'الأتمتة والوكلاء', description: 'إطار لتجارب التعاون بين عدة وكلاء.', setupNote: 'يتطلب بيئة تطوير ونموذجاً مناسباً.', url: 'https://microsoft.github.io/autogen/', icon: Icons.forum_outlined),
  NovaTool(id: 8, name: 'Model Context Protocol', category: 'الأتمتة والوكلاء', description: 'معيار موحد لتوصيل الوكلاء بالأدوات ومصادر البيانات.', setupNote: 'كل خادم MCP يحتاج إعداد صلاحيات وتحقق أمني.', url: 'https://modelcontextprotocol.io/', icon: Icons.cable_outlined),
  NovaTool(id: 9, name: 'GitHub', category: 'التطوير والاختبار', description: 'إدارة المستودعات والفروع وطلبات الدمج والمشكلات.', setupNote: 'ربط API يحتاج صلاحيات محدودة وتخزين آمن للاعتماد.', url: 'https://github.com/', icon: Icons.code),
  NovaTool(id: 10, name: 'GitHub Actions', category: 'التطوير والاختبار', description: 'تشغيل التحليل والاختبارات والبناء تلقائياً.', setupNote: 'الحصة المجانية محدودة؛ راقب دقائق التشغيل والآرتيفاكت.', url: 'https://docs.github.com/actions', icon: Icons.play_circle_outline),
  NovaTool(id: 11, name: 'Gemini CLI', category: 'التطوير والاختبار', description: 'مساعد برمجي يعمل من الطرفية.', setupNote: 'الحصص والوصول للنموذج تعتمد على الحساب والسياسة الحالية.', url: 'https://github.com/google-gemini/gemini-cli', icon: Icons.terminal),
  NovaTool(id: 12, name: 'OpenHands', category: 'التطوير والاختبار', description: 'وكيل تطوير يعمل داخل بيئة برمجية معزولة.', setupNote: 'يحتاج تشغيل بيئة آمنة ونموذجاً مناسباً.', url: 'https://openhands.dev/', icon: Icons.construction_outlined),
  NovaTool(id: 13, name: 'Aider', category: 'التطوير والاختبار', description: 'مساعد تعديل كود مرتبط بـGit.', setupNote: 'يتطلب مزود نموذج أو نموذجاً محلياً.', url: 'https://aider.chat/', icon: Icons.edit_note),
  NovaTool(id: 14, name: 'Playwright', category: 'التطوير والاختبار', description: 'اختبارات متصفح آلية لواجهات الويب والتدفقات.', setupNote: 'مفتوح المصدر؛ يجب تشغيل الاختبارات على بيئة مصرح بها.', url: 'https://playwright.dev/', icon: Icons.web),
  NovaTool(id: 15, name: 'Flutter', category: 'التطوير والاختبار', description: 'بناء تطبيق NOVA وواجهات Android متعددة المنصات.', setupNote: 'مجاني ومفتوح المصدر؛ البناء يحتاج بيئة مناسبة.', url: 'https://flutter.dev/', icon: Icons.phone_android),
  NovaTool(id: 16, name: 'Visual Studio Code', category: 'التطوير والاختبار', description: 'بيئة تطوير وإضافات وتشغيل أوامر البناء.', setupNote: 'برنامج مجاني؛ الإضافات الخارجية تخضع لشروطها.', url: 'https://code.visualstudio.com/', icon: Icons.integration_instructions_outlined),
  NovaTool(id: 17, name: 'Ollama', category: 'التطوير والاختبار', description: 'تشغيل نماذج ذكاء اصطناعي محلياً على جهاز مناسب.', setupNote: 'لا توجد رسوم API محلية، لكن الجهاز يحتاج ذاكرة وقدرة معالجة.', url: 'https://ollama.com/', icon: Icons.memory),
  NovaTool(id: 18, name: 'Context7', category: 'التطوير والاختبار', description: 'استرجاع توثيق المكتبات لمساعدة البرمجة.', setupNote: 'تحقق من حدود الاستخدام وطريقة التكامل المتاحة.', url: 'https://context7.com/', icon: Icons.menu_book_outlined),
  NovaTool(id: 19, name: 'Tavily', category: 'البحث والفرص', description: 'بحث ويب مهيأ لوكلاء الذكاء الاصطناعي.', setupNote: 'يلزم التحقق من الحصة المجانية ومفتاح API.', url: 'https://tavily.com/', icon: Icons.travel_explore),
  NovaTool(id: 20, name: 'Exa', category: 'البحث والفرص', description: 'بحث واسترجاع محتوى ويب للطلبات المتخصصة.', setupNote: 'يتطلب حساباً ومفتاحاً؛ الحصص تتغير.', url: 'https://exa.ai/', icon: Icons.search),
  NovaTool(id: 21, name: 'Firecrawl', category: 'البحث والفرص', description: 'تحويل صفحات الويب إلى محتوى منظم للتحليل.', setupNote: 'احترم robots.txt وشروط المواقع وحدود الخطة.', url: 'https://www.firecrawl.dev/', icon: Icons.travel_explore_outlined),
  NovaTool(id: 22, name: 'Google Trends', category: 'البحث والفرص', description: 'مقارنة اهتمام البحث حسب الموضوع والمنطقة والزمن.', setupNote: 'متاح للبحث اليدوي؛ API رسمي ليس مضموناً لكل استخدام.', url: 'https://trends.google.com/', icon: Icons.trending_up),
  NovaTool(id: 23, name: 'Hugging Face', category: 'البحث والفرص', description: 'اكتشاف نماذج وبيانات وأدوات مفتوحة.', setupNote: 'التشغيل المحلي ممكن؛ الاستدلال المستضاف قد يكون محدوداً أو مدفوعاً.', url: 'https://huggingface.co/', icon: Icons.psychology_outlined),
  NovaTool(id: 24, name: 'Google Alerts', category: 'البحث والفرص', description: 'تنبيهات بالكلمات المفتاحية لمتابعة فرص وأخبار.', setupNote: 'يعمل كتنبيه خارجي؛ التكامل الآلي يحتاج آلية موثوقة لجلب النتائج.', url: 'https://www.google.com/alerts', icon: Icons.notifications_active_outlined),
  NovaTool(id: 25, name: 'Reddit', category: 'البحث والفرص', description: 'رصد أسئلة الجمهور ومشكلاته وأفكار المنتجات.', setupNote: 'API والوصول الآلي يخضعان لشروط وحدود المنصة.', url: 'https://www.reddit.com/', icon: Icons.forum),
  NovaTool(id: 26, name: 'Product Hunt', category: 'البحث والفرص', description: 'متابعة المنتجات الجديدة والمنافسين.', setupNote: 'التكامل الآلي يحتاج التحقق من API وشروط الوصول.', url: 'https://www.producthunt.com/', icon: Icons.rocket_launch_outlined),
  NovaTool(id: 27, name: 'Supabase', category: 'البيانات والذاكرة', description: 'PostgreSQL ومصادقة وتخزين وواجهات API.', setupNote: 'الخطة المجانية محدودة؛ يتطلب إعداداً وصلاحيات.', url: 'https://supabase.com/', icon: Icons.storage),
  NovaTool(id: 28, name: 'PostgreSQL', category: 'البيانات والذاكرة', description: 'قاعدة بيانات علائقية لحفظ المهام والفرص وسجل التنفيذ.', setupNote: 'مفتوح المصدر؛ يحتاج استضافة ونسخاً احتياطية.', url: 'https://www.postgresql.org/', icon: Icons.table_chart_outlined),
  NovaTool(id: 29, name: 'Qdrant', category: 'البيانات والذاكرة', description: 'بحث متجهات دلالي في الوثائق والنتائج السابقة.', setupNote: 'الاستضافة الذاتية تحتاج موارد وإدارة بيانات.', url: 'https://qdrant.tech/', icon: Icons.hub_outlined),
  NovaTool(id: 30, name: 'LlamaIndex', category: 'البيانات والذاكرة', description: 'فهرسة الوثائق واسترجاع المعرفة للمساعد.', setupNote: 'مكتبة برمجية؛ تكاليف النموذج والبنية منفصلة.', url: 'https://www.llamaindex.ai/', icon: Icons.library_books_outlined),
  NovaTool(id: 31, name: 'Mem0', category: 'البيانات والذاكرة', description: 'طبقة ذاكرة لسياق المستخدم والمهام السابقة.', setupNote: 'تحتاج سياسة خصوصية واحتفاظ وحذف واضحة.', url: 'https://mem0.ai/', icon: Icons.psychology),
  NovaTool(id: 32, name: 'Langfuse', category: 'البيانات والذاكرة', description: 'تتبع طلبات النماذج والأخطاء والتكلفة والجودة.', setupNote: 'يمكن الاستضافة الذاتية؛ انتبه لعدم تسجيل الأسرار.', url: 'https://langfuse.com/', icon: Icons.monitor_heart_outlined),
  NovaTool(id: 33, name: 'Canva', category: 'المحتوى والتسويق', description: 'تصميم صور مصغرة ومنشورات وأصول تسويقية.', setupNote: 'ميزات وواجهات API محددة قد تتطلب خطة أو موافقة.', url: 'https://www.canva.com/', icon: Icons.palette_outlined),
  NovaTool(id: 34, name: 'Remotion', category: 'المحتوى والتسويق', description: 'إنشاء فيديوهات قابلة للبرمجة باستخدام React.', setupNote: 'تحقق من الترخيص وشروط الاستخدام التجاري الحالية.', url: 'https://www.remotion.dev/', icon: Icons.movie_creation_outlined),
  NovaTool(id: 35, name: 'FFmpeg', category: 'المحتوى والتسويق', description: 'قص ودمج وتحويل وضغط ملفات الفيديو والصوت.', setupNote: 'مفتوح المصدر؛ بعض الترميزات تخضع لتراخيص منفصلة.', url: 'https://ffmpeg.org/', icon: Icons.movie_outlined),
  NovaTool(id: 36, name: 'Whisper', category: 'المحتوى والتسويق', description: 'تحويل الكلام إلى نص لتفريغ الفيديو وإعداد الترجمات.', setupNote: 'يمكن تشغيله محلياً؛ الأداء يعتمد على العتاد واللغة.', url: 'https://github.com/openai/whisper', icon: Icons.subtitles_outlined),
  NovaTool(id: 37, name: 'vidIQ', category: 'المحتوى والتسويق', description: 'تحليل قناة YouTube والأفكار والكلمات المفتاحية.', setupNote: 'الخطة المجانية محدودة؛ ربط الحساب يحتاج تفويضاً.', url: 'https://vidiq.com/', icon: Icons.analytics_outlined),
  NovaTool(id: 38, name: 'Buffer', category: 'المحتوى والتسويق', description: 'إدارة وجدولة المحتوى للحسابات والمنصات المدعومة.', setupNote: 'التكامل والنشر يحتاجان حساباً وصلاحيات API متاحة.', url: 'https://buffer.com/', icon: Icons.calendar_month_outlined),
  NovaTool(id: 39, name: 'Piper TTS', category: 'المحتوى والتسويق', description: 'تحويل النص إلى صوت محلياً للأصوات المتاحة.', setupNote: 'اختبر جودة العربية والترخيص قبل الاستخدام التجاري.', url: 'https://github.com/OHF-Voice/piper1-gpl', icon: Icons.record_voice_over_outlined),
  NovaTool(id: 40, name: 'TradingView', category: 'التحليل المالي', description: 'رسوم بيانية ومراقبة أسواق وتنبيهات.', setupNote: 'بعض البيانات والميزات والربط البرمجي مدفوع أو مقيد.', url: 'https://www.tradingview.com/', icon: Icons.show_chart),
  NovaTool(id: 41, name: 'Alpha Vantage', category: 'التحليل المالي', description: 'بيانات أسهم ومؤشرات مالية عبر API.', setupNote: 'الحدود والتغطية والتأخير تختلف حسب الخطة.', url: 'https://www.alphavantage.co/', icon: Icons.show_chart),
  NovaTool(id: 42, name: 'CoinGecko', category: 'التحليل المالي', description: 'أسعار العملات المشفرة وبيانات السوق.', setupNote: 'توجد حدود طلبات وشروط خطة؛ البيانات لا تضمن الربح.', url: 'https://www.coingecko.com/', icon: Icons.currency_bitcoin),
  NovaTool(id: 43, name: 'DefiLlama', category: 'التحليل المالي', description: 'بيانات التمويل اللامركزي والسيولة والقيمة المقفلة.', setupNote: 'استخدم البيانات كمؤشرات بحث وليس كتوصية استثمارية.', url: 'https://defillama.com/', icon: Icons.account_balance_outlined),
  NovaTool(id: 44, name: 'SEC EDGAR', category: 'التحليل المالي', description: 'البحث في الإفصاحات الرسمية للشركات الأمريكية.', setupNote: 'مصدر عام؛ التزم بحدود الطلبات وسياسة الوصول.', url: 'https://www.sec.gov/edgar/search/', icon: Icons.description_outlined),
  NovaTool(id: 45, name: 'Cloudflare Workers', category: 'التشغيل والأمان', description: 'تشغيل واجهات API ومهام خفيفة في السحابة.', setupNote: 'الخطة المجانية لها حدود؛ قد يلزم إعداد حساب ونشر.', url: 'https://developers.cloudflare.com/workers/', icon: Icons.cloud_outlined),
  NovaTool(id: 46, name: 'Firebase', category: 'التشغيل والأمان', description: 'مصادقة وإشعارات وقاعدة بيانات وخدمات خلفية لتطبيق Android.', setupNote: 'بعض المنتجات تفرض حدوداً أو تتطلب فوترة عند التوسع.', url: 'https://firebase.google.com/', icon: Icons.local_fire_department_outlined),
  NovaTool(id: 47, name: 'Sentry', category: 'التشغيل والأمان', description: 'رصد أعطال التطبيق والخدمات وتشخيصها.', setupNote: 'الخطة المجانية محدودة؛ لا تسجل بيانات حساسة.', url: 'https://sentry.io/', icon: Icons.bug_report_outlined),
  NovaTool(id: 48, name: 'Dependabot', category: 'التشغيل والأمان', description: 'تنبيهات تحديث التبعيات والثغرات المعروفة.', setupNote: 'يتطلب إعداد GitHub وصيانة التحديثات المقترحة.', url: 'https://github.com/dependabot', icon: Icons.security_outlined),
  NovaTool(id: 49, name: 'OWASP ZAP', category: 'التشغيل والأمان', description: 'اختبارات أمان تطبيقات الويب المصرح بفحصها.', setupNote: 'مفتوح المصدر؛ افحص فقط الأنظمة التي تملك إذناً عليها.', url: 'https://www.zaproxy.org/', icon: Icons.shield_outlined),
  NovaTool(id: 50, name: 'Uptime Kuma', category: 'التشغيل والأمان', description: 'مراقبة توفر الخدمات وإظهار الأعطال.', setupNote: 'مفتوح المصدر؛ يحتاج جهازاً أو خادماً يعمل باستمرار.', url: 'https://github.com/louislam/uptime-kuma', icon: Icons.monitor_outlined),
];
