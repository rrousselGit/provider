import 'package:flutter/widgets.dart';

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923
Type _typeOf<T>() => T;

/// An helper to easily exposes a value using [InheritedWidget]
/// without having to write one.
class Provider<T> extends InheritedWidget {
  /// The value exposed to other widgets.
  ///
  /// You can obtain this value this widget's descendants
  /// using [Provider.of] method
  final T value;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedWidget.updateShouldNotify] is called.
  /// It should return [false] when there's no need to update its dependents.
  ///
  /// The default behavior is `previous == current`
  final bool Function(T previous, T current) _updateShouldNotify;

  const Provider({
    Key key,
    this.value,
    Widget child,
    bool Function(T previous, T current) updateShouldNotify,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

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
    if (_updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget.value, value);
    }
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
  /// [previous] is `null` on the first call
  /// Since it is called on [initState] and [didUpdateWidget], it is not
  /// possible to subscribe to an [InheritedWidget] using this method.
  /// Use [didChangeDependencies] instead.
  final T Function(BuildContext context, T previous) valueBuilder;

  /// [didChangeDependencies] is a hook to [State.didChangeDependencies]
  /// It can be used to build/update values depending on an [InheritedWidget]
  final T Function(BuildContext context, T value) didChangeDependencies;

  /// [onDispose] is a callback called when [StatefulProvider] is
  /// removed for the widget tree, and pass the current value as parameter.
  /// It is useful when the provided object needs to have a custom dipose behavior,
  /// such as closing streams.
  final void Function(BuildContext context, T value) onDispose;
  final Widget child;
  final bool Function(T previous, T current) updateShouldNotify;

  const StatefulProvider({
    Key key,
    this.valueBuilder,
    this.child,
    this.onDispose,
    this.didChangeDependencies,
    this.updateShouldNotify,
  })  : assert(valueBuilder != null || didChangeDependencies != null),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.didChangeDependencies != null) {
      _value = widget.didChangeDependencies(context, _value);
    }
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(context, _value);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      value: _value,
      updateShouldNotify: widget.updateShouldNotify,
      child: widget.child,
    );
  }

  void _buildValue() {
    if (widget.valueBuilder != null) {
      _value = widget.valueBuilder(context, _value);
    }
  }
}
