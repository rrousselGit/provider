import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/src/provider.dart';

class ValueBuilder extends Mock {
  int call(BuildContext context);
}

class Dispose extends Mock {
  void call(BuildContext context, int value);
}

void main() {
  test('asserts', () {
    expect(
      () => StatefulProvider<dynamic>(valueBuilder: null, child: null),
      throwsAssertionError,
    );
    // don't throw
    StatefulProvider<dynamic>(valueBuilder: (_) => null, child: null);
  });

  testWidgets('calls valueBuilder only once', (tester) async {
    final builder = ValueBuilder();
    await tester.pumpWidget(StatefulProvider<int>(
      valueBuilder: builder,
      child: Container(),
    ));
    await tester.pumpWidget(StatefulProvider<int>(
      valueBuilder: builder,
      child: Container(),
    ));
    await tester.pumpWidget(Container());

    verify(builder(any)).called(1);
  });

  testWidgets('dispose', (tester) async {
    final dispose = Dispose();
    const key = ValueKey(42);

    await tester.pumpWidget(
      StatefulProvider<int>(
        key: key,
        valueBuilder: (_) => 42,
        onDispose: dispose,
        child: Container(),
      ),
    );

    final context = tester.element(find.byKey(key));

    verifyZeroInteractions(dispose);
    await tester.pumpWidget(Container());
    verify(dispose(context, 42)).called(1);
  });

  testWidgets('update should notify', (tester) async {
    final shouldNotify = (int a, int b) => true;

    await tester.pumpWidget(
      StatefulProvider<int>(
        valueBuilder: (_) => 42,
        updateShouldNotify: shouldNotify,
        child: Container(),
      ),
    );

    final provider =
        tester.widget(find.byWidgetPredicate((w) => w is Provider<int>))
            as Provider<int>;

    expect(debugGetProviderUpdateShouldNotify(provider), shouldNotify);
  });
}
