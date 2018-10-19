An helper to easily exposes a value using `InheritedWidget` without having to write one.

## Usage

A simple usage example:

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
