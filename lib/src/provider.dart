import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A function that disposes of [value].
typedef Disposer<T> = void Function(BuildContext context, T value);

/// A function that creates an object of type [T].
typedef ValueBuilder<T> = T Function(BuildContext context);

/// A function that returns true when the update from [previous] to [current]
/// should notify listeners, if any.
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// Returns the type [T].
/// See https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923.
Type _typeOf<T>() => T;

/// A base class for providers so tha [MultiProvider] can regroup them into a
/// linear list.
abstract class SingleChildCloneableWidget implements Widget {
  /// Clones the current provider with a new [child].
  ///
  /// Note for implementers: all other values, including [Key] must be
  /// preserved.
  SingleChildCloneableWidget cloneWithChild(Widget child);
}

/// A generic implementation of an [InheritedWidget].
///
/// It is possible to customize the behavior of
/// [InheritedWidget.updateShouldNotify] by passing a callback with the desired
/// behavior.
class Provider<T> extends InheritedWidget
    implements SingleChildCloneableWidget {
  /// The value exposed to other widgets.
  ///
  /// You can obtain this value this widget's descendants
  /// using [Provider.of] method
  final T value;

  /// An optional delegate for [InheritedWidget.updateShouldNotify()] that
  /// should return `false` when there is no need to update its descendents.
  ///
  /// By default, this is `null`. Descendents are notified whenever the [value]
  /// is changed (determined by `!=` operator).
  final UpdateShouldNotify<T> _updateShouldNotify;

  /// Create a [Provider] and pass down [value] to all of its descendants.
  const Provider({
    @required this.value,
    Key key,
    Widget child,
    UpdateShouldNotify<T> updateShouldNotify,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// Obtains the nearest Provider<T> up its widget tree and returns its value.
  ///
  /// If [listen] is true (default), later value changes will trigger a new
  /// [State.build] to widgets, and [State.didChangeDependencies] for
  /// [StatefulWidget].
  static T of<T>(BuildContext context, {bool listen = true}) {
    final type = _typeOf<Provider<T>>();
    final provider = listen
        ? context.inheritFromWidgetOfExactType(type) as Provider<T>
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget
            as Provider<T>;
    if (provider == null) {
      throw ProviderNotFoundError(T, context.widget.runtimeType);
    }
    return provider.value;
  }

  @override
  bool updateShouldNotify(Provider<T> oldWidget) {
    if (_updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget.value, value);
    }
    return oldWidget.value != value;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
  }

  @override
  Provider<T> cloneWithChild(Widget child) {
    return Provider<T>(
      key: key,
      value: value,
      child: child,
      updateShouldNotify: _updateShouldNotify,
    );
  }
}

/// A provider that merges multiple providers into a single linear widget tree.
/// It is used to improve readability and reduce boilderplate code of having to
/// nest mutliple layers of providers.
///
/// As such, we're going from:
///
/// ```dart
/// Provider<Foo>(
///   value: foo,
///   child: Provider<Bar>(
///     value: bar,
///     child: Provider<Baz>(
///       value: baz,
///       child: someWidget,
///     )
///   )
/// )
/// ```
///
/// To:
///
/// ```dart
/// MultiProvider(
///   providers: [
///     Provider<Foo>(value: foo),
///     Provider<Bar>(value: bar),
///     Provider<Baz>(value: baz),
///   ],
///   child: someWidget,
/// )
/// ```
///
/// The widget tree representation of the two approaches are identical.
class MultiProvider extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// Build a tree of providers from a list of [SingleChildCloneableWidget].
  const MultiProvider({@required this.providers, Key key, this.child})
      : assert(providers != null),
        super(key: key);

  /// The list of providers that will be transformed into a tree from top to
  /// bottom.
  ///
  /// Example: with [A, B, C] and [child], the resulting widget tree looks like:
  ///   A
  ///   |
  ///   B
  ///   |
  ///   C
  ///   |
  /// child
  final List<SingleChildCloneableWidget> providers;

  /// The child of the last provider in [providers].
  ///
  /// If [providers] is empty, [MultiProvider] just returns [child].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var tree = child;
    for (final provider in providers.reversed) {
      tree = provider.cloneWithChild(tree);
    }
    return tree;
  }

  @override
  MultiProvider cloneWithChild(Widget child) {
    return MultiProvider(
      key: key,
      providers: providers,
      child: child,
    );
  }
}

