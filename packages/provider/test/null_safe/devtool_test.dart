import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

import 'matchers.dart';

void main() {
  late PostEventSpy spy;

  setUp(() {
    spy = spyPostEvent();
  });

  tearDown(() => spy.dispose());

  testWidgets('calls postEvent whenever a provider is updated', (tester) async {
    final notifier = ValueNotifier(42);
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notifier),
        ],
        child: Consumer<ValueNotifier<int>>(
          builder: (context, value, child) {
            return Container();
          },
        ),
      ),
    );

    final notifierId =
        ProviderBinding.debugInstance.providerDetails.keys.single;

    spy.logs.clear();

    notifier.notifyListeners();

    expect(spy.logs, isEmpty);

    await tester.pump();

    expect(
      spy.logs,
      [
        isPostEventCall(
          'provider:provider_changed',
          <String, dynamic>{'id': notifierId},
        ),
      ],
    );
    spy.logs.clear();
  });

  testWidgets('calls postEvent whenever a provider is mounted/unmounted',
      (tester) async {
    Provider.value(value: 42);

    expect(spy.logs, isEmpty);
    expect(ProviderBinding.debugInstance.providerDetails, isEmpty);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: 42),
        ],
        child: Container(),
      ),
    );

    final intProviderId =
        ProviderBinding.debugInstance.providerDetails.keys.first;

    expect(ProviderBinding.debugInstance.providerDetails, {
      intProviderId: isA<ProviderNode>()
          .having((e) => e.id, 'id', intProviderId)
          .having((e) => e.type, 'type', 'Provider<int>')
          .having((e) => e.value, 'value', 42),
    });
    expect(
      spy.logs,
      [isPostEventCall('provider:provider_list_changed', isEmpty)],
    );
    spy.logs.clear();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: 42),
          Provider.value(value: '42'),
        ],
        child: Container(),
      ),
    );

    final stringProviderId =
        ProviderBinding.debugInstance.providerDetails.keys.last;

    expect(intProviderId, isNot(stringProviderId));
    expect(ProviderBinding.debugInstance.providerDetails, {
      intProviderId: isA<ProviderNode>()
          .having((e) => e.id, 'id', intProviderId)
          .having((e) => e.type, 'type', 'Provider<int>')
          .having((e) => e.value, 'value', 42),
      stringProviderId: isA<ProviderNode>()
          .having((e) => e.id, 'id', stringProviderId)
          .having((e) => e.type, 'type', 'Provider<String>')
          .having((e) => e.value, 'value', '42'),
    });
    expect(
      spy.logs,
      [isPostEventCall('provider:provider_list_changed', isEmpty)],
    );
    spy.logs.clear();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: 42),
        ],
        child: Container(),
      ),
    );

    expect(ProviderBinding.debugInstance.providerDetails, {
      intProviderId: isA<ProviderNode>()
          .having((e) => e.id, 'id', intProviderId)
          .having((e) => e.type, 'type', 'Provider<int>')
          .having((e) => e.value, 'value', 42),
    });
    expect(
      spy.logs,
      [isPostEventCall('provider:provider_list_changed', isEmpty)],
    );
    spy.logs.clear();
  });
  testWidgets('DevTools inspection preserves lazy provider creation', (
    tester,
  ) async {
    var createCalls = 0;
    final key = GlobalKey();

    await tester.pumpWidget(
      Provider<int>(
        create: (_) {
          createCalls++;
          return 42;
        },
        child: Container(key: key),
      ),
    );

    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isFalse);
    expect(node.value, isNull);
    expect(createCalls, 0);

    expect(key.currentContext!.read<int>(), 42);
    expect(createCalls, 1);
    expect(node.isInitialized, isTrue);
    expect(node.value, 42);
  });

  testWidgets('DevTools distinguishes an initialized null value', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<int?>.value(value: null, child: Container()),
    );

    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isTrue);
    expect(node.value, isNull);
  });

}
