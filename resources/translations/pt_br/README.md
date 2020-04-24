[English](./README.md) | [Português](./resources/translations/pt/README.md)

[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dev/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

Uma mistura entre injeção de dependência (ID) e gerenciamento de estado, feito com widgets
para widgets.

O seu propósito é usar widgets para ID/gerenciamento de estado ao invés de somente classes do Dart como `Stream`.
A razão é que, widgets são muito simples mas ainda robustos e escaláveis.

Utilizando widgets para gerenciamento de estado, o `provider` pode garantir:

- manutenibilidade, através da imposição de um fluxo de dados unidirecional
- testabilidade/composição, pois é sempre possível mockar/sobrescrever um
  valor
- robustez, já que é mais difícil esquecer de atualizar a estrutura de um
  modelo/widget

Para ler mais sobre o `provider`, veja a [documentação](https://pub.dev/documentation/provider/latest/).

## Migração da v3.x.0 para v4.0.0

- Os parâmetros `builder` e `initialBuilder` foram removidos dos providers.

  - `initialBuilder` deve ser substituído por `create`.
  - `builder` de providers "proxy" deve ser substituído por `update`
  - `builder` de providers clássicos deve ser substituído por `create`.

- Os novos retornos de chamada `create`/`update` são carregados a medida que forem necessários (lazy-loaded), o que significa que eles são chamados
  na primeira vez que o valor for lido ao invés de quando o provedor for criado.

  Se desejar, você pode desativar o carregamento sob demanda (lazy-loading) passando `lazy: false` para
  o provedor de sua escolha:

  ```dart
  FutureProvider(
    create: (_) async => doSomeHttpRequest(),
    lazy: false,
    child: ...
  )
  ```

- `ProviderNotFoundError` foi renomeado para `ProviderNotFoundException`.

- A interface `SingleChildCloneableWidget` foi removida e substituída por um novo tipo
  de widget `SingleChildWidget`.

  Veja [essa issue](https://github.com/rrousselGit/provider/issues/237) para detalhes de como realizar a migração.

- `Selector` agora compara complementarmente os valores anteriores e novos se forem coleções.

  Se desejar, você pode reverter ao comportamento anterior passando um parâmetro `shouldRebuild`
  para o `Selector`:

  ```dart
  Selector<Selected, Consumed>(
    shouldRebuild: (previous, next) => previous == next,
    builder: ...,
  )
  ```

- `DelegateWidget` e companhia foram finalmente removidos. Ao invés, para providers customizados,
  herda diretamente de `InheritedProvider` ou um provedor existente.

## Uso

### Expondo um valor

#### Expondo uma nova instância de um objeto

Providers permitem não somente expor um valor, mas também criar/ouvir/dispô-lo.

Para expor um objeto recém criado, use o construtor padrão de um provider.
_Não_ use o construtor `.value` se você quiser **criar** um objeto, ou caso
caso contrário você poderá ter efeitos colaterais indesejados.

Veja [essa resposta no stackoverflow](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
que explica em mais detalhes por que usar o construtor `.value` para
criar valores é indesejado.

- **FAÇA** crie um novo objeto dentro do `create`.

```dart
Provider(
  create: (_) => new MyModel(),
  child: ...
)
```

- **NÃO** use o `Provider.value` para criar o seu objeto.

```dart
ChangeNotifierProvider.value(
  value: new MyModel(),
  child: ...
)
```

- **NÃO** crie seus objetos a partir de variáveis que possam
  mudar ao longo do tempo.

  Nessa situação, seu objeto pode nunca ser atualizado quando o
  valor mudar.

```dart
int count;

Provider(
  create: (_) => new MyModel(count),
  child: ...
)
```

Se você quiser passar variáveis que possam mudar ao longo do tempo para o seu objeto,
considere usar o `ProxyProvider`:

```dart
int count;

ProxyProvider0(
  update: (_, __) => new MyModel(count),
  child: ...
)
```

#### Re-usando uma instância existente de um objeto:

Se você já tem uma instância de um objeto e quer expô-la,
você deve usar o construtor `.value` de um provider.

Não fazer isso pode ser chamar o método `dispose` do seu objeto quando ele ainda está em uso.

- **FAÇA** use o `ChangeNotifierProvider.value` para prover um
  `ChangeNotifier` existente.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **NÃO** reuse um `ChangeNotifier` existente usando o construtor padrão

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Lendo um valor

A maneira mais fácil de ler um valor é usando um método estático
`Provider.of<T>(BuildContext context)`.

Esse método irá olhar na árvore de widgets acima começando pelo widget associado
com o `BuildContext` passado e retornará a variável mais próxima do tipo
`T` que foi encontrada (ou lançará uma exceção se nada for encontrado).

Combinado com o primeiro exemplo de [expondo um valor](#expondo-um-valor), esse
widget irá ler a variável `String` exposta e renderizar "Hello World."

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // Não se esqueça de passar o tipo do objeto que você quer obter ao `Provider.of`!
      Provider.of<String>(context)
    );
  }
}
```

Alternativamente ao invés de usar `Provider.of`, nós podemos usar `Consumer` e `Selector`.

Esses podem ser úteis para otimizações de performance ou quando for difícil de
obter um `BuildContext` descendente do provider.

Veja o [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) ou a documentação do [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
e [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
para mais informação.

### MultiProvider

Quando estiver injetando muitos valores em grandes aplicações, o `Provider` pode rapidamente se
tornar muito aninhado:

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

Para:

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

O comportamento de ambos exemplos é estritamente o mesmo. O `MultiProvider` apenas muda
a aparência do código.

### ProxyProvider

Desde a versão 3.0.0, existe um novo tipo de provider: `ProxyProvider`.

`ProxyProvider` é um provider que combina múltiplo valores de outros providers
em um novo objeto, e envia o resultado para o `Provider`.

Esse novo objeto será atualizado quando um dos providers que ele depende
atualizar.

O exemplo a seguir usa o `ProxyProvider` para construir traduções baseadas em um
contador vindo de outro provider.

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

  String get title => 'Você clicou $_value vezes';
}
```

Ele está sujeito a várias variações, como:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  O digito apos o nome da classe é o número de outros providers que o
  `ProxyProvider` depende.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Eles todos funciona de forma similar, mas ao invés de enviar o resultado ao `Provider`,
  um `ChangeNotifierProxyProvider` irá enviar um valor ao `ChangeNotifierProvider`.

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
unnecessarily rebuild.

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

The complete list of all the objects available is [here](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| name                                                                                                                          | description                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | The most basic form of provider. It takes a value and exposes it, whatever the value is.                                                                               |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | A specific provider for Listenable object. ListenableProvider will listen to the object and ask widgets which depend on it to rebuild whenever the listener is called. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | A specification of ListenableProvider for ChangeNotifier. It will automatically call `ChangeNotifier.dispose` when needed.                                             |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Listen to a ValueListenable and only expose `ValueListenable.value`.                                                                                                   |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Listen to a Stream and expose the latest value emitted.                                                                                                                |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Takes a `Future` and updates dependents when the future completes.                                                                                                     |
