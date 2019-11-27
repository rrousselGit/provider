import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'delegate_widget.dart';
import 'listenable_provider.dart' show ListenableProvider;
import 'provider.dart';

/// Listens to a [ValueListenable] and expose its current value.
class ValueListenableProvider<T> extends ValueDelegateWidget<ValueListenable<T>>
    implements SingleChildCloneableWidget {
  /// Creates a [ValueNotifier] using `create` and automatically dispose it
  /// when [ValueListenableProvider] is removed from the tree.
  ///
  /// `create` must not be `null`.
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
    @Deprecated('Will be removed as part of 4.0.0, use update instead')
        ValueBuilder<ValueNotifier<T>> builder,
    @required ValueBuilder<ValueNotifier<T>> create,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: BuilderStateDelegate<ValueNotifier<T>>(
            // ignore: deprecated_member_use_from_same_package
            create ?? builder,
            dispose: _dispose,
          ),
          updateShouldNotify: updateShouldNotify,
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
    Widget child,
  }) : this._(
          key: key,
          delegate: SingleValueDelegate(value),
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  ValueListenableProvider._({
    Key key,
    @required ValueStateDelegate<ValueListenable<T>> delegate,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  static void _dispose(BuildContext context, ValueNotifier notifier) {
    notifier.dispose();
  }

  /// The widget that is below the current [ValueListenableProvider] widget in
  /// the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@macro provider.updateshouldnotify}
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  ValueListenableProvider<T> cloneWithChild(Widget child) {
    return ValueListenableProvider._(
      key: key,
      delegate: delegate,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: delegate.value,
      builder: (_, value, child) {
        return InheritedProvider<T>(
          value: value,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );
      },
      child: child,
    );
  }
}
