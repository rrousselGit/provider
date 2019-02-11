import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class _UseStreamMock extends Mock {
  AsyncSnapshot<T> call<T>(Stream<T> stream, {T initialData});
}

void main() {
  tearDown(() => useStreamSeam = useStream);
  group('StreamProvider', () {
    test('seam defaults to useStream', () {
      expect(useStreamSeam, useStream);
    });
    test('throws if stream is null', () {
      expect(
        () => StreamProvider<int>(
              stream: null,
            ),
        throwsAssertionError,
      );
    });
    testWidgets('calls and exposes value from seam', (tester) async {
      useStreamSeam = _UseStreamMock();

      final stream = const Stream<int>.empty();

      final keyChild = GlobalKey();

      when(useStreamSeam<int>(any))
          .thenReturn(const AsyncSnapshot.withData(ConnectionState.active, 42));

      await tester.pumpWidget(StreamProvider(
        stream: stream,
        child: Container(key: keyChild),
      ));

      verify(useStreamSeam(stream)).called(1);

      expect(StreamProvider.of<int>(keyChild.currentContext).data, 42);
    });
    testWidgets('pass down initialData', (tester) async {
      useStreamSeam = _UseStreamMock();

      final stream = const Stream<int>.empty();
      final keyChild = GlobalKey();

      await tester.pumpWidget(StreamProvider(
        stream: stream,
        initialData: 42,
        child: Container(key: keyChild),
      ));

      verify(useStreamSeam(stream, initialData: 42)).called(1);
    });
    testWidgets('exposes value throw both Provider.of and StreamProvider.of',
        (tester) async {
      final stream = const Stream<int>.empty();

      final keyChild = GlobalKey();

      await tester.pumpWidget(StreamProvider(
        stream: stream,
        child: Container(key: keyChild),
      ));

      expect(StreamProvider.of<int>(keyChild.currentContext).data, null);
      expect(
          Provider.of<AsyncSnapshot<int>>(keyChild.currentContext).data, null);
    });
    testWidgets('pass down key', (tester) async {
      final stream = const Stream<int>.empty();
      final keyProvider = GlobalKey();

      await tester.pumpWidget(StreamProvider(
        key: keyProvider,
        stream: stream,
        child: Container(),
      ));
      expect((keyProvider.currentWidget as StreamProvider).stream, stream);
    });
  });
}
