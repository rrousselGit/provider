Release 1.1.0

- `onDispose` has been added to `StatefulProvider`
- `BuildContext` is now passed to `valueBuilder` callback

Release 1.1.1

- add `didChangeDependencies` callback to allow updating the value based on an `InheritedWidget`
- add `updateShouldNotify` method to both `Provider` and `StatefulProvider`
