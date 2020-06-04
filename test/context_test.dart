import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('watch in layoutbuilder', (tester) async {
    await tester.pumpWidget(
      Provider(
        create: (_) => 42,
        child: LayoutBuilder(builder: (context, _) {
          return Text(
            context.watch<int>().toString(),
            textDirection: TextDirection.ltr,
          );
        }),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });
  testWidgets('select in layoutbuilder', (tester) async {
    await tester.pumpWidget(
      Provider(
        create: (_) => 42,
        child: LayoutBuilder(builder: (context, _) {
          return Text(
            context.select((int i) => '$i'),
            textDirection: TextDirection.ltr,
          );
        }),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });
  testWidgets('cannot select in listView', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Provider(
          create: (_) => 0,
          child: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Text(context.select((int v) => '$v'));
            },
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isAssertionError.having(
          (s) => s.message,
          'message',
          contains(
            'Tried to use context.select inside a SliverList/SliderGridView.',
          )),
    );
  });
  testWidgets('watch in listView', (tester) async {
    final notifier = ValueNotifier([0, 0]);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ChangeNotifierProvider(
          create: (_) => notifier,
          child: ListView.builder(
            itemCount: 2,
            itemBuilder: (context, index) {
              return Text(
                context
                    .watch<ValueNotifier<List<int>>>()
                    .value[index]
                    .toString(),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNWidgets(2));

    notifier.value = [1, 0];

    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
  testWidgets('watch in gridView', (tester) async {
    final notifier = ValueNotifier([0, 0]);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ChangeNotifierProvider(
          create: (_) => notifier,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              return Text(
                context
                    .watch<ValueNotifier<List<int>>>()
                    .value[index]
                    .toString(),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNWidgets(2));

    notifier.value = [1, 0];

    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  group('BuildContext', () {
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
