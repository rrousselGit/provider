import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/src/provider.dart';

import 'common.dart';

class ValueBuilder extends Mock {
  int call(BuildContext context);
}

class Dispose extends Mock {
  void call(BuildContext context, int value);
}

void main() {
  test('asserts', () {
    expect(
      () => Provider<dynamic>(create: null, child: null),
      throwsAssertionError,
    );
    // don't throw
    Provider<dynamic>(create: (_) => null, child: null);
  });

  testWidgets('calls builder only once', (tester) async {
    final builder = ValueBuilder();
    await tester.pumpWidget(Provider<int>(
      create: builder,
      child: const TextOf<int>(),
    ));
    await tester.pumpWidget(Provider<int>(
      create: builder,
      child: const TextOf<int>(),
    ));
    await tester.pumpWidget(Container());

    verify(builder(any)).called(1);
  });

  testWidgets('dispose', (tester) async {
    final dispose = Dispose();

    await tester.pumpWidget(
      Provider<int>(
        create: (_) => 42,
        dispose: dispose,
        child: const TextOf<int>(),
      ),
    );

    final context = tester
        .element(find.byWidgetPredicate((w) => w is InheritedProvider<int>));

    verifyZeroInteractions(dispose);
    await tester.pumpWidget(Container());
    verify(dispose(context, 42)).called(1);
  });
}
