import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);
typedef UpdateShouldNotifyDependent<T, Token> = bool Function(
    T previous, T current, Set<Token> dependencies);

// used to generate fake types for tags
class _Tag implements Type {
  final Object obj;

  _Tag(this.obj) : assert(obj != null);

  bool operator ==(Object other) {
    return other is _Tag && other.obj == obj;
  }

  @override
  int get hashCode => obj.hashCode;
}

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923
Type _typeOf<T>() => T;

mixin _Provider<T> on InheritedWidget {
  T get value;
  bool Function(T previous, T current) get shouldNotify;

  @override
  bool updateShouldNotify(_Provider<T> oldWidget) {
    if (shouldNotify != null) {
      return shouldNotify(oldWidget.value, value);
    }
    return oldWidget.value != value;
  }
}

T _of<T>(BuildContext context,
    {Object tag, Object aspect, bool listen = true}) {
  assert(aspect == null || listen == false);
  // this is required to get generic Type
  final type = tag != null ? _Tag(tag) : _typeOf<Provider<T>>();
  final _Provider<T> provider = listen
      ? context.inheritFromWidgetOfExactType(type, aspect: aspect)
      : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget;
  assert(provider?.value == null || provider?.value is T);
  return provider?.value;
}

InheritedElement _elementOf<T>(BuildContext context, {Object tag}) {
  Type type = tag != null ? _Tag(tag) : _typeOf<Provider<T>>();
  final element = context.ancestorInheritedElementForWidgetOfExactType(type);
  assert(() {
    final _Provider<T> provider = element?.widget;
    return provider?.value == null || provider?.value is T;
  }());
  return element;
}

/// An helper to easily exposes a value using [InheritedModel]
/// without having to write one.
class Provider<T> extends InheritedWidget with _Provider<T> {
  /// The value exposed to other widgets.
  ///
  /// You can obtain this value this widget's descendants
  /// using [Provider.of] method
  final T value;

  final Object tag;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedModel.updateShouldNotify] is called.
  /// It should return [false] when there's no need to update its dependents.
  ///
  /// The default behavior is `previous == current`
  @visibleForTesting
  final bool Function(T previous, T current) shouldNotify;

  Provider({
    this.tag,
    Key key,
    this.value,
    Widget child,
    this.shouldNotify,
  })  : runtimeType = tag != null ? _Tag(tag) : _typeOf<Provider<T>>(),
        super(key: key, child: child);

  @override
  final Type runtimeType;

  /// Obtain the nearest Provider<T> and returns its value.
  ///
  /// If [listen] is true (default), later value changes will
  /// trigger a new [build] to widgets, and [didChangeDependencies] for [StatefulWidget]
  static T of<T>(BuildContext context,
          {Object tag, Object aspect, bool listen = true}) =>
      _of(context, listen: listen, aspect: aspect, tag: tag);

  static InheritedElement elementOf<T>(BuildContext context, {Object tag}) =>
      _elementOf<T>(context, tag: tag);
}

class ModelProvider<T, Token> extends InheritedModel<Token> with _Provider<T> {
  /// The value exposed to other widgets.
  ///
  /// You can obtain this value this widget's descendants
  /// using [Provider.of] method
  final T value;

  final Object tag;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedModel.updateShouldNotify] is called.
  /// It should return [false] when there's no need to update its dependents.
  ///
  /// The default behavior is `previous == current`
  @visibleForTesting
  final bool Function(T previous, T current) shouldNotify;

  final bool Function(T previous, T current, Set<Token> dependencies)
      shouldNotifyDependent;

  ModelProvider({
    Key key,
    this.tag,
    this.value,
    Widget child,
    this.shouldNotify,
    this.shouldNotifyDependent,
  })  :
        // we voluntary overrides to Provider<T> so that it is compatible with `Provider.of`
        runtimeType = tag != null ? _Tag(tag) : _typeOf<Provider<T>>(),
        super(key: key, child: child);

  @override
  final Type runtimeType;

  @override
  bool updateShouldNotifyDependent(
      ModelProvider<T, Token> oldWidget, Set<Token> dependencies) {
    if (shouldNotifyDependent != null) {
      return shouldNotifyDependent(oldWidget.value, value, dependencies);
    }
    return true;
  }
}

