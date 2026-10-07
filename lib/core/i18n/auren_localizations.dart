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

  bool get isArabic => locale.languageCode == 'ar';
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get pulse => isArabic ? 'نبض' : 'Pulse';
  String get discover => isArabic ? 'اكتشف' : 'Discover';
  String get messenger => isArabic ? 'الرسائل' : 'Messenger';
  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  String get incomingVideoCall => isArabic ? 'مكالمة فيديو واردة' : 'Incoming video call';
  String get incomingAudioCall => isArabic ? 'مكالمة صوتية واردة' : 'Incoming audio call';
  String get incomingRandomCall => isArabic
      ? 'مكالمة عشوائية واردة من مستخدم AUREN'
      : 'Incoming random call from an AUREN user';
  String get decline => isArabic ? 'رفض' : 'Decline';
  String get accept => isArabic ? 'قبول' : 'Accept';
  String get signInRequired => isArabic ? 'يجب تسجيل الدخول' : 'Sign in required';
  String get profileLoadError => isArabic ? 'تعذر تحميل الملف الشخصي.' : 'Could not load profile.';
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit profile';
  String get aiProfile => isArabic ? 'الملف الشخصي بالذكاء الاصطناعي' : 'AI Profile';
  String get profileModes => isArabic ? 'شخصي • منشئ محتوى • مهني • تجاري' : 'Personal • Creator • Professional • Business';
  String get socialGraph => isArabic ? 'الرسم الاجتماعي' : 'Social Graph';
  String get socialGraphDescription => isArabic ? 'المتابعون والمتابَعون والمجتمعات' : 'Followers, following and communities';
  String get shareProfile => isArabic ? 'مشاركة ملف AUREN' : 'Share my AUREN profile';
  String get shareProfileDescription => isArabic ? 'انسخ رابط ملفك وشاركه مع الآخرين' : 'Copy your profile link and share it';
  String get copiedProfileLink => isArabic ? 'تم نسخ رابط الملف.' : 'Profile link copied.';
  String get followers => isArabic ? 'المتابعون' : 'Followers';
  String get following => isArabic ? 'المتابَعون' : 'Following';
  String get displayName => isArabic ? 'اسم العرض' : 'Display name';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
}

class _AurenLocalizationsDelegate
    extends LocalizationsDelegate<AurenLocalizations> {
  const _AurenLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => AurenLocalizations.supportedLocales
      .any((supported) => supported.languageCode == locale.languageCode);
  @override
  Future<AurenLocalizations> load(Locale locale) async => AurenLocalizations(locale);
  @override
  bool shouldReload(_AurenLocalizationsDelegate old) => false;
}
