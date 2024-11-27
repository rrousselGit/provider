import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppObserver extends ChangeNotifierObserver {
  @override
  void onCreate(String providerName) {
    super.onCreate(providerName);
    debugPrint('$providerName: Created');
  }

  @override
  void onChange(String providerName, dynamic newState) {
    super.onChange(providerName, newState);
    debugPrint('$providerName: State Changed to $newState (from AppObserver)');
  }

  @override
  void onDispose(String providerName) {
    super.onDispose(providerName);
    debugPrint('$providerName: Disposed');
  }
}
