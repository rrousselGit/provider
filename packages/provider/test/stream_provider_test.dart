import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class ErrorBuilderMock<T> extends Mock {
  T call(BuildContext context, Object error);
}

class MockStreamController<T> extends Mock implements StreamController<T> {}

class MockStream<T> extends Mock implements Stream<T> {}

void main() {
  group('streamProvider', () {
    testWidgets('update when value change (default) ', (tester) async {
      final controller = StreamController<int>();
      final providerKey = GlobalKey();
      final childKey = GlobalKey();
      BuildContext context;

      await tester.pumpWidget(StreamProvider(
        key: providerKey,
        builder: (c) {
          context = c;
          return controller.stream;
        },
        child: Container(key: childKey),
      ));

      expect(context, equals(providerKey.currentContext));
      expect(Provider.of<int>(childKey.currentContext), null);

      controller.add(0);
      // adding to stream is asynchronous so we have to delay the pump
      await Future.microtask(tester.pump);

      expect(Provider.of<int>(childKey.currentContext), 0);
    });
    testWidgets('update when value change (.value)', (tester) async {
      final controller = StreamController<int>();
      final key = GlobalKey();

      await tester.pumpWidget(StreamProvider.value(
        value: controller.stream,
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), null);

      controller.add(0);
      // adding to stream is asynchronous so we have to delay the pump
      await Future.microtask(tester.pump);

      expect(Provider.of<int>(key.currentContext), 0);
    });

    testWidgets("don't notify descendants when rebuilding by default",
        (tester) async {
      final controller = StreamController<int>();

      final builder = BuilderMock();
      when(builder(any)).thenAnswer((invocation) {
        final context = invocation.positionalArguments.first as BuildContext;
        Provider.of<int>(context);
        return Container();
      });
      final child = Builder(builder: builder);

      await tester.pumpWidget(StreamProvider.value(
        value: controller.stream,
        child: child,
      ));

      await tester.pumpWidget(StreamProvider.value(
        value: controller.stream,
        child: child,
      ));

      verify(builder(any)).called(1);
    });

    testWidgets('pass down keys', (tester) async {
      final controller = StreamController<int>();
      final key = GlobalKey();

      await tester.pumpWidget(StreamProvider.value(
        key: key,
        value: controller.stream,
        child: Container(),
      ));

      expect(key.currentWidget, isInstanceOf<StreamProvider>());
    });

    testWidgets('pass updateShouldNotify', (tester) async {
      final shouldNotify = UpdateShouldNotifyMock<int>();
      when(shouldNotify(null, 1)).thenReturn(true);

      final controller = StreamController<int>();
      await tester.pumpWidget(StreamProvider.value(
        value: controller.stream,
        updateShouldNotify: shouldNotify,
        child: Container(),
      ));

      verifyZeroInteractions(shouldNotify);

      controller.add(1);
      // adding to stream is asynchronous so we have to delay the pump
      await Future.microtask(tester.pump);

      verify(shouldNotify(null, 1)).called(1);
      verifyNoMoreInteractions(shouldNotify);
    });

    testWidgets("don't listen again if stream instance doesn't change",
        (tester) async {
      final stream = MockStream<int>();
      await tester.pumpWidget(StreamProvider.value(
        value: stream,
        child: Container(),
      ));
      await tester.pumpWidget(StreamProvider.value(
        value: stream,
        child: Container(),
      ));

      verify(
        stream.listen(any,
            onError: anyNamed('onError'),
            onDone: anyNamed('onDone'),
            cancelOnError: anyNamed('cancelOnError')),
      ).called(1);
      verifyNoMoreInteractions(stream);
    });

    testWidgets('throws if stream has error and catchError is missing',
        (tester) async {
      final controller = StreamController<int>();

      await tester.pumpWidget(StreamProvider.value(
        value: controller.stream,
        child: Container(),
      ));

      controller.addError(42);

      await Future.microtask(tester.pump);
      final exception = tester.takeException() as Object;
      expect(exception, isFlutterError);
      expect(exception.toString(), equals('''
An exception was throw by _ControllerStream<int> listened by
StreamProvider<int>, but no `catchError` was provided.

Exception:
42
'''));
    });
    testWidgets('calls catchError if present and stream has error',
        (tester) async {
      final controller = StreamController<int>();
      final key = GlobalKey();
      final catchError = ErrorBuilderMock<int>();
      when(catchError(any, 42)).thenReturn(0);

      await tester.pumpWidget(StreamProvider.value(
        value: controller.stream,
        catchError: catchError,
        child: Container(key: key),
      ));

      controller.addError(42);

      await Future.microtask(tester.pump);

      expect(Provider.of<int>(key.currentContext), 0);

      final context = findElementOfWidget<StreamProvider<int>>();

      verify(catchError(context, 42));
    });

    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [
          StreamProvider<int>.value(value: const Stream<int>.empty()),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), null);
    });
    test('works with MultiProvider #2', () {
      final provider = StreamProvider<int>.value(
        value: const Stream<int>.empty(),
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
      final provider = StreamProvider<int>.controller(
        builder: (_) => StreamController<int>(),
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
      await tester.pumpWidget(StreamProvider<int>.value(
        value: null,
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), null);
    });

    group('stateful constructor', () {
      test('crashes if builder is null', () {
        expect(
          () => StreamProvider<int>.controller(builder: null),
          throwsAssertionError,
        );
      });

      testWidgets('works with null', (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(StreamProvider<int>.controller(
          builder: (_) => null,
          child: Container(key: key),
        ));

        expect(Provider.of<int>(key.currentContext), null);

        await tester.pumpWidget(Container());
      });

      testWidgets('create and dispose stream with builder', (tester) async {
        final realController = StreamController<int>();
        final controller = MockStreamController<int>();
        when(controller.stream).thenAnswer((_) => realController.stream);

        final builder = ValueBuilderMock<StreamController<int>>();
        when(builder(any)).thenReturn(controller);

        await tester.pumpWidget(StreamProvider<int>.controller(
          builder: builder,
          child: Container(),
        ));

        final context = findElementOfWidget<StreamProvider<int>>();

        verify(builder(context)).called(1);
        clearInteractions(controller);

        // extra build to see if builder isn't called again
        await tester.pumpWidget(StreamProvider<int>.controller(
          builder: builder,
          child: Container(),
        ));

        await tester.pumpWidget(Container());

        verifyNoMoreInteractions(builder);
        verify(controller.close());
      });

      testWidgets('pass updateShouldNotify', (tester) async {
        final shouldNotify = UpdateShouldNotifyMock<int>();
        when(shouldNotify(null, 1)).thenReturn(true);

        var controller = StreamController<int>();
        await tester.pumpWidget(StreamProvider<int>.controller(
          builder: (_) => controller,
          updateShouldNotify: shouldNotify,
          child: Container(),
        ));

        verifyZeroInteractions(shouldNotify);

        controller.add(1);
        // adding to stream is asynchronous so we have to delay the pump
        await Future.microtask(tester.pump);

        verify(shouldNotify(null, 1)).called(1);
        verifyNoMoreInteractions(shouldNotify);
      });

      testWidgets(
          'Changing from default to stateful constructor calls stateful builder',
          (tester) async {
        final key = GlobalKey();
        final controller = StreamController<int>();
        await tester.pumpWidget(StreamProvider<int>.value(
          value: controller.stream,
          child: Container(),
        ));

        final realController2 = StreamController<int>();
        final controller2 = MockStreamController<int>();
        when(controller2.stream).thenAnswer((_) => realController2.stream);

        realController2.add(42);

        await tester.pumpWidget(StreamProvider<int>.controller(
          builder: (_) => controller2,
          child: Container(key: key),
        ));

        await tester.pump();

        expect(Provider.of<int>(key.currentContext), 42);

        await tester.pumpWidget(Container());

        verify(controller2.close()).called(1);
      });
      testWidgets(
          'Changing from stateful to default constructor dispose correctly stateful stream',
          (tester) async {
        final realController = StreamController<int>();
        final controller = MockStreamController<int>();
        when(controller.stream).thenAnswer((_) => realController.stream);

        final key = GlobalKey();

        await tester.pumpWidget(StreamProvider<int>.controller(
          builder: (_) => controller,
          child: Container(),
        ));

        await tester.pumpWidget(StreamProvider.value(
          value: Stream<int>.fromIterable([42]),
          child: Container(key: key),
        ));
        await tester.pump();

        expect(Provider.of<int>(key.currentContext), 42);

        await tester.pumpWidget(Container());

        verify(controller.close()).called(1);
      });
    });
  });
}
