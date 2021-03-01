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

  testWidgets(
      'ProviderContainer calls postEvent whenever it mounts/unmount a provider',
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
          .having((e) => e.type, 'type', 'Provider<int>'),
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
          .having((e) => e.type, 'type', 'Provider<int>'),
      stringProviderId: isA<ProviderNode>()
          .having((e) => e.id, 'id', stringProviderId)
          .having((e) => e.type, 'type', 'Provider<String>'),
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
          .having((e) => e.type, 'type', 'Provider<int>'),
    });
    expect(
      spy.logs,
      [isPostEventCall('provider:provider_list_changed', isEmpty)],
    );
    spy.logs.clear();
  });
}
