import 'package:flutter/widgets.dart' hide TypeMatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' show TypeMatcher;

import 'common.dart';

void main() {
  testWidgets('works with MultiProvider', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(
            value: 42,
          ),
        ],
        child: const TextOf<int>(),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });
  group('Provider.of', () {
    testWidgets('throws if T is dynamic', (tester) async {
      await tester.pumpWidget(
        Provider<dynamic>.value(
          value: 42,
          child: Container(),
        ),
      );

      expect(
        () => Provider.of<dynamic>(tester.element(find.byType(Container))),
        throwsAssertionError,
      );
    });
    testWidgets(
      'listen defaults to true when building widgets',
      (tester) async {
        var buildCount = 0;
        final child = Builder(
          builder: (context) {
            buildCount++;
            Provider.of<int>(context);
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: child,
          ),
        );

        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 24,
            child: child,
          ),
        );

        expect(buildCount, equals(2));
      },
    );
    testWidgets(
      'listen defaults to false outside of the widget tree',
      (tester) async {
        var buildCount = 0;
        final child = Builder(
          builder: (context) {
            buildCount++;
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: child,
          ),
        );

        final context = tester.element(find.byWidget(child));
        Provider.of<int>(context, listen: false);
        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 24,
            child: child,
          ),
        );

        expect(buildCount, equals(1));
      },
    );
    testWidgets(
      "listen:false doesn't trigger rebuild",
      (tester) async {
        var buildCount = 0;
        final child = Builder(
          builder: (context) {
            Provider.of<int>(context, listen: false);
            buildCount++;
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: child,
          ),
        );

        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 24,
            child: child,
          ),
        );

        expect(buildCount, equals(1));
      },
    );
    testWidgets(
      'listen:true outside of the widget tree throws',
      (tester) async {
        final child = Builder(
          builder: (context) {
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: child,
          ),
        );

        final context = tester.element(find.byWidget(child));

        expect(
          () => Provider.of<int>(context, listen: true),
          throwsAssertionError,
        );
      },
    );
  });
  group('Provider', () {
    testWidgets('throws if the provided value is a Listenable/Stream',
        (tester) async {
      expect(
        () => Provider.value(
          value: MyListenable(),
          child: const TextOf<MyListenable>(),
        ),
        throwsFlutterError,
      );

      expect(
        () => Provider.value(
          value: MyStream(),
          child: const TextOf<MyListenable>(),
        ),
        throwsFlutterError,
      );

      await tester.pumpWidget(
        Provider(
          key: UniqueKey(),
          create: (_) => MyListenable(),
          child: const TextOf<MyListenable>(),
        ),
      );

      expect(tester.takeException(), isFlutterError);

      await tester.pumpWidget(
        Provider(
          key: UniqueKey(),
          create: (_) => MyStream(),
          child: const TextOf<MyStream>(),
        ),
      );
      expect(tester.takeException(), isFlutterError);
    });
    testWidgets('debugCheckInvalidValueType can be disabled', (tester) async {
      final previous = Provider.debugCheckInvalidValueType;
      Provider.debugCheckInvalidValueType = null;
      addTearDown(() => Provider.debugCheckInvalidValueType = previous);

      await tester.pumpWidget(
        Provider.value(
          value: MyListenable(),
          child: const TextOf<MyListenable>(),
        ),
      );

      await tester.pumpWidget(
        Provider.value(
          value: MyStream(),
          child: const TextOf<MyStream>(),
        ),
      );
    });

    testWidgets('simple usage', (tester) async {
      var buildCount = 0;
      int value;
      double second;

      // We voluntarily reuse the builder instance so that later call to
      // pumpWidget don't call builder again unless subscribed to an
      // inheritedWidget
      final builder = Builder(
        builder: (context) {
          buildCount++;
          value = Provider.of<int>(context);
          second = Provider.of<double>(context, listen: false);
          return Container();
        },
      );

      await tester.pumpWidget(
        Provider<double>.value(
          value: 24.0,
          child: Provider<int>.value(
            value: 42,
            child: builder,
          ),
        ),
      );

      expect(value, equals(42));
      expect(second, equals(24.0));
      expect(buildCount, equals(1));

      // nothing changed
      await tester.pumpWidget(
        Provider<double>.value(
          value: 24.0,
          child: Provider<int>.value(
            value: 42,
            child: builder,
          ),
        ),
      );
      // didn't rebuild
      expect(buildCount, equals(1));

      // changed a value we are subscribed to
      await tester.pumpWidget(
        Provider<double>.value(
          value: 24.0,
          child: Provider<int>.value(
            value: 43,
            child: builder,
          ),
        ),
      );
      expect(value, equals(43));
      expect(second, equals(24.0));
      // got rebuilt
      expect(buildCount, equals(2));

      // changed a value we are _not_ subscribed to
      await tester.pumpWidget(
        Provider<double>.value(
          value: 20.0,
          child: Provider<int>.value(
            value: 43,
            child: builder,
          ),
        ),
      );
      // didn't get rebuilt
      expect(buildCount, equals(2));
    });

    testWidgets('throws an error if no provider found', (tester) async {
      await tester.pumpWidget(Builder(builder: (context) {
        Provider.of<String>(context);
        return Container();
      }));

      expect(
        tester.takeException(),
        const TypeMatcher<ProviderNotFoundException>()
            .having((err) => err.valueType, 'valueType', String)
            .having((err) => err.widgetType, 'widgetType', Builder),
      );
    });

    testWidgets('update should notify', (tester) async {
      int old;
      int curr;
      var callCount = 0;
      final updateShouldNotify = (int o, int c) {
        callCount++;
        old = o;
        curr = c;
        return o != c;
      };

      var buildCount = 0;
      int buildValue;
      final builder = Builder(builder: (BuildContext context) {
        buildValue = Provider.of(context);
        buildCount++;
        return Container();
      });

      await tester.pumpWidget(
        Provider<int>.value(
          value: 24,
          updateShouldNotify: updateShouldNotify,
          child: builder,
        ),
      );
      expect(callCount, equals(0));
      expect(buildCount, equals(1));
      expect(buildValue, equals(24));

      // value changed
      await tester.pumpWidget(
        Provider<int>.value(
          value: 25,
          updateShouldNotify: updateShouldNotify,
          child: builder,
        ),
      );
      expect(callCount, equals(1));
      expect(old, equals(24));
      expect(curr, equals(25));
      expect(buildCount, equals(2));
      expect(buildValue, equals(25));

      // value didn't change
      await tester.pumpWidget(
        Provider<int>.value(
          value: 25,
          updateShouldNotify: updateShouldNotify,
          child: builder,
        ),
      );
      expect(callCount, equals(2));
      expect(old, equals(25));
      expect(curr, equals(25));
      expect(buildCount, equals(2));
    });
  });
}
