# 1.5.0

- new: `MultiProvider`, a provider that makes a tree of provider more readable

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

