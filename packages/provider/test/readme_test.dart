import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'root/package/provider/README.md and root/README.md are identical',
    () async {
      final root = await File.fromUri(Uri.parse(
              '${Directory.current.parent.parent.parent.path}/README.md'))
          .readAsString();
      final local = await File.fromUri(
              Uri.parse('${Directory.current.parent.path}/README.md'))
          .readAsString();

      expect(root, equals(local));
    },
    // Don't run the test if it's not inside the entire repo
    skip: !Directory.current.parent.path.endsWith('/packages/provider'),
  );
}
