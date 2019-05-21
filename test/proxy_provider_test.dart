import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class ConsumerBuilderMock extends Mock {
  Widget call(Combined foo);
}

class CombinerMock extends Mock {
  Combined call(BuildContext context, A a, Combined foo);
}

class ProviderBuilderMock extends Mock {
  Widget call(BuildContext context, Combined value, Widget child);
}

class Combined extends DiagnosticableTree {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;
  final Combined previous;
  final BuildContext context;

  Combined(this.context, this.previous, this.a,
      [this.b, this.c, this.d, this.e, this.f]);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Combined &&
      other.context == context &&
      other.previous == previous &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.e == e &&
      other.f == f;

  // fancy toString for debug purposes.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.properties.addAll([
      DiagnosticsProperty('a', a, defaultValue: null),
      DiagnosticsProperty('b', b, defaultValue: null),
      DiagnosticsProperty('c', c, defaultValue: null),
      DiagnosticsProperty('d', d, defaultValue: null),
      DiagnosticsProperty('e', e, defaultValue: null),
      DiagnosticsProperty('f', f, defaultValue: null),
      DiagnosticsProperty('previous', previous, defaultValue: null),
      DiagnosticsProperty('context', context, defaultValue: null),
    ]);
  }
}

Finder findProvider<T>() => find
    .byWidgetPredicate((widget) => widget.runtimeType == typeOf<Provider<T>>());

void main() {
  final a = A();

  final combinedConsumerMock = ConsumerBuilderMock();
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

    Finder findProxyProvider<T>() => find
        .byWidgetPredicate((widget) => widget is ProxyProvider<T, Combined>);

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
      var shouldNotify = (Object a, Object b) => a == b;
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: a),
          ProxyProvider<A, Object>(
            builder: (_, a, __) => a,
            updateShouldNotify: shouldNotify,
          ),
        ],
        child: Container(),
      ));

      final provider =
          tester.widget(findProvider<Object>()) as Provider<Object>;

      expect(provider.updateShouldNotify, equals(shouldNotify));
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
        initialBuilder: (_) {},
        builder: (_, __, ___) {},
        updateShouldNotify: (_, __) {},
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
      expect(clone.providerBuilder, equals(provider.providerBuilder));
    });

    // useful for libraries such as Mobx where events are synchronously dispatched
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

  group('ProxyProvider.custom', () {
    test('works with MultiProvider', () {
      final provider = ProxyProvider<A, B>.custom(
        key: const Key('42'),
        initialBuilder: (_) {},
        builder: (_, __, ___) {},
        providerBuilder: (_, __, ___) {},
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
      expect(clone.providerBuilder, equals(provider.providerBuilder));
    });
    test('throws if builder is null', () {
      expect(
        () => ProxyProvider<A, B>.custom(
              builder: null,
              providerBuilder: (_, __, ___) {},
            ),
        throwsAssertionError,
      );
    });
    test('throws if providerBuilder is null', () {
      expect(
        () => ProxyProvider<A, B>.custom(
              builder: (_, __, ___) {},
              providerBuilder: null,
            ),
        throwsAssertionError,
      );
    });

    testWidgets("don't create a Provider and instead calls providerBuilder",
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>.custom(
              builder: (c, a, p) => Combined(c, p, a),
              providerBuilder: (_, __, ___) => Container(key: key),
            )
          ],
        ),
      );

      expect(key.currentWidget, isNotNull);
      expect(() => Provider.of<Combined>(key.currentContext),
          throwsA(isInstanceOf<ProviderNotFoundError>()));
    });
    testWidgets('passes current value/context/child to providerBuilder',
        (tester) async {
      final providerBuilder = ProviderBuilderMock();
      when(providerBuilder(any, any, any)).thenReturn(Container());

      final child = Container();
      final key = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>.custom(
              key: key,
              builder: (c, a, p) => Combined(c, p, a),
              providerBuilder: providerBuilder,
            )
          ],
          child: child,
        ),
      );

      verify(providerBuilder(
        key.currentContext,
        Combined(key.currentContext, null, a),
        child,
      )).called(1);
      verifyNoMoreInteractions(providerBuilder);
    });

    test('pass down key', () {
      final key = GlobalKey();
      final provider = ProxyProvider<A, B>.custom(
        key: key,
        builder: (_, __, ___) {},
        providerBuilder: (_, __, ___) {},
      );

      expect(provider.key, key);
    });
    test('pass down dispose', () {
      final dispose = (BuildContext c, B value) {};
      final provider = ProxyProvider<A, B>.custom(
        dispose: dispose,
        builder: (_, __, ___) {},
        providerBuilder: (_, __, ___) {},
      );

      expect(provider.dispose, equals(dispose));
    });
  });
}
