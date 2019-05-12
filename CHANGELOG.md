# 2.0.1

- fix a bug where `ListenableProvider.value`/`ChangeNotifierProvider.value`/`StreamProvider.value`/`ValueListenableProvider.value` subscribed/unsubscribed to their respective object too often
- fix a bug where `ListenableProvider.value`/`ChangeNotifierProvider.value` may rebuild too often or skip some.

# 2.0.0

- `Consumer` now takes an optional `child` argument for optimization purposes.
- merged `Provider` and `StatefulProvider`
- added a "builder" constructor to `ValueListenableProvider`
- normalized providers constructors such that the default constructor is a "builder", and offer a `value` named constructor.

# 1.6.1

- `Provider.of<T>` now crashes with a `ProviderNotFoundException` when no `Provider<T>` are found in the ancestors of the context used.

# 1.6.0

- new: `ChangeNotifierProvider`, similar to scoped_model that exposes `ChangeNotifer` subclass and rebuilds dependents only when `notifyListeners` is called.
- new: `ValueListenableProvider`, a provider that rebuilds whenever the value passed to a `ValueNotifier` change.

# 1.5.0

- new: Add `Consumer` with up to 6 parameters.
- new: `MultiProvider`, a provider that makes a tree of provider more readable
- new: `StreamProvider`, a stream that exposes to its descendants the current value of a `Stream`.

# 1.4.0

- Reintroduced `StatefulProvider` with a modified prototype.
  The second argument of `valueBuilder` and `didChangeDependencies` have been removed.
  And `valueBuilder` is now called only once for the whole life-cycle of `StatefulProvider`.

# 1.3.0

- Added `Consumer`, useful when we need to both expose and consume a value simultaneously.

# 1.2.0

- Added: `HookProvider`, a `Provider` that creates its value from a `Hook`.
- Deprecated `StatefulProvider`. Either make a `StatefulWidget` or use `HookProvider`.
- Integrated the widget inspector, so that `Provider` widget shows the current value.

# 1.1.1

- add `didChangeDependencies` callback to allow updating the value based on an `InheritedWidget`
- add `updateShouldNotify` method to both `Provider` and `StatefulProvider`

# 1.1.0

- `onDispose` has been added to `StatefulProvider`
- `BuildContext` is now passed to `valueBuilder` callback
