import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/services/api/notesApi.dart';

/// Fake [NotesApi] that records calls and returns scripted payloads without
/// touching the network. Constructed with a no-op context callback; the
/// overridden methods never invoke `super`, so the inherited HTTP client and
/// authentication helpers are never exercised.
class _FakeNotesApi extends NotesApi {
  _FakeNotesApi({
    NotesPayload? initialPayload,
    bool conflictOnFirstSave = false,
    Exception? failGetWith,
    Exception? failPutWith,
  })  : _initialPayload = initialPayload ??
            NotesPayload(
              eventId: 'event-1',
              userNote: 'hello from server',
              etag: 'etag-1',
            ),
        _conflictOnFirstSave = conflictOnFirstSave,
        _failGetWith = failGetWith,
        _failPutWith = failPutWith,
        super(getContextCallBack: (() => null));

  NotesPayload _initialPayload;
  final bool _conflictOnFirstSave;
  final Exception? _failGetWith;
  final Exception? _failPutWith;

  int getCalls = 0;
  int putCalls = 0;
  final List<String> putBodies = <String>[];
  final List<String> putEtags = <String>[];

  @override
  Future<NotesPayload> getNotes(
    String eventId, {
    NotesScope scope = NotesScope.auto,
  }) async {
    getCalls += 1;
    if (_failGetWith != null) throw _failGetWith!;
    return _initialPayload;
  }

  @override
  Future<NotesPayload> updateNotes({
    required String eventId,
    required String userNote,
    required String etag,
    NotesScope scope = NotesScope.auto,
  }) async {
    putCalls += 1;
    putBodies.add(userNote);
    putEtags.add(etag);
    if (_failPutWith != null) throw _failPutWith!;
    if (_conflictOnFirstSave && putCalls == 1) {
      return NotesPayload(
        eventId: eventId,
        userNote: 'server moved on',
        etag: 'etag-2',
        concurrencyConflict: true,
      );
    }
    final next = NotesPayload(
      eventId: eventId,
      userNote: userNote,
      etag: 'etag-${putCalls + 1}',
    );
    _initialPayload = next;
    return next;
  }
}

