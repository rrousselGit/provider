import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

class _BuilderMock extends Mock {
  Widget call(BuildContext context);
}

void main() {
  group('ChangeNotifierProvider', () {
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      var notifier = ChangeNotifier();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(notifier: notifier),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<ChangeNotifier>(key.currentContext), notifier);
    });
    group('default constructor', () {
      test('throws if notifier is null', () {
        expect(
          // ignore: prefer_const_constructors
          () => ChangeNotifierProvider(
                notifier: null,
              ),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final notifier = ChangeNotifier();
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider(
          key: keyProvider,
          notifier: notifier,
          child: Container(),
        ));
        expect(
          keyProvider.currentWidget,
          isNotNull,
        );
      });
    });
    group('stateful constructor', () {
      test('throws if builder is null', () {
        expect(
          // ignore: prefer_const_constructors
          () => ChangeNotifierProvider.stateful(
                builder: null,
              ),
          throwsAssertionError,
        );
      });
      testWidgets('pass down key', (tester) async {
        final keyProvider = GlobalKey();

        await tester.pumpWidget(ChangeNotifierProvider.stateful(
          key: keyProvider,
          builder: () => ChangeNotifier(),
          child: Container(),
        ));
        expect(
          keyProvider.currentWidget,
          isNotNull,
        );
      });
    });
    testWidgets('builder called once', (tester) async {
      // TODO:
    });
    testWidgets('dispose called on unmount', (tester) async {
      // TODO:
    });
    testWidgets(
        'Changing from stateful to default constructor dispose correctly notifier from stateful',
        (tester) async {
      // TODO:
    });
    testWidgets('Changing from default to stateful constructor calls builder',
        (tester) async {
      // TODO:
    });
    testWidgets('changing notifier rebuilds descendants', (tester) async {
      final builder = _BuilderMock();
      when(builder(any)).thenReturn(Container());

      var notifier = ChangeNotifier();
      Widget build() {
        return ChangeNotifierProvider(
          notifier: notifier,
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
      final builder = _BuilderMock();
      when(builder(any)).thenReturn(Container());

      final child = Builder(
        key: keyChild,
        builder: builder,
      );

      await tester.pumpWidget(ChangeNotifierProvider(
        notifier: notifier,
        child: child,
      ));

      verify(builder(any)).called(1);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), notifier);

      await tester.pumpWidget(ChangeNotifierProvider(
        notifier: notifier,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
      expect(Provider.of<ChangeNotifier>(keyChild.currentContext), notifier);
    });
    testWidgets('notifylistener rebuilds descendants', (tester) async {
      final notifier = ChangeNotifier();
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
      var changeNotifierProvider = ChangeNotifierProvider(
        notifier: notifier,
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
