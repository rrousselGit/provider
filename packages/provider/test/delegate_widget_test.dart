// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('DelegateWidget', () {
    testWidgets(
        "can't call context.inheritFromWidgetOfExactType from first initDelegate",
        (tester) async {
      await tester.pumpWidget(Provider.value(
        value: 42,
        child: TestDelegateWidget(
          delegate: InitDelegate(),
          child: Container(),
        ),
      ));

      expect(tester.takeException(), isFlutterError);
    });
    testWidgets(
        "can't call context.inheritFromWidgetOfExactType from initDelegate after an update",
        (tester) async {
      await tester.pumpWidget(Provider.value(
        value: 42,
        child: TestDelegateWidget(
          delegate: SingleValueDelegate(42),
          child: Container(),
        ),
      ));

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(Provider.value(
        value: 42,
        child: TestDelegateWidget(
          delegate: InitDelegate(),
          child: Container(),
        ),
      ));

      expect(tester.takeException(), isFlutterError);
    });
    testWidgets('mount initializes setState and context and calls initDelegate',
        (tester) async {
      final state = MockStateDelegate<int>();
      final key = GlobalKey();

      expect(state.context, isNull);
      expect(state.setState, isNull);
      verifyZeroInteractions(state.initDelegateMock);

      await tester.pumpWidget(TestDelegateWidget(
        key: key,
        delegate: state,
        child: Container(),
      ));

      expect(state.context, key.currentContext);
      expect(state.setState, key.currentState.setState);

      verify(state.initDelegateMock(
        key.currentContext,
        key.currentState.setState,
      )).called(1);
      verifyZeroInteractions(state.didUpdateDelegateMock);
      verifyZeroInteractions(state.disposeMock);
    });
    testWidgets(
        'rebuilding with delegate of the same type calls didUpdateDelegate',
        (tester) async {
      final state = MockStateDelegate<int>();
      final state2 = MockStateDelegate<int>();
      final key = GlobalKey();

      await tester.pumpWidget(TestDelegateWidget(
        key: key,
        delegate: state,
        child: Container(),
      ));
      clearInteractions(state.initDelegateMock);

      final context = key.currentContext;
      final setState = key.currentState.setState;

      await tester.pumpWidget(TestDelegateWidget(
        key: key,
        delegate: state2,
        child: Container(),
      ));

      expect(state.context, isNull);
      expect(state.setState, isNull);
      verifyZeroInteractions(state.initDelegateMock);
      verifyZeroInteractions(state.didUpdateDelegateMock);
      verifyZeroInteractions(state.disposeMock);

      expect(state2.context, context);
      expect(state2.setState, setState);
      verify(state2.didUpdateDelegate(state)).called(1);
      verifyZeroInteractions(state2.initDelegateMock);
      verifyNoMoreInteractions(state2.didUpdateDelegateMock);
      verifyZeroInteractions(state2.disposeMock);
    });
    testWidgets(
        'rebuilding with delegate of a different type disposes the previous and init the new one',
        (tester) async {
      final state = MockStateDelegate<int>();
      final state2 = MockStateDelegate<String>();
      final key = GlobalKey();

      await tester.pumpWidget(TestDelegateWidget(
        key: key,
        delegate: state,
        child: Container(),
      ));
      clearInteractions(state.initDelegateMock);

      final context = key.currentContext;
      final setState = key.currentState.setState;

      await tester.pumpWidget(TestDelegateWidget(
        key: key,
        delegate: state2,
        child: Container(),
      ));

      expect(state.context, isNull);
      expect(state.setState, isNull);

      verifyZeroInteractions(state.initDelegateMock);
      verifyZeroInteractions(state.didUpdateDelegateMock);
      verify(state.disposeMock(context, setState)).called(1);
      verifyNoMoreInteractions(state.disposeMock);

      expect(state2.context, key.currentContext);
      expect(state2.setState, key.currentState.setState);

      verify(state2.initDelegateMock(context, setState)).called(1);
      verifyNoMoreInteractions(state2.initDelegateMock);
      verifyNoMoreInteractions(state2.didUpdateDelegateMock);
      verifyZeroInteractions(state2.disposeMock);
    });

    testWidgets('unmounting the widget calls delegate.dispose', (tester) async {
      final state = MockStateDelegate<int>();
      final key = GlobalKey();

      await tester.pumpWidget(TestDelegateWidget(
        key: key,
        delegate: state,
        child: Container(),
      ));
      clearInteractions(state.initDelegateMock);

      final context = key.currentContext;
      final setState = key.currentState.setState;

      await tester.pumpWidget(Container());

      expect(state.context, isNull);
      expect(state.setState, isNull);
      verifyZeroInteractions(state.initDelegateMock);
      verifyZeroInteractions(state.didUpdateDelegateMock);
      verify(state.disposeMock(context, setState)).called(1);
      verifyNoMoreInteractions(state.disposeMock);
    });

    test('throws if delegate is null', () {
      expect(
        () => TestDelegateWidget(child: Container()),
        throwsAssertionError,
      );
    });
  });

  group('SingleValueDelegate', () {
    test('implements ValueStateDelegate', () {
      expect(
        SingleValueDelegate(0),
        isInstanceOf<ValueStateDelegate<int>>(),
      );
    });

    testWidgets('stores and update value', (tester) async {
      int value;
      BuildContext context;
      final key = GlobalKey();

      await tester.pumpWidget(BuilderDelegateWidget<SingleValueDelegate<int>>(
        key: key,
        delegate: SingleValueDelegate(0),
        builder: (c, d) {
          value = d.value;
          context = c;
          return Container();
        },
      ));

      expect(context, equals(key.currentContext));
      expect(value, equals(0));

      await tester.pumpWidget(BuilderDelegateWidget<SingleValueDelegate<int>>(
        key: key,
        delegate: SingleValueDelegate(42),
        builder: (c, d) {
          value = d.value;
          context = c;
          return Container();
        },
      ));

      expect(context, equals(key.currentContext));
      expect(value, equals(42));
    });
  });

  group('BuilderStateDelegate', () {
    test('implements ValueStateDelegate', () {
      expect(
        BuilderStateDelegate((_) => 42),
        isInstanceOf<ValueStateDelegate<int>>(),
      );
    });
    test('throws if builder is missing', () {
      expect(
        () => BuilderStateDelegate<dynamic>(null),
        throwsAssertionError,
      );
    });

    testWidgets('initialize value and never recreate it', (tester) async {
      int value;
      BuildContext context;
      final key = GlobalKey();

      await tester
          .pumpWidget(BuilderDelegateWidget<BuilderStateDelegate<int>>(
        key: key,
        delegate: BuilderStateDelegate((_) => 42),
        builder: (c, d) {
          value = d.value;
          context = c;
          return Container();
        },
      ));

      expect(context, equals(key.currentContext));
      expect(value, equals(42));

      await tester
          .pumpWidget(BuilderDelegateWidget<BuilderStateDelegate<int>>(
        key: key,
        delegate: BuilderStateDelegate((_) => 0),
        builder: (c, d) {
          value = d.value;
          context = c;
          return Container();
        },
      ));

      expect(context, equals(key.currentContext));
      expect(value, equals(42));
    });

    testWidgets('initialize value and never recreate it', (tester) async {
      final disposeMock = DisposerMock<int>();
      final key = GlobalKey();
      final delegate2 = BuilderStateDelegate(
        (_) => 42,
        dispose: disposeMock,
      );

      await tester
          .pumpWidget(BuilderDelegateWidget<BuilderStateDelegate<int>>(
        key: key,
        delegate: delegate2,
        builder: (_, __) => Container(),
      ));

      final context = key.currentContext;

      verifyZeroInteractions(disposeMock);

      await tester.pumpWidget(Container());

      verify(disposeMock(context, 42)).called(1);
      verifyNoMoreInteractions(disposeMock);
    });
  });
}

