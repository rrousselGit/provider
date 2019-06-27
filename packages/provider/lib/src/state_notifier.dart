import 'package:flutter/foundation.dart';

abstract class StateNotifier<T> extends ChangeNotifier {
  T _state;

  StateNotifier() {
    _state = initialState;
  }

  T get initialState;
  T get state => _state;

  void setState(T state) {
    _state = state;
    notifyListeners();
  }
}
