import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

// tests forked from stream_provider_test.dart
// by replacing Stream with Future and StreamController with Completer

class ErrorBuilderMock<T> extends Mock {
  T call(BuildContext context, Object error);
}

class MockFuture<T> extends Mock implements Future<T> {}

void main() {
  group('FutureProvider', () {
    testWidgets('update when value change', (tester) async {
      final completer = Completer<int>();
      final key = GlobalKey();

      await tester.pumpWidget(FutureProvider.value(
        value: completer.future,
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), null);

      completer.complete(0);
      // futures are asynchronous so we have to delay the pump
      await Future.microtask(tester.pump);

      expect(Provider.of<int>(key.currentContext), 0);
    });

    testWidgets("don't notify descendants when rebuilding by default",
        (tester) async {
      final completer = Completer<int>();

      final builder = BuilderMock();
      when(builder(any)).thenAnswer((invocation) {
        final context = invocation.positionalArguments.first as BuildContext;
        Provider.of<int>(context);
        return Container();
      });
      final child = Builder(builder: builder);

      await tester.pumpWidget(FutureProvider.value(
        value: completer.future,
        child: child,
      ));

      await tester.pumpWidget(FutureProvider.value(
        value: completer.future,
        child: child,
      ));

      verify(builder(any)).called(1);
    });

    testWidgets('pass down keys', (tester) async {
      final completer = Completer<int>();
      final key = GlobalKey();

      await tester.pumpWidget(FutureProvider.value(
        key: key,
        value: completer.future,
        child: Container(),
      ));

      expect(key.currentWidget, isInstanceOf<FutureProvider>());
    });

    testWidgets('pass updateShouldNotify', (tester) async {
      final shouldNotify = UpdateShouldNotifyMock<int>();
      when(shouldNotify(null, 1)).thenReturn(true);

      final completer = Completer<int>();
      await tester.pumpWidget(FutureProvider.value(
        value: completer.future,
        updateShouldNotify: shouldNotify,
        child: Container(),
      ));

      verifyZeroInteractions(shouldNotify);

      completer.complete(1);
      // futures are asynchronous so we have to delay the pump
      await Future.microtask(tester.pump);

      verify(shouldNotify(null, 1)).called(1);
      verifyNoMoreInteractions(shouldNotify);
    });

    testWidgets("don't listen future again if it doesn't change",
        (tester) async {
      final future = MockFuture<int>();
      await tester.pumpWidget(FutureProvider.value(
        value: future,
        child: Container(),
      ));
      await tester.pumpWidget(FutureProvider.value(
        value: future,
        child: Container(),
      ));

      verify(future.then<void>(any, onError: anyNamed('onError'))).called(1);
      verifyNoMoreInteractions(future);
    });

    testWidgets('future emits error and catchError is missing', (tester) async {
      final completer = Completer<int>();

      await tester.pumpWidget(FutureProvider.value(
        value: completer.future,
        child: Container(),
      ));

      completer.completeError(42);

      await Future.microtask(tester.pump);
      final exception = tester.takeException() as Object;
      expect(exception, isFlutterError);
      expect(exception.toString(), equals('''
An exception was throw by Future<int> listened by
FutureProvider<int>, but no `catchError` was provided.

Exception:
42
'''));
    });
    testWidgets('calls catchError if future emits error', (tester) async {
      final completer = Completer<int>();
      final key = GlobalKey();
      final catchError = ErrorBuilderMock<int>();
      when(catchError(any, 42)).thenReturn(0);

      await tester.pumpWidget(FutureProvider.value(
        value: completer.future,
        catchError: catchError,
        child: Container(key: key),
      ));

      completer.completeError(42);

      await Future.microtask(tester.pump);

      expect(Provider.of<int>(key.currentContext), 0);

      final context = findElementOfWidget<FutureProvider<int>>();

      verify(catchError(context, 42));
    });

    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [
          FutureProvider<int>.value(value: Future<int>.value()),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), null);
    });
    test('works with MultiProvider #2', () {
      final provider = FutureProvider<int>.value(
        value: Future<int>.value(),
        initialData: 42,
        child: Container(),
        catchError: (_, __) => 42,
        key: const Key('42'),
        updateShouldNotify: (_, __) => true,
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
      expect(clone.key, equals(provider.key));
      expect(clone.initialData, equals(provider.initialData));
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
      expect(clone.catchError, equals(provider.catchError));
    });
    test('works with MultiProvider #3', () {
      final provider = FutureProvider<int>(
        builder: (_) => Future<int>.value(),
        initialData: 42,
        child: Container(),
        catchError: (_, __) => 42,
        key: const Key('42'),
        updateShouldNotify: (_, __) => true,
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
      expect(clone.key, equals(provider.key));
      expect(clone.initialData, equals(provider.initialData));
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
      expect(clone.catchError, equals(provider.catchError));
    });
    testWidgets('works with null', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(FutureProvider<int>.value(
        value: null,
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), null);
    });

    group('stateful constructor', () {
      test('crashes if builder is null', () {
        expect(
          () => FutureProvider<int>(builder: null),
          throwsAssertionError,
        );
      });

      testWidgets('works with null', (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(FutureProvider<int>(
          builder: (_) => null,
          child: Container(key: key),
        ));

        expect(Provider.of<int>(key.currentContext), null);

        await tester.pumpWidget(Container());
      });

      testWidgets('create future with builder', (tester) async {
        final completer = Completer<int>();

        final builder = ValueBuilderMock<Future<int>>();
        when(builder(any)).thenAnswer((_) => completer.future);

        await tester.pumpWidget(FutureProvider<int>(
          builder: builder,
          child: Container(),
        ));

        final context = findElementOfWidget<FutureProvider<int>>();

        verify(builder(context)).called(1);

        // extra build to see if builder isn't called again
        await tester.pumpWidget(FutureProvider<int>(
          builder: builder,
          child: Container(),
        ));

        await tester.pumpWidget(Container());

        verifyNoMoreInteractions(builder);
      });

      testWidgets('pass updateShouldNotify', (tester) async {
        final shouldNotify = UpdateShouldNotifyMock<int>();
        when(shouldNotify(null, 1)).thenReturn(true);

        var completer = Completer<int>();
        await tester.pumpWidget(FutureProvider<int>(
          builder: (_) => completer.future,
          updateShouldNotify: shouldNotify,
          child: Container(),
        ));

        verifyZeroInteractions(shouldNotify);

        completer.complete(1);
        // futures are asynchronous so we have to delay the pump
        await Future.microtask(tester.pump);

        verify(shouldNotify(null, 1)).called(1);
        verifyNoMoreInteractions(shouldNotify);
      });

      testWidgets(
          'Changing from default to stateful constructor calls stateful builder',
          (tester) async {
        final key = GlobalKey();
        final completer = Completer<int>();
        await tester.pumpWidget(FutureProvider<int>.value(
          value: completer.future,
          child: Container(),
        ));

        await tester.pumpWidget(FutureProvider<int>(
          builder: (_) => Future.value(42),
          child: Container(key: key),
        ));

        await tester.pump();

        expect(Provider.of<int>(key.currentContext), 42);

        await tester.pumpWidget(Container());
      });
      testWidgets('Changing from stateful to default constructor',
          (tester) async {
        await tester.pumpWidget(FutureProvider<int>(
          builder: (_) => Future.value(0),
          child: Container(),
        ));

        final key = GlobalKey();
        await tester.pumpWidget(FutureProvider.value(
          value: Future.value(1),
          child: Container(key: key),
        ));
        await tester.pump();

        expect(Provider.of<int>(key.currentContext), 1);
      });
    });
  });
}
