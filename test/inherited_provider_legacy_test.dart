// Mixed mode: test is legacy, runtime is legacy, package:provider is null safe.
// @dart=2.11
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('allows nulls in mixed mode', (tester) async {
    // ignore: avoid_returning_null
    int initialValueBuilder(BuildContext _) => null;

    await tester.pumpWidget(
      InheritedProvider<int>(
        create: initialValueBuilder,
        child: const Context(),
      ),
    );

    // Prior to fix: first get initializes to null, second get throws
    // because of the null. After fix, the null counts as valid.
    expect(Provider.of<int>(context, listen: false), isNull);
    expect(Provider.of<int>(context, listen: false), isNull);
  });
}

BuildContext get context => find.byType(Context).evaluate().single;

class Context extends StatelessWidget {
  const Context({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
