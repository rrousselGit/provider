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

  testWidgets('mounting providers updates the registry in place',
      (tester) async {
    final registry = ProviderBinding.debugInstance.providerDetails;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>.value(value: 1),
          Provider<String>.value(value: 'value'),
        ],
        child: Container(),
      ),
    );

    expect(
      identical(ProviderBinding.debugInstance.providerDetails, registry),
      isTrue,
    );
    expect(registry.length, 2);

    await tester.pumpWidget(Container());

    expect(
      identical(ProviderBinding.debugInstance.providerDetails, registry),
      isTrue,
    );
    expect(registry, isEmpty);
  });

  testWidgets('mounting accepts a const registry assignment', (tester) async {
    final binding = ProviderBinding.debugInstance;
    const assigned = <String, ProviderNode>{};
    binding.providerDetails = assigned;

    await tester.pumpWidget(
      Provider<int>.value(value: 1, child: const SizedBox()),
    );

    expect(tester.takeException(), isNull);
    final registry = binding.providerDetails;
    expect(registry.values.single.value, 1);
    expect(assigned, isEmpty);

    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), isNull);
    expect(identical(binding.providerDetails, registry), isTrue);
    expect(registry, isEmpty);
    expect(
      spy.logs,
      List.filled(
          3, isPostEventCall('provider:provider_list_changed', isEmpty)),
    );
  });

  testWidgets('lifecycle updates accept an unmodifiable populated registry',
      (tester) async {
    final binding = ProviderBinding.debugInstance;
    await tester.pumpWidget(
      Provider<int>.value(value: 1, child: const SizedBox()),
    );
    final assigned = Map<String, ProviderNode>.unmodifiable(
      binding.providerDetails,
    );
    binding.providerDetails = assigned;
    final registry = binding.providerDetails;
    spy.logs.clear();

    await tester.pumpWidget(
      Provider<int>.value(
        value: 1,
        child: Provider<String>.value(
          value: 'second',
          child: const SizedBox(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(identical(binding.providerDetails, registry), isTrue);
    expect(registry.length, 2);
    expect(registry[assigned.keys.single], same(assigned.values.single));

    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), isNull);
    expect(identical(binding.providerDetails, registry), isTrue);
    expect(registry, isEmpty);
    expect(assigned.length, 1);
    expect(
      spy.logs,
      List.filled(
          3, isPostEventCall('provider:provider_list_changed', isEmpty)),
    );
  });
}
