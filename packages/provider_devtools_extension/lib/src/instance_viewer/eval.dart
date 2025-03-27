// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A few utilities related to evaluating dart code

library eval;

import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vm_service/vm_service.dart';

final serviceProvider = StreamProvider<VmService>((ref) {
  final controller = StreamController<VmService>.broadcast();
  void handleConnectionChange() {
    final isConnected = serviceManager.connectedState.value.connected;
    final isServiceAvailable = serviceManager.isServiceAvailable;
    if (isConnected && isServiceAvailable) {
      controller.add(serviceManager.service!);
    }
  }

  serviceManager.connectedState.addListener(handleConnectionChange);

  handleConnectionChange();

  ref.onDispose(() {
    serviceManager.connectedState.removeListener(handleConnectionChange);
    controller.close();
  });

  return controller.stream;
});

/// An [EvalOnDartLibrary] that has access to no specific library in particular
///
/// Not suitable to be used when evaluating third-party objects, as it would
/// otherwise not be possible to read private properties.
final evalProvider = libraryEvalProvider('dart:io');

/// An [EvalOnDartLibrary] that has access to `provider`
final providerEvalProvider =
    libraryEvalProvider('package:provider/src/provider.dart');

/// An [EvalOnDartLibrary] for custom objects.
final libraryEvalProvider =
    FutureProviderFamily<EvalOnDartLibrary, String>((ref, libraryPath) async {
  final service = await ref.watch(serviceProvider.future);

  final eval = EvalOnDartLibrary(
    libraryPath,
    service,
    serviceManager: serviceManager,
  );
  ref.onDispose(eval.dispose);
  return eval;
});

final hotRestartEventProvider =
    ChangeNotifierProvider<ValueNotifier<void>>((ref) {
  final selectedIsolateListenable =
      serviceManager.isolateManager.selectedIsolate;

  // Since ChangeNotifierProvider calls `dispose` on the returned ChangeNotifier
  // when the provider is destroyed, we can't simply return `selectedIsolateListenable`.
  // So we're making a copy of it instead.
  final notifier = ValueNotifier<IsolateRef?>(selectedIsolateListenable.value);

  void listener() => notifier.value = selectedIsolateListenable.value;
  selectedIsolateListenable.addListener(listener);
  ref.onDispose(() => selectedIsolateListenable.removeListener(listener));

  return notifier;
});
