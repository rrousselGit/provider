// ignore_for_file: unnecessary_lambdas
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void main() {
  group('BuildContext', () {
    testWidgets('context.select deeply compares maps', (tester) async {
      final notifier = ValueNotifier(<int, int>{});

      var buildCount = 0;
      final selector = MockSelector.identity<Map<int, int>>();
      final child = Builder(builder: (c) {
        buildCount++;
        c.select<Map<int, int>, Map<int, int>>((v) {
          return selector(v);
        });
        return Container();
      });

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: notifier,
          child: child,
        ),
      );

      expect(buildCount, 1);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);

      notifier.value = {0: 0, 1: 1};
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(2);
      verifyNoMoreInteractions(selector);

      notifier.value = {0: 0, 1: 1};
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);
    });
    testWidgets('context.select deeply compares lists', (tester) async {
      final notifier = ValueNotifier(<int>[]);

      var buildCount = 0;
      final selector = MockSelector.identity<List<int>>();
      final child = Builder(builder: (c) {
        buildCount++;
        c.select<List<int>, List<int>>((v) {
          return selector(v);
        });
        return Container();
      });

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: notifier,
          child: child,
        ),
      );

      expect(buildCount, 1);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);

      notifier.value = [0, 1];
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(2);
      verifyNoMoreInteractions(selector);

      notifier.value = [0, 1];
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);
    });
    testWidgets('context.select deeply compares iterables', (tester) async {
      final notifier = ValueNotifier<Iterable<int>>(<int>[]);

      var buildCount = 0;
      final selector = MockSelector.identity<Iterable<int>>();
      final child = Builder(builder: (c) {
        buildCount++;
        c.select<Iterable<int>, Iterable<int>>((v) {
          return selector(v);
        });
        return Container();
      });

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: notifier,
          child: child,
        ),
      );

      expect(buildCount, 1);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);

      notifier.value = [0, 1];
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(2);
      verifyNoMoreInteractions(selector);

      notifier.value = [0, 1];
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);
    });
    testWidgets('context.select deeply compares sets', (tester) async {
      final notifier = ValueNotifier<Set<int>>(<int>{});

      var buildCount = 0;
      final selector = MockSelector.identity<Set<int>>();
      final child = Builder(builder: (c) {
        buildCount++;
        c.select<Set<int>, Set<int>>((v) {
          return selector(v);
        });
        return Container();
      });

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: notifier,
          child: child,
        ),
      );

      expect(buildCount, 1);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);

      notifier.value = {0, 1};
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(2);
      verifyNoMoreInteractions(selector);

      notifier.value = {0, 1};
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier.value)).called(1);
      verifyNoMoreInteractions(selector);
    });
    testWidgets('context.read does not listen to value changes', (tester) async {
      final child = Builder(builder: (context) {
        final value = context.read<int>();
        return Text('$value', textDirection: TextDirection.ltr);
      });

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(find.text('42'), findsOneWidget);

      await tester.pumpWidget(
        Provider.value(
          value: 24,
          child: child,
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });
    testWidgets('context.watch listens to value changes', (tester) async {
      final child = Builder(builder: (context) {
        final value = context.watch<int>();
        return Text('$value', textDirection: TextDirection.ltr);
      });

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(find.text('42'), findsOneWidget);

      await tester.pumpWidget(
        Provider.value(
          value: 24,
          child: child,
        ),
      );

      expect(find.text('24'), findsOneWidget);
    });
  });
}

class MockSelector<T, R> extends Mock {
  static MockSelector<T, T> identity<T>() {
    final res = MockSelector<T, T>();
    when(res(any)).thenAnswer((i) {
      return i.positionalArguments.first as T;
    });
    return res;
  }

  R call(T v);
}