// ignore: public_member_api_docs
@visibleForTesting
UpdateShouldNotify<T> debugGetProviderUpdateShouldNotify<T>(
        Provider<T> provider) =>
    provider._updateShouldNotify;

/// A [Provider] that manages the lifecycle of the value it provides by
/// delegating to a pair of [ValueBuilder] and [Disposer].
///
/// It is usually used to avoid making a [StatefulWidget] for something trivial,
/// such as instantiating a BLoC.
///
/// [StatefulBuilder] is the equivalent of a [State.initState] combined with
/// [State.dispose]. [ValueBuilder] is called only once in [State.initState].
/// We cannot use [InheritedWidget] as it requires the value to be
/// constructor-initialized and final.
///
/// The following example instantiates a `Model` once, and disposes it when
/// [StatefulProvider] is removed from the tree.
///
/// ```
/// class Model {
///   void dispose() {}
/// }
///
/// class Stateless extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return StatefulProvider<Model>(
///       valueBuilder: (context) =>  Model(),
///       dispose: (context, value) => value.dispose(),
///       child: ...,
///     );
///   }
/// }
/// ```
class StatefulProvider<T> extends StatefulWidget
    implements SingleChildCloneableWidget {
  /// Allows to specify parameters to [StatefulProvider]
  StatefulProvider({
    @required this.valueBuilder,
    Key key,
    this.child,
    this.dispose,
    this.updateShouldNotify,
  })  : assert(valueBuilder != null),
        super(key: key);

  /// The widget that is below the current [StatefulProvider] widget in the
  /// tree.
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Non-null function called to create the provided value.
  ///
  /// Note this is called exactly once during the life-time of the
  /// [StatefulProvider] during [State.initState].
  final ValueBuilder<T> valueBuilder;

  /// Optional function called when [StatefulProvider] is removed from the
  /// widget tree. The provided value is passed to the function as the sole
  /// parameter.
  ///
  /// This function is useful when the provided value has custom disposal
  /// behavior. For example a sink which needs to be closed explicitly.
  final Disposer<T> dispose;

  /// User-provided custom logic for [InheritedWidget.updateShouldNotify].
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  _StatefulProviderState<T> createState() => _StatefulProviderState<T>();

  @override
  StatefulProvider<T> cloneWithChild(Widget child) {
    return StatefulProvider<T>(
      key: key,
      child: child,
      valueBuilder: valueBuilder,
      dispose: dispose,
      updateShouldNotify: updateShouldNotify,
    );
  }
}

class _StatefulProviderState<T> extends State<StatefulProvider<T>> {
  T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.valueBuilder(context);
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose(context, _value);
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
}

/// The error that will be thrown if [Provider.of<T>] fails to find a
/// [Provider<T>] as an ancestor of the [BuildContext] used.
class ProviderNotFoundError extends Error {
  /// The type of the value being retrieved
  final Type valueType;

  /// The type of the Widget requesting the value
  final Type widgetType;

  /// Create a ProviderNotFound error with the type represented as a String.
  ProviderNotFoundError(
    this.valueType,
    this.widgetType,
  );

  @override
  String toString() {
    return '''
Error: Could not find the correct Provider<$valueType> above this $widgetType Widget

To fix, please:

  * Ensure the Provider<$valueType> is an ancestor to this $widgetType Widget
  * Provide types to Provider<$valueType>
  * Provide types to Consumer<$valueType>
  * Provide types to Provider.of<$valueType>()
  * Always use package imports. Ex: `import 'package:my_app/my_code.dart';
  * Ensure the correct `context` is being used.

If none of these solutions work, please file a bug at:
https://github.com/rrousselGit/provider/issues
''';
  }
}
