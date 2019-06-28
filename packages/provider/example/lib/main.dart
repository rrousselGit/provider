// ignore_for_file: public_member_api_docs
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class Counter with ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count += 100;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (_) => Counter()),
        Consumer<Counter>(
          builder: (context, counter, child) => AnimatedProvider<int>.value(
                value: counter.count,
                duration: Duration(seconds: 2),
                interpolate: (from, to, _) => IntTween(begin: from, end: to),
                child: child,
              ),
        ),
        ProxyProvider<int, double>(builder: (_, count, __) => count / 100)
      ],
      child: Consumer<int>(
        builder: (context, value, _) {
          return MaterialApp(
            supportedLocales: const [Locale('en')],
            localizationsDelegates: [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
              _ExampleLocalizationsDelegate(value),
            ],
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}

class ExampleLocalizations {
  static ExampleLocalizations of(BuildContext context) =>
      Localizations.of<ExampleLocalizations>(context, ExampleLocalizations);

  const ExampleLocalizations(this._count);

  final int _count;

  String get title => 'Tapped $_count times';
}

class _ExampleLocalizationsDelegate
    extends LocalizationsDelegate<ExampleLocalizations> {
  const _ExampleLocalizationsDelegate(this.count);

  final int count;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<ExampleLocalizations> load(Locale locale) =>
      SynchronousFuture(ExampleLocalizations(count));

  @override
  bool shouldReload(_ExampleLocalizationsDelegate old) => old.count != count;
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
      onPressed: () {
        // `listen: false` is specified here because otherwise
        // that would make `IncrementCounterButton` rebuild when the counter updates.
        Provider.of<Counter>(context, listen: false).increment();
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

class CounterLabel extends StatelessWidget {
  const CounterLabel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = Provider.of<int>(context);
    final half = Provider.of<double>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'You have pushed the button this many times:',
        ),
        Text('$count', style: Theme.of(context).textTheme.display1),
        Text('$half', style: Theme.of(context).textTheme.display1),
      ],
    );
  }
}

class Title extends StatelessWidget {
  const Title({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(ExampleLocalizations.of(context).title);
  }
}
