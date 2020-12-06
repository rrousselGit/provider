import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

Element findElementOfWidget<T extends Widget>() {
  return find.byType(T).first.evaluate().first;
}

InheritedContext<T> findInheritedContext<T>() {
  return find
      .byElementPredicate((e) => e is InheritedContext<T>)
      .first
      .evaluate()
      .first as InheritedContext<T>;
}

Type typeOf<T>() => T;

class InitialValueBuilderMock<T> extends Mock {
  InitialValueBuilderMock(this._value) {
    when(this(any)).thenAnswer((_) => _value);
  }

  final T _value;

  T call(BuildContext? context) {
    return super.noSuchMethod(Invocation.method(#call, [context]), _value) as T;
  }
}

class ValueBuilderMock<T> extends Mock {
  ValueBuilderMock(this._value) {
    when(this(any, any)).thenReturn(_value);
  }

  final T _value;

  T call(BuildContext? context, T? previous) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, previous]),
      _value,
    ) as T;
  }
}

class TransitionBuilderMock extends Mock {
  TransitionBuilderMock([Widget Function(BuildContext c, Widget child)? cb]) {
    if (cb != null) {
      when(this(any, any)).thenAnswer((i) {
        final context = i.positionalArguments.first as BuildContext;
        final child = i.positionalArguments[1] as Widget;
        return cb(context, child);
      });
    }
  }

  Widget call(BuildContext? context, Widget? child) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, child]),
      Container(),
    ) as Widget;
  }
}

class StartListeningMock<T> extends Mock {
  StartListeningMock(VoidCallback value) {
    when(this(any, any)).thenReturn(value);
  }

  VoidCallback call(InheritedContext<T>? context, T? value) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, value]),
      () {},
    ) as VoidCallback;
  }
}

class StopListeningMock extends Mock {
  void call();
}

class DisposeMock<T> extends Mock {
  void call(BuildContext? context, T? value) {
    super.noSuchMethod(
      Invocation.method(#call, [context, value]),
    );
  }
}

class MockNotifier extends Mock implements ChangeNotifier {
  @override
  void addListener(VoidCallback? listener);

  @override
  void removeListener(VoidCallback? listener);
}

class ValueWidgetBuilderMock<T> extends Mock {
  ValueWidgetBuilderMock([
    Widget Function(BuildContext c, T value, Widget child)? cb,
  ]) {
    if (cb != null) {
      when(this(any, any, any)).thenAnswer((i) {
        final context = i.positionalArguments.first as BuildContext;
        final value = i.positionalArguments[1] as T;
        final child = i.positionalArguments[2] as Widget;
        return cb(context, value, child);
      });
    }
  }

  Widget call(BuildContext? context, T? value, Widget? child) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, value, child]),
      Container(),
    ) as Widget;
  }
}

class BuilderMock extends Mock {
  BuilderMock([Widget Function(BuildContext c)? cb]) {
    if (cb != null) {
      when(this(any)).thenAnswer((i) {
        final context = i.positionalArguments.first as BuildContext;
        return cb(context);
      });
    }
  }

  Widget call(BuildContext? context) {
    return super.noSuchMethod(
      Invocation.method(#call, [context]),
      Container(),
    ) as Widget;
  }
}

class StreamMock<T> extends Mock implements Stream<T> {}

class FutureMock<T> extends Mock implements Future<T> {}

class StreamSubscriptionMock<T> extends Mock implements StreamSubscription<T> {}

class MockConsumerBuilder<T> extends Mock {
  Widget call(BuildContext? context, T? value, Widget? child) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, value, child]),
      Container(),
    ) as Widget;
  }
}

class UpdateShouldNotifyMock<T> extends Mock {
  bool call(T? old, T? newValue) {
    return super.noSuchMethod(
      Invocation.method(#call, [old, newValue]),
      false,
    ) as bool;
  }
}

class TextOf<T> extends StatelessWidget {
  TextOf({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      Provider.of<T>(context).toString(),
      textDirection: TextDirection.ltr,
    );
  }
}

class DeferredStartListeningMock<T, R> extends Mock {
  DeferredStartListeningMock([
    VoidCallback Function(
      InheritedContext<R> context,
      void Function(R value) setState,
      T controller,
      R value,
    )?
        call,
  ]) {
    if (call != null) {
      when(this(any, any, any, any)).thenAnswer((invoc) {
        return Function.apply(
          call,
          invoc.positionalArguments,
          invoc.namedArguments,
        ) as VoidCallback;
      });
    }
  }

  VoidCallback call(
    InheritedContext<R>? context,
    void Function(R value)? setState,
    T? controller,
    R? value,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #start,
          [context, setState, controller, value],
        ),
        () {},
      ) as VoidCallback;
}

class DebugCheckValueTypeMock<T> extends Mock {
  void call(T value);
}

class A with DiagnosticableTreeMixin {}

class B with DiagnosticableTreeMixin {}

class C with DiagnosticableTreeMixin {}

class D with DiagnosticableTreeMixin {}

class E with DiagnosticableTreeMixin {}

class F with DiagnosticableTreeMixin {}

class MockCombinedBuilder extends Mock {
  Widget call(Combined? foo) {
    return super.noSuchMethod(
      Invocation.method(#call, [foo]),
      Container(),
    ) as Widget;
  }
}

class CombinerMock extends Mock {
  Combined call(BuildContext? context, A? a, Combined? foo) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, a, foo]),
      const Combined(),
    ) as Combined;
  }
}

class ProviderBuilderMock extends Mock {
  Widget call(BuildContext context, Combined value, Widget child);
}

class MyStream extends Fake implements Stream<int> {}

@immutable
class Combined extends DiagnosticableTree {
  const Combined([
    this.context,
    this.previous,
    this.a,
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
  ]);

  final A? a;
  final B? b;
  final C? c;
  final D? d;
  final E? e;
  final F? f;
  final Combined? previous;
  final BuildContext? context;

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

int buildCountOf(BuildCount widget) {
  return ((find.byWidget(widget).evaluate().single as StatefulElement).state
          as _BuildCountState)
      .buildCount;
}

class BuildCount extends StatefulWidget {
  const BuildCount(this.builder, {Key? key}) : super(key: key);

  final WidgetBuilder builder;

  @override
  _BuildCountState createState() => _BuildCountState();
}

class _BuildCountState extends State<BuildCount> {
  int buildCount = 0;

  @override
  Widget build(BuildContext context) {
    buildCount++;
    return widget.builder(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('buildCount', buildCount));
  }
}

Matcher throwsProviderNotFound<T>() {
  return throwsA(isA<ProviderNotFoundException>()
      .having((err) => err.valueType, 'valueType', T));
}
