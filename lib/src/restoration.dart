part of 'provider.dart';

/// This is proxy [RestorationMixin] for your provider
mixin RestorationHandler {
  _RestorationMixinWrapperState _wrapperState;

  /// See [RestorationMixin.bucket]
  RestorationBucket get bucket {
    assert(
      _wrapperState != null,
      'registerForRestoration called before initialization',
    );
    return _wrapperState.bucket;
  }

  /// See [RestorationMixin.restoreState]
  @mustCallSuper
  @protected
  void restoreState(
    RestorationBucket oldBucket,
    bool initialRestore,
  );

  /// See [RestorationMixin.registerForRestoration]
  @protected
  void registerForRestoration(
    RestorableProperty<Object> property,
    String restorationId,
  ) {
    assert(
      _wrapperState != null,
      'registerForRestoration called before initialization',
    );
    // ignore: invalid_use_of_protected_member
    _wrapperState.registerForRestoration(property, restorationId);
  }

  /// See [RestorationMixin.unregisterFromRestoration]
  @protected
  void unregisterFromRestoration(RestorableProperty<Object> property) {
    assert(
      _wrapperState != null,
      'registerForRestoration called before initialization',
    );
    // ignore: invalid_use_of_protected_member
    _wrapperState.unregisterFromRestoration(property);
  }

  /// See [RestorationMixin.restorePending]
  bool get restorePending {
    assert(
      _wrapperState != null,
      'registerForRestoration called before initialization',
    );
    return _wrapperState.restorePending;
  }
}

class _RestorationMixinWrapper<T extends RestorationHandler>
    extends StatefulWidget {
  _RestorationMixinWrapper({
    Key key,
    @required this.restorationId,
    @required this.value,
    @required this.child,
  }) : super(key: key);

  final String restorationId;
  final T value;
  final Widget child;

  @override
  _RestorationMixinWrapperState createState() =>
      _RestorationMixinWrapperState<T>();
}

class _RestorationMixinWrapperState<T extends RestorationHandler>
    extends State<_RestorationMixinWrapper<T>> with RestorationMixin {
  bool _hasFirstRestore = false;

  @override
  void initState() {
    super.initState();

    widget.value?._wrapperState = this;
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  String get restorationId => widget.restorationId;

  @override
  void restoreState(
    RestorationBucket oldBucket,
    bool initialRestore,
  ) {
    final value = widget.value;
    if (value != null) {
      value.restoreState(oldBucket, initialRestore);
      _hasFirstRestore = true;
    }
  }

  void _notifyIfNeeded(T value) {
    if (!_hasFirstRestore && value != null) {
      value
        .._wrapperState = this
        ..restoreState(bucket, true);
      _hasFirstRestore = true;
    }
  }
}
