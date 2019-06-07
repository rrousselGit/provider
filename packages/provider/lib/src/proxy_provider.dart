import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'delegate_widget.dart';
import 'provider.dart';

typedef ProviderBuilder<R> = Widget Function(
    BuildContext context, R value, Widget child);

typedef ProxyProviderBuilder<T, R> = R Function(
    BuildContext context, T value, R previous);

typedef ProxyProviderBuilder2<T, T2, R> = R Function(
    BuildContext context, T value, T2 value2, R previous);

typedef ProxyProviderBuilder3<T, T2, T3, R> = R Function(
    BuildContext context, T value, T2 value2, T3 value3, R previous);

typedef ProxyProviderBuilder4<T, T2, T3, T4, R> = R Function(
    BuildContext context, T value, T2 value2, T3 value3, T4 value4, R previous);

typedef ProxyProviderBuilder5<T, T2, T3, T4, T5, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  R previous,
);

typedef ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  T6 value6,
  R previous,
);

/// A [StatefulWidget] that uses [ProxyProviderState] as [State].
abstract class ProxyProviderWidget extends StatefulWidget {
  /// Initializes [key] for subclasses.
  const ProxyProviderWidget({Key key}) : super(key: key);

  @override
  ProxyProviderState<ProxyProviderWidget> createState();

  @override
  ProxyProviderElement createElement() => ProxyProviderElement(this);
}

/// A [State] with an added life-cycle: [didUpdateDependencies].
///
/// Widgets such as [ProxyProvider] are expected to build their
/// value from within [didUpdateDependencies] instead of [didChangeDependencies].
abstract class ProxyProviderState<T extends ProxyProviderWidget>
    extends State<T> {
  /// To not confuse with [didChangeDependencies].
  ///
  /// As opposed to [didChangeDependencies], [didUpdateDependencies] is
  /// guaranteed to be followed by a call to [build], and will be called only
  /// once after _all_ dependencies have changed.
  ///
  /// This guarantees that everything is up to date when [didUpdateDependencies]
  /// is called, and that the widget will not be unmounted before updates are
  /// applied. It is therefore safe to make network http calls or mutations
  /// inside this life-cycle.
  @protected
  @mustCallSuper
  void didUpdateDependencies() {}
}

/// An [Element] that uses a [ProxyProviderWidget] as its configuration.
class ProxyProviderElement extends StatefulElement {
  /// Creates an element that uses the given widget as its configuration.
  ProxyProviderElement(ProxyProviderWidget widget) : super(widget);

  @override
  ProxyProviderWidget get widget => super.widget as ProxyProviderWidget;

  @override
  ProxyProviderState<ProxyProviderWidget> get state =>
      super.state as ProxyProviderState<ProxyProviderWidget>;

  bool _didChangeDependencies = true;

  @override
  void didChangeDependencies() {
    _didChangeDependencies = true;
    super.didChangeDependencies();
  }

  @override
  Widget build() {
    if (_didChangeDependencies) {
      _didChangeDependencies = false;
      state.didUpdateDependencies();
    }
    return super.build();
  }
}

// ignore: public_member_api_docs
abstract class Void {}

/// A base class for custom "Proxy provider".
///
/// See [ProxyProvider] for a concrete implementation.
abstract class ProxyProviderBase<R> extends ProxyProviderWidget {
  /// Initializes [key], [initialBuilder] and [dispose] for subclasses.
  ProxyProviderBase({
    Key key,
    this.initialBuilder,
    this.dispose,
  }) : super(key: key);

  /// Builds the initial value passed as `previous` to [didChangeDependencies].
  ///
  /// If omitted, [didChangeDependencies] will be called with `null` instead.
  final ValueBuilder<R> initialBuilder;

  /// Optionally allows to clean-up resources when the widget is removed from
  /// the tree.
  final Disposer<R> dispose;

  @override
  _ProxyProviderState<R> createState() => _ProxyProviderState();

  /// Builds the value passed to [build] by combining [InheritedWidget].
  ///
  /// [didChangeDependencies] will be called once when the widget is mounted,
  /// and once whenever any of the [InheritedWidget] which [ProxyProviderBase]
  /// depends on updates.
  ///
  /// It is safe to perform side-effects in this method.
  R didChangeDependencies(BuildContext context, R previous);

  /// An equivalent of [StatelessWidget.build].
  ///
  /// `value` is the latest result of [didChangeDependencies].
  ///
  /// [build] should avoid depending on [InheritedWidget]. Instead these
  /// [InheritedWidget] should be used inside [didChangeDependencies].
  Widget build(BuildContext context, R value);
}

class _ProxyProviderState<R> extends ProxyProviderState<ProxyProviderBase<R>> {
  R _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialBuilder?.call(context);
  }

  @override
  void didUpdateDependencies() {
    super.didUpdateDependencies();
    _value = widget.didChangeDependencies(context, _value);
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _value);

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose(context, _value);
    }
    super.dispose();
  }
}

