import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'common.dart';

void main() {
  group('valueListenableProvider', () {
    testWidgets('rebuilds when value change', (tester) async {
      final listenable = ValueNotifier(0);

      final child = Builder(
          builder: (context) => Text(Provider.of<int>(context).toString(),
              textDirection: TextDirection.ltr));

      await tester.pumpWidget(ValueListenableProvider(
        listenable: listenable,
        child: child,
      ));

      expect(find.text('0'), findsOneWidget);
      listenable.value++;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets("don't rebuild dependents by default", (tester) async {
      final builder = BuilderMock();
      when(builder(any)).thenAnswer((invocation) {
        final context = invocation.positionalArguments.first as BuildContext;
        Provider.of<int>(context);
        return Container();
      });

      final listenable = ValueNotifier(0);
      final child = Builder(builder: builder);

      await tester.pumpWidget(ValueListenableProvider(
        listenable: listenable,
        child: child,
      ));
      verify(builder(any)).called(1);

      await tester.pumpWidget(ValueListenableProvider(
        listenable: listenable,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
    });

    testWidgets('pass keys', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ValueListenableProvider(
        key: key,
        listenable: ValueNotifier(42),
        child: Container(),
      ));

      expect(key.currentWidget, isInstanceOf<ValueListenableProvider<int>>());
    });
    testWidgets('pass updateShouldNotify', (tester) async {
      final shouldNotify = UpdateShouldNotifyMock<int>();
      when(shouldNotify(0, 1)).thenReturn(true);

      var notifier = ValueNotifier(0);
      await tester.pumpWidget(ValueListenableProvider(
        listenable: notifier,
        updateShouldNotify: shouldNotify,
        child: Container(),
      ));

      verifyZeroInteractions(shouldNotify);

      notifier.value++;
      await tester.pump();

      verify(shouldNotify(0, 1)).called(1);
      verifyNoMoreInteractions(shouldNotify);
    });

    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [ValueListenableProvider(listenable: ValueNotifier(42))],
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), 42);
    });
  });
}
