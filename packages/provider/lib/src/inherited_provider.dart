import 'package:flutter/widgets.dart';

import 'provider.dart' show Provider;

/// A function that returns true when the update from [previous] to [current]
/// should notify listeners, if any.
///
/// See also:
///
///   * [InheritedWidget.updateShouldNotify]
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// A function that creates an object of type [T].
///
/// See also:
///
///  * [Disposer], to free the resources associated to the value created.
typedef ValueBuilder<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
///
/// See also:
///
///  * [ValueBuilder], to create a value that will later be disposed of.
typedef Disposer<T> = void Function(BuildContext context, T value);

/// A callback used to start and an object, and return a function that allows
/// cancelling the subscription.
///
/// It is called the first time the value is obtained (through
/// [InheritedProviderElement.value]). And the returned callback will be called
/// when [InheritedProvider] is unmounted or when the it is rebuilt with a new
/// value.
typedef StartListening<T> = VoidCallback Function(
    InheritedProviderElement<T> element, T value);

/// A generic implementation of an [InheritedWidget].
///
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
abstract class InheritedProvider<T> extends InheritedWidget {
  /// Create a value, then expose it to its descendants.
  ///
  /// The value will be disposed of when [InheritedProvider] is removed from
  /// the widget tree.
  factory InheritedProvider({
    Key key,
    ValueBuilder<T> initialValueBuilder,
    T valueBuilder(BuildContext context, T value),
    UpdateShouldNotify<T> updateShouldNotify,
    void Function(T value) debugCheckInvalidValueType,
    StartListening<T> startListening,
    Disposer<T> dispose,
    @required Widget child,
  }) = _CreateInheritedProvider<T>;

  /// Expose to its descendants an existing value,
  factory InheritedProvider.value({
    Key key,
    @required T value,
    UpdateShouldNotify<T> updateShouldNotify,
    StartListening<T> startListening,
    @required Widget child,
  }) = _ValueInheritedProvider<T>;

  InheritedProvider._constructor({Key key, Widget child})
      : super(key: key, child: child);

  @override
  InheritedProviderElement<T> createElement();

  @override
  Type get runtimeType => _typeOf<InheritedProvider<T>>();
}

Type _typeOf<T>() => T;

/// An [Element] that uses an [InheritedProvider] as its configuration.
abstract class InheritedProviderElement<T> extends InheritedElement {
  /// Creates an element that uses the given widget as its configuration.
  InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  InheritedProvider<T> get widget => super.widget as InheritedProvider<T>;

  /// The current value exposed by [InheritedProvider].
  ///
  /// If [InheritedProvider] was built using the default constructor and
  /// `initialValueBuilder` haven't been called yet, then reading [value]
  /// will call `initialValueBuilder`.
  T get value;

  bool _shouldNotifyDependents = false;

  /// Mark the [InheritedProvider] as needing to update dependents.
  ///
  /// This bypass [InheritedWidget.updateShouldNotify] and will force widgets
  /// that depends on [T] to rebuild.
  void markNeedsNotifyDependents() {
    markNeedsBuild();
    _shouldNotifyDependents = true;
  }

  @override
  Widget build() {
    if (_shouldNotifyDependents) {
      _shouldNotifyDependents = false;
      notifyClients(widget);
    }
    return super.build();
  }
}

class _CreateInheritedProvider<T> extends InheritedProvider<T> {
  _CreateInheritedProvider({
    Key key,
    this.initialValueBuilder,
    this.valueBuilder,
    UpdateShouldNotify<T> updateShouldNotify,
    this.debugCheckInvalidValueType,
    this.startListening,
    this.dispose,
    @required Widget child,
  })  : assert(initialValueBuilder != null || valueBuilder != null),
        _updateShouldNotify = updateShouldNotify,
        super._constructor(key: key, child: child);

  final ValueBuilder<T> initialValueBuilder;
  final T Function(BuildContext context, T value) valueBuilder;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final void Function(T value) debugCheckInvalidValueType;
  final StartListening<T> startListening;
  final Disposer<T> dispose;

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    return false;
  }

  @override
  _CreateInheritedProviderElement<T> createElement() =>
      _CreateInheritedProviderElement(this);
}

class _CreateInheritedProviderElement<T> extends InheritedProviderElement<T> {
  _CreateInheritedProviderElement(_CreateInheritedProvider<T> widget)
      : super(widget);

  @override
  _CreateInheritedProvider<T> get widget =>
      super.widget as _CreateInheritedProvider<T>;