class InitDelegate extends StateDelegate {
  @override
  void initDelegate() {
    super.initDelegate();
    Provider.of<int>(context);
  }
}

class InitDelegateMock extends Mock {
  void call(BuildContext context, StateSetter setState);
}

class DidUpdateDelegateMock extends Mock {
  void call(StateDelegate old);
}

class DisposeMock extends Mock {
  void call(BuildContext context, StateSetter setState);
}

class MockStateDelegate<T> extends StateDelegate {
  final disposeMock = DisposeMock();
  final initDelegateMock = InitDelegateMock();
  final didUpdateDelegateMock = DidUpdateDelegateMock();

  @override
  void initDelegate() {
    super.initDelegate();
    initDelegateMock(context, setState);
  }

  @override
  void didUpdateDelegate(StateDelegate old) {
    super.didUpdateDelegate(old);
    didUpdateDelegateMock(old);
  }

  @override
  void dispose() {
    disposeMock(context, setState);
    super.dispose();
  }
}

class BuilderDelegateWidget<T extends ValueStateDelegate<dynamic>>
    extends ValueDelegateWidget<dynamic> {
  BuilderDelegateWidget({Key key, this.builder, T delegate})
      : super(key: key, delegate: delegate);

  final Widget Function(BuildContext context, T delegate) builder;

  @override
  Widget build(BuildContext context) => builder(context, delegate as T);
}

class TestDelegateWidget extends DelegateWidget {
  TestDelegateWidget({Key key, this.child, StateDelegate delegate})
      : super(key: key, delegate: delegate);

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
