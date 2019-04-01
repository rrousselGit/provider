import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/src/adaptative_builder_widget.dart';

class BuilderMock extends Mock {
  void call(BuildContext context, int value);
}

class DisposeMock extends Mock {
  void call(Foo foo);
}

class DidBuildMock extends Mock {
  void call(Foo value);
}

class ValueBuilderMock extends Mock {
  ValueBuilderMock([Foo foo]) {
    if (foo != null) when(this(any)).thenReturn(foo);
  }

  Foo call(BuildContext context);
}

class Foo {
  Foo(this.bar);

  final int bar;
}

class Test extends AdaptativeBuilderWidget<int, Foo> {
  Test(
      {Key key,
      this.buildValue,
      this.didBuild,
      this.dispose,
      ValueBuilder<Foo> builder})
      : super(key: key, builder: builder);

  Test.value({Key key, this.buildValue, this.didBuild, this.dispose, int value})
      : super.value(key: key, value: value);

  final BuilderMock buildValue;
  final DidBuildMock didBuild;
  final DisposeMock dispose;

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test>
    with AdaptativeBuilderWidgetStateMixin<int, Foo, Test> {
  @override
  Widget build(BuildContext context) {
    if (widget.buildValue != null) {
      widget.buildValue(context, value);
    }
    return Text(value.toString(), textDirection: TextDirection.ltr);
  }

  @override
  int didBuild(Foo built) {
    if (widget.didBuild != null) {
      widget.didBuild(built);
    }
    return built?.bar;
  }

  @override
  void disposeBuilt(Test oldWidget, Foo built) {
    if (widget.dispose != null) {
      widget.dispose(built);
    }
  }
}

void main() {
  group('adaptive', () {
    test('both constructors have the same runtimeType', () {
      final defaultConstructor = Test(builder: (_) => null);
      final valueConstructor = Test.value();

      expect(
        defaultConstructor.runtimeType,
        valueConstructor.runtimeType,
        reason:
            'constructors must not be factories otherwise switching between them destroys the state of the widget tree.',
      );
    });
    test('builder cannot be null', () {
      expect(() => Test(), throwsAssertionError);
    });
    test('value can be null', () {
      Test.value(value: null);
    });
    group('builder constructor', () {
      testWidgets('handle null', (tester) async {
        final builder = ValueBuilderMock(null);
        final didBuild = DidBuildMock();
        final buildValue = BuilderMock();
        final dispose = DisposeMock();
        await tester.pumpWidget(Test(
          builder: builder,
          didBuild: didBuild,
          buildValue: buildValue,
          dispose: dispose,
        ));

        final context = tester.element(find.byType(Test));

        expect(find.text('null'), findsOneWidget);
        verifyInOrder([
          builder(context),
          didBuild(null),
          buildValue(context, null),
        ]);
        verifyZeroInteractions(dispose);
        verifyNoMoreInteractions(builder);
        verifyNoMoreInteractions(didBuild);
        verifyNoMoreInteractions(buildValue);
      });
      testWidgets('initial mount calls builder', (tester) async {
        final foo = Foo(42);
        final builder = ValueBuilderMock(foo);
        final didBuild = DidBuildMock();
        final build = BuilderMock();
        final dispose = DisposeMock();

        await tester.pumpWidget(Test(
          builder: builder,
          didBuild: didBuild,
          buildValue: build,
          dispose: dispose,
        ));

        final context = tester.element(find.byType(Test));

        expect(find.text('42'), findsOneWidget);
        verifyInOrder([
          builder(context),
          didBuild(foo),
          build(context, 42),
        ]);
        verifyZeroInteractions(dispose);
        verifyNoMoreInteractions(builder);
        verifyNoMoreInteractions(didBuild);
        verifyNoMoreInteractions(build);
      });
      testWidgets('unmounting widget dispose built value', (tester) async {
        final foo = Foo(42);
        final dispose = DisposeMock();
        await tester.pumpWidget(Test(
          builder: (_) => foo,
          dispose: dispose,
        ));

        await tester.pumpWidget(Container());

        verify(dispose(foo));
        verifyNoMoreInteractions(dispose);
      });
      testWidgets('rebuilding widget is noop', (tester) async {
        final foo = Foo(42);
        final dispose = DisposeMock();
        final builder = ValueBuilderMock(foo);
        final didBuild = DidBuildMock();
        final buildValue = BuilderMock();

        final build = () => Test(
              builder: builder,
              dispose: dispose,
              buildValue: buildValue,
              didBuild: didBuild,
            );
        await tester.pumpWidget(build());

        await tester.pumpWidget(build());
        final context = tester.element(find.byType(Test));

        expect(find.text('42'), findsOneWidget);
        verifyInOrder([
          builder(context),
          didBuild(foo),
          buildValue(context, 42),
          buildValue(context, 42),
        ]);
        verifyZeroInteractions(dispose);
        verifyNoMoreInteractions(builder);
        verifyNoMoreInteractions(didBuild);
        verifyNoMoreInteractions(buildValue);
      });
    });
    group('value constructor', () {
      testWidgets('works with null', (tester) async {
        final didBuild = DidBuildMock();
        final buildValue = BuilderMock();
        final dispose = DisposeMock();

        await tester.pumpWidget(Test.value(
          value: null,
          didBuild: didBuild,
          buildValue: buildValue,
          dispose: dispose,
        ));

        final context = tester.element(find.byType(Test));

        expect(find.text('null'), findsOneWidget);
        verify(buildValue(context, null)).called(1);
        verifyZeroInteractions(dispose);
        verifyZeroInteractions(didBuild);
        verifyNoMoreInteractions(buildValue);
      });
      testWidgets("mount don't call life-cycles", (tester) async {
        final didBuild = DidBuildMock();
        final buildValue = BuilderMock();
        final dispose = DisposeMock();

        await tester.pumpWidget(Test.value(
          value: 42,
          didBuild: didBuild,
          buildValue: buildValue,
          dispose: dispose,
        ));

        final context = tester.element(find.byType(Test));

        expect(find.text('42'), findsOneWidget);
        verify(buildValue(context, 42)).called(1);
        verifyZeroInteractions(dispose);
        verifyZeroInteractions(didBuild);
        verifyNoMoreInteractions(buildValue);
      });
      testWidgets('rebuilding widget updates with new value', (tester) async {
        final didBuild = DidBuildMock();
        final buildValue = BuilderMock();
        final dispose = DisposeMock();

        await tester.pumpWidget(Test.value(
          value: 42,
          didBuild: didBuild,
          buildValue: buildValue,
          dispose: dispose,
        ));
        await tester.pumpWidget(Test.value(
          value: 43,
          didBuild: didBuild,
          buildValue: buildValue,
          dispose: dispose,
        ));

        final context = tester.element(find.byType(Test));

        expect(find.text('43'), findsOneWidget);
        verifyInOrder([
          buildValue(context, 42),
          buildValue(context, 43),
        ]);
        verifyZeroInteractions(dispose);
        verifyZeroInteractions(didBuild);
        verifyNoMoreInteractions(buildValue);
      });
      testWidgets("dispose don't call life-cycle", (tester) async {
        final dispose = DisposeMock();

        await tester.pumpWidget(Test.value(
          value: 42,
          dispose: dispose,
        ));
        await tester.pumpWidget(Container());

        verifyZeroInteractions(dispose);
      });
    });

    group('from builder to value constructor', () {
      testWidgets('disposes of the built value', (tester) async {
        final foo = Foo(42);
        final builder = ValueBuilderMock(foo);
        final dispose = DisposeMock();

        await tester.pumpWidget(Test(
          builder: builder,
        ));
        clearInteractions(builder);

        await tester.pumpWidget(Test.value(
          value: 24,
          dispose: dispose,
        ));

        expect(find.text('24'), findsOneWidget);

        verify(dispose(foo)).called(1);
        verifyNoMoreInteractions(dispose);
        verifyNoMoreInteractions(builder);
      });
    });
  });
  group('from value to builder constructor', () {
    testWidgets('build value', (tester) async {
      final foo = Foo(24);
      final builder = ValueBuilderMock(foo);
      final didBuild = DidBuildMock();
      final buildValue = BuilderMock();
      final dispose = DisposeMock();

      await tester.pumpWidget(Test.value(
        value: 42,
      ));

      await tester.pumpWidget(Test(
        builder: builder,
        didBuild: didBuild,
        buildValue: buildValue,
        dispose: dispose,
      ));
      final context = tester.element(find.byType(Test));

      verifyInOrder([
        builder(context),
        didBuild(foo),
        buildValue(context, 24),
      ]);

      verifyNoMoreInteractions(dispose);
      verifyNoMoreInteractions(builder);
    });
  });
}
