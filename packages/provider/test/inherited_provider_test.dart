import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class Context extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

BuildContext get context => find.byType(Context).evaluate().single;

T of<T>([BuildContext c]) => Provider.of<T>(c ?? context, listen: false);

void main() {
  group('InheritedProvider.value()', () {
    testWidgets('pass down current value', (tester) async {
      int value;
      final child = Consumer<int>(
        builder: (_, v, __) {
          value = v;
          return Container();
        },
      );

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 42, child: child),
      );

      expect(value, equals(42));

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 43, child: child),
      );

      expect(value, equals(43));
    });
    testWidgets('default updateShouldNotify', (tester) async {
      var buildCount = 0;

      final child = Consumer<int>(builder: (_, __, ___) {
        buildCount++;
        return Container();
      });

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 42, child: child),
      );
      expect(buildCount, equals(1));

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 42, child: child),
      );
      expect(buildCount, equals(1));

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 43, child: child),
      );
      expect(buildCount, equals(2));
    });
    testWidgets('custom updateShouldNotify', (tester) async {
      var buildCount = 0;
      final updateShouldNotify = UpdateShouldNotifyMock<int>();

      final child = Consumer<int>(builder: (_, __, ___) {
        buildCount++;
        return Container();
      });

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          updateShouldNotify: updateShouldNotify,
          child: child,
        ),
      );
      expect(buildCount, equals(1));
      verifyZeroInteractions(updateShouldNotify);

      when(updateShouldNotify(any, any)).thenReturn(false);
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 43,
          updateShouldNotify: updateShouldNotify,
          child: child,
        ),
      );
      expect(buildCount, equals(1));
      verify(updateShouldNotify(42, 43))..called(1);

      when(updateShouldNotify(any, any)).thenReturn(true);
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 44,
          updateShouldNotify: updateShouldNotify,
          child: child,
        ),
      );
      expect(buildCount, equals(2));
      verify(updateShouldNotify(43, 44))..called(1);

      verifyNoMoreInteractions(updateShouldNotify);
    });
  });
  group('InheritedProvider()', () {
    testWidgets(
      'fails if initialValueBuilder calls inheritFromElement/inheritFromWiggetOfExactType',
      (tester) async {
        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: InheritedProvider<double>(
              initialValueBuilder: (context) =>
                  Provider.of<int>(context).toDouble(),
              child: Consumer<double>(
                builder: (_, __, ___) => Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isAssertionError);
      },
    );
    testWidgets(
      'builder is called on every rebuild'
      'and after a dependency change',
      (tester) async {
        int lastValue;
        final child = Consumer<int>(
          builder: (_, value, __) {
            lastValue = value;
            return Container();
          },
        );
        final valueBuilder = ValueBuilderMock<int>();
        when(valueBuilder(any, any))
            .thenAnswer((i) => (i.positionalArguments[1] as int) * 2);

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => 42,
            valueBuilder: valueBuilder,
            child: Container(),
          ),
        );

        final inheritedElement = tester.element(
          find.byWidgetPredicate((w) => w is InheritedProvider<int>),
        );
        verifyZeroInteractions(valueBuilder);

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => 42,
            valueBuilder: valueBuilder,
            child: child,
          ),
        );

        verify(valueBuilder(inheritedElement, 42)).called(1);
        expect(lastValue, equals(84));

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => 42,
            valueBuilder: valueBuilder,
            child: child,
          ),
        );

        verify(valueBuilder(inheritedElement, 84)).called(1);
        expect(lastValue, equals(168));

        verifyNoMoreInteractions(valueBuilder);
      },
    );
    testWidgets(
      'builder calls updateShouldNotify & use == if missing',
      (tester) async {
        int lastValue;
        var buildCount = 0;
        final child = Consumer<int>(
          builder: (_, value, __) {
            lastValue = value;
            buildCount++;
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => null,
            valueBuilder: (_, __) => 42,
            child: child,
          ),
        );

        expect(lastValue, equals(42));
        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => null,
            valueBuilder: (_, __) => 42,
            child: child,
          ),
        );

        expect(lastValue, equals(42));
        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => null,
            valueBuilder: (_, __) => 43,
            child: child,
          ),
        );

        expect(lastValue, equals(43));
        expect(buildCount, equals(2));
      },
    );
    testWidgets(
      'builder calls updateShouldNotify callback',
      (tester) async {
        final updateShouldNotify = UpdateShouldNotifyMock<int>();

        int lastValue;
        var buildCount = 0;
        final child = Consumer<int>(
          builder: (_, value, __) {
            lastValue = value;
            buildCount++;
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => null,
            valueBuilder: (_, __) => 42,
            updateShouldNotify: updateShouldNotify,
            child: child,
          ),
        );

        verifyZeroInteractions(updateShouldNotify);
        expect(lastValue, equals(42));
        expect(buildCount, equals(1));

        when(updateShouldNotify(any, any)).thenReturn(true);
        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => null,
            valueBuilder: (_, __) => 42,
            updateShouldNotify: updateShouldNotify,
            child: child,
          ),
        );

        verify(updateShouldNotify(42, 42)).called(1);
        expect(lastValue, equals(42));
        expect(buildCount, equals(2));

        when(updateShouldNotify(any, any)).thenReturn(false);
        await tester.pumpWidget(
          InheritedProvider<int>(
            initialValueBuilder: (_) => null,
            valueBuilder: (_, __) => 43,
            updateShouldNotify: updateShouldNotify,
            child: child,
          ),
        );

        verify(updateShouldNotify(42, 43)).called(1);
        expect(lastValue, equals(42));
        expect(buildCount, equals(2));

        verifyNoMoreInteractions(updateShouldNotify);
      },
    );
    // TODO: calls builder again if dependencies change
    // TODO: throw if either builder or initialBuilder is missing
    // TODO: don't update dependents when rebuilding
    testWidgets('calls initialValueBuilder lazily once', (tester) async {
      final initialValueBuilder = InitialValueBuilderMock<int>();
      when(initialValueBuilder(any)).thenReturn(42);

      await tester.pumpWidget(
        InheritedProvider<int>(
          initialValueBuilder: initialValueBuilder,
          child: Context(),
        ),
      );

      verifyZeroInteractions(initialValueBuilder);

      final inheritedProviderElement = tester.element(
        find.byWidgetPredicate((w) => w is InheritedProvider<int>),
      );

      expect(of<int>(), equals(42));
      verify(initialValueBuilder(inheritedProviderElement)).called(1);

      await tester.pumpWidget(
        InheritedProvider<int>(
          initialValueBuilder: initialValueBuilder,
          child: Context(),
        ),
      );

      expect(of<int>(), equals(42));
      verifyNoMoreInteractions(initialValueBuilder);
    });
  });
}
