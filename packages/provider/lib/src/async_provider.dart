import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

import 'inherited_provider.dart';

/// A callback used to build a valid value from an error.
///
/// See also:
///
///   * [StreamProvider] and [FutureProvider], which both uses [ErrorBuilder] to
///     handle respectively [Stream.catchError] and [Future.catch].
typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

/// Listens to a [Stream] and exposes its content to `child` and descendants.
///
/// Its main use-case is to provide to a large number of a widget the content
/// of a [Stream], without caring about reacting to events.
/// A typical example would be to expose the battery level, or a Firebase query.
///
/// Trying to use [Stream] to replace [ChangeNotifier] is outside of the scope
/// of this class.
///
/// It is considered an error to pass a stream that can emit errors without
/// providing a `catchError` method.
///
/// `initialData` determines the value exposed until the [Stream] emits a value.
/// If omitted, defaults to `null`.
///
/// By default, [StreamProvider] considers that the [Stream] listened uses
/// immutable data. As such, it will not rebuild dependents if the previous and
/// the new value are `==`.
/// To change this behavior, pass a custom `updateShouldNotify`.
///
/// See also:
///
///   * [Stream], which is listened by [StreamProvider].
///   * [StreamController], to create a [Stream].
class StreamProvider<T> extends SingleChildStatelessWidget {
  /// Creates a [Stream] using `create` and subscribes to it.
  ///
  /// The parameter `create` must not be `null`.
  StreamProvider({
    Key key,
    @required Create<Stream<T>> create,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  })  : assert(create != null),
        _initialData = initialData,
        _value = null,
        _catchError = catchError,
        _updateShouldNotify = updateShouldNotify,
        _create = create,
        super(key: key, child: child);

  /// Listens to `value` and expose it to all of [StreamProvider] descendants.
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
        _create = null,
        super(key: key, child: child);

  // TODO: .controller
  // TODO: add builder parameter

  final UpdateShouldNotify<T> _updateShouldNotify;
  final Stream<T> _value;
  final Create<Stream<T>> _create;
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
  Widget buildWithChild(BuildContext context, Widget child) {
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
      child: child,
    );
  }
}

/// Listens to a [Future] and exposes its result to `child` and its descendants.
///
/// It is considered an error to pass a future that can emit errors without
/// providing a `catchError` method.
///
/// {@macro provider.updateshouldnotify}
///
/// See also:
///
///   * [Future], which is listened by [FutureProvider].
class FutureProvider<T> extends SingleChildStatelessWidget {
  /// Creates a [Future] from `create` and subscribes to it.
  ///
  /// `create` must not be `null`.
  FutureProvider({
    Key key,
    @required Create<Future<T>> create,
    T initialData,
    ErrorBuilder<T> catchError,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  })  : assert(create != null),
        _initialData = initialData,
        _value = null,
        _catchError = catchError,
        _updateShouldNotify = updateShouldNotify,
        _create = create,
        super(key: key, child: child);

  /// Listens to `value` and expose it to all of [FutureProvider] descendants.
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
        _create = null,
        super(key: key, child: child);

  final UpdateShouldNotify<T> _updateShouldNotify;
  final Future<T> _value;
  final Create<Future<T>> _create;
  final T _initialData;

  /// An optional function used whenever the [Future] emits an error.
  ///
  /// [_catchError] will be called with the emitted error and is expected to
  /// return a fallback value without throwing.
  ///
  /// The returned value will then be exposed to the descendants of
  /// [FutureProvider] like any valid value.
  final ErrorBuilder<T> _catchError;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
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
      child: child,
    );
  }
}
