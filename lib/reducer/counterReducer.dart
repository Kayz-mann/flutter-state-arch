// ignore_for_file: file_names

import 'package:custom_redux/action/action.dart';
import 'package:custom_redux/main.dart';

typedef Reducer<State extends ReduxState> = State Function(
    State state, ReduxAction action);

CounterState counterReducer(CounterState state, ReduxAction action) {
  // Switch on the action itself (not action.runtimeType): object patterns like
  // `IncrementAction _` test `value is IncrementAction`, which is only true for
  // the action instance, never for a Type object.
  switch (action) {
    case IncrementAction _:
      return state.copyWith(counter: state.counter + 1);
    case DecrementAction _:
      return state.copyWith(counter: state.counter - 1);
    case AddAction a:
      return state.copyWith(counter: state.counter + a.value);
    default:
      return state;
  }
}

AppState appReducer(AppState state, ReduxAction action) {
  return AppState(
    counterState: counterReducer(state.counterState, action),
  );
}
