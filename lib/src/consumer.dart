import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

/// {@template provider.consumer}
/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
/// {@endtemplate}
class Consumer<T> extends StatelessWidget {
  /// {@template provider.consumer.builder}
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  /// {@endtemplate}
  final Widget Function(BuildContext context, T value) builder;

  /// {@template provider.consumer.constructor}
  /// Consumes a [Provider<T>]
  /// {@endtemplate}
  Consumer({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, Provider.of<T>(context));
  }
}

/// {@macro provider.consumer}
class Consumer2<A, B> extends StatelessWidget {
  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2) builder;

  /// {@macro provider.consumer.constructor}
  Consumer2({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
    );
  }
}

/// {@macro provider.consumer}
class Consumer3<A, B, C> extends StatelessWidget {
  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2, C value3)
      builder;

  /// {@macro provider.consumer.constructor}
  Consumer3({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
    );
  }
}

/// {@macro provider.consumer}
class Consumer4<A, B, C, D> extends StatelessWidget {
  /// {@macro provider.consumer.builder}
  final Widget Function(
      BuildContext context, A value, B value2, C value3, D value4) builder;

  /// {@macro provider.consumer.constructor}
  Consumer4({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      Provider.of<D>(context),
    );
  }
}

/// {@macro provider.consumer}
class Consumer5<A, B, C, D, E> extends StatelessWidget {
  /// {@macro provider.consumer.builder}
  final Widget Function(
          BuildContext context, A value, B value2, C value3, D value4, E value5)
      builder;

  /// {@macro provider.consumer.constructor}
  Consumer5({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      Provider.of<D>(context),
      Provider.of<E>(context),
    );
  }
}

/// {@macro provider.consumer}
class Consumer6<A, B, C, D, E, F> extends StatelessWidget {
  /// {@macro provider.consumer.builder}
  final Widget Function(BuildContext context, A value, B value2, C value3,
      D value4, E value5, F value6) builder;

  /// {@macro provider.consumer.constructor}
  Consumer6({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

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
    );
  }
}
