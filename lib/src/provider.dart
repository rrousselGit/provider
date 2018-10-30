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
  UpdateShouldNotify<T> get shouldNotify;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedModel.updateShouldNotify] is called.
  /// It should return [false] when there's no need to update its dependents.
  ///
  /// The default behavior is `previous != current`
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
  final UpdateShouldNotify<T> shouldNotify;

  Provider({
    this.tag,
    Key key,
    this.value,
    Widget child,
    UpdateShouldNotify<T> updateShouldNotify,
  })  : shouldNotify = updateShouldNotify,
        runtimeType = tag != null ? _Tag(tag) : _typeOf<Provider<T>>(),
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
  final UpdateShouldNotify<T> shouldNotify;

  final UpdateShouldNotifyDependent<T, Token> shouldNotifyDependent;

  ModelProvider({
    Key key,
    this.tag,
    this.value,
    Widget child,
    UpdateShouldNotify<T> updateShouldNotify,
    UpdateShouldNotifyDependent<T, Token> updateShouldNotifyDependent,
  })  : shouldNotify = updateShouldNotify,
        shouldNotifyDependent = updateShouldNotifyDependent,
        // we voluntary overrides to Provider<T> so that it is compatible with `Provider.of`
        runtimeType = tag != null ? _Tag(tag) : _typeOf<Provider<T>>(),
        super(key: key, child: child);

  @override
  final Type runtimeType;

  static InheritedModelElement elementOf(BuildContext context, {Object tag}) {
    final e = _elementOf(context, tag: tag);
    assert(e is InheritedModelElement);
    return e;
  }

  @override
  bool updateShouldNotifyDependent(
    ModelProvider<T, Token> oldWidget,
    Set<Token> dependencies,
  ) {
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
  final bool Function(T previous, T current) updateShouldNotify;
  final Object tag;

  const StatefulProvider({
    Key key,
    this.valueBuilder,
    this.child,
    this.onDispose,
    this.didChangeDependencies,
    this.updateShouldNotify,
    this.tag,
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
      updateShouldNotify: widget.updateShouldNotify,
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

  final UpdateShouldNotify<T> updateShouldNotify;

  ValueListenableProvider({
    Key key,
    this.updateShouldNotify,
    this.child,
    this.valueListenable,
  }) : super(key: key, listenable: valueListenable);

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

  final UpdateShouldNotify<T> updateShouldNotify;
  final UpdateShouldNotifyDependent<T, Token> updateShouldNotifyDependent;

  ValueListenableModelProvider({
    Key key,
    this.updateShouldNotify,
    this.updateShouldNotifyDependent,
    this.child,
    this.valueListenable,
  }) : super(key: key, listenable: valueListenable);

  @override
  Widget build(BuildContext context) {
    return ModelProvider<T, Token>(
      value: valueListenable.value,
      updateShouldNotify: updateShouldNotify,
      updateShouldNotifyDependent: updateShouldNotifyDependent,
      child: child,
    );
  }
}

abstract class _StreamProvider<T>
    extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  /// Creates a new [StreamBuilder] that builds itself based on the latest
  /// snapshot of interaction with the specified [stream] and whose build
  /// strategy is given by [builder]. The [initialData] is used to create the
  /// initial snapshot. It is null by default.
  const _StreamProvider({
    Key key,
    this.initialData,
    Stream<T> stream,
  }) : super(key: key, stream: stream);

  /// The data that will be used to create the initial snapshot. Null by default.
  final T initialData;

  @override
  AsyncSnapshot<T> initial() =>
      AsyncSnapshot<T>.withData(ConnectionState.none, initialData);

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  @override
  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) {
    return AsyncSnapshot<T>.withError(ConnectionState.active, error);
  }

  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.done);

  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary);
}

class StreamProvider<T> extends _StreamProvider<T> {
  final Widget child;
  final Object tag;
  final UpdateShouldNotify<AsyncSnapshot<T>> updateShouldNotify;

  const StreamProvider({
    this.tag,
    Key key,
    T initialData,
    this.updateShouldNotify,
    Stream<T> stream,
    this.child,
  }) : super(key: key, stream: stream);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    return Provider<AsyncSnapshot<T>>(
      tag: tag,
      child: child,
      value: currentSummary,
      updateShouldNotify: updateShouldNotify,
    );
  }
}

class StreamModelProvider<T, Token> extends _StreamProvider<T> {
  final Widget child;
  final Object tag;
  final UpdateShouldNotify<AsyncSnapshot<T>> updateShouldNotify;
  final UpdateShouldNotifyDependent<AsyncSnapshot<T>, Token>
      updateShouldNotifyDependent;

  const StreamModelProvider({
    this.tag,
    Key key,
    this.updateShouldNotify,
    this.updateShouldNotifyDependent,
    T initialData,
    Stream<T> stream,
    this.child,
  }) : super(key: key, stream: stream);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) {
    return ModelProvider<AsyncSnapshot<T>, Token>(
      tag: tag,
      child: child,
      value: currentSummary,
      updateShouldNotify: updateShouldNotify,
      updateShouldNotifyDependent: updateShouldNotifyDependent,
    );
  }
}
