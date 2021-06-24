// Mixed mode: test is legacy, runtime is legacy, package:provider is null safe.
// @dart=2.11
import 'package:flutter/widgets.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';
import 'inherited_provider_test.dart';

void main() {
  testWidgets('allows nulls in mixed mode', (tester) async {
    final initialValueBuilder = InitialValueBuilderMock<int>(-1);
    when(initialValueBuilder(any)).thenReturn(null);

    await tester.pumpWidget(
      InheritedProvider<int>(
        create: initialValueBuilder,
        child: const Context(),
      ),
    );

    expect(of<int>(), equals(null));
    expect(of<int>(), equals(null));
  });
}
