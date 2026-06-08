// End-to-end UI test driving the real app in a real engine.
//
// Unlike the headless widget tests in test/, this runs through
// `IntegrationTestWidgetsFlutterBinding`, so it is the flow the Android
// emulator CI job installs and screenshots. It wires the app exactly like
// `main()` and walks a realistic user journey: Increment -> Add 100 ->
// Decrement, asserting the visible counter at each step.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:custom_redux/main.dart';
import 'package:custom_redux/reducer/counterReducer.dart';
import 'package:custom_redux/middleware/increment_action_middleware.dart';
import 'package:custom_redux/store/store.dart';

Store<AppState> buildStore() => Store<AppState>(
      initialState: AppState(counterState: CounterState()),
      reducer: appReducer,
      middlewares: [incrementMiddleware()],
    );

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ElevatedButton, label));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('counter responds to the full action flow end-to-end',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: buildStore()));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);

    await tapButton(tester, 'Increment'); // 0 -> 1
    expect(find.text('1'), findsOneWidget);

    await tapButton(tester, 'Add 100'); // 1 -> 101
    expect(find.text('101'), findsOneWidget);

    await tapButton(tester, 'Decrement'); // 101 -> 100
    expect(find.text('100'), findsOneWidget);
  });
}
