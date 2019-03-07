import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

Element findElementOfWidget<T extends Widget>() {
  return find.byType(T).first.evaluate().first;
}

class ValueBuilderMock<T> extends Mock {
  T call(BuildContext context);
}

class DisposerMock<T> extends Mock {
  void call(BuildContext context, T value);
}

class MockNotifier extends Mock implements ChangeNotifier {}

class BuilderMock extends Mock {
  Widget call(BuildContext context);
}

class UpdateShouldNotifyMock<T> extends Mock {
  bool call(T old, T newValue);
}
