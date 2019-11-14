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
class InheritedProvider<T> extends InheritedWidget {
  /// Create a value, then expose it to its descendants.
  ///
  /// The value will be disposed of when [InheritedProvider] is removed from
  /// the widget tree.
  InheritedProvider({
    Key key,
    ValueBuilder<T> initialValueBuilder,
    T valueBuilder(BuildContext context, T value),
    UpdateShouldNotify<T> updateShouldNotify,
    void Function(T value) debugCheckInvalidValueType,
    StartListening<T> startListening,
    Disposer<T> dispose,
    @required Widget child,
  })  : assert(initialValueBuilder != null || valueBuilder != null),
        _isStateful = true,
        _value = null,
        _startListening = startListening,
        _initialValueBuilder = initialValueBuilder,
        _valueBuilder = valueBuilder,
        _updateShouldNotify = updateShouldNotify,
        _debugCheckInvalidValueType = debugCheckInvalidValueType,
        _dispose = dispose,
        super(key: key, child: child);

  /// Expose to its descendants an existing value,
  InheritedProvider.value({
    Key key,
    @required T value,
    UpdateShouldNotify<T> updateShouldNotify,
    StartListening<T> startListening,
    @required Widget child,
  })  : _isStateful = false,
        _value = value,
        _startListening = startListening,
        _dispose = null,
        _initialValueBuilder = null,
        _valueBuilder = null,
        _debugCheckInvalidValueType = null,
        _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  final bool _isStateful;

  /// The currently exposed value.
  ///
  /// Mutating `value` should be avoided. Instead rebuild the widget tree
  /// and replace [InheritedProvider] with one that holds the new value.
  final T _value;
  final ValueBuilder<T> _initialValueBuilder;
  final T Function(BuildContext context, T value) _valueBuilder;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final Disposer<T> _dispose;
  final void Function(T value) _debugCheckInvalidValueType;
  final StartListening<T> _startListening;

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    throw StateError(
      '''updateShouldNotify is implemented internally by InheritedProviderElement''',
    );
  }

  @override
  InheritedProviderElement<T> createElement() =>
      InheritedProviderElement<T>(this);
}

/// An [Element] that uses an [InheritedProvider] as its configuration.
class InheritedProviderElement<T> extends InheritedElement {
  /// Creates an element that uses the given widget as its configuration.
  InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  InheritedProvider<T> get widget => super.widget as InheritedProvider<T>;

  bool _didInitValue = false;
  bool _debugInheritLocked = false;
  T _value;
  VoidCallback _removeListener;
  bool _shouldNotifyDependents = false;
  InheritedProvider<T> _previousWidget;

  /// The current value exposed by [InheritedProvider].
  ///
  /// If [InheritedProvider] was built using the default constructor and
  /// `initialValueBuilder` haven't been called yet, then reading [value]
  /// will call `initialValueBuilder`.
  T get value {
    if (widget._isStateful && !_didInitValue) {
      _didInitValue = true;
      assert(() {
        _debugInheritLocked = true;
        return true;
      }());
      if (widget._initialValueBuilder != null) {
        _value = widget._initialValueBuilder(this);

        assert(() {
          widget._debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
      assert(() {
        _debugInheritLocked = false;
        return true;
      }());
      if (widget._valueBuilder != null) {
        _value = widget._valueBuilder(this, _value);

        assert(() {
          widget._debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
    }

    _removeListener ??= widget._startListening?.call(this, _value);
    return _value;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    _value = widget._value;
    super.mount(parent, newSlot);
  }

  @override
  void updated(InheritedProvider<T> oldWidget) {
    if (!widget._isStateful) {
      bool shouldNotify;
      if (widget._updateShouldNotify != null) {
        shouldNotify = widget._updateShouldNotify(oldWidget._value, _value);
      } else {
        shouldNotify = oldWidget._value != _value;
      }

      if (shouldNotify) {
        if (_removeListener != null) {
          _removeListener();
          _removeListener = null;
        }

        notifyClients(oldWidget);
      }
    }
  }

  @override
  void update(InheritedProvider<T> newWidget) {
    final oldWidget = widget;
    final oldValue = _value;
    var shouldDispose = false;
    if (!newWidget._isStateful && oldWidget._isStateful) {
      if (_didInitValue) {
        shouldDispose = true;
        _didInitValue = false;
      }
    }
    if (oldWidget._isStateful != newWidget._isStateful) {
      _value = null;
      // since `value` is lazy loaded, it's not possible to compare the current
      // value with the upcoming one. Therefore we have to force an update on
      // dependents, so that they load the value if they need it.
      _shouldNotifyDependents = true;
      
      // TODO: test switch value to builder but with no dependent
      // -> builder not called
    }
    if (!newWidget._isStateful) {
      _value = newWidget._value;
    }

    super.update(newWidget);

    if (shouldDispose) {
      oldWidget._dispose?.call(this, oldValue);
    }
  }

  @override
  Widget build() {
    var shouldNotify = false;
    if (_didInitValue && widget._valueBuilder != null) {
      final previousValue = _value;
      _value = widget._valueBuilder(this, _value);

      shouldNotify = widget._updateShouldNotify != null
          ? widget._updateShouldNotify(previousValue, _value)
          : _value != previousValue;

      if (shouldNotify) {
        assert(() {
          widget._debugCheckInvalidValueType?.call(_value);
          return true;
        }());
        if (_removeListener != null) {
          _removeListener();
          _removeListener = null;
        }
        _previousWidget?._dispose?.call(this, previousValue);
      }
    }

    if (shouldNotify || _shouldNotifyDependents) {
      _shouldNotifyDependents = false;
      notifyClients(widget);
    }
    _previousWidget = widget;
    return super.build();
  }

  /// Mark the [InheritedProvider] as needing to update dependents.
  ///
  /// This bypass [InheritedWidget.updateShouldNotify] and will force widgets
  /// that depends on [T] to rebuild.
  void markNeedsNotifyDependents() {
    markNeedsBuild();
    _shouldNotifyDependents = true;
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

  @override
  void unmount() {
    super.unmount();
    _removeListener?.call();
    if (_didInitValue) {
      widget._dispose?.call(this, _value);
    }
  }
}
