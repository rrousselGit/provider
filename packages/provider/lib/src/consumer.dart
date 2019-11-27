import 'package:flutter/widgets.dart';
import 'provider.dart';
import 'selector.dart' show Selector;

/// {@template provider.consumer}
/// Obtain [Provider<T>] from its ancestors and pass its value to [builder].
///
/// The widget [Consumer] doesn't do any fancy work. It just calls [Provider.of]
/// in a new widget, and delegate its `build` implementation to [builder].
///
/// [builder] must not be null and may be called multiple times (such as when
/// provided value change).
///
/// The wiget [Consumer] has two main purposes:
///
/// * It allows obtaining a value from a provider when we don't have a
///   [BuildContext] that is a descendant of the said provider, and therefore
///   cannot use [Provider.of].
///
/// Such scenario typically happens when the widget that creates the provider
/// is also one of its consumers, like in the following example:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return ChangeNotifierProvider(
///     create: (_) => Foo(),
///     child: Text(Provider.of<Foo>(context).value),
///   );
/// }
/// ```
///
/// This example will throw a [ProviderNotFoundError], because [Provider.of]
/// is called with a [BuildContext] that is an ancestor of the provider.
///
/// Instead, we can use the [Consumer] widget, that will call [Provider.of]
/// with its own [BuildContext].
///
/// Using [Consumer], the previous example will become:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return ChangeNotifierProvider(
///     create: (_) => Foo(),
///     child: Consumer<Foo>(
///       builder: (_, foo, __) => Text(foo.value),
///     },
///   );
/// }
/// ```
///
/// This won't throw a [ProviderNotFoundError] and will correctly build the
/// [Text]. It will also update the [Text] whenever the value `foo` changes.
///
///
/// * It helps with performance optimisation by having more granular rebuilds.
///
/// Unless `listen: false` is passed to [Provider.of], it means that the widget
/// associated to the [BuildContext] passed to [Provider.of] will rebuild
/// whenever the obtained value changes.
///
/// This is the expected behavior, but sometimes it may rebuild more widgets
/// than needed.
///
/// Here's an example:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return FooWidget(
///      child: BarWidget(
///        bar: Provider.of<Bar>(context),
///      ),
///    );
///  }
/// ```
///
/// In such code, only `BarWidget` depends on the value returned by
/// [Provider.of]. But when `Bar` changes, then both `BarWidget` _and_
/// `FooWidget` will rebuild.
///
/// Ideally, only `BarWidget` should be rebuilt. And to achieve that, one
/// solution is to use [Consumer].
///
/// To do so, we will wrap _only_ the widgets that depends on a provider into
/// a [Consumer]:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return FooWidget(
///      child: Consumer<Bar>(
///        builder: (_, bar, __) => BarWidget(bar: bar),
///      ),
///    );
///  }
/// ```
///
/// In this situation, if `Bar` were to update, only `BarWidget` would rebuild.
///
/// But what if it was `FooWidget` that depended on a provider? Example:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return FooWidget(
///      foo: Provider.of<Foo>(context),
///      child: BarWidget(),
///    );
///  }
/// ```
///
/// Using [Consumer], we can handle this kind of scenario using the optional
/// [child] argument:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return Consumer<Foo>(
///      builder: (_, foo, child) => FooWidget(foo: foo, child: child),
///      child: BarWidget(),
///    );
///  }
/// ```
///
/// In that example, `BarWidget` is built outside of [builder]. Then, the
/// `BarWidget` instance is passed to [builder] as the last parameter.
///
/// This means that when [builder] is called again with new values, new
/// instance of `BarWidget` will not be recreated.
/// This let Flutter knows that it doesn't have to rebuild `BarWidget`.
/// Therefore in such configuration, only `FooWidget` will rebuild
/// if `Foo` changes.
///
/// ## Note:
///
/// The widget [Consumer] can also be used inside [MultiProvider]. To do so, it
/// must returns the `child` passed to [builder] in the widget tree it creates.
///
/// ```dart
/// MultiProvider(
///   providers: [
///     Provider(create: (_) => Foo()),
///     Consumer<Foo>(
///       builder: (context, foo, child) =>
///         Provider.value(value: foo.bar, child: child),
///     )
///   ],
/// );
/// ```
///
/// See also:
///   * [Selector], a [Consumer] that can filter updates.
/// {@endtemplate}
class Consumer<T> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// {@template provider.consumer.constructor}
  /// Consumes a [Provider<T>]
  /// {@endtemplate}
  Consumer({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
  final Widget child;

  /// {@template provider.consumer.builder}
  /// Build a widget tree based on the value from a [Provider<T>].
  ///
  /// Must not be `null`.
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

  @override
  Consumer<T> cloneWithChild(Widget child) {
    return Consumer(
      key: key,
      builder: builder,
      child: child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer2<A, B> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// {@macro provider.consumer.constructor}
  Consumer2({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
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

  @override
  Consumer2<A, B> cloneWithChild(Widget child) {
    return Consumer2(
      key: key,
      builder: builder,
      child: child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer3<A, B, C> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// {@macro provider.consumer.constructor}
  Consumer3({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
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

  @override
  Consumer3<A, B, C> cloneWithChild(Widget child) {
    return Consumer3(
      key: key,
      builder: builder,
      child: child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer4<A, B, C, D> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// {@macro provider.consumer.constructor}
  Consumer4({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
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

  @override
  Consumer4<A, B, C, D> cloneWithChild(Widget child) {
    return Consumer4(
      key: key,
      builder: builder,
      child: child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer5<A, B, C, D, E> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// {@macro provider.consumer.constructor}
  Consumer5({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
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

  @override
  Consumer5<A, B, C, D, E> cloneWithChild(Widget child) {
    return Consumer5(
      key: key,
      builder: builder,
      child: child,
    );
  }
}

/// {@macro provider.consumer}
class Consumer6<A, B, C, D, E, F> extends StatelessWidget
    implements SingleChildCloneableWidget {
  /// {@macro provider.consumer.constructor}
  Consumer6({
    Key key,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  /// The child widget to pass to [builder].
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

  @override
  Consumer6<A, B, C, D, E, F> cloneWithChild(Widget child) {
    return Consumer6(
      key: key,
      builder: builder,
      child: child,
    );
  }
}
