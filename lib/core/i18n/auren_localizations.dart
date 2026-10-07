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
