abstract class ChangeNotifierObserver {
  void onCreate(String providerName) {}

  void onChange(String providerName, dynamic newState) {}

  void onDispose(String providerName) {}
}
