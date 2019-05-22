part of 'provider.dart';

/// Listens to a [ChangeNotifier], expose it to its descendants
/// and rebuilds dependents whenever the [ChangeNotifier.notifyListeners] is called.
///
/// See also:
///   * [ListenableProvider], similar to [ChangeNotifier] but works with any [Listenable].
///   * [ChangeNotifier]
class ChangeNotifierProvider<T extends ChangeNotifier>
    extends ListenableProvider<T> implements SingleChildCloneableWidget {
  static void _disposer(BuildContext context, ChangeNotifier notifier) =>
      notifier?.dispose();

  /// Create a [ChangeNotifier] using the [builder] function and automatically dispose it
  /// when [ChangeNotifierProvider] is removed from the widget tree.
  ///
  /// [builder] must not be `null`.
  ChangeNotifierProvider({
    Key key,
    @required ValueBuilder<T> builder,
    Widget child,
  }) : super(key: key, builder: builder, dispose: _disposer, child: child);

  /// Listens to [value] and expose it to all of [ChangeNotifierProvider] descendants.
  ChangeNotifierProvider.value({
    Key key,
    @required T value,
    Widget child,
  }) : super.value(key: key, value: value, child: child);
}