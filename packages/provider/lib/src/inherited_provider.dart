import 'dart:async';

import 'package:flutter/scheduler.dart';
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
///  * [Dispose], to free the resources associated to the value created.
typedef Create<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
///
/// See also:
///
///  * [Create], to create a value that will later be disposed of.
typedef Dispose<T> = void Function(BuildContext context, T value);

/// A callback used to start the listening of an object and return a function
/// that cancels the subscription.
///
/// It is called the first time the value is obtained (through
/// [InheritedProviderElement.value]). And the returned callback will be called
/// when [InheritedProvider] is unmounted or when the it is rebuilt with a new
/// value.
///
/// See also:
///
/// - [InheritedProvider]
/// - [DeferredStartListening], a variant of this typedef for more advanced
///   listening.
typedef StartListening<T> = VoidCallback Function(
    InheritedProviderElement<T> element, T value);

/// A callback used to handle the subscription of `controller`.
///
/// It is expected to start the listening process and return a callback
/// that will later be used to stop that listening.
///
/// See also:
///
/// - [DeferredInheritedProvider]
/// - [StartListening], a simpler version of this typedef.
typedef DeferredStartListening<T, R> = VoidCallback Function(
  DeferredInheritedProviderElement<T, R> context,
  void Function(R value) setState,
  T controller,
  R value,
);

/// A generic implementation of an [InheritedWidget].
///
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
abstract class InheritedProvider<T> extends InheritedWidget {
  /// Creates a value, then expose it to its descendants.
  ///
  /// The value will be disposed of when [InheritedProvider] is removed from
  /// the widget tree.
  factory InheritedProvider({
    Key key,
    Create<T> create,
    T update(BuildContext context, T value),
    UpdateShouldNotify<T> updateShouldNotify,
    void Function(T value) debugCheckInvalidValueType,
    StartListening<T> startListening,
    Dispose<T> dispose,
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

  // Necessary override so that subclasses can work with Provider.of.
  @override
  Type get runtimeType => _typeOf<InheritedProvider<T>>();
}

Type _typeOf<T>() => T;

/// Express if the widget tree is currently being updated.
bool get isWidgetTreeBuilding => _isWidgetTreeBuilding;

bool _isWidgetTreeBuilding = false;
int _frameId;
// we track the number of providers in the widget tree, such that when all of
// them are disposed, we can stop scheduling frames.
//
// This is a requirement for testWidgets, as it would otherwise fail if there's
// an uncancelled frame callback.
int _providerCount = 0;

void _startWatchingScheduler() {
  _isWidgetTreeBuilding = true;

  final endFrameCallback = (Duration _) {
    _isWidgetTreeBuilding = false;
    if (_providerCount == 0 && _frameId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_frameId);
      _frameId = null;
    }
  };

  void Function(Duration) startFrameCallback;
  startFrameCallback = (Duration _) {
    _isWidgetTreeBuilding = true;

    SchedulerBinding.instance.addPostFrameCallback(endFrameCallback);

    _frameId = SchedulerBinding.instance.scheduleFrameCallback(
      startFrameCallback,
      rescheduling: true,
    );
  };

  _frameId = SchedulerBinding.instance.scheduleFrameCallback(
    startFrameCallback,
  );
  SchedulerBinding.instance.addPostFrameCallback(endFrameCallback);
}

/// An [Element] that uses an [InheritedProvider] as its configuration.
abstract class InheritedProviderElement<T> extends InheritedElement {
  /// Creates an element that uses the given widget as its configuration.
  InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  InheritedProvider<T> get widget => super.widget as InheritedProvider<T>;

  /// The current value exposed by [InheritedProvider].
  ///
  /// This property is lazy loaded, and reading it the first time may trigger
  /// some side-effects such as creating a [T] instance or start a subscription.
  T get value;

  bool _shouldNotifyDependents = false;
  bool _debugInheritLocked = false;

  @override
  void mount(Element parent, dynamic newSlot) {
    _providerCount++;
    if (_providerCount == 1) {
      _startWatchingScheduler();
    }
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _providerCount--;
    super.unmount();
  }

  /// Marks the [InheritedProvider] as needing to update dependents.
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

  @override
  void update(InheritedProvider<T> newWidget) {
    assert(() {
      if (widget.createElement.runtimeType !=
          newWidget.createElement.runtimeType) {
        _providerCount--;

        throw StateError('''
InheritedProvider was rebuilt with a different kind of provider.

This is unsupported. If you need to switch between types of providers consider
passing a different "key" to each type of provider.
''');
      }
      return true;
    }());
    super.update(newWidget);
  }

