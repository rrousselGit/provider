import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'change_notifier_provider.dart'
    show ChangeNotifierProvider, ChangeNotifierProxyProvider;
import 'delegate_widget.dart';
import 'provider.dart';
import 'proxy_provider.dart';

/// Listens to a [Listenable], expose it to its descendants and rebuilds
/// dependents whenever the listener emits an event.
///
/// For usage informations, see [ChangeNotifierProvider], a subclass of
/// [ListenableProvider] made for [ChangeNotifier].
///
/// You will generaly want to use [ChangeNotifierProvider] instead.
/// But [ListenableProvider] is available in case you want to implement
/// [Listenable] yourself, or use [Animation].
class ListenableProvider<T extends Listenable> extends ValueDelegateWidget<T>
    implements SingleChildCloneableWidget {
  /// Creates a [Listenable] using `create` and subscribes to it.
  ///
  /// [dispose] can optionally passed to free resources
  /// when [ListenableProvider] is removed from the tree.
  ///
  /// `create` must not be `null`.
  ListenableProvider({
    Key key,
    @required ValueBuilder<T> create,
    @Deprecated('Will be removed as part of 4.0.0, use create instead')
        ValueBuilder<T> builder,
    Disposer<T> dispose,
    Widget child,
  }) : this._(
          key: key,
          delegate:
              // ignore: deprecated_member_use_from_same_package
              _BuilderListenableDelegate(create ?? builder, dispose: dispose),
          child: child,
        );

  /// Provides an existing [Listenable].
  ListenableProvider.value({
    Key key,
    @required T value,
    Widget child,
  }) : this._(
          key: key,
          delegate: _ValueListenableDelegate(value),
          child: child,
        );

  ListenableProvider._valueDispose({
    Key key,
    @required T value,
    Disposer<T> disposer,
    Widget child,
  }) : this._(
          key: key,
          delegate: _ValueListenableDelegate(value, disposer),
          child: child,
        );

  ListenableProvider._({
    Key key,
    @required _ListenableDelegateMixin<T> delegate,
    // ignore: lines_longer_than_80_chars
    // TODO: updateShouldNotify for when the listenable instance change with `.value` constructor
    this.child,
  }) : super(key: key, delegate: delegate);

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
  _ValueListenableDelegate(T value, [this.disposer]) : super(value);

  final Disposer<T> disposer;

  @override
  void didUpdateDelegate(_ValueListenableDelegate<T> oldDelegate) {
    super.didUpdateDelegate(oldDelegate);
    if (oldDelegate.value != value) {
      _removeListener?.call();
      oldDelegate.disposer?.call(context, oldDelegate.value);
      if (value != null) startListening(value, rebuild: true);
    }
  }

  @override
  void startListening(T listenable, {bool rebuild = false}) {
    assert(disposer == null || debugCheckIsNewlyCreatedListenable(listenable));
    super.startListening(listenable, rebuild: rebuild);
  }
}

class _BuilderListenableDelegate<T extends Listenable>
    extends BuilderStateDelegate<T> with _ListenableDelegateMixin<T> {
  _BuilderListenableDelegate(ValueBuilder<T> create, {Disposer<T> dispose})
      : super(create, dispose: dispose);

  @override
  void startListening(T listenable, {bool rebuild = false}) {
    assert(debugCheckIsNewlyCreatedListenable(listenable));
    super.startListening(listenable, rebuild: rebuild);
  }
}

