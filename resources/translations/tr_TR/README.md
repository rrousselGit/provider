[English](https://github.com/rrousselGit/provider/blob/master/packages/provider/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](https://github.com/rrousselGit/provider/blob/master/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md) | [Turkish](https://github.com/rrousselGit/provider/blob/master/resources/translations/tr_TR/README.md) | [Italian](https://github.com/rrousselGit/provider/blob/master/resources/translations/it_IT/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) <a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

[InheritedWidget]'ı sarmalayarak kullanımını kolaylaştırır ve 
daha fazla yeniden kullanılabilir hale getirir.

Elle [InheritedWidget] yazmak yerine `provider` kullanarak şunları elde edersiniz:

- kaynakların(resources) basitleştirilmiş tahsisi/tasfiyesi
- lazy-load eklentisini
- her seferinde yeni bir sınıf oluşturmaya kıyasla büyük ölçüde azaltılmış bir boilerplate
- devtool dostu - Provider kullanarak, uygulamanızın durumu Flutter devtool'da görünür olacaktır
- [InheritedWidget]ları kullanmanın daha esnek bir yolu olarak yeni widgetlar(Bkz. [Provider.of]/[Consumer]/[Selector])
- katlanarak büyüyen bir dinleme mekanizmasına sahip sınıflar için artırılmış ölçeklenebilirlik
  karmaşıklıktadır (bildirim gönderimi için O(N) olan [ChangeNotifier] gibi).

`provider` hakkında daha detaylı bilgi için, dokümanı inceleyebilirsiniz [documentation](https://pub.dev/documentation/provider/latest/provider/provider-library.html).

Ayrıca: 

- [Resmi Flutter state management belgeleri](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), `provider` + [ChangeNotifier]'ın nasıl kullanılacağını göstermektedir.
- `provider` + [ChangeNotifier] kullanılarak geliştirilmiş bir uygulama örneği [Flutter state management mimarisi örneği](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider)
- State management mimarilerinde bir `provider` kullanan [flutter_bloc](https://github.com/felangel/bloc) ve [Mobx](https://github.com/mobxjs/mobx.dart)

## 4.x.x'den 5.0.0-nullsafety'ye geçiş

- Hem `FutureProvider` hem de `StreamProvider` için `initialData` artık gerekli.

  Geçiş işlemleri için:

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

  yenilenmiş hali:

  ```dart
  FutureProvider<int?>(
    initialValue: null,
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    // ? ile işaretlendiğine emin ol watch<int?>
    final value = context.watch<int?>();
    return Text('$value');
  }
  ```

- `ValueListenableProvider` kaldırıldı

  Geçiş yapmak için bunun yerine `ValueListenableBuilder` ile birlikte `Provider` kullanabilirsiniz:

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

## Kullanım

### Bir değeri expose etme

#### Yeni bir obje örneğini expose etme

Provider'lar yalnızca bir değeri expose etmenizi değil, aynı zamanda onu oluşturmanıza, dinlemenize ve atmanıza da olanak tanır.

Yeni oluşturulmuş bir objeyi expose etmek için, bir providerın varsayılan constructer'ını kullanın.
Bir nesneyi **create** etmek istiyorsanız `.value` yapıcısını kullanmayın
aksi takdirde istenmeyen yan etkiler oluşacaktır.

Bakınız [StackOverflow yanıtı](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
Bu da değer oluşturmak için `.value` constructor'ı kullanılmasının neden istenmediğini açıklıyor.

- **Yapmanız Gereken** `create` methodunun altında yeni bir obje oluşturmak.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **Yapmayın!** `Provider.value` ile obje oluşturmak.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **Yapmayın!** objenizi zaman içerisinde değişebilecek değişkenler üzerine kurmak.

  Böyle bir durumda, oluşturduğunuz obje değiştiğinde veriler asla
  update edilmeyecektir.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

Eğer atadığınız obje zaman içerisinde değişecekse,
`ProxyProvider` kullanmayı tercih edin:

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**DIPNOT**:

Provider'ın sağladığı `create`/`update` callback methodlarını kullanırken, kullandığınız bu callbacklerin
default olarak lazily tanımlamasına uyduğunu unutmayın.

Bu şu anlama geliyor, `create`/`update` methodları en az bir kez çağırılana kadar asla dinlenmeyecekler.

Bu durumu değiştirerek, veriler üzerinde işlem yapmak isterseniz, `lazy` parametresini kullanabilirsiniz.

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### Mevcut bir object instance'ını yeniden kullanma:

Zaten halihazırda bir obje instance'ına sahipseniz ve onu tekrar kullanmak istiyorsanız, `.value` constructor'ı aradığınız şey olacaktır.

Yanlış kullanıldığı durumda, zaten kullanımda olan objeniz için `dispose` method'ı devreye girebilir.

- **Yapmanız Gereken** [ChangeNotifier] içerisinde bulunan veriyi
  `ChangeNotifierProvider.value` ile çağırın.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **Yapmayın!** [ChangeNotifier] ile halihazırda çağırılmış veriyi kullanmak.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Veri dinleme işlemleri

Bir veriyi dinlemenin en basit yolu [BuildContext] üzerinde bulunan extension methodları aracılığı ile veriye erişmektir.

- `context.watch<T>()`, `T` üzerindeki widget değişimleri dinler.
- `context.read<T>()`, `T` okuması yapar fakat dinleme işlemi yapmaz.
- `context.select<T, R>(R cb(T value))`, `T` verisinin sadece belli bir kısmı için dinleme işlemi yapar.

Benzer şekilde davranacak olan `Provider.of<T>(context)` static methodu da dinleme işlemi için
kullanılabilir. `listen` parametresi `false` olarak belirlendiğinde (`Provider.of<T>(context, listen: false)` 'da olduğu gibi), aynı
`read` işlemi yaptığımız durumdaki gibi davranacaktır.

`context.read<T>()` işleminin widget rebuild işlemini triggerlamayacak olduğunu not 
ediniz. ayrıca `StatelessWidget.build`/`State.build` içerisinde de çağırılamaz.
Fakat, bu methodların dışında istenilen şekilde kullanılabilir.

Bu methodların her biri ilişkili olduğu widget ağacının başlangıcında bulunan 
`BuildContext` methoduna dönecek ve en yakın `T` verisi ile eşlenecektir.
(eğer eşlenecek bir veri bulamazsa boşa düşecek).

Bu işlem bir O(1) işlemi gibidir. Widgetın bulunduğu ağaçta bir şey içermez.

İlk örnekle birleştirdiğmiz durumda [veri dinleme işlemleri](#bir_değeri_expose_etme), `String` verisi expose edilerek okunacak ve "Hello World" render edilecektir.

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // "watch" işlemi ile elde etmek istediğiniz objenin tipini belirtmeyi unutmayın!
      context.watch<String>(),
    );
  }
}
```

Alternatif olarak, bu yöntemleri kullanmak yerine, [Consumer] veya [Selector] kullanılabilir.

Bu yöntemler performans açısından yararlı olabilir, ayrıca `BuildContext` elde etmek
zor olduğunda da kullanılabilir.

Ayrıca daha fazla bilgi [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do), [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)  dokümanı ve [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) dokümanına bakabilirsiniz.

### Provider'ın opsiyonel olduğu durumlar

Bazen, providerın mevcut olmadığı durumları desteklemek isteyebiliriz. Örneğin, 
oluşturduğumuz bir widget projenin farklı noktalarında tekrar kullanılabilir, ve bu 
durum providerın dışında gerçekleşebilir.

Böyle durumlarda, `context.watch`/`context.read` yöntemini kullanarak, generic bir 
type'ı null olmaktan kurtarabiliriz. Öyle ki:

```dart
context.watch<Model>()
```

bu durum eğer matchlenebileceği bir provider bulamaz ise `ProviderNotFoundException`
 fırlatacaktır, fakat:

```dart
context.watch<Model?>()
```

match olabileceği bir provider arayacaktır. Eğer bulamazsa bu sefer `null` olarak 
dönecektir.

### MultiProvider

Büyük projelerde çok fazla değeri projeye entegre etmeniz gerektiğinde 
oluşturduğunuz `Provider`'ları iç içe kullanmak yerine:

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

Bu şekilde kullanın:

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

Aslında iki yöntem de aynı işlevi yerine getiriyor.`MultiProvider` yalnızca 
yazdığınız kodun okunabilirliğine katkı sağlıyor.

### ProxyProvider

3.0.0 sürümü ile birlikte, yeni bir provider türü eklendi: `ProxyProvider`.

`ProxyProvider` farklı provider verilerini birleştirerek yenilerini üretmenize olanak sağlayan bir `Provider` türü.

Yeni oluşturulan obje, providerlarınızdan herhangi birinde gerçekleşen bir update'i dinleyecek ve update oluşması durumunda otomatik olarak güncellenecek.

Aşağıdaki örnek `ProxyProvider` başka bir providerda oluşan counter dinlemesi ile objenin build edilmesini gösteriyor.

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

Birden fazla varyasonu destekliyor, örneğin:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  `ProxyProvider` için çalışma sırası üstünlüğü numaralandırıldığı konuma bağlı 
  olarak yönetilir.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Hepsi aynı şekilde çalışır, ancak bir `Provider`'a result yollamak yerine, 
  `ChangeNotifierProxyProvider` resultları `ChangeNotifierProvider`'a yollar.

### FAQ

#### Nesnelerin içeriğini nasıl inceleyebilirim?

Flutter anlık olarak widget bilgilerini görebileceğiniz [devtool](https://github.com/flutter/devtools) ile gelir.

Providerlar temelde birer widget oldukları için, devtool üzerinde onları da inceleyebilirsiniz.

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

Görselde providera tıklarsanız, expose edilen valueları görebilirsiniz.

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(devtool'da alınan screenshotlar `example` klasörünü kullanmakta)

#### Devtool sadece "Instance of MyClass" gösteriyor. Ne yapmalıyım?

Buna sebep olan durum, devtool'un default olarak `toString` kullanması ve "Instance of MyClass" dönmesidir.

Daha faydalı olması açısından, iki çözüm bulunur:

- Flutter tarafından sağlanan [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) API kullanın. 

  Bir çok senaryo için, objeler için [DiagnosticableTreeMixin], ve custom bir şekilde entegre edilmiş [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html) sorunu çözebilir.

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

- `toString` methodunu geçersiz kılın.

  [DiagnosticableTreeMixin]'ı (class içerisindeki bir package sorun çıkartıyorsa)
  kullanamıyorsanız, `toString`'i methodunu geçersiz kılmayı deneyebilirsiniz.

  Bu yöntem [DiagnosticableTreeMixin] kullanmaktan daha basittir fakat daha 
  güçsüzdür. Bu yöntemle objeleri detay açısından expand/collapse yapamazsınız.

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

#### `initState` içerisinde providerlara ulaşmakta sorun yaşıyorum. Ne yapmalıyım?

Bu hatanın oluşmasının sebebi bir providerı life-cycle açısından bir daha 
kullanılmayacak bir method içerisinde dinlemeye çalışmanızdan dolayıdır.

Bu durumda ya başka bir life-cycle (`build`) methodu kullanın veya güncelleme 
durumlarını dinlemekten vazgeçin.

Örneğin, bunun yerine:

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

bunu kullanabilirsiniz:

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

bu şekilde `value` değiştiğinde terminale çıktı alacaksınız.(sadece değiştiğinde)

Alternatif olarak, bunu kullanabilirsiniz:

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

Bu yöntem `value` bir kez print edecek ve sonraki _updateleri görmezden gelecektir._

#### Objelerimi nasıl hot-reload edebilirim?

Provide edilmiş objenin entegre edilmesini `ReassembleHandler` yapın:

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

Sonrasında ise tipik `provider` yapısını kullanın.

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### [ChangeNotifier] kullanıyorum, veri update ettiğimde hata alıyorum. Bu neden oluyor?

Bu genellikle [ChangeNotifier]'ın içerdiği öğelerin çağırıldığı widget ağacının build edildiği sırada değiştirilmesinden dolayı olur.

Yaygın bir senaryo olarak ele alırsak, notifier içerisinde store edilmiş bir future'ı başlattığınız sırada oluşması beklenebilir:

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

Bu yöntemin kullanılamamasının sebebi state update durumunun senkron bir işlem olmasıdır.

Bu şu anlama geliyor. Bazı widgetlar mutasyon _öncesinde_ build edilir. (önceki değeri alır), bazı widgetlar _sonrasında_ build edilir (yeni değeri alır). Bu durum kullanıcı arayüzünde beklenmeyen problemler yaratabileceği için kullanımına izin verilmez.

Bunun yerine, bu mutasyonu tüm widget ağacını eşit şekilde etkileyebilecek şekilde
yapınız:

- direkt olarak modelinizin provider/constructor'ınızın bulunduğu `create` methodu içerisinde:

```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  Bu yöntem "ekstra parametlerin" olmadığı durumlarda faydalı olabilir.

- frame sonunda asenkron bir şekilde:
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>().fetchSomething(someValue);
    );
  }
  ```
  Bu çok ideal bir yöntem değildir, ama parametreleri mutasyon içerisinde kullanabilmenizi sağlar.

#### [ChangeNotifier]'ı complex state durumlarında kullanmalı mıyım?

Hayır.

Bu durumda nesneleri state olarak tanımlayabilirsiniz. Örneğin, farklı bir yapı 
olarak `Provider.value()` ve `StatefulWidget` kombinasyonunu kullanabilirsiniz.

Burada bir sayaç örneği bulabilirsiniz:

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

state'i dinlemek için:

```dart
return Text(context.watch<int>().toString());
```

state üzerinde işlem yapmak için:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

Alternatif olarak kendi provider yapınızı da kurabilirsiniz.

#### Kendi Provider'ımı oluşturabilir miyim?

Evet. `provider` aslında tüm küçük componentleri kullanarak hazırlanmış bir tam kapsayıcı providerdır diyebiliriz.

Neleri içerir: 

- `MultiProvider` ile çalışması için `SingleChildStatelessWidget` widgetları kurmak.
  Bu burada bulunan yapıyı kullanır `package:provider/single_child_widget`

- `context.watch` işlemi yaparak klasik `InheritedWidget` elde etmenizi sağlayan [InheritedProvider].

Burada `ValueNotifier`'ı state olarak kullanan bir örnek bulabilirsiniz:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### Widgetlarım çok sık rebuild oluyor. Ne yapmalıyım?

`context.watch` kullanmak yerine, dinleme işlemlerini daha spesifik ve belirli objeler üzerinde yapmak için `context.select` kullanabilirsiniz.

Örneğin, yazma işlemi yaparken:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

Bu işlem `name` değeri dışında bir değişiklik olursa da widgetın rebuild olmasına neden olacaktır.

Fakat, `name` dinleme işlemini `context.select` ile yapmak sadece onun dinlenmesini sağlayacaktır.

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

Bu yöntem sayesinde, `name` dışında başka değerlerde oluşan değişiklikler rebuild triggerlamayacaktır.

Benzer olarak, [Consumer]/[Selector] da kullanılabilir. Bu widgetlarda opsiyonel olarak sunulan `child` argumenti widget ağacının geri kalanı için rebuild işlemini azaltmak için kullanılabilir:

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

Bu örnekte, `A` update edildiğinde sadece`Bar` rebuild edilecektir. 
`Foo` ve `Baz` gereksiz şekilde rebuild olmayacaktır.

#### Aynı tip veri için iki farklı provider verisini kullanabilir miyim?

Hayır. Evet aynı anda farklı providerlar aracılığı ile veri paylaşımı yapabilirsiniz fakat böyle bir durumda widget en yakın olduğu veriyi kullanacaktır.

Bunun yerine, iki providera da daha belirgin tanımlamalar yapmak yardımcı olacaktır.

Örneğin, bu örnek yerine:

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

Bunu tercih edin:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### Arayüzü kullanarak bir entegrasyon oluşturabilir miyim ?

Evet, bir entegrasyon oluşturmak için `create` içerisinde bir implementasyon sağlanmalıdır.

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

### Mevcut providerlar

`provider` farklı obje tiplerdeki objeler için farklı "provider"lar sağlar.

Mevcut tüm obje listesi için [here](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| name                                                                                                                          | description                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | Provider'ın en basit hali. Bir değeri alır ve onu expose eder.                                                                               |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Dinlenebilir bir obje için spesifik bir provider türü. ListenableProvider objeyi dinlerken aynı zamanda widgetı rebuild edilmesi konusunda uyarma işlemlerini listener çağırıldığında tetikler.|
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | ListenableProvider'ın  ChangeNotifier için özelleştirilmiş hali. Otomatik olarak gerekli durumlarda `ChangeNotifier.dispose` çağırır.                                               |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | ValueListenable dinlemesi yaparak sadece `ValueListenable.value` değerini expose edin.                                                                                                   |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Bir stream'i dinler ve son entegre edilmiş değeri expose eder.                                                                                                                |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | `Future` alır ve bağımlılık durumunun tamamlanmasını kontrol eder.                                                                                                     |

### Application'ım StackOverflowError hatası veriyor çünkü çok fazla providera sahibim, ne yapmalıyım?

Çok fazla sayıda providera sahipseniz (150+), bazı cihazlarda `StackOverflowError` hatası almanız olasıdır. Bunun nedeni çok fazla sayıda providerın aynı anda rebuild edilmesidir.

Bu durumda yapabileceğiniz birkaç çözüm bulunmaktadır:

- Eğer application'ınınız bir splash-screen'e sahipse, tüm providerları aynı anda değil de zaman içerisinde mount etmeyi deneyin.

  Şu şekilde yapılabilir:

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

  splash screen animasyonunuz sırasında, bu çözümü de uygulayabilirsiniz:

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

- `MultiProvider` kullanmayı bırakmayı düşünebilirsiniz.
  `MultiProvider` her provider için bir widget ekler. `MultiProvider` kullanmamak 
  `StackOverflowError` hatasına ulaşmadan önceki limiti arttırabilir.

## Sponsorlar

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