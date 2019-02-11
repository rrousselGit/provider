import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

void main() {
  group('Provider', () {
    test('cloneWithChild works', () {
      final provider = Provider(
        value: 42,
        child: Container(),
        key: const ValueKey(42),
        updateShouldNotify: (int _, int __) => true,
      );

      final newChild = Container();
      final clone = provider.cloneWithChild(newChild);
      expect(clone.child, newChild);
      expect(clone.value, provider.value);
      expect(clone.key, provider.key);
      expect(debugGetProviderUpdateShouldNotify(provider),
          debugGetProviderUpdateShouldNotify(clone));
    });
    testWidgets('diagnosticable', (tester) async {
      await tester.pumpWidget(Provider<int>(
        child: Container(),
        value: 42,
      ));

      var widget = tester.widget(find.byWidgetPredicate((w) => w is Provider));

      final builder = DiagnosticPropertiesBuilder();
      widget.debugFillProperties(builder);
      expect(builder.properties.length, 1);

      expect(builder.properties.first.name, 'value');
      expect(builder.properties.first.value, 42);
    });
    testWidgets('simple usage', (tester) async {
      var buildCount = 0;
      int value;
      double second;
      String missing;

      // We voluntarily reuse the builder instance so that later call to pumpWidget
      // don't call builder again unless subscribed to an inheritedWidget
      final builder = Builder(
        builder: (context) {
          buildCount++;
          value = Provider.of(context);
          missing = Provider.of(context);
          second = Provider.of(context, listen: false);
          return Container();
        },
      );

      await tester.pumpWidget(
        Provider<double>(
          value: 24.0,
          child: Provider<int>(
            value: 42,
            child: builder,
          ),
        ),
      );

      expect(value, equals(42));
      expect(second, equals(24.0));
      expect(missing, isNull);
      expect(buildCount, equals(1));

      // nothing changed
      await tester.pumpWidget(
        Provider<double>(
          value: 24.0,
          child: Provider<int>(
            value: 42,
            child: builder,
          ),
        ),
      );
      // didn't rebuild
      expect(buildCount, equals(1));

      // changed a value we are subscribed to
      await tester.pumpWidget(
        Provider<double>(
          value: 24.0,
          child: Provider<int>(
            value: 43,
            child: builder,
          ),
        ),
      );
      expect(value, equals(43));
      expect(second, equals(24.0));
      expect(missing, isNull);
      // got rebuilt
      expect(buildCount, equals(2));

      // changed a value we are _not_ subscribed to
      await tester.pumpWidget(
        Provider<double>(
          value: 20.0,
          child: Provider<int>(
            value: 43,
            child: builder,
          ),
        ),
      );
      // didn't get rebuilt
      expect(buildCount, equals(2));
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
        Provider<int>(
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
        Provider<int>(
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
        Provider<int>(
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
