import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide TypeMatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:test_api/test_api.dart' show TypeMatcher;

import 'common.dart';

void main() {
  group('Provider', () {
    testWidgets('throws if the provided value is a Listenable/Stream',
        (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: MyListenable(),
          child: Container(),
        ),
      );

      expect(tester.takeException(), isFlutterError);

      await tester.pumpWidget(
        Provider.value(
          value: MyStream(),
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
        Provider.value(
          value: MyListenable(),
          child: Container(),
        ),
      );

      await tester.pumpWidget(
        Provider.value(
          value: MyStream(),
          child: Container(),
        ),
      );
    });
    test('cloneWithChild works', () {
      final provider = Provider.value(
        value: 42,
        child: Container(),
        key: const ValueKey(42),
        updateShouldNotify: (int _, int __) => true,
      );

      final newChild = Container();
      final clone = provider.cloneWithChild(newChild);
      expect(clone.child, equals(newChild));
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
      expect(clone.key, equals(provider.key));
      expect(provider.updateShouldNotify, equals(clone.updateShouldNotify));
    });
    testWidgets('simple usage', (tester) async {
      var buildCount = 0;
      int value;
      double second;

      // We voluntarily reuse the builder instance so that later call to pumpWidget
      // don't call builder again unless subscribed to an inheritedWidget
      final builder = Builder(
        builder: (context) {
          buildCount++;
          value = Provider.of(context);
          second = Provider.of(context, listen: false);
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
        const TypeMatcher<ProviderNotFoundError>()
            .having((err) => err.valueType, 'valueType', String)
            .having((err) => err.widgetType, 'widgetType', Builder)
            .having((err) => err.toString(), 'toString()', '''
Error: Could not find the correct Provider<String> above this Builder Widget

To fix, please:

  * Ensure the Provider<String> is an ancestor to this Builder Widget
  * Provide types to Provider<String>
  * Provide types to Consumer<String>
  * Provide types to Provider.of<String>()
  * Always use package imports. Ex: `import 'package:my_app/my_code.dart';
  * Ensure the correct `context` is being used.

If none of these solutions work, please file a bug at:
https://github.com/rrousselGit/provider/issues
'''),
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

      // value didnt' change
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
