import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EqualSource {
  _EqualSource(this.current);

  int current;
  void Function(int)? _listener;

  bool get isSubscribed => _listener != null;

  // ignore: use_setters_to_change_properties
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
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is _EqualSource;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 0;
}

void main() {
  for (final lazy in [true, false]) {
    testWidgets('replacement compares once lazy=$lazy', (tester) async {
      final first = _EqualSource(0);
      final second = _EqualSource(1);
      var comparisons = 0;
      var builds = 0;
      final consumer = Builder(builder: (context) {
        builds++;
        return Text('${context.watch<int>()}',
            textDirection: TextDirection.ltr);
      });
      Widget provider(_EqualSource source) =>
          DeferredInheritedProvider<_EqualSource, int>.value(
            value: source,
            lazy: lazy,
            updateShouldNotify: (_, __) => ++comparisons == 1,
            startListening: (_, setState, controller, previous) {
              setState(controller.current);
              controller.subscribe(setState);
              return controller.unsubscribe;
            },
            child: consumer,
          );

      await tester.pumpWidget(provider(first));
      await tester.pumpWidget(provider(second));
      expect(comparisons, 1);
      expect(builds, 2);
      expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'read after failed replacement updates retained consumer lazy=$lazy',
        (tester) async {
      final first = _EqualSource(0);
      final second = _EqualSource(1);
      var attempts = 0;
      BuildContext? readContext;
      final consumer = Builder(builder: (context) {
        readContext = context;
        return Text('${context.watch<int>()}',
            textDirection: TextDirection.ltr);
      });
      final previousErrorBuilder = ErrorWidget.builder;
      ErrorWidget.builder = (_) => consumer;
      addTearDown(() => ErrorWidget.builder = previousErrorBuilder);
      Widget provider(_EqualSource source) =>
          DeferredInheritedProvider<_EqualSource, int>.value(
            value: source,
            lazy: lazy,
            startListening: (_, setState, controller, previous) {
              setState(controller.current);
              if (identical(controller, second) && attempts++ == 0) {
                throw StateError('replacement failed');
              }
              controller.subscribe(setState);
              return controller.unsubscribe;
            },
            child: consumer,
          );

      await tester.pumpWidget(provider(first));
      await tester.pumpWidget(provider(second));
      expect(tester.takeException(), isA<StateError>());
      ErrorWidget.builder = previousErrorBuilder;
      expect(find.text('0'), findsOneWidget);
      expect(readContext!.read<int>(), 1);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(first.isSubscribed, isFalse);
      expect(second.isSubscribed, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(second.isSubscribed, isFalse);
    });

    testWidgets(
        'replacement subscription errors propagate and retry lazy=$lazy',
        (tester) async {
      final first = _EqualSource(0);
      final second = _EqualSource(1);
      final failure = StateError('subscription failed');
      var attempts = 0;
      var comparisons = 0;
      final consumer = Builder(
        builder: (context) =>
            Text('${context.watch<int>()}', textDirection: TextDirection.ltr),
      );
      Widget provider(_EqualSource source) =>
          DeferredInheritedProvider<_EqualSource, int>.value(
            value: source,
            lazy: lazy,
            updateShouldNotify: (previous, current) {
              comparisons++;
              return previous != current;
            },
            startListening: (_, setState, controller, previous) {
              if (identical(controller, second) && attempts++ == 0) {
                throw failure;
              }
              setState(controller.current);
              controller.subscribe(setState);
              return controller.unsubscribe;
            },
            child: consumer,
          );

      await tester.pumpWidget(provider(first));
      await tester.pumpWidget(provider(second));
      expect(identical(tester.takeException(), failure), isTrue);
      expect(first.isSubscribed, isFalse);
      expect(second.isSubscribed, isFalse);
      expect(comparisons, 0);

      await tester.pumpWidget(provider(second));
      expect(attempts, 2);
      expect(second.isSubscribed, isTrue);
      expect(find.text('1'), findsOneWidget);
      second.send(2);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(second.isSubscribed, isFalse);
    });

    for (final suppressNotification in [true, false]) {
      testWidgets(
          'synchronous replacement lazy=$lazy suppress=$suppressNotification',
          (tester) async {
        final first = _EqualSource(0);
        final second = _EqualSource(1);
        var builds = 0;
        final consumer = Builder(builder: (context) {
          builds++;
          return Text('${context.watch<int>()}',
              textDirection: TextDirection.ltr);
        });
        Widget provider(_EqualSource source) =>
            DeferredInheritedProvider<_EqualSource, int>.value(
              value: source,
              lazy: lazy,
              updateShouldNotify:
                  suppressNotification ? (_, __) => false : null,
              startListening: (_, setState, controller, previous) {
                setState(controller.current);
                controller.subscribe(setState);
                return controller.unsubscribe;
              },
              child: consumer,
            );

        await tester.pumpWidget(provider(first));
        await tester.pumpWidget(provider(second));
        expect(first.isSubscribed, isFalse);
        expect(second.isSubscribed, isTrue);
        expect(builds, suppressNotification ? 1 : 2);
        expect(find.text(suppressNotification ? '0' : '1'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        expect(second.isSubscribed, isFalse);
      });
    }
  }

  testWidgets('equal deferred controllers must switch their subscriptions', (
    tester,
  ) async {
    final first = _EqualSource(0);
    final second = _EqualSource(1);
    var builds = 0;

    final consumer = Builder(
      builder: (context) {
        builds++;
        return Text(
          '${context.watch<int>()}',
          textDirection: TextDirection.ltr,
        );
      },
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
    final beforeReplacement = builds;

    await tester.pumpWidget(provider(second));
    expect(first.isSubscribed, isFalse);
    expect(second.isSubscribed, isTrue);
    expect(find.text('5'), findsOneWidget);
    expect(builds, beforeReplacement);

    first.send(6);
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    second.send(7);
    await tester.pump();
    expect(find.text('7'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(second.isSubscribed, isFalse);
  });
}
