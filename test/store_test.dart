// Tests for the Store: dispatching an action must run it through the reducer,
// update `state`, and notify listeners (the Store is a ChangeNotifier).

import 'package:flutter_test/flutter_test.dart';

import 'package:custom_redux/main.dart';
import 'package:custom_redux/action/action.dart';
import 'package:custom_redux/reducer/counterReducer.dart';
import 'package:custom_redux/middleware/increment_action_middleware.dart';
import 'package:custom_redux/store/store.dart';

Store<AppState> buildStore() => Store<AppState>(
      initialState: AppState(counterState: CounterState()),
      reducer: appReducer,
      middlewares: [incrementMiddleware()],
    );

void main() {
  test('dispatch updates state through the reducer', () {
    final store = buildStore();
    expect(store.state.counterState.counter, 0);

    store.dispatch(IncrementAction());
    expect(store.state.counterState.counter, 1);

    store.dispatch(AddAction(100));
    expect(store.state.counterState.counter, 101);
  });

  test('dispatch notifies listeners once per action', () {
    final store = buildStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    store.dispatch(IncrementAction());
    store.dispatch(DecrementAction());

    expect(notifications, 2);
  });

  test('async middleware schedules a delayed increment', () async {
    final store = buildStore();

    store.dispatch(IncrementActionAsync());
    // The middleware waits 2s before dispatching the real IncrementAction, so
    // immediately after dispatch the counter is unchanged.
    expect(store.state.counterState.counter, 0);

    await Future<void>.delayed(const Duration(seconds: 2));
    expect(store.state.counterState.counter, 1);
  });
}
