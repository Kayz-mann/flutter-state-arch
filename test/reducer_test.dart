// Pure-function tests for the reducers. Reducers must be deterministic and
// side-effect free, so we assert on the new state they return for each action.

import 'package:flutter_test/flutter_test.dart';

import 'package:custom_redux/main.dart';
import 'package:custom_redux/action/action.dart';
import 'package:custom_redux/reducer/counterReducer.dart';

void main() {
  group('counterReducer', () {
    test('IncrementAction adds one', () {
      final next = counterReducer(CounterState(counter: 5), IncrementAction());
      expect(next.counter, 6);
    });

    test('DecrementAction subtracts one', () {
      final next = counterReducer(CounterState(counter: 5), DecrementAction());
      expect(next.counter, 4);
    });

    test('AddAction adds its value', () {
      final next = counterReducer(CounterState(counter: 5), AddAction(100));
      expect(next.counter, 105);
    });

    test('IncrementActionAsync is a no-op in the reducer (handled by middleware)',
        () {
      final next =
          counterReducer(CounterState(counter: 5), IncrementActionAsync());
      expect(next.counter, 5);
    });

    test('does not mutate the incoming state', () {
      final initial = CounterState(counter: 5);
      counterReducer(initial, IncrementAction());
      expect(initial.counter, 5);
    });
  });

  group('appReducer', () {
    test('delegates to counterReducer for the nested counter state', () {
      final state = AppState(counterState: CounterState(counter: 0));
      final next = appReducer(state, AddAction(42));
      expect(next.counterState.counter, 42);
    });
  });
}
