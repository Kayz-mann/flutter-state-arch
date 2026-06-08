// Widget (UI) tests for the custom Redux counter app.
//
// These drive the real widget tree the same way `main()` wires it up: a
// `Store<AppState>` with the app reducer and the async increment middleware,
// passed into `MyApp`. The UI uses labelled `ElevatedButton`s (Increment /
// Decrement / Add 100 / Increment Async), so we find buttons by their label
// rather than by icon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custom_redux/main.dart';
import 'package:custom_redux/reducer/counterReducer.dart';
import 'package:custom_redux/middleware/increment_action_middleware.dart';
import 'package:custom_redux/store/store.dart';

/// Builds a store wired exactly like `main()` does, so widget tests exercise
/// the same reducer + middleware stack as the running app.
Store<AppState> buildStore() {
  return Store<AppState>(
    initialState: AppState(counterState: CounterState()),
    reducer: appReducer,
    middlewares: [incrementMiddleware()],
  );
}

/// Taps the `ElevatedButton` carrying [label] and settles a frame.
Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ElevatedButton, label));
  await tester.pump();
}

void main() {
  testWidgets('counter starts at 0 and renders all action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: buildStore()));

    expect(find.text('0'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Increment'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Decrement'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Add 100'), findsOneWidget);
    expect(
        find.widgetWithText(ElevatedButton, 'Increment Async'), findsOneWidget);
  });

  testWidgets('Increment raises the counter by one',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: buildStore()));

    await tapButton(tester, 'Increment');

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Decrement lowers the counter by one',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: buildStore()));

    await tapButton(tester, 'Decrement');

    expect(find.text('-1'), findsOneWidget);
  });

  testWidgets('Add 100 raises the counter by one hundred',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: buildStore()));

    await tapButton(tester, 'Add 100');

    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('Increment Async updates only after the 2s middleware delay',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: buildStore()));

    await tapButton(tester, 'Increment Async');
    // The middleware schedules the real increment 2 seconds later, so the
    // counter must still read 0 immediately after the tap.
    expect(find.text('0'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1'), findsOneWidget);
  });
}
