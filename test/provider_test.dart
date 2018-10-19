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
      Provider<double>(
        value: 24.0,
        child: Provider<int>(
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
      Provider<double>(
        value: 24.0,
        child: Provider<int>(
          value: 42,
          child: builder,
        ),
      ),
    );
    // didn't rebuild
    expect(buildCount, equals(1));

    // changed a value we are subscribed to
    await tester.pumpWidget(
      Provider<double>(
        value: 24.0,
        child: Provider<int>(
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
      Provider<double>(
        value: 20.0,
        child: Provider<int>(
          value: 43,
          child: builder,
        ),
      ),
    );
    // didn't get rebuilt
    expect(buildCount, equals(2));
  });
}
