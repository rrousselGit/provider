import 'dart:async';

import 'package:flutter/widgets.dart';

import 'delegate_widget.dart';
import 'provider.dart';

/// A callback used to build a valid value from an error.
///
/// See also:
///
///   * [StreamProvider.catchError] which uses [ErrorBuilder] to handle errors
///     emitted by a [Stream].
///   * [FutureProvider.catchError] which uses [ErrorBuilder] to handle
///     [Future.catch].
typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

/// Listens to a [Stream<T>] and exposes [T] to its descendants.
///
/// It is considered an error to pass a stream that can emit errors without providing
/// a [catchError] method.
///
/// {@template provider.streamprovider.initialdata}
/// [initialData] determines the value exposed until the [Stream] emits a value.
/// If omitted, defaults to `null`.
/// {@endtemplate}
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///
///   * [Stream], which is listened by [StreamProvider].
///   * [StreamController], to create a [Stream]
class StreamProvider<T> extends ValueDelegateWidget<Stream<T>>
    implements SingleChildCloneableWidget {
  /// Creates a [Stream] from [builder] and subscribes to it.
  ///
  /// The parameter [builder] must not be `null`.
  StreamProvider({
    Key key,
    @required ValueBuilder<Stream<T>> builder,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: BuilderStateDelegate<Stream<T>>(builder),
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  /// Creates a [StreamController] from [builder] and subscribes to its stream.
  ///
  /// [StreamProvider] will automatically call [StreamController.close]
  /// when the widget is removed from the tree.
  ///
  /// The parameter [builder] must not be `null`.
  StreamProvider.controller({
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

  /// Listens to [value] and expose it to all of [StreamProvider] descendants.
  StreamProvider.value({
    Key key,
    @required Stream<T> value,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: SingleValueDelegate(value),
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  StreamProvider._({
    Key key,
    @required ValueStateDelegate<Stream<T>> delegate,
    this.initialData,
    this.catchError,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  /// {@macro provider.streamprovider.initialdata}
  final T initialData;

  /// The widget that is below the current [StreamProvider] widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// An optional function used whenever the [Stream] emits an error.
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
      updateShouldNotify: updateShouldNotify,
      initialData: initialData,
      catchError: catchError,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: delegate.value,
      initialData: initialData,
      builder: (_, snapshot) {
        return InheritedProvider<T>(
          value: _snapshotToValue(snapshot, context, catchError, this),
          child: child,
          updateShouldNotify: updateShouldNotify,
        );
      },
    );
  }
}

T _snapshotToValue<T>(AsyncSnapshot<T> snapshot, BuildContext context,
    ErrorBuilder<T> catchError, ValueDelegateWidget owner) {
  if (snapshot.hasError) {
    if (catchError != null) {
      return catchError(context, snapshot.error);
    }
    throw FlutterError('''
An exception was throw by ${
        // ignore: invalid_use_of_protected_member
        owner.delegate.value?.runtimeType} listened by
$owner, but no `catchError` was provided.

Exception:
${snapshot.error}
''');
  }
  return snapshot.data;
}

class _StreamControllerBuilderDelegate<T>
    extends ValueStateDelegate<Stream<T>> {
  _StreamControllerBuilderDelegate(this._builder) : assert(_builder != null);

  StreamController<T> _controller;
  ValueBuilder<StreamController<T>> _builder;

  @override
  Stream<T> value;

  @override
  void initDelegate() {
    super.initDelegate();
    _controller = _builder(context);
    value = _controller?.stream;
  }

  @override
  void didUpdateDelegate(_StreamControllerBuilderDelegate<T> old) {
    super.didUpdateDelegate(old);
    value = old.value;
    _controller = old._controller;
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }
}

/// Listens to a [Future<T>] and exposes [T] to its descendants.
///
/// It is considered an error to pass a future that can emit errors without providing
/// a [catchError] method.
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///
///   * [Future], which is listened by [FutureProvider].
class FutureProvider<T> extends ValueDelegateWidget<Future<T>>
    implements SingleChildCloneableWidget {
  /// Creates a [Future] from [builder] and subscribes to it.
  ///
  /// [builder] must not be `null`.
  FutureProvider({
    Key key,
    @required ValueBuilder<Future<T>> builder,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          delegate: BuilderStateDelegate(builder),
          child: child,
        );

  /// Listens to [value] and expose it to all of [FutureProvider] descendants.
  FutureProvider.value({
    Key key,
    @required Future<T> value,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          initialData: initialData,
          catchError: catchError,
          updateShouldNotify: updateShouldNotify,
          delegate: SingleValueDelegate(value),
          child: child,
        );

  FutureProvider._({
    Key key,
    @required ValueStateDelegate<Future<T>> delegate,
    this.initialData,
    this.catchError,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  /// [initialData] determines the value exposed until the [Future] completes.
  ///
  /// If omitted, defaults to `null`.
  final T initialData;

  /// The widget that is below the current [FutureProvider] widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Optional function used if the [Future] emits an error.
  ///
  /// [catchError] will be called with the emitted error and
  /// is expected to return a fallback value without throwing.
  ///
  /// The returned value will then be exposed to the descendants of [FutureProvider]
  /// like any valid value.
  final ErrorBuilder<T> catchError;

  /// {@macro provider.updateshouldnotify}
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  FutureProvider<T> cloneWithChild(Widget child) {
    return FutureProvider._(
      key: key,
      delegate: delegate,
      updateShouldNotify: updateShouldNotify,
      initialData: initialData,
      catchError: catchError,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: delegate.value,
      initialData: initialData,
      builder: (_, snapshot) {
        return InheritedProvider<T>(
          value: _snapshotToValue(snapshot, context, catchError, this),
          updateShouldNotify: updateShouldNotify,
          child: child,
        );
      },
    );
  }
}
