import 'package:flutter/widgets.dart';

import 'provider.dart';

/// {@template provider.consumer}
/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
///
/// ## Performance optimizations:
///
/// {@macro provider.consumer.child}
/// {@endtemplate}
class Consumer<T> extends StatelessWidget {
  /// {@template provider.consumer.constructor}
  /// Consumes a [Provider<T>]
  /// {@endtemplate}
  Consumer({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  // fork of the documentation from https://docs.flutter.io/flutter/widgets/AnimatedBuilder/child.html
  /// The child widget to pass to [builder].
  /// {@template provider.consumer.child}
  ///
  /// If a builder callback's return value contains a subtree that does not depend on the provided value,
  /// it's more efficient to build that subtree once instead of rebuilding it on every change of the provided value.
  ///
  /// If the pre-built subtree is passed as the child parameter, [Consumer] will pass it back to the builder function so that it can be incorporated into the build.
  ///
  /// Using this pre-built child is entirely optional, but can improve performance significantly in some cases and is therefore a good practice.
  /// {@endtemplate}
  final Widget child;

  /// {@template provider.consumer.builder}
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  /// {@endtemplate}
  final Widget Function(BuildContext context, T value, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<T>(context),
      child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer2<A, B> extends StatelessWidget {
  /// {@macro provider.consumer.constructor}
  Consumer2({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
  ///
  /// {@macro provider.consumer.child}
  final Widget child;

  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2, Widget child)
      builder;

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer3<A, B, C> extends StatelessWidget {
  /// {@macro provider.consumer.constructor}
  Consumer3({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
  ///
  /// {@macro provider.consumer.child}
  final Widget child;

  /// {@macro provider.consumer.builder}
  final Widget Function(
      BuildContext context, A value, B value2, C value3, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer4<A, B, C, D> extends StatelessWidget {
  /// {@macro provider.consumer.constructor}
  Consumer4({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
  ///
  /// {@macro provider.consumer.child}
  final Widget child;

  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2, C value3,
      D value4, Widget child) builder;
  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      Provider.of<D>(context),
      child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer5<A, B, C, D, E> extends StatelessWidget {
  /// {@macro provider.consumer.constructor}
  Consumer5({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
  ///
  /// {@macro provider.consumer.child}
  final Widget child;

  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2, C value3,
      D value4, E value5, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      Provider.of<D>(context),
      Provider.of<E>(context),
      child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer6<A, B, C, D, E, F> extends StatelessWidget {
  /// {@macro provider.consumer.constructor}
  Consumer6({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
  ///
  /// {@macro provider.consumer.child}
  final Widget child;

  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2, C value3,
      D value4, E value5, F value6, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      Provider.of<D>(context),
      Provider.of<E>(context),
      Provider.of<F>(context),
      child,
    );
  }
}
