import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/src/delegate_widget.dart';
import 'package:provider/src/provider.dart';

typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

/// Listens to a [Stream<T>] and exposes [T] to its descendants.
///
/// It is considered an error to pass a stream that can emit errors without providing
/// an [catchError] method.
///
/// {@template provider.streamprovider.initialdata}
/// [initialData] determines the value exposed until the [Stream] emits a value.
/// If omitted, defaults to `null`.
/// {@endtemplate}
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///   * [Stream]
///   * [StreamController], to create a [Stream]
class StreamProvider<T> extends ValueDelegateWidget<Stream<T>>
    implements SingleChildCloneableWidget {
  /// Creates a [StreamController] from [builder] and subscribes to it.
  ///
  /// [StreamProvider] will automatically call [StreamController.close]
  /// when the widget is removed from the tree.
  ///
  /// [builder] must not be `null`.
  StreamProvider({
    Key key,
    @required ValueBuilder<StreamController<T>> builder,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: _StreamControllerBuilderDelegate(builder),
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  /// Creates a [StreamController] from [builder] and subscribes to it.
  ///
  /// [StreamProvider] will automatically call [StreamController.close]
  /// when the widget is removed from the tree.
  ///
  /// [builder] must not be `null`.
  StreamProvider.stream({
    Key key,
    @required ValueBuilder<Stream<T>> builder,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: BuilderAdaptiveDelegate(builder),
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  /// Listens to [stream] and expose it to all of [StreamProvider] descendants.
  StreamProvider.value({
    Key key,
    @required Stream<T> stream,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: SingleValueDelegate(stream),
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  StreamProvider._({
    Key key,
    @required ValueAdaptiveDelegate<Stream<T>> delegate,
    this.initialData,
    this.catchError,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  /// {@macro provider.streamprovider.initialdata}
  final T initialData;

  /// The widget that is below the current [StreamProvider] widget in the
  /// tree.
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Optional function used whenever the [Stream] emits an error.
  ///
  /// [catchError] will be called with the emitted error and
  /// is expected to return a fallback value without throwing.
  ///
  /// The returned value will then be exposed to the descendants of [StreamProvider]
  /// like any valid value.
  final ErrorBuilder<T> catchError;

  /// {@macro provider.updateshouldnotify}
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  StreamProvider<T> cloneWithChild(Widget child) {
    return StreamProvider._(
      key: key,
      delegate: delegate,
      child: child,
      updateShouldNotify: updateShouldNotify,
      initialData: initialData,
      catchError: catchError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: delegate.value,
      initialData: initialData,
      builder: (_, snapshot) {
        return Provider<T>.value(
          value: _getValue(snapshot, context, catchError),
          child: child,
          updateShouldNotify: updateShouldNotify,
        );
      },
    );
  }
}

T _getValue<T>(AsyncSnapshot<T> snapshot, BuildContext context,
    ErrorBuilder<T> catchError) {
  if (snapshot.hasError) {
    if (catchError != null) {
      return catchError(context, snapshot.error);
    }
    // ignore: only_throw_errors
    throw snapshot.error;
  }
  return snapshot.data;
}

class _StreamControllerBuilderDelegate<T>
    extends ValueAdaptiveDelegate<Stream<T>> {
  _StreamControllerBuilderDelegate(this.builder) : assert(builder != null);

  StreamController<T> controller;
  ValueBuilder<StreamController<T>> builder;

  @override
  Stream<T> value;

  @override
  void initDelegate() {
    controller = builder(context);
    value = controller?.stream;
  }

  @override
  void didUpdateDelegate(_StreamControllerBuilderDelegate<T> old) {
    value = old.value;
    controller = old.controller;
  }

  @override
  void dispose() {
    controller?.close();
  }
}
