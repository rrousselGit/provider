import 'package:flutter/widgets.dart';

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

Widget _changeNotifierProviderBuilder<R extends ChangeNotifier>(
  BuildContext context,
  R value,
  Widget child,
) =>
    ChangeNotifierProvider<R>.value(value: value, child: child);

void _dispose(BuildContext context, ChangeNotifier notifier) =>
    notifier.dispose();

class ChangeNotifierProxyProvider<T, R extends ChangeNotifier>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ChangeNotifierProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _changeNotifierProviderBuilder,
          dispose: _dispose,
          child: child,
        );

  final ProxyProviderBuilder<T, R> builder;

  @override
  ChangeNotifierProxyProvider<T, R> cloneWithChild(Widget child) {
    return ChangeNotifierProxyProvider(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        previous,
      );
}

class ChangeNotifierProxyProvider2<T, T2, R extends ChangeNotifier>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ChangeNotifierProxyProvider2({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _changeNotifierProviderBuilder,
          dispose: _dispose,
          child: child,
        );

  final ProxyProviderBuilder2<T, T2, R> builder;

  @override
  ChangeNotifierProxyProvider2<T, T2, R> cloneWithChild(Widget child) {
    return ChangeNotifierProxyProvider2(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        previous,
      );
}

class ChangeNotifierProxyProvider3<T, T2, T3, R extends ChangeNotifier>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ChangeNotifierProxyProvider3({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _changeNotifierProviderBuilder,
          dispose: _dispose,
          child: child,
        );

  final ProxyProviderBuilder3<T, T2, T3, R> builder;

  @override
  ChangeNotifierProxyProvider3<T, T2, T3, R> cloneWithChild(Widget child) {
    return ChangeNotifierProxyProvider3(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        previous,
      );
}

class ChangeNotifierProxyProvider4<T, T2, T3, T4, R extends ChangeNotifier>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ChangeNotifierProxyProvider4({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _changeNotifierProviderBuilder,
          dispose: _dispose,
          child: child,
        );

  final ProxyProviderBuilder4<T, T2, T3, T4, R> builder;

  @override
  ChangeNotifierProxyProvider4<T, T2, T3, T4, R> cloneWithChild(Widget child) {
    return ChangeNotifierProxyProvider4(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        Provider.of<T4>(context),
        previous,
      );
}

class ChangeNotifierProxyProvider5<T, T2, T3, T4, T5, R extends ChangeNotifier>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ChangeNotifierProxyProvider5({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _changeNotifierProviderBuilder,
          dispose: _dispose,
          child: child,
        );

  final ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder;

  @override
  ChangeNotifierProxyProvider5<T, T2, T3, T4, T5, R> cloneWithChild(
      Widget child) {
    return ChangeNotifierProxyProvider5(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        Provider.of<T4>(context),
        Provider.of<T5>(context),
        previous,
      );
}

class ChangeNotifierProxyProvider6<T, T2, T3, T4, T5, T6,
        R extends ChangeNotifier> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ChangeNotifierProxyProvider6({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _changeNotifierProviderBuilder,
          dispose: _dispose,
          child: child,
        );

  final ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder;

  @override
  ChangeNotifierProxyProvider6<T, T2, T3, T4, T5, T6, R> cloneWithChild(
      Widget child) {
    return ChangeNotifierProxyProvider6(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        Provider.of<T4>(context),
        Provider.of<T5>(context),
        Provider.of<T6>(context),
        previous,
      );
}
