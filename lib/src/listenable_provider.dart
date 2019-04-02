import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/adaptative_builder_widget.dart';
import 'package:provider/src/provider.dart';

class ListenableProvider<T extends Listenable>
    extends AdaptativeBuilderWidget<T, T>
    implements SingleChildCloneableWidget {
  const ListenableProvider.value({
    Key key,
    @required T listenable,
    this.child,
  })  : dispose = null,
        super.value(key: key, value: listenable);

  const ListenableProvider({
    Key key,
    this.dispose,
    ValueBuilder<T> builder,
    this.child,
  }) : super(key: key, builder: builder);

  final Disposer<T> dispose;
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
    with AdaptativeBuilderWidgetStateMixin<T, T, ListenableProvider<T>> {
  /// The number of time [Listenable] called its listeners.
  ///
  /// It is used to differentiate external rebuilds from rebuilds caused by the listenable emitting an event.
  /// This allows [InheritedWidget.updateShouldNotify] to return true only in the latter scenario.
  int _buildCount;
  UpdateShouldNotify<T> updateShouldNotify;

  void listener() {
    setState(() {
      _buildCount ??= 0;
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
    final capturedBuildCount = _buildCount;
    return updateShouldNotify = (_, __) => _buildCount != capturedBuildCount;
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
    if (oldValue != null) stopListening(oldValue);
    if (newValue != null) startListening(newValue);
  }
}

class ChangeNotifierProvider<T extends ChangeNotifier>
    extends ListenableProvider<T> implements SingleChildCloneableWidget {
  static void _disposer(BuildContext context, ChangeNotifier notifier) =>
      notifier?.dispose();

  const ChangeNotifierProvider.value({
    Key key,
    T notifier,
    Widget child,
  }) : super.value(key: key, listenable: notifier, child: child);

  const ChangeNotifierProvider({
    Key key,
    ValueBuilder<T> builder,
    Widget child,
  }) : super(
          key: key,
          builder: builder,
          dispose: _disposer,
          child: child,
        );

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

/// Expose the current value of a [ValueListenable].
///
/// Changing [listenable] will stop listening to the previous [listenable] and listen the new one.
/// Removing [ValueListenableProvider] from the tree will also stop listening to [listenable].
///
///
/// ```dart
/// ValueListenable<int> foo;
///
/// ValueListenableProvider<int>(
///   listenable: foo,
///   child: Container(),
/// );
class ValueListenableProvider<T> extends AnimatedWidget
    implements SingleChildCloneableWidget {
  /// Allow configuring [Key]
  ValueListenableProvider.value({
    Key key,
    @required ValueListenable<T> listenable,
    this.child,
    this.updateShouldNotify,
  }) : super(key: key, listenable: listenable);

  @override
  ValueListenable<T> get listenable => super.listenable as ValueListenable<T>;

  final Widget child;
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  Widget build(BuildContext context) {
    return Provider<T>.value(
      value: listenable.value,
      child: child,
      updateShouldNotify: updateShouldNotify,
    );
  }

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) {
    return ValueListenableProvider.value(
      key: key,
      listenable: listenable,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }
}
