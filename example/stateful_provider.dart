import 'dart:async';

import 'package:flutter/widgets.dart';
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

  void dipose() {
    _streamController.close();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulProvider<Bloc>(
      valueBuilder: (_) => Bloc(),
      onDispose: (_, value) => value.dipose(),
      child: Example(),
    );
  }
}

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Provider.of<Bloc>(context).stream,
      builder: (context, snapshot) {
        return Text(snapshot.data.toString() ?? 'Foo');
      },
    );
  }
}
