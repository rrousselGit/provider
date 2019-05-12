import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Bloc {
  final StreamController<int> _streamController = StreamController();
  Stream<int> stream;

  Bloc() {
    stream = _streamController.stream.asBroadcastStream();
  }

  void dispose() {
    _streamController.close();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<Bloc>(
      builder: (_) => Bloc(),
      dispose: (_, value) => value.dispose(),
      child: MaterialApp(
        home: Example(),
      ),
    );
  }
}

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLoC example')),
      body: Center(
        child: StreamBuilder<int>(
          stream: Provider.of<Bloc>(context).stream,
          builder: (context, snapshot) {
            return Text(snapshot.data?.toString() ?? 'Foo');
          },
        ),
      ),
    );
  }
}
