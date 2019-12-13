import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:nested/nested.dart';

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

/// A generic implementation of an [InheritedWidget].
///
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
class InheritedProvider<T> extends InheritedWidget
    implements SingleChildWidget {
  /// Creates a value, then expose it to its descendants.
  ///
  /// The value will be disposed of when [InheritedProvider] is removed from
  /// the widget tree.
  InheritedProvider({
    Key key,
    Create<T> create,
    T update(BuildContext context, T value),
    UpdateShouldNotify<T> updateShouldNotify,
    void Function(T value) debugCheckInvalidValueType,
    StartListening<T> startListening,
    Dispose<T> dispose,
    Widget child,
  })  : _delegate = _CreateInheritedProvider(
          create: create,
          update: update,
          updateShouldNotify: updateShouldNotify,
          debugCheckInvalidValueType: debugCheckInvalidValueType,
          startListening: startListening,
          dispose: dispose,
        ),
        super(key: key, child: child);

  /// Expose to its descendants an existing value,
  InheritedProvider.value({
    Key key,
    @required T value,
    UpdateShouldNotify<T> updateShouldNotify,
    StartListening<T> startListening,
    Widget child,
  })  : _delegate = _ValueInheritedProvider(
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: startListening,
        ),
        super(key: key, child: child);

  InheritedProvider._constructor({
    Key key,
    _Delegate<T> delegate,
    Widget child,
  })  : _delegate = delegate,
        super(key: key, child: child);

  final _Delegate<T> _delegate;

  @override
  InheritedProviderElement<T> createElement() {
    return InheritedProviderElement(this);
  }

  // Necessary override so that subclasses can work with Provider.of.
  @override
  Type get runtimeType => _typeOf<InheritedProvider<T>>();

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegate.debugFillProperties(properties);
  }
}

/// An [Element] that uses an [InheritedProvider] as its configuration.
class InheritedProviderElement<T> extends InheritedElement
    with SingleChildWidgetElement, SingleChildInheritedElementMixin {
  /// Creates an element that uses the given widget as its configuration.
  InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  InheritedProvider<T> get widget => super.widget as InheritedProvider<T>;

  /// The current value exposed by [InheritedProvider].
  ///
  /// This property is lazy loaded, and reading it the first time may trigger
  /// some side-effects such as creating a [T] instance or start a subscription.
  T get value => _delegateState.value;

  bool _shouldNotifyDependents = false;
  bool _debugInheritLocked = false;
  bool _isNotifyDependentsEnabled = true;

  _DelegateState<T, _Delegate<T>> _delegateState;

  @override
  void mount(Element parent, dynamic newSlot) {
    _mountDelegate();
    _providerCount++;
    if (_providerCount == 1) {
      _startWatchingScheduler();
    }
    super.mount(parent, newSlot);
  }

  void _mountDelegate() {
    _delegateState = widget._delegate.createState()..element = this;
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

    if (widget._delegate.runtimeType != newWidget._delegate.runtimeType) {
      _providerCount--;
      throw StateError('''Rebuilt $widget using a different constructor.
      
This is likely a mistake and is unsupported.
If you're in this situation, consider passing a `key` unique to each individual constructor.
''');
    }
    _delegateState.willUpdateDelegate(
      newWidget._delegate,
      newWidget,
    );
    super.update(newWidget);
  }

  @override
  void unmount() {
    _providerCount--;
    _delegateState.dispose();
    super.unmount();
  }

  /// Marks the [InheritedProvider] as needing to update dependents.
  ///
  /// This bypass [InheritedWidget.updateShouldNotify] and will force widgets
  /// that depends on [T] to rebuild.
  void markNeedsNotifyDependents() {
    if (!_isNotifyDependentsEnabled) return;

    markNeedsBuild();
    _shouldNotifyDependents = true;
  }

  @override
  Widget build() {
    _delegateState.build();
    if (_shouldNotifyDependents) {
      _shouldNotifyDependents = false;
      notifyClients(widget);
    }
    return super.build();
  }

  bool _debugSetInheritedLock(bool value) {
    assert(() {
      _debugInheritLocked = value;
      return true;
    }());
    return true;
  }

  @override
  InheritedWidget dependOnInheritedElement(
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
    return super.dependOnInheritedElement(ancestor, aspect: aspect);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegateState.debugFillProperties(properties);
  }
}

