import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('InheritedProvider', () {
    testWidgets('updateShouldNotify throws', (tester) async {
      expect(
        () => InheritedProvider<int>(
          value: 42,
          child: Container(),
          // ignore: invalid_use_of_protected_member
        ).updateShouldNotify(null),
        throwsUnsupportedError,
      );
    });
    testWidgets('pass down value', (tester) async {
      await tester.pumpWidget(InheritedProvider<int>(
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

      await tester.pumpWidget(InheritedProvider<int>(
        key: key,
        value: 0,
        startListening: startListening,
        child: Container(),
      ));

      verifyZeroInteractions(startListening);

      await tester.pumpWidget(InheritedProvider<int>(
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

      await tester.pumpWidget(InheritedProvider<int>(
        value: 0,
        startListening: startListening,
        child: child,
      ));

      await tester.pumpWidget(InheritedProvider<int>(
        value: 0,
        startListening: startListening,
        child: child,
      ));

      verify(startListening()).called(1);
    });
  });
}
