import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';
import 'package:flutter/foundation.dart';

import 'common.dart';

class _ValueBuilderMock<T> extends Mock {
  T call(BuildContext context);
}

class DisposerMock<T> extends Mock {
  void call(BuildContext context, T value);
}

class MockNotifier extends Mock implements ChangeNotifier {}

class _BuilderMock extends Mock {
  Widget call(BuildContext context);
}

void main() {
  group('ListenableProvider', () {
    test('debugFillProperties', () {
      final provider = ListenableProvider(listenable: null, child: Container());
      final builder = DiagnosticPropertiesBuilder();

      provider.debugFillProperties(builder);
      expect(
        builder.properties
            .any((d) => d.name == 'listenable' && d.value == null),
        true,
      );
    });
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      var listenable = ChangeNotifier();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ListenableProvider(listenable: listenable),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), listenable);
    });
    group('default constructor', () {
      testWidgets('pass down key', (tester) async {
        final listenable = ChangeNotifier();
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ListenableProvider(
          key: keyProvider,
          listenable: listenable,
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
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>(
        listenable: null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    testWidgets('works with null (builder)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.builder(
        builder: (_) => null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    group('stateful constructor', () {
      testWidgets('called with context', (tester) async {
        final builder = _ValueBuilderMock<ChangeNotifier>();
        final key = GlobalKey();

        await tester.pumpWidget(ListenableProvider<ChangeNotifier>.builder(
          key: key,
          builder: builder,
          child: Container(),
        ));
        verify(builder(key.currentContext)).called(1);
      });
      test('throws if builder is null', () {
        expect(
          // ignore: prefer_const_constructors
          () => ListenableProvider.builder(
                builder: null,
              ),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ListenableProvider.builder(
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
      final builder = _ValueBuilderMock<Listenable>();
      when(builder(any)).thenReturn(listenable);

      await tester.pumpWidget(ListenableProvider.builder(
        builder: builder,
        child: Container(),
      ));

      final context = findElementOfWidget<ListenableProvider>();

      verify(builder(context)).called(1);
      verifyNoMoreInteractions(builder);
      clearInteractions(listenable);

      await tester.pumpWidget(ListenableProvider.builder(
        builder: builder,
        child: Container(),
      ));

      verifyNoMoreInteractions(builder);
      verifyNoMoreInteractions(listenable);
    });
    testWidgets('dispose called on unmount', (tester) async {
      final listenable = MockNotifier();
      final builder = _ValueBuilderMock<Listenable>();
      final disposer = DisposerMock<Listenable>();
      when(builder(any)).thenReturn(listenable);

      await tester.pumpWidget(ListenableProvider.builder(
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
      await tester.pumpWidget(ListenableProvider.builder(
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
      await tester.pumpWidget(ListenableProvider<ChangeNotifier>(
        listenable: listenable,
        child: Container(),
      ));
      final listener = verify(listenable.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(listenable);

      await tester.pumpWidget(ListenableProvider<ChangeNotifier>.builder(
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

      await tester.pumpWidget(ListenableProvider.builder(
        builder: (_) => listenable,
        dispose: disposer,
        child: Container(),
      ));

      final context = findElementOfWidget<ListenableProvider<ChangeNotifier>>();

      final listener = verify(listenable.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(listenable);
      await tester.pumpWidget(ListenableProvider(
        listenable: listenable2,
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
    testWidgets('dispose can be null', (tester) async {
      await tester.pumpWidget(ListenableProvider.builder(
        builder: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });
    testWidgets('changing listenable rebuilds descendants', (tester) async {
      final builder = _BuilderMock();
      when(builder(any)).thenReturn(Container());

      var listenable = ChangeNotifier();
      Widget build() {
        return ListenableProvider(
          listenable: listenable,
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
      final builder = _BuilderMock();
      when(builder(any)).thenReturn(Container());

      final child = Builder(
        key: keyChild,
        builder: builder,
      );

      await tester.pumpWidget(ListenableProvider(
        listenable: listenable,
        child: child,
      ));

      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);

      await tester.pumpWidget(ListenableProvider(
        listenable: listenable,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), listenable);
    });
    testWidgets('notifylistener rebuilds descendants', (tester) async {
      final listenable = ChangeNotifier();
      final keyChild = GlobalKey();
      final builder = _BuilderMock();
      when(builder(any)).thenReturn(Container());

      final child = Builder(
        key: keyChild,
        builder: (context) {
          // subscribe
          Provider.of<ChangeNotifier>(context);
          return builder(context);
        },
      );
      var changeNotifierProvider = ListenableProvider(
        listenable: listenable,
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