mixin _ListenableDelegateMixin<T extends Listenable> on ValueStateDelegate<T> {
  UpdateShouldNotify<T> updateShouldNotify;
  VoidCallback _removeListener;

  bool debugCheckIsNewlyCreatedListenable(Listenable listenable) {
    if (listenable is ChangeNotifier) {
      // ignore: invalid_use_of_protected_member
      assert(!listenable.hasListeners, '''
The default constructor of ListenableProvider/ChangeNotifierProvider
must create a new, unused Listenable.

If you want to reuse an existing Listenable, use the second constructor:

- DO use ChangeNotifierProvider.value to provider an existing ChangeNotifier:

MyChangeNotifier variable;
ChangeNotifierProvider.value(
  value: variable,
  child: ...
)

- DON'T reuse an existing ChangeNotifier using the default constructor.

MyChangeNotifier variable;
ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
''');
    }
    return true;
  }

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

  void startListening(T listenable, {bool rebuild = false}) {
    /// The number of time [Listenable] called its listeners.
    ///
    /// It is used to differentiate external rebuilds from rebuilds caused by
    /// the listenable emitting an event.  This allows
    /// [InheritedWidget.updateShouldNotify] to return true only in the latter
    /// scenario.
    var buildCount = 0;
    final setState = this.setState;
    final listener = () => setState(() => buildCount++);

    var capturedBuildCount = buildCount;
    // purposefully desynchronize buildCount and capturedBuildCount
    // after an update to ensure that the first updateShouldNotify returns true
    if (rebuild) capturedBuildCount--;
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
    @required ValueBuilder<R> initialBuilder,
    @required this.builder,
    Disposer<R> dispose,
    this.child,
  })  : assert(builder != null),
        super(
          key: key,
          create: initialBuilder,
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
    return ListenableProvider<R>._valueDispose(
      value: value,
      disposer: dispose,
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

/// {@template provider.listenableproxyprovider}
/// A variation of [ListenableProvider] that builds its value from
/// values obtained from other providers.
///
/// See the discussion on [ChangeNotifierProxyProvider] for a complete
/// explanation on how to use it.
///
/// [ChangeNotifierProxyProvider] extends [ListenableProxyProvider] to make it
/// work with [ChangeNotifier], but the behavior stays the same.
/// Most of the time you'll want to use [ChangeNotifierProxyProvider] instead.
/// But [ListenableProxyProvider] is exposed in case one wants to use a
/// [Listenable] implementation other than [ChangeNotifier], such as
/// [Animation].
/// {@endtemplate}
class ListenableProxyProvider<T, R extends Listenable>
    extends _NumericProxyProvider<T, Void, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder<T, R> update,
    @Deprecated('will be removed in 4.0.0, use create instead')
        ValueBuilder<R> initialBuilder,
    @Deprecated('will be removed in 4.0.0, use update instead')
        ProxyProviderBuilder<T, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          // ignore: deprecated_member_use_from_same_package
          initialBuilder: create ?? initialBuilder,
          // ignore: deprecated_member_use_from_same_package
          builder: update ?? builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder<T, R> get builder =>
      super.builder as ProxyProviderBuilder<T, R>;
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider2<T, T2, R extends Listenable>
    extends _NumericProxyProvider<T, T2, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider2({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder2<T, T2, R> update,
    @Deprecated('will be removed in 4.0.0, use create instead')
        ValueBuilder<R> initialBuilder,
    @Deprecated('will be removed in 4.0.0, use update instead')
        ProxyProviderBuilder2<T, T2, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          // ignore: deprecated_member_use_from_same_package
          initialBuilder: create ?? initialBuilder,
          // ignore: deprecated_member_use_from_same_package
          builder: update ?? builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder2<T, T2, R> get builder =>
      super.builder as ProxyProviderBuilder2<T, T2, R>;
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider3<T, T2, T3, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider3({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder3<T, T2, T3, R> update,
    @Deprecated('will be removed in 4.0.0, use create instead')
        ValueBuilder<R> initialBuilder,
    @Deprecated('will be removed in 4.0.0, use update instead')
        ProxyProviderBuilder3<T, T2, T3, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          // ignore: deprecated_member_use_from_same_package
          initialBuilder: create ?? initialBuilder,
          // ignore: deprecated_member_use_from_same_package
          builder: update ?? builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder3<T, T2, T3, R> get builder =>
      super.builder as ProxyProviderBuilder3<T, T2, T3, R>;
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider4<T, T2, T3, T4, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, T4, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider4({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> update,
    @Deprecated('will be removed in 4.0.0, use create instead')
        ValueBuilder<R> initialBuilder,
    @Deprecated('will be removed in 4.0.0, use update instead')
        ProxyProviderBuilder4<T, T2, T3, T4, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          // ignore: deprecated_member_use_from_same_package
          initialBuilder: create ?? initialBuilder,
          // ignore: deprecated_member_use_from_same_package
          builder: update ?? builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder4<T, T2, T3, T4, R> get builder =>
      super.builder as ProxyProviderBuilder4<T, T2, T3, T4, R>;
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider5<T, T2, T3, T4, T5, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, T4, T5, Void, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider5({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> update,
    @Deprecated('will be removed in 4.0.0, use create instead')
        ValueBuilder<R> initialBuilder,
    @Deprecated('will be removed in 4.0.0, use update instead')
        ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          // ignore: deprecated_member_use_from_same_package
          initialBuilder: create ?? initialBuilder,
          // ignore: deprecated_member_use_from_same_package
          builder: update ?? builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder5<T, T2, T3, T4, T5, R> get builder =>
      super.builder as ProxyProviderBuilder5<T, T2, T3, T4, T5, R>;
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R extends Listenable>
    extends _NumericProxyProvider<T, T2, T3, T4, T5, T6, R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider6({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> update,
    @Deprecated('will be removed in 4.0.0, use create instead')
        ValueBuilder<R> initialBuilder,
    @Deprecated('will be removed in 4.0.0, use update instead')
        ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          // ignore: deprecated_member_use_from_same_package
          initialBuilder: create ?? initialBuilder,
          // ignore: deprecated_member_use_from_same_package
          builder: update ?? builder,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> get builder =>
      super.builder as ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R>;
}
