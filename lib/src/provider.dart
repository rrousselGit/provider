import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/src/adaptative_builder_widget.dart';

/// An handler for the disposal of an object
typedef void Disposer<T>(BuildContext context, T value);

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923
Type _typeOf<T>() => T;

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// A base class for providers so tha [MultiProvider] can regroup them into a linear list
abstract class SingleChildCloneableWidget implements Widget {
  /// Clone the current provider with a new child.
  ///
  /// All values, including [Key] must be preserved.
  SingleChildCloneableWidget cloneWithChild(Widget child);
}

class _Provider<T> extends InheritedWidget {
  const _Provider({
    Key key,
    @required this.value,
    Widget child,
    UpdateShouldNotify<T> updateShouldNotify,
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

/// A provider that exposes that merges multiple other providers into one.
///
/// [MultiProvider] is used to improve the readability and reduce the boilerplate of
/// having many nested providers.
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
/// Technically, these two are identical. [MultiProvider] will convert the array into a tree.
/// This changes only the appearance of the code.
class MultiProvider extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// Build a tree of providers from a list of [SingleChildCloneableWidget].
  const MultiProvider({Key key, @required this.providers, this.child})
      : assert(providers != null),
        super(key: key);

  /// The list of providers that will be transformed into a tree.
  ///
  /// The tree is created from top to bottom. The first item because to topmost provider, while the last item it the direct parent of [child].
  final List<SingleChildCloneableWidget> providers;

  /// The child of the latest provider.
  ///
  /// If [providers] is empty, then [MultiProvider] just returns [child].
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

/// A [Provider] that can also create and dispose an object.
///
/// It is usually used to avoid making a [StatefulWidget] for something trivial, such as instanciating a BLoC.
///
/// [StatefulBuilder] is the equivalent of a [State.initState] combined with [State.dispose].
/// As such, [builder] is called only once and is unable to use [InheritedWidget]; which makes it impossible to update the created value.
///
/// The following example instanciate a `Model` once, and dispose it when [Provider] is removed from the tree.
///
/// ```
/// class Model {
///   void dispose() {}
/// }
///
/// class Stateless extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Provider(<Model>(
///       valueBuilder: (context) =>  Model(),
///       dispose: (context, value) => value.dispose(),
///       child: ...,
///     );
///   }
/// }
/// ```
class Provider<T> extends AdaptativeBuilderWidget<T>
    implements SingleChildCloneableWidget {
  /// Obtain the nearest Provider<T> and returns its value.
  ///
  /// If [listen] is true (default), later value changes will
  /// trigger a new [State.build] to widgets, and [State.didChangeDependencies] for [StatefulWidget]
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
    this.updateShouldNotify,
    this.dispose,
    this.child,
  })  : assert(builder != null),
        super(key: key, builder: builder);

  /// Allows to specify parameters to [Provider]
  const Provider.value({
    Key key,
    @required T value,
    this.updateShouldNotify,
    this.child,
  })  : dispose = null,
        super.value(key: key, value: value);

  /// [dispose] is a callback called when [Provider] is
  /// removed for the widget tree, and pass the current value as parameter.
  /// It is useful when the provided object needs to have a custom dipose behavior,
  /// such as closing streams.
  final Disposer<T> dispose;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A customizable implementation for [InheritedWidget.updateShouldNotify]
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
            updateShouldNotify: updateShouldNotify,
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
    with AdaptativeBuilderWidgetStateMixin<T, Provider<T>> {
  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose(context, value);
    }
    super.dispose();
  }

  @override
  void didChangeValue(T previousValue) {
    if (widget.dispose != null) {
      widget.dispose(context, previousValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Provider<T>(
      value: value,
      updateShouldNotify: widget.updateShouldNotify,
      child: widget.child,
    );
  }
}

/// The error that will be thrown if [Provider.of<T>] fails to find a [Provider<T>] as ancestor of the [BuildContext] used.
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
