// Tests for the A+B+E redesign of ContactInputFieldWidget.
//
// These tests are intentionally RED until the implementation is done.
//
// A – person_add leading icon  +  explicit add IconButton
// B – inline validation error for invalid email/phone
// E – chips and text field rendered in one cohesive inline layout
//
// NOTE: one new arb key is expected by these tests:
//   "invalidContactFormat": "Not a valid email or phone number"
// Add it to app_en.arb (and app_es.arb) before running after implementation.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ── test harness ─────────────────────────────────────────────────────────────

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// Pumps the widget and waits for all async work and animations to settle.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_buildTestApp(child: child));
  await tester.pumpAndSettle();
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// Returns a fresh mutable contacts list that is always replaced (not appended)
/// on each callback invocation, so tests can inspect the latest state.
List<Contact> _captureContacts() => [];

extension on List<Contact> {
  void replace(List<Contact> incoming) {
    clear();
    addAll(incoming);
  }
}

/// Taps the expand button (Icons.add) to reveal the text field.
Future<void> _expand(WidgetTester tester) async {
  await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
  await tester.pump();
}

/// Enters [text] and submits via the enabled check button (Icons.check).
/// Caller must ensure [text] is a valid contact so the check button is enabled.
Future<void> _submitViaButton(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.widgetWithIcon(IconButton, Icons.check));
  await tester.pump();
}

