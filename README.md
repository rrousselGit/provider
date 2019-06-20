[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dartlang.org/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

A mixture between dependency injection (DI) and state management, built with widgets for widgets.

It purposefully use widgets for DI/state management instead of dart-only classes like `Stream`.
The reason is, widgets are very simple yet robust and scalable.

By using widgets for state management, `provider` can guarantee:

- maintainability, through a forced uni-directional data-flow
- testability/composability, since it is always possible mock/override a value
- robustness, as it is harder to forget to handle the update scenario of a model/widget

## Migration from v2.0.0 to v3.0.0

- Providers can no longer be instantiated with `const`.
- `Provider` now throws if used with a `Listenable`/`Stream`.
  Consider using `ListenableProvider`/`StreamProvider` instead. Alternatively,
  this exception can be disabled by setting `Provider.debugCheckInvalidValueType`
  to `null` like so:

```dart
void main() {
  Provider.debugCheckInvalidValueType = null;

  runApp(MyApp());
}
```

- All `XXProvider.value` constructors now use `value` as parameter name.

Before:

```dart
ChangeNotifierProvider.value(notifier: myNotifier),
```

After:

```dart
ChangeNotifierProvider.value(value: myNotifier),
```

- `StreamProvider`'s default constructor now builds a `Stream` instead of `StreamController`. The previous behavior has been moved to the named constructor `StreamProvider.controller`.

Before:

```dart
StreamProvider(builder: (_) => StreamController<int>()),
```

After:

```dart
StreamProvider.controller(builder: (_) => StreamController<int>()),
```

## Usage

### Exposing a value

To expose a variable using `provider`, wrap any widget into one of the provider widgets from this package
and pass it your variable. Then, all descendants of the newly added provider widget can access this variable.

A simple example would be to wrap the entire application into a `Provider` widget and pass it our variable:

```dart
Provider<String>.value(
  value: 'Hello World',
  child: MaterialApp(
    home: Home(),
  )
)
```

Alternatively, for complex objects, most providers expose a constructor that takes a function to create the value.
The provider will call that function only once, when inserting the widget in the tree, and expose the result.
This is perfect for exposing a complex object that never changes over time without writing a `StatefulWidget`.

The following creates and exposes a `MyComplexClass`. And in the event where `Provider` is removed from the widget tree,
the instantiated `MyComplexClass` will be disposed.

```dart
Provider<MyComplexClass>(
  builder: (context) => MyComplexClass(),
  dispose: (context, value) => value.dispose()
  child: SomeWidget(),
)
```

### Reading a value

The easiest way to read a value is by using the static method `Provider.of<T>(BuildContext context)`. This method will look
up in widget tree starting from the widget associated with the `BuildContext` passed and it will return the nearest variable
of type `T` found (or throw if nothing if found).

Combined with the first example of [exposing a value](#exposing-a-value), this widget will read the exposed `String` and render "Hello World."

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      /// Don't forget to pass the type of the object you want to obtain to `Provider.of`!
      Provider.of<String>(context)
    );
  }
}
```

Alternatively instead of using `Provider.of`, we can use the `Consumer` widget.

This can be useful for performance optimizations or when it is difficult to obtain a `BuildContext` descendant of the provider.

```dart
Provider<String>.value(
  value: 'Hello World',
  child: Consumer<String>(
    builder: (context, value, child) => Text(value),
  ),
);
```

---

Note that you can freely use multiple providers with different types together:

```dart
Provider<int>.value(
  value: 42,
  child: Provider<String>.value(
    value: 'Hello World',
    child: // ...
  )
)
```

And obtain their value independently:

```dart
var value = Provider.of<int>(context);
var value2 = Provider.of<String>(context);
```

### MultiProvider

When injecting many values in big applications, `Provider` can rapidly become pretty nested:

```dart
Provider<Foo>.value(
  value: foo,
  child: Provider<Bar>.value(
    value: bar,
    child: Provider<Baz>.value(
      value: baz,
      child: someWidget,
    )
  )
)
```

In that situation, we can use `MultiProvider` to improve the readability:

```dart
MultiProvider(
  providers: [
    Provider<Foo>.value(value: foo),
    Provider<Bar>.value(value: bar),
    Provider<Baz>.value(value: baz),
  ],
  child: someWidget,
)
```

The behavior of both examples is strictly the same. `MultiProvider` only changes the appearance of the code.

### ProxyProvider

Since the 3.0.0, there is a new kind of provider: `ProxyProvider`.

`ProxyProvider` is a provider that combines multiple values from other providers into a new object, and send the result to `Provider`.

That new object will then be updated whenever one of the providers it depends on
updates.

The following example use `ProxyProvider` to build translations based on a counter
coming from another provider.

```dart
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(builder: (_) => Counter()),
      ProxyProvider<Counter, Translations>(
        builder: (_, counter, __) => Translations(counter.value),
      ),
    ],
    child: Foo(),
  );
}

class Translations {
  const Translations(this._value);

  final int _value;

  String get title => 'You clicked $_value times';
}
```

It comes under multiple variations, such:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  That digit after the class name is the number of other providers that `ProxyProvider` depends on.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  They all works similarly, but instead of sending the result into a `Provider`, a `ChangeNotifierProxyProvider` will its value to a `ChangeNotifierProvider`.

### Existing providers

`provider` exposes a few different kinds of "provider" for different types of objects.

| name                                                                                                                          | description                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | The most basic form of provider. It takes a value and exposes it, whatever the value is.                                                                               |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | A specific provider for Listenable object. ListenableProvider will listen to the object and ask widgets which depend on it to rebuild whenever the listener is called. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | A specification of ListenableProvider for ChangeNotifier. It will automatically call `ChangeNotifier.dispose` when needed.                                             |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Listen to a ValueListenable and only expose `ValueListenable.value`.                                                                                                   |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Listen to a Stream and expose the latest value emitted.                                                                                                                |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Takes a `Future` and updates dependents when the future completes.                                                                                                     |
