import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Keeps an actionable server explanation while replacing generic errors.
/// Exception strings may contain technical/request details and are not shown.
String operationFailureMessage(AppLocalizations l10n,
    {required String fallback, Object? error}) {
  final message = error is TilerError ? error.Message?.trim() : null;
  if (message == null ||
      message.isEmpty ||
      message == l10n.errorOccurred.trim() ||
      message == l10n.responseHandlingError.trim() ||
      message == l10n.responseContentError.trim() ||
      message == l10n.failedToSendRequest.trim() ||
      const {
        'unknown error',
        'unknown error.',
        'something went wrong',
        'something went wrong.',
        'could not do that right now.',
      }.contains(message.toLowerCase())) {
    return fallback;
  }
  return '$fallback\n$message';
}