/// Enters [text] and submits via keyboard Done (TextInputAction.done).
Future<void> _submitViaKeyboard(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContactInputFieldWidget – 2-state flow', () {
    // ── A: Collapsed / expanded behaviour ────────────────────────────────────

    testWidgets('A: no redundant leading person_add icon', (tester) async {
      // Bucket 1.1: the expand/check button is the single add affordance.
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      expect(
        find.byIcon(Icons.person_add_outlined),
        findsNothing,
        reason: 'Leading person_add icon should not be present',
      );
    });

    testWidgets('A: text field hidden on initial render (collapsed state)',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      expect(
        find.byType(TextField),
        findsNothing,
        reason: 'TextField should be hidden until the user expands the input',
      );
    });

    testWidgets('A: expand button visible on initial render', (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      expect(
        find.widgetWithIcon(IconButton, Icons.add),
        findsOneWidget,
        reason:
            'The expand button (Icons.add) should be visible in collapsed state',
      );
    });

    testWidgets('A: tapping expand button reveals the text field',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);

      expect(
        find.byType(TextField),
        findsOneWidget,
        reason: 'TextField should appear after tapping the expand button',
      );
    });

    testWidgets('A: expand button replaced by check button when expanded',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);

      expect(
        find.widgetWithIcon(IconButton, Icons.add),
        findsNothing,
        reason: 'Expand button should be hidden when the input is expanded',
      );
      expect(
        find.widgetWithIcon(IconButton, Icons.check),
        findsOneWidget,
        reason: 'Check button (Icons.check) should replace the expand button',
      );
    });

    testWidgets('A: check button is disabled when field is empty',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));
      await _expand(tester);

      final checkButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check),
      );

      expect(
        checkButton.onPressed,
        isNull,
        reason: 'Check button must be disabled when the field is empty',
      );
    });

    testWidgets('A: check button remains disabled with invalid text',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));
      await _expand(tester);

      await tester.enterText(find.byType(TextField), 'notanemail');
      await tester.pump();

      final checkButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check),
      );

      expect(
        checkButton.onPressed,
        isNull,
        reason:
            'Check button must stay disabled when the text is not a valid contact',
      );
    });

    testWidgets('A: check button enabled when field has valid email',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));
      await _expand(tester);

      await tester.enterText(find.byType(TextField), 'alice@example.com');
      await tester.pump();

      final checkButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check),
      );

      expect(
        checkButton.onPressed,
        isNotNull,
        reason: 'Check button should be enabled once a valid email is typed',
      );
    });

    testWidgets(
        'A: tapping check button with a valid email adds a chip and clears the field',
        (tester) async {
      final captured = _captureContacts();

      await _pump(
        tester,
        ContactInputFieldWidget(
          isReadOnly: false,
          onContactUpdate: (contacts) => captured.replace(contacts),
        ),
      );

      await _expand(tester);
      await _submitViaButton(tester, 'alice@example.com');

      expect(
        find.text('alice@example.com'),
        findsOneWidget,
        reason: 'A chip labelled with the email should appear',
      );
      final fieldController =
          tester.widget<TextField>(find.byType(TextField)).controller;
      expect(
        fieldController?.text ?? '',
        isEmpty,
        reason: 'The text field should be cleared after a successful add',
      );
      expect(captured, hasLength(1));
      expect(captured.first.email, 'alice@example.com');
    });

    testWidgets(
        'A: tapping check button with a valid phone number adds a chip and clears the field',
        (tester) async {
      final captured = _captureContacts();

      await _pump(
        tester,
        ContactInputFieldWidget(
          isReadOnly: false,
          onContactUpdate: (contacts) => captured.replace(contacts),
        ),
      );

      await _expand(tester);
      await _submitViaButton(tester, '+15550001234');

      expect(captured, hasLength(1));
      expect(captured.first.phoneNumber, '+15550001234');
    });

    testWidgets('A: field stays expanded after a successful add',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      await _submitViaButton(tester, 'stay@example.com');

      expect(
        find.byType(TextField),
        findsOneWidget,
        reason:
            'Field should remain visible after adding, to enable rapid multi-add',
      );
      expect(
        find.widgetWithIcon(IconButton, Icons.check),
        findsOneWidget,
        reason:
            'Check button should remain visible in expanded state after add',
      );
    });

    // ── B: Inline validation ──────────────────────────────────────────────────

    testWidgets('B: no validation error shown on initial render',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      expect(
        find.text('Not a valid email or phone number'),
        findsNothing,
        reason:
            'Validation error must not be shown before the user has done anything',
      );
    });

    testWidgets(
        'B: validation error appears when keyboard Done is pressed with invalid text',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      // Check button is gated on valid input; use keyboard Done to attempt invalid submit.
      await _submitViaKeyboard(tester, 'notanemail');

      expect(
        find.text('Not a valid email or phone number'),
        findsOneWidget,
        reason:
            'A validation error should appear when keyboard Done is pressed with invalid input',
      );
    });

    testWidgets('B: no chip is added when validation fails', (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      await _submitViaKeyboard(tester, 'notanemail');

      expect(
        find.byType(Chip),
        findsNothing,
        reason: 'An invalid entry must not produce a chip',
      );
    });

    testWidgets('B: validation error clears after the field is emptied',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      await _submitViaKeyboard(tester, 'notanemail');

      // Clear the field
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(
        find.text('Not a valid email or phone number'),
        findsNothing,
        reason: 'Clearing the field should dismiss the validation error',
      );
    });

    testWidgets(
        'B: validation error clears after a subsequent valid submission',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      // Trigger error with invalid keyboard Done
      await _submitViaKeyboard(tester, 'bad-input');

      // Submit a valid email via check button (now enabled)
      await _submitViaButton(tester, 'good@example.com');

      expect(
        find.text('Not a valid email or phone number'),
        findsNothing,
        reason:
            'A successful submission should clear any prior validation error',
      );
    });

    // ── E: Inline chip layout ─────────────────────────────────────────────────

    testWidgets('E: chip appears after adding a valid contact', (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      await _submitViaButton(tester, 'bob@example.com');

      expect(
        find.byType(Chip),
        findsOneWidget,
        reason: 'Adding a contact should render a Chip',
      );
    });

    testWidgets(
        'E: chip and text field are both visible in the same layout region',
        (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      // Add a chip — field stays expanded so chip + field are visible together.
      await _submitViaButton(tester, 'inline@example.com');

      // Both must be in the widget tree simultaneously.
      expect(find.byType(Chip), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Chip and field should share vertical space (both visible without scrolling).
      final chipRect = tester.getRect(find.byType(Chip));
      final fieldRect = tester.getRect(find.byType(TextField));
      final combinedHeight = Rect.fromLTRB(
        0,
        chipRect.top < fieldRect.top ? chipRect.top : fieldRect.top,
        0,
        chipRect.bottom > fieldRect.bottom ? chipRect.bottom : fieldRect.bottom,
      ).height;

      expect(
        combinedHeight,
        lessThan(120),
        reason:
            'Chip and TextField should be in the same inline row/wrap, not stacked '
            'in separate sections — combined height should be compact',
      );
    });

    testWidgets('E: multiple contacts produce multiple chips', (tester) async {
      await _pump(tester, ContactInputFieldWidget(isReadOnly: false));

      await _expand(tester);
      for (final email in [
        'alpha@example.com',
        'beta@example.com',
        'gamma@example.com',
      ]) {
        await _submitViaButton(tester, email);
      }

      expect(
        find.byType(Chip),
        findsNWidgets(3),
        reason: 'Each added contact should produce exactly one chip',
      );
    });

    testWidgets(
        'E: tapping chip delete icon removes contact and fires callback',
        (tester) async {
      final captured = _captureContacts();

      await _pump(
        tester,
        ContactInputFieldWidget(
          isReadOnly: false,
          onContactUpdate: (contacts) => captured.replace(contacts),
        ),
      );

      await _expand(tester);
      await _submitViaButton(tester, 'delete@example.com');

      expect(find.byType(Chip), findsOneWidget);
      expect(captured, hasLength(1));

      // Tap the chip's delete icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(
        find.byType(Chip),
        findsNothing,
        reason: 'Chip should be removed from the tree after deletion',
      );
      expect(captured, isEmpty,
          reason: 'Callback should fire with an empty list after removal');
    });

    testWidgets(
        'E: pre-populated contacts are rendered as chips on initial build',
        (tester) async {
      final existing = [
        Contact()..email = 'existing@example.com',
        Contact()..phoneNumber = '+447700900000',
      ];

      await _pump(
        tester,
        ContactInputFieldWidget(
          isReadOnly: false,
          contacts: existing,
        ),
      );

      expect(
        find.byType(Chip),
        findsNWidgets(2),
        reason:
            'Pre-populated contacts should each render as a chip immediately',
      );
    });

    // ── Regression ────────────────────────────────────────────────────────────

    testWidgets(
        'keyboard Done still adds a valid contact (original behaviour preserved)',
        (tester) async {
      final captured = _captureContacts();

      await _pump(
        tester,
        ContactInputFieldWidget(
          isReadOnly: false,
          onContactUpdate: (contacts) => captured.replace(contacts),
        ),
      );

      await _expand(tester);
      await _submitViaKeyboard(tester, 'keyboard@example.com');

      expect(
        find.text('keyboard@example.com'),
        findsOneWidget,
        reason: 'Pressing keyboard Done should still add the contact',
      );
      expect(captured.first.email, 'keyboard@example.com');
    });

    testWidgets(
        'read-only mode: no expand/check button and no text field are rendered',
        (tester) async {
      final existing = [Contact()..email = 'readonly@example.com'];

      await _pump(
        tester,
        ContactInputFieldWidget(
          isReadOnly: true,
          contacts: existing,
        ),
      );

      expect(find.byType(TextField), findsNothing,
          reason: 'No input field in read-only mode');
      expect(find.widgetWithIcon(IconButton, Icons.add), findsNothing,
          reason: 'No expand button in read-only mode');
      expect(find.widgetWithIcon(IconButton, Icons.check), findsNothing,
          reason: 'No check button in read-only mode');
      expect(find.byType(Chip), findsOneWidget,
          reason: 'Existing chips should still be visible in read-only mode');
    });
  });
}
