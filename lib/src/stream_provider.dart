import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

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
  final T Function(Object error) orElse;
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        T value = orElse != null
            ? (snapshot.hasError ? orElse(snapshot.error) : snapshot.data)
            : snapshot.requireData;
        return Provider<T>(
          value: value,
          child: child,
          updateShouldNotify: updateShouldNotify,
        );
      },
    );
  }
}
