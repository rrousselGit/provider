import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart' show spyPostEvent;

void main() {
  testWidgets('DevTools inspection preserves lazy provider creation', (
    tester,
  ) async {
    var createCalls = 0;
    final key = GlobalKey();

    await tester.pumpWidget(
      Provider<int>(
        create: (_) {
          createCalls++;
          return 42;
        },
        child: Container(key: key),
      ),
    );

    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isFalse);
    expect(node.value, isNull);
    expect(createCalls, 0);

    expect(key.currentContext!.read<int>(), 42);
    expect(createCalls, 1);
    expect(node.isInitialized, isTrue);
    expect(node.value, 42);
  });

  testWidgets('DevTools distinguishes an initialized null value', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<int?>.value(value: null, child: Container()),
    );

    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isTrue);
    expect(node.value, isNull);
  });

  for (final createController in [false, true]) {
    testWidgets(
        'DevTools preserves deferred laziness (create: $createController)',
        (tester) async {
      var createCalls = 0;
      var listenCalls = 0;
      var cancelCalls = 0;
      final key = GlobalKey();

      VoidCallback startListening(
        InheritedContext<int?> context,
        void Function(int) setState,
        int controller,
        int? previous,
      ) {
        listenCalls++;
        setState(controller);
        return () => cancelCalls++;
      }

      final child = SizedBox(key: key);
      await tester.pumpWidget(
        createController
            ? DeferredInheritedProvider<int, int>(
                create: (_) {
                  createCalls++;
                  return 42;
                },
                startListening: startListening,
                child: child,
              )
            : DeferredInheritedProvider<int, int>.value(
                value: 42,
                startListening: startListening,
                child: child,
              ),
      );

      final node = ProviderBinding.debugInstance.providerDetails.values.single;
      expect(node.isInitialized, isFalse);
      expect(node.value, isNull);
      expect(createCalls, 0);
      expect(listenCalls, 0);

      expect(key.currentContext!.read<int>(), 42);
      expect(node.isInitialized, isTrue);
      expect(node.value, 42);
      expect(createCalls, createController ? 1 : 0);
      expect(listenCalls, 1);

      await tester.pumpWidget(const SizedBox());
      expect(cancelCalls, 1);
    });
  }

  for (final deferred in [false, true]) {
    testWidgets(
        'first application read emits initialization (deferred: $deferred)',
        (tester) async {
      final spy = spyPostEvent();
      addTearDown(spy.dispose);
      final key = GlobalKey();
      final child = SizedBox(key: key);
      await tester.pumpWidget(
        deferred
            ? DeferredInheritedProvider<int, int>.value(
                value: 42,
                startListening: (_, setState, controller, previous) {
                  setState(controller);
                  return () {};
                },
                child: child,
              )
            : Provider<int>(create: (_) => 42, child: child),
      );
      final node = ProviderBinding.debugInstance.providerDetails.values.single;
      spy.logs.clear();
      expect(node.value, isNull);
      expect(spy.logs, isEmpty);
      expect(key.currentContext!.read<int>(), 42);
      expect(spy.logs, hasLength(1));
      expect(spy.logs.single.eventKind, 'provider:provider_changed');
      expect(spy.logs.single.event, {'id': node.id});
      expect(key.currentContext!.read<int>(), 42);
      expect(node.value, 42);
      expect(spy.logs, hasLength(1));
    });
  }

  testWidgets('failed creation refreshes inspection and survives reassembly',
      (tester) async {
    final spy = spyPostEvent();
    addTearDown(spy.dispose);
    final key = GlobalKey();
    final error = StateError('creation failed');
    await tester.pumpWidget(Provider<int>(
      create: (_) => throw error,
      child: SizedBox(key: key),
    ));
    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    spy.logs.clear();
    expect(() => key.currentContext!.read<int>(), throwsA(same(error)));
    expect(() => node.value, throwsStateError);
    final reassembly = tester.binding.reassembleApplication();
    await tester.pump();
    await reassembly;
    expect(() => key.currentContext!.read<int>(), throwsStateError);
    expect(() => node.value, throwsStateError);
    expect(spy.logs, hasLength(1));
    expect(spy.logs.single.eventKind, 'provider:provider_changed');
  });

  testWidgets('inspecting a value notifier does not subscribe', (tester) async {
    final notifier = _InspectableNotifier();
    addTearDown(notifier.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: notifier, child: SizedBox(key: key)),
    );
    final node = ProviderBinding.debugInstance.providerDetails.values.single;
    expect(node.isInitialized, isTrue);
    expect(node.value, same(notifier));
    // ignore: unawaited_futures
    tester.binding.reassembleApplication();
    expect(notifier.reassembleCalls, 1);
    expect(notifier.isSubscribed, isFalse);
    expect(key.currentContext!.read<_InspectableNotifier>(), same(notifier));
    expect(notifier.isSubscribed, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(notifier.isSubscribed, isFalse);
  });
}

class _InspectableNotifier extends ChangeNotifier implements ReassembleHandler {
  int reassembleCalls = 0;

  @override
  void reassemble() => reassembleCalls++;

  bool get isSubscribed => hasListeners;
}
