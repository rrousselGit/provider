import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('HookProvider', () {
    test('cloneWithChild works', () {
      final provider = HookProvider(
        hook: () => 42,
        child: Container(),
        key: const ValueKey(42),
        updateShouldNotify: (int _, int __) => true,
      );

      final newChild = Container();
      final clone = provider.cloneWithChild(newChild);
      expect(clone.child, newChild);
      expect(clone.hook, provider.hook);
      expect(clone.key, provider.key);
      expect(provider.updateShouldNotify, clone.updateShouldNotify);
    });

    testWidgets('pass down value', (tester) async {
      ValueNotifier<int> state;
      await tester.pumpWidget(HookProvider(
        child: Container(),
        hook: () {
          state = useState(0);
          return state.value;
        },
      ));

      var provider = _findProvider(tester);

      expect(provider, isNotNull);
      expect(provider.value, 0);

      state.value++;

      await tester.pump();

      provider = _findProvider(tester);
      expect(provider, isNotNull);
      expect(provider.value, 1);
    });
    testWidgets('pass key', (tester) async {
      await tester.pumpWidget(HookProvider(
        key: const ObjectKey(42),
        child: Container(),
        hook: () {},
      ));

      final provider =
          tester.widget(find.byWidgetPredicate((w) => w is HookProvider));
      expect(provider.key, const ObjectKey(42));
    });
    testWidgets('pass child', (tester) async {
      final child = Container();
      await tester.pumpWidget(HookProvider(
        child: child,
        hook: () {},
      ));

      final provider =
          tester.widget(find.byWidgetPredicate((w) => w is HookProvider))
              as HookProvider;
      expect(provider.child, child);
    });
  });
}

Provider<int> _findProvider(WidgetTester tester) {
  return tester.firstWidget(find.byWidgetPredicate((w) => w is Provider))
      as Provider<int>;
}
