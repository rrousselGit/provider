import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class ConsumerBuilderMock extends Mock {
  Widget call(Combined foo);
}

class Combined {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;
  final Widget child;
  final BuildContext context;

  Combined(this.context, this.child, this.a,
      [this.b, this.c, this.d, this.e, this.f]);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Combined &&
      other.context == context &&
      other.child == child &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.e == e &&
      other.f == f;
}

void main() {
  final a = A();
  final b = B();
  final c = C();
  final d = D();
  final e = E();
  final f = F();
  final provider = MultiProvider(
    providers: [
      Provider.value(value: a),
      Provider.value(value: b),
      Provider.value(value: c),
      Provider.value(value: d),
      Provider.value(value: e),
      Provider.value(value: f),
    ],
  );

  final mock = ConsumerBuilderMock();
  setUp(() {
    when(mock(any)).thenReturn(Container());
  });
  tearDown(() {
    clearInteractions(mock);
  });

  group('consumer', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer<A>(
            key: key,
            builder: (context, value, child) =>
                mock(Combined(context, child, value)),
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer<int>(builder: null),
        throwsAssertionError,
      );
    });
    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: List.from(provider.providers)
          ..add(Consumer<A>(
            key: key,
            builder: (_, a, child) => Container(child: child),
          )),
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });

  group('consumer2', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer2<A, B>(
            key: key,
            builder: (context, value, v2, child) =>
                mock(Combined(context, child, value, v2)),
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer2<A, B>(builder: null),
        throwsAssertionError,
      );
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: List.from(provider.providers)
          ..add(Consumer2<A, B>(
            key: key,
            builder: (_, a, b, child) => Container(child: child),
          )),
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });
  group('consumer3', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer3<A, B, C>(
            key: key,
            builder: (context, value, v2, v3, child) =>
                mock(Combined(context, child, value, v2, v3)),
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer3<A, B, C>(builder: null),
        throwsAssertionError,
      );
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: List.from(provider.providers)
          ..add(Consumer3<A, B, C>(
            key: key,
            builder: (_, a, b, c, child) => Container(child: child),
          )),
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });
  group('consumer4', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer4<A, B, C, D>(
            key: key,
            builder: (context, value, v2, v3, v4, child) =>
                mock(Combined(context, child, value, v2, v3, v4)),
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c, d)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer4<A, B, C, D>(builder: null),
        throwsAssertionError,
      );
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: List.from(provider.providers)
          ..add(Consumer4<A, B, C, D>(
            key: key,
            builder: (_, a, b, c, d, child) => Container(child: child),
          )),
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });
  group('consumer5', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer5<A, B, C, D, E>(
            key: key,
            builder: (context, value, v2, v3, v4, v5, child) =>
                mock(Combined(context, child, value, v2, v3, v4, v5)),
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c, d, e)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer5<A, B, C, D, E>(builder: null),
        throwsAssertionError,
      );
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: List.from(provider.providers)
          ..add(Consumer5<A, B, C, D, E>(
            key: key,
            builder: (_, a, b, c, d, e, child) => Container(child: child),
          )),
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });
  group('consumer6', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer6<A, B, C, D, E, F>(
            key: key,
            builder: (context, value, v2, v3, v4, v5, v6, child) =>
                mock(Combined(context, child, value, v2, v3, v4, v5, v6)),
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c, d, e, f)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer6<A, B, C, D, E, F>(builder: null),
        throwsAssertionError,
      );
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: List.from(provider.providers)
          ..add(Consumer6<A, B, C, D, E, F>(
            key: key,
            builder: (_, a, b, c, d, e, f, child) => Container(child: child),
          )),
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });
}
