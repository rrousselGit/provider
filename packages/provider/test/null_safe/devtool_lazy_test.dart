import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('DevTools inspection preserves lazy provider creation', (
    tester,
  ) async {
    var createCalls = 0;
    final key = GlobalKey();

    await tester.pumpWidget(
      Provider<int>(
        create: (_) {
          createCalls++;
          return 42;
        },
        child: Container(key: key),
      ),
    );

    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isFalse);
    expect(node.value, isNull);
    expect(createCalls, 0);

    expect(key.currentContext!.read<int>(), 42);
    expect(createCalls, 1);
    expect(node.isInitialized, isTrue);
    expect(node.value, 42);
  });

  testWidgets('DevTools distinguishes an initialized null value', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<int?>.value(value: null, child: Container()),
    );

    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isTrue);
    expect(node.value, isNull);
  });
}
