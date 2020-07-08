import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ReassembleHandler extends ReassembleHandler {
  bool hasReassemble = false;

  @override
  void reassemble() {
    hasReassemble = true;
  }
}

void main() {
  testWidgets('ReassembleHandler', (tester) async {
    final provider = _ReassembleHandler();

    await tester.pumpWidget(
      Provider.value(
        value: provider,
        child: const SizedBox(),
      ),
    );

    // ignore: unawaited_futures
    tester.binding.reassembleApplication();

    await tester.pump();

    expect(provider.hasReassemble, equals(true));
  });
}
