import 'package:flutter/widgets.dart';

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
Type _typeOf<T>() => T;

/// An helper to easily exposes a value using [InheritedWidget]
/// without having to write one.
class Provider<T> extends InheritedWidget {
  final T value;

  const Provider({Key key, this.value, Widget child})
      : super(key: key, child: child);

  /// Obtain the nearest Provider<T> and returns its value.
  ///
  /// If [listen] is true (default), later value changes will
  /// trigger a new [build] to widgets, and [didChangeDependencies] for [StatefulWidget]
  static T of<T>(BuildContext context, {bool listen = true}) {
    // this is required to get generic Type
    final type = _typeOf<Provider<T>>();
    final Provider<T> provider = listen
        ? context.inheritFromWidgetOfExactType(type)
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget;
    return provider?.value;
  }

  @override
  bool updateShouldNotify(Provider<T> oldWidget) {
    return oldWidget.value != value;
  }
}
