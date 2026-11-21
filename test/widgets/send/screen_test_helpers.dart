import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/harness.dart';

// Small helpers shared by the send, recipients and history widget tests, so
// each test reads as "do this, expect that" and not as finder plumbing.

/// A phone tall enough that a scrolling screen builds every row it has.
/// A ListView builds its rows lazily, so a tile far below the fold would not
/// exist yet and could not be found.
const tallPhone = Size(430, 1600);

/// Shows [screen] inside the test app and lets the cubits receive the first
/// list from the in-memory repositories.
Future<void> showScreen(
  WidgetTester tester,
  TestApp app,
  Widget screen, {
  bool bindFirst = true,
  bool dark = false,
}) async {
  await app.pumpScreen(
    tester,
    screen,
    size: tallPhone,
    bindFirst: bindFirst,
    dark: dark,
  );
  await tester.pumpAndSettle();
}

/// Found while the page under the tested screen is the one showing.
const basePageKey = Key('test.basePage');
const _openKey = Key('test.openScreen');

/// Shows [screen] one route above a plain page, as in the real app. Back,
/// Cancel and Done then have a page to return to, and a test can tell a
/// screen that was popped or replaced from one that is still there.
Future<void> showScreenAbovePage(
  WidgetTester tester,
  TestApp app,
  Widget screen, {
  bool bindFirst = true,
}) async {
  await app.pumpScreen(
    tester,
    _BasePage(screen: screen),
    size: tallPhone,
    bindFirst: bindFirst,
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

class _BasePage extends StatelessWidget {
  const _BasePage({required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: basePageKey,
      body: Center(
        child: TextButton(
          key: _openKey,
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('open'),
        ),
      ),
    );
  }
}

/// Types [text] into the field that has [key], replacing what is there.
Future<void> enterIn(WidgetTester tester, Key key, String text) async {
  final field = find.byKey(key);
  expect(field, findsOneWidget, reason: 'no field has the key $key');
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Taps the widget that has [key] and waits for the animations to finish.
Future<void> press(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  expect(target, findsOneWidget, reason: 'no widget has the key $key');
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// The string shown by the `Text` that has [key].
String textOf(WidgetTester tester, Key key) {
  final target = find.byKey(key);
  expect(target, findsOneWidget, reason: 'no Text has the key $key');
  return tester.widget<Text>(target).data ?? '';
}

/// What is typed in the text field that has [key].
String fieldText(WidgetTester tester, Key key) {
  final editable = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
  expect(editable, findsOneWidget, reason: 'no text field has the key $key');
  return tester.widget<EditableText>(editable).controller.text;
}

/// [tile] found inside the list that has the key [list].
Finder tileIn(Key list, Key tile) {
  return find.descendant(of: find.byKey(list), matching: find.byKey(tile));
}

/// The keys appear one under the other, in the order given.
void expectTopToBottom(WidgetTester tester, List<Key> keys) {
  final tops = [for (final key in keys) tester.getTopLeft(find.byKey(key)).dy];
  for (var i = 0; i < tops.length - 1; i++) {
    expect(
      tops[i],
      lessThan(tops[i + 1]),
      reason: '${keys[i]} should sit above ${keys[i + 1]}',
    );
  }
}

/// One snack bar is on screen.
void expectSnack() => expect(find.byType(SnackBar), findsOneWidget);

/// The last named route pushed (or pushed as a replacement) is [name], and
/// its page is the one showing.
void expectOnRoute(TestApp app, String name) {
  expect(app.pushed, isNotEmpty, reason: 'no route was pushed');
  expect(app.pushed.last.name, name);
  expect(find.text('route:$name'), findsOneWidget);
}

void expectNothingPushed(TestApp app) {
  expect(app.pushed, isEmpty, reason: 'a route was pushed');
}

/// The ids of the stored transactions, taken before an action.
Set<String> recordIds(TestApp app) {
  return app.transactionRepo.items.map((record) => record.id).toSet();
}

/// The transactions written since [before] was taken.
List<TransactionRecord> recordsAddedSince(TestApp app, Set<String> before) {
  return app.transactionRepo.items
      .where((record) => !before.contains(record.id))
      .toList();
}

/// The stored transaction with [id].
TransactionRecord recordWith(TestApp app, String id) {
  return app.transactionRepo.items.firstWhere((record) => record.id == id);
}

/// The MoMo PIN is typed in the phone's own dialog, so no screen may hold a
/// field for it: nothing obscured, nothing labelled PIN, no key naming one.
void expectNoPinField(WidgetTester tester) {
  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    expect(
      field.obscureText,
      isFalse,
      reason: 'an obscured field can hold a PIN',
    );
    final decoration = field.decoration;
    final words =
        '${decoration?.hintText ?? ''} ${decoration?.labelText ?? ''}';
    expect(words.toLowerCase(), isNot(contains('pin')));
  }
  final pinKeys = tester.allWidgets
      .map((widget) => widget.key)
      .whereType<ValueKey<String>>()
      .where((key) => key.value.toLowerCase().contains('pin'));
  expect(pinKeys, isEmpty, reason: 'a widget key mentions a PIN');
}
