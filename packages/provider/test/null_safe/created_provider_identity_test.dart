import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EqualNotifier extends ChangeNotifier {
  _EqualNotifier(this.label);

  final String label;
  bool wasDisposed = false;
  int disposalCount = 0;
  int removalCount = 0;

  bool get isObserved => hasListeners;

  void sendNotification() => notifyListeners();

  @override
  void removeListener(VoidCallback listener) {
    removalCount++;
    super.removeListener(listener);
  }

  @override
  void dispose() {
    disposalCount++;
    wasDisposed = true;
    super.dispose();
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is _EqualNotifier;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 0;
}

void main() {
  testWidgets('replacing equal created values transfers listener and disposal',
      (tester) async {
    final first = _EqualNotifier('first');
    final second = _EqualNotifier('second');
    var current = first;

    Widget build() => InheritedProvider<_EqualNotifier>(
          create: (_) => first,
          update: (_, previous) => current,
          startListening: (element, notifier) {
            notifier.addListener(element.markNeedsNotifyDependents);
            return () =>
                notifier.removeListener(element.markNeedsNotifyDependents);
          },
          dispose: (_, notifier) => notifier.dispose(),
          child: Consumer<_EqualNotifier>(
            builder: (context, notifier, _) => Text(
              notifier.label,
              textDirection: TextDirection.ltr,
            ),
          ),
        );

    await tester.pumpWidget(build());
    expect(first.isObserved, isTrue);
    expect(find.text('first'), findsOneWidget);

    current = second;
    await tester.pumpWidget(build());
    expect(first.wasDisposed, isTrue);
    expect(first.removalCount, 1);
    expect(first.disposalCount, 1);
    expect(second.removalCount, 0);
    expect(second.isObserved, isTrue);

    second.sendNotification();
    await tester.pump();
    expect(find.text('second'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(second.wasDisposed, isTrue);
    expect(first.removalCount, 1);
    expect(first.disposalCount, 1);
    expect(second.removalCount, 1);
    expect(second.disposalCount, 1);
  });

  testWidgets('notify-only updates must not dispose an unchanged instance',
      (tester) async {
    final notifier = _EqualNotifier('same');

    Widget build() => InheritedProvider<_EqualNotifier>(
          create: (_) => notifier,
          update: (_, previous) => notifier,
          updateShouldNotify: (_, __) => true,
          startListening: (element, current) {
            current.addListener(element.markNeedsNotifyDependents);
            return () =>
                current.removeListener(element.markNeedsNotifyDependents);
          },
          dispose: (_, current) => current.dispose(),
          child: Consumer<_EqualNotifier>(
            builder: (_, value, child) =>
                Text(value.label, textDirection: TextDirection.ltr),
          ),
        );

    await tester.pumpWidget(build());
    expect(notifier.isObserved, isTrue);
    expect(notifier.wasDisposed, isFalse);

    await tester.pumpWidget(build());
    expect(notifier.wasDisposed, isFalse);
    expect(notifier.isObserved, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(notifier.wasDisposed, isTrue);
    expect(notifier.disposalCount, 1);
    expect(notifier.removalCount, 2);
  });

  testWidgets('suppressed notification still releases replaced resources',
      (tester) async {
    final first = _EqualNotifier('first');
    final second = _EqualNotifier('second');
    var current = first;
    var builds = 0;
    _EqualNotifier? visible;
    final consumer = Consumer<_EqualNotifier>(
      builder: (_, value, __) {
        builds++;
        visible = value;
        return const SizedBox();
      },
    );
    Widget build() => InheritedProvider<_EqualNotifier>(
          update: (_, previous) => current,
          updateShouldNotify: (_, __) => false,
          startListening: (element, notifier) {
            notifier.addListener(element.markNeedsNotifyDependents);
            return () =>
                notifier.removeListener(element.markNeedsNotifyDependents);
          },
          dispose: (_, notifier) => notifier.dispose(),
          child: consumer,
        );

    await tester.pumpWidget(build());
    current = second;
    await tester.pumpWidget(build());
    expect(builds, 1);
    expect(identical(visible, first), isTrue);
    expect(first.disposalCount, 1);
    expect(first.removalCount, 1);
    expect(second.isObserved, isTrue);

    second.sendNotification();
    await tester.pump();
    expect(identical(visible, second), isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(first.disposalCount, 1);
    expect(second.disposalCount, 1);
    expect(second.removalCount, 1);
  });
}
