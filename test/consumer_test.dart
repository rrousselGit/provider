import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('consumer', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      BuildContext _context;
      int _value;
      await tester.pumpWidget(MaterialApp(
        home: Provider<int>(
          value: 42,
          child: Consumer<int>(
            builder: (context, value) {
              _value = value;
              _context = context;
              return Text(value.toString());
            },
          ),
        ),
      ));

      expect(_value, 42);
      expect(_context,
          tester.element(find.byWidgetPredicate((w) => w is Consumer<int>)));
      expect(find.text('42'), findsOneWidget);
    });
    testWidgets('crashed with no builder', (tester) async {
      expect(
        () => Consumer<int>(builder: null),
        throwsAssertionError,
      );
    });
  });
}
