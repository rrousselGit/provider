import 'dart:io';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFonts() async {
  // source: https://medium.com/swlh/test-your-flutter-widgets-using-golden-files-b533ac0de469

  //https://github.com/flutter/flutter/issues/20907
  if (Directory.current.path.endsWith('/test')) {
    Directory.current = Directory.current.parent;
  }

  const fonts = {
    'Roboto': [
      'fonts/Roboto/Roboto-Thin.ttf',
      'fonts/Roboto/Roboto-Light.ttf',
      'fonts/Roboto/Roboto-Regular.ttf',
      'fonts/Roboto/Roboto-Medium.ttf',
      'fonts/Roboto/Roboto-Bold.ttf',
      'fonts/Roboto/Roboto-Black.ttf',
    ],
    'RobotoMono': [
      'fonts/Roboto_Mono/RobotoMono-Thin.ttf',
      'fonts/Roboto_Mono/RobotoMono-Light.ttf',
      'fonts/Roboto_Mono/RobotoMono-Regular.ttf',
      'fonts/Roboto_Mono/RobotoMono-Medium.ttf',
      'fonts/Roboto_Mono/RobotoMono-Bold.ttf',
    ],
    'Octicons': ['fonts/Octicons.ttf'],
    // 'Codicon': ['packages/codicon/font/codicon.ttf']
  };

  final loadFontsFuture = fonts.entries.map((entry) async {
    final loader = FontLoader(entry.key);

    for (final path in entry.value) {
      final fontData = File(path).readAsBytes().then((bytes) {
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      });

      loader.addFont(fontData);
    }

    await loader.load();
  });

  await Future.wait(loadFontsFuture);
}

// NOTE: the below helpers are duplicated from
// `flutter/devtools/packages/devtools_test`. We copied because `devtools_test`
// is not published on pub.dev for us to import.

/// Wraps [widget] with the build context it needs to load in a test.
///
/// This includes a [MaterialApp] to provide context like [Theme.of], a
/// [Material] to support elements like [TextField] that draw ink effects, and a
/// [Directionality] to support [RenderFlex] widgets like [Row] and [Column].
Widget wrap(Widget widget) {
  return MaterialApp(
    theme: themeFor(
      isDarkTheme: false,
      ideTheme: IdeTheme(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
    ),
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ),
  );
}

/// Runs a test with the size of the app window under test to [windowSize].
void testWidgetsWithWindowSize(
  String name,
  Size windowSize,
  WidgetTesterCallback test, {
  bool skip = false,
}) {
  testWidgets(
    name,
    (WidgetTester tester) async {
      await _setWindowSize(tester, windowSize);
      await test(tester);
      await _resetWindowSize(tester);
    },
    skip: skip,
  );
}

Future<void> _setWindowSize(WidgetTester tester, Size windowSize) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.setSurfaceSize(windowSize);
  tester.view.physicalSize = windowSize;
  tester.view.devicePixelRatio = 1.0;
}

Future<void> _resetWindowSize(WidgetTester tester) async {
  await _setWindowSize(tester, const Size(800.0, 600.0));
}
