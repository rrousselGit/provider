import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'listenable_provider.dart' show ListenableProvider;
import 'provider.dart';

/// Listens to a [ValueListenable] and expose its current value.
class ValueListenableProvider<T>
    extends DeferredInheritedProvider<ValueListenable<T>, T> {
  /// Creates a [ValueNotifier] using [create] and automatically dispose it
  /// when [ValueListenableProvider] is removed from the tree.
  ///
  /// [create] must not be `null`.
  ///
  /// {@macro provider.updateshouldnotify}
  ///
  /// See also:
  ///
  ///   * [ValueListenable]
  ///   * [ListenableProvider], similar to [ValueListenableProvider] but for any
  /// kind of [Listenable].
  ValueListenableProvider({
    Key key,
    @required Create<ValueNotifier<T>> create,
    UpdateShouldNotify<T> updateShouldNotify,
    bool lazy,
    TransitionBuilder builder,
    Widget child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          startListening: _startListening(),
          dispose: _dispose,
          child: child,
        );

  /// Listens to [value] and exposes its current value.
  ///
  /// Changing [value] will stop listening to the previous [value] and listen
  /// the new one.  Removing [ValueListenableProvider] from the tree will also
  /// stop listening to [value].
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
    @required ValueListenable<T> value,
    UpdateShouldNotify<T> updateShouldNotify,
    TransitionBuilder builder,
    Widget child,
  }) : super.value(
          key: key,
          builder: builder,
          value: value,
          updateShouldNotify: updateShouldNotify,
          startListening: _startListening(),
          child: child,
        );

  static void _dispose(BuildContext context, ValueListenable<Object> notifier) {
    if (notifier is ValueNotifier) {
      notifier.dispose();
    }
  }

  static DeferredStartListening<ValueListenable<T>, T> _startListening<T>() {
    return (_, setState, controller, __) {
      setState(controller.value);

      final listener = () => setState(controller.value);
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    };
  }
}
