import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

/// An handler for the disposal of an object
typedef void Disposer<T>(T value);

/// A function that creates an object
typedef T ValueBuilder<T>();

class ListenableProvider<T extends Listenable> extends StatefulWidget
    implements SingleChildClonableWidget {
  const ListenableProvider({
    Key key,
    @required this.listenable,
    this.child,
  })  : dispose = null,
        builder = null,
        super(key: key);

  const ListenableProvider.builder({
    Key key,
    this.dispose,
    this.builder,
    this.child,
  })  : listenable = null,
        assert(builder != null),
        super(key: key);

  const ListenableProvider._({
    Key key,
    this.dispose,
    this.builder,
    this.listenable,
    this.child,
  }) : super(key: key);

  final ValueBuilder<T> builder;
  final Disposer<T> dispose;
  final T listenable;
  final Widget child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('listenable', listenable));
  }

  @override
  _ListenableProviderState<T> createState() => _ListenableProviderState<T>();

  @override
  ListenableProvider<T> cloneWithChild(Widget child) {
    return ListenableProvider<T>._(
      key: key,
      builder: builder,
      listenable: listenable,
      dispose: dispose,
      child: child,
    );
  }
}

class _ListenableProviderState<T extends Listenable>
    extends State<ListenableProvider<T>> {
  static bool didChangeBetweenDefaultAndBuilderConstructor(
    ListenableProvider oldWidget,
    ListenableProvider widget,
  ) =>
      isBuilderConstructor(oldWidget) != isBuilderConstructor(widget);

  static bool isBuilderConstructor(ListenableProvider provider) =>
      provider.builder != null;

  /// The number of time [Listenable] called its listeners.
  ///
  /// It is used to differentiate external rebuilds from rebuilds caused by the listenable emitting an event.
  /// This allows [InheritedWidget.updateShouldNotify] to return true only in the latter scenario.
  int buildCount = 0;
  UpdateShouldNotify<T> updateShouldNotify;
  T listenable;

  @override
  void initState() {
    super.initState();
    startListening();
  }

  void listener() {
    setState(() {
      buildCount++;
    });
  }

  void startListening() {
    listenable = widget.listenable ?? widget.builder();
    updateShouldNotify = createUpdateShouldNotify();
    listenable.addListener(listener);
  }

  void stopListening() {
    listenable.removeListener(listener);
    if (widget.dispose != null) {
      // if we have a dispose, then we're using builder constructor so we can safely call the method
      widget.dispose(listenable);
    }
    listenable = null;
  }

  UpdateShouldNotify<T> createUpdateShouldNotify() {
    final capturedBuildCount = buildCount;
    return updateShouldNotify = (_, __) => buildCount == capturedBuildCount;
  }

  @override
  void didUpdateWidget(ListenableProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (didChangeBetweenDefaultAndBuilderConstructor(oldWidget, widget) ||
        widget.listenable != oldWidget.listenable) {
      stopListening();
      startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider<T>(
      value: widget.listenable,
      child: widget.child,
      updateShouldNotify: updateShouldNotify,
    );
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

class ChangeNotifierProvider<T extends ChangeNotifier>
    extends ListenableProvider<T> implements SingleChildClonableWidget {
  static void _disposer(ChangeNotifier notifier) => notifier.dispose();

  const ChangeNotifierProvider({
    Key key,
    T notifier,
    Widget child,
  }) : super(key: key, listenable: notifier, child: child);

  const ChangeNotifierProvider.builder({
    Key key,
    ValueBuilder<T> builder,
    Widget child,
  }) : super.builder(
          key: key,
          builder: builder,
          dispose: _disposer,
          child: child,
        );

  const ChangeNotifierProvider._({
    Key key,
    ValueBuilder<T> builder,
    T listenable,
    Widget child,
  }) : super._(
          key: key,
          builder: builder,
          listenable: listenable,
          child: child,
          dispose: _disposer,
        );

  // While the behavior doesn't change between ChangeNotifierProvider and ListenableProvider
  // it is required to override `cloneWithChild` because the `runtimeType` is different, which Flutter use.
  @override
  ChangeNotifierProvider<T> cloneWithChild(Widget child) {
    return ChangeNotifierProvider<T>._(
      key: key,
      listenable: listenable,
      builder: builder,
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
    implements SingleChildClonableWidget {
  /// Allow configuring [Key]
  ValueListenableProvider({
    Key key,
    @required ValueListenable<T> listenable,
    this.child,
  }) : super(key: key, listenable: listenable);

  @override
  ValueListenable<T> get listenable => super.listenable as ValueListenable<T>;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Provider<T>(
      value: listenable.value,
      child: child,
      // purposefully omit `updateShouldNotify` to use the default comparison (operator==)
    );
  }

  @override
  SingleChildClonableWidget cloneWithChild(Widget child) {
    return ValueListenableProvider(
      key: key,
      listenable: listenable,
      child: child,
    );
  }
}
