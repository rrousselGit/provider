import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('simple usage', (tester) async {
    int buildCount = 0;
    int value;

    final valueBuilder = (int previous) {
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

    expect(buildCount, equals(1));
    expect(value, equals(1));

    await tester.pumpWidget(
      StatefulProvider<int>(
        valueBuilder: valueBuilder,
        child: builder,
      ),
    );

    expect(buildCount, equals(2));
    expect(value, equals(2));
  });
}
