import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('assets', () {
    expect(() => StatefulProvider(), throwsAssertionError);
    expect(() => StatefulProvider(didChangeDependencies: (_, __) => null),
        isNot(throwsAssertionError));
    expect(() => StatefulProvider(valueBuilder: (_, __) => null),
        isNot(throwsAssertionError));
    expect(
        () => StatefulProvider(
              valueBuilder: (_, __) => null,
              didChangeDependencies: (_, __) => null,
            ),
        isNot(throwsAssertionError));
  });

  testWidgets('simple usage', (tester) async {
    int buildCount = 0;
    int previous;
    int value;
    BuildContext context;

    final valueBuilder = (BuildContext c, int p) {
      previous = p;
      context = c;
      return ++buildCount;
    };

    final builder = Builder(
      builder: (context) {
        value = Provider.of(context);
        return Container();
      },
    );

    await tester.pumpWidget(
      StatefulProvider<int>(
        valueBuilder: valueBuilder,
        child: builder,
      ),
    );

    final element = tester.element(find.byElementType(StatefulElement).first);

    expect(buildCount, equals(1));
    expect(previous, isNull);
    expect(value, equals(1));
    expect(element, equals(context));

    await tester.pumpWidget(
      StatefulProvider<int>(
        valueBuilder: valueBuilder,
        child: builder,
      ),
    );

    expect(buildCount, equals(2));
    expect(previous, equals(1));
    expect(value, equals(2));

    // pump different widget to trigger dispose mecanism
    // no `onDispose` has been provided: should handle null
    await tester.pumpWidget(Container());
  });

  testWidgets('didChangeDependencies', (tester) async {
    int dependenciesCount = 0;
    BuildContext context;
    int value;
    int previous;

    final dependencies = (BuildContext c, int v) {
      context = c;
      dependenciesCount++;
      previous = v;
      value = Provider.of<double>(context).toInt();
      return value;
    };

    await tester.pumpWidget(
      Provider<double>(
        value: 42.0,
        child: StatefulProvider<int>(
          didChangeDependencies: dependencies,
          child: Container(),
        ),
      ),
    );

    final element = tester.element(find.byElementType(StatefulElement).first);

    expect(dependenciesCount, equals(1));
    expect(previous, isNull);
    expect(value, equals(42));
    expect(context, equals(element));

    await tester.pumpWidget(
      Provider<double>(
        value: 43.0,
        child: StatefulProvider<int>(
          didChangeDependencies: dependencies,
          child: Container(),
        ),
      ),
    );

    expect(dependenciesCount, equals(2));
    expect(previous, equals(42));
    expect(value, equals(43));
    expect(context, equals(element));
  });

  testWidgets('dispose', (tester) async {
    int disposeCount = 0;
    int value;
    BuildContext context;

    final dispose = (BuildContext c, int v) {
      context = c;
      disposeCount++;
      value = v;
    };

    final valueBuilder = (BuildContext context, int previous) => 42;

    await tester.pumpWidget(
      StatefulProvider<int>(
        valueBuilder: valueBuilder,
        onDispose: dispose,
        child: Container(),
      ),
    );

    final element = tester.element(find.byElementType(StatefulElement).first);

    await tester.pump();
    // pump different widget to trigger dispose mecanism
    await tester.pumpWidget(Container());

    expect(disposeCount, equals(1));
    expect(value, equals(42));
    expect(context, equals(element));
  });
}
