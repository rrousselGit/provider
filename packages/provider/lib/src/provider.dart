import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/src/delegate_widget.dart';

/// A function that returns true when the update from [previous] to [current]
/// should notify listeners, if any.
///
/// See also:
///
///   * [InheritedWidget.updateShouldNotify]
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
/// Any descendant of this widget can obtain `value` using [Provider.of].
///
/// Do not use this class directly unless you are creating a custom "Provider".
/// Instead use [Provider] class, which wraps [InheritedProvider].
class InheritedProvider<T> extends InheritedWidget {
  /// Allow customizing [updateShouldNotify].
  const InheritedProvider({
    Key key,
    @required T value,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  })  : _value = value,
        _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// The currently exposed value.
  ///
  /// Mutating `value` should be avoided. Instead rebuild the widget tree
  /// and replace [InheritedProvider] with one that holds the new value.
  final T _value;
  final UpdateShouldNotify<T> _updateShouldNotify;

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    if (_updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget._value, _value);
    }
    return oldWidget._value != _value;
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
///
/// ```dart
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
class Provider<T> extends ValueDelegateWidget<T>
    implements SingleChildCloneableWidget {
  /// Allows to specify parameters to [Provider].
  Provider({
    Key key,
    @required ValueBuilder<T> builder,
    Disposer<T> dispose,
    Widget child,
  }) : this._(
          key: key,
          delegate: BuilderStateDelegate<T>(builder, dispose: dispose),
          updateShouldNotify: null,
          child: child,
        );

  /// Allows to specify parameters to [Provider].
  Provider.value({
    Key key,
    @required T value,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: SingleValueDelegate<T>(value),
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  Provider._({
    Key key,
    @required ValueStateDelegate<T> delegate,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  /// Obtains the nearest [Provider<T>] up its widget tree and returns its value.
  ///
  /// If [listen] is `true` (default), later value changes will trigger a new
  /// [State.build] to widgets, and [State.didChangeDependencies] for
  /// [StatefulWidget].
  static T of<T>(BuildContext context, {bool listen = true}) {
    // this is required to get generic Type
    final type = _typeOf<InheritedProvider<T>>();
    final provider = listen
        ? context.inheritFromWidgetOfExactType(type) as InheritedProvider<T>
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget
            as InheritedProvider<T>;

    if (provider == null) {
      throw ProviderNotFoundError(T, context.widget.runtimeType);
    }

    return provider._value;
  }

  /// A sanity check to prevent misuse of [Provider] when a variant should be used.
  ///
  /// By default, [debugCheckInvalidValueType] will throw if `value` is a [Listenable]
  /// or a [Stream].
  /// In release mode, [debugCheckInvalidValueType] does nothing.
  ///
  /// This check can be disabled altogether by setting [debugCheckInvalidValueType]
  /// to `null` like so:
  ///
  /// ```dart
  /// void main() {
  ///   Provider.debugCheckInvalidValueType = null;
  ///   runApp(MyApp());
  /// }
  /// ```
  static void Function<T>(T value) debugCheckInvalidValueType = <T>(T value) {
    assert(() {
      if (value is Listenable || value is Stream) {
        throw FlutterError('''
Tried to use Provider with a subtype of Listenable/Stream ($T).

This is likely a mistake, as Provider will not automatically update dependents
when $T is updated. Instead, consider changing Provider for more specific
implementation that handles the update mecanism, such as:

- ListenableProvider
- ChangeNotifierProvider
- ValueListenableProvider
- StreamProvider

Alternatively, if you are making your own provider, consider using InheritedProvider.

If you think that this is not an error, you can disable this check by setting
Provider.debugCheckInvalidValueType to `null` in your main file:

```
void main() {
  Provider.debugCheckInvalidValueType = null;

  runApp(MyApp());
}
```
''');
      }
      return true;
    }());
  };

  /// User-provided custom logic for [InheritedWidget.updateShouldNotify].
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  Provider<T> cloneWithChild(Widget child) {
    return Provider._(
      key: key,
      delegate: delegate,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(() {
      Provider.debugCheckInvalidValueType?.call<T>(delegate.value);
      return true;
    }());
    return InheritedProvider<T>(
      value: delegate.value,
      updateShouldNotify: updateShouldNotify,
      child: child,
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
