import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EqualSource {
  _EqualSource(this.current);

  int current;
  void Function(int)? _listener;

  bool get isSubscribed => _listener != null;

  void subscribe(void Function(int) listener) {
    _listener = listener;
  }

  void unsubscribe() {
    _listener = null;
  }

  void send(int value) {
    current = value;
    _listener?.call(value);
  }

  @override
  bool operator ==(Object other) => other is _EqualSource;

  @override
  int get hashCode => 0;
}

void main() {
  testWidgets('equal deferred controllers must switch their subscriptions', (
    tester,
  ) async {
    final first = _EqualSource(0);
    final second = _EqualSource(1);

    final consumer = Builder(
      builder: (context) => Text(
        '${context.watch<int>()}',
        textDirection: TextDirection.ltr,
      ),
    );

    Widget provider(_EqualSource source) =>
        DeferredInheritedProvider<_EqualSource, int>.value(
          value: source,
          startListening: (element, setState, controller, previous) {
            setState(previous ?? controller.current);
            controller.subscribe(setState);
            return controller.unsubscribe;
          },
          child: consumer,
        );

    await tester.pumpWidget(provider(first));
    expect(first.isSubscribed, isTrue);
    expect(find.text('0'), findsOneWidget);

    first.send(5);
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    await tester.pumpWidget(provider(second));
    expect(first.isSubscribed, isFalse);
    expect(second.isSubscribed, isTrue);
    expect(find.text('5'), findsOneWidget);

    first.send(6);
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    second.send(7);
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });
}
