import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart'
    hide widget;

part 'provider.g.dart';

/// Necessary to obtain generic [Type]
/// see https://stackoverflow.com/questions/52891537/how-to-get-generic-type
/// and https://github.com/dart-lang/sdk/issues/11923
Type _typeOf<T>() => T;

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

/// A generic implementation of an [InheritedWidget]
///
/// It is possible to customize the behavior of [InheritedWidget.updateShouldNotify]
/// by passing a callback with the desired behavior.
class Provider<T> extends InheritedWidget {
  /// The value exposed to other widgets.
  ///
  /// You can obtain this value this widget's descendants
  /// using [Provider.of] method
  final T value;

  // has a different name then the actual method
  // so that it can have documentation
  /// A callback called whenever [InheritedWidget.updateShouldNotify] is called.
  /// It should return `false` when there's no need to update its dependents.
  ///
  /// The default behavior is `previous == current`
  final bool Function(T previous, T current) _updateShouldNotify;

  /// Creates a [Provider] and pass down [value] to all of its descendants
  const Provider({
    Key key,
    @required this.value,
    @required Widget child,
    UpdateShouldNotify<T> updateShouldNotify,
  })  : _updateShouldNotify = updateShouldNotify,
        super(key: key, child: child);

  /// Obtain the nearest Provider<T> and returns its value.
  ///
  /// If [listen] is true (default), later value changes will
  /// trigger a new [State.build] to widgets, and [State.didChangeDependencies] for [StatefulWidget]
  static T of<T>(BuildContext context, {bool listen = true}) {
    // this is required to get generic Type
    final type = _typeOf<Provider<T>>();
    final provider = listen
        ? context.inheritFromWidgetOfExactType(type) as Provider<T>
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget
            as Provider<T>;
    return provider?.value;
  }

  @override
  bool updateShouldNotify(Provider<T> oldWidget) {
    if (_updateShouldNotify != null) {
      return _updateShouldNotify(oldWidget.value, value);
    }
    return oldWidget.value != value;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
  }
}

/// A wrapper over [Provider] to make exposing complex objets
///
/// It is usuallt used to create once an object, to not recreate it on every [State.build] call
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
@Deprecated('Prefer HookBuilder combined with useState hook instead')
class StatefulProvider<T> extends StatefulWidget {
  /// [valueBuilder] is called on [State.initState] and [State.didUpdateWidget]
  ///
  /// The second argument of [valueBuilder] is the previous value returned by [valueBuilder].
  /// This value will be `null` on the first call.
  ///
  /// It is not possible to obtain an [InheritedWidget] from [valueBuilder].
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

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A customizable implementation for [InheritedWidget.updateShouldNotify]
  final bool Function(T previous, T current) updateShouldNotify;

  /// Allows to specify parameters to [StatefulProvider]
  StatefulProvider({
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

@deprecated
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

/// A [Provider] that exposes a value obtained from a [Hook].
///
/// [HookProvider] will rebuild and potentially expose a new value if the hooks used ask for it.
@hwidget
Widget hookProvider<T>(
    {T hook(),
    @required Widget child,
    UpdateShouldNotify<T> updateShouldNotify}) {
  return Provider<T>(
    value: hook(),
    child: child,
    updateShouldNotify: updateShouldNotify,
  );
}
