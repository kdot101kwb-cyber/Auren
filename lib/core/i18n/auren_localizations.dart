import 'package:flutter/material.dart';

class AurenLocalizations {
  final Locale locale;
  const AurenLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale('ar'), Locale('en'), Locale('fr'), Locale('es'), Locale('pt'),
    Locale('tr'), Locale('zh'), Locale('hi'), Locale('ur'), Locale('id'),
    Locale('sw'), Locale('ha'), Locale('de'),
  ];

  static const languageNames = <String, String>{
    'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'es': 'Español',
    'pt': 'Português', 'tr': 'Türkçe', 'zh': '中文', 'hi': 'हिन्दी',
    'ur': 'اردو', 'id': 'Bahasa Indonesia', 'sw': 'Kiswahili',
    'ha': 'Hausa', 'de': 'Deutsch',
  };

  static const LocalizationsDelegate<AurenLocalizations> delegate =
      _AurenLocalizationsDelegate();

  static AurenLocalizations of(BuildContext context) =>
      Localizations.of<AurenLocalizations>(context, AurenLocalizations)!;

  String _t(Map<String, String> values) =>
      values[locale.languageCode] ?? values['en']!;

  String get home => _t({
    'ar': 'الرئيسية', 'en': 'Home', 'fr': 'Accueil', 'es': 'Inicio',
    'pt': 'Início', 'tr': 'Ana Sayfa', 'zh': '首页', 'hi': 'होम',
    'ur': 'ہوم', 'id': 'Beranda', 'sw': 'Nyumbani', 'ha': 'Gida', 'de': 'Startseite',
  });

  String get pulse => _t({
    'ar': 'نبض', 'en': 'Pulse', 'fr': 'Pulse', 'es': 'Pulso',
    'pt': 'Pulso', 'tr': 'Akış', 'zh': '动态', 'hi': 'पल्स',
    'ur': 'پلس', 'id': 'Pulse', 'sw': 'Mtiririko', 'ha': 'Pulse', 'de': 'Pulse',
  });

  String get discover => _t({
    'ar': 'اكتشف', 'en': 'Discover', 'fr': 'Découvrir', 'es': 'Descubrir',
    'pt': 'Descobrir', 'tr': 'Keşfet', 'zh': '发现', 'hi': 'खोजें',
    'ur': 'دریافت کریں', 'id': 'Temukan', 'sw': 'Gundua', 'ha': 'Gano', 'de': 'Entdecken',
  });

  String get messenger => _t({
    'ar': 'الرسائل', 'en': 'Messenger', 'fr': 'Messages', 'es': 'Mensajes',
    'pt': 'Mensagens', 'tr': 'Mesajlar', 'zh': '消息', 'hi': 'मैसेंजर',
    'ur': 'پیغامات', 'id': 'Pesan', 'sw': 'Ujumbe', 'ha': 'Saƙonni', 'de': 'Messenger',
  });

  String get profile => _t({
    'ar': 'الملف الشخصي', 'en': 'Profile', 'fr': 'Profil', 'es': 'Perfil',
    'pt': 'Perfil', 'tr': 'Profil', 'zh': '个人资料', 'hi': 'प्रोफ़ाइल',
    'ur': 'پروفائل', 'id': 'Profil', 'sw': 'Wasifu', 'ha': 'Bayanan martaba', 'de': 'Profil',
  });

  String get incomingVideoCall => _t({
    'ar': 'مكالمة فيديو واردة', 'en': 'Incoming video call', 'fr': 'Appel vidéo entrant',
    'es': 'Videollamada entrante', 'pt': 'Chamada de vídeo recebida', 'tr': 'Gelen görüntülü arama',
    'zh': '来电视频通话', 'hi': 'आने वाली वीडियो कॉल', 'ur': 'آنے والی ویڈیو کال',
    'id': 'Panggilan video masuk', 'sw': 'Simu ya video inayoingia', 'ha': 'Kiran bidiyo mai shigowa',
    'de': 'Eingehender Videoanruf',
  });

  String get incomingAudioCall => _t({
    'ar': 'مكالمة صوتية واردة', 'en': 'Incoming audio call', 'fr': 'Appel audio entrant',
    'es': 'Llamada de audio entrante', 'pt': 'Chamada de áudio recebida', 'tr': 'Gelen sesli arama',
    'zh': '来电语音通话', 'hi': 'आने वाली ऑडियो कॉल', 'ur': 'آنے والی آڈیو کال',
    'id': 'Panggilan audio masuk', 'sw': 'Simu ya sauti inayoingia', 'ha': 'Kiran sauti mai shigowa',
    'de': 'Eingehender Audioanruf',
  });

  String get incomingRandomCall => _t({
    'ar': 'مكالمة عشوائية واردة من مستخدم AUREN',
    'en': 'Incoming random call from an AUREN user',
    'fr': 'Appel aléatoire entrant d’un utilisateur AUREN',
    'es': 'Llamada aleatoria entrante de un usuario de AUREN',
    'pt': 'Chamada aleatória recebida de um usuário AUREN',
    'tr': 'Bir AUREN kullanıcısından gelen rastgele arama',
    'zh': '来自 AUREN 用户的随机来电',
    'hi': 'AUREN उपयोगकर्ता की आने वाली रैंडम कॉल',
    'ur': 'AUREN صارف کی آنے والی رینڈم کال',
    'id': 'Panggilan acak masuk dari pengguna AUREN',
    'sw': 'Simu ya nasibu kutoka kwa mtumiaji wa AUREN',
    'ha': 'Kiran bazata daga mai amfani da AUREN',
    'de': 'Eingehender Zufallsanruf von einem AUREN-Nutzer',
  });

  String get decline => _t({
    'ar': 'رفض', 'en': 'Decline', 'fr': 'Refuser', 'es': 'Rechazar',
    'pt': 'Recusar', 'tr': 'Reddet', 'zh': '拒绝', 'hi': 'अस्वीकार',
    'ur': 'مسترد کریں', 'id': 'Tolak', 'sw': 'Kataa', 'ha': 'Ƙi', 'de': 'Ablehnen',
  });

  String get accept => _t({
    'ar': 'قبول', 'en': 'Accept', 'fr': 'Accepter', 'es': 'Aceptar',
    'pt': 'Aceitar', 'tr': 'Kabul Et', 'zh': '接受', 'hi': 'स्वीकार',
    'ur': 'قبول کریں', 'id': 'Terima', 'sw': 'Kubali', 'ha': 'Karɓa', 'de': 'Annehmen',
  });

  String get signInRequired => _t({
    'ar': 'يجب تسجيل الدخول', 'en': 'Sign in required', 'fr': 'Connexion requise',
    'es': 'Se requiere iniciar sesión', 'pt': 'É necessário iniciar sessão',
    'tr': 'Giriş yapmanız gerekiyor', 'zh': '需要登录', 'hi': 'साइन इन आवश्यक है',
    'ur': 'سائن ان ضروری ہے', 'id': 'Perlu masuk', 'sw': 'Kuingia kunahitajika',
    'ha': 'Ana buƙatar shiga', 'de': 'Anmeldung erforderlich',
  });

  String get profileLoadError => _t({
    'ar': 'تعذر تحميل الملف الشخصي.', 'en': 'Could not load profile.',
    'fr': 'Impossible de charger le profil.', 'es': 'No se pudo cargar el perfil.',
    'pt': 'Não foi possível carregar o perfil.', 'tr': 'Profil yüklenemedi.',
    'zh': '无法加载个人资料。', 'hi': 'प्रोफ़ाइल लोड नहीं हो सकी।',
    'ur': 'پروفائل لوڈ نہیں ہو سکا۔', 'id': 'Profil tidak dapat dimuat.',
    'sw': 'Wasifu haukuweza kupakiwa.', 'ha': 'An kasa loda bayanan martaba.',
    'de': 'Profil konnte nicht geladen werden.',
  });

  String get editProfile => _t({
    'ar': 'تعديل الملف الشخصي', 'en': 'Edit profile', 'fr': 'Modifier le profil',
    'es': 'Editar perfil', 'pt': 'Editar perfil', 'tr': 'Profili düzenle',
    'zh': '编辑个人资料', 'hi': 'प्रोफ़ाइल संपादित करें', 'ur': 'پروفائل میں ترمیم',
    'id': 'Edit profil', 'sw': 'Hariri wasifu', 'ha': 'Gyara bayanan martaba',
    'de': 'Profil bearbeiten',
  });

  String get aiProfile => _t({
    'ar': 'الملف الشخصي بالذكاء الاصطناعي', 'en': 'AI Profile',
    'fr': 'Profil IA', 'es': 'Perfil de IA', 'pt': 'Perfil de IA',
    'tr': 'Yapay Zekâ Profili', 'zh': 'AI 个人资料', 'hi': 'AI प्रोफ़ाइल',
    'ur': 'AI پروفائل', 'id': 'Profil AI', 'sw': 'Wasifu wa AI',
    'ha': 'Bayanan martaba na AI', 'de': 'KI-Profil',
  });

  String get profileModes => _t({
    'ar': 'شخصي • منشئ محتوى • مهني • تجاري',
    'en': 'Personal • Creator • Professional • Business',
    'fr': 'Personnel • Créateur • Professionnel • Entreprise',
    'es': 'Personal • Creador • Profesional • Negocio',
    'pt': 'Pessoal • Criador • Profissional • Negócios',
    'tr': 'Kişisel • İçerik Üreticisi • Profesyonel • İşletme',
    'zh': '个人 • 创作者 • 专业 • 商业',
    'hi': 'व्यक्तिगत • क्रिएटर • पेशेवर • व्यवसाय',
    'ur': 'ذاتی • کریئیٹر • پیشہ ور • کاروباری',
    'id': 'Pribadi • Kreator • Profesional • Bisnis',
    'sw': 'Binafsi • Mtayarishi • Kitaalamu • Biashara',
    'ha': 'Na sirri • Mahalicci • Kwararre • Kasuwanci',
    'de': 'Persönlich • Creator • Beruflich • Geschäftlich',
  });

  String get socialGraph => _t({
    'ar': 'الرسم الاجتماعي', 'en': 'Social Graph', 'fr': 'Graphe social',
    'es': 'Grafo social', 'pt': 'Grafo social', 'tr': 'Sosyal Grafik',
    'zh': '社交关系图', 'hi': 'सोशल ग्राफ', 'ur': 'سوشل گراف',
    'id': 'Graf Sosial', 'sw': 'Mchoro wa kijamii', 'ha': 'Taswirin zamantakewa',
    'de': 'Sozialer Graph',
  });

  String get socialGraphDescription => _t({
    'ar': 'المتابعون والمتابَعون والمجتمعات',
    'en': 'Followers, following and communities',
    'fr': 'Abonnés, abonnements et communautés',
    'es': 'Seguidores, seguidos y comunidades',
    'pt': 'Seguidores, seguindo e comunidades',
    'tr': 'Takipçiler, takip edilenler ve topluluklar',
    'zh': '关注者、关注对象和社区',
    'hi': 'फ़ॉलोअर, फ़ॉलोइंग और समुदाय',
    'ur': 'فالوورز، فالوونگ اور کمیونٹیز',
    'id': 'Pengikut, mengikuti, dan komunitas',
    'sw': 'Wafuasi, unaowafuata na jumuiya',
    'ha': 'Masu bi, waɗanda kake bi da al’ummomi',
    'de': 'Follower, gefolgte Konten und Communities',
  });

  String get shareProfile => _t({
    'ar': 'مشاركة ملف AUREN', 'en': 'Share my AUREN profile',
    'fr': 'Partager mon profil AUREN', 'es': 'Compartir mi perfil de AUREN',
    'pt': 'Compartilhar meu perfil AUREN', 'tr': 'AUREN profilimi paylaş',
    'zh': '分享我的 AUREN 个人资料', 'hi': 'मेरा AUREN प्रोफ़ाइल साझा करें',
    'ur': 'میرا AUREN پروفائل شیئر کریں', 'id': 'Bagikan profil AUREN saya',
    'sw': 'Shiriki wasifu wangu wa AUREN', 'ha': 'Raba bayanan martaba na AUREN',
    'de': 'Mein AUREN-Profil teilen',
  });

  String get shareProfileDescription => _t({
    'ar': 'انسخ رابط ملفك وشاركه مع الآخرين', 'en': 'Copy your profile link and share it',
    'fr': 'Copiez le lien de votre profil et partagez-le', 'es': 'Copia el enlace de tu perfil y compártelo',
    'pt': 'Copie o link do seu perfil e compartilhe', 'tr': 'Profil bağlantınızı kopyalayıp paylaşın',
    'zh': '复制个人资料链接并分享', 'hi': 'अपना प्रोफ़ाइल लिंक कॉपी करके साझा करें',
    'ur': 'اپنے پروفائل کا لنک کاپی کرکے شیئر کریں', 'id': 'Salin tautan profil dan bagikan',
    'sw': 'Nakili kiungo cha wasifu na ushiriki', 'ha': 'Kwafi hanyar bayanin martaba ka raba',
    'de': 'Profil-Link kopieren und teilen',
  });

  String get copiedProfileLink => _t({
    'ar': 'تم نسخ رابط الملف.', 'en': 'Profile link copied.', 'fr': 'Lien du profil copié.',
    'es': 'Enlace del perfil copiado.', 'pt': 'Link do perfil copiado.',
    'tr': 'Profil bağlantısı kopyalandı.', 'zh': '个人资料链接已复制。',
    'hi': 'प्रोफ़ाइल लिंक कॉपी किया गया।', 'ur': 'پروفائل لنک کاپی ہو گیا۔',
    'id': 'Tautan profil disalin.', 'sw': 'Kiungo cha wasifu kimenakiliwa.',
    'ha': 'An kwafi hanyar bayanin martaba.', 'de': 'Profil-Link kopiert.',
  });

  String get followers => _t({
    'ar': 'المتابعون', 'en': 'Followers', 'fr': 'Abonnés', 'es': 'Seguidores',
    'pt': 'Seguidores', 'tr': 'Takipçiler', 'zh': '关注者', 'hi': 'फ़ॉलोअर',
    'ur': 'فالوورز', 'id': 'Pengikut', 'sw': 'Wafuasi', 'ha': 'Masu bi', 'de': 'Follower',
  });

  String get following => _t({
    'ar': 'المتابَعون', 'en': 'Following', 'fr': 'Abonnements', 'es': 'Siguiendo',
    'pt': 'Seguindo', 'tr': 'Takip', 'zh': '正在关注', 'hi': 'फ़ॉलोइंग',
    'ur': 'فالوونگ', 'id': 'Mengikuti', 'sw': 'Unaowafuata', 'ha': 'Waɗanda kake bi',
    'de': 'Gefolgt',
  });

  String get displayName => _t({
    'ar': 'اسم العرض', 'en': 'Display name', 'fr': 'Nom affiché', 'es': 'Nombre para mostrar',
    'pt': 'Nome de exibição', 'tr': 'Görünen ad', 'zh': '显示名称', 'hi': 'प्रदर्शित नाम',
    'ur': 'ڈسپلے نام', 'id': 'Nama tampilan', 'sw': 'Jina la kuonyesha',
    'ha': 'Sunan nunawa', 'de': 'Anzeigename',
  });

  String get cancel => _t({
    'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler', 'es': 'Cancelar',
    'pt': 'Cancelar', 'tr': 'İptal', 'zh': '取消', 'hi': 'रद्द करें',
    'ur': 'منسوخ کریں', 'id': 'Batal', 'sw': 'Ghairi', 'ha': 'Soke', 'de': 'Abbrechen',
  });

  String get notifications => _t({'ar':'الإشعارات','en':'Notifications','fr':'Notifications','es':'Notificaciones','pt':'Notificações','tr':'Bildirimler','zh':'通知','hi':'सूचनाएं','ur':'اطلاعات','id':'Notifikasi','sw':'Arifa','ha':'Sanarwa','de':'Benachrichtigungen'});
  String get searchAuren => _t({'ar':'ابحث في AUREN','en':'Search AUREN','fr':'Rechercher dans AUREN','es':'Buscar en AUREN','pt':'Pesquisar no AUREN','tr':'AUREN’da ara','zh':'搜索 AUREN','hi':'AUREN खोजें','ur':'AUREN تلاش کریں','id':'Cari AUREN','sw':'Tafuta AUREN','ha':'Nemo AUREN','de':'AUREN durchsuchen'});
  String get adaptiveHome => _t({'ar':'الرئيسية المتكيفة في AUREN','en':'AUREN Adaptive Home','fr':'Accueil adaptatif AUREN','es':'Inicio adaptativo de AUREN','pt':'Início adaptativo AUREN','tr':'AUREN Uyarlanabilir Ana Sayfa','zh':'AUREN 自适应首页','hi':'AUREN अनुकूली होम','ur':'AUREN موافق ہوم','id':'Beranda Adaptif AUREN','sw':'Nyumbani inayobadilika ya AUREN','ha':'Gidan AUREN mai daidaitawa','de':'AUREN Adaptive Startseite'});
  String get adaptiveHomeSubtitle => _t({'ar':'يتكيف AUREN مع هدفك الحالي ويقترح الخطوة التالية.','en':'AUREN adapts to your current goal and suggests the next step.','fr':'AUREN s’adapte à votre objectif actuel et suggère la prochaine étape.','es':'AUREN se adapta a tu objetivo actual y sugiere el siguiente paso.','pt':'AUREN adapta-se ao seu objetivo atual e sugere o próximo passo.','tr':'AUREN mevcut hedefinize uyum sağlar ve sonraki adımı önerir.','zh':'AUREN 会根据你的当前目标建议下一步。','hi':'AUREN आपके वर्तमान लक्ष्य के अनुसार अगला कदम सुझाता है।','ur':'AUREN آپ کے موجودہ ہدف کے مطابق اگلا قدم تجویز کرتا ہے۔','id':'AUREN menyesuaikan dengan tujuan Anda dan menyarankan langkah berikutnya.','sw':'AUREN hubadilika kulingana na lengo lako na kupendekeza hatua inayofuata.','ha':'AUREN yana dacewa da burinka na yanzu kuma yana ba da shawarar mataki na gaba.','de':'AUREN passt sich deinem aktuellen Ziel an und schlägt den nächsten Schritt vor.'});
  String get adaptsToYou => _t({'ar':'AUREN يتكيف معك، وليس العكس.','en':'AUREN adapts to you, not the other way around.','fr':'AUREN s’adapte à vous, pas l’inverse.','es':'AUREN se adapta a ti, no al revés.','pt':'AUREN adapta-se a você, não o contrário.','tr':'AUREN size uyum sağlar, siz AUREN’e değil.','zh':'AUREN 适应你，而不是让你适应 AUREN。','hi':'AUREN आपके अनुसार ढलता है, आप AUREN के अनुसार नहीं।','ur':'AUREN آپ کے مطابق ڈھلتا ہے، آپ AUREN کے مطابق نہیں۔','id':'AUREN menyesuaikan diri dengan Anda, bukan sebaliknya.','sw':'AUREN hubadilika kwako, si wewe kwake.','ha':'AUREN yana dacewa da kai, ba akasin haka ba.','de':'AUREN passt sich dir an, nicht umgekehrt.'});
  String get opportunityRadar => _t({'ar':'رادار الفرص','en':'Opportunity Radar','fr':'Radar des opportunités','es':'Radar de oportunidades','pt':'Radar de oportunidades','tr':'Fırsat Radarı','zh':'机会雷达','hi':'अवसर रडार','ur':'مواقع ریڈار','id':'Radar Peluang','sw':'Rada ya Fursa','ha':'Radar na Dama','de':'Chancenradar'});
  String get peopleToConnect => _t({'ar':'أشخاص للتواصل','en':'People to Connect','fr':'Personnes à contacter','es':'Personas para conectar','pt':'Pessoas para conectar','tr':'Bağlanılacak kişiler','zh':'可联系的人','hi':'जुड़ने के लिए लोग','ur':'رابطے کے لیے لوگ','id':'Orang untuk terhubung','sw':'Watu wa kuwasiliana','ha':'Mutanen da za a haɗa','de':'Menschen zum Vernetzen'});
  String get matchEverything => _t({'ar':'طابق كل شيء','en':'Match Everything','fr':'Tout mettre en relation','es':'Conectar todo','pt':'Combinar tudo','tr':'Her şeyi eşleştir','zh':'匹配一切','hi':'सब कुछ मिलाएं','ur':'سب کچھ میچ کریں','id':'Cocokkan Semuanya','sw':'Linganisha kila kitu','ha':'Daidaita komai','de':'Alles abgleichen'});
  String get aurenAi => _t({'ar':'AUREN AI','en':'AUREN AI','fr':'AUREN AI','es':'AUREN AI','pt':'AUREN AI','tr':'AUREN AI','zh':'AUREN AI','hi':'AUREN AI','ur':'AUREN AI','id':'AUREN AI','sw':'AUREN AI','ha':'AUREN AI','de':'AUREN AI'});
  String get goalReality => _t({'ar':'الهدف → الواقع','en':'Goal → Reality','fr':'Objectif → Réalité','es':'Objetivo → Realidad','pt':'Objetivo → Realidade','tr':'Hedef → Gerçeklik','zh':'目标 → 现实','hi':'लक्ष्य → वास्तविकता','ur':'ہدف → حقیقت','id':'Tujuan → Realitas','sw':'Lengo → Uhalisia','ha':'Manufa → Gaskiya','de':'Ziel → Realität'});
  String get dailyPlan => _t({'ar':'خطة اليوم','en':'Daily Plan','fr':'Plan du jour','es':'Plan diario','pt':'Plano diário','tr':'Günlük Plan','zh':'每日计划','hi':'दैनिक योजना','ur':'روزانہ منصوبہ','id':'Rencana Harian','sw':'Mpango wa kila siku','ha':'Tsarin yau da kullum','de':'Tagesplan'});
  String get saved => _t({'ar':'المحفوظات','en':'Saved','fr':'Enregistré','es':'Guardado','pt':'Salvos','tr':'Kaydedilenler','zh':'已保存','hi':'सहेजे गए','ur':'محفوظ','id':'Tersimpan','sw':'Vilivyohifadhiwa','ha':'Abubuwan da aka ajiye','de':'Gespeichert'});
  String get actionCenter => _t({'ar':'مركز الإجراءات','en':'Action Center','fr':'Centre des actions','es':'Centro de acciones','pt':'Central de ações','tr':'Eylem Merkezi','zh':'行动中心','hi':'एक्शन सेंटर','ur':'ایکشن سینٹر','id':'Pusat Tindakan','sw':'Kituo cha Vitendo','ha':'Cibiyar Ayyuka','de':'Aktionszentrum'});
  String get safetyCenter => _t({'ar':'مركز الأمان','en':'Safety Center','fr':'Centre de sécurité','es':'Centro de seguridad','pt':'Central de segurança','tr':'Güvenlik Merkezi','zh':'安全中心','hi':'सुरक्षा केंद्र','ur':'حفاظتی مرکز','id':'Pusat Keamanan','sw':'Kituo cha Usalama','ha':'Cibiyar Tsaro','de':'Sicherheitszentrum'});
  String get aurenCore5 => _t({'ar':'AUREN Core 5','en':'AUREN Core 5','fr':'AUREN Core 5','es':'AUREN Core 5','pt':'AUREN Core 5','tr':'AUREN Core 5','zh':'AUREN Core 5','hi':'AUREN Core 5','ur':'AUREN Core 5','id':'AUREN Core 5','sw':'AUREN Core 5','ha':'AUREN Core 5','de':'AUREN Core 5'});
  String get more => _t({'ar':'المزيد','en':'More','fr':'Plus','es':'Más','pt':'Mais','tr':'Daha Fazla','zh':'更多','hi':'और','ur':'مزید','id':'Lainnya','sw':'Zaidi','ha':'Ƙari','de':'Mehr'});
  String get save => _t({
    'ar': 'حفظ', 'en': 'Save', 'fr': 'Enregistrer', 'es': 'Guardar',
    'pt': 'Salvar', 'tr': 'Kaydet', 'zh': '保存', 'hi': 'सहेजें',
    'ur': 'محفوظ کریں', 'id': 'Simpan', 'sw': 'Hifadhi', 'ha': 'Ajiye', 'de': 'Speichern',
  });
}

class _AurenLocalizationsDelegate
    extends LocalizationsDelegate<AurenLocalizations> {
  const _AurenLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AurenLocalizations.supportedLocales
      .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AurenLocalizations> load(Locale locale) async =>
      AurenLocalizations(locale);

  @override
  bool shouldReload(_AurenLocalizationsDelegate old) => false;
}
