import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('simple usage', (tester) async {
    int buildCount = 0;
    int value;
    double second;
    String missing;

    // We voluntarily reuse the builder instance so that later call to pumpWidget
    // don't call builder again unless subscribed to an inheritedWidget
    final builder = Builder(
      builder: (context) {
        buildCount++;
        value = Provider.of(context);
        missing = Provider.of(context);
        second = Provider.of(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      ModelProvider<double, int>(
        value: 24.0,
        child: ModelProvider<int, int>(
          value: 42,
          child: builder,
        ),
      ),
    );

    expect(value, equals(42));
    expect(second, equals(24.0));
    expect(missing, isNull);
    expect(buildCount, equals(1));

    // nothing changed
    await tester.pumpWidget(
      ModelProvider<double, int>(
        value: 24.0,
        child: ModelProvider<int, int>(
          value: 42,
          child: builder,
        ),
      ),
    );
    // didn't rebuild
    expect(buildCount, equals(1));

    // changed a value we are subscribed to
    await tester.pumpWidget(
      ModelProvider<double, int>(
        value: 24.0,
        child: ModelProvider<int, int>(
          value: 43,
          child: builder,
        ),
      ),
    );
    expect(value, equals(43));
    expect(second, equals(24.0));
    expect(missing, isNull);
    // got rebuilt
    expect(buildCount, equals(2));

    // changed a value we are _not_ subscribed to
    await tester.pumpWidget(
      ModelProvider<double, int>(
        value: 20.0,
        child: ModelProvider<int, int>(
          value: 43,
          child: builder,
        ),
      ),
    );
    // didn't get rebuilt
    expect(buildCount, equals(2));
  });

  testWidgets('update should notify', (tester) async {
    int old;
    int curr;
    int callCount = 0;
    final updateShouldNotify = (int o, int c) {
      callCount++;
      old = o;
      curr = c;
      return o != c;
    };

    int buildCount = 0;
    int buildValue;
    final builder = Builder(builder: (BuildContext context) {
      buildValue = Provider.of(context);
      buildCount++;
      return Container();
    });

    await tester.pumpWidget(
      ModelProvider<int, int>(
        value: 24,
        shouldNotify: updateShouldNotify,
        child: builder,
      ),
    );
    expect(callCount, equals(0));
    expect(buildCount, equals(1));
    expect(buildValue, equals(24));

    // value changed
    await tester.pumpWidget(
      ModelProvider<int, int>(
        value: 25,
        shouldNotify: updateShouldNotify,
        child: builder,
      ),
    );
    expect(callCount, equals(1));
    expect(old, equals(24));
    expect(curr, equals(25));
    expect(buildCount, equals(2));
    expect(buildValue, equals(25));

    // value didnt' change
    await tester.pumpWidget(
      ModelProvider<int, int>(
        value: 25,
        shouldNotify: updateShouldNotify,
        child: builder,
      ),
    );
    expect(callCount, equals(2));
    expect(old, equals(25));
    expect(curr, equals(25));
    expect(buildCount, equals(2));
  });

  testWidgets('tags', (tester) async {
    Object fooTag = "foo";
    Object barTag = "bar";

    await tester.pumpWidget(
      ModelProvider<int, int>(
        key: ValueKey(fooTag),
        value: 24,
        tag: fooTag,
        child: ModelProvider<int, int>(
          key: ValueKey(barTag),
          value: 42,
          tag: barTag,
          child: Container(),
        ),
      ),
    );

    final context = tester.element(find.byType(Container));

    expect(Provider.of<int>(context, tag: fooTag), equals(24));
    expect(Provider.of<int>(context, tag: barTag), equals(42));
    expect(Provider.of<int>(context), isNull);
    expect(
      () => Provider.of<String>(context, tag: barTag),
      throwsAssertionError,
    );

    expect(
      Provider.elementOf<int>(context, tag: fooTag),
      equals(tester.element(find.byKey(ValueKey(fooTag)))),
    );
    expect(
      Provider.elementOf<int>(context, tag: barTag),
      equals(tester.element(find.byKey(ValueKey(barTag)))),
    );
    expect(Provider.elementOf<int>(context), isNull);
    expect(
      () => Provider.elementOf<String>(context, tag: barTag),
      throwsAssertionError,
    );
  });
}
