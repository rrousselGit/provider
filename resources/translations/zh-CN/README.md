[English](../../../README.md) | [Português](./../pt_br/README.md) | [简体中文](./README.md)

[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dev/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)


[InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html) 组件的上层封装， 使其更易用， 更易复用。

使用 `provider` 而非手动书写 [InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html)，你会获得:

- 简化的资源分配与处置
- 懒加载
- 相较于每次创建一个新类，大大减少模板代码量
- 对开发者工具更为友好
- 更通用的消费 [InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html) 的方式(见 [Provider.of](https://pub.dev/documentation/provider/latest/provider/Provider/of.html)/[Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)/[Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) )
- 提升类的可伸缩性， 整体的监听架构(`listening mechanism`)时间复杂度以指数级增长(如[ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)， 其复杂度为O(N²))

想了解更多`provider`相关， 请参考 [文档](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

也可通过以下资源学习:

- [the official Flutter state management documentation](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)，展示如何结合使用`provider`与[ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)
- [flutter architecture sample](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider)，使用`provider`与[ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)的应用具体实现
- [flutter_bloc](https://github.com/felangel/bloc) and [Mobx](https://github.com/mobxjs/mobx.dart)，在BLoC与Mobx架构中使用`provider`

## 从 v3.x.0 迁移至 v4.0.0

- providers的 builder 与 initialBuilder 参数被移除

  - `initialBuilder`现在应当被 `create` 代替
  - 代理类providers(如 `ProxyProvider` )的 `builder` 属性应当被 `update` 代替
  - 普通providers的 `builder` 属性应当被 `create` 代替

- 新的 create/update 回调函数是懒加载的， 也就是说他们在对应的值第一次被读取时才被调用， 而非provider首次被创建时.

  如果你不需要这个特性， 你可以通过将provider的lazy属性置为false， 来禁用懒加载

  ```dart
  FutureProvider(
    create: (_) async => doSomeHttpRequest()，
    lazy: false，
    child: ...
  )
  ```

- `ProviderNotFoundError` 更名为 `ProviderNotFoundException`.

- `SingleChildCloneableWidget` 接口被移除， 并被全新类型的组件 `SingleChildWidget` 所替代

  参考这个 [issue](https://github.com/rrousselGit/provider/issues/237) 来获取迁移细节.

- [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) 现在会将先后的**集合类型的值**进行深层对比

  如果你不需要这个特性， 你可以通过 `shouldRebuild` 参数来使其还原至旧有表现.

  ```dart
  Selector<Selected， Consumed>(
    shouldRebuild: (previous， next) => previous == next，
    builder: ...，
  )
  ```

- `DelegateWidget`及其家族widget被移除， 现在想要自定义provider， 直接继承 [InheritedProvider](https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html) 或当前存在的provider.



## 使用

### 暴露一个值

#### 暴露一个新的对象实例

Providers不仅允许暴露出一个值，也可以创建/监听/销毁它。

要暴露一个新创建的对象， 使用一个provider的默认构造函数. 如果你想**创建**一个对象， **不要**使用 `.value` 构造函数， 否则可能会有你预期外的副作用。

查看该 [StackOverflow Answer](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)，来了解更多为什么不要使用`.value`构造函数创建值。

- **在create内创建新对象**

  ```dart
  Provider(
    create: (_) => MyModel()，
    child: ...
  )
  ```

- **不要使用`Provider.value`创建对象**

  ```dart
  ChangeNotifierProvider.value(
    value: MyModel()，
    child: ...
  )
  ```

- 不要以**可能随时间改变的变量**创建对象

  在这种情况下，如果变量发生变化，你的对象将永远不会被更新
  
  ```dart
  int count;
  
  Provider(
    create: (_) => MyModel(count)，
    child: ...
  )
  ```

	如果你想将随时间改变的变量传入给对象，请使用`ProxyProvider`:
	
	 ```dart
	int count;
	
	ProxyProvider0(
	  update: (_， __) => MyModel(count)，
	  child: ...
	)
	 ```
	
	

**注意:**

在使用一个provider的`create`/`update`回调时，请注意回调函数默认是**懒调用**的。

也就是说， 除非这个值被读取了至少一次， 否则`create`/`update`函数不会被调用。

如果你想预先计算一些逻辑， 可以通过使用`lazy`参数来禁用这一行为。

```dart
MyProvider(
  create: (_) => Something()，
  lazy: false，
)
```

#### 复用一个已存在的对象实例:

如果你已经拥有一个对象实例并且想暴露出它，你应当使用一个provider的`.value`构造函数。

如果你没有这么做，那么在你调用对象的 `dispose` 方法时， 这个对象可能仍然在被使用。

- **使用`ChangeNotifierProvider.value`来提供一个当前已存在的 [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)**

  ```dart
  MyChangeNotifier variable;
  
  ChangeNotifierProvider.value(
    value: variable，
    child: ...
  )
  ```

- 不要使用默认的构造函数来尝试复用一个已存在的 [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)

  ```dart
  MyChangeNotifier variable;
  
  ChangeNotifierProvider(
    create: (_) => variable，
    child: ...
  )
  ```



### 读取一个值

读取一个值最简单的方式就是使用`BuildContext`上的扩展属性(由`provider`注入)。

- `context.watch<T>()`， 一方法使得widget能够监听泛型`T`上发生的改变。
- `context.read<T>()`，直接返回`T`，不会监听改变。
- `context.select<T， R>(R cb(T value))`，允许widget只监听`T`上的一部分(`R`)。

或者使用 `Provider.of<T>(context) `这一静态方法，它的表现类似 `watch` ，而在你为 `listen` 参数传入 `false` 时(如 `Provider.of<T>(context，listen: false)` )，它的表现类似于 `read`。

值得注意的是，`context.read<T>()` 方法不会在值变化时使得widget重新构建， 并且不能在 `StatelessWidget.build`/`State.build` 内调用. 换句话说， 它可以在除了这两个方法以外的任意之处调用。

上面列举的这些方法会与传入的 `BuildContext` 关联的widget开始查找widget树，并返回查找到的最近的类型T的变量(如果没有找到， 将抛出错误)。

值得注意是这一操作的复杂度是 O(1)，它实际上并不涉及遍历整个组件树。

结合上面第一个[向外暴露一个值](https://github.com/rrousselGit/provider/blob/master/README.md#exposing-a-value)的例子，这个widget会读取暴露出的`String`并渲染`Hello World`。

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // Don't forget to pass the type of the object you want to obtain to `watch`!
      context.watch<String>()，
    );
  }
}
```

或者不使用这些方法，我们也可以使用 [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html) 与 [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)。

这些往往在**性能优化**以及当**很难获取到provider的构建上下文后代**(difficult to obtain a `BuildContext` descendant of the provider) 时是很有用的。



参见 [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) 或关于[Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html) 和 [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) 的文档部分了解更多.



### MultiProvider

当在大型应用中注入较多状态时， `Provider` 很容易变得高度耦合:

```dart
Provider<Something>(
  create: (_) => Something()，
  child: Provider<SomethingElse>(
    create: (_) => SomethingElse()，
    child: Provider<AnotherThing>(
      create: (_) => AnotherThing()，
      child: someWidget，
    )，
  )，
)，
```

使用`MultiProvider`:

```dart
MultiProvider(
  providers: [
    Provider<Something>(create: (_) => Something())，
    Provider<SomethingElse>(create: (_) => SomethingElse())，
    Provider<AnotherThing>(create: (_) => AnotherThing())，
  ]，
  child: someWidget，
)
```

以上两个例子的实际表现是一致的， `MultiProvider`唯一改变的就是代码书写方式.



### ProxyProvider

从3.0.0开始， 我们提供了一种新的provider: `ProxyProvider`.

`ProxyProvider`能够将多个来自于其他的providers的值聚合为一个新对象，并且将结果传递给`Provider`。

这个新对象会在其依赖的任一providers更新后被更新

下面的例子使用`ProxyProvider`，基于来自于另一个provider的counter值进行转化。

```dart
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => Counter())，
      ProxyProvider<Counter， Translations>(
        update: (_， counter， __) => Translations(counter.value)，
      )，
    ]，
    child: Foo()，
  );
}

