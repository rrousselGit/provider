[English](../../../README.md) | [Português](./README.md)

[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dev/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

Uma mistura entre injeção de dependência (ID) e gerenciamento de estado, feito com widgets
para widgets.

O seu propósito é usar widgets para ID/gerenciamento de estado ao invés de somente classes do Dart como `Stream`.
A razão é que, widgets são muito simples mas ainda assim robustos e escaláveis.

Utilizando widgets para gerenciamento de estado, o `provider` pode garantir:

- manutenibilidade, através da imposição de um fluxo de dados unidirecional
- testabilidade/composição, pois é sempre possível mockar/sobrescrever um
  valor
- robustez, já que é mais difícil esquecer de atualizar a estrutura de um
  model/widget

Para ler mais sobre o `provider`, veja a [documentação](https://pub.dev/documentation/provider/latest/).

## Migração da v3.x.0 para v4.0.0

- Os parâmetros `builder` e `initialBuilder` foram removidos dos providers.

  - `initialBuilder` deve ser substituído por `create`.
  - `builder` dos providers "proxy" devem ser substituído por `update`
  - `builder` dos providers clássicos devem ser substituído por `create`.

- Os novos retornos de chamada `create`/`update` são carregados a medida que forem necessários (lazy-loaded), o que significa que eles são chamados
  apenas na primeira vez em que o valor for lido ao invés de quando o provider for criado.

  Se desejar, você pode desativar o carregamento sob demanda (lazy-loading) passando `lazy: false` para
  o provider de sua escolha:

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

- `Selector` agora compara complementarmente os valores anteriores e os novos se forem coleções.

  Se desejar, você pode voltar ao comportamento anterior passando um parâmetro `shouldRebuild`
  para o `Selector`:

  ```dart
  Selector<Selected, Consumed>(
    shouldRebuild: (previous, next) => previous == next,
    builder: ...,
  )
  ```

- `DelegateWidget` e companhia foram finalmente removidos. Ao invés, providers customizados
  herdam diretamente de `InheritedProvider` ou um provedor existente.

## Uso

### Expondo um valor

#### Expondo uma nova instância de um objeto

Providers permitem não somente expor um valor, mas também criar/ouvir/dispô-lo.

Para expor um objeto recém criado, use o construtor padrão de um provider.
_Não_ use o construtor `.value` se você quiser **criar** um objeto, ou caso
caso contrário você poderá ter efeitos colaterais indesejados.

Veja [essa resposta no stackoverflow](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
que explica em mais detalhes por que usar o construtor `.value` para
criar valores não é ideal.

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

Não fazendo isso o método `dispose` do seu objeto pode ser chamado quando ele ainda está em uso.

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

A maneira mais fácil de ler um valor é usando o método estático
`Provider.of<T>(BuildContext context)`.

Esse método irá olhar na árvore de widgets acima começando pelo widget associado
ao `BuildContext` passado e retornará a variável mais próxima do tipo
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

Esses podem ser úteis para otimizações de performance ou quando for difícil de se
obter um `BuildContext` descendente do provider.

Veja o [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) ou a documentação do [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
e [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
para mais informação.

### MultiProvider

Quando estiver injetando muitos valores em grandes aplicações, o `Provider` pode se tornar muito aninhado rapidamente:

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

`ProxyProvider` é um provider que combina múltiplos valores de outros providers
em um novo objeto, e envia o resultado para o `Provider`.

Esse novo objeto será atualizado quando um dos providers que ele depende
for atualizado.

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

Ele está sujeito a variações, como:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  O digito apos o nome da classe é o número de outros providers que o
  `ProxyProvider` depende.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Todos eles funcionam de forma similar, mas ao invés de enviar o resultado ao `Provider`,
  um `ChangeNotifierProxyProvider` irá enviar o valor ao `ChangeNotifierProvider`.

### FAQ

### Eu recebo uma exceção quando estou obtendo Providers dentro do `initState`. O que posso fazer?

Essa exceção ocorre porque você está tentando ouvir de um provider a partir
de um ciclo de vida que nunca será chamado novamente.

Isso significa que você deve utilizar outro ciclo de vida como
(`didChangeDependencies`/`build`), ou explicitar especificamente que você não se importa
com as atualizações.

Como, ao invés de:

```dart
initState() {
  super.initState();
  print(Provider.of<Foo>(context).value);
}
```

você pode fazer:

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

que imprimirá o `value` sempre que ele mudar.

Alternativamente você pode fazer:

```dart
initState() {
  super.initState();
  print(Provider.of<Foo>(context, listen: false).value);
}
```

Que imprimirá o `value` uma vez e irá ignorar as atualizações.

### Eu uso o `ChangeNotifier` e estou recebendo uma exceção quando o atualizo, o que acontece?

Isso provavelmente acontece porque você está mudando o `ChangeNotifier` de um dos
seus descendentes _enquanto a árvore de widgets está sendo construída_.

Uma tipica situação onde isso acontece é quando se está iniciando uma requição http, onde
o future é armazenado dentro do notifier:

```dart
initState() {
  super.initState();
  Provider.of<Foo>(context).fetchSomething();
}
```

Isso não é permitido, porque as modificações são imediatas.

O que significa que alguns widgets podem ser construídos _antes_ da mudança, enquanto outros
widgets serão construídos _após_ a mudança.
Isso pode causar consequências na sua interface e portanto não é permitido.

Ao invés, você deve executar essa mudança em um local que afete igualmente
a árvore inteira:

- diretamente dentro do `create` do provider/construtor do seu model:

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  Isso é útil quando não temos "parâmetros externos".

- assincronamente ao fim do frame:
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<Foo>(context).fetchSomething(someValue);
    );
  }
  ```
  É um pouco menos ideal, mas permite a passagem de parâmetros para a mudança.

#### Preciso usar o `ChangeNotifier` para estados complexos?

Não.

Você pode utilizar qualquer objeto para representar o seu estado. Por exemplo, uma arquitetura
alternativa é usar o `Provider.value()` combinado com um `StatefulWidget`.

Aqui está um exemplo de contador usando essa arquitetura:

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

Onde podemos ler o estado usando:

```dart
return Text(Provider.of<int>(context).toString());
```

e modificar o estado com:

```dart
return FloatingActionButton(
  onPressed: Provider.of<ExampleState>(context).increment,
  child: Icon(Icons.plus_one),
);
```

Alternativamente, você pode criar o seu próprio provider.

#### Posso criar o meu próprio Provider?

Sim. O `provider` expõe todos os pequenos componentes que tornam um provider completo.

Isso inclui:

- `SingleChildCloneableWidget`, para fazer com que qualquer widget funcione com o `MultiProvider`.
- `InheritedProvider`, o `InheritedWidget` generico é obtido usando o `Provider.of`.
- `DelegateWidget`/`BuilderDelegate`/`ValueDelegate` para ajudar a lidar com a lógica do
  "MyProvider() que cria um objeto" vs "MyProvider.value() que pode ser atualizado com o tempo".

Aqui está um exempo de um provider cutomizado que usa o `ValueNotifier` como estado:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### Meu widget é reconstruído com frequência, o que posso fazer?

Ao invés de usar o `Provider.of`, você pode usar o `Consumer`/`Selector`.

O seu argumento opcional `child` permite reconstruir somente uma parte específica da
árvore de widgets:

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

Nesse exemplo, somente `Bar` será reconstruído quando `A` for atualizado. `Foo` e `Baz` não
serão reconstruídos desnecessariamente.

Dando um passo a mais, é possível utilizar o `Selector` para ignorar mudanças se
elas não tiverem impacto na árvore de widgets:

```dart
Selector<List, int>(
  selector: (_, list) => list.length,
  builder: (_, length, __) {
    return Text('$length');
  }
);
```

Esse trecho será reconstruído somente se o tamanho da lista mudar. Mas não irá
atualizar desnecessariamente se um item for atualizado.

#### Posso obter dois providers diferentes usando o mesmo tipo?

Não. Embora você possa ter vários providers compartilhando o mesmo tipo, um widget
só ira conseguir obter apenas um deles: o ancestral mais próximo.

Ao invés disso, você deve dar explicitamente tipos diferentes a ambos providers.

Ao invés de:

```dart
Provider<String>(
  create: (_) => 'Inglaterra',
  child: Provider<String>(
    create: (_) => 'Londres',
    child: ...,
  ),
),
```

Prefira:

```dart
Provider<Country>(
  create: (_) => Country('Inglaterra'),
  child: Provider<City>(
    create: (_) => City('Londres'),
    child: ...,
  ),
),
```

## Providers existentes

O `provider` expõe alguns diferentes tipos de "provider" para diferentes tipos de objetos.

A lista completa de todos os objetos disponiveis está [aqui](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| nome                                                                                                                          | descrição                                                                                                                                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | A forma mais básica de provider. Ele pega um valor e o expõe, qualquer que seja o valor.                                                                                                                 |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Um provider especifico para objetos que possam ser ouvidos. O ListenableProvider irá ouvir o objetor e pedir para que os widgets que dependam dele sejam reconstruídos sempre que o ouvinte for chamado. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | Uma especificação do ListenableProvider para ChangeNotifier. Ele chama automaticamente o `ChangeNotifier.dispose` quando preciso.                                                                        |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Escuta um ValueListenable e apenas expoe o `ValueListenable.value`.                                                                                                                                      |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Escuta uma Stream e expoe o ultimo valor emitido.                                                                                                                                                        |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Recebe um `Future` e atualiza os depedentes quando o future for atualizado.                                                                                                                              |
