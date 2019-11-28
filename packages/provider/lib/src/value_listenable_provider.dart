import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

import 'inherited_provider.dart';
import 'listenable_provider.dart' show ListenableProvider;

/// Listens to a [ValueListenable] and expose its current value.
class ValueListenableProvider<T> extends SingleChildStatelessWidget {
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
  })  : _updateShouldNotify = updateShouldNotify,
        _create = create,
        _value = null,
        super(key: key, child: child);

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
        super(key: key, child: child);

  static void _dispose(BuildContext context, ValueListenable<Object> notifier) {
    if (notifier is ValueNotifier) {
      notifier.dispose();
    }
  }

  final UpdateShouldNotify<T> _updateShouldNotify;
  final ValueListenable<T> _value;
  final Create<ValueListenable<T>> _create;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
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
      child: child,
    );
  }
}
