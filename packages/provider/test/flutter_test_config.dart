import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

FutureOr<void> testExecutable(FutureOr<void> Function() testMain) {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnored(
    allNotGCed: true,
    createdByTestHelpers: true,
    classes: [
      'RenderObject',
      'RenderParagraph',
      'StatefulElement',
      '_StatefulTestState',
      'StatelessElement',
      'SingleChildRenderObjectElement',
      '_InheritedProviderScopeElement',
      '_InheritedProviderScopeElement<String?>',
      '_InheritedProviderScopeElement<ValueNotifier<int>?>',
      '_InheritedProviderScopeElement<int?>',
      'MultiChildRenderObjectElement',
      'TextPainter',
    ],
  );

  return testMain();
}
