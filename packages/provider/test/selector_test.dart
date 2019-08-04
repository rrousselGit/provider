import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as mockito show when;
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void mockImplementation<T extends Function>(VoidCallback when, T mock) {
  mockito.when(when()).thenAnswer((invo) {
    return Function.apply(mock, invo.positionalArguments, invo.namedArguments);
  });
}

void main() {
  final selector = MockSelector<int>();
  final builder = MockBuilder<int>();

  tearDown(() {
    clearInteractions(builder);
    clearInteractions(selector);
  });

  void mockBuilder(ValueWidgetBuilder<int> implementation) {
    mockImplementation(() => builder(any, any, any), implementation);
  }

  test('asserts that builder/selector are not null', () {
    expect(
      () => Selector0<int>(
        selector: null,
        builder: (_, __, ___) => Container(),
      ),
      throwsAssertionError,
    );
    expect(
      () => Selector<A, int>(selector: null, builder: (_, __, ___) => null),
      throwsAssertionError,
    );
    expect(
      () => Selector2<A, B, int>(selector: null, builder: (_, __, ___) => null),
      throwsAssertionError,
    );
    expect(
      () => Selector3<A, B, C, int>(
        selector: null,
        builder: (_, __, ___) => null,
      ),
      throwsAssertionError,
    );
    expect(
      () => Selector4<A, B, C, D, int>(
        selector: null,
        builder: (_, __, ___) => null,
      ),
      throwsAssertionError,
    );
    expect(
      () => Selector5<A, B, C, D, E, int>(
        selector: null,
        builder: (_, __, ___) => null,
      ),
      throwsAssertionError,
    );
    expect(
      () => Selector6<A, B, C, D, E, F, int>(
        selector: null,
        builder: (_, __, ___) => null,
      ),
      throwsAssertionError,
    );

    expect(
      () => Selector0<int>(
        selector: (_) => 42,
        builder: null,
      ),
      throwsAssertionError,
    );
  });
  testWidgets('passes `child` and `key`', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(Selector0<Null>(
      key: key,
      selector: (_) => null,
      builder: (_, __, child) => child,
      child: const Text('42', textDirection: TextDirection.ltr),
    ));

    expect(key.currentContext, isNotNull);

    expect(find.text('42'), findsOneWidget);
  });
  testWidgets('calls builder if the callback changes', (tester) async {
    await tester.pumpWidget(Selector0<int>(
      selector: (_) => 42,
      builder: (_, __, ___) =>
          const Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);

    await tester.pumpWidget(Selector0<int>(
      selector: (_) => 42,
      builder: (_, __, ___) =>
          const Text('bar', textDirection: TextDirection.ltr),
    ));

    expect(find.text('bar'), findsOneWidget);
  });
  testWidgets('works with MultiProvider', (tester) async {
    final key = GlobalKey();
    var selector = (BuildContext _) => 42;
    var builder = (BuildContext _, int __, Widget child) => child;
    final child = const Text('foo', textDirection: TextDirection.ltr);

    await tester.pumpWidget(MultiProvider(
      providers: [
        Selector0<int>(
          key: key,
          selector: selector,
          builder: builder,
        ),
      ],
      child: child,
    ));

    final widget = tester.widget(
      find.byWidgetPredicate((w) => w is Selector0<int>),
    ) as Selector0<int>;

    expect(find.text('foo'), findsOneWidget);
    expect(widget.key, key);
    expect(widget.selector, equals(selector));
    expect(widget.builder, equals(builder));
  });
  testWidgets(
      "don't call builder again if it rebuilds"
      'but selector returns the same thing', (tester) async {
    when(selector(any)).thenReturn(42);

    mockBuilder((_, value, ___) {
      return Text(value.toString(), textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(Selector0<int>(
      selector: selector,
      builder: builder,
    ));

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(selector);

    verify(builder(argThat(isNotNull), 42, null)).called(1);
    verifyNoMoreInteractions(selector);

    expect(find.text('42'), findsOneWidget);

    tester
        .element(find.byWidgetPredicate((w) => w is Selector0))
        .markNeedsBuild();

    await tester.pump();

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(builder);
    verifyNoMoreInteractions(selector);
    expect(find.text('42'), findsOneWidget);
  });
  testWidgets(
      'call builder again if it rebuilds'
      'abd selector returns the a different variable', (tester) async {
    when(selector(any)).thenReturn(42);

    mockBuilder((_, value, ___) {
      return Text(value.toString(), textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(Selector0<int>(
      selector: selector,
      builder: builder,
    ));

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(selector);

    verify(builder(argThat(isNotNull), 42, null)).called(1);
    verifyNoMoreInteractions(selector);

    expect(find.text('42'), findsOneWidget);

    tester
        .element(find.byWidgetPredicate((w) => w is Selector0))
        .markNeedsBuild();

    when(selector(any)).thenReturn(24);

    await tester.pump();

    verify(selector(argThat(isNotNull))).called(1);
    verify(builder(argThat(isNotNull), 24, null)).called(1);
    verifyNoMoreInteractions(selector);
    verifyNoMoreInteractions(builder);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('Selector', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
        ],
        child: Selector<A, String>(
          selector: (_, a) => '$a',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
  });
  testWidgets('Selector2', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
        ],
        child: Selector2<A, B, String>(
          selector: (_, a, b) => '$a $b',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B'), findsOneWidget);
  });
  testWidgets('Selector3', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
        ],
        child: Selector3<A, B, C, String>(
          selector: (_, a, b, c) => '$a $b $c',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C'), findsOneWidget);
  });
  testWidgets('Selector4', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
          Provider.value(value: D()),
        ],
        child: Selector4<A, B, C, D, String>(
          selector: (_, a, b, c, d) => '$a $b $c $d',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C D'), findsOneWidget);
  });
  testWidgets('Selector5', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
          Provider.value(value: D()),
          Provider.value(value: E()),
        ],
        child: Selector5<A, B, C, D, E, String>(
          selector: (_, a, b, c, d, e) => '$a $b $c $d $e',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C D E'), findsOneWidget);
  });
  testWidgets('Selector6', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
          Provider.value(value: D()),
          Provider.value(value: E()),
          Provider.value(value: F()),
        ],
        child: Selector6<A, B, C, D, E, F, String>(
          selector: (_, a, b, c, d, e, f) => '$a $b $c $d $e $f',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C D E F'), findsOneWidget);
  });
}

mixin _ToString {
  @override
  String toString() {
    return runtimeType.toString();
  }
}

class A with _ToString {}

class B with _ToString {}

class C with _ToString {}

class D with _ToString {}

class E with _ToString {}

class F with _ToString {}

class MockSelector<T> extends Mock {
  T call(BuildContext context);
}

class MockBuilder<T> extends Mock {
  Widget call(BuildContext context, T value, Widget child);
}
