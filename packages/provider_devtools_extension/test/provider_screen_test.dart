// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
import 'package:provider_devtools_extension/src/provider_screen.dart';
import 'package:provider_devtools_extension/src/instance_viewer/instance_details.dart';
import 'package:provider_devtools_extension/src/instance_viewer/instance_providers.dart';
import 'package:provider_devtools_extension/src/provider_list.dart';
import 'package:provider_devtools_extension/src/provider_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  // Set a wide enough screen width that we do not run into overflow.
  const windowSize = Size(2225.0, 1000.0);

  late Widget providerScreen;

  setUpAll(() async => await loadFonts());

  setUp(() {
    // setGlobal(IdeTheme, getIdeTheme());
  });

  setUp(() {
    providerScreen = Container(
      color: Colors.grey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: wrap(
          const ProviderScreenBody(),
        ),
      ),
    );
  });

  // TODO: add a test that verifies the add banner message request was posted
  // to devtools via the extension manager.
  // group('ProviderScreen', () {
  //   testWidgetsWithWindowSize(
  //     'shows ProviderUnknownErrorBanner if the devtool failed to fetch the list of providers',
  //     windowSize,
  //     (tester) async {
  //       await tester.pumpWidget(
  //         ProviderScope(
  //           overrides: [
  //             sortedProviderNodesProvider.overrideWithValue(
  //               const AsyncValue.loading(),
  //             ),
  //           ],
  //           child: providerScreen,
  //         ),
  //       );

  //       await tester.pumpWidget(
  //         ProviderScope(
  //           overrides: [
  //             sortedProviderNodesProvider.overrideWithValue(
  //               AsyncValue.error(StateError('')),
  //             ),
  //           ],
  //           child: providerScreen,
  //         ),
  //       );

  //       // wait for the Banner to appear as it is mounted asynchronously
  //       await tester.pump();

  //       await expectLater(
  //         find.byType(ProviderScreenBody),
  //         matchesGoldenFile(
  //           'goldens/provider_screen/list_error_banner.png',
  //         ),
  //       );
  //     },
  //   );
  // });

  group('selectedProviderIdProvider', () {
    test('selects the first provider available', () async {
      final container = ProviderContainer(
        overrides: [
          sortedProviderNodesProvider.overrideWithValue(
            const AsyncValue.loading(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen<String?>(
        selectedProviderIdProvider,
        (prev, next) {},
      );

      expect(sub.read(), isNull);

      container.updateOverrides([
        sortedProviderNodesProvider.overrideWithValue(
          const AsyncValue.data([
            ProviderNode(id: '0', type: 'Provider<A>'),
            ProviderNode(id: '1', type: 'Provider<B>'),
          ]),
        ),
      ]);

      await container.pump();

      expect(sub.read(), '0');
    });

    test('selects the first provider available after an error', () async {
      final container = ProviderContainer(
        overrides: [
          sortedProviderNodesProvider.overrideWithValue(
            AsyncValue.error(Error()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen<String?>(
        selectedProviderIdProvider,
        (prev, next) {},
      );

      // wait for the error to be handled
      await container.pump();

      expect(sub.read(), isNull);

      container.updateOverrides([
        sortedProviderNodesProvider.overrideWithValue(
          const AsyncValue.data([
            ProviderNode(id: '0', type: 'Provider<A>'),
            ProviderNode(id: '1', type: 'Provider<B>'),
          ]),
        ),
      ]);

      // wait for the ids update to be handled
      await container.pump();

      expect(sub.read(), '0');
    });

    test(
      'When the currently selected provider is removed, selects the next first provider',
      () {
        final container = ProviderContainer(
          overrides: [
            sortedProviderNodesProvider.overrideWithValue(
              const AsyncValue.data([
                ProviderNode(id: '0', type: 'Provider<A>'),
              ]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen<String?>(
          selectedProviderIdProvider,
          (prev, next) {},
        );

        expect(sub.read(), '0');

        container.updateOverrides([
          sortedProviderNodesProvider.overrideWithValue(
            const AsyncValue.data([
              ProviderNode(id: '1', type: 'Provider<B>'),
            ]),
          ),
        ]);

        expect(sub.read(), '1');
      },
    );

    test('Once a provider is selected, further updates are no-op', () async {
      final container = ProviderContainer(
        overrides: [
          sortedProviderNodesProvider.overrideWithValue(
            const AsyncValue.data([
              ProviderNode(id: '0', type: 'Provider<A>'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen<String?>(
        selectedProviderIdProvider,
        (prev, next) {},
      );

      await container.pump();

      expect(sub.read(), '0');

      container.updateOverrides([
        sortedProviderNodesProvider.overrideWithValue(
          // '0' is no-longer the first provider on purpose
          const AsyncValue.data([
            ProviderNode(id: '1', type: 'Provider<B>'),
            ProviderNode(id: '0', type: 'Provider<A>'),
          ]),
        ),
      ]);

      await container.pump();

      expect(sub.read(), '0');
    });

    test(
      'when the list of providers becomes empty, the current provider is unselected '
      ', then, the first provider will be selected when the list becomes non-empty again.',
      () async {
        final container = ProviderContainer(
          overrides: [
            sortedProviderNodesProvider.overrideWithValue(
              const AsyncValue.data([
                ProviderNode(id: '0', type: 'Provider<A>'),
              ]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen<String?>(
          selectedProviderIdProvider,
          (prev, next) {},
        );

        await container.pump();

        expect(sub.read(), '0');

        container.updateOverrides([
          sortedProviderNodesProvider.overrideWithValue(
            const AsyncValue.data([]),
          ),
        ]);

        await container.pump();

        expect(sub.read(), isNull);

        container.updateOverrides([
          sortedProviderNodesProvider.overrideWithValue(
            const AsyncValue.data([
              ProviderNode(id: '1', type: 'Provider<B>'),
            ]),
          ),
        ]);

        await container.pump();

        expect(sub.read(), '1');
      },
    );
  });

  group('ProviderList', () {
    List<Override> getOverrides() {
      return [
        instanceProvider(const InstancePath.fromProviderId('0'))
            .overrideWithValue(
          AsyncValue.data(
            InstanceDetails.string(
              'Value0',
              instanceRefId: 'string/0',
              setter: null,
            ),
          ),
        ),
      ];
    }

    testWidgetsWithWindowSize(
      'selects the first provider the first time a provider is received',
      windowSize,
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            sortedProviderNodesProvider
                .overrideWithValue(const AsyncValue.loading()),
            ...getOverrides(),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: providerScreen,
          ),
        );

        expect(container.read(selectedProviderIdProvider), isNull);
        expect(find.byType(ProviderNodeItem), findsNothing);

        await expectLater(
          find.byType(ProviderScreenBody),
          matchesGoldenFile(
            'goldens/provider_screen/no_selected_provider.png',
          ),
        );

        container.updateOverrides([
          sortedProviderNodesProvider.overrideWithValue(
            const AsyncValue.data([
              ProviderNode(id: '0', type: 'Provider<A>'),
              ProviderNode(id: '1', type: 'Provider<B>'),
            ]),
          ),
          ...getOverrides(),
        ]);

        await tester.pump();

        expect(container.read(selectedProviderIdProvider), '0');
        expect(find.byType(ProviderNodeItem), findsNWidgets(2));
        expect(
          find.descendant(
            of: find.byKey(const Key('provider-0')),
            matching: find.text('Provider<A>()'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('provider-1')),
            matching: find.text('Provider<B>()'),
          ),
          findsOneWidget,
        );

        await expectLater(
          find.byType(ProviderScreenBody),
          matchesGoldenFile(
            'goldens/provider_screen/selected_provider.png',
          ),
        );
      },
    );

    // TODO: add a test that verifies the add banner message request was posted
    // to devtools via the extension manager.
    // testWidgetsWithWindowSize(
    //   'shows ProviderUnknownErrorBanner if the devtool failed to fetch the selected provider',
    //   windowSize,
    //   (tester) async {
    //     final overrides = [
    //       sortedProviderNodesProvider.overrideWithValue(
    //         const AsyncValue.data([
    //           ProviderNode(id: '0', type: 'Provider<A>'),
    //           ProviderNode(id: '1', type: 'Provider<B>'),
    //         ]),
    //       ),
    //       ...getOverrides(),
    //     ];

    //     await tester.pumpWidget(
    //       ProviderScope(
    //         overrides: [
    //           ...overrides,
    //           instanceProvider(const InstancePath.fromProviderId('0'))
    //               .overrideWithValue(const AsyncValue.loading()),
    //         ],
    //         child: providerScreen,
    //       ),
    //     );

    //     await tester.pumpWidget(
    //       ProviderScope(
    //         overrides: [
    //           ...overrides,
    //           instanceProvider(const InstancePath.fromProviderId('0'))
    //               .overrideWithValue(AsyncValue.error(Error())),
    //         ],
    //         child: providerScreen,
    //       ),
    //     );

    //     // await for the modal to be mounted as it is rendered asynchronously
    //     await tester.pump();

    //     expect(
    //       find.byKey(
    //         Key('ProviderUnknownErrorBanner - ${ProviderScreen.id}'),
    //       ),
    //       findsOneWidget,
    //     );

    //     await expectLater(
    //       find.byType(ProviderScreenBody),
    //       matchesGoldenFile(
    //         'goldens/provider_screen/selected_provider_error_banner.png',
    //       ),
    //     );
    //   },
    // );
  });
}
