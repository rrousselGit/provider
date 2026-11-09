import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('watch uses the existing inherited element for notifications',
      (tester) async {
    final notifier = ValueNotifier<int>(0);
    addTearDown(notifier.dispose);
    var builds = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider<ValueNotifier<int>>.value(
        value: notifier,
        child: Builder(
          builder: (context) {
            builds++;
            final value = context.watch<ValueNotifier<int>>().value;
            return Text('$value', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    expect(builds, 1);
    notifier.value = 1;
    await tester.pump();

    expect(builds, 2);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a missing optional provider still tracks GlobalKey relocation',
      (tester) async {
    final key = GlobalKey();
    final reader = Builder(
      key: key,
      builder: (context) {
        final value = context.watch<int?>();
        return Text('${value ?? 'missing'}', textDirection: TextDirection.ltr);
      },
    );

    await tester.pumpWidget(
      Column(children: [reader, const SizedBox()]),
    );
    expect(find.text('missing'), findsOneWidget);

    await tester.pumpWidget(
      Column(
        children: [
          const SizedBox(),
          Provider<int>.value(value: 42, child: reader),
        ],
      ),
    );
    expect(find.text('42'), findsOneWidget);
  });
}