  VoidCallback _removeListener;
  bool _didInitValue = false;
  bool _debugInheritLocked = false;
  T _value;
  _CreateInheritedProvider<T> _previousWidget;

  @override
  T get value {
    if (!_didInitValue) {
      _didInitValue = true;
      assert(() {
        _debugInheritLocked = true;
        return true;
      }());
      if (widget.initialValueBuilder != null) {
        _value = widget.initialValueBuilder(this);

        assert(() {
          widget.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
      assert(() {
        _debugInheritLocked = false;
        return true;
      }());
      if (widget.valueBuilder != null) {
        _value = widget.valueBuilder(this, _value);

        assert(() {
          widget.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
    }

    _removeListener ??= widget.startListening?.call(this, _value);
    assert(widget.startListening == null || _removeListener != null);
    return _value;
  }

  @override
  void unmount() {
    super.unmount();
    _removeListener?.call();
    if (_didInitValue) {
      widget.dispose?.call(this, _value);
    }
  }

  @override
  Widget build() {
    var shouldNotify = false;
    if (_didInitValue && widget.valueBuilder != null) {
      final previousValue = _value;
      _value = widget.valueBuilder(this, _value);

      shouldNotify = widget._updateShouldNotify != null
          ? widget._updateShouldNotify(previousValue, _value)
          : _value != previousValue;

      if (shouldNotify) {
        assert(() {
          widget.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
        if (_removeListener != null) {
          _removeListener();
          _removeListener = null;
        }
        _previousWidget?.dispose?.call(this, previousValue);
      }
    }

    if (shouldNotify) {
      _shouldNotifyDependents = true;
    }
    _previousWidget = widget;
    return super.build();
  }

  @override
  InheritedWidget inheritFromElement(
    InheritedElement ancestor, {
    Object aspect,
  }) {
    assert(() {
      if (_debugInheritLocked) {
        throw FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary(
              'Tried to listen to an InheritedWidget '
              'in a life-cycle that will never be called again.',
            ),
            ErrorDescription('''
This error typically happens when calling Provider.of with `listen` to `true`,
in a situation where listening to the provider doesn't make sense, such as:
- initState of a StatefulWidget
- the "builder" callback of a provider

This is undesired because these life-cycles are called only once in the
lifetime of a widget. As such, while `listen` is `true`, the widget has
no mean to handle the update scenario.

To fix, consider:
- passing `listen: false` to `Provider.of`
- use a life-cycle that handles update (like didChangeDependencies)
- use a provider that handle updates (like ProxyProvider).
'''),
          ],
        );
      }
      return true;
    }());
    return super.inheritFromElement(ancestor, aspect: aspect);
  }
}

class _ValueInheritedProvider<T> extends InheritedProvider<T> {
  _ValueInheritedProvider({
    Key key,
    @required this.value,
    UpdateShouldNotify<T> updateShouldNotify,
    this.startListening,
    @required Widget child,
  })  : _updateShouldNotify = updateShouldNotify,
        super._constructor(key: key, child: child);

  final T value;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final StartListening<T> startListening;

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    throw StateError(
      '''updateShouldNotify is implemented internally by InheritedProviderElement''',
    );
  }

  @override
  _ValueInheritedProviderElement<T> createElement() =>
      _ValueInheritedProviderElement<T>(this);
}

class _ValueInheritedProviderElement<T> extends InheritedProviderElement<T> {
  _ValueInheritedProviderElement(_ValueInheritedProvider<T> widget)
      : super(widget);

  @override
  _ValueInheritedProvider<T> get widget =>
      super.widget as _ValueInheritedProvider<T>;

  VoidCallback _removeListener;

  @override
  T get value {
    _removeListener ??= widget.startListening?.call(this, widget.value);
    assert(widget.startListening == null || _removeListener != null);
    return widget.value;
  }

  @override
  void updated(_ValueInheritedProvider<T> oldWidget) {
    bool shouldNotify;
    if (widget._updateShouldNotify != null) {
      shouldNotify = widget._updateShouldNotify(oldWidget.value, widget.value);
    } else {
      shouldNotify = oldWidget.value != widget.value;
    }

    if (shouldNotify) {
      if (_removeListener != null) {
        _removeListener();
        _removeListener = null;
      }

      notifyClients(oldWidget);
    }
  }

  @override
  void unmount() {
    super.unmount();
    _removeListener?.call();
  }
}
