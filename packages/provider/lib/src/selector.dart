import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

import 'consumer.dart';
import 'delegate_widget.dart';

/// A base class for custom [Selector].
///
/// It works with any [InheritedWidget]. Variants like [Selector] and
/// [Selector6] are just syntax sugar to use [Selector0] with [Provider.of].
///
/// But it will **not** work with values
/// coming from anything but [InheritedWidget].
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
class Selector0<T> extends StatefulWidget
    implements SingleChildCloneableWidget {
  /// Both `builder` and `selector` must not be `null`.
  Selector0({
    Key key,
    @required this.builder,
    @required this.selector,
    this.child,
  })  : assert(builder != null),
        assert(selector != null),
        super(key: key);

  /// A function that builds a widget tree from [child] and the last result of
  /// [selector].
  ///
  /// [builder] will be called again whenever the its parent widget asks for an
  /// update, or if [selector] return a value that is different from the
  /// previous one using [operator==].
  ///
  /// Must not be `null`.
  final ValueWidgetBuilder<T> builder;

  /// A function that obtains some [InheritedWidget] and map their content into
  /// a new object with only a limited number of properties.
  ///
  /// The returned object must implement [operator==].
  ///
  /// Must not be `null`
  final ValueBuilder<T> selector;

  /// A cache of a widget tree that does not depend on the value of [selector].
  ///
  /// See [Consumer] for an explanation on how to use it.
  final Widget child;

  @override
  _Selector0State<T> createState() => _Selector0State<T>();

  @override
  Selector0<T> cloneWithChild(Widget child) {
    return Selector0(
      key: key,
      selector: selector,
      builder: builder,
      child: child,
    );
  }
}

class _Selector0State<T> extends State<Selector0<T>> {
  T value;
  Widget cache;
  Widget oldWidget;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selector(context);

    if (oldWidget != widget || selected != value) {
      value = selected;
      oldWidget = widget;
      cache = widget.builder(
        context,
        selected,
        widget.child,
      );
    }
    return cache;
  }
}

/// {@template provider.selector}
/// An equivalent to [Consumer] that can filter updates by selecting a limited
/// amount of values and prevent rebuild if they don't change.
///
/// [Selector] will obtain a value using [Provider.of], then pass that value
/// to `selector`. That `selector` callback is then tasked to return an object
/// that contains only the informations needed for `builder` to complete.
///
/// The object returned by `selector` should be immutable and override
/// [operator==] such that two objects with the same content are equal, even
/// if they are not [identical].
///
/// As such, to select multiple values, the easiest solution is to use a "Tuple"
/// from [tuple](https://pub.dev/packages/tuple):
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
/// For generic usage informations, see [Consumer].
///
/// {@endtemplate}
class Selector<A, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(context, Provider.of(context)),
          child: child,
        );
}

/// {@macro provider.selector}
class Selector2<A, B, S> extends Selector0<S> {
  /// {@macro provider.selector}
  Selector2({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
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
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
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
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C, D) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
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
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C, D, E) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
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
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C, D, E, F) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
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
