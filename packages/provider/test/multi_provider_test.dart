import 'package:flutter/widgets.dart' hide TypeMatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:provider/provider.dart';

Type _typeOf<T>() => T;

Matcher throwsProviderNotFound({Type widgetType, Type valueType}) {
  return throwsA(const TypeMatcher<ProviderNotFoundError>()
      .having((err) => err.valueType, 'valueType', valueType)
      .having((err) => err.widgetType, 'widgetType', widgetType));
}

void main() {
  group('MultiProvider', () {
    test('cloneWithChild works', () {
      final provider = MultiProvider(
        providers: [],
        child: Container(),
        key: const ValueKey(42),
      );

      final newChild = Container();
      final clone = provider.cloneWithChild(newChild);
      expect(clone.child, newChild);
      expect(clone.providers, provider.providers);
      expect(clone.key, provider.key);
    });
    test('throw if providers is null', () {
      expect(
        () => MultiProvider(providers: null, child: Container()),
        throwsAssertionError,
      );
    });

    testWidgets('MultiProvider with empty providers returns child',
        (tester) async {
      await tester.pumpWidget(const MultiProvider(
        providers: [],
        child: Text(
          'Foo',
          textDirection: TextDirection.ltr,
        ),
      ));

      expect(find.text('Foo'), findsOneWidget);
    });

    testWidgets('MultiProvider children can only access parent providers',
        (tester) async {
      final k1 = GlobalKey();
      final k2 = GlobalKey();
      final k3 = GlobalKey();
      final p1 = Provider.value(key: k1, value: 42);
      final p2 = Provider.value(key: k2, value: 'foo');
      final p3 = Provider.value(key: k3, value: 44.0);

      final keyChild = GlobalKey();
      await tester.pumpWidget(MultiProvider(
        providers: [p1, p2, p3],
        child: Text('Foo', key: keyChild, textDirection: TextDirection.ltr),
      ));

      expect(find.text('Foo'), findsOneWidget);

      // p1 cannot access to p1/p2/p3
      expect(
        () => Provider.of<int>(k1.currentContext),
        throwsProviderNotFound(
            valueType: int, widgetType: _typeOf<Provider<int>>()),
      );
      expect(
        () => Provider.of<String>(k1.currentContext),
        throwsProviderNotFound(
            valueType: String, widgetType: _typeOf<Provider<int>>()),
      );
      expect(
        () => Provider.of<double>(k1.currentContext),
        throwsProviderNotFound(
            valueType: double, widgetType: _typeOf<Provider<int>>()),
      );

      // p2 can access only p1
      expect(Provider.of<int>(k2.currentContext), 42);
      expect(
        () => Provider.of<String>(k2.currentContext),
        throwsProviderNotFound(
            valueType: String, widgetType: _typeOf<Provider<String>>()),
      );
      expect(
        () => Provider.of<double>(k2.currentContext),
        throwsProviderNotFound(
            valueType: double, widgetType: _typeOf<Provider<String>>()),
      );

      // p3 can access both p1 and p2
      expect(Provider.of<int>(k3.currentContext), 42);
      expect(Provider.of<String>(k3.currentContext), 'foo');
      expect(
        () => Provider.of<double>(k3.currentContext),
        throwsProviderNotFound(
            valueType: double, widgetType: _typeOf<Provider<double>>()),
      );

      // the child can access them all
      expect(Provider.of<int>(keyChild.currentContext), 42);
      expect(Provider.of<String>(keyChild.currentContext), 'foo');
      expect(Provider.of<double>(keyChild.currentContext), 44);
    });
  });
}
