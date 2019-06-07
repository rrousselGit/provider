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
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
    });
    test('works with MultiProvider #3', () {
      final provider = ListenableProvider<ChangeNotifier>(
        builder: (_) => ChangeNotifier(),
        dispose: (_, n) {},
        child: Container(),
        key: const Key('42'),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
    });

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
    });
    testWidgets("don't listen again if listenable instance doesn't change",
        (tester) async {
      final listenable = MockNotifier();
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.value(
        value: listenable,
        child: Container(),
      ));
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.value(
        value: listenable,
        child: Container(),
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
        builder: (_) => null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    group('stateful constructor', () {
      testWidgets('called with context', (tester) async {
        final builder = ValueBuilderMock<ChangeNotifier>();
        final key = GlobalKey();

        await tester.pumpWidget(ListenableProvider<ChangeNotifier>(
          key: key,
          builder: builder,
          child: Container(),
        ));
        verify(builder(key.currentContext)).called(1);
      });
      test('throws if builder is null', () {
        expect(
          // ignore: prefer_const_constructors
          () => ListenableProvider(
                builder: null,
              ),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ListenableProvider(
          key: keyProvider,
          builder: (_) => ChangeNotifier(),
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
      final builder = ValueBuilderMock<Listenable>();
      when(builder(any)).thenReturn(listenable);

      await tester.pumpWidget(ListenableProvider(
        builder: builder,
        child: Container(),
      ));

      final context = findElementOfWidget<ListenableProvider>();

      verify(builder(context)).called(1);
      verifyNoMoreInteractions(builder);
      clearInteractions(listenable);

      await tester.pumpWidget(ListenableProvider(
        builder: builder,
        child: Container(),
      ));

      verifyNoMoreInteractions(builder);
      verifyNoMoreInteractions(listenable);
    });
    testWidgets('dispose called on unmount', (tester) async {
      final listenable = MockNotifier();
      final builder = ValueBuilderMock<Listenable>();
      final disposer = DisposerMock<Listenable>();
      when(builder(any)).thenReturn(listenable);

      await tester.pumpWidget(ListenableProvider(
        builder: builder,
        dispose: disposer,
        child: Container(),
      ));

      final context = findElementOfWidget<ListenableProvider>();

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
        builder: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });
    testWidgets(
        'Changing from default to stateful constructor calls stateful builder',
        (tester) async {
      final listenable = MockNotifier();
      var listenable2 = ChangeNotifier();
      final key = GlobalKey();
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.value(
        value: listenable,
        child: Container(),
      ));
      final listener = verify(listenable.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(listenable);

      await tester.pumpWidget(ListenableProvider<ChangeNotifier>(
        builder: (_) {
          return listenable2;
        },
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), listenable2);

      await tester.pumpWidget(Container());
      verify(listenable.removeListener(listener)).called(1);
      verifyNoMoreInteractions(listenable);
    });
    testWidgets(
        'Changing from stateful to default constructor dispose correctly stateful listenable',
        (tester) async {
      final ChangeNotifier listenable = MockNotifier();
      final disposer = DisposerMock<Listenable>();
      var listenable2 = ChangeNotifier();
      final key = GlobalKey();

      await tester.pumpWidget(ListenableProvider(
        builder: (_) => listenable,
        dispose: disposer,
        child: Container(),
      ));

      final context = findElementOfWidget<ListenableProvider<ChangeNotifier>>();

      final listener = verify(listenable.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(listenable);
      await tester.pumpWidget(ListenableProvider.value(
        value: listenable2,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), listenable2);

      await tester.pumpWidget(Container());

      verifyInOrder([
        listenable.removeListener(listener),
        disposer(context, listenable),
      ]);
      verifyNoMoreInteractions(listenable);
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

      // ignore: invalid_use_of_protected_member
      expect(listenable.hasListeners, true);

      var previousNotifier = listenable;
      listenable = ChangeNotifier();
      await tester.pumpWidget(build());

      // ignore: invalid_use_of_protected_member
      expect(listenable.hasListeners, true);
      // ignore: invalid_use_of_protected_member
      expect(previousNotifier.hasListeners, false);

      verify(builder(any)).called(1);

      await tester.pumpWidget(Container());

      // ignore: invalid_use_of_protected_member
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
      // ignore: invalid_use_of_protected_member
      listenable.notifyListeners();
      await Future<void>.value();
      await tester.pump();
      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);
    });
  });
}
