import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class LocalizationService {
  static LocalizationService? _instance;

  LocalizationService._internal();

  // Singleton getter
  static LocalizationService get instance {
    _instance ??= LocalizationService._internal();
    return _instance!;
  }

  AppLocalizations get translations {
    return lookupAppLocalizations(Locale('en'));
  }

  AppLocalizations getTranslationsForLocale(Locale locale) {
    return lookupAppLocalizations(locale);
  }

  String translate(String Function(AppLocalizations) translator) {
    return translator(translations);
  }
}
