import 'package:flutter/widgets.dart';

import 'delegate_widget.dart';
import 'listenable_provider.dart';
import 'provider.dart';
import 'proxy_provider.dart';

/// Listens to a [ChangeNotifier], expose it to its descendants and rebuilds
/// dependents whenever the [ChangeNotifier.notifyListeners] is called.
///
/// Depending on wether you want to **create** or **reuse** a [ChangeNotifier],
/// you will want to use different constructors.
///
/// ## Creating a [ChangeNotifier]:
///
/// To create a value, use the default constructor. Creating the instance
/// inside `build` using [ChangeNotifierProvider.value] will lead to memory
/// leaks and potentially undesired side-effects.
///
/// See [this stackoverflow answer](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
/// which explains in further details why using the `.value` constructor to
/// create values is undesired.
///
/// - DO create a new [ChangeNotifier] inside `builder`.
/// ```dart
/// ChangeNotifierProvider(
///   builder: (_) => new MyChangeNotifier(),
///   child: ...
/// )
/// ```
///
/// - DON'T use [ChangeNotifierProvider.value] to create your [ChangeNotifier].
/// ```dart
/// ChangeNotifierProvider.value(
///   value: new MyChangeNotifier(),
///   child: ...
/// )
/// ```
///
/// - DON'T create your [ChangeNotifier] from variables that can change over
///   the time.
///
///   In such situation, your [ChangeNotifier] would never be updated when the
///   value changes.
/// ```dart
/// int count;
///
/// ChangeNotifierProvider(
///   builder: (_) => new MyChangeNotifier(count),
///   child: ...
/// )
/// ```
///
/// If your updating variable comes from a provider, consider using
/// [ChangeNotifierProxyProvider].
/// Otherwise, consider making a [StatefulWidget] and managing your
/// [ChangeNotifier] manually.
///
/// ## Reusing an existing instance of [ChangeNotifier]:
///
/// If you already have an instance of [ChangeNotifier] and want to expose it,
/// you should use [ChangeNotifierProvider.value] instead of the default
/// constructor.
///
/// Failing to do so may dispose the [ChangeNotifier] when it is still in use.
///
/// - DO use [ChangeNotifierProvider.value] to provide an existing
///   [ChangeNotifier].
/// ```dart
/// MyChangeNotifier variable;
///
/// ChangeNotifierProvider.value(
///   value: variable,
///   child: ...
/// )
/// ```
///
/// - DON'T reuse an existing [ChangeNotifier] using the default constructor.
/// ```dart
/// MyChangeNotifier variable;
///
/// ChangeNotifierProvider(
///   builder: (_) => variable,
///   child: ...
/// )
/// ```
///
/// See also:
///
///   * [ChangeNotifier], which is listened by [ChangeNotifierProvider].
///   * [ChangeNotifierProxyProvider], to create and provide a [ChangeNotifier]
///     of variables from other providers.
///   * [ListenableProvider], similar to [ChangeNotifierProvider] but works with
///     any [Listenable].
class ChangeNotifierProvider<T extends ChangeNotifier>
    extends ListenableProvider<T> implements SingleChildCloneableWidget {
  static void _disposer(BuildContext context, ChangeNotifier notifier) =>
      notifier?.dispose();

  /// Creates a [ChangeNotifier] using `builder` and automatically
  /// dispose it when [ChangeNotifierProvider] is removed from the widget tree.
  ///
  /// `builder` must not be `null`.
  ChangeNotifierProvider({
    Key key,
    @required ValueBuilder<T> builder,
    Widget child,
  }) : super(key: key, builder: builder, dispose: _disposer, child: child);

  /// Provides an existing [ChangeNotifier].
  ChangeNotifierProvider.value({
    Key key,
    @required T value,
    Widget child,
  }) : super.value(key: key, value: value, child: child);
}

