/// An observer that tracks lifecycle events of ChangeNotifier instances.
///
/// This observer can be used to monitor the creation, state changes, and disposal
/// of providers. Extend this class and override the methods to implement custom
/// tracking logic.
abstract class ChangeNotifierObserver {
  /// Called when a new ChangeNotifier instance is created.
  ///
  /// [providerName] identifies the provider being created.
  void onCreate(String? providerName) {}

  /// Called when the state of a ChangeNotifier changes.
  ///
  /// [providerName] identifies the provider that changed.
  /// [newState] represents the updated state.
  void onChange(String? providerName, Object? newState) {}

  /// Called when a ChangeNotifier instance is disposed.
  ///
  /// [providerName] identifies the provider being disposed.
  void onDispose(String? providerName) {}
}
