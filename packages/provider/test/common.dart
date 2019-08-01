import 'dart:async';

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

class MockConsumerBuilder<T> extends Mock {
  Widget call(BuildContext context, T value, Widget child);
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

class MockCombinedBuilder extends Mock {
  Widget call(Combined foo);
}

class CombinerMock extends Mock {
  Combined call(BuildContext context, A a, Combined foo);
}

class ProviderBuilderMock extends Mock {
  Widget call(BuildContext context, Combined value, Widget child);
}

class Combined extends DiagnosticableTree {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;
  final F f;
  final Combined previous;
  final BuildContext context;

  Combined(this.context, this.previous, this.a,
      [this.b, this.c, this.d, this.e, this.f]);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Combined &&
      other.context == context &&
      other.previous == previous &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.e == e &&
      other.f == f;

  // fancy toString for debug purposes.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.properties.addAll([
      DiagnosticsProperty('a', a, defaultValue: null),
      DiagnosticsProperty('b', b, defaultValue: null),
      DiagnosticsProperty('c', c, defaultValue: null),
      DiagnosticsProperty('d', d, defaultValue: null),
      DiagnosticsProperty('e', e, defaultValue: null),
      DiagnosticsProperty('f', f, defaultValue: null),
      DiagnosticsProperty('previous', previous, defaultValue: null),
      DiagnosticsProperty('context', context, defaultValue: null),
    ]);
  }
}

class MyListenable extends ChangeNotifier {}

class MyStream extends Stream<void> {
  @override
  StreamSubscription<void> listen(void Function(void event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return null;
  }
}
