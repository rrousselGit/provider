import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

class AppScreen {
  const AppScreen(this._driver);

  static final incrementFloatingButton =
      find.byValueKey('increment_floatingActionButton');
  static final appBarText = find.text('Example');
  static final counterState = find.byValueKey('counterState');
  final FlutterDriver _driver;

  /// verify the AppBar text is Counter
  Future<void> verifyTheAppBarText() async {
    expect(await _driver.getText(appBarText), 'Example');
  }

  Future<void> verifyCounterTextIsZero() async {
    expect(await _driver.getText(counterState), '0');
  }

  Future<void> pressIncrementFloatingActionButtonTwice() async {
    // tap floating action button
    await _driver.tap(incrementFloatingButton);
    expect(await _driver.getText(counterState), '1');

    // tap floating action button
    await _driver.tap(incrementFloatingButton);
    expect(await _driver.getText(counterState), '2');
  }
}
