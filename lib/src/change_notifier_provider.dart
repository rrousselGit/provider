import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'delegate_widget.dart';
import 'listenable_provider.dart';
import 'provider.dart';
import 'proxy_provider.dart';

/// Listens to a [ChangeNotifier], expose it to its descendants
/// and rebuilds dependents whenever the [ChangeNotifier.notifyListeners] is called.
///
/// See also:
///   * [ListenableProvider], similar to [ChangeNotifier] but works with any [Listenable].
///   * [ChangeNotifier]
class ChangeNotifierProvider<T extends ChangeNotifier>
    extends ListenableProvider<T> implements SingleChildCloneableWidget {
  static void _disposer(BuildContext context, ChangeNotifier notifier) =>
      notifier?.dispose();

  /// Create a [ChangeNotifier] using the [builder] function and automatically dispose it
  /// when [ChangeNotifierProvider] is removed from the widget tree.
  ///
  /// [builder] must not be `null`.
  ChangeNotifierProvider({
    Key key,
    @required ValueBuilder<T> builder,
    Widget child,
  }) : super(key: key, builder: builder, dispose: _disposer, child: child);

  /// Listens to [value] and expose it to all of [ChangeNotifierProvider] descendants.
  ChangeNotifierProvider.value({
    Key key,
    @required T value,
    Widget child,
  }) : super.value(key: key, value: value, child: child);
}

void _dispose(BuildContext context, ChangeNotifier notifier) =>
    notifier.dispose();

class _NumericProxyProvider<F extends Function, T, T2, T3, T4, T5, T6,
        R extends ChangeNotifier> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  _NumericProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          dispose: _dispose,
        );

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@macro provider.proxyprovider.build}
  final F builder;

  @override
  _NumericProxyProvider<F, T, T2, T3, T4, T5, T6, R> cloneWithChild(
      Widget child) {
    return _NumericProxyProvider(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, R value) {
    return ChangeNotifierProvider<R>.value(
      value: value,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) {
    final arguments = <dynamic>[
      context,
      Provider.of<T>(context),
    ];

    if (T2 != Void) arguments.add(Provider.of<T2>(context));
    if (T3 != Void) arguments.add(Provider.of<T3>(context));
    if (T4 != Void) arguments.add(Provider.of<T4>(context));
    if (T5 != Void) arguments.add(Provider.of<T5>(context));
    if (T6 != Void) arguments.add(Provider.of<T6>(context));

    arguments.add(previous);
    return Function.apply(builder, arguments) as R;
  }
}

mixin _Noop {}

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider<T, R extends ChangeNotifier> = _NumericProxyProvider<
    ProxyProviderBuilder<T, R>, T, Void, Void, Void, Void, Void, R> with _Noop;

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider2<T, T2, R extends ChangeNotifier> = _NumericProxyProvider<
    ProxyProviderBuilder2<T, T2, R>,
    T,
    T2,
    Void,
    Void,
    Void,
    Void,
    R> with _Noop;

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider3<T, T2, T3, R extends ChangeNotifier> = _NumericProxyProvider<
    ProxyProviderBuilder3<T, T2, T3, R>,
    T,
    T2,
    T3,
    Void,
    Void,
    Void,
    R> with _Noop;

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider4<T, T2, T3, T4, R extends ChangeNotifier> = _NumericProxyProvider<
    ProxyProviderBuilder4<T, T2, T3, T4, R>,
    T,
    T2,
    T3,
    T4,
    Void,
    Void,
    R> with _Noop;

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider5<T, T2, T3, T4, T5, R extends ChangeNotifier> = _NumericProxyProvider<
    ProxyProviderBuilder5<T, T2, T3, T4, T5, R>,
    T,
    T2,
    T3,
    T4,
    T5,
    Void,
    R> with _Noop;

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider6<T, T2, T3, T4, T5, T6, R extends ChangeNotifier> = _NumericProxyProvider<
    ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R>,
    T,
    T2,
    T3,
    T4,
    T5,
    T6,
    R> with _Noop;
