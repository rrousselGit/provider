import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923
Type _typeOf<T>() => T;

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// A base class for providers so tha [MultiProvider] can regroup them into a linear list
abstract class ProviderBase implements Widget {
  /// Clone the current provider with a new child.
  ///
  /// All values, including [Key] must be preserved.
  ProviderBase cloneWithChild(Widget child);
}

/// A generic implementation of an [InheritedWidget]
///
/// It is possible to customize the behavior of [InheritedWidget.updateShouldNotify]
/// by passing a callback with the desired behavior.
class Provider<T> extends InheritedWidget implements ProviderBase {
  /// The value exposed to other widgets.
  ///
  /// You can obtain this value this widget's descendants
  /// using [Provider.of] method
  final T value;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedWidget.updateShouldNotify] is called.
  /// It should return `false` when there's no need to update its dependents.
  ///
  /// The default behavior is `previous == current`
  final bool Function(T previous, T current) _updateShouldNotify;

  /// Creates a [Provider] and pass down [value] to all of its descendants
  const Provider({
    Key key,
    @required this.value,
    Widget child,
    UpdateShouldNotify<T> updateShouldNotify,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// Obtain the nearest Provider<T> and returns its value.
  ///
  /// If [listen] is true (default), later value changes will
  /// trigger a new [State.build] to widgets, and [State.didChangeDependencies] for [StatefulWidget]
  static T of<T>(BuildContext context, {bool listen = true}) {
    // this is required to get generic Type
    final type = _typeOf<Provider<T>>();
    final provider = listen
        ? context.inheritFromWidgetOfExactType(type) as Provider<T>
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget
            as Provider<T>;

    if (provider == null) {
      throw ProviderNotFoundError(
        T.toString(),
        context.widget.runtimeType.toString(),
      );
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
class MultiProvider extends StatelessWidget implements ProviderBase {
  /// Build a tree of providers from a list of [ProviderBase].
  const MultiProvider({Key key, @required this.providers, this.child})
      : assert(providers != null),
        super(key: key);

  /// The list of providers that will be transformed into a tree.
  ///
  /// The tree is created from top to bottom. The first item because to topmost provider, while the last item it the direct parent of [child].
  final List<ProviderBase> providers;

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

@visibleForTesting
// ignore: public_member_api_docs
UpdateShouldNotify<T> debugGetProviderUpdateShouldNotify<T>(
        Provider<T> provider) =>
    provider._updateShouldNotify;

/// A [Provider] that can also create and dispose an object.
///
/// It is usually used to avoid making a [StatefulWidget] for something trivial, such as instanciating a BLoC.
///
/// [StatefulBuilder] is the equivalent of a [State.initState] combined with [State.dispose].
/// As such, [valueBuilder] is called only once and is unable to use [InheritedWidget]; which makes it impossible to update the created value.
///
/// If this is too limiting, consider instead [HookProvider], which offer a much more advanced control over the created value.
///
/// The following example instanciate a `Model` once, and dispose it when [StatefulProvider] is removed from the tree.
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
///       onDispose: (context, value) => value.dispose(),
///       child: ...,
///     );
///   }
/// }
/// ```
class StatefulProvider<T> extends StatefulWidget implements ProviderBase {
  /// Allows to specify parameters to [StatefulProvider]
  StatefulProvider({
    Key key,
    @required this.valueBuilder,
    this.child,
    this.onDispose,
    this.updateShouldNotify,
  })  : assert(valueBuilder != null),
        super(key: key);

  /// A function that creates the provided value.
  ///
  /// [valueBuilder] must not be null and is called only once for the life-cycle of [StatefulProvider].
  ///
  /// It is not possible to obtain an [InheritedWidget] from [valueBuilder].
  final T Function(BuildContext context) valueBuilder;

  /// [onDispose] is a callback called when [StatefulProvider] is
  /// removed for the widget tree, and pass the current value as parameter.
  /// It is useful when the provided object needs to have a custom dipose behavior,
  /// such as closing streams.
  final void Function(BuildContext context, T value) onDispose;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A customizable implementation for [InheritedWidget.updateShouldNotify]
  final bool Function(T previous, T current) updateShouldNotify;

  @override
  _StatefulProviderState<T> createState() => _StatefulProviderState<T>();

  @override
  StatefulProvider<T> cloneWithChild(Widget child) {
    return StatefulProvider<T>(
      child: child,
      valueBuilder: valueBuilder,
      key: key,
      onDispose: onDispose,
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
}

/// A provider which can use hooks from [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)
///
/// This is especially useful to create complex providers, without having to make a `StatefulWidget`.
///
/// The following example uses BLoC pattern to create a BLoC, provide its value, and dispose it when the provider is removed from the tree.
///
/// ```dart
/// HookProvider<MyBloc>(
///   hook: () {
///     final bloc = useMemoized(() => MyBloc());
///     useEffect(() => bloc.dispose, [bloc]);
///     return bloc;
///   },
///   child: // ...
/// )
/// ```
class HookProvider<T> extends HookWidget implements ProviderBase {
  /// A provider which can use hooks from [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)
  ///
  /// This is especially useful to create complex providers, without having to make a `StatefulWidget`.
  ///
  /// The following example uses BLoC pattern to create a BLoC, provide its value, and dispose it when the provider is removed from the tree.
  ///
  /// ```dart
  /// HookProvider<MyBloc>(
  ///   hook: () {
  ///     final bloc = useMemoized(() => MyBloc());
  ///     useEffect(() => bloc.dispose, [bloc]);
  ///     return bloc;
  ///   },
  ///   child: // ...
  /// )
  /// ```
  const HookProvider({Key key, this.hook, this.child, this.updateShouldNotify})
      : super(key: key);

  /// A provider which can use hooks from [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)
  ///
  /// This is especially useful to create complex providers, without having to make a `StatefulWidget`.
  ///
  /// The following example uses BLoC pattern to create a BLoC, provide its value, and dispose it when the provider is removed from the tree.
  ///
  /// ```dart
  /// HookProvider<MyBloc>(
  ///   hook: () {
  ///     final bloc = useMemoized(() => MyBloc());
  ///     useEffect(() => bloc.dispose, [bloc]);
  ///     return bloc;
  ///   },
  ///   child: // ...
  /// )
  /// ```
  final T Function() hook;

  /// A provider which can use hooks from [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)
  ///
  /// This is especially useful to create complex providers, without having to make a `StatefulWidget`.
  ///
  /// The following example uses BLoC pattern to create a BLoC, provide its value, and dispose it when the provider is removed from the tree.
  ///
  /// ```dart
  /// HookProvider<MyBloc>(
  ///   hook: () {
  ///     final bloc = useMemoized(() => MyBloc());
  ///     useEffect(() => bloc.dispose, [bloc]);
  ///     return bloc;
  ///   },
  ///   child: // ...
  /// )
  /// ```
  final Widget child;

  /// A provider which can use hooks from [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)
  ///
  /// This is especially useful to create complex providers, without having to make a `StatefulWidget`.
  ///
  /// The following example uses BLoC pattern to create a BLoC, provide its value, and dispose it when the provider is removed from the tree.
  ///
  /// ```dart
  /// HookProvider<MyBloc>(
  ///   hook: () {
  ///     final bloc = useMemoized(() => MyBloc());
  ///     useEffect(() => bloc.dispose, [bloc]);
  ///     return bloc;
  ///   },
  ///   child: // ...
  /// )
  /// ```
  final bool Function(T, T) updateShouldNotify;

  @override
  Widget build(BuildContext context) => Provider<T>(
        value: hook(),
        child: child,
        updateShouldNotify: updateShouldNotify,
      );

  @override
  HookProvider<T> cloneWithChild(Widget child) {
    return HookProvider<T>(
      key: key,
      child: child,
      hook: hook,
      updateShouldNotify: updateShouldNotify,
    );
  }
}

@visibleForTesting
// ignore: public_member_api_docs
var useStreamSeam = useStream;

/// A provider that exposes the current value of a `Stream` as an `AsyncSnapshot`.
///
/// Changing [stream] will stop listening to the previous [stream] and listen the new one.
/// Removing [StreamProvider] from the tree will also stop listening to [stream].
///
/// To obtain the current value of type `T`, one must explicitly request `Provider.of<AsyncSnapshot<T>>`.
/// It is also possible to use `StreamProvider.of<T>`.
///
/// ```dart
/// Stream<int> foo;
///
/// StreamProvider<int>(
///   stream: foo,
///   child: Container(),
/// );
/// ```
class StreamProvider<T> extends HookProvider<AsyncSnapshot<T>> {
  /// Allow configuring [Key]
  StreamProvider({
    @required this.stream,
    Key key,
    T initialData,
    Widget child,
  })  : assert(stream != null),
        super(
            key: key,
            hook: () => useStreamSeam(stream, initialData: initialData),
            child: child);

  /// Obtains the currently exposed value from [StreamProvider]
  ///
  /// [StreamProvider.of<T>] is a shorthand for [Provider.of<AsyncSnapshot<T>>].
  static AsyncSnapshot<T> of<T>(BuildContext context) =>
      Provider.of<AsyncSnapshot<T>>(context);

  /// The currently listened [Stream].
  ///
  /// It is fine to change the instance of [stream].
  final Stream<T> stream;
}

/// An handler for the disposal of an object
typedef void Disposer<T>(T value);

/// A function that creates an object
typedef T ValueBuilder<T>();

/// Expose a [ChangeNotifier] subclass and ask its depends to rebuild whenever [ChangeNotifier.notifyListeners] is called
///
/// Listeners to [ChangeNotifier] only rebuilds when [ChangeNotifier.notifyListeners] is called, even if [ChangeNotifierProvider] is rebuilt.
///
/// ```dart
/// class MyModel extends ChangeNotifier {
///   int _value;
///
///   int get value => _value;
///
///   set value(int value) {
///     _value = value;
///     notifyListeners();
///   }
/// }
///
///
/// // ...
///
/// ChangeNotifierProfider<MyModel>.stateful(
///   builder: () => MyModel(),
///   child: Container(),
/// )
/// ```
class ChangeNotifierProvider<T extends ChangeNotifier> extends HookWidget
    implements ProviderBase {
  /// Allow configuring [Key]
  ///
  /// [notifier] must not be `null`
  const ChangeNotifierProvider({Key key, @required T notifier, this.child})
      : assert(notifier != null),
        _notifier = notifier,
        _builder = null,
        _disposer = null,
        super(key: key);

  /// Allow configuring [Key]
  ///
  /// [disposer] will be called when [ChangeNotifierProvider] is removed from the tree.
  /// Or when switching from [ChangeNotifierProvider.stateful] to [ChangeNotifierProvider] constructor.
  ///
  /// [builder] must not be `null`
  const ChangeNotifierProvider.stateful({
    Key key,
    @required ValueBuilder<T> builder,
    Disposer<T> disposer,
    this.child,
  })  : assert(builder != null),
        _builder = builder,
        _notifier = null,
        _disposer = disposer,
        super(key: key);

  ChangeNotifierProvider._(
      Key key, this.child, this._builder, this._disposer, this._notifier)
      : super(key: key);

  static bool _alwaysUpdate(
          ChangeNotifier previousValue, ChangeNotifier newValue) =>
      true;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  final T _notifier;
  final ValueBuilder<T> _builder;
  final Disposer<T> _disposer;

  @override
  Widget build(BuildContext context) {
    final notifier = useMemoized<T>(
      () => _notifier ?? _builder(),
      <dynamic>[_notifier],
    );

    final buildCount = useState<int>(0);
    useEffect(() {
      final listener = () => buildCount.value++;
      notifier.addListener(listener);
      return () {
        notifier.removeListener(listener);
      };
    }, <dynamic>[notifier]);

    final disposer = useState(_disposer);
    useValueChanged<Disposer<T>, void>(
        _disposer, (_, __) => disposer.value = _disposer);

    useEffect(
      () {
        if (_notifier == null) {
          return () {
            if (disposer.value != null) {
              disposer.value(notifier);
            }
            notifier.dispose();
          };
        }
      },
      <dynamic>[notifier],
    );

    return useMemoized(
      () {
        return Provider<T>(
          child: child,
          value: notifier,
          updateShouldNotify: _alwaysUpdate,
        );
      },
      <dynamic>[buildCount.value, child, notifier],
    );
  }

  @override
  ChangeNotifierProvider<T> cloneWithChild(Widget child) {
    return ChangeNotifierProvider<T>._(
      key,
      child,
      _builder,
      _disposer,
      _notifier,
    );
  }
}

@visibleForTesting
// ignore: public_member_api_docs
var useValueListenableSeam = useValueListenable;

/// Expose the current value of a [ValueListenable].
///
/// Changing [valueListenable] will stop listening to the previous [valueListenable] and listen the new one.
/// Removing [ValueListenableProvider] from the tree will also stop listening to [valueListenable].
///
///
/// ```dart
/// ValueListenable<int> foo;
///
/// ValueListenableProvider<int>(
///   valueListenable: foo,
///   child: Container(),
/// );
class ValueListenableProvider<T> extends HookProvider<T> {
  /// Allow configuring [Key]
  ValueListenableProvider({
    @required this.valueListenable,
    Key key,
    Widget child,
  })  : assert(valueListenable != null),
        super(
          key: key,
          hook: () => useValueListenableSeam(valueListenable),
          child: child,
        );

  /// The currently listened [Stream].
  ///
  /// It is fine to change the instance of [valueListenable].
  final ValueListenable<T> valueListenable;
}

/// The error that will be thrown if the Provider cannot be found in the
/// Widget tree.
class ProviderNotFoundError extends Error {
  final String _type;
  final String _currentWidget;

  /// Create a ProviderNotFound error with the type represented as a String.
  ProviderNotFoundError(
    this._type,
    this._currentWidget,
  );

  @override
  String toString() {
    return '''
Error: Could not find the correct Provider<$_type> above this $_currentWidget Widget 

To fix, please:

  * Ensure the Provider<$_type> is an ancestor to this $_currentWidget Widget 
  * Provide types to Provider<$_type>
  * Provide types to Consumer<$_type>
  * Provide types to Provider.of<$_type>()
  * Always use package imports. Ex: `import 'package:my_app/my_code.dart';
  * Ensure the correct `context` is being used.

If none of these solutions work, please file a bug at:
https://github.com/rrousselGit/provider/issues
      ''';
  }
}
