[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dartlang.org/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

A mixture between dependency injection (DI) and state management, built with
widgets for widgets.

It purposefully uses widgets for DI/state management instead of dart-only
classes like `Stream`.
The reason is, widgets are very simple yet robust and scalable.

By using widgets for state management, `provider` can guarantee:

- maintainability, through a forced uni-directional data-flow
- testability/composability, since it is always possible to mock/override a
  value
- robustness, as it is harder to forget to handle the update scenario of a
  model/widget

To read more about `provider`, see the [documentation](https://pub.dev/documentation/provider/latest/).

## Migration from v2.0.0 to v3.0.0

- Providers can no longer be instantiated with `const`.
- `Provider` now throws if used with a `Listenable`/`Stream`.
  Consider using `ListenableProvider`/`StreamProvider` instead. Alternatively,
  this exception can be disabled by setting
  `Provider.debugCheckInvalidValueType` to `null` like so:

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

- `StreamProvider`'s default constructor now builds a `Stream` instead of a
  `StreamController`. The previous behavior has been moved to the named
  constructor `StreamProvider.controller`.

Before:

```dart
StreamProvider(create: (_) => StreamController<int>()),
```

After:

```dart
StreamProvider.controller(create: (_) => StreamController<int>()),
```

## Usage

### Exposing a value

To expose a variable using `provider`, wrap any widget into one of the provider
widgets from this package and pass it your variable. Then, all descendants of
the newly added provider widget can access this variable.

A simple example would be to wrap the entire application into a `Provider`
widget and pass it our variable:

```dart
Provider<String>.value(
  value: 'Hello World',
  child: MaterialApp(
    home: Home(),
  )
)
```

Alternatively, for complex objects, most providers expose a constructor that
takes a function to create the value. The provider will call that function only
once, when inserting the widget in the tree, and expose the result. This is
perfect for exposing a complex object that never changes over time without
writing a `StatefulWidget`.

The following creates and exposes a `MyComplexClass`. And in the event where
`Provider` is removed from the widget tree, the instantiated `MyComplexClass`
will be disposed.

```dart
Provider<MyComplexClass>(
  create: (context) => MyComplexClass(),
  dispose: (context, value) => value.dispose()
  child: SomeWidget(),
)
```

### Reading a value

The easiest way to read a value is by using the static method
`Provider.of<T>(BuildContext context)`.

This method will look up in the widget tree starting from the widget associated
with the `BuildContext` passed and it will return the nearest variable of type
`T` found (or throw if nothing is found).

Combined with the first example of [exposing a value](#exposing-a-value), this
widget will read the exposed `String` and render "Hello World."

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

Alternatively instead of using `Provider.of`, we can use `Consumer` and `Selector`.

These can be useful for performance optimizations or when it is difficult to
obtain a `BuildContext` descendant of the provider.

See the [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) or the documentation of [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
and [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
for more information.

### MultiProvider

When injecting many values in big applications, `Provider` can rapidly become
pretty nested:

```dart
Provider<Foo>(
  create: (_) => Foo(),
  child: Provider<Bar>(
    create: (_) => Bar(),
    child: Provider<Baz>(
      create: (_) => Baz(),
      child: someWidget,
    )
  )
)
```

In that situation, we can use `MultiProvider` to improve the readability:

```dart
MultiProvider(
  providers: [
    Provider<Foo>(create: (_) => Foo()),
    Provider<Bar>(create: (_) => Bar()),
    Provider<Baz>(create: (_) => Baz()),
  ],
  child: someWidget,
)
```

The behavior of both examples is strictly the same. `MultiProvider` only changes
the appearance of the code.

### ProxyProvider

Since the 3.0.0, there is a new kind of provider: `ProxyProvider`.

`ProxyProvider` is a provider that combines multiple values from other providers
into a new object, and sends the result to `Provider`.

That new object will then be updated whenever one of the providers it depends on
updates.

The following example uses `ProxyProvider` to build translations based on a
counter coming from another provider.

```dart
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => Counter()),
      ProxyProvider<Counter, Translations>(
        create: (_, counter, __) => Translations(counter.value),
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

It comes under multiple variations, such as:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  That digit after the class name is the number of other providers that
  `ProxyProvider` depends on.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  They all work similarly, but instead of sending the result into a `Provider`,
  a `ChangeNotifierProxyProvider` will send its value to a `ChangeNotifierProvider`.

### FAQ

### I have an exception when obtaining Providers inside `initState`. What can I do?

This exception happens because you're trying to listen to a provider from a
life-cycle that will never ever be called again.

It means that you either should use another life-cycle
(`didChangeDependencies`/`build`), or explicitly specify that you do not care
about updates.

As such, instead of:

```dart
initState() {
  super.initState();
  print(Provider.of<Foo>(context).value);
}
```

you can do:

```dart
Value value;

didChangeDependencies() {
  super.didChangeDependencies();
  final value = Provider.of<Foo>(context).value;
  if (value != this.value) {
    this.value = value;
    print(value);
  }
}
```

which will print `value` whenever it changes.

Alternatively you can do:

```dart
initState() {
  super.initState();
  print(Provider.of<Foo>(context, listen: false).value);
}
```

Which will print `value` once and ignore updates.

### I use `ChangeNotifier` and I have an exception when I update it, what happens?

This likely happens because you are modifying the `ChangeNotifier` from one of
its descendants _while the widget tree is building_.

A typical situation where this happens is when starting an http request, where
the future is stored inside the notifier:

```dart
initState() {
  super.initState();
  Provider.of<Foo>(context).fetchSomething();
}
```

This is not allowed, because the modification is immediate.

Which means that some widgets may build _before_ the mutation, while other
widgets will build _after_ the mutation.
This could cause inconsistencies in your UI and is therefore not allowed.

Instead, you should perform that mutation in a place that would affect the
entire tree equally:

- directly inside the `create` of your provider/constructor of your model:
  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```
  This is useful when there's no "external parameter".

- asynchronously at the end of the frame:
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<Foo>(context).fetchSomething(someValue);
    );
  }
  ```
  It is slightly less ideal, but allows passing parameters to the mutation.

#### Do I have to use `ChangeNotifier` for complex states?

No.

You can use any object to represent your state. For example, an alternate
architecture is to use `Provider.value()` combined with a `StatefulWidget`.

Here's a counter example using such architecture:

```dart
class Example extends StatefulWidget {
  const Example({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  ExampleState createState() => ExampleState();
}

class ExampleState extends State<Example> {
  int _count;

  void increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _count,
      child: Provider.value(
        value: this,
        child: widget.child,
      ),
    );
  }
}
```

where we can read the state by doing:

```dart
return Text(Provider.of<int>(context).toString());
```
and modify the state with:
```dart
return FloatingActionButton(
  onPressed: Provider.of<ExampleState>(context).increment,
  child: Icon(Icons.plus_one),
);
```

Alternatively, you can create your own provider.

#### Can I make my own Provider?

Yes. `provider` exposes all the small components that makes a fully fledged provider.

This includes:

- `SingleChildCloneableWidget`, to make any widget works with `MultiProvider`.
- `InheritedProvider`, the generic `InheritedWidget` obtained when doing `Provider.of`.
- `DelegateWidget`/`BuilderDelegate`/`ValueDelegate` to help handle the logic of
  "MyProvider() that creates an object" vs "MyProvider.value() that can update over time".
  
Here's an example of a custom provider to use `ValueNotifier` as state:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### My widget rebuilds too often, what can I do?

Instead of `Provider.of`, you can use `Consumer`/`Selector`.

Their optional `child` argument allows to rebuild only a very specific part of
the widget tree:

```dart
Foo(
  child: Consumer<A>(
    builder: (_, a, child) {
      return Bar(a: a, child: child);
    },
    child: Baz(),
  ),
)
```

In this example, only `Bar` will rebuild when `A` updates. `Foo` and `Baz` won't
unnecesseraly rebuild.

To go one step further, it is possible to use `Selector` to ignore changes if
they don't have an impact on the widget-tree:

```dart
Selector<List, int>(
  selector: (_, list) => list.length,
  builder: (_, length, __) {
    return Text('$length');
  }
);
```

This snippet will rebuild only if the length of the list changes. But it won't
unnecessarily update if an item is updated.

#### Can I obtain two different providers using the same type?

No. While you can have multiple providers sharing the same type, a widget will
be able to obtain only one of them: the closest ancestor.

Instead, you must explicitly give both providers a different type.

Instead of:

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

Prefer:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

## Existing providers

`provider` exposes a few different kinds of "provider" for different types of objects.

The complete list of all the objects availables is [here](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| name                                                                                                                          | description                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | The most basic form of provider. It takes a value and exposes it, whatever the value is.                                                                               |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | A specific provider for Listenable object. ListenableProvider will listen to the object and ask widgets which depend on it to rebuild whenever the listener is called. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | A specification of ListenableProvider for ChangeNotifier. It will automatically call `ChangeNotifier.dispose` when needed.                                             |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Listen to a ValueListenable and only expose `ValueListenable.value`.                                                                                                   |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Listen to a Stream and expose the latest value emitted.                                                                                                                |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Takes a `Future` and updates dependents when the future completes.                                                                                                     |
