@TestOn('browser')
import 'package:devtools_app_shared/ui.dart' show IdeTheme;
import 'package:devtools_app_shared/utils.dart' show setGlobal;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_devtools_extension/src/instance_viewer/instance_details.dart';
import 'package:provider_devtools_extension/src/instance_viewer/instance_providers.dart';
import 'package:provider_devtools_extension/src/provider_nodes.dart';
import 'package:provider_devtools_extension/src/provider_screen.dart';

import 'test_utils.dart';

void main() {
  setUp(() => setGlobal(IdeTheme, IdeTheme()));

  testWidgets('distinguishes an unread provider from an initialized null',
      (tester) async {
    tester.view.physicalSize = const Size(2225, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final initialized = providerIsInitializedProvider('0');
    var valueReads = 0;
    List<Override> overrides(bool isInitialized) => [
          sortedProviderNodesProvider.overrideWithValue(const AsyncValue.data([
            ProviderNode(id: '0', type: 'Provider<int?>'),
          ])),
          initialized.overrideWithValue(AsyncValue.data(isInitialized)),
          instanceProvider(const InstancePath.fromProviderId('0'))
              .overrideWithProvider(AutoDisposeFutureProvider((ref) async {
            valueReads++;
            return InstanceDetails.nill(setter: null);
          })),
        ];
    final container = ProviderContainer(overrides: overrides(false));
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: wrap(const ProviderScreenBody()),
    ));
    await tester.pump();
    expect(find.text('<not yet initialized>'), findsOneWidget);
    expect(find.text('null'), findsNothing);
    expect(valueReads, 0);
    container.updateOverrides(overrides(true));
    await tester.pumpAndSettle();
    expect(find.text('<not yet initialized>'), findsNothing);
    expect(find.text('null'), findsOneWidget);
    expect(valueReads, 1);
  });
}
