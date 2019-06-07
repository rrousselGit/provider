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
  test('cloneWithChild works', () {
    final provider = Provider(
      builder: (_) => 42,
      child: Container(),
      key: const ValueKey(42),
    );

    final newChild = Container();
    final clone = provider.cloneWithChild(newChild);
    expect(clone.child, equals(newChild));
      // ignore: invalid_use_of_protected_member
    expect(clone.delegate, equals(provider.delegate));
    expect(clone.key, equals(provider.key));
    expect(provider.updateShouldNotify, equals(clone.updateShouldNotify));
  });
  test('asserts', () {
    expect(
      () => Provider<dynamic>(builder: null, child: null),
      throwsAssertionError,
    );
    // don't throw
    Provider<dynamic>(builder: (_) => null, child: null);
  });

  testWidgets('calls builder only once', (tester) async {
    final builder = ValueBuilder();
    await tester.pumpWidget(Provider<int>(
      builder: builder,
      child: Container(),
    ));
    await tester.pumpWidget(Provider<int>(
      builder: builder,
      child: Container(),
    ));
    await tester.pumpWidget(Container());

    verify(builder(any)).called(1);
  });

  testWidgets('dispose', (tester) async {
    final dispose = Dispose();
    const key = ValueKey(42);

    await tester.pumpWidget(
      Provider<int>(
        key: key,
        builder: (_) => 42,
        dispose: dispose,
        child: Container(),
      ),
    );

    final context = tester.element(find.byKey(key));

    verifyZeroInteractions(dispose);
    await tester.pumpWidget(Container());
    verify(dispose(context, 42)).called(1);
  });
}
