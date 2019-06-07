import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'change_notifier_provider.dart' show ChangeNotifierProvider;
import 'delegate_widget.dart';
import 'provider.dart';
import 'proxy_provider.dart';
import 'value_listenable_provider.dart' show ValueListenableProvider;

/// Listens to a [Listenable], expose it to its descendants
/// and rebuilds dependents whenever the listener emits an event.
///
/// See also:
///
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
    @required _ListenableDelegateMixin<T> delegate,
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
      updateShouldNotify: delegate.updateShouldNotify,
      child: child,
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
    extends BuilderStateDelegate<T> with _ListenableDelegateMixin<T> {
  _BuilderListenableDelegate(ValueBuilder<T> builder, {Disposer<T> dispose})
      : super(builder, dispose: dispose);
}

mixin _ListenableDelegateMixin<T extends Listenable>
    on ValueStateDelegate<T> {
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

class _NumericProxyProvider<T, T2, T3, T4, T5, T6, R extends Listenable>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  _NumericProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    this.child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          dispose: dispose,
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
      dispose: dispose,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, R value) {
    return ListenableProvider<R>.value(
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
class ListenableProxyProvider<T, R extends Listenable>
    extends _NumericProxyProvider<T, Void, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder<T, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder<T, R> get builder =>
      super.builder as ProxyProviderBuilder<T, R>;
}

/// {@macro provider.proxyprovider}
class ListenableProxyProvider2<T, T2, R extends Listenable>
    extends _NumericProxyProvider<T, T2, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider2({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder2<T, T2, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder2<T, T2, R> get builder =>
      super.builder as ProxyProviderBuilder2<T, T2, R>;
}

/// {@macro provider.proxyprovider}
class ListenableProxyProvider3<T, T2, T3, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider3({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder3<T, T2, T3, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder3<T, T2, T3, R> get builder =>
      super.builder as ProxyProviderBuilder3<T, T2, T3, R>;
}

/// {@macro provider.proxyprovider}
class ListenableProxyProvider4<T, T2, T3, T4, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, T4, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider4({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder4<T, T2, T3, T4, R> get builder =>
      super.builder as ProxyProviderBuilder4<T, T2, T3, T4, R>;
}

/// {@macro provider.proxyprovider}
class ListenableProxyProvider5<T, T2, T3, T4, T5, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, T4, T5, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider5({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder5<T, T2, T3, T4, T5, R> get builder =>
      super.builder as ProxyProviderBuilder5<T, T2, T3, T4, T5, R>;
}

/// {@macro provider.proxyprovider}
class ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, T4, T5, T6, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider6({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> get builder =>
      super.builder as ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R>;
}
