// ignore_for_file: unnecessary_lambdas
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void main() {
  group('BuildContext', () {
    testWidgets("don't call old selectors if the child rebuilds individually", (tester) async {
      final notifier = ValueNotifier(0);

      var buildCount = 0;
      final selector = MockSelector.identity<ValueNotifier<int>>();
      final child = Builder(builder: (c) {
        buildCount++;
        c.select<ValueNotifier<int>, ValueNotifier<int>>((v) {
          return selector(v);
        });
        return Container();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: notifier,
          child: child,
        ),
      );

      expect(buildCount, 1);
      verify(selector(notifier)).called(1);
      verifyNoMoreInteractions(selector);

      tester.element(find.byWidget(child)).markNeedsBuild();
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier)).called(1);
      verifyNoMoreInteractions(selector);

      notifier.notifyListeners();
      await tester.pump();

      expect(buildCount, 2);
      verify(selector(notifier)).called(1);
      verifyNoMoreInteractions(selector);
    });
    testWidgets('select throws if try to read dynamic', (tester) async {
      await tester.pumpWidget(
        Builder(builder: (c) {
          c.select<dynamic, dynamic>((dynamic i) => i);
          return Container();
        }),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('select throws ProviderNotFoundException', (tester) async {
      await tester.pumpWidget(
        Builder(builder: (c) {
          c.select((int i) => i);
          return Container();
        }),
      );

      expect(tester.takeException(), isA<ProviderNotFoundException>());
    });
    testWidgets('select throws if watch called inside the callback from build', (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: Builder(builder: (context) {
            context.select((int i) {
              context.watch<int>();
              return i;
            });
            return Container();
          }),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('select throws if read called inside the callback from build', (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: Builder(builder: (context) {
            context.select((int i) {
              context.read<int>();
              return i;
            });
            return Container();
          }),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('select throws if select called inside the callback from build', (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: Builder(builder: (context) {
            context.select((int i) {
              context.select((int i) => i);
              return i;
            });
            return Container();
          }),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('select throws if read called inside the callback on dependency change', (tester) async {
      var shouldCall = false;
      var child = Builder(builder: (context) {
        context.select((int i) {
          if (shouldCall) {
            context.read<int>();
          }
          // trigger selector call without rebuilding
          return 0;
        });
        return const Text('foo', textDirection: TextDirection.ltr);
      });

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      shouldCall = true;
      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: child,
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('select throws if watch called inside the callback on dependency change', (tester) async {
      var shouldCall = false;
      var child = Builder(builder: (context) {
        context.select((int i) {
          if (shouldCall) {
            context.watch<int>();
          }
          // trigger selector call without rebuilding
          return 0;
        });
        return const Text('foo', textDirection: TextDirection.ltr);
      });

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      shouldCall = true;
      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: child,
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('select throws if select called inside the callback on dependency change', (tester) async {
      var shouldCall = false;
      var child = Builder(builder: (context) {
        context.select((int i) {
          if (shouldCall) {
            context.select((int i) => i);
          }
          // trigger selector call without rebuilding
          return 0;
        });
        return const Text('foo', textDirection: TextDirection.ltr);
      });

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      shouldCall = true;
      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: child,
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('throws if select called inside didChangeDependencies on rebuild', (tester) async {
      var child = StatefulTest(
        didChangeDependencies: (context) {
          context.select((int i) => i);
        },
        child: const Text('foo', textDirection: TextDirection.ltr),
      );

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: child,
        ),
      );

      expect(tester.takeException(), isAssertionError);

      // future calls to select still works
      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: StatefulTest(
            builder: (context) {
              return Text(
                context.select((int i) => i.toString()),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('21'), findsOneWidget);
    });
    testWidgets('can call read/watch inside didChangeDepencies', (tester) async {
      var didChangeDependenciesCount = 0;
      var child = StatefulTest(
        didChangeDependencies: (context) {
          didChangeDependenciesCount++;
          context
            ..watch<int>()
            ..read<int>();
        },
        child: const Text('42', textDirection: TextDirection.ltr),
      );

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(didChangeDependenciesCount, 1);
      expect(find.text('42'), findsOneWidget);

      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: child,
        ),
      );

      expect(didChangeDependenciesCount, 2);
      expect(find.text('42'), findsOneWidget);
    });
    testWidgets('select in didChangeDependencies stops working if build uses select too', (tester) async {
      var didChangeDependenciesCount = 0;
      var selectorCount = 0;
      var child = StatefulTest(
        didChangeDependencies: (c) {
          didChangeDependenciesCount++;
          c.select((int i) {
            selectorCount++;
            return i;
          });
        },
        builder: (context) {
          // never trigger a rebuild in itself, but still clear selectors
          context.select((int i) => 0);
          return Container();
        },
      );

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: child,
        ),
      );

      expect(selectorCount, 1);
      expect(didChangeDependenciesCount, 1);

      tester.element(find.byType(StatefulTest)).markNeedsBuild();
      await tester.pump();

      expect(selectorCount, 1);
      expect(didChangeDependenciesCount, 1);

      await tester.pumpWidget(
        Provider.value(
          value: 21,
          child: child,
        ),
      );

      // selectors in `didChangeDependencies` where cleared
      expect(selectorCount, 1);
      expect(didChangeDependenciesCount, 1);
    });
    testWidgets('select in initState throws', (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: StatefulTest(
            initState: (c) {
              c.select((int i) => i);
            },
            child: Container(),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('watch in initState throws', (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: StatefulTest(
            initState: (c) {
              c.watch<int>();
            },
            child: Container(),
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('read in initState works', (tester) async {
      int value;
      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: StatefulTest(
            initState: (c) {
              value = c.read<int>();
            },
            child: Container(),
          ),
        ),
      );

      expect(value, 42);
    });
    testWidgets('consumer can be removed and selector stops to be called', (tester) async {
      final selector = MockSelector.identity<int>();

      final child = Builder(builder: (c) {
        c.select<int, int>((v) {
          return selector(v);
        });
        return Container();
      });

      await tester.pumpWidget(
        Provider.value(
          value: 0,
          child: child,
        ),
      );

      verify(selector(0)).called(1);
      verifyNoMoreInteractions(selector);

      await tester.pumpWidget(
        Provider.value(
          value: 42,
          child: Container(),
        ),
      );

      // necessary call because didChangeDependencies may be called even
      // if the widget will be unmounted in the same frame
      verify(selector(42)).called(1);
      verifyNoMoreInteractions(selector);

      await tester.pumpWidget(
        Provider.value(
          value: 84,
          child: Container(),
        ),
      );

      verifyNoMoreInteractions(selector);
    });
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

class StatefulTest extends StatefulWidget {
  StatefulTest({Key key, this.initState, this.child, this.didChangeDependencies, this.builder}) : super(key: key);

  final void Function(BuildContext c) initState;
  final void Function(BuildContext c) didChangeDependencies;
  final WidgetBuilder builder;
  final Widget child;

  @override
  _StatefulTestState createState() => _StatefulTestState();
}

class _StatefulTestState extends State<StatefulTest> {
  @override
  void initState() {
    super.initState();
    widget.initState?.call(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder(context);
    }
    return widget.child;
  }
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
