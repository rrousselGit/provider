import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EqualNotifier extends ChangeNotifier {
  @override
  bool operator ==(Object other) => other is _EqualNotifier;

  @override
  int get hashCode => 0;

  bool get isObserved => hasListeners;

  void emit() => notifyListeners();
}

void main() {
  testWidgets('replacing equal but distinct values retargets listeners',
      (tester) async {
    final first = _EqualNotifier();
    final second = _EqualNotifier();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    expect(first == second, isTrue);
    expect(identical(first, second), isFalse);

    var buildCount = 0;
    final consumer = Consumer<_EqualNotifier>(
      builder: (context, value, child) {
        buildCount++;
        return const SizedBox();
      },
    );

    Widget provider(_EqualNotifier notifier) =>
        ListenableProvider<_EqualNotifier>.value(
          value: notifier,
          child: consumer,
        );

    await tester.pumpWidget(provider(first));
    expect(first.isObserved, isTrue);
    expect(second.isObserved, isFalse);

    await tester.pumpWidget(provider(second));
    expect(first.isObserved, isFalse);
    expect(second.isObserved, isTrue);

    final beforeNotification = buildCount;
    first.emit();
    await tester.pump();
    expect(buildCount, beforeNotification);

    second.emit();
    await tester.pump();
    expect(buildCount, greaterThan(beforeNotification));
  });
}
