import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

/// A callback that will handle lifecycle callbacks
///
/// To reduce boilerplate code, defining callback at the top level
typedef LifecycleUpdater<T> = T Function();

/// [InternalCallBack] is the object that will be responsible of listening
/// to our lifecycle callbacks and execute them
class InternalCallBack<T> {
  /// To achieve encapsulation, getting callback from public fields and assigning
  /// it to [LifecycleUpdater]
  InternalCallBack({LifecycleUpdater<T>? callback}) : _callback = callback;

  /// To achieve encapsulation, making internal callback private
  LifecycleUpdater<T>? _callback;

  /// In dart every method have a signature of [call], here we're overriding
  /// call method to perform custom processes.
  ///
  /// this [call] method will be responsible of returning [call] method of
  /// [LifecycleUpdater] with return type of [T] which will be the actual
  /// return type of [LifecycleUpdater]
  T call() {
    return _callback!.call();
  }
}

/// Declaring lifecycle mixin, which will be wrapper of all of lifecycle
/// callbacks
mixin BaseLifecycle {
  /// at the top level we declared [InternalCallBack] in which we'll add return
  /// type signature, which will be then executed by [LifecycleUpdater].
  ///
  /// here [InternalCallBack] signature is [void] because this property will
  /// be responsible for giving us notification that whether our ChangeNotifier
  /// has been initialized or not, so there will be no return type in this case
  /// that's why we're moving forward with [void]
  final initialize = InternalCallBack<void>();

  /// To achieve abstraction, put more realistic and understandable callbacks
  /// which will then can be overridden to our actual classes, where ever we
  /// need lifecycle callbacks
  ///
  /// this signature will be used at the public level in [ChangeNotifier] classes
  void onInit() {}

  /// just in case if you want to execute a piece of code after UI frames
  /// rendered then use [onReady] callback
  void onReady() {}

  /// just for checking whether currently pushed [ChangeNotifier] has used
  /// lifecycle before or not, we're adding a flag here to maintain the state
  /// of class, and to achieve encapsulation, we'll scope it accordingly
  bool _initialized = false;

  /// getter for [_initialized] flag, which will be responsible for getting
  /// current state of [ChangeNotifier]
  bool get initialized => _initialized;

  /// setter for [_initialized] flag
  set initialized(bool value) {
    _initialized = value;
  }

  /// Internal method to trigger the callback of [onInit]
  void _onStart() {
    if (initialized) {
      return;
    }
    onInit();

    /// after triggering initialization callback, we'll add post frame callback
    /// here to guarantee that every frame or [Widget] have been rendered,
    /// and we're now executing [onReady]
    SchedulerBinding.instance.addPostFrameCallback((_) => onReady());
    _initialized = true;
  }

  /// finally making a public interface for configuring lifecycle of
  /// [ChangeNotifier]
  void $configureLifeCycle() {
    _checkIfLifeCycleIsAlreadyConfigured();
    (initialize._callback = _onStart)();
  }

  /// check if lifecycle is already configured in one class, in that case if
  /// there is a second request to [$configureLifeCycle] than throw an error
  void _checkIfLifeCycleIsAlreadyConfigured() {
    /// checking if lifecycle is already configured than throw [Exception]
    if (_initialized) {
      throw Exception('You can only configure lifecycle once');
    }
  }
}

/// defining a parent class which will be responsible of triggering, lifecycle
/// request
abstract class LifeCycle with BaseLifecycle {
  /// checking that, whenever Lifecycle used in any of [ChangeNotifier] then
  /// configure lifecycle for that class
  LifeCycle() {
    $configureLifeCycle();
  }
}
