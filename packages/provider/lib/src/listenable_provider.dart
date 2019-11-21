import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/src/inherited_provider.dart';

import 'change_notifier_provider.dart'
    show ChangeNotifierProvider, ChangeNotifierProxyProvider;
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
class ListenableProvider<T extends Listenable> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// Creates a [Listenable] using [create] and subscribes to it.
  ///
  /// [dispose] can optionally passed to free resources
  /// when [ListenableProvider] is removed from the tree.
  ///
  /// [create] must not be `null`.
  ListenableProvider({
    Key key,
    @required ValueBuilder<T> create,
    Disposer<T> dispose,
    this.child,
  })  : assert(create != null),
        _debugCheckType = true,
        _builder = create,
        _dispose = dispose,
        _value = null,
        updateShouldNotify = null,
        super(key: key);

  /// Provides an existing [Listenable].
  ListenableProvider.value({
    Key key,
    @required T value,
    this.updateShouldNotify,
    this.child,
  })  : _value = value,
        _debugCheckType = false,
        _dispose = null,
        _builder = null,
        super(key: key);

  ListenableProvider._(
    this._debugCheckType,
    this._builder,
    this._dispose,
    this._value, {
    Key key,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key);

  static VoidCallback _startListening(
    InheritedProviderElement<Listenable> e,
    Listenable value,
  ) {
    value?.addListener(e.markNeedsNotifyDependents);
    return () => value?.removeListener(e.markNeedsNotifyDependents);
  }

  final ValueBuilder<T> _builder;
  final Disposer<T> _dispose;
  final T _value;
  final bool _debugCheckType;

  /// User-provided custom logic for [InheritedWidget.updateShouldNotify].
  final UpdateShouldNotify<T> updateShouldNotify;

  /// The widget that is below the current [ListenableProvider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  ListenableProvider<T> cloneWithChild(Widget child) {
    return ListenableProvider._(
      _debugCheckType,
      _builder,
      _dispose,
      _value,
      key: key,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_builder != null) {
      void Function(T value) checkType;
      assert(() {
        checkType = (value) {
          if (value is ChangeNotifier) {
            // ignore: invalid_use_of_protected_member
            assert(!value.hasListeners, '''
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
        };
        return true;
      }());
      return InheritedProvider(
        create: _builder,
        dispose: _dispose,
        startListening: _startListening,
        updateShouldNotify: updateShouldNotify,
        debugCheckInvalidValueType: checkType,
        child: child,
      );
    }

    return InheritedProvider.value(
      value: _value,
      startListening: _startListening,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }
}

class _ListenableProxyProvider<R extends Listenable> extends StatelessWidget
    implements SingleChildCloneableWidget {
  _ListenableProxyProvider({
    Key key,
    @required this.create,
    @required this.update,
    this.dispose,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key);

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@macro provider.proxyprovider.update}
  final R Function(BuildContext context, R previous) update;

  final UpdateShouldNotify<R> updateShouldNotify;

  final Disposer<R> dispose;
  final ValueBuilder<R> create;

  @override
  _ListenableProxyProvider<R> cloneWithChild(Widget child) {
    return _ListenableProxyProvider(
      key: key,
      create: create,
      update: update,
      dispose: dispose,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    void Function(R value) checkType;
    assert(() {
      checkType = (value) {
        if (value is ChangeNotifier) {
          // ignore: invalid_use_of_protected_member
          assert(value.hasListeners != true);
        }
      };
      return true;
    }());
    return InheritedProvider<R>(
      create: create,
      update: update,
      dispose: dispose,
      startListening: ListenableProvider._startListening,
      debugCheckInvalidValueType: checkType,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
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
    extends _ListenableProxyProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder<T, R> update,
    Disposer<R> dispose,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider2<T, T2, R extends Listenable>
    extends _ListenableProxyProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider2({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder2<T, T2, R> update,
    Disposer<R> dispose,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider3<T, T2, T3, R extends Listenable>
    extends _ListenableProxyProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider3({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder3<T, T2, T3, R> update,
    Disposer<R> dispose,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider4<T, T2, T3, T4, R extends Listenable>
    extends _ListenableProxyProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider4({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> update,
    Disposer<R> dispose,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider5<T, T2, T3, T4, T5, R extends Listenable>
    extends _ListenableProxyProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider5({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> update,
    Disposer<R> dispose,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider6<T, T2, T3, T4, T5, T6, R extends Listenable>
    extends _ListenableProxyProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider6({
    Key key,
    @required ValueBuilder<R> create,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> update,
    Disposer<R> dispose,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}