class Translations {
  const Translations(this._value);

  final int _value;

  String get title => 'You clicked $_value times';
}
```

这个例子还有多种变化:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`， ...

  类名后的数字是 `ProxyProvider` 依赖的其他providers的数量

  

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`， ...

  它们工作的方式是相似的， 但 `ChangeNotifierProxyProvider` 会将它的值传递给`ChangeNotifierProvider` 而非 `Provider`。

### FAQ

#### 我是否能查看(inspect)我的对象的内容?

Flutter提供的[开发者工具](https://github.com/flutter/devtools)能够展示特定时刻下的widget树。

既然providers同样是widget，他们同样能通过开发者工具进行查看。

![img](https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg)

点击一个provider， 即可查看它暴露出的值:

![img](https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg)

以上的开发者工具截图来自于 `/example` 文件夹下的示例



#### 开发者工具只显示"Instance of MyClass"， 我能做什么?

默认情况下， 开发者工具基于`toString`，也就使得默认结果是 "Instance of MyClass"。

如果要得到更多信息，你有两种方式:

- 使用Flutter提供的 [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-class.html) API

  在大多数情况下， 只需要在你的对象上使用 [DiagnosticableTreeMixin](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html) 即可，以下是一个自定义 [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html) 实现的例子:

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a， this.b});
  
    final int a;
    final String b;
  
    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // list all the properties of your class here.
      // See the documentation of debugFillProperties for more information.
      properties.add(IntProperty('a'， a));
      properties.add(StringProperty('b'， b));
    }
  }
  ```

