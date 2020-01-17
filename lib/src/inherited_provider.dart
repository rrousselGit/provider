part of 'provider.dart';

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
/// [InheritedContext.value]). And the returned callback will be called
/// when [InheritedProvider] is unmounted or when the it is rebuilt with a new
/// value.
///
/// See also:
///
/// - [InheritedProvider]
/// - [DeferredStartListening], a variant of this typedef for more advanced
///   listening.
typedef StartListening<T> = VoidCallback Function(InheritedContext<T> element, T value);

/// A generic implementation of an [InheritedWidget].
///
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
class InheritedProvider<T> extends SingleChildStatelessWidget {
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
    ValueWidgetBuilder<T> builder,
    bool lazy,
    Widget child,
  })  : _lazy = lazy,
        _builder = builder,
        _delegate = _CreateInheritedProvider(
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
    bool lazy,
    ValueWidgetBuilder<T> builder,
    Widget child,
  })  : _lazy = lazy,
        _builder = builder,
        _delegate = _ValueInheritedProvider(
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: startListening,
        ),
        super(key: key, child: child);

  InheritedProvider._constructor({
    Key key,
    _Delegate<T> delegate,
    bool lazy,
    ValueWidgetBuilder<T> builder,
    Widget child,
  })  : _lazy = lazy,
        _builder = builder,
        _delegate = delegate,
        super(key: key, child: child);

  final _Delegate<T> _delegate;
  final bool _lazy;
  final ValueWidgetBuilder<T> _builder;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _delegate.debugFillProperties(properties);
  }

  @override
  _InheritedProviderElement<T> createElement() {
    return _InheritedProviderElement<T>(this);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return _DefaultInheritedProviderScope<T>(
      owner: this,
      child: _builder != null
          ? Builder(
              builder: (context) {
                return _builder(context, Provider.of<T>(context), child);
              },
            )
          : child,
    );
  }
}

class _InheritedProviderElement<T> extends SingleChildStatelessElement {
  _InheritedProviderElement(InheritedProvider<T> widget) : super(widget);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    visitChildren((e) {
      e.debugFillProperties(properties);
    });
  }
}

/// Adds a `select` method on [BuildContext].
extension SelectContext on BuildContext {
  /// Watch a value of type [T] exposed from a provider, and listen only partially
  /// to changes.
  ///
  /// By using [select], instead of watching the entire object, the listener will
  /// rebuild only if the value returned by `selector` changes.
  ///
  /// When a provider emits an update, it will call synchronously all `selector`.
  ///
  /// Then, if they return a value different from the previously returned value,
  /// the dependent will be marked as needing to rebuild.
  ///
  /// For example, consider the following object:
  ///
  /// ```dart
  /// class Person with ChangeNotifier {
  ///   String name;
  ///   int age;
  ///
  ///   // Add some logic that may update `name` and `age`
  /// }
  /// ```
  ///
  /// Then a widget may want to listen to a person's `name` without listening
  /// to its `age`.
  ///
  /// This cannot be done using `context.watch`/[Provider.of]. Instead, we
  /// can use [select], by writing the following:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final name = context.select((Person p) => p.name);
  ///
  ///   return Text(name);
  /// }
  /// ```
  ///
  /// It is fine to call `select` multiple times, but there's a catch.
  /// Each individual [select] must either:
  ///
  /// - use a different provider:
  ///
  ///  `Provider.of<Person>(context)` vs `Provider.of<City>(context)`
  /// - select a different type:
  ///
  ///  *OK*:
  ///   ```dart
  ///   final String name = context.select((Person p) => p.name);
  ///   final int age = context.select((Person p) => p.age);
  ///   ```
  ///   We can select two values from `Person`, because they are from two different
  ///   types.
  ///
  ///   *OK*:
  ///   ```dart
  ///   final String personName = context.select((Person p) => p.name);
  ///   final String cityName = context.select((City p) => p.name);
  ///   ```
  ///   We can select `String` twice here, person one of them is from a `Person`
  ///   and another one is from `City`.
  ///
  ///   *BAD*:
  ///   ```dart
  ///   final bool hasName = context.select((Person p) => p.hasName);
  ///   final bool hasAge = context.select((Person p) => p.hasAge);
  ///   ```
  ///   This won't work, because we selected two `bool` from `Person`.
  ///
  ///   Instead, if you need such thing, you can give a "key" to [select]:
  ///   ```dart
  ///   final bool hasName = context.select((Person p) => p.hasName, 0);
  ///   final bool hasAge = context.select((Person p) => p.hasAge, 1);
  ///   ```
  ///
  ///   This time, the example works, because we gave each [select] a unique
  ///   identifier (here `0` and `1`).
  R select<T, R>(R selector(T value), [Object key]) {
    final inheritedElement = Provider._inheritedElementOf<T>(this);
    final selected = selector(inheritedElement.value);
    dependOnInheritedElement(
      inheritedElement,
      aspect: _SelectorAspect(selector, selected, key),
    );
    return selected;
  }
}

