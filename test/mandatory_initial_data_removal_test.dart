import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'common.dart';

void main() {
  group('Test group', () {
    testWidgets('Future provider works', (tester) async {
      await tester.pumpWidget(
        FutureProvider<int?>.value(
          value: Future.value(42),
          child: TextOf<int?>(),
        ),
      );

      expect(find.text('null'), findsOneWidget);

      await Future.microtask(tester.pump);

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('Stream provider works', (tester) async {
      await tester.pumpWidget(
        StreamProvider<int?>.value(
          value: Stream.value(42),
          child: TextOf<int?>(),
        ),
      );

      expect(find.text('null'), findsOneWidget);

      await Future.microtask(tester.pump);

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('calls catchError if present and stream has error',
        (tester) async {
      final controller = StreamController<int>(sync: true);
      final catchError = ErrorBuilderMock<int>(0);
      when(catchError(any, 42)).thenReturn(42);

      await tester.pumpWidget(
        StreamProvider<int?>.value(
          value: controller.stream,
          catchError: catchError,
          child: TextOf<int?>(),
        ),
      );

      expect(find.text('null'), findsOneWidget);

      controller.addError(42);

      await Future.microtask(tester.pump);

      expect(find.text('42'), findsOneWidget);
      verify(catchError(argThat(isNotNull), 42)).called(1);
      verifyNoMoreInteractions(catchError);

      // ignore: unawaited_futures
      controller.close();
    });
  });
}

class ErrorBuilderMock<T> extends Mock {
  ErrorBuilderMock(this.fallback);

  final T fallback;

  T call(BuildContext? context, Object? error) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, error]),
      returnValue: fallback,
      returnValueForMissingStub: fallback,
    ) as T;
  }
}
