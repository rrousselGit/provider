import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Bloc {
  StreamController<int> _streamController = StreamController();
  Stream<int> stream;

  Bloc() {
    stream = _streamController.stream.asBroadcastStream();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulProvider<Bloc>(
      valueBuilder: (old) => old ?? Bloc(),
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
        return Text(snapshot.data.toString() ?? "Foo");
      },
    );
  }
}
