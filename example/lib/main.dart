import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class Counter with ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

class Translations with ChangeNotifier {
  String get title => 'Tapped ${_counter.count} times';

  Counter _counter;
  void registerCounter(Counter counter) {
    if (_counter != counter) {
      _counter?.removeListener(notifyListeners);
      _counter = counter..addListener(notifyListeners);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _counter?.removeListener(notifyListeners);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (_) => Counter()),
        ProxyProvider<Counter, Translations>.custom(
          builder: (context, counter, previous) {
            final model = previous ?? Translations();
            model.registerCounter(counter);
            return model;
          },
          providerBuilder: (_, value, child) =>
              ChangeNotifierProvider.value(notifier: value, child: child),
          dispose: (context, value) => value.dispose(),
        ),
      ],
      child: const MaterialApp(home: MyHomePage()),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Title()),
      body: const Center(child: CounterLabel()),
      floatingActionButton: const IncrementCounterButton(),
    );
  }
}

class IncrementCounterButton extends StatelessWidget {
  const IncrementCounterButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: Provider.of<Counter>(context).increment,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

class CounterLabel extends StatelessWidget {
  const CounterLabel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counter = Provider.of<Counter>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'You have pushed the button this many times:',
        ),
        Text(
          '${counter.count}',
          style: Theme.of(context).textTheme.display1,
        ),
      ],
    );
  }
}

class Title extends StatelessWidget {
  const Title({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(Provider.of<Translations>(context).title);
  }
}
