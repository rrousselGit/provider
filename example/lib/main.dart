// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This is a reimplementation of the default Flutter application using provider + [ChangeNotifier].

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Counter()),
      ],
      child: const MyApp(),
    ),
  );
}

class Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  final complex = ComplexObject();

  void increment() {
    _count++;
    notifyListeners();
  }

  @override
  // ignore: hash_and_equals, overriding the hashcode for testing purposes
  int get hashCode => 42;
}

enum Enum { a, b }

final _token = Object();

class ComplexObject {
  Enum enumeration = Enum.a;
  Null nill;
  bool boolean = false;
  int integer = 0;
  double float = .42;
  String string = 'hello world';
  Type type = Counter;
  Object plainInstance = const _SubObject('hello world');

  var map = <Object, Object>{
    'list': [42],
    'string': 'string',
    42: 'number_key',
    true: 'number_key',
    null: null,
    const _SubObject('complex-key'): const _SubObject('complex-value'),
    _token: 'non-constant key',
    'nested_map': <Object, Object>{
      'key': 'value',
    }
  };

  var list = <Object>[
    42,
    'string',
    <Object>[],
    <Object, Object>{},
    const _SubObject('complex-value'),
    null,
  ];

  @override
  // ignore: hash_and_equals, overriding the hashcode for testing purposes
  int get hashCode => 21;
}

class _SubObject {
  const _SubObject(this.value);
  final String value;
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text('You have pushed the button this many times:'),

            /// Extracted as a separate widget for performance optimization.
            /// As a separate widget, it will rebuild independently from [MyHomePage].
            ///
            /// This is totally optional (and rarely needed).
            /// Similarly, we could also use [Consumer] or [Selector].
            Count(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('increment_floatingActionButton'),

        /// Calls `context.read` instead of `context.watch` so that it does not rebuild
        /// when [Counter] changes.
        onPressed: () => context.read<Counter>().increment(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Count extends StatelessWidget {
  const Count({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      /// Calls `context.watch` to make [Count] rebuild when [Counter] changes.
      '${context.watch<Counter>().count}',
      key: const Key('counterState'),
      style: Theme.of(context).textTheme.headline4,
    );
  }
}
