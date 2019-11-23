import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'inherited_provider.dart';
import 'listenable_provider.dart' show ListenableProvider;

/// Listens to a [ValueListenable] and expose its current value.
class ValueListenableProvider<T> extends StatelessWidget {
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
    Widget child,
  })  : _child = child,
        _updateShouldNotify = updateShouldNotify,
        _create = create,
        _value = null,
        super(key: key);

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
    Widget child,
  })  : _value = value,
        _updateShouldNotify = updateShouldNotify,
        _create = null,
        _child = child,
        super(key: key);

  static void _dispose(BuildContext context, ValueListenable<Object> notifier) {
    if (notifier is ValueNotifier) {
      notifier.dispose();
    }
  }

  final Widget _child;
  final UpdateShouldNotify<T> _updateShouldNotify;
  final ValueListenable<T> _value;
  final Create<ValueListenable<T>> _create;

  @override
  Widget build(BuildContext context) {
    return autoDeferred<ValueListenable<T>, T>(
      // TODO: conisider a ValueDelegate & CreateDelegate.
      // The issue being, InheritedProvider wouldn't have these delegates
      // because the create ctor doesn't have an updateShouldNotify

      // valid because _value and _create will never be both not null together
      value: _value,
      create: _create,
      dispose: _create == null ? null : _dispose,
      startListening: (_, setState, controller, __) {
        setState(controller.value);

        final listener = () => setState(controller.value);
        controller.addListener(listener);
        return () => controller.removeListener(listener);
      },
      updateShouldNotify: _updateShouldNotify,
      child: _child,
    );
  }
}
