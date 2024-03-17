import 'package:flutter/foundation.dart';

typedef CreateValue<T> = T Function();

class SharedInstance<T> {
  SharedInstance._({
    required this.value,
    required String instanceKey,
  }) : _instanceKey = instanceKey;

  static final _container = <String, SharedInstance<dynamic>>{};

  static int _getAcquirerCount(String instanceKey) {
    return _container[instanceKey]?._acquirers.length ?? 0;
  }

  static bool hasAcquirer(String instanceKey) {
    return _getAcquirerCount(instanceKey) > 0;
  }

  @visibleForTesting
  static void disposeAll() {
    _container.forEach((key, value) {
      value._acquirers.clear();
    });
    _container.clear();
  }

  final String _instanceKey;

  final T value;

  final Set<Object> _acquirers = {};

  bool get _hasAcquirer {
    return _acquirers.isNotEmpty;
  }

  void _addAcquirer(Object acquirer) {
    _acquirers.add(acquirer);
  }

  void _removeAcquirer(Object acquirer) {
    _acquirers.remove(acquirer);
  }

  ///
  /// Creates and returns an instance if it does not exist in the container.
  /// Otherwise, returns an existing instance.
  /// The acquirer is added to the list of acquirers.
  ///
  factory SharedInstance.acquire({
    required CreateValue<T> createValue,
    required Object acquirer,
    required String instanceKey,
  }) {
    if (!_container.containsKey(instanceKey)) {
      _container[instanceKey] = SharedInstance<T>._(
        value: createValue(),
        instanceKey: instanceKey,
      );
    }
    final sharedInstance = _container[instanceKey]! as SharedInstance<T>;
    sharedInstance._addAcquirer(acquirer);
    return sharedInstance;
  }

  ///
  /// Releases the instance from the acquirer.
  /// If the instance is no longer used, it is removed from the container.
  /// Returns true if the instance has been removed from the container.
  /// Returns false if the instance remains in the container.
  ///
  bool release(Object acquirer) {
    _removeAcquirer(acquirer);
    if (!_hasAcquirer) {
      _container.remove(_instanceKey);
    }
    return !hasAcquirer(_instanceKey);
  }
}
