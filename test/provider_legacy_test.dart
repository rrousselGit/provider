// Mixed mode: test is legacy, runtime is legacy, package:provider is null safe.
// @dart=2.11
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  // See `provider_test.dart` for corresponding sound mode test.
  testWidgets('falls back to Provider<T?> in unsound mode', (tester) async {
    double value;

    final builder = Builder(
      builder: (context) {
        // Look up a Provider<double>.
        value = Provider.of<double>(context, listen: false);
        return Container();
      },
    );

    await tester.pumpWidget(
      // Install a Provider<double?>.
      nullableProviderOfValue<double>(
        24,
        Provider<int>.value(
          value: 42,
          child: builder,
        ),
      ),
    );

    // Provider<double> not found, uses Provider<double?> instead.
    expect(value, equals(24.0));
  });
}
