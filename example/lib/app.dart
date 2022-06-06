import 'package:jaspr/jaspr.dart';
import 'package:jaspr_provider/jaspr_provider.dart';

class App extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield ChangeNotifierProvider(
      create: (_) => Counter(),
      child: const MyApp(),
    );
  }
}

class Counter extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class MyApp extends StatelessComponent {
  const MyApp({Key? key}) : super(key: key);

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield const MyHomePage();
  }
}

class MyHomePage extends StatelessComponent {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield const Text('Example', rawHtml: true);
    yield const Text('You have pushed the button this many times:', rawHtml: true);
    yield Count();
    yield DomComponent(
      tag: 'button',
      events: {
        'click': (dynamic e) {
          context.read<Counter>().increment();
        },
      },
      child: DomComponent(tag: 'Press'),
    );
  }
}

class Count extends StatelessComponent {
  const Count({Key? key}) : super(key: key);

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield Text(
      /// Calls `context.watch` to make [Count] rebuild when [Counter] changes.
      '${context.watch<Counter>().count}',
      key: const Key('counterState'), rawHtml: true,
    );
  }
}