@immutable
abstract class _Delegate<T> {
  _DelegateState<T, _Delegate<T>> createState();

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

abstract class _DelegateState<T, D extends _Delegate<T>> {
  InheritedProviderElement<T> element;

  T get value;

  D get delegate => element.widget._delegate as D;

  bool debugSetInheritedLock(bool value) {
    return element._debugSetInheritedLock(value);
  }

  void willUpdateDelegate(
    D newDelegate,
    InheritedProvider<T> newWidget,
  ) {}

  void dispose() {}

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  void build() {}
}

class _CreateInheritedProvider<T> extends _Delegate<T> {
  _CreateInheritedProvider({
    this.create,
    this.update,
    UpdateShouldNotify<T> updateShouldNotify,
    this.debugCheckInvalidValueType,
    this.startListening,
    this.dispose,
  })  : assert(create != null || update != null),
        _updateShouldNotify = updateShouldNotify;

  final Create<T> create;
  final T Function(BuildContext context, T value) update;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final void Function(T value) debugCheckInvalidValueType;
  final StartListening<T> startListening;
  final Dispose<T> dispose;

  @override
  _CreateInheritedProviderState<T> createState() =>
      _CreateInheritedProviderState();
}

class _CreateInheritedProviderState<T>
    extends _DelegateState<T, _CreateInheritedProvider<T>> {
  VoidCallback _removeListener;
  bool _didInitValue = false;
  T _value;
  _CreateInheritedProvider<T> _previousWidget;

  @override
  T get value {
    if (!_didInitValue) {
      _didInitValue = true;
      if (delegate.create != null) {
        assert(debugSetInheritedLock(true));
        _value = delegate.create(element);
        assert(debugSetInheritedLock(false));

        assert(() {
          delegate.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
      if (delegate.update != null) {
        _value = delegate.update(element, _value);

        assert(() {
          delegate.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
      }
    }

    element._isNotifyDependentsEnabled = false;
    _removeListener ??= delegate.startListening?.call(element, _value);
    element._isNotifyDependentsEnabled = true;
    assert(delegate.startListening == null || _removeListener != null);
    return _value;
  }

  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
    if (_didInitValue) {
      delegate.dispose?.call(element, _value);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_didInitValue) {
      properties
        ..add(DiagnosticsProperty('value', value))
        ..add(
          FlagProperty(
            null,
            value: _removeListener != null,
            defaultValue: false,
            ifTrue: 'listening to value',
          ),
        );
    } else {
      properties.add(
        FlagProperty(
          'value',
          value: true,
          showName: true,
          ifTrue: '<not yet loaded>',
        ),
      );
    }
  }

  @override
  void build() {
    @override
    var shouldNotify = false;
    if (_didInitValue && delegate.update != null) {
      final previousValue = _value;
      _value = delegate.update(element, _value);

      shouldNotify = delegate._updateShouldNotify != null
          ? delegate._updateShouldNotify(previousValue, _value)
          : _value != previousValue;

      if (shouldNotify) {
        assert(() {
          delegate.debugCheckInvalidValueType?.call(_value);
          return true;
        }());
        if (_removeListener != null) {
          _removeListener();
          _removeListener = null;
        }
        _previousWidget?.dispose?.call(element, previousValue);
      }
    }

    if (shouldNotify) {
      element._shouldNotifyDependents = true;
    }
    _previousWidget = delegate;
    return super.build();
  }
}

class _ValueInheritedProvider<T> extends _Delegate<T> {
  _ValueInheritedProvider({
    @required this.value,
    UpdateShouldNotify<T> updateShouldNotify,
    this.startListening,
  }) : _updateShouldNotify = updateShouldNotify;

  final T value;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final StartListening<T> startListening;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', value));
  }

  @override
  _ValueInheritedProviderState<T> createState() {
    return _ValueInheritedProviderState<T>();
  }
}

class _ValueInheritedProviderState<T>
    extends _DelegateState<T, _ValueInheritedProvider<T>> {
  VoidCallback _removeListener;

  @override
  T get value {
    element._isNotifyDependentsEnabled = false;
    _removeListener ??= delegate.startListening?.call(element, delegate.value);
    element._isNotifyDependentsEnabled = true;
    assert(delegate.startListening == null || _removeListener != null);
    return delegate.value;
  }

  @override
  void willUpdateDelegate(
    _ValueInheritedProvider<T> newDelegate,
    InheritedProvider<T> newWidget,
  ) {
    bool shouldNotify;
    if (delegate._updateShouldNotify != null) {
      shouldNotify = delegate._updateShouldNotify(
        delegate.value,
        newDelegate.value,
      );
    } else {
      shouldNotify = newDelegate.value != delegate.value;
    }

    if (shouldNotify) {
      if (_removeListener != null) {
        _removeListener();
        _removeListener = null;
      }

      element.notifyClients(newWidget);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        null,
        value: _removeListener != null,
        defaultValue: false,
        ifTrue: 'listening to value',
      ),
    );
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
  Widget child,
}) {
  assert(dispose == null || create != null);
  assert(value == null || create == null);

  if (create != null) {
    return DeferredInheritedProvider<T, R>(
      key: key,
      create: create,
      dispose: dispose,
      startListening: startListening,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }
  return DeferredInheritedProvider.value(
    key: key,
    value: value,
    startListening: startListening,
    updateShouldNotify: updateShouldNotify,
    child: child,
  );
}

abstract class _DeferredDelegate<T, R> extends _Delegate<R> {
  @override
  _DeferredDelegateState<T, R, _DeferredDelegate<T, R>> createState();
}

abstract class _DeferredDelegateState<T, R, W extends _DeferredDelegate<T, R>>
    extends _DelegateState<R, W> {
  @override
  DeferredInheritedProviderElement<T, R> get element =>
      super.element as DeferredInheritedProviderElement<T, R>;

  VoidCallback _removeListener;

  T get controller;

  R _value;
  @override
  R get value {
    // setState should be no-op inside startListening, as it's lazy-loaded
    // otherwise Flutter will throw an exception for no reason.
    element._isNotifyDependentsEnabled = false;
    _removeListener ??= element.widget._startListening(
      element,
      element.setState,
      controller,
      _value,
    );
    element._isNotifyDependentsEnabled = true;
    assert(element.hasValue, '''
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

  @override
  void dispose() {
    super.dispose();
    _removeListener?.call();
  }

  bool get isLoaded => _removeListener != null;
}

/// An [InheritedProvider] where the object listened is _not_ the object
/// emitted.
///
/// For example, for a stream provider, we'll want to listen to `Stream<T>`,
/// but expose `T` not the [Stream].

class DeferredInheritedProvider<T, R> extends InheritedProvider<R> {
  /// Lazily create an object automatically disposed when
  /// [DeferredInheritedProvider] is removed from the tree.
  ///
  /// The object create will be listened using `startListening`, and its content
  /// will be exposed to `child` and its descendants.
  DeferredInheritedProvider({
    Key key,
    @required Create<T> create,
    Dispose<T> dispose,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    Widget child,
  })  : _startListening = startListening,
        _updateShouldNotify = updateShouldNotify,
        super._constructor(
          key: key,
          child: child,
          delegate: _CreateDeferredInheritedProvider(
            create: create,
            dispose: dispose,
          ),
        );

  /// Listens to `value` and expose its content to `child` and its descendants.
  DeferredInheritedProvider.value({
    Key key,
    @required T value,
    @required DeferredStartListening<T, R> startListening,
    UpdateShouldNotify<R> updateShouldNotify,
    Widget child,
  })  : _startListening = startListening,
        _updateShouldNotify = updateShouldNotify,
        super._constructor(
          key: key,
          delegate: _ValueDeferredInheritedProvider<T, R>(value),
          child: child,
        );

  final DeferredStartListening<T, R> _startListening;
  final UpdateShouldNotify<R> _updateShouldNotify;

  @override
  DeferredInheritedProviderElement<T, R> createElement() {
    return DeferredInheritedProviderElement<T, R>(this);
  }
}

/// The element associated to [DeferredInheritedProvider].
///
/// It is responsible for updating dependents, managing subscriptions,
/// and creating/disposing [T].
class DeferredInheritedProviderElement<T, R>
    extends InheritedProviderElement<R> {
  /// Creates an element that uses the given widget as its configuration.
  DeferredInheritedProviderElement(DeferredInheritedProvider<T, R> widget)
      : super(widget);

  @override
  DeferredInheritedProvider<T, R> get widget =>
      super.widget as DeferredInheritedProvider<T, R>;

  /// The object listened (and potentially created/disposed) by
  /// [DeferredInheritedProvider], which will be used to control [value].
  T get controller => _delegateState.controller;

  bool _hasValue = false;

  @override
  _DeferredDelegateState<T, R, _DeferredDelegate<T, R>> get _delegateState {
    return super._delegateState
        as _DeferredDelegateState<T, R, _DeferredDelegate<T, R>>;
  }

  /// Wether [setState] was called at least once or not.
  ///
  /// It can be used by [DeferredStartListening] to differentiate between the
  /// very first listening, and a rebuild after [controller] changed.
  bool get hasValue => _hasValue;

  /// Update [value] and mark dependents as needing build.
  ///
  /// Contrarily to [markNeedsNotifyDependents], this method follows
  /// `InheritedProvider.updateShouldNotify` and will not rebuild dependents if
  /// the new value is the same as the previous one.
  void setState(R value) {
    if (_hasValue) {
      final shouldNotify = widget._updateShouldNotify != null
          ? widget._updateShouldNotify(_delegateState._value, value)
          : _delegateState._value != value;
      if (shouldNotify) {
        markNeedsNotifyDependents();
      }
    }
    _hasValue = true;
    _delegateState._value = value;
  }
}

class _CreateDeferredInheritedProvider<T, R> extends _DeferredDelegate<T, R> {
  _CreateDeferredInheritedProvider({@required this.create, this.dispose});

  final Create<T> create;
  final Dispose<T> dispose;

  @override
  _CreateDeferredInheritedProviderElement<T, R> createState() {
    return _CreateDeferredInheritedProviderElement<T, R>();
  }
}

class _CreateDeferredInheritedProviderElement<T, R>
    extends _DeferredDelegateState<T, R,
        _CreateDeferredInheritedProvider<T, R>> {
  bool _didBuild = false;

  T _controller;
  @override
  T get controller {
    if (!_didBuild) {
      assert(debugSetInheritedLock(true));
      _controller = delegate.create(element);
      _didBuild = true;
    }
    return _controller;
  }

  @override
  void dispose() {
    super.dispose();
    if (_didBuild) {
      delegate.dispose?.call(element, _controller);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (isLoaded) {
      properties
        ..add(DiagnosticsProperty('controller', controller))
        ..add(DiagnosticsProperty('value', value));
    } else {
      properties
        ..add(
          FlagProperty(
            'controller',
            value: true,
            showName: true,
            ifTrue: '<not yet loaded>',
          ),
        )
        ..add(
          FlagProperty(
            'value',
            value: true,
            showName: true,
            ifTrue: '<not yet loaded>',
          ),
        );
    }
  }
}

class _ValueDeferredInheritedProvider<T, R> extends _DeferredDelegate<T, R> {
  _ValueDeferredInheritedProvider(this.value);

  final T value;

  @override
  _ValueDeferredInheritedProviderState<T, R> createState() {
    return _ValueDeferredInheritedProviderState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('controller', value));
  }
}

class _ValueDeferredInheritedProviderState<T, R> extends _DeferredDelegateState<
    T, R, _ValueDeferredInheritedProvider<T, R>> {
  @override
  void willUpdateDelegate(
    _ValueDeferredInheritedProvider<T, R> oldDelegate,
    InheritedWidget oldWidget,
  ) {
    if (delegate.value != oldDelegate.value) {
      if (_removeListener != null) {
        _removeListener();
        _removeListener = null;
      }
      element.notifyClients(oldWidget);
    }
  }

  @override
  T get controller => delegate.value;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_removeListener != null) {
      properties.add(DiagnosticsProperty('value', value));
    } else {
      properties.add(
        FlagProperty(
          'value',
          value: true,
          showName: true,
          ifTrue: '<not yet loaded>',
        ),
      );
    }
  }
}
