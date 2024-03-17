typedef CreateValue<T> = T Function();

class SharedInstance<T> {
  SharedInstance._({
    required this.value,
    required Object acquirer,
    required String instanceKey,
  }) : _instanceKey = instanceKey {
    _acquirers.add(acquirer);
  }

  final String _instanceKey;

  final T value;

  final Set<Object> _acquirers = {};

  static final _container = <String, SharedInstance<dynamic>>{};

  static int _getAcquirerCount(String instanceKey) {
    return _container[instanceKey]?._acquirers.length ?? 0;
  }

  static bool hasAcquirer(String instanceKey) {
    return _getAcquirerCount(instanceKey) > 0;
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
        acquirer: acquirer,
        instanceKey: instanceKey,
      );
    }
    return _container[instanceKey]! as SharedInstance<T>;
  }

  ///
  /// Releases the instance from the acquirer.
  /// If the instance is no longer used, it is removed from the container.
  /// Returns true if the instance has been removed from the container.
  /// Returns false if the instance remains in the container.
  ///
  bool release(Object acquirer) {
    _acquirers.remove(acquirer);
    if (_acquirers.isEmpty) {
      _container.remove(_instanceKey);
    }
    return !hasAcquirer(_instanceKey);
  }
}
