import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'common.dart';

class ValueNotifierMock<T> extends Mock implements ValueNotifier<T> {}

void main() {
  group('valueListenableProvider', () {
    testWidgets(
        'disposing ValueListenableProvider on a builder constructor disposes of the ValueNotifier',
        (tester) async {
      final mock = ValueNotifierMock<int>();
      await tester.pumpWidget(ValueListenableProvider<int>(
        builder: (_) => mock,
        child: Container(),
      ));

      final listener =
          verify(mock.addListener(captureAny)).captured.first as VoidCallback;

      clearInteractions(mock);
      await tester.pumpWidget(Container());
      verifyInOrder([
        mock.removeListener(listener),
        mock.dispose(),
      ]);
      verifyNoMoreInteractions(mock);
    });
    testWidgets('rebuilds when value change', (tester) async {
      final listenable = ValueNotifier(0);

      final child = Builder(
          builder: (context) => Text(Provider.of<int>(context).toString(),
              textDirection: TextDirection.ltr));

      await tester.pumpWidget(ValueListenableProvider.value(
        value: listenable,
        child: child,
      ));

      expect(find.text('0'), findsOneWidget);
      listenable.value++;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets("don't rebuild dependents by default", (tester) async {
      final builder = BuilderMock();
      when(builder(any)).thenAnswer((invocation) {
        final context = invocation.positionalArguments.first as BuildContext;
        Provider.of<int>(context);
        return Container();
      });

      final listenable = ValueNotifier(0);
      final child = Builder(builder: builder);

      await tester.pumpWidget(ValueListenableProvider.value(
        value: listenable,
        child: child,
      ));
      verify(builder(any)).called(1);

      await tester.pumpWidget(ValueListenableProvider.value(
        value: listenable,
        child: child,
      ));
      verifyNoMoreInteractions(builder);
    });

    testWidgets('pass keys', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(ValueListenableProvider.value(
        key: key,
        value: ValueNotifier(42),
        child: Container(),
      ));

      expect(key.currentWidget, isInstanceOf<ValueListenableProvider<int>>());
    });

    testWidgets("don't listen again if stream instance doesn't change",
        (tester) async {
      final valueNotifier = ValueNotifierMock<int>();
      await tester.pumpWidget(ValueListenableProvider.value(
        value: valueNotifier,
        child: Container(),
      ));
      await tester.pumpWidget(ValueListenableProvider.value(
        value: valueNotifier,
        child: Container(),
      ));

      verify(valueNotifier.addListener(any)).called(1);
      verify(valueNotifier.value);
      verifyNoMoreInteractions(valueNotifier);
    });
    testWidgets('pass updateShouldNotify', (tester) async {
      final shouldNotify = UpdateShouldNotifyMock<int>();
      when(shouldNotify(0, 1)).thenReturn(true);

      var notifier = ValueNotifier(0);
      await tester.pumpWidget(ValueListenableProvider.value(
        value: notifier,
        updateShouldNotify: shouldNotify,
        child: Container(),
      ));

      verifyZeroInteractions(shouldNotify);

      notifier.value++;
      await tester.pump();

      verify(shouldNotify(0, 1)).called(1);
      verifyNoMoreInteractions(shouldNotify);
    });

    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [ValueListenableProvider.value(value: ValueNotifier(42))],
        child: Container(key: key),
      ));

      expect(Provider.of<int>(key.currentContext), 42);
    });

    test('works with MultiProvider #2', () {
      final provider = ValueListenableProvider.value(
        key: const Key('42'),
        value: ValueNotifier<int>(42),
        child: Container(),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
    });
    test('works with MultiProvider #3', () {
      final provider = ValueListenableProvider<int>(
        builder: (_) => ValueNotifier<int>(42),
        child: Container(),
        key: const Key('42'),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      // ignore: invalid_use_of_protected_member
      expect(clone.delegate, equals(provider.delegate));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
    });
  });
}
