import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mobx/mobx.dart' show Store;
import 'package:provider/provider.dart';

class StoreMock extends Mock implements Store {}

void main() {
  testWidgets('updateShouldNotify', (tester) async {
    final updateShouldNotify = UpdateShouldNotifyMock<StoreMock>();
    when(updateShouldNotify(any, any)).thenAnswer((invocation) {
      return invocation.positionalArguments.first !=
          invocation.positionalArguments.last;
    });

    var store = StoreMock();

    var buildCount = 0;
    final child = Builder(builder: (context) {
      Provider.of<StoreMock>(context);
      buildCount++;
      return Container();
    });

    await tester.pumpWidget(StoreProvider.value(
      value: store,
      updateShouldNotify: updateShouldNotify,
      child: child,
    ));

    verifyZeroInteractions(updateShouldNotify);
    expect(buildCount, equals(1));

    await tester.pumpWidget(StoreProvider.value(
      value: store,
      updateShouldNotify: updateShouldNotify,
      child: child,
    ));

    expect(buildCount, equals(1));
    verify(updateShouldNotify(store, store)).called(1);
    verifyNoMoreInteractions(updateShouldNotify);

    var store2 = StoreMock();
    await tester.pumpWidget(StoreProvider.value(
      value: store2,
      updateShouldNotify: updateShouldNotify,
      child: child,
    ));

    verify(updateShouldNotify(store, store2)).called(1);
    verifyNoMoreInteractions(updateShouldNotify);
    expect(buildCount, equals(2));
  });
  group('StoreProvider', () {
    testWidgets('default ctor creates and dispose stores', (tester) async {
      var store = StoreMock();
      final builder = BuilderMock<StoreMock>();
      final key = GlobalKey();

      when(builder(any)).thenReturn(store);

      await tester.pumpWidget(StoreProvider(
        builder: builder,
        child: Container(key: key),
      ));

      expect(Provider.of<StoreMock>(key.currentContext), equals(store));

      await tester.pumpWidget(StoreProvider(
        builder: builder,
        child: Container(key: key),
      ));

      verifyZeroInteractions(store);

      expect(Provider.of<StoreMock>(key.currentContext), equals(store));

      await tester.pumpWidget(Container());

      verify(store.dispose()).called(1);
      verifyNoMoreInteractions(store);
    });
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();
      var store = StoreMock();

      await tester.pumpWidget(MultiProvider(
        providers: [
          StoreProvider.value(value: store),
        ],
        child: Container(key: key),
      ));

      expect(Provider.of<StoreMock>(key.currentContext), store);
    });
    test('works with MultiProvider #2', () {
      final provider = StoreProvider<Store>.value(
        key: const Key('42'),
        value: StoreMock(),
        child: Container(),
        updateShouldNotify: (_, __) {},
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
      expect(clone.delegate, equals(provider.delegate));
    });
    test('works with MultiProvider #3', () {
      final provider = StoreProvider<StoreMock>(
        builder: (_) => StoreMock(),
        child: Container(),
        key: const Key('42'),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
      expect(clone.delegate, equals(provider.delegate));
    });
  });
}

class BuilderMock<T> extends Mock {
  T call(BuildContext context);
}

class UpdateShouldNotifyMock<T> extends Mock {
  bool call(T t1, T t2);
}
