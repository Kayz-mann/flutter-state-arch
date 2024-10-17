import 'package:custom_redux/action/action.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../reducer/counterReducer.dart';
import '../middleware/increment_action_middleware.dart';

typedef Dispatcher = void Function(Action action);

class Store<StoreState extends ReduxState> extends ChangeNotifier {
  StoreState _state;
  final Reducer<StoreState> _reducer;
  final List<Middleware<StoreState>> _middlewares;

  StoreState get state => _state;

  Store({
    required StoreState initialState,
    required Reducer<StoreState> reducer,
    List<Middleware<StoreState>> middlewares = const [],
  })  : _state = initialState,
        _reducer = reducer,
        _middlewares = middlewares;

  void dispatch(ReduxAction action) {
    _state = _reducer(_state, action);
    for (final middleware in _middlewares) {
      middleware(_state, action, dispatch);
    }
    notifyListeners();
  }
}