  bool _debugSetInheritedLock(bool value) {
    assert(() {
      _debugInheritLocked = value;
      return true;
    }());
    return true;
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
- the "create" callback of a provider

This is undesired because these life-cycles are called only once in the
lifetime of a widget. As such, while `listen` is `true`, the widget has
no mean to handle the update scenario.

To fix, consider:
- passing `listen: false` to `Provider.of`
- use a life-cycle that handles updates (like didChangeDependencies)
- use a provider that handles updates (like ProxyProvider).
'''),
          ],
        );
      }
      return true;
    }());
    return super.inheritFromElement(ancestor, aspect: aspect);
  }
}

class _CreateInheritedProvider<T> extends InheritedProvider<T> {
  _CreateInheritedProvider({
    Key key,
    this.create,
    this.update,
    UpdateShouldNotify<T> updateShouldNotify,
    this.debugCheckInvalidValueType,
    this.startListening,
    this.dispose,
    @required Widget child,
  })  : assert(create != null || update != null),
        _updateShouldNotify = updateShouldNotify,
        super._constructor(key: key, child: child);

  final Create<T> create;
  final T Function(BuildContext context, T value) update;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final void Function(T value) debugCheckInvalidValueType;
  final StartListening<T> startListening;
  final Dispose<T> dispose;

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
  T _value;
  _CreateInheritedProvider<T> _previousWidget;

  @override
  T get value {
    if (!_didInitValue) {
      _didInitValue = true;
      if (widget.create != null) {
        assert(_debugSetInheritedLock(true));
        _value = widget.create(this);
        assert(_debugSetInheritedLock(false));

        assert(() {
          widget.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
      if (widget.update != null) {
        _value = widget.update(this, _value);

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
    if (_didInitValue && widget.update != null) {
      final previousValue = _value;
      _value = widget.update(this, _value);

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

/// Listens to an object and expose its internal state to `child`.
DeferredInheritedProvider<T, R> autoDeferred<T, R>({
  Key key,
  @required Create<T> create,
  Dispose<T> dispose,
  @required T value,
  @required DeferredStartListening<T, R> startListening,
  UpdateShouldNotify<R> updateShouldNotify,
  @required Widget child,
}) {
  assert(dispose == null || create != null);
  assert(value == null || create == null);

  if (create != null) {
    return _CreateDeferredInheritedProvider(
      key: key,
      create: create,
      dispose: dispose,
      startListening: startListening,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }
  return _ValueDeferredInheritedProvider(
    key: key,
    value: value,
    startListening: startListening,
    updateShouldNotify: updateShouldNotify,
    child: child,
  );
}

/// An [InheritedProvider] where the object listened is _not_ the object
/// emitted.
///
/// For example, for a stream provider, we'll want to listen to `Stream<T>`,
/// but expose `T` not the [Stream].
abstract class DeferredInheritedProvider<T, R> extends InheritedProvider<R> {
  DeferredInheritedProvider._constructor({
    Key key,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    @required Widget child,
  })  : assert(startListening != null),
        assert(child != null),
        _startListening = startListening,
        _updateShouldNotify = updateShouldNotify,
        super._constructor(key: key, child: child);

  /// Lazily create an object automatically disposed when
  /// [DeferredInheritedProvider] is removed from the tree.
  ///
  /// The object create will be listened using `startListening`, and its content
  /// will be exposed to `child` and its descendants.
  factory DeferredInheritedProvider({
    Key key,
    @required Create<T> create,
    Dispose<T> dispose,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    @required Widget child,
  }) = _CreateDeferredInheritedProvider<T, R>;

  /// Listens to `value` and expose its content to `child` and its descendants.
  factory DeferredInheritedProvider.value({
    Key key,
    @required T value,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    @required Widget child,
  }) = _ValueDeferredInheritedProvider<T, R>;

  final DeferredStartListening<T, R> _startListening;
  final UpdateShouldNotify<R> _updateShouldNotify;

  @override
  DeferredInheritedProviderElement<T, R> createElement();

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    throw StateError(
      '''updateShouldNotify is implemented internally by InheritedProviderElement''',
    );
  }
}

/// The element associated to [DeferredInheritedProvider].
///
/// It is responsible for updating dependents, managing subscriptions,
/// and creating/disposing [T].
abstract class DeferredInheritedProviderElement<T, R>
    extends InheritedProviderElement<R> {
  /// Creates an element that uses the given widget as its configuration.
  DeferredInheritedProviderElement(DeferredInheritedProvider<T, R> widget)
      : super(widget);

  @override
  DeferredInheritedProvider<T, R> get widget =>
      super.widget as DeferredInheritedProvider<T, R>;

  VoidCallback _removeListener;

  R _value;
  @override
  R get value {
    // setState should be no-op inside startListening, as it's lazy-loaded
    // otherwise Flutter will throw an exception for no reason.
    _setStateShouldNotify = false;
    _removeListener ??=
        widget._startListening(this, setState, controller, _value);
    _setStateShouldNotify = true;
    assert(hasValue, '''
The callback "startListening" was called, but it left DeferredInhertitedProviderElement<$T, $R>
in an unitialized state.

It is necessary for "startListening" to call "setState" at least once the very
first time "value" is requested.

To fix, consider:

DeferredInheritedProvider(
  ...,
  startListening: (element, setState, controller, value) {
    if (!element.hasValue) {
      setState(myInitialValue); // TODO replace myInitialValue with your own
    }
    ...
  }
)
    ''');
    assert(_removeListener != null);
    return _value;
  }

  /// The object listened (and potentially created/disposed) by
  /// [DeferredInheritedProvider], which will be used to control [value].
  T get controller;

  bool _hasValue = false;

  /// Wether [setState] was called at least once or not.
  ///
  /// It can be used by [DeferredStartListening] to differentiate between the
  /// very first listening, and a rebuild after [controller] changed.
  bool get hasValue => _hasValue;

  var _setStateShouldNotify = true;

  /// Update [value] and mark dependents as needing build.
  ///
  /// Contrarily to [markNeedsNotifyDependents], this method follows
  /// [InheritedProvider.updateShouldNotify] and will not rebuild dependents if
  /// the new value is the same as the previous one.
  void setState(R value) {
    if (_setStateShouldNotify && _hasValue) {
      final shouldNotify = widget._updateShouldNotify != null
          ? widget._updateShouldNotify(_value, value)
          : _value != value;
      if (shouldNotify) {
        markNeedsNotifyDependents();
      }
    }
    _hasValue = true;
    _value = value;
  }

  @override
  void unmount() {
    super.unmount();
    _removeListener?.call();
  }
}

class _CreateDeferredInheritedProvider<T, R>
    extends DeferredInheritedProvider<T, R> {
  _CreateDeferredInheritedProvider({
    Key key,
    @required this.create,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    this.dispose,
    @required Widget child,
  }) : super._constructor(
          key: key,
          startListening: startListening,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  final Create<T> create;
  final Dispose<T> dispose;

  @override
  _CreateDeferredInheritedProviderElement<T, R> createElement() =>
      _CreateDeferredInheritedProviderElement(this);
}

class _CreateDeferredInheritedProviderElement<T, R>
    extends DeferredInheritedProviderElement<T, R> {
  _CreateDeferredInheritedProviderElement(
      _CreateDeferredInheritedProvider<T, R> widget)
      : super(widget);

  @override
  _CreateDeferredInheritedProvider<T, R> get widget =>
      super.widget as _CreateDeferredInheritedProvider<T, R>;

  bool _didBuild = false;

  T _controller;
  @override
  T get controller {
    if (!_didBuild) {
      assert(_debugSetInheritedLock(true));
      _controller = widget.create(this);
      _didBuild = true;
    }
    return _controller;
  }

  @override
  void unmount() {
    super.unmount();
    if (_didBuild) {
      widget.dispose?.call(this, _controller);
    }
  }
}

class _ValueDeferredInheritedProvider<T, R>
    extends DeferredInheritedProvider<T, R> {
  _ValueDeferredInheritedProvider({
    Key key,
    @required this.value,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    @required Widget child,
  }) : super._constructor(
          key: key,
          startListening: startListening,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  final T value;

  @override
  _ValueDeferredInheritedProviderElement<T, R> createElement() =>
      _ValueDeferredInheritedProviderElement(this);
}

class _ValueDeferredInheritedProviderElement<T, R>
    extends DeferredInheritedProviderElement<T, R> {
  _ValueDeferredInheritedProviderElement(
      _ValueDeferredInheritedProvider<T, R> widget)
      : super(widget);

  @override
  _ValueDeferredInheritedProvider<T, R> get widget =>
      super.widget as _ValueDeferredInheritedProvider<T, R>;

  @override
  void updated(_ValueDeferredInheritedProvider<T, R> oldWidget) {
    if (widget.value != oldWidget.value) {
      if (_removeListener != null) {
        _removeListener();
        _removeListener = null;
      }
      notifyClients(widget);
    }
  }

  @override
  T get controller => widget.value;
}
