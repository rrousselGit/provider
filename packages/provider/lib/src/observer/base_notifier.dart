import 'package:flutter/material.dart';

import 'change_notifier_observer.dart';

class BaseNotifier extends ChangeNotifier {
  BaseNotifier(this.observer, this.providerName) {
    // call onCreate when the object is created
    observer.onCreate(providerName);
  }
  final ChangeNotifierObserver observer;
  final String providerName;

  @protected
  void updateState(dynamic newState) {
    // call onChange when the state is changed
    observer.onChange(providerName, newState);
    notifyListeners();
  }

  @override
  void dispose() {
    // call onDispose when the object is disposed
    observer.onDispose(providerName);
    super.dispose();
  }
}