/// A wrapper over [Provider] and [ModelProvider] to expose complex objets
///
/// It is usually used to create **not** recreate the provided value on every [build]
/// call, without having to manually create a [StatefulWidget]
///
/// ```
/// class Model {}
///
/// class Stateless extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return StatefulProvider<Model>(
///       valueBuilder: (context, old) =>  old ?? Model(),
///       child: ...,
///     );
///   }
/// }
/// ```
class StatefulProvider<T> extends StatefulWidget {
  /// [valueBuilder] is called on [initState] and [didUpdateWidget]
  /// [previous] is the previous value returned by [valueBuilder].
  /// [previous] is `null` on the first call
  /// Since it is called on [initState] and [didUpdateWidget], it is not
  /// possible to subscribe to an [InheritedWidget] using this method.
  /// Use [didChangeDependencies] instead.
  final T Function(BuildContext context, T previous) valueBuilder;

  /// [didChangeDependencies] is a hook to [State.didChangeDependencies]
  /// It can be used to build/update values depending on an [InheritedWidget]
  final T Function(BuildContext context, T value) didChangeDependencies;

  /// [onDispose] is a callback called when [StatefulProvider] is
  /// removed for the widget tree, and pass the current value as parameter.
  /// It is useful when the provided object needs to have a custom dipose behavior,
  /// such as closing streams.
  final void Function(BuildContext context, T value) onDispose;
  final Widget child;
  final bool Function(T previous, T current) shouldNotify;

  const StatefulProvider({
    Key key,
    this.valueBuilder,
    this.child,
    this.onDispose,
    this.didChangeDependencies,
    this.shouldNotify,
  })  : assert(valueBuilder != null || didChangeDependencies != null),
        super(key: key);

  @override
  _StatefulProviderState<T> createState() => _StatefulProviderState<T>();
}

class _StatefulProviderState<T> extends State<StatefulProvider<T>> {
  T _value;

  @override
  void initState() {
    super.initState();
    _buildValue();
  }

  @override
  void didUpdateWidget(StatefulProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildValue();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.didChangeDependencies != null) {
      _value = widget.didChangeDependencies(context, _value);
    }
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(context, _value);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      value: _value,
      shouldNotify: widget.shouldNotify,
      child: widget.child,
    );
  }

  void _buildValue() {
    if (widget.valueBuilder != null) {
      _value = widget.valueBuilder(context, _value);
    }
  }
}

class ValueListenableProvider<T> extends AnimatedWidget {
  final ValueListenable<T> valueListenable;
  final Widget child;

  final UpdateShouldNotify<T> _updateShouldNotify;

  ValueListenableProvider({
    Key key,
    UpdateShouldNotify<T> updateShouldNotify,
    this.child,
    this.valueListenable,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, listenable: valueListenable);

  @override
  Widget build(BuildContext context) {
    return Provider<T>(
      value: valueListenable.value,
      child: child,
    );
  }
}

class ValueListenableModelProvider<T, Token> extends AnimatedWidget {
  final ValueListenable<T> valueListenable;
  final Widget child;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedModel.updateShouldNotify] is called.
  /// It should return [false] when there's no need to update its dependents.
  ///
  /// The default behavior is `previous == current`
  final UpdateShouldNotify<T> _updateShouldNotify;

  final UpdateShouldNotifyDependent<T, Token> _updateShouldNotifyDependent;

  ValueListenableModelProvider({
    Key key,
    UpdateShouldNotify<T> shouldNotify,
    UpdateShouldNotifyDependent<T, Token> shouldNotifyDependent,
    this.child,
    this.valueListenable,
  })  : _updateShouldNotify = shouldNotify,
        _updateShouldNotifyDependent = shouldNotifyDependent,
        super(key: key, listenable: valueListenable);

  @override
  Widget build(BuildContext context) {
    return ModelProvider<T, Token>(
      value: valueListenable.value,
      shouldNotify: _updateShouldNotify,
      shouldNotifyDependent: _updateShouldNotifyDependent,
      child: child,
    );
  }
}
