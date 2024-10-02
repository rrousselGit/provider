[English](https://github.com/rrousselGit/provider/blob/master/packages/provider/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](https://github.com/rrousselGit/provider/blob/master/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md) | [Turkish](https://github.com/rrousselGit/provider/blob/master/resources/translations/tr_TR/README.md) | [Italian](https://github.com/rrousselGit/provider/blob/master/resources/translations/it_IT/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) <a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

Un wrapper attorno a [InheritedWidget] per renderli più facili da usare e più riutilizzabili.

Utilizzando `provider` invece di scrivere manualmente [InheritedWidget], ottieni:

- una gestione semplificata dell'allocazione e della rimozione delle risorse
- caricamento ritardato (lazy-loading)
- una drastica riduzione del codice boilerplate rispetto alla creazione di una nuova classe ogni volta
- compatibilità con gli strumenti di sviluppo – utilizzando Provider, lo stato della tua applicazione sarà visibile negli strumenti di sviluppo di Flutter
- un modo comune per consumare questi [InheritedWidget] (Vedi [Provider.of]/[Consumer]/[Selector])
- una maggiore scalabilità per le classi con un meccanismo di ascolto che cresce esponenzialmente in complessità (come [ChangeNotifier], che è O(N) per l'invio di notifiche).

Per ulteriori informazioni su `provider`, consulta la sua [documentazione](https://pub.dev/documentation/provider/latest/provider/provider-library.html).

Vedi anche:

- [La documentazione ufficiale di Flutter sulla gestione dello stato](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), che mostra come usare `provider` + [ChangeNotifier]
- [Esempio di architettura Flutter](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider), che contiene un'implementazione di quell'app utilizzando `provider` + [ChangeNotifier]
- [flutter_bloc](https://github.com/felangel/bloc) e [Mobx](https://github.com/mobxjs/mobx.dart), che utilizzano un `provider` nella loro architettura

## Migrazione da 4.x.x a 5.0.0-nullsafety

- `initialData` per entrambi `FutureProvider` e `StreamProvider` ora è richiesto.

  Per migrare, ciò che prima era:

  ```dart
  FutureProvider<int>(
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    final value = context.watch<int>();
    return Text('$value');
  }
  ```

  ora è:

  ```dart
  FutureProvider<int?>(
    initialValue: null,
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    // assicurati di specificare ? in watch<int?>
    final value = context.watch<int?>();
    return Text('$value');
  }
  ```

  - `ValueListenableProvider` è stato rimosso

  Per migrare, puoi invece usare `Provider` combinato con `ValueListenableBuilder`:

  ```dart
  ValueListenableBuilder<int>(
    valueListenable: myValueListenable,
    builder: (context, value, _) {
      return Provider<int>.value(
        value: value,
        child: MyApp(),
      );
    }
  )
  ```

## Utilizzo

### Esporre un valore

#### Esporre una nuova istanza di un oggetto

I provider ti permettono non solo di esporre un valore, ma anche di crearlo, ascoltarlo e disporne.

Per esporre un oggetto appena creato, utilizza il costruttore predefinito di un provider.
Non utilizzare il costruttore `.value` se desideri **creare** un oggetto, altrimenti potresti avere effetti collaterali indesiderati.

Consulta [questa risposta su StackOverflow](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build) che spiega perché l'utilizzo del costruttore `.value` per creare valori è sconsigliato.

- **DEVI** creare un nuovo oggetto all'interno di `create`.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **NON** usare `Provider.value` per creare il tuo oggetto.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **NON** creare il tuo oggetto a partire da variabili che possono cambiare nel tempo.

  In una situazione del genere, il tuo oggetto non si aggiornerebbe mai quando il valore cambia.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

Se desideri passare variabili che possono cambiare nel tempo al tuo oggetto,
considera l'uso di `ProxyProvider`:

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTA**:

Quando si utilizza la callback `create`/`update` di un provider, è importante notare che questa callback viene chiamata in modo lazy (pigro) per impostazione predefinita.

Ciò significa che finché il valore non viene richiesto almeno una volta, le callback `create`/`update` non verranno chiamate.

Questo comportamento può essere disabilitato se si desidera pre-calcolare una logica, utilizzando il parametro `lazy`:

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### Riutilizzare un'istanza di oggetto esistente:

Se hai già un'istanza di un oggetto e vuoi esporla, è meglio utilizzare il costruttore `.value` di un provider.

Se non lo fai, potresti chiamare il metodo `dispose` del tuo oggetto mentre è ancora in uso.

- **DEVI** utilizzare `ChangeNotifierProvider.value` per fornire un [ChangeNotifier] esistente.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **NON** riutilizzare un [ChangeNotifier] esistente utilizzando il costruttore predefinito

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Leggere un valore

Il modo più semplice per leggere un valore è utilizzare i metodi di estensione su [BuildContext]:

- `context.watch<T>()`, che fa sì che il widget ascolti le modifiche su `T`
- `context.read<T>()`, che restituisce `T` senza ascoltarlo
- `context.select<T, R>(R cb(T value))`, che consente a un widget di ascoltare solo una piccola parte di `T`.

Si può anche usare il metodo statico `Provider.of<T>(context)`, che si comporterà in modo simile a `watch`. Quando il parametro `listen` è impostato su `false` (come in `Provider.of<T>(context, listen: false)`), si comporterà in modo simile a `read`.

Vale la pena notare che `context.read<T>()` non farà ricostruire un widget quando il valore cambia e non può essere chiamato all'interno di `StatelessWidget.build`/`State.build`.
D'altra parte, può essere chiamato liberamente al di fuori di questi metodi.

Questi metodi cercheranno nell'albero dei widget a partire dal widget associato al `BuildContext` passato e restituiranno la variabile più vicina di tipo `T` trovata (o lanceranno un'eccezione se nulla viene trovato).

Questa operazione è O(1). Non comporta l'attraversamento dell'albero dei widget.

Combinato con il primo esempio di [esporre un valore](#esporre-un-valore), questo widget leggerà la `String` esposta e renderizzerà "Hello World."

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // Non dimenticare di passare il tipo di oggetto che vuoi ottenere a `watch`!
      context.watch<String>(),
    );
  }
}
```

In alternativa, invece di utilizzare questi metodi, possiamo usare [Consumer] e [Selector].

Questi possono essere utili per ottimizzazioni delle prestazioni o quando è difficile
ottenere un `BuildContext` discendente del provider.

Consulta le [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do)
o la documentazione di [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
e [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
per ulteriori informazioni.

### Dipendere facoltativamente da un provider

A volte, potremmo voler supportare casi in cui un provider non esiste. Un
esempio potrebbe essere per widget riutilizzabili che potrebbero essere utilizzati in varie posizioni,
anche al di fuori di un provider.

Per fare ciò, quando chiami `context.watch`/`context.read`, rendi il tipo generico
nullable. In modo tale che invece di:

```dart
context.watch<Model>()
```

che lancerà un `ProviderNotFoundException` se non vengono trovati provider corrispondenti, fai:

```dart
context.watch<Model?>()
```

che cercherà di ottenere un provider corrispondente. Ma se nessuno viene trovato,
verrà restituito `null` invece di lanciare un'eccezione.

### MultiProvider

Quando si iniettano molti valori in applicazioni grandi, `Provider` può diventare rapidamente
piuttosto annidato:

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

In:

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

Il comportamento di entrambi gli esempi è strettamente lo stesso. `MultiProvider` cambia solo
l'aspetto del codice.

### ProxyProvider

A partire dalla versione 3.0.0, esiste un nuovo tipo di provider: `ProxyProvider`.

`ProxyProvider` è un provider che combina più valori da altri provider in un nuovo oggetto e invia il risultato a `Provider`.

Questo nuovo oggetto verrà aggiornato ogni volta che uno dei provider da cui dipendiamo viene aggiornato.

Il seguente esempio utilizza `ProxyProvider` per costruire traduzioni basate su un contatore proveniente da un altro provider.

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

Esistono diverse varianti, come:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  Il numero dopo il nome della classe indica quanti altri provider da cui `ProxyProvider` dipende.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Funzionano tutti in modo simile, ma invece di inviare il risultato a un `Provider`,
  un `ChangeNotifierProxyProvider` invierà il suo valore a un `ChangeNotifierProvider`.

### FAQ

#### Posso ispezionare il contenuto dei miei oggetti?

Flutter viene fornito con un [devtool](https://github.com/flutter/devtools) che mostra
l'albero dei widget in un dato momento.

Poiché i provider sono widget, sono anche visibili in quel devtool:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

Da lì, se clicchi su un provider, sarai in grado di vedere il valore che espone:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(screenshot dei devtools usando la cartella `example`)

#### Il devtool mostra solo "Instance of MyClass". Cosa posso fare?

Per impostazione predefinita, il devtool si basa su `toString`, che per default restituisce "Instance of MyClass".

Per avere qualcosa di più utile, hai due soluzioni:

- utilizza l'API [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) di Flutter.

  Nella maggior parte dei casi, utilizza [DiagnosticableTreeMixin] sui tuoi oggetti, seguito da un'implementazione personalizzata di [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html).

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // elenca qui tutte le proprietà della tua classe.
      // Per ulteriori informazioni, consultare la documentazione di debugFillProperties.
      properties.add(IntProperty('a', a));
      properties.add(StringProperty('b', b));
    }
  }
  ```

- Sovrascrivi `toString`.

  Se non puoi utilizzare [DiagnosticableTreeMixin] (ad esempio, se la tua classe è in un pacchetto che non dipende da Flutter), puoi sovrascrivere `toString`.

  Questo è più semplice rispetto all'uso di [DiagnosticableTreeMixin], ma è meno potente:
  Non sarai in grado di espandere/contrarre i dettagli del tuo oggetto.
  
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

#### Ho un'eccezione quando ottengo i Providers all'interno di `initState`. Cosa posso fare?

Questa eccezione si verifica perché stai cercando di ascoltare un provider da un
ciclo di vita che non verrà mai più chiamato.

Significa che dovresti utilizzare un altro ciclo di vita (`build`), oppure specificare esplicitamente che non ti interessano gli aggiornamenti.

Pertanto, invece di:

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

puoi fare:

```dart
Value value;

Widget build(BuildContext context) {
  final value = context.watch<Foo>().value;
  if (value != this.value) {
    this.value = value;
    print(value);
  }
}
```

che stamperà `value` ogni volta che cambia (e solo quando cambia).

In alternativa, puoi fare:

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

che stamperà `value` una sola volta _e ignorerà gli aggiornamenti._

#### Come gestire il hot-reload sui miei oggetti?

Puoi far implementare al tuo oggetto fornito `ReassembleHandler`:

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

Poi usato tipicamente con `provider`:

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### Uso [ChangeNotifier], e ho un'eccezione quando lo aggiorno. Cosa succede?

Questo probabilmente accade perché stai modificando il [ChangeNotifier] da uno dei suoi discendenti _mentre l'albero dei widget è in fase di costruzione_.

Una situazione tipica in cui ciò accade è quando si avvia una richiesta http, dove il futuro è memorizzato all'interno del notifier:

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

Questo non è consentito perché l'aggiornamento dello stato è sincrono.

Ciò significa che alcuni widget potrebbero essere costruiti _prima_ che avvenga la mutazione (ottenendo un valore obsoleto), mentre altri widget verranno costruiti _dopo_ che la mutazione è completata (ottenendo un nuovo valore). Questo potrebbe causare incoerenze nella tua UI e quindi non è permesso.

Invece, dovresti eseguire quella mutazione in un luogo che influenzi
l'intero albero in modo uniforme:

- direttamente all'interno del `create` del tuo provider/costruttore del tuo modello:

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```
  Questo è utile quando non c'è un "parametro esterno".

- in modo asincrono alla fine del frame:
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>().fetchSomething(someValue);
    );
  }
  ```
  È leggermente meno ideale, ma consente di passare parametri alla mutazione.
 
#### Devo usare [ChangeNotifier] per stati complessi?

No.

Puoi usare qualsiasi oggetto per rappresentare il tuo stato. Ad esempio, un'alternativa
è usare `Provider.value()` combinato con un `StatefulWidget`.

Ecco un esempio di contatore che utilizza tale architettura:

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
dove possiamo leggere lo stato facendo:

```dart
return Text(context.watch<int>().toString());
```

e modificare lo stato con:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

In alternativa, puoi creare il tuo provider.

#### Posso creare il mio Provider?

Sì. `provider` espone tutti i piccoli componenti che costituiscono un provider completo.

Questo include:

- `SingleChildStatelessWidget`, per far funzionare qualsiasi widget con `MultiProvider`.
  Questa interfaccia è esposta come parte di `package:provider/single_child_widget`.

- [InheritedProvider], il `InheritedWidget` generico ottenuto quando si usa `context.watch`.

Ecco un esempio di un provider personalizzato che utilizza `ValueNotifier` come stato:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### Il mio widget si ricostruisce troppo spesso. Cosa posso fare?

Invece di `context.watch`, puoi usare `context.select` per ascoltare solo un insieme specifico di proprietà sull'oggetto ottenuto.

Ad esempio, mentre puoi scrivere:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

Questo potrebbe causare la ricostruzione del widget se qualcosa oltre a `name` cambia.

Invece, puoi usare `context.select` per ascoltare solo la proprietà `name`:

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

In questo modo, il widget non verrà ricostruito inutilmente se qualcosa oltre a `name` cambia.

Allo stesso modo, puoi usare [Consumer]/[Selector]. Il loro argomento opzionale `child` consente di ricostruire solo una parte particolare dell'albero dei widget:

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

In questo esempio, solo `Bar` verrà ricostruito quando `A` viene aggiornato. `Foo` e `Baz` non verranno ricostruiti inutilmente.

#### Posso ottenere due provider diversi utilizzando lo stesso tipo?

No. Anche se puoi avere più provider che condividono lo stesso tipo, un widget sarà in grado di ottenere solo uno di essi: il più vicino antenato.

Invece, sarebbe utile se dessi esplicitamente a entrambi i provider un tipo diverso.

Invece di:

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

Preferisci:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### Posso consumare un'interfaccia e fornire un'implementazione?

Sì, è necessario fornire un'indicazione al compilatore per indicare che l'interfaccia sarà consumata, con l'implementazione fornita in `create`.

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

### Provider esistenti

`provider` espone alcuni tipi diversi di "provider" per diversi tipi di oggetti.

La lista completa di tutti gli oggetti disponibili è [qui](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| nome                                                                                                                          | descrizione                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | La forma più basilare di provider. Prende un valore e lo espone, qualunque sia il valore.                                                                               |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | AUn provider specifico per oggetti Listenable. ListenableProvider ascolterà l'oggetto e chiederà ai widget che dipendono da esso di ricostruirsi ogni volta che il listener viene chiamato. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | Una specifica di ListenableProvider per ChangeNotifier. Chiamerà automaticamente `ChangeNotifier.dispose` quando necessario.                                             |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Ascolta un ValueListenable e espone solo `ValueListenable.value`.                                                         |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Ascolta uno Stream e espone l'ultimo valore emesso.                                                                                                      |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Prende un `Future` e aggiorna i dipendenti quando il future si completa.                                                                                                    |

### La mia applicazione lancia un StackOverflowError perché ho troppi provider, cosa posso fare?

Se hai un numero molto grande di provider (150+), è possibile che alcuni dispositivi lancino un `StackOverflowError` perché finisci per costruire troppi widget contemporaneamente.

In questa situazione, hai alcune soluzioni:

- Se la tua applicazione ha una splash-screen, prova a montare i tuoi provider nel tempo anziché tutti in una volta.

  Potresti fare:

  ```dart
  MultiProvider(
    providers: [
      if (step1) ...[
        <lots of providers>,
      ],
      if (step2) ...[
        <some more providers>
      ]
    ],
  )
  ```

  dove, durante l'animazione della tua splash screen, potresti fare:

  ```dart
  bool step1 = false;
  bool step2 = false;
  @override
  initState() {
    super.initState();
    Future(() {
      setState(() => step1 = true);
      Future(() {
        setState(() => step2 = true);
      });
    });
  }
  ```

- Considera di non utilizzare `MultiProvider`.
  `MultiProvider` funziona aggiungendo un widget tra ogni provider. Non utilizzare `MultiProvider` può
  aumentare il limite prima che venga raggiunto un `StackOverflowError`.

## Sponsor

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html



