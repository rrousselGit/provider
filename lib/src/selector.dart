import 'package:collection/collection.dart';
import 'package:jaspr/jaspr.dart';

import 'consumer.dart';
import 'provider.dart';
import 'value_listenable_provider.dart';

/// Used by providers to determine whether dependents needs to be updated
/// when the value exposed changes
typedef ShouldRebuild<T> = bool Function(T previous, T next);

/// A base class for custom [Selector].
///
/// It works with any [InheritedComponent]. Variants like [Selector] and
/// [Selector6] are just syntax sugar to use [Selector0] with [Provider.of].
///
/// But it will **not** work with values
/// coming from anything but [InheritedComponent].
///
/// As such, the following:
///
/// ```dart
/// T value;
///
/// return Selector0(
///   selector: (_) => value,
///   builder: ...,
/// )
/// ```
///
/// will still call `builder` again, even if `value` didn't change.
class Selector0<T> extends StatefulComponent {
  /// Both `builder` and `selector` must not be `null`.
  Selector0({
    Key? key,
    required this.builder,
    required this.selector,
    ShouldRebuild<T>? shouldRebuild,
    this.child,
  })  : _shouldRebuild = shouldRebuild,
        super(key: key);

  /// A function that builds a widget tree from `child` and the last result of
  /// [selector].
  ///
  /// [builder] will be called again whenever the its parent widget asks for an
  /// update, or if [selector] return a value that is different from the
  /// previous one using [operator==].
  ///
  /// Must not be `null`.
  final ValueComponentBuilder<T> builder;
  
  /// Component which will be passed to the [builder].
  final Component? child;

  /// A function that obtains some [InheritedComponent] and map their content into
  /// a new object with only a limited number of properties.
  ///
  /// The returned object must implement [operator==].
  ///
  /// Must not be `null`
  final T Function(BuildContext) selector;

  final ShouldRebuild<T>? _shouldRebuild;

  @override
  _Selector0State<T> createState() => _Selector0State<T>();
}

class _Selector0State<T> extends State<Selector0<T>> {
  T? value;
  Component? cache;
  Component? oldWidget;

  @override
  Iterable<Component> build(BuildContext context) sync* {
    final selected = component.selector(context);

    final shouldInvalidateCache = oldWidget != component ||
        (component._shouldRebuild != null &&
            component._shouldRebuild!(value as T, selected)) ||
        (component._shouldRebuild == null &&
            !const DeepCollectionEquality().equals(value, selected));
    if (shouldInvalidateCache) {
      value = selected;
      oldWidget = component;
      cache = component.builder(
        context,
        selected,
        component.child,
      );
    }
    yield cache!;
  }
}

/// {@template provider.selector}
/// An equivalent to [Consumer] that can filter updates by selecting a limited
/// amount of values and prevent rebuild if they don't change.
///
/// [Selector] will obtain a value using [Provider.of], then pass that value
/// to `selector`. That `selector` callback is then tasked to return an object
/// that contains only the information needed for `builder` to complete.
///
/// By default, [Selector] determines if `builder` needs to be called again
/// by comparing the previous and new result of `selector` using
/// [DeepCollectionEquality] from the package `collection`.
///
/// This behavior can be overridden by passing a custom `shouldRebuild` callback.
///
///  **NOTE**:
/// The selected value must be immutable, or otherwise [Selector] may think
/// nothing changed and not call `builder` again.
///
/// As such, it `selector` should return either a collection ([List]/[Map]/[Set]/[Iterable])
/// or a class that override `==`.
///
/// To select multiple values without having to write a class that implements `==`,
/// the easiest solution is to use a "Tuple" from [tuple](https://pub.dev/packages/tuple):
///
/// ```dart
/// Selector<Foo, Tuple2<Bar, Baz>>(
///   selector: (_, foo) => Tuple2(foo.bar, foo.baz),
///   builder: (_, data, __) {
///     return Text('${data.item1}  ${data.item2}');
///   }
/// )
/// ```
///
/// In that example, `builder` will be called again only if `foo.bar` or
/// `foo.baz` changes.
///
/// For generic usage information, see [Consumer].
/// {@endtemplate}
class Selector<A, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector({
    Key? key,
    required ValueComponentBuilder<S> builder,
    required S Function(BuildContext, A) selector,
    ShouldRebuild<S>? shouldRebuild,
    Component? child,
  }) : super(
          key: key,
          shouldRebuild: shouldRebuild,
          builder: builder,
          selector: (context) => selector(context, Provider.of(context)),
          child: child,
        );
}

/// {@macro provider.selector}
class Selector2<A, B, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector2({
    Key? key,
    required ValueComponentBuilder<S> builder,
    required S Function(BuildContext, A, B) selector,
    ShouldRebuild<S>? shouldRebuild,
    Component? child,
  }) : super(
          key: key,
          shouldRebuild: shouldRebuild,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

/// {@macro provider.selector}
class Selector3<A, B, C, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector3({
    Key? key,
    required ValueComponentBuilder<S> builder,
    required S Function(BuildContext, A, B, C) selector,
    ShouldRebuild<S>? shouldRebuild,
    Component? child,
  }) : super(
          key: key,
          shouldRebuild: shouldRebuild,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

/// {@macro provider.selector}
class Selector4<A, B, C, D, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector4({
    Key? key,
    required ValueComponentBuilder<S> builder,
    required S Function(BuildContext, A, B, C, D) selector,
    ShouldRebuild<S>? shouldRebuild,
    Component? child,
  }) : super(
          key: key,
          shouldRebuild: shouldRebuild,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

/// {@macro provider.selector}
class Selector5<A, B, C, D, E, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector5({
    Key? key,
    required ValueComponentBuilder<S> builder,
    required S Function(BuildContext, A, B, C, D, E) selector,
    ShouldRebuild<S>? shouldRebuild,
    Component? child,
  }) : super(
          key: key,
          shouldRebuild: shouldRebuild,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

/// {@macro provider.selector}
class Selector6<A, B, C, D, E, F, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector6({
    Key? key,
    required ValueComponentBuilder<S> builder,
    required S Function(BuildContext, A, B, C, D, E, F) selector,
    ShouldRebuild<S>? shouldRebuild,
    Component? child,
  }) : super(
          key: key,
          shouldRebuild: shouldRebuild,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}