- 重写`toString`方法

  如果你无法使用 [DiagnosticableTreeMixin](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html) (比如你的类在一个不依赖于Flutter的包中)， 那么你可以通过简单重写`toString`方法来达成效果。
  
  这比使用 [DiagnosticableTreeMixin](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html) 要更简单，但能力也有着不足: 你无法 展开/折叠 来查看你的对象内部细节。
  
  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a， this.b});
  
    final int a;
    final String b;
  
    @override
    String toString() {
      return '$runtimeType(a: $a， b: $b)';
    }
  }
  ```

#### 在获得`initState`内部的Providers时发生了异常， 该做什么?

这个异常的出现是因为你在尝试监听一个来自于**永远不会再次被调用的生命周期**的provider。

这意味着你要么使用另外一个生命周期(`build`)，要么显式指定你并不在意后续更新。

也就是说，不应该这么做:

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

你可以这么做:

```dart
Value value;

Widget build(BuildContext context) {
  final value = context.watch<Foo>.value;
  if (value != this.value) {
    this.value = value;
    print(value);
  }
}
```

这会且只会在`value`变化时打印它。

或者你也可以这么做:

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

这样只会打印一次value，并且会忽视后续的更新

#### 如何控制我的对象上的热更新?

你可以使你提供的对象实现 `ReassembleHandler` 类:

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

通常会和 `provider` 一同使用:

```dart
ChangeNotifierProvider(create: (_) => Example())，
```

#### 使用[ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)时， 在更新后出现了异常， 发生了什么?

这通常是因为你**在widget树正在构建时**，从[ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)的某个后代更改了ChangeNotifier。

最典型的情况是在一个future被保存在notifier内部时发起http请求。

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

这是不被允许的，因为更改会立即生效.

也就是说，一些widget可能在**变更发生前**构建，而有些则可能在**变更后**. 这可能造成UI不一致， 因此是被禁止的。

所以，你应该在一个**整个widget树所受影响相同的位置**执行变更:

- 直接在你的model的 provider/constructor 的 `create` 方法内调用:

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }
  
    Future<void> _fetchSomething() async {}
  }
  ```

  在不需要传入形参的情况下，这是相当有用的。

