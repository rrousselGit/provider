import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('ChangeNotifierProvider', () {
    testWidgets('default', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ValueNotifier(0),
          builder: (context, child) {
            assert(context.read<ValueNotifier<int>>() != null);
            return child;
          },
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('.value', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: ValueNotifier(0),
          builder: (context, child) {
            assert(context.read<ValueNotifier<int>>() != null);
            return child;
          },
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
  });
  group('ListenableProvider', () {
    testWidgets('default', (tester) async {
      await tester.pumpWidget(
        ListenableProvider(
          create: (_) => ValueNotifier(0),
          builder: (context, child) {
            assert(context.read<ValueNotifier<int>>() != null);
            return child;
          },
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('.value', (tester) async {
      await tester.pumpWidget(
        ListenableProvider.value(
          value: ValueNotifier(0),
          builder: (context, child) {
            assert(context.read<ValueNotifier<int>>() != null);
            return child;
          },
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
  });
  group('Provider', () {
    testWidgets('default', (tester) async {
      await tester.pumpWidget(
        Provider(
          create: (_) => 0,
          builder: (context, child) {
            assert(context.read<int>() != null);
            return child;
          },
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('.value', (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: 0,
          builder: (context, child) {
            assert(context.read<int>() != null);
            return child;
          },
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
  });
  group('ProxyProvider', () {
    testWidgets('0', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ProxyProvider0<int>(
              update: (_, __) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('1', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: ''),
            ProxyProvider<String, int>(
              update: (_, __, ___) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('2', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: ''),
            Provider.value(value: .0),
            ProxyProvider2<String, double, int>(
              update: (a, b, c, d) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('3', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: ''),
            Provider.value(value: .0),
            Provider.value(value: A()),
            ProxyProvider3<String, double, A, int>(
              update: (a, b, c, d, e) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('4', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: ''),
            Provider.value(value: .0),
            Provider.value(value: A()),
            Provider.value(value: B()),
            ProxyProvider4<String, double, A, B, int>(
              update: (a, b, c, d, e, f) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('6', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: ''),
            Provider.value(value: .0),
            Provider.value(value: A()),
            Provider.value(value: B()),
            Provider.value(value: C()),
            ProxyProvider5<String, double, A, B, C, int>(
              update: (a, b, c, d, e, f, g) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
    testWidgets('6', (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: ''),
            Provider.value(value: .0),
            Provider.value(value: A()),
            Provider.value(value: B()),
            Provider.value(value: C()),
            Provider.value(value: D()),
            ProxyProvider6<String, double, A, B, C, D, int>(
              update: (a, b, c, d, e, f, g, h) => 0,
              builder: (context, child) {
                buildCount++;
                assert(context.read<int>() != null);
                return child;
              },
            ),
          ],
          child: const Text('child', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('child'), findsOneWidget);
    });
  });
}
