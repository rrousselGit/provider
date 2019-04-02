import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _Mock extends Mock {
  Widget call(Foo foo);
}

class Foo {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;
  final BuildContext context;

  Foo(this.context, this.a, [this.b, this.c, this.d, this.e, this.f]);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Foo &&
      other.context == context &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.e == e &&
      other.f == f;
}

class A {}

class B {}

class C {}

class D {}

class E {}

class F {}

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

  final mock = _Mock();
  setUp(() {
    when(mock(any)).thenReturn(Container());
  });
  tearDown(() {
    clearInteractions(mock);
  });

  group('consumer', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer<A>(
              key: key, builder: (context, value) => mock(Foo(context, value))),
        ),
      );

      verify(mock(Foo(key.currentContext, a)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer<int>(builder: null),
        throwsAssertionError,
      );
    });
  });

  group('consumer2', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer2<A, B>(
              key: key,
              builder: (context, value, v2) => mock(Foo(context, value, v2))),
        ),
      );

      verify(mock(Foo(key.currentContext, a, b)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer2<A, B>(builder: null),
        throwsAssertionError,
      );
    });
  });
  group('consumer3', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer3<A, B, C>(
              key: key,
              builder: (context, value, v2, v3) =>
                  mock(Foo(context, value, v2, v3))),
        ),
      );

      verify(mock(Foo(key.currentContext, a, b, c)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer3<A, B, C>(builder: null),
        throwsAssertionError,
      );
    });
  });
  group('consumer4', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer4<A, B, C, D>(
              key: key,
              builder: (context, value, v2, v3, v4) =>
                  mock(Foo(context, value, v2, v3, v4))),
        ),
      );

      verify(mock(Foo(key.currentContext, a, b, c, d)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer4<A, B, C, D>(builder: null),
        throwsAssertionError,
      );
    });
  });
  group('consumer5', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer5<A, B, C, D, E>(
              key: key,
              builder: (context, value, v2, v3, v4, v5) =>
                  mock(Foo(context, value, v2, v3, v4, v5))),
        ),
      );

      verify(mock(Foo(key.currentContext, a, b, c, d, e)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer5<A, B, C, D, E>(builder: null),
        throwsAssertionError,
      );
    });
  });
  group('consumer6', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        provider.cloneWithChild(
          Consumer6<A, B, C, D, E, F>(
              key: key,
              builder: (context, value, v2, v3, v4, v5, v6) =>
                  mock(Foo(context, value, v2, v3, v4, v5, v6))),
        ),
      );

      verify(mock(Foo(key.currentContext, a, b, c, d, e, f)));
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer6<A, B, C, D, E, F>(builder: null),
        throwsAssertionError,
      );
    });
  });
}
