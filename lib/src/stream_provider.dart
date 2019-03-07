import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

class StreamProvider<T> extends StatelessWidget {
  const StreamProvider({
    Key key,
    this.initialData,
    this.stream,
    this.child,
    this.orElse,
    this.updateShouldNotify,
  }) : super(key: key);

  final T initialData;
  final Stream<T> stream;
  final Widget child;
  final ErrorBuilder<T> orElse;
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (_, snapshot) {
        return Provider<T>(
          value: orElse != null
            ? (snapshot.hasError ? orElse(context, snapshot.error) : snapshot.data)
            : snapshot.requireData,
          child: child,
          updateShouldNotify: updateShouldNotify,
        );
      },
    );
  }
}