- 在框架的末尾异步的执行(`Future.microtask`):

  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>(context).fetchSomething(someValue);
    );
  }
  ```
  
  这可能不是理想的使用方式，但它允许你向变更传递参数。

#### 我必须为复杂状态使用 [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) 吗?

不。

你可以使用任意对象来表示你的状态，举例来说，一个可选的架构方案是使用`Provider.value`配合`StatefulWidget`

这是一个使用这种架构的计数器示例:

```dart
class Example extends StatefulWidget {
  const Example({Key key， this.child}) : super(key: key);

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
      value: _count，
      child: Provider.value(
        value: this，
        child: widget.child，
      )，
    );
  }
}
```

我们可以通过这样来读取状态:

```dart
return Text(context.watch<int>().toString());
```

并且这样来修改状态:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment()，
  child: Icon(Icons.plus_one)，
);
```

或者你还可以自定义provider.

#### 我可以创建自己的Provider吗?

可以，`provider`暴露出了所有构建功能完备的provider所需的组件，它包含:

- `SingleChildStatelessWidget`， 使任意widget能够与 `MultiProvider` 协作， 这个接口被暴露为包 `package:provider/**single_child_widget` 的一部分**
- [InheritedProvider](https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html)，在使用 `context.watch` 时可获取的通用`InheritedWidget`。

这里有个使用 `ValueNotifier` 作为状态的自定义provider例子:

https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### 我的widget重构建太频繁了， 我能做什么?

你可以使用 `context.select` 而非 `context.watch` 来指定只监听对象的部分属性:

举例来说，你可以这么写:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

这可能导致widget在 `name` 以外的属性发生变化时重构建。

你可以使用 `context.select`来 只监听`name`属性

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

这样，这widget间就不会在`name`以外的属性变化时进行不必要的重构建了。

同样，你也可以使用[Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)/[Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)，可选的`child`参数使得widget树中只有所指定的一部分会重构建。

```dart
Foo(
  child: Consumer<A>(
    builder: (_， a， child) {
      return Bar(a: a， child: child);
    }，
    child: Baz()，
  )，
)
```

在这个示例中， 只有`Bar`会在`A`更新时重构建，`Foo`与`Baz`不会进行不必要的重构建。

#### 我能使用相同类型来获得两个不同的provider吗?

不。 当你有两个持有相同类型的不同provider时，一个widget只会获取其中之一: **最近的一个**。

你必须显式为两个provider提供不同类型，而不是:

```dart
Provider<String>(
  create: (_) => 'England'，
  child: Provider<String>(
    create: (_) => 'London'，
    child: ...，
  )，
)，
```

推荐的写法:

```dart
Provider<Country>(
  create: (_) => Country('England')，
  child: Provider<City>(
    create: (_) => City('London')，
    child: ...，
  )，
)，
```

#### 我能消费一个接口并且提供一个实现吗?

能，类型提示(`type hint`)必须被提供给编译器，来指定将要被消费的接口，同时需要在`craete`中提供具体实现:

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
  create: (_) => ProviderImplementation()，
  child: Foo()，
)，
```

#### 现有的providers

`provider`中提供了几种不同类型的"provider"，供不同类型的对象使用。

完整的可用列表参见 [provider-library]([here](https://pub.dev/documentation/provider/latest/provider/provider-library.html))

| name                                                                                                                          | description                                                                                               |
| ----------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | 最基础的provider组成，接收一个值并暴露它， 无论值是什么。                                                 |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | 供可监听对象使用的特殊provider，ListenableProvider会监听对象，并在监听器被调用时更新依赖此对象的widgets。 |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | 为ChangeNotifier提供的ListenableProvider规范，会在需要时自动调用`ChangeNotifier.dispose`。                |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | 监听ValueListenable，并且只暴露出`ValueListenable.value`。                                                |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | 监听流，并暴露出当前的最新值。                                                                            |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | 接收一个`Future`，并在其进入complete状态时更新依赖它的组件。                                              |