/// A [BuildContext] associated to an [InheritedProvider].
///
/// It an extra [markNeedsNotifyDependents] method and the exposed value.
abstract class InheritedContext<T> extends BuildContext {
  /// The current value exposed by [InheritedProvider].
  ///
  /// This property is lazy loaded, and reading it the first time may trigger
  /// some side-effects such as creating a [T] instance or start a subscription.
  T get value;

  /// Marks the [InheritedProvider] as needing to update dependents.
  ///
  /// This bypass [InheritedWidget.updateShouldNotify] and will force widgets
  /// that depends on [T] to rebuild.
  void markNeedsNotifyDependents();

  /// Wether `setState` was called at least once or not.
  ///
  /// It can be used by [DeferredStartListening] to differentiate between the
  /// very first listening, and a rebuild after `controller` changed.
  bool get hasValue;
}

class _DefaultInheritedProviderScope<T> extends InheritedWidget {
  _DefaultInheritedProviderScope({
    this.owner,
    @required Widget child,
  }) : super(child: child);

  final InheritedProvider<T> owner;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  @override
  _DefaultInheritedProviderScopeElement<T> createElement() {
    return _DefaultInheritedProviderScopeElement<T>(this);
  }
}

class _DefaultInheritedProviderScopeElement<T> extends InheritedElement with _InheritedProviderScopeMixin<T> {
  _DefaultInheritedProviderScopeElement(_DefaultInheritedProviderScope<T> widget) : super(widget);

  @override
  _DefaultInheritedProviderScope<T> get widget => super.widget as _DefaultInheritedProviderScope<T>;

  @override
  bool _isLazy(_DefaultInheritedProviderScope<T> widget) => widget.owner._lazy;

  @override
  _DelegateState<T, _Delegate<T>> _delegateState;

  @override
  _Delegate<T> _widgetToDelegate(_DefaultInheritedProviderScope<T> widget) {
    return widget.owner._delegate;
  }

  @override
  void _mountDelegate() {
    _delegateState = widget.owner._delegate.createState()..element = this;
  }
}

class _SelectorAspect<T, R> {
  _SelectorAspect(this.selector, this.selected, [Object key]) : type = key ?? R;

  final R Function(T value) selector;
  final R selected;

  final Object type;
}

