import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/adaptive_builder_widget.dart';
import 'package:provider/src/provider.dart';

/// Listens to a [Listenable], expose it to its descendants
/// and rebuilds dependents whenever the listener emits an event.
///
/// See also:
///   * [ChangeNotifierProvider], a subclass of [ListenableProvider] specific to [ChangeNotifier].
///   * [ValueListenableProvider], which listens to a [ValueListenable] but exposes only [ValueListenable.value] instead of the whole object.
///   * [Listenable]
class ListenableProvider<T extends Listenable>
    extends AdaptiveBuilderWidget<T, T> implements SingleChildCloneableWidget {
  /// Creates a [Listenable] using [builder] and subscribes to it.
  ///
  /// [dispose] can optionally passed to free resources
  /// when [ListenableProvider] is removed from the tree.
  ///
  /// [builder] must not be `null`.
  const ListenableProvider({
    Key key,
    @required ValueBuilder<T> builder,
    this.dispose,
    this.child,
  }) : super(key: key, builder: builder);

  /// Listens [listenable] and expose it to all of [ListenableProvider] descendants.
  ///
  /// Rebuilding [ListenableProvider] without
  /// changing the instance of [listenable] will not rebuild dependants.
  const ListenableProvider.value({
    Key key,
    @required T listenable,
    this.child,
  })  : dispose = null,
        super.value(key: key, value: listenable);

  /// Function used to dispose of an object created by [builder].
  ///
  /// [dispose] will be called whenever [ListenableProvider] is removed from the tree
  /// or when switching from [ListenableProvider] to [ListenableProvider.value] constructor.
  final Disposer<T> dispose;

  /// The widget that is below the current [ListenableProvider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _ListenableProviderState<T> createState() => _ListenableProviderState<T>();

  @override
  ListenableProvider<T> cloneWithChild(Widget child) {
    return builder != null
        ? ListenableProvider(
            key: key,
            builder: builder,
            dispose: dispose,
            child: child,
          )
        : ListenableProvider.value(
            key: key,
            listenable: value,
            child: child,
          );
  }
}

class _ListenableProviderState<T extends Listenable>
    extends State<ListenableProvider<T>>
    with AdaptiveBuilderWidgetStateMixin<T, T, ListenableProvider<T>> {
  /// The number of time [Listenable] called its listeners.
  ///
  /// It is used to differentiate external rebuilds from rebuilds caused by the listenable emitting an event.
  /// This allows [InheritedWidget.updateShouldNotify] to return true only in the latter scenario.
  int _buildCount = 0;
  UpdateShouldNotify<T> updateShouldNotify;

  void listener() {
    setState(() {
      _buildCount++;
    });
  }

  void startListening(T listenable) {
    updateShouldNotify = createUpdateShouldNotify();
    listenable.addListener(listener);
  }

  void stopListening(T listenable) {
    listenable?.removeListener(listener);
  }

  UpdateShouldNotify<T> createUpdateShouldNotify() {
    var capturedBuildCount = _buildCount;
    return updateShouldNotify = (_, __) {
      final res = _buildCount != capturedBuildCount;
      capturedBuildCount = _buildCount;
      return res;
    };
  }

  @override
  Widget build(BuildContext context) {
    return Provider<T>.value(
      value: value,
      child: widget.child,
      updateShouldNotify: updateShouldNotify,
    );
  }

  @override
  T didBuild(T built) {
    return built;
  }

  @override
  void disposeBuilt(ListenableProvider<T> widget, T built) {
    if (widget.dispose != null) {
      widget.dispose(context, built);
    }
  }

  @override
  void dispose() {
    stopListening(value);
    super.dispose();
  }

  @override
  void changeValue(ListenableProvider<T> oldWidget, T oldValue, T newValue) {
    if (oldValue != newValue) {
      if (oldValue != null) stopListening(oldValue);
      if (newValue != null) startListening(newValue);
    }
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
  const ChangeNotifierProvider({
    Key key,
    @required ValueBuilder<T> builder,
    Widget child,
  }) : super(key: key, builder: builder, dispose: _disposer, child: child);

  /// Listens to [notifier] and expose it to all of [ChangeNotifierProvider] descendants.
  const ChangeNotifierProvider.value({
    Key key,
    @required T notifier,
    Widget child,
  }) : super.value(key: key, listenable: notifier, child: child);

  // While the behavior doesn't change between ChangeNotifierProvider and ListenableProvider
  // it is required to override `cloneWithChild` because the `runtimeType` is different, which Flutter use.
  @override
  ChangeNotifierProvider<T> cloneWithChild(Widget child) {
    return builder != null
        ? ChangeNotifierProvider(
            key: key,
            builder: builder,
            child: child,
          )
        : ChangeNotifierProvider.value(
            key: key,
            notifier: value,
            child: child,
          );
  }
}

/// Listens to a [ValueListenable] and expose its current value.
class ValueListenableProvider<T>
    extends AdaptiveBuilderWidget<ValueListenable<T>, ValueNotifier<T>>
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
  const ValueListenableProvider({
    Key key,
    @required ValueBuilder<ValueNotifier<T>> builder,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, builder: builder);

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
  const ValueListenableProvider.value({
    Key key,
    @required ValueListenable<T> valueListenable,
    this.updateShouldNotify,
    this.child,
  }) : super.value(key: key, value: valueListenable);

  /// The widget that is below the current [ValueListenableProvider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@macro provider.updateshouldnotify}
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  _ValueListenableProviderState<T> createState() =>
      _ValueListenableProviderState<T>();

  @override
  ValueListenableProvider<T> cloneWithChild(Widget child) {
    return builder != null
        ? ValueListenableProvider(key: key, builder: builder, child: child)
        : ValueListenableProvider.value(
            key: key,
            valueListenable: value,
            child: child,
          );
  }
}

class _ValueListenableProviderState<T> extends State<ValueListenableProvider<T>>
    with
        AdaptiveBuilderWidgetStateMixin<ValueListenable<T>, ValueNotifier<T>,
            ValueListenableProvider<T>> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: value,
      builder: (_, value, child) {
        return Provider<T>.value(
          value: value,
          child: widget.child,
          updateShouldNotify: widget.updateShouldNotify,
        );
      },
      child: widget.child,
    );
  }

  @override
  ValueListenable<T> didBuild(ValueNotifier<T> built) {
    return built;
  }

  @override
  void disposeBuilt(
      ValueListenableProvider<T> oldWidget, ValueNotifier<T> built) {
    built.dispose();
  }
}
