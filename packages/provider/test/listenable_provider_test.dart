// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'common.dart';

void main() {
  group('ListenableProvider', () {
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      var listenable = ChangeNotifier();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ListenableProvider.value(value: listenable),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), listenable);
    });
    testWidgets(
      'asserts that the created notifier has no listener',
      (tester) async {
        final notifier = ValueNotifier(0)..addListener(() {});

        await tester.pumpWidget(ListenableProvider(
          create: (_) => notifier,
          child: const TextOf<ValueNotifier<int>>(),
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );
    test('works with MultiProvider #2', () {
      final provider = ListenableProvider.value(
        key: const Key('42'),
        value: ChangeNotifier(),
        child: Container(),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      // expect(clone.delegate, equals(provider.delegate));
    }, skip: true);
    test('works with MultiProvider #3', () {
      final provider = ListenableProvider<ChangeNotifier>(
        create: (_) => ChangeNotifier(),
        dispose: (_, n) {},
        child: Container(),
        key: const Key('42'),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      // expect(clone.delegate, equals(provider.delegate));
    }, skip: true);

    group('value constructor', () {
      testWidgets('pass down key', (tester) async {
        final listenable = ChangeNotifier();
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ListenableProvider.value(
          key: keyProvider,
          value: listenable,
          child: Container(),
        ));
        expect(
          keyProvider.currentWidget,
          isNotNull,
        );
      });
      testWidgets(
        'changing the Listenable instance rebuilds dependents',
        (tester) async {
          final mockBuilder = MockConsumerBuilder<MockNotifier>();
          when(mockBuilder(any, any, any)).thenReturn(Container());
          final child = Consumer<MockNotifier>(builder: mockBuilder);

          final previousListenable = MockNotifier();
          await tester.pumpWidget(ListenableProvider.value(
            value: previousListenable,
            child: child,
          ));

          clearInteractions(mockBuilder);
          clearInteractions(previousListenable);

          final listenable = MockNotifier();
          await tester.pumpWidget(ListenableProvider.value(
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
    }, skip: true);
    testWidgets("don't listen again if listenable instance doesn't change",
        (tester) async {
      final listenable = MockNotifier();
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.value(
        value: listenable,
        child: const TextOf<ChangeNotifier>(),
      ));
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.value(
        value: listenable,
        child: const TextOf<ChangeNotifier>(),
      ));

      verify(listenable.addListener(any)).called(1);
      verifyNoMoreInteractions(listenable);
    });
    testWidgets('works with null (default)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.value(
        value: null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    testWidgets('works with null (builder)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>(
        create: (_) => null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    group('stateful constructor', () {
      testWidgets('called with context', (tester) async {
        final builder = InitialValueBuilderMock<ChangeNotifier>();

        await tester.pumpWidget(ListenableProvider<ChangeNotifier>(
          create: builder,
          child: const TextOf<ChangeNotifier>(),
        ));
        verify(builder(argThat(isNotNull))).called(1);
      });
      test('throws if builder is null', () {
        expect(
          () => ListenableProvider(create: null),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ListenableProvider(
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
    testWidgets('stateful builder called once', (tester) async {
      final listenable = MockNotifier();
      when(listenable.hasListeners).thenReturn(false);
      final builder = InitialValueBuilderMock<Listenable>();
      when(builder(any)).thenReturn(listenable);

      await tester.pumpWidget(ListenableProvider(
        create: builder,
        child: const TextOf<Listenable>(),
      ));

      verify(builder(argThat(isNotNull))).called(1);
      verifyNoMoreInteractions(builder);
      clearInteractions(listenable);

      await tester.pumpWidget(ListenableProvider(
        create: builder,
        child: Container(),
      ));

      verifyNoMoreInteractions(builder);
      verifyNoMoreInteractions(listenable);
    });
    testWidgets('dispose called on unmount', (tester) async {
      final listenable = MockNotifier();
      when(listenable.hasListeners).thenReturn(false);
      final builder = InitialValueBuilderMock<Listenable>();
      final disposer = DisposerMock<Listenable>();
      when(builder(any)).thenReturn(listenable);

      await tester.pumpWidget(ListenableProvider(
        create: builder,
        dispose: disposer,
        child: const TextOf<Listenable>(),
      ));

      final context = findElementOfWidget<InheritedProvider<Listenable>>();

      verify(builder(context)).called(1);
      verifyNoMoreInteractions(builder);
      final listener = verify(listenable.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(listenable);

      await tester.pumpWidget(Container());

      verifyInOrder([
        listenable.removeListener(listener),
        disposer(context, listenable),
      ]);
      verifyNoMoreInteractions(builder);
      verifyNoMoreInteractions(listenable);
    });
    testWidgets('dispose can be null', (tester) async {
      await tester.pumpWidget(ListenableProvider(
        create: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });

    testWidgets('changing listenable rebuilds descendants', (tester) async {
      final builder = BuilderMock();
      when(builder(any)).thenReturn(Container());

      var listenable = ChangeNotifier();
      Widget build() {
        return ListenableProvider.value(
          value: listenable,
          child: Builder(builder: (context) {
            Provider.of<ChangeNotifier>(context);
            return builder(context);
          }),
        );
      }

      await tester.pumpWidget(build());

      verify(builder(any)).called(1);

      expect(listenable.hasListeners, true);

      var previousNotifier = listenable;
      listenable = ChangeNotifier();

      await tester.pumpWidget(build());

      expect(listenable.hasListeners, true);
      expect(previousNotifier.hasListeners, false);

      verify(builder(any)).called(1);

      await tester.pumpWidget(Container());

      expect(listenable.hasListeners, false);
    });
    testWidgets("rebuilding with the same provider don't rebuilds descendants",
        (tester) async {
      final listenable = ChangeNotifier();
      final keyChild = GlobalKey();
      final builder = BuilderMock();
      when(builder(any)).thenReturn(Container());

      final child = Builder(
        key: keyChild,
        builder: builder,
      );

      await tester.pumpWidget(ListenableProvider.value(
        value: listenable,
        child: child,
      ));

      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);

      await tester.pumpWidget(ListenableProvider.value(
        value: listenable,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);

      listenable.notifyListeners();
      await tester.pump();

      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);

      await tester.pumpWidget(ListenableProvider.value(
        value: listenable,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);

      await tester.pumpWidget(ListenableProvider.value(
        value: listenable,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);
    });
    testWidgets('notifylistener rebuilds descendants', (tester) async {
      final listenable = ChangeNotifier();
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
      var changeNotifierProvider = ListenableProvider.value(
        value: listenable,
        child: child,
      );
      await tester.pumpWidget(changeNotifierProvider);

      clearInteractions(builder);
      listenable.notifyListeners();
      await Future<void>.value();
      await tester.pump();
      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);
    });
  });
}
