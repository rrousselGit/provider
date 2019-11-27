// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/proxy_provider.dart' show ProxyProviderBase;

import 'common.dart';

class _ListenableCombined = Combined with ChangeNotifier;

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

  final mockConsumer = Consumer<_ListenableCombined>(
    builder: (context, combined, child) => combinedConsumerMock(combined),
  );

  group('ChangeNotifierProxyProvider', () {
    test('throws if update is missing', () {
      expect(
        () => ChangeNotifierProxyProvider<A, _ListenableCombined>(
          create: null,
          update: null,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('works with null', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: 0),
            ChangeNotifierProxyProvider<int, ChangeNotifier>(
              create: (_) => null,
              update: (_, __, value) => value,
            )
          ],
          child: Container(),
        ),
      );

      await tester.pumpWidget(Container());
    });

    testWidgets('rebuilds dependendents when listeners are called',
        (tester) async {
      final notifier = ValueNotifier(0);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: 0),
            ChangeNotifierProxyProvider<int, ValueNotifier<int>>(
              create: (_) => notifier,
              update: (_, count, value) => value..value = count,
            )
          ],
          child: Consumer<ValueNotifier<int>>(builder: (_, value, __) {
            return Text(
              value.value.toString(),
              textDirection: TextDirection.ltr,
            );
          }),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      notifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
    testWidgets('disposes of created value', (tester) async {
      final notifier = MockNotifier();
      when(notifier.hasListeners).thenReturn(false);
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: 0),
            ChangeNotifierProxyProvider<int, MockNotifier>(
              key: key,
              create: (_) => notifier,
              update: (_, count, value) => value,
            )
          ],
          child: Container(),
        ),
      );

      await tester.pumpWidget(Container());

      verify(notifier.dispose()).called(1);
    });
  });

  group('ChangeNotifierProxyProvider variants', () {
    Finder findProxyProvider() => find
        .byWidgetPredicate((widget) => widget is ProxyProviderBase<Combined>);
    testWidgets('ChangeNotifierProxyProvider2', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ChangeNotifierProxyProvider2<A, B, _ListenableCombined>(
              create: (_) => _ListenableCombined(null, null, null),
              update: (context, a, b, previous) =>
                  _ListenableCombined(context, previous, a, b),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider());

      verify(
        combinedConsumerMock(
          _ListenableCombined(
              context, _ListenableCombined(null, null, null), a, b),
        ),
      ).called(1);
    });
    testWidgets('ChangeNotifierProxyProvider3', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ChangeNotifierProxyProvider3<A, B, C, _ListenableCombined>(
              create: (_) => _ListenableCombined(null, null, null),
              update: (context, a, b, c, previous) =>
                  _ListenableCombined(context, previous, a, b, c),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider());

      verify(
        combinedConsumerMock(
          _ListenableCombined(
              context, _ListenableCombined(null, null, null), a, b, c),
        ),
      ).called(1);
    });
    testWidgets('ChangeNotifierProxyProvider4', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ChangeNotifierProxyProvider4<A, B, C, D, _ListenableCombined>(
              create: (_) => _ListenableCombined(null, null, null),
              update: (context, a, b, c, d, previous) =>
                  _ListenableCombined(context, previous, a, b, c, d),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider());

      verify(
        combinedConsumerMock(
          _ListenableCombined(
              context, _ListenableCombined(null, null, null), a, b, c, d),
        ),
      ).called(1);
    });
    testWidgets('ChangeNotifierProxyProvider5', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ChangeNotifierProxyProvider5<A, B, C, D, E, _ListenableCombined>(
              create: (_) => _ListenableCombined(null, null, null),
              update: (context, a, b, c, d, e, previous) =>
                  _ListenableCombined(context, previous, a, b, c, d, e),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider());

      verify(
        combinedConsumerMock(
          _ListenableCombined(context, _ListenableCombined(null, null, null), a,
              b, c, d, e, null),
        ),
      ).called(1);
    });
    testWidgets('ChangeNotifierProxyProvider6', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ChangeNotifierProxyProvider6<A, B, C, D, E, F, _ListenableCombined>(
              create: (_) => _ListenableCombined(null, null, null),
              update: (context, a, b, c, d, e, f, previous) =>
                  _ListenableCombined(context, previous, a, b, c, d, e, f),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = tester.element(findProxyProvider());

      verify(
        combinedConsumerMock(
          _ListenableCombined(
              context, _ListenableCombined(null, null, null), a, b, c, d, e, f),
        ),
      ).called(1);
    });
  });
}
