// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'common.dart';

void main() {
  group('ChangeNotifierProvider', () {
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      var notifier = ChangeNotifier();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notifier),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), notifier);
    });
    testWidgets(
      'asserts that the created notifier has no listener',
      (tester) async {
        final notifier = ValueNotifier(0)..addListener(() {});

        await tester.pumpWidget(ChangeNotifierProvider(
          create: (_) => notifier,
          child: Container(),
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );
    test('works with MultiProvider #2', () {
      final provider = ChangeNotifierProvider.value(
        key: const Key('42'),
        value: ChangeNotifier(),
        child: Container(),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      expect(clone.delegate, equals(provider.delegate));
    });
    test('works with MultiProvider #3', () {
      final provider = ChangeNotifierProvider<ChangeNotifier>(
        create: (_) => ChangeNotifier(),
        child: Container(),
        key: const Key('42'),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      expect(clone.delegate, equals(provider.delegate));
    });
    group('default constructor', () {
      testWidgets('pass down key', (tester) async {
        final notifier = ChangeNotifier();
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider.value(
          key: keyProvider,
          value: notifier,
          child: Container(),
        ));
        expect(
          keyProvider.currentWidget,
          isNotNull,
        );
      });
    });
    testWidgets('works with null (default)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>.value(
        value: null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    testWidgets('works with null (create)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>(
        create: (_) => null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    testWidgets(
      'changing the Listenable instance rebuilds dependents',
      (tester) async {
        final mockBuilder = MockConsumerBuilder<MockNotifier>();
        when(mockBuilder(any, any, any)).thenReturn(Container());
        final child = Consumer<MockNotifier>(builder: mockBuilder);

        final previousListenable = MockNotifier();
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: previousListenable,
          child: child,
        ));

        clearInteractions(mockBuilder);
        clearInteractions(previousListenable);

        final listenable = MockNotifier();
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: listenable,
          child: child,
        ));

        verify(previousListenable.removeListener(any)).called(1);
        verify(listenable.addListener(any)).called(1);
        verifyNoMoreInteractions(previousListenable);
        verifyNoMoreInteractions(listenable);

        final context = tester.element(find.byWidget(child));
        verify(mockBuilder(context, listenable, null));
      },
    );
    group('stateful constructor', () {
      testWidgets('called with context', (tester) async {
        final create = ValueBuilderMock<ChangeNotifier>();
        final key = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>(
          key: key,
          create: create,
          child: Container(),
        ));
        verify(create(key.currentContext)).called(1);
      });
      test('throws if create is null', () {
        expect(
          // ignore: prefer_const_constructors
          () => ChangeNotifierProvider(
            create: null,
          ),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider(
          key: keyProvider,
          create: (_) => ChangeNotifier(),
          child: Container(),
        ));
        expect(
          keyProvider.currentWidget,
          isNotNull,
        );
      });
    });
    testWidgets('stateful create called once', (tester) async {
      final notifier = MockNotifier();
      when(notifier.hasListeners).thenReturn(false);
      final create = ValueBuilderMock<ChangeNotifier>();
      when(create(any)).thenReturn(notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: create,
        child: Container(),
      ));

      final context = findElementOfWidget<ChangeNotifierProvider>();

      verify(create(context)).called(1);
      verifyNoMoreInteractions(create);
      clearInteractions(notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: create,
        child: Container(),
      ));

      verifyNoMoreInteractions(create);
      verifyNoMoreInteractions(notifier);
    });
    testWidgets('dispose called on unmount', (tester) async {
      final notifier = MockNotifier();
      when(notifier.hasListeners).thenReturn(false);
      final create = ValueBuilderMock<ChangeNotifier>();
      when(create(any)).thenReturn(notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: create,
        child: Container(),
      ));

      final context = findElementOfWidget<ChangeNotifierProvider>();

      verify(create(context)).called(1);
      verifyNoMoreInteractions(create);
      final listener = verify(notifier.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(notifier);

      await tester.pumpWidget(Container());

      verifyInOrder([notifier.removeListener(listener), notifier.dispose()]);
      verifyNoMoreInteractions(create);
      verifyNoMoreInteractions(notifier);
    });
    testWidgets('dispose can be null', (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });
    testWidgets(
        'Changing from default to stateful constructor calls stateful create',
        (tester) async {
      final notifier = MockNotifier();
      var notifier2 = ChangeNotifier();
      final key = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>.value(
        value: notifier,
        child: Container(),
      ));
      final listener = verify(notifier.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(notifier);

      await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>(
        create: (_) {
          return notifier2;
        },
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), notifier2);

      await tester.pumpWidget(Container());
      verify(notifier.removeListener(listener)).called(1);
      verifyNoMoreInteractions(notifier);
    });
    testWidgets(
        // ignore: lines_longer_than_80_chars
        'Changing from stateful to default constructor dispose correctly stateful notifier',
        (tester) async {
      final ChangeNotifier notifier = MockNotifier();
      when(notifier.hasListeners).thenReturn(false);
      var notifier2 = ChangeNotifier();
      final key = GlobalKey();

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => notifier,
        child: Container(),
      ));

      final listener = verify(notifier.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(notifier);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: notifier2,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), notifier2);

      await tester.pumpWidget(Container());

      verifyInOrder([
        notifier.removeListener(listener),
        notifier.dispose(),
      ]);
      verifyNoMoreInteractions(notifier);
    });
    testWidgets('dispose can be null', (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });
    testWidgets('changing notifier rebuilds descendants', (tester) async {
      final create = BuilderMock();
      when(create(any)).thenReturn(Container());

      var notifier = ChangeNotifier();
      Widget build() {
        return ChangeNotifierProvider.value(
          value: notifier,
          child: Builder(builder: (context) {
            Provider.of<ChangeNotifier>(context);
            return create(context);
          }),
        );
      }

      await tester.pumpWidget(build());

      verify(create(any)).called(1);

      expect(notifier.hasListeners, true);

      var previousNotifier = notifier;
      notifier = ChangeNotifier();
      await tester.pumpWidget(build());

      expect(notifier.hasListeners, true);
      expect(previousNotifier.hasListeners, false);

      verify(create(any)).called(1);

      await tester.pumpWidget(Container());

      expect(notifier.hasListeners, false);
    });
    testWidgets("rebuilding with the same provider don't rebuilds descendants",
        (tester) async {
      final notifier = ChangeNotifier();
      final keyChild = GlobalKey();
      final builder = BuilderMock();
      when(builder(any)).thenReturn(Container());

      final child = Builder(
        key: keyChild,
        builder: builder,
      );

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: notifier,
        child: child,
      ));

      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), notifier);

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: notifier,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), notifier);
    });
    testWidgets('notifylistener rebuilds descendants', (tester) async {
      final notifier = ChangeNotifier();
      final keyChild = GlobalKey();
      final builder = BuilderMock();
      when(builder(any)).thenReturn(Container());

      final child = Builder(
        key: keyChild,
        builder: (context) {
          // subscribe
          Provider.of<ChangeNotifier>(context);
          return builder(context);
        },
      );
      var changeNotifierProvider = ChangeNotifierProvider.value(
        value: notifier,
        child: child,
      );
      await tester.pumpWidget(changeNotifierProvider);

      clearInteractions(builder);
      notifier.notifyListeners();
      await Future<void>.value();
      await tester.pump();
      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), notifier);
    });
  });
}
