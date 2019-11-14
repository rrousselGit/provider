import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('ChangeNotifierProvider', () {
    testWidgets('value', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: myNotifier),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      // would throw if myNotifier is disposed
      myNotifier.notifyListeners();
    });

    testWidgets('builder', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(builder: (_) => myNotifier),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
    testWidgets('builder1', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(builder: (_) => A()),
            ChangeNotifierProxyProvider<A, ValueNotifier<int>>(
              initialBuilder: (_) => null,
              builder: (_, __, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
    testWidgets('builder2', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(builder: (_) => A()),
            Provider(builder: (_) => B()),
            ChangeNotifierProxyProvider2<A, B, ValueNotifier<int>>(
              initialBuilder: (_) => null,
              builder: (_, _a, _b, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
    testWidgets('builder3', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(builder: (_) => A()),
            Provider(builder: (_) => B()),
            Provider(builder: (_) => C()),
            ChangeNotifierProxyProvider3<A, B, C, ValueNotifier<int>>(
              initialBuilder: (_) => null,
              builder: (_, _a, _b, _c, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
    testWidgets('builder4', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(builder: (_) => A()),
            Provider(builder: (_) => B()),
            Provider(builder: (_) => C()),
            Provider(builder: (_) => D()),
            ChangeNotifierProxyProvider4<A, B, C, D, ValueNotifier<int>>(
              initialBuilder: (_) => null,
              builder: (_, _a, _b, _c, _d, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
    testWidgets('builder5', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(builder: (_) => A()),
            Provider(builder: (_) => B()),
            Provider(builder: (_) => C()),
            Provider(builder: (_) => D()),
            Provider(builder: (_) => E()),
            ChangeNotifierProxyProvider5<A, B, C, D, E, ValueNotifier<int>>(
              initialBuilder: (_) => null,
              builder: (_, _a, _b, _c, _d, _e, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
    testWidgets('builder6', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(builder: (_) => A()),
            Provider(builder: (_) => B()),
            Provider(builder: (_) => C()),
            Provider(builder: (_) => D()),
            Provider(builder: (_) => E()),
            Provider(builder: (_) => F()),
            ChangeNotifierProxyProvider6<A, B, C, D, E, F, ValueNotifier<int>>(
              initialBuilder: (_) => null,
              builder: (_, _a, _b, _c, _d, _e, _f, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
  });
}