mixin _InheritedProviderScopeMixin<T> on InheritedElement implements InheritedContext<T> {
  bool _shouldNotifyDependents = false;
  bool _debugInheritLocked = false;
  bool _isNotifyDependentsEnabled = true;
  bool _firstBuild = true;

  Map<Element, Set<Object>> _debugSelectedKeysWithinFrame;

  @override
  void updateDependencies(Element dependent, Object aspect) {
    final dependencies = getDependencies(dependent) as Map<Object, _SelectorAspect<T, Object>>;
    // once subscribed to everything once, it always stays subscribed to everything
    if (dependencies != null && dependencies.isEmpty) return;

    if (aspect is _SelectorAspect<T, Object>) {
      assert(() {
        if (_debugSelectedKeysWithinFrame?.containsKey(dependent) ?? false) {
          final selectedKeysThisFrame = _debugSelectedKeysWithinFrame[dependent];

          assert(selectedKeysThisFrame?.contains(aspect.type) != true);
        }
        return true;
      }());
      assert(() {
        _debugSelectedKeysWithinFrame ??= {};
        _debugSelectedKeysWithinFrame[dependent] ??= {};
        _debugSelectedKeysWithinFrame[dependent].add(aspect.type);

        Future.microtask(() {
          _debugSelectedKeysWithinFrame = null;
        });
        return true;
      }());

      final newDependencies = dependencies ?? HashMap();

      newDependencies[aspect.type] = aspect;
      setDependencies(dependent, newDependencies);
    } else {
      // subscribes to everything
      setDependencies(dependent, HashMap<Object, _SelectorAspect<T, Object>>());
    }
  }

  @override
  void notifyDependent(InheritedWidget oldWidget, Element dependent) {
    final dependencies = getDependencies(dependent) as Map<Object, _SelectorAspect<T, Object>>;

    var shouldNotify = false;
    if (dependencies != null) {
      if (dependencies.isEmpty) {
        shouldNotify = true;
      } else {
        for (final dependency in dependencies.values) {
          if (dependency.selector(value) != dependency.selected) {
            shouldNotify = true;
            break;
          }
        }
      }
    }
    if (shouldNotify) {
      dependent.didChangeDependencies();
    }
  }

  void _mountDelegate();

  _Delegate<T> _widgetToDelegate(covariant InheritedWidget widget);

  _DelegateState<T, _Delegate<T>> get _delegateState;

  bool _isLazy(covariant InheritedWidget widget);

  @override
  bool get hasValue => _delegateState.hasValue;

  @override
  void performRebuild() {
    if (_firstBuild) {
      _firstBuild = false;
      _mountDelegate();
    }
    super.performRebuild();
  }

  bool _updatedShouldNotify = false;
  bool _isBuildFromExternalSources = false;
  @override
  void update(InheritedWidget newWidget) {
    assert(() {
      if (_widgetToDelegate(widget).runtimeType != _widgetToDelegate(newWidget).runtimeType) {
        throw StateError('''Rebuilt $widget using a different constructor.
      
This is likely a mistake and is unsupported.
If you're in this situation, consider passing a `key` unique to each individual constructor.
''');
      }
      return true;
    }());

    _isBuildFromExternalSources = true;
    _updatedShouldNotify = _delegateState.willUpdateDelegate(_widgetToDelegate(newWidget));
    super.update(newWidget);
    _updatedShouldNotify = false;
  }

  @override
  void updated(InheritedWidget oldWidget) {
    super.updated(oldWidget);
    if (_updatedShouldNotify) {
      notifyClients(oldWidget);
    }
  }

  @override
  void didChangeDependencies() {
    _isBuildFromExternalSources = true;
    super.didChangeDependencies();
  }

  @override
  void unmount() {
    _delegateState.dispose();
    super.unmount();
  }

  @override
  void markNeedsNotifyDependents() {
    if (!_isNotifyDependentsEnabled) return;

    markNeedsBuild();
    _shouldNotifyDependents = true;
  }

  @override
  Widget build() {
    if (_isLazy(widget) == false) {
      value; // this will force the value to be computed.
    }
    _delegateState.build(_isBuildFromExternalSources);
    _isBuildFromExternalSources = false;
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
  T get value => _delegateState.value;

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
  _InheritedProviderScopeMixin<T> element;

  T get value;

  D get delegate => element._widgetToDelegate(element.widget) as D;

  bool get hasValue;

  bool debugSetInheritedLock(bool value) {
    return element._debugSetInheritedLock(value);
  }

  bool willUpdateDelegate(D newDelegate) => false;

  void dispose() {}

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  void build(bool isBuildFromExternalSources) {}
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
  _CreateInheritedProviderState<T> createState() => _CreateInheritedProviderState();
}

bool _debugIsInInheritedProviderUpdate = false;

class _CreateInheritedProviderState<T> extends _DelegateState<T, _CreateInheritedProvider<T>> {
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
        assert(() {
          _debugIsInInheritedProviderUpdate = true;
          return true;
        }());
        _value = delegate.update(element, _value);
        assert(() {
          _debugIsInInheritedProviderUpdate = false;
          return true;
        }());

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
  void build(bool isBuildFromExternalSources) {
    var shouldNotify = false;
    // Don't call `update` unless the build was triggered from `updated`/`didChangeDependencies`
    // otherwise `markNeedsNotifyDependents` will trigger unnecessary `update` calls
    if (isBuildFromExternalSources && _didInitValue && delegate.update != null) {
      final previousValue = _value;
      _value = delegate.update(element, _value);

      if (delegate._updateShouldNotify != null) {
        shouldNotify = delegate._updateShouldNotify(previousValue, _value);
      } else {
        shouldNotify = _value != previousValue;
      }

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
    return super.build(isBuildFromExternalSources);
  }

  @override
  bool get hasValue => _didInitValue != null;
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

class _ValueInheritedProviderState<T> extends _DelegateState<T, _ValueInheritedProvider<T>> {
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
  bool willUpdateDelegate(_ValueInheritedProvider<T> newDelegate) {
    bool shouldNotify;
    if (delegate._updateShouldNotify != null) {
      shouldNotify = delegate._updateShouldNotify(
        delegate.value,
        newDelegate.value,
      );
    } else {
      shouldNotify = newDelegate.value != delegate.value;
    }

    if (shouldNotify && _removeListener != null) {
      _removeListener();
      _removeListener = null;
    }
    return shouldNotify;
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

  @override
  bool get hasValue => true;
}
