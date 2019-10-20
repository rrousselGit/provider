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
  const InheritedProvider({
    Key key,
    @required ValueBuilder<T> initialValueBuilder,
    T valueBuilder(BuildContext context, T value),
    UpdateShouldNotify<T> updateShouldNotify,
    @required Widget child,
  })  : assert(initialValueBuilder != null),
        _value = null,
        _initialValueBuilder = initialValueBuilder,
        _valueBuilder = valueBuilder,
        _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// Expose to its descendants an existing value,
  const InheritedProvider.value({
    Key key,
    @required T value,
    UpdateShouldNotify<T> updateShouldNotify,
    @required Widget child,
  })  : _value = value,
        _initialValueBuilder = null,
        _valueBuilder = null,
        _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// The currently exposed value.
  ///
  /// Mutating `value` should be avoided. Instead rebuild the widget tree
  /// and replace [InheritedProvider] with one that holds the new value.
  final T _value;
  final ValueBuilder<T> _initialValueBuilder;
  final T Function(BuildContext context, T value) _valueBuilder;
  final UpdateShouldNotify<T> _updateShouldNotify;

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    if (_initialValueBuilder == null && _updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget._value, _value);
    }
    return oldWidget._value != _value;
  }

  @override
  InheritedProviderElement<T> createElement() =>
      InheritedProviderElement<T>(this);
}

class InheritedProviderElement<T> extends InheritedElement {
  InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  InheritedProvider<T> get widget => super.widget as InheritedProvider<T>;

  bool get _isStateful => widget._initialValueBuilder != null;
  bool _didInitValue = false;
  bool _debugInheritLocked = false;
  T _value;

  /// The current value exposed by [InheritedProvider].
  ///
  /// If [InheritedProvider] was built using the default constructor and
  /// `initialValueBuilder` haven't been called yet, then reading [value]
  /// will call `initialValueBuilder`.
  T get value {
    if (_isStateful && !_didInitValue) {
      _didInitValue = true;
      assert(() {
        _debugInheritLocked = true;
        return true;
      }());
      _value = widget._initialValueBuilder(this);
      if (widget._valueBuilder != null) {
        _value = widget._valueBuilder(this, _value);
      }
      assert(() {
        _debugInheritLocked = false;
        return true;
      }());
    }
    return _value;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    _value = widget._value;
    super.mount(parent, newSlot);
  }

  @override
  void update(InheritedProvider<T> newWidget) {
    if (!_isStateful) {
      _value = newWidget._value;
    }
    super.update(newWidget);
  }

  @override
  Widget build() {
    if (_didInitValue && widget._valueBuilder != null) {
      final previousValue = _value;
      _value = widget._valueBuilder(this, _value);

      final shouldNotify = widget._updateShouldNotify != null
          ? widget._updateShouldNotify(previousValue, _value)
          : _value != previousValue;
      if (shouldNotify) {
        notifyClients(widget);
      }
    }
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
