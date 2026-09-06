// A real [AppLocalizations] instance for tests that call label helpers
// directly.
//
// The Add Tile label helpers take an [AppLocalizations] parameter instead of
// reading a `BuildContext` (D29), which is exactly what lets them be unit
// tested without pumping a widget — but they still need a real instance. The
// generated English delegate is constructible on its own, so tests assert
// against the SHIPPED English strings rather than a hand-written stub that
// could drift from `app_en.arb`.
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/l10n/app_localizations_en.dart';

final AppLocalizations testL10n = AppLocalizationsEn();
