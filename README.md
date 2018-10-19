An helper to easily exposes a value using `InheritedWidget` without having to write one.

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
    return StatefulProvider(
      // we voluntary reuse the previous value
      valueBuilder: (Model old) =>  old ?? Model(),
      // child: ...,
    );
  }
}
```