/// {@template provider.changenotifierproxyprovider}
/// A [ChangeNotifierProvider] that builds and synchronizes a [ChangeNotifier]
/// from values obtained from other providers.
///
/// To understand better this variation of [ChangeNotifierProvider], we can
/// look into the following code using the original provider:
///
/// ```dart
/// ChangeNotifierProvider(
///   builder: (context) {
///     return MyChangeNotifier(
///       foo: Provider.of<Foo>(context, listen: false),
///     );
///   },
///   child: ...
/// )
/// ```
///
/// In example, we built a `MyChangeNotifier` from a value coming from another
/// provider: `Foo`.
///
/// This works as long as `Foo` never changes. But if it somehow updates, then
/// our [ChangeNotifier] will never update accordingly.
///
/// To solve this issue, we could instead use this class, like so:
///
/// ```dart
/// ChangeNotifierProxyProvider<Foo, MyChangeNotifier>(
///   initialBuilder: (_) => MyChangeNotifier(),
///   builder: (_, foo, myNotifier) => myNotifier
///     ..foo = foo,
///   child: ...
/// );
/// ```
///
/// In that situation, if `Foo` were to update, then `MyChangeNotifier` will
/// be able to update accordingly.
///
/// Notice how `MyChangeNotifier` doesn't receive `Foo` in its constructor
/// anymore. It is now passed through a custom setter instead.
///
/// A typical implementation of such `MyChangeNotifier` would be:
///
/// ```dart
/// class MyChangeNotifier with ChangeNotifier {
///   Foo _foo;
///   set foo(Foo value) {
///     if (_foo != value) {
///       _foo = value;
///       // do some extra work, that may call `notifyListeners()`
///     }
///   }
/// }
/// ```
///
/// - DON'T create the [ChangeNotifier] inside `builder` directly.
///
///   This will cause your state to be lost when one of the values used updates.
///   It will also cause uncesserary overhead because it will dispose the
///   previous notifier, then subscribes to the new one.
///
///  Instead use properties with custom setters like shown previously, or
///   methods.
///
/// ```dart
/// ChangeNotifierProxyProvider<Foo, MyChangeNotifier>(
///   // may cause the state to be destroyed unvoluntarily
///   builder: (_, foo, myNotifier) => MyChangeNotifier(foo: foo),
///   child: ...
/// );
/// ```
///
/// - PREFER using [ProxyProvider] when possible.
///
///   If the created object is only a combination of other objects, without
///   http calls or similar side-effects, then it is likely that an immutable
///   object built using [ProxyProvider] will work.
/// {@endtemplate}
class ChangeNotifierProxyProvider<T, R extends ChangeNotifier>
    extends ListenableProxyProvider<T, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider({
    Key key,
    @required ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder<T, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: ChangeNotifierProvider._disposer,
          child: child,
        );
}

/// {@macro provider.changenotifierproxyprovider}
class ChangeNotifierProxyProvider2<T, T2, R extends ChangeNotifier>
    extends ListenableProxyProvider2<T, T2, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider2({
    Key key,
    @required ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder2<T, T2, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: ChangeNotifierProvider._disposer,
          child: child,
        );
}

/// {@macro provider.changenotifierproxyprovider}
class ChangeNotifierProxyProvider3<T, T2, T3, R extends ChangeNotifier>
    extends ListenableProxyProvider3<T, T2, T3, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider3({
    Key key,
    @required ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder3<T, T2, T3, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: ChangeNotifierProvider._disposer,
          child: child,
        );
}

/// {@macro provider.changenotifierproxyprovider}
class ChangeNotifierProxyProvider4<T, T2, T3, T4, R extends ChangeNotifier>
    extends ListenableProxyProvider4<T, T2, T3, T4, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider4({
    Key key,
    @required ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: ChangeNotifierProvider._disposer,
          child: child,
        );
}

/// {@macro provider.changenotifierproxyprovider}

class ChangeNotifierProxyProvider5<T, T2, T3, T4, T5, R extends ChangeNotifier>
    extends ListenableProxyProvider5<T, T2, T3, T4, T5, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider5({
    Key key,
    @required ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: ChangeNotifierProvider._disposer,
          child: child,
        );
}

/// {@macro provider.changenotifierproxyprovider}
class ChangeNotifierProxyProvider6<T, T2, T3, T4, T5, T6,
        R extends ChangeNotifier>
    extends ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider6({
    Key key,
    @required ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: ChangeNotifierProvider._disposer,
          child: child,
        );
}
