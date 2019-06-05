import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:mockito/mockito.dart';

import 'common.dart';

class Foo extends StatelessWidget {
  const Foo({Key key}) : this._(key: key);
  const Foo._({Key key, this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }

  Foo call(List<Widget> children) {
    return Foo._(key: key, children: children);
  }
}

void main() {
  group('ProxyProvider', () {
    testWidgets('report error to FlutterError', (tester) async {
      final originOnError = FlutterError.onError;
      var errorMock = FlutterErrorMock();
      FlutterError.onError = errorMock;

      final reactiveContext = ReactiveContextMock();
      final error = Error();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: 1),
          ProxyProvider<int, Counter>(
            reactiveContext: reactiveContext,
            builder: (_, __, ___) => throw error,
          ),
        ],
        child: Container(),
      ));
      FlutterError.onError = originOnError;

      final verifyDetails = verify(errorMock(captureAny))..called(1);
      final details = verifyDetails.captured.first as FlutterErrorDetails;

      expect(details.exception, equals(error));
      expect(details.library, equals('mobx_provider'));
      verifyInOrder([
        reactiveContext.startUntracked(),
        reactiveContext.endUntracked(any),
      ]);
    });
    testWidgets('disposes of the store', (tester) async {
      final store = Counter();
      final disposer = DisposerMock<Counter>();
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: 1),
          ProxyProvider<int, Counter>(
            key: key,
            builder: (_, __, ___) => store,
            dispose: disposer,
          ),
        ],
        child: Container(),
      ));

      verifyNoMoreInteractions(disposer);
      final context = key.currentContext;

      await tester.pumpWidget(Container());

      verify(disposer(context, store)).called(1);
      verifyNoMoreInteractions(disposer);
    });
    test('uses Proxy.debugCheckInvalidValueType', () {});
    test('pass updateShouldNotify', () {});
    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: 42),
          ProxyProvider<int, double>(builder: (c, a, p) => a.toDouble()),
        ],
        child: Container(key: key),
      ));

      expect(
        Provider.of<double>(key.currentContext),
        equals(42.0),
      );
    });
    test('works with MultiProvider #2', () {
      final provider = ProxyProvider<int, double>(
        key: const Key('42'),
        initialBuilder: (_) {},
        builder: (_, __, ___) {},
        updateShouldNotify: (_, __) {},
        dispose: (_, __) {},
        child: Container(),
      );
      var child2 = Container();
      final clone = provider.cloneWithChild(child2);

      expect(clone.child, equals(child2));
      expect(clone.key, equals(provider.key));
      expect(clone.initialBuilder, equals(provider.initialBuilder));
      expect(clone.builder, equals(provider.builder));
      expect(clone.updateShouldNotify, equals(provider.updateShouldNotify));
      expect(clone.reactiveContext, equals(provider.reactiveContext));
      expect(clone.dispose, equals(provider.dispose));
    });

    test('builder/initialbuilder called with proper arguments', () {});
    testWidgets('smoke test', (tester) async {
      var buildCount = 0;
      final child = Observer(builder: (context) {
        buildCount++;
        return Text(
          Provider.of<Counter>(context).value.toString(),
          textDirection: TextDirection.ltr,
        );
      });
      final store = Counter();

      final provider = ProxyProvider<int, Counter>(
        initialBuilder: (_) => store,
        builder: (_, value, model) => model..value = value,
      );

      await tester.pumpWidget(MultiProvider(
        providers: [Provider.value(value: 1), provider],
        child: child,
      ));

      expect(buildCount, equals(1));
      expect(store.value, equals(1));
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(MultiProvider(
        providers: [Provider.value(value: 2), provider],
        child: child,
      ));

      expect(store.value, equals(2));
      expect(buildCount, equals(2));
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(MultiProvider(
        providers: [Provider.value(value: 2), provider],
        child: child,
      ));

      expect(store.value, equals(2));
      expect(buildCount, equals(2));
      expect(find.text('2'), findsOneWidget);
    });
  });
}
