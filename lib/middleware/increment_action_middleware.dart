// Middleware
import 'package:custom_redux/action/action.dart';
import 'package:custom_redux/main.dart';

typedef Dispatcher = void Function(ReduxAction action);
typedef Middleware<StoreState extends ReduxState> = void Function(
    StoreState state, ReduxAction action, Dispatcher dispatch);

Middleware<AppState> incrementMiddleware() {
  return (AppState state, ReduxAction action, Dispatcher dispatch) {
    if (action is IncrementActionAsync) {
      Future.delayed(Duration(seconds: 2), () {
        dispatch(IncrementAction());
      });
    }
  };
}
