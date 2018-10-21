import 'package:flutter/widgets.dart';

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923
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

/// A wrapper over [Provider] to make exposing complex objets
///
/// It is usuallt used to create once an object, to not recreate it on every [build] call
/// without having to manually create a [StatefulWidget]
///
/// ```
/// class Model {}
///
/// class Stateless extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return StatefulProvider<Model>(
///       valueBuilder: (context, old) =>  old ?? Model(),
///       child: ...,
///     );
///   }
/// }
/// ```
class StatefulProvider<T> extends StatefulWidget {
  /// [valueBuilder] is called on [initState] and [didUpdateWidget]
  /// [previous] is the previous value returned by [valueBuilder].
  /// It is `null` on the first call
  /// [valueBuilder] must not be null.
  final T Function(BuildContext context, T previous) valueBuilder;

  /// [onDispose] is a callback called when [StatefulProvider] is
  /// removed for the widget tree, and pass the current value as parameter.
  /// It is useful when the provided object needs to have a custom dipose behavior,
  /// such as closing streams.
  final void Function(BuildContext context, T value) onDispose;
  final Widget child;

  const StatefulProvider(
      {Key key, @required this.valueBuilder, this.child, this.onDispose})
      : assert(valueBuilder != null),
        super(key: key);

  @override
  _StatefulProviderState<T> createState() => _StatefulProviderState<T>();
}

class _StatefulProviderState<T> extends State<StatefulProvider<T>> {
  T _value;

  @override
  void initState() {
    super.initState();
    _buildValue();
  }

  @override
  void didUpdateWidget(StatefulProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildValue();
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.onDispose != null) {
      widget.onDispose(context, _value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      value: _value,
      child: widget.child,
    );
  }

  void _buildValue() {
    _value = widget.valueBuilder(context, _value);
  }
}
