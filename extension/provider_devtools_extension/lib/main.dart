import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/provider_screen.dart';

void main() {
  runApp(const FooPackageDevToolsExtension());
}

class FooPackageDevToolsExtension extends StatelessWidget {
  const FooPackageDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ProviderScope(
        child: ProviderScreenBody(),
      ),
    );
  }
}
