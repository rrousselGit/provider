import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
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
class ListenableProvider<T extends Listenable>
    extends SingleChildStatelessWidget {
  /// Creates a [Listenable] using [create] and subscribes to it.
  ///
  /// [dispose] can optionally passed to free resources
  /// when [ListenableProvider] is removed from the tree.
  ///
  /// [create] must not be `null`.
  ListenableProvider({
    Key key,
    @required Create<T> create,
    Dispose<T> dispose,
    Widget child,
  })  : assert(create != null),
        _create = create,
        _dispose = dispose,
        _value = null,
        updateShouldNotify = null,
        super(key: key, child: child);

  /// Provides an existing [Listenable].
  ListenableProvider.value({
    Key key,
    @required T value,
    this.updateShouldNotify,
    Widget child,
  })  : _value = value,
        _dispose = null,
        _create = null,
        super(key: key, child: child);

  static VoidCallback _startListening(
    InheritedProviderElement<Listenable> e,
    Listenable value,
  ) {
    value?.addListener(e.markNeedsNotifyDependents);
    return () => value?.removeListener(e.markNeedsNotifyDependents);
  }

  final Create<T> _create;
  final Dispose<T> _dispose;
  final T _value;

  /// User-provided custom logic for [InheritedWidget.updateShouldNotify].
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    if (_create != null) {
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
        create: _create,
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

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider0<R extends Listenable>
    extends InheritedProvider<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider0({
    Key key,
    @required Create<R> create,
    @required R Function(BuildContext, R previous) update,
    Dispose<R> dispose,
    UpdateShouldNotify<R> updateShouldNotify,
    Widget child,
  })  : assert(create != null || update != null),
        super(
          key: key,
          create: create,
          update: update,
          dispose: dispose,
          updateShouldNotify: updateShouldNotify,
          startListening: ListenableProvider._startListening,
          debugCheckInvalidValueType: kReleaseMode
              ? null
              : (value) {
                  if (value is ChangeNotifier) {
                    // ignore: invalid_use_of_protected_member
                    assert(value.hasListeners != true);
                  }
                },
          child: child,
        );
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
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider({
    Key key,
    @required Create<R> create,
    @required ProxyProviderBuilder<T, R> update,
    Dispose<R> dispose,
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
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider2({
    Key key,
    @required Create<R> create,
    @required ProxyProviderBuilder2<T, T2, R> update,
    Dispose<R> dispose,
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
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider3({
    Key key,
    @required Create<R> create,
    @required ProxyProviderBuilder3<T, T2, T3, R> update,
    Dispose<R> dispose,
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
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider4({
    Key key,
    @required Create<R> create,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> update,
    Dispose<R> dispose,
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
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider5({
    Key key,
    @required Create<R> create,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> update,
    Dispose<R> dispose,
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
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider6({
    Key key,
    @required Create<R> create,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> update,
    Dispose<R> dispose,
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
