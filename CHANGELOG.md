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

