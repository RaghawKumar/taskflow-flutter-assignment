import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  static const supportedLocales = [Locale('en'), Locale('hi')];
  static const LocalizationsDelegate<AppLocalizations> delegate = _Delegate();
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const _values = <String, Map<String, String>>{
    'en': {
      'app': 'TaskFlow',
      'home': 'Home',
      'dashboard': 'Dashboard',
      'projects': 'Projects',
      'tasks': 'Tasks',
      'settings': 'Settings',
      'members': 'Members',
      'completed': 'Completed',
      'upcoming': 'Upcoming tasks',
      'login': 'Sign in',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'profileSettings': 'Profile & Settings',
      'darkMode': 'Dark mode',
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'offline': 'Offline • cached data may be stale',
      'retry': 'Retry',
      'loading': 'Loading content',
      'logout': 'Log out',
      'filterTasks': 'Filter tasks',
    },
    'hi': {
      'app': 'टास्कफ्लो',
      'home': 'होम',
      'dashboard': 'डैशबोर्ड',
      'projects': 'प्रोजेक्ट',
      'tasks': 'कार्य',
      'settings': 'सेटिंग्स',
      'members': 'सदस्य',
      'completed': 'पूर्ण',
      'upcoming': 'आगामी कार्य',
      'login': 'साइन इन करें',
      'register': 'रजिस्टर',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'profileSettings': 'प्रोफ़ाइल और सेटिंग्स',
      'darkMode': 'डार्क मोड',
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिन्दी',
      'offline': 'ऑफ़लाइन • कैश किया गया डेटा पुराना हो सकता है',
      'retry': 'पुनः प्रयास',
      'loading': 'सामग्री लोड हो रही है',
      'logout': 'लॉग आउट',
      'filterTasks': 'कार्य फ़िल्टर करें',
    },
  };
  String text(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(_Delegate old) => false;
}

extension LocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
