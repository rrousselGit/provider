// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// Generator: FunctionalWidget
// **************************************************************************

/// A [Provider] that exposes a value obtained from a [Hook].
///
/// [HookProvider] will rebuild and potentially expose a new value if the hooks used ask for it.
class HookProvider<T> extends HookWidget {
  /// A [Provider] that exposes a value obtained from a [Hook].
  ///
  /// [HookProvider] will rebuild and potentially expose a new value if the hooks used ask for it.
  const HookProvider(
      {Key key, this.hook, @required this.child, this.updateShouldNotify})
      : super(key: key);

  /// A [Provider] that exposes a value obtained from a [Hook].
  ///
  /// [HookProvider] will rebuild and potentially expose a new value if the hooks used ask for it.
  final T Function() hook;

  /// A [Provider] that exposes a value obtained from a [Hook].
  ///
  /// [HookProvider] will rebuild and potentially expose a new value if the hooks used ask for it.
  final Widget child;

  /// A [Provider] that exposes a value obtained from a [Hook].
  ///
  /// [HookProvider] will rebuild and potentially expose a new value if the hooks used ask for it.
  final bool Function(T, T) updateShouldNotify;

  @override
  Widget build(BuildContext _context) => hookProvider<T>(
      hook: hook, child: child, updateShouldNotify: updateShouldNotify);
  @override
  int get hashCode => hashValues(hook, child, updateShouldNotify);
  @override
  bool operator ==(Object o) =>
      identical(o, this) ||
      (o is HookProvider<T> &&
          hook == o.hook &&
          child == o.child &&
          updateShouldNotify == o.updateShouldNotify);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<dynamic>.has('hook', hook));
    properties.add(DiagnosticsProperty<Widget>('child', child));
    properties.add(ObjectFlagProperty<dynamic>.has(
        'updateShouldNotify', updateShouldNotify));
  }
}
