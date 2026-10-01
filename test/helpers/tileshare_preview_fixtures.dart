// Fixtures for the accept preview (redesign Step 9.10). The JSON files under
// test/fixtures/tileshare_preview are the `Content` the backend builds
// (TileSharePreview.cs / TileShareScheduleOperations.cs); API tests wrap them in
// the `{Error, Content}` envelope every Tiler endpoint answers with.
import 'dart:convert';
import 'dart:io';

/// The fixture's content as a map.
Map<String, dynamic> previewFixture(String name) => jsonDecode(
        File('test/fixtures/tileshare_preview/$name.json').readAsStringSync())
    as Map<String, dynamic>;

/// The same content as the server sends it: wrapped in `{Error, Content}`,
/// with the error code as a string ("0" = success).
String previewBody(Object? content,
        {String code = '0', String message = 'SUCCESS'}) =>
    jsonEncode({
      'Error': {'Code': code, 'Message': message},
      'Content': content,
    });

/// The 409 the server sends for a conflict: the reason is the error message.
String previewConflictBody(String reason) =>
    jsonEncode({'Error': {'Code': '2', 'Message': reason}, 'Content': null});

/// Ids the fixtures carry.
const String kPreviewAssignmentId =
    'DesignatedTileTemplate+01JGPMJJFC18Z1E2WXW9YBTTTA+01JGPMJJFCTY6288SEG6B6SEXT';
const String kPreviewToken = '0123456789abcdef0123456789abcdef';
const String kPreviewOperationId = 'fedcba9876543210fedcba9876543210';
