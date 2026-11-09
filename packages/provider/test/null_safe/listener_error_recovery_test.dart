import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> expectNotificationsAfterSubscriptionRetry(
  WidgetTester tester,
  Widget Function(Widget child) wrap,
  InheritedContext<int?>? Function() subscribedContext,
) async {
  var buildCount = 0;

  await tester.pumpWidget(
    wrap(
      Builder(
        builder: (context) {
          buildCount++;
          if (buildCount == 1) {
            expect(() => context.watch<int>(), throwsA(isA<StateError>()));
          } else {
            expect(context.watch<int>(), 1);
          }
          return const SizedBox();
        },
      ),
    ),
  );
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
          subscribedContext = element;
          if (attempts++ == 0) {
            throw StateError('transient failure');
          }
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
          subscribedContext = element;
          if (attempts++ == 0) {
            throw StateError('transient failure');
          }
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
          subscribedContext = element;
          if (attempts++ == 0) {
            throw StateError('transient failure');
          }
          return () {};
        },
        child: child,
      ),
      () => subscribedContext,
    );
  });
}
