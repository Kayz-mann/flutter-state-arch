// Reducer
import 'package:custom_redux/action/action.dart';
import 'package:custom_redux/main.dart';

typedef Reducer<State extends ReduxState> = State Function(
    State state, ReduxAction action);

CounterState counterReducer(CounterState state, ReduxAction action) {
  switch (action.runtimeType) {
    case IncrementAction:
      return state.copyWith(counter: state.counter + 1);
    case DecrementAction:
      return state.copyWith(counter: state.counter - 1);
    case AddAction:
      return state.copyWith(
          counter: state.counter + (action as AddAction).value);
    default:
      return state;
  }
}

AppState appReducer(AppState state, ReduxAction action) {
  return AppState(
    counterState: counterReducer(state.counterState, action),
  );
}
