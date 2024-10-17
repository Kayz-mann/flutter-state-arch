import 'package:flutter/foundation.dart';

@immutable
abstract class ReduxAction {}

class IncrementAction extends ReduxAction {}

class DecrementAction extends ReduxAction {}

class IncrementActionAsync extends ReduxAction {}

class AddAction extends ReduxAction {
  final int value;
  AddAction(this.value);
}
