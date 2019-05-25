part of 'provider.dart';

/// Listens to a [Listenable], expose it to its descendants
/// and rebuilds dependents whenever the listener emits an event.
///
/// See also:
///   * [ChangeNotifierProvider], a subclass of [ListenableProvider] specific to [ChangeNotifier].
///   * [ValueListenableProvider], which listens to a [ValueListenable] but exposes only [ValueListenable.value] instead of the whole object.
///   * [Listenable]
class ListenableProvider<T extends Listenable> extends ValueDelegateWidget<T>
    implements SingleChildCloneableWidget {
  /// Creates a [Listenable] using [builder] and subscribes to it.
  ///
  /// [dispose] can optionally passed to free resources
  /// when [ListenableProvider] is removed from the tree.
  ///
  /// [builder] must not be `null`.
  ListenableProvider({
    Key key,
    @required ValueBuilder<T> builder,
    Disposer<T> dispose,
    Widget child,
  }) : this._(
          key: key,
          delegate: _BuilderListenableDelegate(builder, dispose: dispose),
          child: child,
        );

  /// Listens to [value] and expose it to all of [ListenableProvider] descendants.
  ///
  /// Rebuilding [ListenableProvider] without
  /// changing the instance of [value] will not rebuild dependants.
  ListenableProvider.value({
    Key key,
    @required T value,
    Widget child,
  }) : this._(
          key: key,
          delegate: _ValueListenableDelegate(value),
          child: child,
        );

  ListenableProvider._({
    Key key,
    _ListenableDelegateMixin<T> delegate,
    // TODO: updateShouldNotify for when the listenable instance change with `.value` constructor
    this.child,
  }) : super(
          key: key,
          delegate: delegate,
        );

  /// The widget that is below the current [ListenableProvider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  ListenableProvider<T> cloneWithChild(Widget child) {
    return ListenableProvider._(
      key: key,
      delegate: delegate as _ListenableDelegateMixin<T>,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final delegate = this.delegate as _ListenableDelegateMixin<T>;
    return InheritedProvider<T>(
      value: delegate.value,
      child: child,
      updateShouldNotify: delegate.updateShouldNotify,
    );
  }
}

class _ValueListenableDelegate<T extends Listenable>
    extends SingleValueDelegate<T> with _ListenableDelegateMixin<T> {
  _ValueListenableDelegate(T value) : super(value);

  @override
  void didUpdateDelegate(_ValueListenableDelegate<T> oldDelegate) {
    super.didUpdateDelegate(oldDelegate);
    if (oldDelegate.value != value) {
      _removeListener?.call();
      if (value != null) startListening(value);
    }
  }
}

class _BuilderListenableDelegate<T extends Listenable>
    extends BuilderAdaptiveDelegate<T> with _ListenableDelegateMixin<T> {
  _BuilderListenableDelegate(ValueBuilder<T> builder, {Disposer<T> dispose})
      : super(builder, dispose: dispose);
}

mixin _ListenableDelegateMixin<T extends Listenable>
    on ValueAdaptiveDelegate<T> {
  UpdateShouldNotify<T> updateShouldNotify;
  VoidCallback _removeListener;

  @override
  void initDelegate() {
    super.initDelegate();
    if (value != null) startListening(value);
  }

  @override
  void didUpdateDelegate(StateDelegate old) {
    super.didUpdateDelegate(old);
    final delegate = old as _ListenableDelegateMixin<T>;

    _removeListener = delegate._removeListener;
    updateShouldNotify = delegate.updateShouldNotify;
  }

  void startListening(T listenable) {
    /// The number of time [Listenable] called its listeners.
    ///
    /// It is used to differentiate external rebuilds from rebuilds caused by the listenable emitting an event.
    /// This allows [InheritedWidget.updateShouldNotify] to return true only in the latter scenario.
    var buildCount = 0;
    final setState = this.setState;
    final listener = () => setState(() => buildCount++);

    var capturedBuildCount = buildCount;
    updateShouldNotify = (_, __) {
      final res = buildCount != capturedBuildCount;
      capturedBuildCount = buildCount;
      return res;
    };

    listenable.addListener(listener);
    _removeListener = () {
      listenable.removeListener(listener);
      _removeListener = null;
      updateShouldNotify = null;
    };
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }
}

Widget _listenableProviderBuilder<R extends Listenable>(
  BuildContext context,
  R value,
  Widget child,
) =>
    ListenableProvider<R>.value(listenable: value, child: child);

class ListenableProxyProvider<T, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ListenableProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _listenableProviderBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder<T, R> builder;

  @override
  ListenableProxyProvider<T, R> cloneWithChild(Widget child) {
    return ListenableProxyProvider(
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

class ListenableProxyProvider2<T, T2, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ListenableProxyProvider2({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _listenableProviderBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder2<T, T2, R> builder;

  @override
  ListenableProxyProvider2<T, T2, R> cloneWithChild(Widget child) {
    return ListenableProxyProvider2(
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

class ListenableProxyProvider3<T, T2, T3, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ListenableProxyProvider3({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _listenableProviderBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder3<T, T2, T3, R> builder;

  @override
  ListenableProxyProvider3<T, T2, T3, R> cloneWithChild(Widget child) {
    return ListenableProxyProvider3(
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

class ListenableProxyProvider4<T, T2, T3, T4, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ListenableProxyProvider4({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _listenableProviderBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder4<T, T2, T3, T4, R> builder;

  @override
  ListenableProxyProvider4<T, T2, T3, T4, R> cloneWithChild(Widget child) {
    return ListenableProxyProvider4(
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

class ListenableProxyProvider5<T, T2, T3, T4, T5, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ListenableProxyProvider5({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _listenableProviderBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder;

  @override
  ListenableProxyProvider5<T, T2, T3, T4, T5, R> cloneWithChild(Widget child) {
    return ListenableProxyProvider5(
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

class ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  const ListenableProxyProvider6({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: _listenableProviderBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder;

  @override
  ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R> cloneWithChild(
      Widget child) {
    return ListenableProxyProvider6(
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
