import 'package:flutter/material.dart';

import 'change_notifier_observer.dart';

/// A base class for notifiers that integrates with [ChangeNotifierObserver].
/// Handles lifecycle events and state changes.
class BaseNotifier extends ChangeNotifier {
  /// Creates a [BaseNotifier] with the given [observer] and [providerName].
  ///
  /// The [observer] will be notified of lifecycle events.
  /// The [providerName] is used to identify this notifier in observer callbacks.
  BaseNotifier(this._observer, String providerName)
      : assert(providerName.isNotEmpty, 'providerName cannot be empty'),
        _providerName = providerName {
    // call onCreate when the object is created
    _observer.onCreate(_providerName);
  }

  final ChangeNotifierObserver _observer;
  final String _providerName;

  /// Updates the state and notifies observers and listeners.
  ///
  /// [newState] is the new state value to be set.
  /// Throws if the observer callback fails.
  @protected
  void updateState<T>(T newState) {
    // call onChange when the state is changed
    try {
      _observer.onChange(_providerName, newState);
      notifyListeners();
    } catch (e, stackTrace) {
      // Consider adding error handling through the observer
      rethrow;
    }
  }

  /// Disposes of the notifier and notifies the observer.
  ///
  /// This method must be called when the notifier is no longer needed.
  @override
  void dispose() {
    // call onDispose when the object is disposed
    try {
      _observer.onDispose(_providerName);
    } finally {
      super.dispose();
    }
  }
}
