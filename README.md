[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md)

# Black Lives Matter. [Support the Equal Justice Initiative.](https://support.eji.org/give/153413/#!/donation/checkout)

[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dev/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

A wrapper around [InheritedWidget]
to make them easier to use and more reusable.

By using `provider` instead of manually writing [InheritedWidget], you get:

- simplified allocation/disposal of resources
- lazy-loading
- a largely reduced boilerplate over making a new class every time
- devtools friendly
- a common way to consume these [InheritedWidget]s (See [Provider.of]/[Consumer]/[Selector])
- increased scalability for classes with a listening mechanism that grows exponentially
  in complexity (such as [ChangeNotifier], which is O(N²) for dispatching notifications).

To read more about `provider`, see its [documentation](https://pub.dev/documentation/provider/latest/provider/provider-library.html).

See also:

- [the official Flutter state management documentation](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), which showcase how to use `provider` + [ChangeNotifier]
- [flutter architecture sample](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider), which contains an implementation of that app using `provider` + [ChangeNotifier]
- [flutter_bloc](https://github.com/felangel/bloc) and [Mobx](https://github.com/mobxjs/mobx.dart), which use `provider` in their architecture

## Migration from v3.x.0 to v4.0.0

- The parameters `builder` and `initialBuilder` of providers are removed.

  - `initialBuilder` should be replaced by `create`.
  - `builder` of "proxy" providers should be replaced by `update`
  - `builder` of classical providers should be replaced by `create`.

- The new `create`/`update` callbacks are lazy-loaded, which means they are called
  the first time the value is read instead of the first time the provider is created.

  If this is undesired, you can disable lazy-loading by passing `lazy: false` to
  the provider of your choice:

  ```dart
  FutureProvider(
    create: (_) async => doSomeHttpRequest(),
    lazy: false,
    child: ...
  )
  ```

- `ProviderNotFoundError` is renamed to `ProviderNotFoundException`.

- The `SingleChildCloneableWidget` interface is removed and replaced by a new kind
  of widget `SingleChildWidget`.

  See [this issue](https://github.com/rrousselGit/provider/issues/237) for details
  on how to migrate.

- [Selector] now deeply compares the previous and new values if they are collections.

  If this is undesired, you can revert to the old behavior by passing a `shouldRebuild`
  parameter to [Selector]:

  ```dart
  Selector<Selected, Consumed>(
    shouldRebuild: (previous, next) => previous == next,
    builder: ...,
  )
  ```

- `DelegateWidget` and its family is removed. Instead, for custom providers,
  directly subclass [InheritedProvider] or an existing provider.

## Usage

### Exposing a value

#### Exposing a new object instance

Providers allow to not only expose a value, but also create/listen/dispose it.

To expose a newly created object, use the default constructor of a provider.
Do _not_ use the `.value` constructor if you want to **create** an object, or you
may otherwise have undesired side-effects.

See [this stackoverflow answer](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
which explains in further details why using the `.value` constructor to
create values is undesired.

- **DO** create a new object inside `create`.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **DON'T** use `Provider.value` to create your object.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **DON'T** create your object from variables that can change over
  the time.

  In such a situation, your object would never be updated when the
  value changes.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

If you want to pass variables that can change over time to your object,
consider using `ProxyProvider`:

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTE**:

When using the `create`/`update` callback of a provider, it is worth noting that this callback
is called lazily by default.

What this means is, until the value is requested at least once, the `create`/`update`
callbacks won't be called.

This behavior can be disabled if you want to pre-compute some logic, using the `lazy` parameter:

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### Reusing an existing object instance:

If you already have an object instance and want to expose it,
you should use the `.value` constructor of a provider.

Failing to do so may call the `dispose` method of your object when it is still in use.

- **DO** use `ChangeNotifierProvider.value` to provide an existing
  [ChangeNotifier].

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **DON'T** reuse an existing [ChangeNotifier] using the default constructor

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Reading a value

The easiest way to read a value is by using the extension methods on [BuildContext]:

- `context.watch<T>()`, which makes the widget listen to changes on `T`
- `context.read<T>()`, which returns `T` without listening to it
- `context.select<T, R>(R cb(T value))`, which allows a widget to listen to only a small part of `T`.

Or to use the static method `Provider.of<T>(context)`, which will behave similarly to `watch`/`read`.

These methods will look up in the widget tree starting from the widget associated
with the `BuildContext` passed, and will return the nearest variable of type
`T` found (or throw if nothing is found).

It's worth noting that this operation is O(1). It doesn't involve actually walking
in the widget tree.

Combined with the first example of [exposing a value](#exposing-a-value), this
widget will read the exposed `String` and render "Hello World."

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // Don't forget to pass the type of the object you want to obtain to `watch`!
      context.watch<String>(),
    );
  }
}
```

Alternatively, instead of using these methods, we can use [Consumer] and [Selector].

These can be useful for performance optimizations or when it is difficult to
obtain a `BuildContext` descendant of the provider.

See the [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) or the documentation of [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
and [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
for more information.

### MultiProvider

When injecting many values in big applications, `Provider` can rapidly become
pretty nested:

```dart
Provider<Something>(
  create: (_) => Something(),
  child: Provider<SomethingElse>(
    create: (_) => SomethingElse(),
    child: Provider<AnotherThing>(
      create: (_) => AnotherThing(),
      child: someWidget,
    ),
  ),
),
```

To:

```dart
MultiProvider(
  providers: [
    Provider<Something>(create: (_) => Something()),
    Provider<SomethingElse>(create: (_) => SomethingElse()),
    Provider<AnotherThing>(create: (_) => AnotherThing()),
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
        update: (_, counter, __) => Translations(counter.value),
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

#### Can I inspect the content of my objects?

Flutter comes with a [devtool](https://github.com/flutter/devtools) that shows
what the widget tree is at a given moment.

Since providers are widgets, they are also visible in that devtool:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

From there, if you click on one provider, you will be able to see the value it exposes:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(screenshot of the devtools using the `example` folder)

#### The devtool only shows "Instance of MyClass". What can I do?

By default, the devtool relies on `toString`, which defaults to "Instance of MyClass".

To have something more useful, you have two solutions:

- use the [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-class.html) API from Flutter.

  For most cases, that will be done my using [DiagnosticableTreeMixin]
  on your objects, followed by a custom implementation of [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html).

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // list all the properties of your class here.
      // See the documentation of debugFillProperties for more information.
      properties.add(IntProperty('a', a));
      properties.add(StringProperty('b', b));
    }
  }
  ```

- override `toString`.

  If you cannot use [DiagnosticableTreeMixin] (like if your class is in a package
  that does not depend on Flutter), then you can simply override `toString`.

  This is easier than using [DiagnosticableTreeMixin] but is less powerful:
  You will not be able to expand/collapse the details of your object.

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    String toString() {
      return '$runtimeType(a: $a, b: $b)';
    }
  }
  ```

#### I have an exception when obtaining Providers inside `initState`. What can I do?

This exception happens because you're trying to listen to a provider from a
life-cycle that will never ever be called again.

It means that you either should use another life-cycle
(`didChangeDependencies`/`build`), or explicitly specify that you do not care
about updates.

As such, instead of:

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

you can do:

```dart
Value value;

didChangeDependencies() {
  super.didChangeDependencies();
  final value = context.watch<Foo>.value;
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
  print(context.read<Foo>().value);
}
```

Which will print `value` once _and ignore updates._

#### I use [ChangeNotifier] and I have an exception when I update it, what happens?

This likely happens because you are modifying the [ChangeNotifier] from one of
its descendants _while the widget tree is building_.

A typical situation where this happens is when starting an http request, where
the future is stored inside the notifier:

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
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
      context.read<MyNotifier>(context).fetchSomething(someValue);
    );
  }
  ```
  It is slightly less ideal, but allows passing parameters to the mutation.

#### Do I have to use [ChangeNotifier] for complex states?

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
return Text(context.watch<int>().toString());
```

and modify the state with:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

Alternatively, you can create your own provider.

#### Can I make my own Provider?

Yes. `provider` exposes all the small components that make a fully-fledged provider.

This includes:

- `SingleChildCloneableWidget`, to make any widget works with `MultiProvider`.
- [InheritedProvider], the generic `InheritedWidget` obtained when doing `Provider.of`.
- `DelegateWidget`/`BuilderDelegate`/`ValueDelegate` to help handle the logic of
  "MyProvider() that creates an object" vs "MyProvider.value() that can update over time".

Here's an example of a custom provider to use `ValueNotifier` as state:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### My widget rebuilds too often, what can I do?

Instead of `context.watch`, you can use `context.select` to listen only to a
specific set of properties on the obtained object.

For example, while you can write:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

It may cause the widget to rebuild if something other than `name` changes.

Instead, you can use `context.select` to listen only to the `name` property:

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

This way, the widget won't unnecessarily rebuild if something other than `name`
changes.

Similarly, you can use [Consumer]/[Selector].
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
unnecessarily rebuild.

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

#### Can I consume an interface and provide an implementation?

Yes, a type hint must be given to the compiler to indicate the interface will be consumed, with the implementation provided in create.

```dart
abstract class ProviderInterface with ChangeNotifier {
  ...
}

class ProviderImplementation with ChangeNotifier implements ProviderInterface {
  ...
}

class Foo extends StatelessWidget {
  @override
  build(context) {
    final provider = Provider.of<ProviderInterface>(context);
    return ...
  }
}

ChangeNotifierProvider<ProviderInterface>(
  create: (_) => ProviderImplementation(),
  child: Foo(),
),
```

### Existing providers

`provider` exposes a few different kinds of "provider" for different types of objects.

The complete list of all the objects available is [here](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| name                                                                                                                          | description                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | The most basic form of provider. It takes a value and exposes it, whatever the value is.                                                                               |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | A specific provider for Listenable object. ListenableProvider will listen to the object and ask widgets which depend on it to rebuild whenever the listener is called. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | A specification of ListenableProvider for ChangeNotifier. It will automatically call `ChangeNotifier.dispose` when needed.                                             |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Listen to a ValueListenable and only expose `ValueListenable.value`.                                                                                                   |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Listen to a Stream and expose the latest value emitted.                                                                                                                |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Takes a `Future` and updates dependents when the future completes.                                                                                                     |

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html
