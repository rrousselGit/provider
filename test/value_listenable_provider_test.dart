import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class _UseValueListenableMock extends Mock {
  T call<T>(ValueListenable<T> valueListenable);
}

void main() {
  tearDown(() => useValueListenableSeam = useValueListenable);
  group('ValueListenableProvider', () {
    test('seam defaults to useValueListenable', () {
      expect(useValueListenableSeam, useValueListenable);
    });
    test('throws if valueListenable is null', () {
      expect(
        () => ValueListenableProvider<int>(valueListenable: null),
        throwsAssertionError,
      );
    });
    testWidgets('calls and exposes value from seam', (tester) async {
      useValueListenableSeam = _UseValueListenableMock();

      final valueListenable = ValueNotifier<int>(0);
      final keyChild = GlobalKey();

      when(useValueListenableSeam(valueListenable)).thenReturn(42);

      await tester.pumpWidget(ValueListenableProvider(
        valueListenable: valueListenable,
        child: Container(key: keyChild),
      ));

      verify(useValueListenableSeam(valueListenable)).called(1);

      expect(Provider.of<int>(keyChild.currentContext), 42);
    });

    testWidgets('pass down key', (tester) async {
      final valueListenable = ValueNotifier<int>(0);
      final keyProvider = GlobalKey();

      await tester.pumpWidget(ValueListenableProvider(
        key: keyProvider,
        valueListenable: valueListenable,
        child: Container(),
      ));
      expect(
        (keyProvider.currentWidget as ValueListenableProvider).valueListenable,
        valueListenable,
      );
    });
  });
}
