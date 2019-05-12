import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/src/adaptive_builder_widget.dart';

/// A function that disposes of [value].
typedef Disposer<T> = void Function(BuildContext context, T value);

/// A function that returns true when the update from [previous] to [current]
/// should notify listeners, if any.
typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// Returns the type [T].
/// See https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923.
Type _typeOf<T>() => T;

/// A base class for providers so that [MultiProvider] can regroup them into a
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
class _Provider<T> extends InheritedWidget {
  const _Provider({
    Key key,
    @required this.value,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  final T value;
  final UpdateShouldNotify<T> _updateShouldNotify;

  @override
  bool updateShouldNotify(_Provider<T> oldWidget) {
    if (_updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget.value, value);
    }
    return oldWidget.value != value;
  }
}

/// A provider that merges multiple providers into a single linear widget tree.
/// It is used to improve readability and reduce boilderplate code of having to
/// nest mutliple layers of providers.
///
/// As such, we're going from:
///
/// ```dart
/// Provider<Foo>.value(
///   value: foo,
///   child: Provider<Bar>.value(
///     value: bar,
///     child: Provider<Baz>.value(
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
///     Provider<Foo>.value(value: foo),
///     Provider<Bar>.value(value: bar),
///     Provider<Baz>.value(value: baz),
///   ],
///   child: someWidget,
/// )
/// ```
///
/// The widget tree representation of the two approaches are identical.
class MultiProvider extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// Build a tree of providers from a list of [SingleChildCloneableWidget].
  const MultiProvider({
    Key key,
    @required this.providers,
    this.child,
  })  : assert(providers != null),
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

/// A [Provider] that manages the lifecycle of the value it provides by
/// delegating to a pair of [ValueBuilder] and [Disposer].
///
/// It is usually used to avoid making a [StatefulWidget] for something trivial,
/// such as instantiating a BLoC.
///
/// [Provider] is the equivalent of a [State.initState] combined with
/// [State.dispose]. [ValueBuilder] is called only once in [State.initState].
/// We cannot use [InheritedWidget] as it requires the value to be
/// constructor-initialized and final.
///
/// The following example instantiates a `Model` once, and disposes it when
/// [Provider] is removed from the tree.
///
/// {@template provider.updateshouldnotify}
/// [updateShouldNotify] can optionally be passed to avoid unnecessaryly rebuilding dependants when nothing changed.
/// Defaults to `(previous, next) => previous != next`. See [InheritedWidget.updateShouldNotify] for more informations.
/// {@endtemplate}
/// ```
/// class Model {
///   void dispose() {}
/// }
///
/// class Stateless extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Provider<Model>(
///       builder: (context) =>  Model(),
///       dispose: (context, value) => value.dispose(),
///       child: ...,
///     );
///   }
/// }
/// ```
class Provider<T> extends AdaptiveBuilderWidget<T, T>
    implements SingleChildCloneableWidget {
  /// Obtains the nearest [Provider<T>] up its widget tree and returns its value.
  ///
  /// If [listen] is `true` (default), later value changes will trigger a new
  /// [State.build] to widgets, and [State.didChangeDependencies] for
  /// [StatefulWidget].
  static T of<T>(BuildContext context, {bool listen = true}) {
    // this is required to get generic Type
    final type = _typeOf<_Provider<T>>();
    final provider = listen
        ? context.inheritFromWidgetOfExactType(type) as _Provider<T>
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget
            as _Provider<T>;

    if (provider == null) {
      throw ProviderNotFoundError(T, context.widget.runtimeType);
    }

    return provider.value;
  }

  /// Allows to specify parameters to [Provider]
  const Provider({
    Key key,
    @required ValueBuilder<T> builder,
    this.dispose,
    this.child,
  })  : assert(builder != null),
        updateShouldNotify = null,
        super(key: key, builder: builder);

  /// Allows to specify parameters to [Provider]
  const Provider.value({
    Key key,
    @required T value,
    this.updateShouldNotify,
    this.child,
  })  : dispose = null,
        super.value(key: key, value: value);

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Optional function called when [Provider] is removed from the
  /// widget tree. The provided value is passed to the function as the sole
  /// parameter.
  ///
  /// This function is useful when the provided value has custom disposal
  /// behavior. For example a sink which needs to be closed explicitly.
  final Disposer<T> dispose;

  /// User-provided custom logic for [InheritedWidget.updateShouldNotify].
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  _ProviderState<T> createState() => _ProviderState<T>();

  @override
  Provider<T> cloneWithChild(Widget child) {
    return builder != null
        ? Provider<T>(
            child: child,
            builder: builder,
            key: key,
            dispose: dispose,
          )
        : Provider<T>.value(
            key: key,
            value: value,
            updateShouldNotify: updateShouldNotify,
            child: child,
          );
  }
}

class _ProviderState<T> extends State<Provider<T>>
    with AdaptiveBuilderWidgetStateMixin<T, T, Provider<T>> {
  @override
  Widget build(BuildContext context) {
    return _Provider<T>(
      value: value,
      updateShouldNotify: widget.updateShouldNotify,
      child: widget.child,
    );
  }

  @override
  T didBuild(T built) => built;

  @override
  void disposeBuilt(Provider<T> widget, T built) {
    if (widget.dispose != null) {
      widget.dispose(context, built);
    }
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
