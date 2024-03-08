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

  ///
  /// Creates and returns an instance if it does not exist in the container.
  /// Otherwise, returns an existing instance.
  /// The acquirer is added to the list of acquirers.
  ///
  static SharedInstance<T> acquire<T>({
    required CreateValue<T> createValue,
    required Object acquirer,
    String? instanceKey,
  }) {
    final key = instanceKey ?? T.toString();

    if (!_container.containsKey(key)) {
      _container[key] = SharedInstance<T>._(
        value: createValue(),
        acquirer: acquirer,
        instanceKey: key,
      );
    }
    return _container[key]! as SharedInstance<T>;
  }

  ///
  /// Releases the instance from the acquirer.
  /// If the instance is no longer used, it is removed from the container.
  /// Returns true if the instance has been removed from the container.
  /// Returns false if the instance remains in the container.
  ///
  bool release(Object acquirer) {
    _acquirers.remove(acquirer);
    var disposed = false;
    if (_acquirers.isEmpty) {
      _container.remove(_instanceKey);
      disposed = true;
    }
    return disposed;
  }
}
