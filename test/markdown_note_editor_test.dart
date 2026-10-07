// TileShare redesign Step 9.16c (T27): one markdown note editor for every
// note in the app. The tile notes editor's core - markdown in and out, the
// Quill editor, its toolbar, Edit / Preview - is shared without any saving of
// its own: tile notes keep their auto-save on top of it, and a form (a
// share's description, a task's notes) edits a draft on the same full-screen
// notes page and gets the markdown back. A length limit stops typing at the
// limit and shows a counter near it. One read-only view shows notes.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/services/api/notesApi.dart';

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: home,
    );

/// Replaces the editor's text the way a keystroke does (see
/// edit_tile_notes_test.dart for why the keyboard helpers are avoided).
Future<void> _type(WidgetTester tester, String text) async {
  final QuillController c =
      tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;
  c.replaceText(0, c.document.length - 1, text,
      TextSelection.collapsed(offset: text.length));
  await tester.pump();
}

String _editorText(WidgetTester tester) => tester
    .widget<QuillEditor>(find.byType(QuillEditor))
    .controller
    .document
    .toPlainText()
    .trimRight();

class _NoNotesApi extends NotesApi {
  _NoNotesApi() : super(getContextCallBack: () => null);

  @override
  Future<NotesPayload> getNotes(String eventId,
          {NotesScope scope = NotesScope.auto}) async =>
      NotesPayload(eventId: eventId, userNote: '', etag: 'e');
}

/// Lets the editor's timers run out, then unmounts it.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('MarkdownNoteEditor', () {
    testWidgets(
        'opens on the rendered note; a tap edits; edits come back as '
        'markdown', (tester) async {
      final List<String> changes = [];
      await tester.pumpWidget(_app(Scaffold(
        body: MarkdownNoteEditor(
          initialMarkdown: 'Bring the charts',
          onChanged: changes.add,
        ),
      )));
      expect(find.byType(MarkdownBody), findsOneWidget,
          reason: 'a note opens rendered, as tile notes do');
      expect(find.byType(QuillEditor), findsNothing);
      await tester.tap(find.byType(MarkdownBody));
      await tester.pump();
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.byType(MarkdownNoteToolbar), findsOneWidget);
      await _type(tester, 'Bring the charts and the deck');
      expect(changes.last, 'Bring the charts and the deck');
      await _finish(tester);
    });

    testWidgets('an empty note opens in the editor', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: MarkdownNoteEditor(initialMarkdown: '', onChanged: (_) {}),
      )));
      expect(find.byType(QuillEditor), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('read-only shows the note and no toolbar', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: MarkdownNoteEditor(
            initialMarkdown: '- [ ] charts', readOnly: true, onChanged: (_) {}),
      )));
      await tester.tap(find.byType(MarkdownBody));
      await tester.pump();
      expect(find.byType(QuillEditor), findsNothing);
      expect(find.byType(MarkdownNoteToolbar), findsNothing);
      await _finish(tester);
    });

    testWidgets('setMarkdown replaces the note without reporting a change',
        (tester) async {
      final controller = MarkdownNoteEditorController();
      final List<String> changes = [];
      await tester.pumpWidget(_app(Scaffold(
        body: MarkdownNoteEditor(
            initialMarkdown: '',
            controller: controller,
            onChanged: changes.add),
      )));
      controller.setMarkdown('from the server');
      await tester.pump();
      expect(controller.markdown, 'from the server');
      expect(changes, isEmpty);
      await _finish(tester);
    });

    testWidgets(
        'the limit stops typing past it, and the counter shows near '
        'it', (tester) async {
      final List<String> changes = [];
      await tester.pumpWidget(_app(Scaffold(
        body: MarkdownNoteEditor(
            initialMarkdown: '', maxLength: 50, onChanged: changes.add),
      )));
      await _type(tester, 'a' * 40);
      expect(find.byKey(const Key('note_counter')), findsNothing,
          reason: 'hidden until 90% of the limit');
      await _type(tester, 'a' * 46);
      expect(find.text('46/50'), findsOneWidget);
      await _type(tester, 'a' * 51);
      expect(_editorText(tester), 'a' * 46, reason: 'the change is refused');
      expect(changes.last, 'a' * 46);
      await _type(tester, 'a' * 50);
      expect(find.text('50/50'), findsOneWidget);
      await _finish(tester);
    });

    test('the limit counts the stored markdown, formatting included', () {
      expect(markdownNoteLength('**ab**'), 6);
      expect(defaultNoteMaxLength, 5000);
    });
  });

  group('the tile notes editor is built on it', () {
    testWidgets('same toolbar, same editor', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: EditTileNote(
            eventId: 'e1', notesApi: _NoNotesApi(), skipInitialLoad: true),
      )));
      expect(find.byType(MarkdownNoteEditor), findsOneWidget);
      await _finish(tester);
    });
  });

  group('the notes page edits a draft', () {
    testWidgets('Done hands the markdown back; back leaves it unchanged',
        (tester) async {
      String? result = 'untouched';
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await Navigator.of(context)
                .push<String?>(MaterialPageRoute(
                    builder: (_) => const NoteFullPage.draft(
                        initialNote: '', maxLength: 5000))),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _type(tester, 'Use the Q3 numbers');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, 'Use the Q3 numbers');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _type(tester, 'thrown away');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await _finish(tester);
    });
  });

  group('MarkdownNoteView', () {
    testWidgets('renders the markdown; nothing for an empty note',
        (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        body: MarkdownNoteView(markdown: '**Bring** the charts'),
      )));
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
      await tester.pumpWidget(_app(const Scaffold(
        body: MarkdownNoteView(markdown: '   '),
      )));
      expect(find.byType(MarkdownBody), findsNothing);
      await _finish(tester);
    });
  });
}
