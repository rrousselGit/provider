import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'inherited_provider.dart';
import 'provider.dart';

typedef ProviderBuilder<R> = Widget Function(
    BuildContext context, R value, Widget child);

typedef ProxyProviderBuilder<T, R> = R Function(
    BuildContext context, T value, R previous);

typedef ProxyProviderBuilder2<T, T2, R> = R Function(
    BuildContext context, T value, T2 value2, R previous);

typedef ProxyProviderBuilder3<T, T2, T3, R> = R Function(
    BuildContext context, T value, T2 value2, T3 value3, R previous);

typedef ProxyProviderBuilder4<T, T2, T3, T4, R> = R Function(
    BuildContext context, T value, T2 value2, T3 value3, T4 value4, R previous);

typedef ProxyProviderBuilder5<T, T2, T3, T4, T5, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  R previous,
);

typedef ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  T6 value6,
  R previous,
);

/// {@macro provider.proxyprovider}
@visibleForTesting
class ProxyProvider0<R> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// Initializes [key] for subclasses.
  ProxyProvider0({
    Key key,
    Create<R> create,
    @required R Function(BuildContext context, R value) update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        _update = update,
        _create = create,
        _updateShouldNotify = updateShouldNotify,
        _dispose = dispose,
        _child = child,
        super(key: key);

  final Widget _child;
  final R Function(BuildContext context, R value) _update;
  final UpdateShouldNotify<R> _updateShouldNotify;
  final Create<R> _create;
  final Disposer<R> _dispose;

  @override
  Widget build(BuildContext context) {
    void Function(R value) checkValue;
    assert(() {
      checkValue =
          (R value) => Provider.debugCheckInvalidValueType?.call<R>(value);
      return true;
    }());
    return InheritedProvider<R>(
      create: _create,
      update: _update,
      dispose: _dispose,
      updateShouldNotify: _updateShouldNotify,
      debugCheckInvalidValueType: checkValue,
      child: _child,
    );
  }

  @override
  ProxyProvider0<R> cloneWithChild(Widget child) {
    return ProxyProvider0(
      key: key,
      create: _create,
      update: _update,
      updateShouldNotify: _updateShouldNotify,
      dispose: _dispose,
      child: child,
    );
  }
}

/// {@template provider.proxyprovider}
/// A provider that builds a value based on other providers.
///
/// The exposed value is built through either `create` or `update`, then passed
/// to [InheritedProvider].
///
/// As opposed to the `create`, `update` may be called more than once.
/// It will be called once the first time the value is obtained, then once
/// whenever [ProxyProvider] rebuilds or when one of the providers it depends on
/// updates.
///
/// [ProxyProvider] comes in different variants such as [ProxyProvider2]. This
/// is syntax sugar on the top of [ProxyProvider0].
///
/// As such, `ProxyProvider<A, Result>` is equal to:
/// ```dart
/// ProxyProvider0<Result>(
///   update: (context, result) {
///     final a = Provider.of<A>(context);
///     return update(context, a, b, result);
///   }
/// );
/// ```
///
/// Whereas `ProxyProvider2<A, B, Result>` is equal to:
/// ```dart
/// ProxyProvider0<Result>(
///   update: (context, result) {
///     final a = Provider.of<A>(context);
///     final b = Provider.of<B>(context);
///     return update(context, a, b, result);
///   }
/// );
/// ```
///
/// This last parameter of `update` is previous value returned by either
/// `create` or `update`. It is `null` by default.
///
/// `update` must not be `null`.
///
/// See also:
///
///  * [Provider], which matches the behavior of [ProxyProvider] without
/// dependending on other providers.
/// {@endtemplate}
class ProxyProvider<T, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider({
    Key key,
    Create<R> create,
    @required ProxyProviderBuilder<T, R> update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        super(
          key: key,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider2<T, T2, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider2({
    Key key,
    Create<R> create,
    @required ProxyProviderBuilder2<T, T2, R> update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        super(
          key: key,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider3<T, T2, T3, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider3({
    Key key,
    Create<R> create,
    @required ProxyProviderBuilder3<T, T2, T3, R> update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        super(
          key: key,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider4<T, T2, T3, T4, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider4({
    Key key,
    Create<R> create,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        super(
          key: key,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider5<T, T2, T3, T4, T5, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider5({
    Key key,
    Create<R> create,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        super(
          key: key,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.proxyprovider}
class ProxyProvider6<T, T2, T3, T4, T5, T6, R> extends ProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ProxyProvider6({
    Key key,
    Create<R> create,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> update,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(update != null),
        super(
          key: key,
          create: create,
          update: (context, value) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            value,
          ),
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );
}
