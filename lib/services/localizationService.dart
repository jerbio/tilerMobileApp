
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalizationService {
  final AppLocalizations localizations;

  LocalizationService(this.localizations);

  String get errorOccurred => localizations.errorOccurred;
  String get authenticationIssues => localizations.authenticationIssues;
  String get userIsNotAuthenticated => localizations.userIsNotAuthenticated;
  String get responseContentError => localizations.responseContentError;
  String get responseHandlingError => localizations.responseHandlingError;

}