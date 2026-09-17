import 'dart:convert';

import 'package:tiler_app/data/tilerEvent.dart';

/// Source vocabulary for multi-source calendar search. Mirrors the backend
/// `getDispatchCalendarType()` vocabulary: the request's `sources` filter and the
/// response's per-item `source` field share this lowercase vocabulary
/// (`tiler` / `google` / `microsoft`).
enum CalendarSearchSource { tiler, google, microsoft, unknown }

/// Per-source execution status (wire: `success` / `partial` / `failed`).
enum CalendarSearchStatus { success, partial, failed }

/// How a source executed the query (wire: `native-query` / `default-filter`).
enum CalendarSearchQueryMode { nativeQuery, defaultFilter, unknown }

/// Pure wire-string to enum mappers. Unknown values never throw: they collapse to
/// a safe default so one malformed field cannot sink an otherwise-good envelope.
CalendarSearchSource parseCalendarSearchSource(String? value) {
  switch (value?.toLowerCase()) {
    case 'tiler':
      return CalendarSearchSource.tiler;
    case 'google':
      return CalendarSearchSource.google;
    case 'microsoft':
      return CalendarSearchSource.microsoft;
    default:
      return CalendarSearchSource.unknown;
  }
}

CalendarSearchStatus parseCalendarSearchStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'success':
      return CalendarSearchStatus.success;
    case 'partial':
      return CalendarSearchStatus.partial;
    default:
      // `failed`, and any unknown value, degrade to the failed state: a source that
      // does not explicitly report success/partial is treated as failed.
      return CalendarSearchStatus.failed;
  }
}

CalendarSearchQueryMode parseCalendarSearchQueryMode(String? value) {
  switch (value?.toLowerCase()) {
    case 'native-query':
      return CalendarSearchQueryMode.nativeQuery;
    case 'default-filter':
      return CalendarSearchQueryMode.defaultFilter;
    default:
      return CalendarSearchQueryMode.unknown;
  }
}

/// Per-source actionable capabilities (wire: `capabilities`). Native Tiler exposes
/// all four (derived from read-only state); third-party provider rows expose
/// Edit + Delete only. A read-only row exposes none. All default to `false` so a
/// missing `capabilities` block is read-only-safe.
class CalendarSearchCapabilities {
  final bool canEdit;
  final bool canDelete;
  final bool canComplete;
  final bool canSetAsNow;

  const CalendarSearchCapabilities({
    this.canEdit = false,
    this.canDelete = false,
    this.canComplete = false,
    this.canSetAsNow = false,
  });

  factory CalendarSearchCapabilities.fromJson(Map<String, dynamic> json) {
    return CalendarSearchCapabilities(
      canEdit: json['canEdit'] == true,
      canDelete: json['canDelete'] == true,
      canComplete: json['canComplete'] == true,
      canSetAsNow: json['canSetAsNow'] == true,
    );
  }
}

/// Per-source execution status (wire: one entry in the envelope's `sources`).
/// A failed source carries `category` + `retryable`; a partial source carries
/// `category` + `retryable` + `failureCount`.
class CalendarSearchSourceStatus {
  final String source;
  final CalendarSearchStatus status;
  final CalendarSearchQueryMode queryMode;
  final String? category;
  final bool? retryable;
  final int? failureCount;

  const CalendarSearchSourceStatus({
    required this.source,
    required this.status,
    required this.queryMode,
    this.category,
    this.retryable,
    this.failureCount,
  });

  bool get isPartial => status == CalendarSearchStatus.partial;
  bool get isFailed => status == CalendarSearchStatus.failed;

  factory CalendarSearchSourceStatus.fromJson(Map<String, dynamic> json) {
    return CalendarSearchSourceStatus(
      source: json['source']?.toString() ?? '',
      status: parseCalendarSearchStatus(json['status']?.toString()),
      queryMode: parseCalendarSearchQueryMode(json['queryMode']?.toString()),
      category: json['category']?.toString(),
      retryable: json['retryable'] == null ? null : json['retryable'] == true,
      failureCount: json['failureCount'] == null
          ? null
          : (json['failureCount'] as num).toInt(),
    );
  }
}

/// One search result row (wire: one entry in the envelope's `items`). Carries the
/// Tiler-facing `EventID` (schedule-identical to the one schedule retrieval
/// produces), the provider identity fields for third-party rows, the read-only
/// flag, and the actionable [CalendarSearchCapabilities].
class CalendarSearchItem {
  /// Tiler-facing `EventID` — the value the existing `TileDetail`/edit route
  /// navigates with.
  final String id;
  final String name;

  /// Start time, Unix epoch milliseconds (UTC).
  final int start;

  /// End time, Unix epoch milliseconds (UTC).
  final int end;

  /// Raw wire source vocabulary (`tiler` / `google` / `microsoft`).
  final String source;
  final CalendarSearchSource sourceKind;

