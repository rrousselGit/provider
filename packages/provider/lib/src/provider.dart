import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'inherited_provider.dart';

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

/// A provider that merges multiple providers into a single linear widget tree.
/// It is used to improve readability and reduce boilerplate code of having to
/// nest multiple layers of providers.
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
/// [updateShouldNotify] can optionally be passed to avoid unnecessarily
/// rebuilding dependents when nothing changed. Defaults to
/// `(previous, next) => previous != next`. See
/// [InheritedWidget.updateShouldNotify] for more information.
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
///       create: (context) =>  Model(),
///       dispose: (context, value) => value.dispose(),
///       child: ...,
///     );
///   }
/// }
/// ```
///
/// ## Testing
///
/// When testing widgets that consumes providers, it is necessary to
/// add the proper providers in the widget tree above the tested widget.
///
/// A typical test may like this:
///
/// ```dart
/// final foo = MockFoo();
///
/// await tester.pumpWidget(
///   Provider<Foo>.value(
///     value: foo,
///     child: TestedWidget(),
///   ),
/// );
/// ```
///
/// Note this example purposefully specified the object type, instead of having
/// it infered.
/// Since we used a mocked class (typically using `mockito`), then we have to
/// downcast the mock to the type of the mocked class.
/// Otherwise, the type inference will resolve to `Provider<MockFoo>` instead of
/// `Provider<Foo>`, which will cause `Provider.of<Foo>` to fail.
class Provider<T> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// Creates a value, store it, and expose it to its descendants.
  ///
  /// The value can be optionally disposed using [dispose] callback. This
  /// callback which will be called when [Provider] is unmounted from the
  /// widget tree, or if [Provider] is rebuilt to use [Provider.value] instead.
  ///
  Provider({
    Key key,
    @required ValueBuilder<T> create,
    Disposer<T> dispose,
    this.child,
  })  : assert(create != null),
        _value = null,
        _create = create,
        _dispose = dispose,
        updateShouldNotify = null,
        super(key: key);

  /// Allows to specify parameters to [Provider].
  Provider.value({
    Key key,
    @required T value,
    this.updateShouldNotify,
    this.child,
  })  : _value = value,
        _create = null,
        _dispose = null,
        super(key: key);

  Provider._(
    this._create,
    this._dispose,
    this._value, {
    Key key,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key);

  /// Obtains the nearest [Provider<T>] up its widget tree and returns its
  /// value.
  ///
  /// If [listen] is `true` (default), later value changes will trigger a new
  /// [State.build] to widgets, and [State.didChangeDependencies] for
  /// [StatefulWidget].
  static T of<T>(BuildContext context, {bool listen = true}) {
    // this is required to get generic Type
    final type = _typeOf<InheritedProvider<T>>();

    final inheritedElement =
        context.ancestorInheritedElementForWidgetOfExactType(type)
            as InheritedProviderElement<T>;

    if (inheritedElement == null) {
      throw ProviderNotFoundError(T, context.widget.runtimeType);
    }

    if (listen) {
      context.inheritFromElement(inheritedElement);
    }

    return inheritedElement.value;
  }

  /// A sanity check to prevent misuse of [Provider] when a variant should be
  /// used.
  ///
  /// By default, [debugCheckInvalidValueType] will throw if `value` is a
  /// [Listenable] or a [Stream].  In release mode, [debugCheckInvalidValueType]
  /// does nothing.
  ///
  /// This check can be disabled altogether by setting
  /// [debugCheckInvalidValueType] to `null` like so:
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
implementation that handles the update mechanism, such as:

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

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  final ValueBuilder<T> _create;
  final Disposer<T> _dispose;
  final T _value;

  @override
  Widget build(BuildContext context) {
    if (_create != null) {
      void Function(T value) checkValue;

      assert(() {
        checkValue =
            (T value) => Provider.debugCheckInvalidValueType?.call<T>(value);
        return true;
      }());
      return InheritedProvider(
        create: _create,
        dispose: _dispose,
        debugCheckInvalidValueType: checkValue,
        child: child,
      );
    }

    assert(() {
      Provider.debugCheckInvalidValueType?.call<T>(_value);
      return true;
    }());
    return InheritedProvider.value(
      value: _value,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  Provider<T> cloneWithChild(Widget child) {
    return Provider._(
      _create,
      _dispose,
      _value,
      key: key,
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