Widget _harness(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditTileNote auto-save lifecycle', () {
    testWidgets(
      'GETs the server payload on mount and surfaces the loaded text',
      (tester) async {
        final api = _FakeNotesApi(
          initialPayload: NotesPayload(
            eventId: 'event-1',
            userNote: 'hello from server',
            etag: 'etag-1',
          ),
        );
        final status = ValueNotifier<NotesSaveStatus>(NotesSaveStatus.idle);
        addTearDown(status.dispose);

        await tester.pumpWidget(_harness(EditTileNote(
          eventId: 'event-1',
          notesApi: api,
          statusNotifier: status,
          autoSaveDelay: const Duration(milliseconds: 50),
        )));
        await tester.pumpAndSettle();

        expect(api.getCalls, 1);
        // Loaded server text is shown (preview mode renders it via markdown).
        expect(find.text('hello from server'), findsOneWidget);
        expect(status.value, NotesSaveStatus.idle);
      },
    );

    testWidgets(
      'skipInitialLoad primes the etag in the background so the first save '
      'carries a valid etag (no concurrency conflict)',
      (tester) async {
        final api = _FakeNotesApi(
          initialPayload: NotesPayload(
            eventId: 'event-1',
            userNote: 'pre-hydrated',
            etag: 'etag-primed',
          ),
        );
        final status = ValueNotifier<NotesSaveStatus>(NotesSaveStatus.idle);
        addTearDown(status.dispose);
        final controller = EditTileNoteController();

        await tester.pumpWidget(_harness(EditTileNote(
          eventId: 'event-1',
          tileNote: 'pre-hydrated',
          notesApi: api,
          controller: controller,
          statusNotifier: status,
          skipInitialLoad: true,
          autoSaveDelay: const Duration(milliseconds: 50),
        )));
        // Let the priming GET resolve.
        await tester.pumpAndSettle();

        expect(api.getCalls, 1, reason: 'background etag prime');
        expect(api.putCalls, 0);

        // Drop into edit mode (preview is on because tileNote is non-empty).
        await tester.tap(find.text('pre-hydrated'));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField), 'pre-hydrated + edit');
        // Force the debounce to fire.
        await tester.pump(const Duration(milliseconds: 75));
        await controller.save();
        await tester.pumpAndSettle();

        expect(api.putCalls, 1);
        expect(api.putBodies.single, 'pre-hydrated + edit');
        expect(api.putEtags.single, 'etag-primed',
            reason: 'must use the primed etag, not an empty string');
        expect(status.value, NotesSaveStatus.saved);
      },
    );

    testWidgets(
      'typing flips status to dirty then saving then saved after debounce',
      (tester) async {
        final api = _FakeNotesApi(
          initialPayload: NotesPayload(
            eventId: 'event-1',
            userNote: '',
            etag: 'etag-1',
          ),
        );
        final status = ValueNotifier<NotesSaveStatus>(NotesSaveStatus.idle);
        addTearDown(status.dispose);

        await tester.pumpWidget(_harness(EditTileNote(
          eventId: 'event-1',
          notesApi: api,
          statusNotifier: status,
          autoSaveDelay: const Duration(milliseconds: 50),
        )));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'first draft');
        await tester.pump(); // emit dirty
        expect(status.value, NotesSaveStatus.dirty);

        // Advance past the debounce so _flushSave runs.
        await tester.pump(const Duration(milliseconds: 75));
        await tester.pumpAndSettle();

        expect(api.putCalls, 1);
        expect(api.putBodies.single, 'first draft');
        expect(api.putEtags.single, 'etag-1');
        expect(status.value, NotesSaveStatus.saved);
      },
    );

    testWidgets(
      'controller.save() flushes immediately, bypassing the debounce',
      (tester) async {
        final api = _FakeNotesApi();
        final controller = EditTileNoteController();

        await tester.pumpWidget(_harness(EditTileNote(
          eventId: 'event-1',
          notesApi: api,
          controller: controller,
          autoSaveDelay: const Duration(seconds: 30),
        )));
        await tester.pumpAndSettle();

        // Switch to edit mode (server returned non-empty text → preview on).
        await tester.tap(find.text('hello from server'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'flushed text');
        await tester.pump();

        // No debounce elapsed, yet save() should still fire.
        final persisted = await controller.save();
        await tester.pumpAndSettle();

        expect(api.putCalls, 1);
        expect(api.putBodies.single, 'flushed text');
        expect(persisted, 'flushed text');
        expect(controller.hasUnsavedChanges, isFalse);
      },
    );

    testWidgets(
      'controller.discard() cancels the pending autosave and reverts the '
      'editor to the last persisted text',
      (tester) async {
        final api = _FakeNotesApi();
        final controller = EditTileNoteController();

        await tester.pumpWidget(_harness(EditTileNote(
          eventId: 'event-1',
          notesApi: api,
          controller: controller,
          autoSaveDelay: const Duration(milliseconds: 50),
        )));
        await tester.pumpAndSettle();

        await tester.tap(find.text('hello from server'));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField), 'hello from server + WIP');
        await tester.pump();
        expect(controller.hasUnsavedChanges, isTrue);

        controller.discard();
        await tester.pump();

        expect(controller.hasUnsavedChanges, isFalse);
        expect(controller.currentText, 'hello from server');

        // Wait well past the debounce — no save should fire.
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(api.putCalls, 0,
            reason: 'discard must cancel the queued autosave');
      },
    );

    testWidgets(
      'concurrency conflict from the server flips status to error and keeps '
      'the user\'s draft in the editor',
      (tester) async {
        final api = _FakeNotesApi(conflictOnFirstSave: true);
        final status = ValueNotifier<NotesSaveStatus>(NotesSaveStatus.idle);
        addTearDown(status.dispose);

        await tester.pumpWidget(_harness(EditTileNote(
          eventId: 'event-1',
          notesApi: api,
          statusNotifier: status,
          autoSaveDelay: const Duration(milliseconds: 50),
        )));
        await tester.pumpAndSettle();

        await tester.tap(find.text('hello from server'));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField), 'my local draft');
        await tester.pump(const Duration(milliseconds: 75));
        await tester.pumpAndSettle();

        expect(api.putCalls, 1);
        expect(status.value, NotesSaveStatus.error);
        // Local draft must NOT have been clobbered by the server's text.
        expect(find.text('my local draft'), findsOneWidget);
      },
    );
  });
}
