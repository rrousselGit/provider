import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('InheritedProvider', () {
    testWidgets(
      'getChangedAspects not called if updateShouldNotify returns false',
      (tester) async {
        var calledCount = 0;
        var getChangedAspects = (int _, int __) {
          calledCount++;
          return <Object>{};
        };
        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            getChangedAspects: getChangedAspects,
            child: Container(),
          ),
        );

        expect(calledCount, equals(0));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            getChangedAspects: getChangedAspects,
            child: Container(),
          ),
        );
        expect(calledCount, equals(0));
      },
    );
    testWidgets(
      'rebuilds dependents with no aspects when value changes',
      (tester) async {
        var buildCount = 0;
        var consumer = Consumer<int>(builder: (_, __, ___) {
          buildCount++;
          return Container();
        });

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: consumer,
          ),
        );

        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 43,
            child: consumer,
          ),
        );

        expect(buildCount, equals(2));
      },
    );

    testWidgets(
      "don't rebuilds dependents with aspects when value changes"
      "if the change don't impact the dependents aspects",
      (tester) async {
        var buildCount = 0;
        var consumer = Builder(
          builder: (context) {
            buildCount++;
            Provider.of<int>(context, aspect: 'a');
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: consumer,
          ),
        );

        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 43,
            child: consumer,
          ),
        );

        expect(buildCount, equals(1));
      },
    );
    testWidgets(
      'getChangedAspects called only once with 2+ dependents',
      (tester) async {
        var callCount = 0;
        final getChangedAspects = (int _, int __) {
          callCount++;
          return <Object>{'a', 'b'};
        };

        var buildCountA = 0;
        var buildCountB = 0;
        final child = Row(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            Builder(
              builder: (context) {
                buildCountA++;
                Provider.of<int>(context, aspect: 'a');
                return Container();
              },
            ),
            Builder(
              builder: (context) {
                buildCountB++;
                Provider.of<int>(context, aspect: 'b');
                return Container();
              },
            )
          ],
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            getChangedAspects: getChangedAspects,
            child: child,
          ),
        );

        expect(callCount, equals(0));
        expect(buildCountA, equals(1));
        expect(buildCountB, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 43,
            getChangedAspects: getChangedAspects,
            child: child,
          ),
        );

        expect(callCount, equals(1));
        expect(buildCountA, equals(2));
        expect(buildCountB, equals(2));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 44,
            getChangedAspects: getChangedAspects,
            child: child,
          ),
        );

        expect(callCount, equals(2));
        expect(buildCountA, equals(3));
        expect(buildCountB, equals(3));
      },
    );
    testWidgets(
      "don't call getChanegdAspects if there's no dependent",
      (tester) async {
        var callCount = 0;
        final getChangedAspects = (int _, int __) {
          callCount++;
          return <Object>{};
        };

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            getChangedAspects: getChangedAspects,
            child: Container(),
          ),
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 43,
            getChangedAspects: getChangedAspects,
            child: Container(),
          ),
        );

        expect(callCount, equals(0));
      },
    );
    testWidgets(
      'rebuilds dependents with aspects when value changes'
      'and getChangedAspects contains one aspect used by the dependent',
      (tester) async {
        var buildCount = 0;
        var consumer = Builder(
          builder: (context) {
            buildCount++;
            Provider.of<int>(context, aspect: 'a');
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: consumer,
          ),
        );

        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 43,
            getChangedAspects: (p, c) => {'a', 'b'},
            child: consumer,
          ),
        );

        expect(buildCount, equals(2));
      },
    );

    testWidgets('updateShouldNotify throws', (tester) async {
      expect(
        () => InheritedProvider<int>.value(
          value: 42,
          child: Container(),
          // ignore: invalid_use_of_protected_member
        ).updateShouldNotify(null),
        throwsUnsupportedError,
      );
    });
    testWidgets('pass down value', (tester) async {
      await tester.pumpWidget(InheritedProvider<int>.value(
        value: 42,
        child: Builder(builder: (context) {
          return Text(
            Provider.of<int>(context).toString(),
            textDirection: TextDirection.ltr,
          );
        }),
      ));

      expect(find.text('42'), findsOneWidget);
    });
    testWidgets('can lazily set value using startListening', (tester) async {
      final startListening = ValueBuilderMock<int>();
      when(startListening()).thenReturn(42);

      final key = GlobalKey();

      await tester.pumpWidget(InheritedProvider<int>.value(
        key: key,
        value: 0,
        startListening: startListening,
        child: Container(),
      ));

      verifyZeroInteractions(startListening);

      await tester.pumpWidget(InheritedProvider<int>.value(
        key: key,
        value: 0,
        startListening: startListening,
        child: Builder(builder: (context) {
          verifyZeroInteractions(startListening);
          return Text(
            Provider.of<int>(context).toString(),
            textDirection: TextDirection.ltr,
          );
        }),
      ));

      verify(startListening()).called(1);
      expect(find.text('0'), findsNothing);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets("don't call startListening again on rebuild", (tester) async {
      final startListening = ValueBuilderMock<int>();
      when(startListening()).thenReturn(42);

      final child = Builder(builder: (context) {
        return Text(
          Provider.of<int>(context).toString(),
          textDirection: TextDirection.ltr,
        );
      });

      await tester.pumpWidget(InheritedProvider<int>.value(
        value: 0,
        startListening: startListening,
        child: child,
      ));

      await tester.pumpWidget(InheritedProvider<int>.value(
        value: 0,
        startListening: startListening,
        child: child,
      ));

      verify(startListening()).called(1);
    });
  });
}
