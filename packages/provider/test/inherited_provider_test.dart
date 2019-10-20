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
  group('InheritedProvider.value', () {
    testWidgets('pass down current value', (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          child: Context(),
        ),
      );

      expect(of<int>(), equals(42));
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
}
