import 'package:provider/provider.dart';

class ExampleProvider extends BaseNotifier {
  ExampleProvider(ChangeNotifierObserver observer)
      : super(observer, 'ExampleProvider');
  int _counter = 0;

  int get counter => _counter;

  void increment() {
    _counter++;
    updateState(_counter); // call updateState when the state is changed
  }

  void decrement() {
    _counter--;
    updateState(_counter); // call updateState when the state is changed
  }
}
