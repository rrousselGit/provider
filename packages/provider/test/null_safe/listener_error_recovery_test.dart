import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> expectNotificationsAfterSubscriptionRetry(
  WidgetTester tester,
  Widget Function(Widget child) wrap,
  InheritedContext<int?>? Function() subscribedContext,
) async {
  final key = GlobalKey();
  var shouldWatch = false;
  var buildCount = 0;

  Widget createWidget() => wrap(
        Builder(
          key: key,
          builder: (context) {
            if (shouldWatch) {
              context.watch<int>();
              buildCount++;
            }
            return const SizedBox();
          },
        ),
      );

  await tester.pumpWidget(createWidget());

  expect(
    () => key.currentContext!.read<int>(),
    throwsA(isA<StateError>()),
  );
  expect(key.currentContext!.read<int>(), 1);

  shouldWatch = true;
  await tester.pumpWidget(createWidget());
  expect(buildCount, 1);

  subscribedContext()!.markNeedsNotifyDependents();
  await tester.pump();
  expect(buildCount, 2);
}

void main() {
  testWidgets('value provider recovers notifications after a listener error',
      (tester) async {
    var attempts = 0;
    InheritedContext<int?>? subscribedContext;

    await expectNotificationsAfterSubscriptionRetry(
      tester,
      (child) => InheritedProvider<int>.value(
        value: 1,
        startListening: (element, _) {
          if (attempts++ == 0) throw StateError('transient failure');
          subscribedContext = element;
          return () {};
        },
        child: child,
      ),
      () => subscribedContext,
    );
  });

  testWidgets('created provider recovers notifications after a listener error',
      (tester) async {
    var attempts = 0;
    InheritedContext<int?>? subscribedContext;

    await expectNotificationsAfterSubscriptionRetry(
      tester,
      (child) => InheritedProvider<int>(
        create: (_) => 1,
        startListening: (element, _) {
          if (attempts++ == 0) throw StateError('transient failure');
          subscribedContext = element;
          return () {};
        },
        child: child,
      ),
      () => subscribedContext,
    );
  });

  testWidgets('deferred provider recovers notifications after a listener error',
      (tester) async {
    var attempts = 0;
    InheritedContext<int?>? subscribedContext;

    await expectNotificationsAfterSubscriptionRetry(
      tester,
      (child) => DeferredInheritedProvider<int, int>.value(
        value: 1,
        startListening: (element, setState, controller, previous) {
          setState(controller);
          if (attempts++ == 0) throw StateError('transient failure');
          subscribedContext = element;
          return () {};
        },
        child: child,
      ),
      () => subscribedContext,
    );
  });
}