  /// Provider event id for third-party rows; null for native Tiler.
  final String? thirdPartyEventId;

  /// Connected provider account for third-party rows; null for native Tiler.
  final String? thirdPartyUserId;
  final bool isReadOnly;
  final CalendarSearchCapabilities capabilities;

  const CalendarSearchItem({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.source,
    required this.sourceKind,
    required this.isReadOnly,
    required this.capabilities,
    this.thirdPartyEventId,
    this.thirdPartyUserId,
  });

  bool get isFromTiler => sourceKind == CalendarSearchSource.tiler;
  bool get isFromProvider =>
      sourceKind == CalendarSearchSource.google ||
      sourceKind == CalendarSearchSource.microsoft;

  factory CalendarSearchItem.fromJson(Map<String, dynamic> json) {
    final source = json['source']?.toString() ?? '';
    return CalendarSearchItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      source: source,
      sourceKind: parseCalendarSearchSource(source),
      thirdPartyEventId: json['thirdPartyEventId']?.toString(),
      thirdPartyUserId: json['thirdPartyUserId']?.toString(),
      isReadOnly: json['isReadOnly'] == true,
      capabilities: json['capabilities'] is Map<String, dynamic>
          ? CalendarSearchCapabilities.fromJson(
              json['capabilities'] as Map<String, dynamic>)
          : const CalendarSearchCapabilities(),
    );
  }

  /// Maps this search row to the app's [TilerEvent] so the existing edit/detail
  /// route (`TileDetail(tileId: ...)`) and identity helpers work unchanged. The
  /// wire uses `microsoft` for Microsoft while the app's [TileSource] enum uses
  /// `outlook`; the two are reconciled here.
  TilerEvent toTilerEvent() {
    final event = TilerEvent(name: name, start: start, end: end, id: id);
    event.thirdpartyType = _tileSourceFor(sourceKind);
    final String? providerId = thirdPartyEventId;
    if (providerId != null && providerId.isNotEmpty) {
      event.thirdpartyId = providerId;
    }
    final String? providerUser = thirdPartyUserId;
    if (providerUser != null && providerUser.isNotEmpty) {
      event.thirdPartyUserId = providerUser;
    }
    return event;
  }

  TileSource? _tileSourceFor(CalendarSearchSource kind) {
    switch (kind) {
      case CalendarSearchSource.tiler:
        return TileSource.tiler;
      case CalendarSearchSource.google:
        return TileSource.google;
      case CalendarSearchSource.microsoft:
        return TileSource.outlook;
      case CalendarSearchSource.unknown:
        return null;
    }
  }
}

/// Response envelope for `GET api/CalendarEvent/Search` (wire: the PostBack
/// `Content`). NOT paginated: a per-source cap (50) + a merged cap (150) with
/// silent truncation.
class CalendarSearchEnvelope {
  final List<CalendarSearchItem> items;
  final List<CalendarSearchSourceStatus> sources;
  final String correlationId;

  const CalendarSearchEnvelope({
    required this.items,
    required this.sources,
    required this.correlationId,
  });

  /// True when at least one source reported `partial` or `failed` — the UI
  /// surfaces a non-blocking warning + retry for those sources (the surviving
  /// `items` are still shown).
  bool get hasPartialFailure =>
      sources.any((s) => s.isPartial || s.isFailed);

