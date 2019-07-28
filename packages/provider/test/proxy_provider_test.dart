import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/proxy_provider.dart'
    show NumericProxyProvider, Void;

import 'common.dart';

Finder findProvider<T>() => find.byWidgetPredicate(
    // comparing `runtimeType` instead of using `is` because `is` accepts
    // subclasses but InheritedWidgets don't.
    (widget) => widget.runtimeType == typeOf<InheritedProvider<T>>());

void main() {
  final a = A();
  final b = B();
  final c = C();
  final d = D();
  final e = E();
  final f = F();

  final combinedConsumerMock = MockCombinedBuilder();
  setUp(() => when(combinedConsumerMock(any)).thenReturn(Container()));
  tearDown(() {
    clearInteractions(combinedConsumerMock);
  });

  final mockConsumer = Consumer<Combined>(
    builder: (context, combined, child) => combinedConsumerMock(combined),
  );

  group('ProxyProvider', () {
    final combiner = CombinerMock();
    setUp(() {
      when(combiner(any, any, any)).thenAnswer((Invocation invocation) {
        return Combined(
          invocation.positionalArguments.first as BuildContext,
          invocation.positionalArguments[2] as Combined,
          invocation.positionalArguments[1] as A,
        );
      });
    });
    tearDown(() => clearInteractions(combiner));

    Finder findProxyProvider<T>() => find.byWidgetPredicate(
          (widget) => widget is NumericProxyProvider<T, Void, Void, Void, Void,
              Void, Combined>,
        );

    testWidgets('throws if the provided value is a Listenable/Stream',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyListenable>(
              builder: (_, __, ___) => MyListenable(),
            )
          ],
          child: Container(),
        ),
      );

      expect(tester.takeException(), isFlutterError);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyStream>(
              builder: (_, __, ___) => MyStream(),
            )
          ],
          child: Container(),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });
    testWidgets('debugCheckInvalidValueType can be disabled', (tester) async {
      final previous = Provider.debugCheckInvalidValueType;
      Provider.debugCheckInvalidValueType = null;
      addTearDown(() => Provider.debugCheckInvalidValueType = previous);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyListenable>(
              builder: (_, __, ___) => MyListenable(),
            )
          ],
          child: Container(),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyStream>(
              builder: (_, __, ___) => MyStream(),
            )
          ],
          child: Container(),
        ),
      );
    });

    testWidgets('initialBuilder creates initial value', (tester) async {
      final initialBuilder = ValueBuilderMock<Combined>();
      final key = GlobalKey();

      when(initialBuilder(any)).thenReturn(Combined(null, null, null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              key: key,
              initialBuilder: initialBuilder,
              builder: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );

      final details = verify(initialBuilder(captureAny))..called(1);
      expect(details.captured.first, equals(key.currentContext));

      verify(combiner(key.currentContext, a, Combined(null, null, null)));
    });
    testWidgets('consume another providers', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              builder: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider<A>());

      verify(combinedConsumerMock(Combined(context, null, a))).called(1);
      verifyNoMoreInteractions(combinedConsumerMock);

      verify(combiner(context, a, null)).called(1);
      verifyNoMoreInteractions(combiner);
    });

    test('throws if builder is null', () {
      // ignore: prefer_const_constructors
      expect(() => ProxyProvider<A, Combined>(builder: null),
          throwsAssertionError);
    });

    testWidgets('rebuild descendants if value change', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              builder: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );

      final a2 = A();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a2),
            ProxyProvider<A, Combined>(
              builder: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );
      final context = tester.element(findProxyProvider<A>());

      verifyInOrder([
        combiner(context, a, null),
        combinedConsumerMock(Combined(context, null, a)),
        combiner(context, a2, Combined(context, null, a)),
        combinedConsumerMock(Combined(context, Combined(context, null, a), a2)),
      ]);

      verifyNoMoreInteractions(combiner);
      verifyNoMoreInteractions(combinedConsumerMock);
    });
    testWidgets('call dispose when unmounted with the latest result',
        (tester) async {
      final dispose = DisposerMock<Combined>();
      final dispose2 = DisposerMock<Combined>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(builder: combiner, dispose: dispose)
          ],
          child: mockConsumer,
        ),
      );

      final a2 = A();

      // ProxyProvider creates a new Combined instance
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a2),
            ProxyProvider<A, Combined>(builder: combiner, dispose: dispose2)
          ],
          child: mockConsumer,
        ),
      );
      final context = tester.element(findProxyProvider<A>());

      await tester.pumpWidget(Container());

      verifyZeroInteractions(dispose);
      verify(
          dispose2(context, Combined(context, Combined(context, null, a), a2)));
    });

    testWidgets("don't rebuild descendants if value doesn't change",
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              builder: (c, a, p) => combiner(c, a, null),
            )
          ],
          child: mockConsumer,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(
              value: a,
              updateShouldNotify: (A _, A __) => true,
            ),
            ProxyProvider<A, Combined>(
              builder: (c, a, p) {
                combiner(c, a, p);
                return p;
              },
            )
          ],
          child: mockConsumer,
        ),
      );
      final context = tester.element(findProxyProvider<A>());

      verifyInOrder([
        combiner(context, a, null),
        combinedConsumerMock(Combined(context, null, a)),
        combiner(context, a, Combined(context, null, a)),
      ]);

      verifyNoMoreInteractions(combiner);
      verifyNoMoreInteractions(combinedConsumerMock);
    });

    testWidgets('pass down updateShouldNotify', (tester) async {
      var buildCount = 0;
      final child = Builder(builder: (context) {
        buildCount++;

        return Text(
          '$buildCount ${Provider.of<String>(context)}',
          textDirection: TextDirection.ltr,
        );
      });

      final shouldNotify = UpdateShouldNotifyMock<String>();
      when(shouldNotify('Hello', 'Hello')).thenReturn(false);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<String>.value(
              value: 'Hello', updateShouldNotify: (_, __) => true),
          ProxyProvider<String, String>(
            builder: (_, value, __) => value,
            updateShouldNotify: shouldNotify,
          ),
        ],
        child: child,
      ));

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<String>.value(
              value: 'Hello', updateShouldNotify: (_, __) => true),
          ProxyProvider<String, String>(
            builder: (_, value, __) => value,
            updateShouldNotify: shouldNotify,
          ),
        ],
        child: child,
      ));

      verify(shouldNotify('Hello', 'Hello')).called(1);
      verifyNoMoreInteractions(shouldNotify);

      expect(find.text('2 Hello'), findsNothing);
      expect(find.text('1 Hello'), findsOneWidget);
    });
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: a),
          ProxyProvider<A, Combined>(builder: (c, a, p) => Combined(c, p, a)),
        ],
        child: Container(key: key),
      ));
      final context = tester.element(findProxyProvider<A>());

      expect(
        Provider.of<Combined>(key.currentContext),
        Combined(context, null, a),
      );
    });
    test('works with MultiProvider #2', () {
      final provider = ProxyProvider<A, B>(
        key: const Key('42'),
        initialBuilder: (_) => null,
        builder: (_, __, ___) => null,
        updateShouldNotify: (_, __) => null,
        dispose: (_, __) {},
        child: Container(),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      expect(clone.initialBuilder, equals(provider.initialBuilder));
      expect(clone.builder, equals(provider.builder));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
      expect(clone.dispose, equals(provider.dispose));
      // expect(clone.providerBuilder, equals(provider.providerBuilder));
    });

    // useful for libraries such as Mobx where events are synchronously
    // dispatched
    testWidgets(
        'builder callback can trigger descendants setState synchronously',
        (tester) async {
      var statefulBuildCount = 0;
      void Function(VoidCallback) setState;

      final statefulBuilder = StatefulBuilder(builder: (_, s) {
        setState = s;
        statefulBuildCount++;
        return Container();
      });

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: a),
          ProxyProvider<A, Combined>(builder: (c, a, p) => Combined(c, p, a)),
        ],
        child: statefulBuilder,
      ));

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: A()),
          ProxyProvider<A, Combined>(builder: (c, a, p) {
            setState(() {});
            return Combined(c, p, a);
          }),
        ],
        child: statefulBuilder,
      ));

      expect(
        statefulBuildCount,
        2,
        reason: 'builder must not be called asynchronously',
      );
    });
  });

  group('ProxyProvider variants', () {
    Finder findProxyProvider<A, B, C, D, E, F>() => find.byWidgetPredicate(
          (widget) =>
              widget is NumericProxyProvider<A, B, C, D, E, F, Combined>,
        );
    testWidgets('ProxyProvider2', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider2<A, B, Combined>(
              initialBuilder: (_) => Combined(null, null, null),
              builder: (context, a, b, previous) =>
                  Combined(context, previous, a, b),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context =
          tester.element(findProxyProvider<A, B, Void, Void, Void, Void>());

      verify(
        combinedConsumerMock(
          Combined(context, Combined(null, null, null), a, b),
        ),
      ).called(1);
    });
    testWidgets('ProxyProvider3', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider3<A, B, C, Combined>(
              initialBuilder: (_) => Combined(null, null, null),
              builder: (context, a, b, c, previous) =>
                  Combined(context, previous, a, b, c),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context =
          tester.element(findProxyProvider<A, B, C, Void, Void, Void>());

      verify(
        combinedConsumerMock(
          Combined(context, Combined(null, null, null), a, b, c),
        ),
      ).called(1);
    });
    testWidgets('ProxyProvider4', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider4<A, B, C, D, Combined>(
              initialBuilder: (_) => Combined(null, null, null),
              builder: (context, a, b, c, d, previous) =>
                  Combined(context, previous, a, b, c, d),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context =
          tester.element(findProxyProvider<A, B, C, D, Void, Void>());

      verify(
        combinedConsumerMock(
          Combined(context, Combined(null, null, null), a, b, c, d),
        ),
      ).called(1);
    });
    testWidgets('ProxyProvider5', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider5<A, B, C, D, E, Combined>(
              initialBuilder: (_) => Combined(null, null, null),
              builder: (context, a, b, c, d, e, previous) =>
                  Combined(context, previous, a, b, c, d, e),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider<A, B, C, D, E, Void>());

      verify(
        combinedConsumerMock(
          Combined(context, Combined(null, null, null), a, b, c, d, e, null),
        ),
      ).called(1);
    });
    testWidgets('ProxyProvider6', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider6<A, B, C, D, E, F, Combined>(
              initialBuilder: (_) => Combined(null, null, null),
              builder: (context, a, b, c, d, e, f, previous) =>
                  Combined(context, previous, a, b, c, d, e, f),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider<A, B, C, D, E, F>());

      verify(
        combinedConsumerMock(
          Combined(context, Combined(null, null, null), a, b, c, d, e, f),
        ),
      ).called(1);
    });
  });
}
