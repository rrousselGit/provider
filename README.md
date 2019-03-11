[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dartlang.org/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider)

A generic implementation of `InheritedWidget`. It allows to expose any kind of object, without having to manually write an `InheritedWidget` ourselves.

## Usage

To expose a value, simply wrap any given part of your widget tree into any of the available `Provider` as such:

```dart
Provider<int>(
  value: 42,
  child: // ...
)
```

Descendants of `Provider` and now obtain this value using the static `Provider.of<T>` method:

```dart
var value = Provider.of<int>(context);
```

You can also use `Consumer` widget to insert a descendant, useful when both creating a `Provider` and using it:

```dart
Provider<int>(
  value: 42,
  child: Consumer<int>(
    builder: (context, value) => Text(value.toString()),
  )
)
```

---

Note that you can freely use multiple providers with different type together:

```dart
Provider<int>(
  value: 42,
  child: Provider<String>(
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

## Existing Providers:

### Provider

A simple provider which takes the exposed value directly:

```dart
Provider<int>(
  value: 42,
  child: // ...
)
```

### StatefulProvider

A provider that can also create and dispose an object.

It is usually used to avoid making a `StatefulWidget` for something trivial, such as instanciating a BLoC.

`StatefulBuilder` is the equivalent of a `State.initState` combined with `State.dispose`.
As such, `valueBuilder` is called only once and is unable to use `InheritedWidget`; which makes it impossible to update the created value.

If this is too limiting, consider instead `HookProvider`, which offer a much more advanced control over the created value.

The following example instanciate a `Model` once, and dispose it when `StatefulProvider` is removed from the tree.

```dart
class Model {
  void dispose() {}
}

class Stateless extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulProvider<Model>(
      valueBuilder: (context) =>  Model(),
      onDispose: (context, value) => value.dispose(),
      child: ...,
    );
  }
}
```

### HookProvider

A provider which can use hooks from [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)

This is especially useful to create complex providers, without having to make a `StatefulWidget`.

The following example uses BLoC pattern to create a BLoC, provide its value, and dispose it when the provider is removed from the tree.

```dart
HookProvider<MyBloc>(
  hook: () {
    final bloc = useMemoized(() => MyBloc());
    useEffect(() => bloc.dispose, [bloc]);
    return bloc;
  },
  child: // ...
)
```

## MultiProvider

A provider that merges multiple other providers into one.

`MultiProvider` is used to improve the readability and reduce the boilerplate of
having many nested providers.

As such, we're going from:

```dart
Provider<Foo>(
  value: foo,
  child: Provider<Bar>(
    value: bar,
    child: Provider<Baz>(
      value: baz,
      child: someWidget,
    )
  )
)
```

To:

```dart
MultiProvider(
  providers: [
    Provider<Foo>(value: foo),
    Provider<Bar>(value: bar),
    Provider<Baz>(value: baz),
  ],
  child: someWidget,
)
```

Technically, these two are identical. `MultiProvider` will convert the array into a tree.
This changes only the appearance of the code.

### StreamProvider

A provider that exposes the current value of a `Stream` as an `AsyncSnapshot`.

Changing [stream] will stop listening to the previous [stream] and listen the new one.

Removing [StreamProvider] from the tree will also stop listening to [stream].
To obtain the current value of type `T`, one must explicitly request `Provider.of<AsyncSnapshot<T>>`.
It is also possible to use `StreamProvider.of<T>`.

```dart
Stream<int> foo;

StreamProvider<int>(
  stream: foo,
  child: Container(),
);
```

### ValueListenableProvider

Expose the current value of a [ValueListenable].

Changing [valueListenable] will stop listening to the previous [valueListenable] and listen the new one.
Removing [ValueListenableProvider] from the tree will also stop listening to [valueListenable].

```dart
ValueListenable<int> foo;

ValueListenableProvider<int>(
  valueListenable: foo,
  child: Container(),
);
```

### ChangeNotifierProvider

Expose a [ChangeNotifier] subclass and ask its depends to rebuild whenever [ChangeNotifier.notifyListeners] is called

Listeners to [ChangeNotifier] only rebuilds when [ChangeNotifier.notifyListeners] is called, even if [ChangeNotifierProvider] is rebuilt.

```dart
class MyModel extends ChangeNotifier {
  int _value;

  int get value => _value;

  set value(int value) {
    _value = value;
    notifyListeners();
  }
}


// ...

ChangeNotifierProvider<MyModel>.stateful(
  builder: () => MyModel(),
  child: Container(),
)
```