  factory CalendarSearchEnvelope.fromJson(Map<String, dynamic> json) {
    return CalendarSearchEnvelope(
      items: (json['items'] as List? ?? const [])
          .map((e) => CalendarSearchItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sources: (json['sources'] as List? ?? const [])
          .map((e) =>
              CalendarSearchSourceStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      correlationId: json['correlationId']?.toString() ?? '',
    );
  }
}

/// One failed third-party provider from the typed 502 total-failure error.
class CalendarSearchFailedSource {
  final String provider;
  final String? email;
  final String? category;

  const CalendarSearchFailedSource({
    required this.provider,
    this.email,
    this.category,
  });

  factory CalendarSearchFailedSource.fromJson(Map<String, dynamic> json) {
    return CalendarSearchFailedSource(
      provider: json['provider']?.toString() ?? '',
      email: json['email']?.toString(),
      category: json['category']?.toString(),
    );
  }
}

/// Typed error body for a TOTAL search source failure (HTTP 502, code
/// `search_unavailable`). Deliberately distinct from an empty "no matches"
/// envelope: a 502 is a real failure, never a successful empty result.
class CalendarSearchUnavailableError {
  static const String codeSearchUnavailable = 'search_unavailable';

  final String code;
  final String? message;
  final String? category;
  final String? correlationId;
  final List<CalendarSearchFailedSource> sources;

  const CalendarSearchUnavailableError({
    this.code = codeSearchUnavailable,
    this.message,
    this.category,
    this.correlationId,
    this.sources = const [],
  });

  factory CalendarSearchUnavailableError.fromJson(Map<String, dynamic> json) {
    return CalendarSearchUnavailableError(
      code: json['error']?.toString() ?? codeSearchUnavailable,
      message: json['message']?.toString(),
      category: json['category']?.toString(),
      correlationId: json['correlationId']?.toString(),
      sources: (json['sources'] as List? ?? const [])
          .map((e) =>
              CalendarSearchFailedSource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The four distinct outcomes of a multi-source search request. Discriminating
/// them keeps a flag-off 404 (fall back to legacy) and a 502 (typed error) from
/// being mistaken for a successful empty result or a generic failure.
enum CalendarSearchResultKind { success, flagOff, unavailable, error }

class CalendarSearchResult {
  final CalendarSearchResultKind kind;
  final CalendarSearchEnvelope? envelope;
  final CalendarSearchUnavailableError? unavailable;
  final String? errorMessage;

  const CalendarSearchResult._({
    required this.kind,
    this.envelope,
    this.unavailable,
    this.errorMessage,
  });

  factory CalendarSearchResult.success(CalendarSearchEnvelope envelope) =>
      CalendarSearchResult._(
          kind: CalendarSearchResultKind.success, envelope: envelope);

  factory CalendarSearchResult.flagOff() =>
      const CalendarSearchResult._(kind: CalendarSearchResultKind.flagOff);

  factory CalendarSearchResult.unavailable(
          CalendarSearchUnavailableError error) =>
      CalendarSearchResult._(
          kind: CalendarSearchResultKind.unavailable, unavailable: error);

  factory CalendarSearchResult.error(String message) =>
      CalendarSearchResult._(
          kind: CalendarSearchResultKind.error, errorMessage: message);

  bool get isSuccess => kind == CalendarSearchResultKind.success;
  bool get isFlagOff => kind == CalendarSearchResultKind.flagOff;
  bool get isUnavailable => kind == CalendarSearchResultKind.unavailable;
  bool get isError => kind == CalendarSearchResultKind.error;
}

/// Builds the query-parameter map for `api/CalendarEvent/Search`. Mirrors the
/// backend binding: `query` (required) + optional `sources` (comma-joined).
/// `sources` is omitted when null/empty so the server defaults to all sources.
/// Pure + framework-free so it is unit-testable without the network.
Map<String, dynamic> buildCalendarSearchQueryParameters(
  String query, {
  List<String>? sources,
}) {
  final Map<String, dynamic> params = {'query': query};
  if (sources != null && sources.isNotEmpty) {
    params['sources'] = sources.join(',');
  }
  return params;
}

/// Interprets a raw (HTTP status, body) pair from `api/CalendarEvent/Search`
/// into a [CalendarSearchResult]. Pure + framework-free so it is unit-testable
/// without the network:
/// - 200 + PostBack `{Error:{Code:'0'}, Content:{items, sources, correlationId}}`
///   -> success envelope (an empty `items` list is a legitimate "no matches").
/// - 404 (plain) -> flagOff (feature flag off for this user -> legacy fallback).
/// - 502 -> typed [CalendarSearchUnavailableError] (total source failure).
/// - 400 / anything else -> error.
CalendarSearchResult parseCalendarSearchResponse(int statusCode, String body) {
  switch (statusCode) {
    case 200:
      return _parseEnvelope(body);
    case 404:
      return CalendarSearchResult.flagOff();
    case 502:
      return _parseUnavailable(body);
    default:
      return CalendarSearchResult.error('Search failed (HTTP $statusCode)');
  }
}

/// Parses the 200 PostBack wrapper into a success envelope. Matches
/// `AppApi.isJsonResponseOk`/`isContentInResponse`: success is
/// `Error.Code == '0'` with a non-null `Content` (the envelope object).
CalendarSearchResult _parseEnvelope(String body) {
  try {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final dynamic error = decoded['Error'];
      if (error is Map) {
        final dynamic code = error['Code'];
        if (code?.toString() == '0') {
          final dynamic content = decoded['Content'];
          if (content is Map<String, dynamic>) {
            return CalendarSearchResult.success(
              CalendarSearchEnvelope.fromJson(content),
            );
          }
        } else if (code != null) {
          // A non-zero Error code on a 200 is a request error.
          final dynamic message = error['Message'];
          return CalendarSearchResult.error(
              message?.toString() ?? 'Search request error');
        }
      }
    }
  } catch (_) {
    // fall through to a generic error below.
  }
  return CalendarSearchResult.error('Unexpected search response');
}

/// Parses the typed 502 total-failure body into a [CalendarSearchUnavailableError].
/// A missing/malformed body still yields the typed error (never an empty result).
CalendarSearchResult _parseUnavailable(String body) {
  try {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return CalendarSearchResult.unavailable(
        CalendarSearchUnavailableError.fromJson(decoded),
      );
    }
  } catch (_) {
    // fall through to a minimal typed error below.
  }
  return CalendarSearchResult.unavailable(
    const CalendarSearchUnavailableError(),
  );
}