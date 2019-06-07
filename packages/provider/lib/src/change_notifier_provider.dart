import 'package:flutter/widgets.dart';

import 'delegate_widget.dart';
import 'listenable_provider.dart';
import 'provider.dart';
import 'proxy_provider.dart';

/// Listens to a [ChangeNotifier], expose it to its descendants
/// and rebuilds dependents whenever the [ChangeNotifier.notifyListeners] is called.
///
/// See also:
///
///   * [ChangeNotifier], which is listened by [ChangeNotifierProvider].
///   * [ListenableProvider], similar to [ChangeNotifierProvider] but works with any [Listenable].
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

class _NumericProxyProvider<T, T2, T3, T4, T5, T6, R extends ChangeNotifier>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  _NumericProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          dispose: ChangeNotifierProvider._disposer,
        );

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@macro provider.proxyprovider.builder}
  final Function builder;

  @override
  _NumericProxyProvider<T, T2, T3, T4, T5, T6, R> cloneWithChild(Widget child) {
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

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider<T, R extends ChangeNotifier>
    extends _NumericProxyProvider<T, Void, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder<T, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          child: child,
        );

  @override
  ProxyProviderBuilder<T, R> get builder =>
      super.builder as ProxyProviderBuilder<T, R>;
}

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider2<T, T2, R extends ChangeNotifier>
    extends _NumericProxyProvider<T, T2, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider2({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder2<T, T2, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          child: child,
        );

  @override
  ProxyProviderBuilder2<T, T2, R> get builder =>
      super.builder as ProxyProviderBuilder2<T, T2, R>;
}

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider3<T, T2, T3, R extends ChangeNotifier>
    extends _NumericProxyProvider<T, T2, T3, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider3({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder3<T, T2, T3, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          child: child,
        );

  @override
  ProxyProviderBuilder3<T, T2, T3, R> get builder =>
      super.builder as ProxyProviderBuilder3<T, T2, T3, R>;
}

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider4<T, T2, T3, T4, R extends ChangeNotifier>
    extends _NumericProxyProvider<T, T2, T3, T4, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider4({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          child: child,
        );

  @override
  ProxyProviderBuilder4<T, T2, T3, T4, R> get builder =>
      super.builder as ProxyProviderBuilder4<T, T2, T3, T4, R>;
}

/// {@macro provider.proxyprovider}

class ChangeNotifierProxyProvider5<T, T2, T3, T4, T5, R extends ChangeNotifier>
    extends _NumericProxyProvider<T, T2, T3, T4, T5, Void, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider5({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          child: child,
        );

  @override
  ProxyProviderBuilder5<T, T2, T3, T4, T5, R> get builder =>
      super.builder as ProxyProviderBuilder5<T, T2, T3, T4, T5, R>;
}

/// {@macro provider.proxyprovider}
class ChangeNotifierProxyProvider6<T, T2, T3, T4, T5, T6,
        R extends ChangeNotifier>
    extends _NumericProxyProvider<T, T2, T3, T4, T5, T6, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider6({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          child: child,
        );

  @override
  ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> get builder =>
      super.builder as ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R>;
}
