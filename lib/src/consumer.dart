import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
class Consumer<T> extends StatelessWidget {
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  final Widget Function(BuildContext context, T value) builder;

  /// Consumes a [Provider<T>]
  Consumer({Key key, @required this.builder})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, Provider.of<T>(context));
  }
}

/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
class Consumer2<A, B> extends StatelessWidget {
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  final Widget Function(BuildContext context, A value, B value2) builder;

  /// Consumes a [Provider<T>]
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

/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
class Consumer3<A, B, C> extends StatelessWidget {
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  final Widget Function(BuildContext context, A value, B value2, C value3)
      builder;

  /// Consumes a [Provider<T>]
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

/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
class Consumer4<A, B, C, D> extends StatelessWidget {
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  final Widget Function(
      BuildContext context, A value, B value2, C value3, D value4) builder;

  /// Consumes a [Provider<T>]
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

/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
class Consumer5<A, B, C, D, E> extends StatelessWidget {
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  final Widget Function(
          BuildContext context, A value, B value2, C value3, D value4, E value5)
      builder;

  /// Consumes a [Provider<T>]
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

/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when provided value change).
class Consumer6<A, B, C, D, E, F> extends StatelessWidget {
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be null.
  final Widget Function(BuildContext context, A value, B value2, C value3,
      D value4, E value5, F value6) builder;

  /// Consumes a [Provider<T>]
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
