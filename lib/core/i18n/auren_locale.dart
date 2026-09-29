import 'package:flutter/material.dart';

/// AUREN's country-aware language and terminology foundation.
///
/// Locale follows the user's device by default. A country-specific locale can
/// be supplied later when the profile/country service knows the user's country.
/// Keep product terminology separate from translations so AUREN can use natural
/// local words such as "جوال" in Sudan rather than forcing one Arabic variant.
class AurenLocale {
  final Locale locale;
  final String countryCode;

  const AurenLocale({
    required this.locale,
    this.countryCode = '',
  });

  String get languageCode => locale.languageCode;
  String get normalizedCountry =>
      (countryCode.isEmpty ? (locale.countryCode ?? '') : countryCode).toUpperCase();

  bool get isRtl => const {'ar', 'fa', 'ur', 'he'}.contains(languageCode);

  String term(String key) {
    final country = normalizedCountry;
    final language = languageCode;

    final countryTerms = _termsByCountry[country];
    final languageTerms = _termsByLanguage[language];

    return countryTerms?[key] ?? languageTerms?[key] ?? _fallbackTerms[key] ?? key;
  }

  static const _fallbackTerms = <String, String>{
    'phone': 'Phone',
    'mobile_phone': 'Mobile phone',
    'mobile': 'Mobile',
    'home': 'Home',
    'search': 'Search',
    'settings': 'Settings',
    'profile': 'Profile',
    'message': 'Message',
    'messages': 'Messages',
    'country': 'Country',
    'language': 'Language',
  };

  static const _termsByLanguage = <String, Map<String, String>>{
    'ar': {
      'phone': 'هاتف',
      'mobile_phone': 'هاتف محمول',
      'mobile': 'محمول',
      'home': 'الرئيسية',
      'search': 'بحث',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'message': 'رسالة',
      'messages': 'الرسائل',
      'country': 'الدولة',
      'language': 'اللغة',
    },
    'en': {
      'phone': 'Phone',
      'mobile_phone': 'Mobile phone',
      'mobile': 'Mobile',
      'home': 'Home',
      'search': 'Search',
      'settings': 'Settings',
      'profile': 'Profile',
      'message': 'Message',
      'messages': 'Messages',
      'country': 'Country',
      'language': 'Language',
    },
    'fr': {
      'phone': 'Téléphone',
      'mobile_phone': 'Téléphone portable',
      'mobile': 'Mobile',
      'home': 'Accueil',
      'search': 'Rechercher',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'message': 'Message',
      'messages': 'Messages',
      'country': 'Pays',
      'language': 'Langue',
    },
    'es': {
      'phone': 'Teléfono',
      'mobile_phone': 'Teléfono móvil',
      'mobile': 'Móvil',
      'home': 'Inicio',
      'search': 'Buscar',
      'settings': 'Configuración',
      'profile': 'Perfil',
      'message': 'Mensaje',
      'messages': 'Mensajes',
      'country': 'País',
      'language': 'Idioma',
    },
    'pt': {
      'phone': 'Telefone',
      'mobile_phone': 'Telemóvel',
      'mobile': 'Móvel',
      'home': 'Início',
      'search': 'Pesquisar',
      'settings': 'Definições',
      'profile': 'Perfil',
      'message': 'Mensagem',
      'messages': 'Mensagens',
      'country': 'País',
      'language': 'Idioma',
    },
    'sw': {
      'phone': 'Simu',
      'mobile_phone': 'Simu ya mkononi',
      'mobile': 'Mkononi',
      'home': 'Mwanzo',
      'search': 'Tafuta',
      'settings': 'Mipangilio',
      'profile': 'Wasifu',
      'message': 'Ujumbe',
      'messages': 'Ujumbe',
      'country': 'Nchi',
      'language': 'Lugha',
    },
    'tr': {
      'phone': 'Telefon',
      'mobile_phone': 'Cep telefonu',
      'mobile': 'Cep',
      'home': 'Ana sayfa',
      'search': 'Ara',
      'settings': 'Ayarlar',
      'profile': 'Profil',
      'message': 'Mesaj',
      'messages': 'Mesajlar',
      'country': 'Ülke',
      'language': 'Dil',
    },
  };

  static const _termsByCountry = <String, Map<String, String>>{
    // Sudanese Arabic product vocabulary.
    'SD': {
      'phone': 'هاتف',
      'mobile_phone': 'جوال',
      'mobile': 'جوال',
      'home': 'الرئيسية',
      'search': 'بحث',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'message': 'رسالة',
      'messages': 'الرسائل',
      'country': 'الدولة',
      'language': 'اللغة',
    },
    // Keep country overrides explicit so local terminology can evolve
    // independently from the base language translation.
    'SA': {
      'mobile_phone': 'جوال',
      'mobile': 'جوال',
    },
    'AE': {
      'mobile_phone': 'هاتف محمول',
      'mobile': 'محمول',
    },
    'EG': {
      'mobile_phone': 'موبايل',
      'mobile': 'موبايل',
    },
    'MA': {
      'mobile_phone': 'هاتف محمول',
      'mobile': 'محمول',
    },
  };

  static Locale localeFromPlatform(Locale platformLocale) {
    final supported = _supportedLanguages.contains(platformLocale.languageCode);
    return supported ? platformLocale : const Locale('en');
  }

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('es'),
    Locale('pt'),
    Locale('sw'),
    Locale('tr'),
  ];

  static const _supportedLanguages = {
    'en', 'ar', 'fr', 'es', 'pt', 'sw', 'tr',
  };
}

/// Small, dependency-free localization helper for the first AUREN shell.
///
/// Full feature screens can migrate to this service incrementally without
/// changing the underlying country/language selection logic.
AurenLocale aurenLocaleOf(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return AurenLocale(locale: locale, countryCode: locale.countryCode ?? '');
}