@visibleForTesting
// ignore: public_member_api_docs
class NumericProxyProvider<T, T2, T3, T4, T5, T6, R>
    extends ProxyProviderBase<R> implements SingleChildCloneableWidget {
  // ignore: public_member_api_docs
  NumericProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    this.updateShouldNotify,
    Disposer<R> dispose,
    this.child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          dispose: dispose,
        );

  /// The widget that is below the current [Provider] widget in the
  /// tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// {@template provider.proxyprovider.builder}
  /// Builds the value passed to [InheritedProvider] by combining [InheritedWidget].
  ///
  /// [builder] will be called once when the widget is mounted,
  /// and once whenever any of the [InheritedWidget] which [ProxyProvider]
  /// depends on updates.
  ///
  /// It is safe to perform side-effects in this method.
  /// {@endtemplate}
  final Function builder;

  /// The [UpdateShouldNotify] passed to [InheritedProvider].
  final UpdateShouldNotify<R> updateShouldNotify;

  @override
  NumericProxyProvider<T, T2, T3, T4, T5, T6, R> cloneWithChild(Widget child) {
    return NumericProxyProvider(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      updateShouldNotify: updateShouldNotify,
      dispose: dispose,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, R value) {
    assert(() {
      Provider.debugCheckInvalidValueType?.call(value);
      return true;
    }());
    return InheritedProvider<R>(
      value: value,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) {
    final arguments = <dynamic>[
      context,
      Provider.of<T>(context),
    ];

    if (T2 != Void) arguments.add(Provider.of<T2>(context));
    if (T3 != Void) arguments.add(Provider.of<T3>(context));
    if (T4 != Void) arguments.add(Provider.of<T4>(context));
    if (T5 != Void) arguments.add(Provider.of<T5>(context));
    if (T6 != Void) arguments.add(Provider.of<T6>(context));

    arguments.add(previous);
    return Function.apply(builder, arguments) as R;
  }
}

/// {@template provider.proxyprovider}
/// A provider that builds a value based on other providers.
///
/// The exposed value is built through [builder], and then passed
/// to [InheritedProvider].
///
/// As opposed to the `builder` parameter of [Provider], [builder]
/// may be called more than once. It will be called once when the widget is
/// mounted, then once whenever any of the [InheritedWidget] which [ProxyProvider]
/// depends emits an update.
///
/// [ProxyProvider] comes in different variants such as [ProxyProvider2].
/// This only changes the [builder] function, such that it takes
/// a different number of arguments.
/// The `2` in [ProxyProvider2] means that [builder] builds its
/// value from **2** other providers.
///
/// All variations of [builder] will receive the [BuildContext]
/// as first parameter, and the previously built value as last parameter.
///
/// This previously built value will be `null` by default, unless
/// [initialBuilder] is specified – in which case, it will be the
/// value returned by [initialBuilder].
///
/// [builder] must not be `null`.
///
/// See also:
///
///  * [Provider], which matches the behavior of [ProxyProvider] without
/// dependending on other providers.
/// {@endtemplate}
class ProxyProvider<T, R>
    extends NumericProxyProvider<T, Void, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder<T, R> builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder<T, R> get builder =>
      super.builder as ProxyProviderBuilder<T, R>;
}

/// {@macro provider.proxyprovider}
class ProxyProvider2<T, T2, R>
    extends NumericProxyProvider<T, T2, Void, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ProxyProvider2({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder2<T, T2, R> builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder2<T, T2, R> get builder =>
      super.builder as ProxyProviderBuilder2<T, T2, R>;
}

/// {@macro provider.proxyprovider}
class ProxyProvider3<T, T2, T3, R>
    extends NumericProxyProvider<T, T2, T3, Void, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ProxyProvider3({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder3<T, T2, T3, R> builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder3<T, T2, T3, R> get builder =>
      super.builder as ProxyProviderBuilder3<T, T2, T3, R>;
}

/// {@macro provider.proxyprovider}
class ProxyProvider4<T, T2, T3, T4, R>
    extends NumericProxyProvider<T, T2, T3, T4, Void, Void, R> {
  /// Initializes [key] for subclasses.
  ProxyProvider4({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder4<T, T2, T3, T4, R> builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder4<T, T2, T3, T4, R> get builder =>
      super.builder as ProxyProviderBuilder4<T, T2, T3, T4, R>;
}

/// {@macro provider.proxyprovider}
class ProxyProvider5<T, T2, T3, T4, T5, R>
    extends NumericProxyProvider<T, T2, T3, T4, T5, Void, R> {
  /// Initializes [key] for subclasses.
  ProxyProvider5({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder5<T, T2, T3, T4, T5, R> get builder =>
      super.builder as ProxyProviderBuilder5<T, T2, T3, T4, T5, R>;
}

/// {@macro provider.proxyprovider}
class ProxyProvider6<T, T2, T3, T4, T5, T6, R>
    extends NumericProxyProvider<T, T2, T3, T4, T5, T6, R> {
  /// Initializes [key] for subclasses.
  ProxyProvider6({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  }) : super(
          key: key,
          initialBuilder: initialBuilder,
          builder: builder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  @override
  ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> get builder =>
      super.builder as ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R>;
}
