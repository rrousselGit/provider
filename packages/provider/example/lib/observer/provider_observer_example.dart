import 'package:provider/provider.dart';

class ExampleProvider extends BaseNotifier {
  ExampleProvider(ChangeNotifierObserver observer)
      : super(observer, 'ExampleProvider');
  int _counter = 0;

  int get counter => _counter;

  /// Maximum allowed counter value
  static const int _maxValue = 100;

  /// Minimum allowed counter value
  static const int _minValue = -100;

  /// Increments the counter if it hasn't reached [_maxValue].
  void increment() {
    if (_counter >= _maxValue) {
      return;
    }
    _counter++;
    updateState(_counter);
  }

  /// Decrements the counter if it hasn't reached [_minValue].
  void decrement() {
    if (_counter <= _minValue) {
      return;
    }
    _counter--;
    updateState(_counter);
  }
}
