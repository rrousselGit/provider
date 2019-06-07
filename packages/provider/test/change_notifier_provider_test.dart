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
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
    });
    test('works with MultiProvider #3', () {
      final provider = ChangeNotifierProvider<ChangeNotifier>(
        builder: (_) => ChangeNotifier(),
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
    testWidgets('works with null (builder)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>(
        builder: (_) => null,
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), null);
    });
    group('stateful constructor', () {
      testWidgets('called with context', (tester) async {
        final builder = ValueBuilderMock<ChangeNotifier>();
        final key = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider<ChangeNotifier>(
          key: key,
          builder: builder,
          child: Container(),
        ));
        verify(builder(key.currentContext)).called(1);
      });
      test('throws if builder is null', () {
        expect(
          // ignore: prefer_const_constructors
          () => ChangeNotifierProvider(
                builder: null,
              ),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider(
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
      final notifier = MockNotifier();
      final builder = ValueBuilderMock<ChangeNotifier>();
      when(builder(any)).thenReturn(notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        builder: builder,
        child: Container(),
      ));

      final context = findElementOfWidget<ChangeNotifierProvider>();

      verify(builder(context)).called(1);
      verifyNoMoreInteractions(builder);
      clearInteractions(notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        builder: builder,
        child: Container(),
      ));

      verifyNoMoreInteractions(builder);
      verifyNoMoreInteractions(notifier);
    });
    testWidgets('dispose called on unmount', (tester) async {
      final notifier = MockNotifier();
      final builder = ValueBuilderMock<ChangeNotifier>();
      when(builder(any)).thenReturn(notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        builder: builder,
        child: Container(),
      ));

      final context = findElementOfWidget<ChangeNotifierProvider>();

      verify(builder(context)).called(1);
      verifyNoMoreInteractions(builder);
      final listener = verify(notifier.addListener(captureAny)).captured.first
          as VoidCallback;
      clearInteractions(notifier);

      await tester.pumpWidget(Container());

      verifyInOrder([notifier.removeListener(listener), notifier.dispose()]);
      verifyNoMoreInteractions(builder);
      verifyNoMoreInteractions(notifier);
    });
    testWidgets('dispose can be null', (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        builder: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });
    testWidgets(
        'Changing from default to stateful constructor calls stateful builder',
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
        builder: (_) {
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
        'Changing from stateful to default constructor dispose correctly stateful notifier',
        (tester) async {
      final ChangeNotifier notifier = MockNotifier();
      var notifier2 = ChangeNotifier();
      final key = GlobalKey();

      await tester.pumpWidget(ChangeNotifierProvider(
        builder: (_) => notifier,
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
        builder: (_) => ChangeNotifier(),
        child: Container(),
      ));

      await tester.pumpWidget(Container());
    });
    testWidgets('changing notifier rebuilds descendants', (tester) async {
      final builder = BuilderMock();
      when(builder(any)).thenReturn(Container());

      var notifier = ChangeNotifier();
      Widget build() {
        return ChangeNotifierProvider.value(
          value: notifier,
          child: Builder(builder: (context) {
            Provider.of<ChangeNotifier>(context);
            return builder(context);
          }),
        );
      }

      await tester.pumpWidget(build());

      verify(builder(any)).called(1);

      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, true);

      var previousNotifier = notifier;
      notifier = ChangeNotifier();
      await tester.pumpWidget(build());

      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, true);
      // ignore: invalid_use_of_protected_member
      expect(previousNotifier.hasListeners, false);

      verify(builder(any)).called(1);

      await tester.pumpWidget(Container());

      // ignore: invalid_use_of_protected_member
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
      // ignore: invalid_use_of_protected_member
      notifier.notifyListeners();
      await Future<void>.value();
      await tester.pump();
      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), notifier);
    });
  });
}
