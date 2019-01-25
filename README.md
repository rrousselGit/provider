[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)

[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dartlang.org/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider)

An helper to easily exposes a value using `InheritedWidget` without having to write one.

This is especially useful with patterns such as BLoC or when storing our state inside `InheritedWidget`.
As having to manually write a `StatefulWidget` AND an `InheritedWidget` can be tedious.

## Usage

`Provider` usage:

```dart
import 'package:provider/provider.dart';

main() {
  runApp(
    Provider(
      value: 42,
      child: Builder(
        builder: (context) => {
          // explicitly pass the generic type
          final value = Provider.of<int>(context);

          // type inference works too:
          int value2;
          value2 = Provider.of(context);

          // do something with it
        }
      )
    )
  );
}
```

`StatefulProvider` usage

```dart
class Model {}

class Stateless extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulProvider<Model>(
      // we voluntary reuse the previous value
      valueBuilder: (_, old) =>  old ?? Model(),
      // child: ...,
    );
  }
}
```
