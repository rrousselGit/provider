import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/adaptive_builder_widget.dart' hide ValueBuilder;
import 'package:provider/src/delegate_widget.dart';
import 'package:provider/src/provider.dart';

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

  /// Listens [listenable] and expose it to all of [ListenableProvider] descendants.
  ///
  /// Rebuilding [ListenableProvider] without
  /// changing the instance of [listenable] will not rebuild dependants.
  ListenableProvider.value({
    Key key,
    @required T listenable,
    Widget child,
  }) : this._(
          key: key,
          delegate: _ValueListenableDelegate(listenable),
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
    extends SingleNotifierDelegate<T> with _ListenableDelegateMixin<T> {
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

  /// Listens to [notifier] and expose it to all of [ChangeNotifierProvider] descendants.
  ChangeNotifierProvider.value({
    Key key,
    @required T notifier,
    Widget child,
  }) : super.value(key: key, listenable: notifier, child: child);
}

/// Listens to a [ValueListenable] and expose its current value.
class ValueListenableProvider<T> extends ValueDelegateWidget<ValueListenable<T>>
    implements SingleChildCloneableWidget {
  /// Creates a [ValueNotifier] using [builder] and automatically dispose it
  /// when [ValueListenableProvider] is removed from the tree.
  ///
  /// [builder] must not be `null`.
  ///
  /// {@macro provider.updateshouldnotify}
  /// See also:
  ///   * [ValueListenable]
  ///   * [ListenableProvider], similar to [ValueListenableProvider] but for any kind of [Listenable].
  ValueListenableProvider({
    Key key,
    @required ValueBuilder<ValueNotifier<T>> builder,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: BuilderAdaptiveDelegate<ValueNotifier<T>>(
            builder,
            dispose: _dispose,
          ),
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  /// Listens to [valueListenable] and exposes its current value.
  ///
  /// Changing [valueListenable] will stop listening to the previous [valueListenable] and listen the new one.
  /// Removing [ValueListenableProvider] from the tree will also stop listening to [valueListenable].
  ///
  /// ```dart
  /// ValueListenable<int> foo;
  ///
  /// ValueListenableProvider<int>.value(
  ///   valueListenable: foo,
  ///   child: Container(),
  /// );
  /// ```
  ValueListenableProvider.value({
    Key key,
    @required ValueListenable<T> valueListenable,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: SingleNotifierDelegate(valueListenable),
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  ValueListenableProvider._({
    Key key,
    ValueAdaptiveDelegate<ValueListenable<T>> delegate,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  static void _dispose(BuildContext context, ValueNotifier notifier) {
    notifier.dispose();
  }

  /// The widget that is below the current [ValueListenableProvider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@macro provider.updateshouldnotify}
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  ValueListenableProvider<T> cloneWithChild(Widget child) {
    return ValueListenableProvider._(
      key: key,
      delegate: delegate,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: delegate.value,
      builder: (_, value, child) {
        return InheritedProvider<T>(
          value: value,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );
      },
      child: child,
    );
  }
}
