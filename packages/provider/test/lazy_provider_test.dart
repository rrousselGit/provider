import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('Lazy Provider', () {
    testWidgets('pass down arguments', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(Provider<int>(
        key: key,
        builder: (_) => 42,
        child: const Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(key.currentContext, isNotNull);
      expect(find.text('foo'), findsOneWidget);
    });
    testWidgets('builds its value synchronously on first listening',
        (tester) async {
      final builder = WidgetValueBuilderMock<int>();
      when(builder(any)).thenReturn(42);

      final providerKey = GlobalKey();
      final childKey = GlobalKey();

      await tester.pumpWidget(Provider<int>(
        key: providerKey,
        builder: builder,
        child: Container(key: childKey),
      ));

      verifyZeroInteractions(builder);

      final result = Provider.of<int>(childKey.currentContext);

      verify(builder(providerKey.currentContext)).called(1);
      verifyNoMoreInteractions(builder);
      expect(result, equals(42));
    });
    testWidgets('throws if uses inheritedWidget inside builder',
        (tester) async {
      await tester.pumpWidget(Provider<double>.value(
        value: 42,
        child: Provider<int>(
          builder: (context) => Provider.of<double>(context).toInt(),
          child: Builder(builder: (context) {
            Provider.of<int>(context);
            return Container();
          }),
        ),
      ));

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets("rebuilds don't call builder again", (tester) async {
      final builder = WidgetValueBuilderMock<int>();
      when(builder(any)).thenReturn(42);

      final providerKey = GlobalKey();
      final childKey = GlobalKey();

      await tester.pumpWidget(Provider<int>(
        key: providerKey,
        builder: builder,
        child: Container(key: childKey),
      ));
      Provider.of<int>(childKey.currentContext);

      await tester.pumpWidget(Provider<int>(
        key: providerKey,
        builder: builder,
        child: Container(key: childKey),
      ));

      verify(builder(providerKey.currentContext)).called(1);
      verifyNoMoreInteractions(builder);
      expect(Provider.of<int>(childKey.currentContext), equals(42));
    });

    testWidgets('dispose value when unmounted', (tester) async {
      final childKey = GlobalKey();
      final providerKey = GlobalKey();
      final dispose = DisposerMock<int>();

      await tester.pumpWidget(Provider<int>(
        key: providerKey,
        builder: (_) => 42,
        dispose: dispose,
        child: Container(key: childKey),
      ));

      Provider.of<int>(childKey.currentContext);

      verifyZeroInteractions(dispose);

      final context = providerKey.currentContext;

      await tester.pumpWidget(Container());

      verify(dispose(context, 42)).called(1);
      verifyNoMoreInteractions(dispose);
    });

    test('thows if builder is missing', () {
      expect(
        () => Provider<int>(builder: null),
        throwsAssertionError,
      );
    });

    testWidgets("don't call dispose when unmounted if never listened",
        (tester) async {
      final childKey = GlobalKey();
      final providerKey = GlobalKey();
      final dispose = DisposerMock<int>();

      await tester.pumpWidget(Provider<int>(
        key: providerKey,
        builder: (_) => 42,
        dispose: dispose,
        child: Container(key: childKey),
      ));

      await tester.pumpWidget(Container());

      verifyZeroInteractions(dispose);
    });
  });
}
