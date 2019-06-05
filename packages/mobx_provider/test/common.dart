import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:mockito/mockito.dart';

part 'common.g.dart';

class Counter = CounterBase with _$Counter;

abstract class CounterBase with Store {
  @observable
  int value = 0;

  @action
  void increment() {
    value++;
  }
}

class FlutterErrorMock extends Mock {
  void call(FlutterErrorDetails details);
}

class StoreMock extends Mock implements Store {}

class DisposerMock<T> extends Mock {
  void call(BuildContext context, T value);
}

class ReactiveContextMock extends Mock implements ReactiveContext {}
