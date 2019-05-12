import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

Element findElementOfWidget<T extends Widget>() {
  return find.byType(T).first.evaluate().first;
}

Type typeOf<T>() => T;

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

class A with DiagnosticableTreeMixin {}

class B with DiagnosticableTreeMixin {}

class C with DiagnosticableTreeMixin {}

class D with DiagnosticableTreeMixin {}

class E with DiagnosticableTreeMixin {}

class F with DiagnosticableTreeMixin {}
