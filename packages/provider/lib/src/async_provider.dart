import 'dart:async';

import 'package:flutter/widgets.dart';

import 'inherited_provider.dart';

/// A callback used to build a valid value from an error.
///
/// See also:
///
///   * [StreamProvider] which uses [ErrorBuilder] to handle errors
///     emitted by a [Stream].
///   * [FutureProvider] which uses [ErrorBuilder] to handle
///     [Future.catch].
typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

/// Listens to a [Stream<T>] and exposes [T] to its descendants.
///
/// Its main use-case is to provide to a large number of a widget the content
/// of a [Stream], without caring about reacting to events.
///
/// A typical example would be to expose the battery level, or a Firebase query.
/// Trying to use [Stream] to replace [ChangeNotifier] is outside of the scope
/// of this class.
///
/// It is considered an error to pass a stream that can emit errors without
/// providing a `catchError` method.
///
/// {@template provider.streamprovider.initialdata}
/// `initialData` determines the value exposed until the [Stream] emits a value.
/// If omitted, defaults to `null`.
/// {@endtemplate}
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///
///   * [Stream], which is listened by [StreamProvider].
///   * [StreamController], to create a [Stream]
class StreamProvider<T> extends StatelessWidget {
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
  })  : assert(builder != null),
        _initialData = initialData,
        _value = null,
        _catchError = catchError,
        _updateShouldNotify = updateShouldNotify,
        _child = child,
        _create = builder,
        super(key: key);

  /// Listens to [value] and expose it to all of [StreamProvider] descendants.
  StreamProvider.value({
    Key key,
    @required Stream<T> value,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  })  : _initialData = initialData,
        _value = value,
        _catchError = catchError,
        _updateShouldNotify = updateShouldNotify,
        _child = child,
        _create = null,
        super(key: key);

  final Widget _child;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final Stream<T> _value;
  final ValueBuilder<Stream<T>> _create;
  final T _initialData;

  /// An optional function used whenever the [Stream] emits an error.
  ///
  /// [_catchError] will be called with the emitted error and is expected to
  /// return a fallback value without throwing.
  ///
  /// The returned value will then be exposed to the descendants of
  /// [StreamProvider] like any valid value.
  final ErrorBuilder<T> _catchError;

  @override
  Widget build(BuildContext context) {
    return autoDeferred<Stream<T>, T>(
      // valid because _value and _create will never be both not null together
      value: _value,
      create: _create,
      startListening: (e, setState, controller, __) {
        if (!e.hasValue) {
          setState(_initialData);
        }
        if (controller == null) {
          return () {};
        }
        final sub = controller.listen(
          setState,
          onError: (dynamic error) {
            if (_catchError != null) {
              setState(_catchError(e, error));
            } else {
              FlutterError.reportError(
                FlutterErrorDetails(
                  library: 'provider',
                  exception: FlutterError('''
An exception was throw by ${controller.runtimeType} listened by
$runtimeType, but no `catchError` was provided.

Exception:
$error
'''),
                ),
              );
            }
          },
        );

        return sub.cancel;
      },
      updateShouldNotify: _updateShouldNotify,
      child: _child,
    );
  }
}

/// Listens to a [Future<T>] and exposes [T] to its descendants.
///
/// It is considered an error to pass a future that can emit errors without
/// providing a `catchError` method.
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///
///   * [Future], which is listened by [FutureProvider].
class FutureProvider<T> extends StatelessWidget {
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
  })  : assert(builder != null),
        _initialData = initialData,
        _value = null,
        _catchError = catchError,
        _updateShouldNotify = updateShouldNotify,
        _child = child,
        _create = builder,
        super(key: key);

  /// Listens to [value] and expose it to all of [FutureProvider] descendants.
  FutureProvider.value({
    Key key,
    @required Future<T> value,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  })  : _initialData = initialData,
        _value = value,
        _catchError = catchError,
        _updateShouldNotify = updateShouldNotify,
        _child = child,
        _create = null,
        super(key: key);

  final Widget _child;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final Future<T> _value;
  final ValueBuilder<Future<T>> _create;
  final T _initialData;

  /// An optional function used whenever the [Stream] emits an error.
  ///
  /// [_catchError] will be called with the emitted error and is expected to
  /// return a fallback value without throwing.
  ///
  /// The returned value will then be exposed to the descendants of
  /// [StreamProvider] like any valid value.
  final ErrorBuilder<T> _catchError;

  @override
  Widget build(BuildContext context) {
    return autoDeferred<Future<T>, T>(
      // valid because _value and _create will never be both not null together
      value: _value,
      create: _create,
      startListening: (e, setState, controller, __) {
        if (!e.hasValue) {
          setState(_initialData);
        }

        var canceled = false;
        controller?.then(
          (value) {
            if (canceled) return;
            setState(value);
          },
          onError: (dynamic error) {
            if (canceled) return;
            if (_catchError != null) {
              setState(_catchError(e, error));
            } else {
              FlutterError.reportError(
                FlutterErrorDetails(
                  library: 'provider',
                  exception: FlutterError('''
An exception was throw by ${controller.runtimeType} listened by
$runtimeType, but no `catchError` was provided.

Exception:
$error
'''),
                ),
              );
            }
          },
        );

        return () => canceled = true;
      },
      updateShouldNotify: _updateShouldNotify,
      child: _child,
    );
  }
}
