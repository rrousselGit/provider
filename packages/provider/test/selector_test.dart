import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as mockito show when;
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void mockImplementation<T extends Function>(VoidCallback when, T mock) {
  mockito.when(when()).thenAnswer((invo) {
    return Function.apply(mock, invo.positionalArguments, invo.namedArguments);
  });
}

void main() {
  final selector = MockSelector<int>();
  final builder = MockBuilder<int>();

  tearDown(() {
    clearInteractions(builder);
    clearInteractions(selector);
  });

  void mockBuilder(ValueWidgetBuilder<int> implementation) {
    mockImplementation(() => builder(any, any, any), implementation);
  }

  testWidgets('asserts that builder/selector are not null', (_) async {},
      skip: true);
  testWidgets('passes `child` and `key`', (_) async {}, skip: true);
  testWidgets('calls builder if the callback changes', (_) async {},
      skip: true);
  testWidgets("don't call builder again", (tester) async {
    when(selector(any)).thenReturn(42);

    mockBuilder((_, value, ___) {
      return Text(value.toString(), textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(Selector0<int>(
      selector: selector,
      builder: builder,
    ));

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(selector);

    verify(builder(argThat(isNotNull), 42, null)).called(1);
    verifyNoMoreInteractions(selector);

    expect(find.text('42'), findsOneWidget);
  });
}

class MockSelector<T> extends Mock {
  T call(BuildContext context);
}

class MockBuilder<T> extends Mock {
  Widget call(BuildContext context, T value, Widget child);
}
