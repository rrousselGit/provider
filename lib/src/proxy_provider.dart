part of 'provider.dart';

abstract class ProxyProviderBase<R> extends StatefulWidget {
  const ProxyProviderBase({
    Key key,
    this.initialBuilder,
    this.updateShouldNotify,
    this.dispose,
    this.child,
  })  : providerBuilder = null,
        super(key: key);

  const ProxyProviderBase.custom({
    Key key,
    this.initialBuilder,
    @required this.providerBuilder,
    this.dispose,
    this.child,
  })  : assert(providerBuilder != null),
        updateShouldNotify = null,
        super(key: key);

  final ValueBuilder<R> initialBuilder;
  final UpdateShouldNotify<R> updateShouldNotify;
  final Widget child;
  final Disposer<R> dispose;
  final ValueWidgetBuilder<R> providerBuilder;

  @override
  ProxyProviderState<R> createState() => ProxyProviderState();

  R didChangeDependencies(BuildContext context, R previous);
}

typedef ProviderBuilder<R> = Widget Function(
    BuildContext context, R value, Widget child);

class ProxyProviderState<R> extends State<ProxyProviderBase<R>> {
  R _value;
  bool _didChangeDependencies = true;

  @override
  void initState() {
    super.initState();
    _value = widget.initialBuilder?.call(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies is called before didUpdateWidget and is called
    // once per updated inherited widget. So we can't use it to call widget.builder
    _didChangeDependencies = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_didChangeDependencies) {
      _didChangeDependencies = false;
      _value = widget.didChangeDependencies(context, _value);
    }

    if (widget.providerBuilder != null) {
      return widget.providerBuilder(context, _value, widget.child);
    }

    return Provider<R>.value(
      value: _value,
      child: widget.child,
      updateShouldNotify: widget.updateShouldNotify,
    );
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose(context, _value);
    }
    super.dispose();
  }
}

typedef ProxyProviderBuilder<T, R> = R Function(
    BuildContext context, T value, R previous);

class ProxyProvider<T, R> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ProxyProvider({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  const ProxyProvider.custom({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    @required ValueWidgetBuilder<R> providerBuilder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder<T, R> builder;

  @override
  ProxyProvider<T, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider.custom(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) =>
      builder(context, Provider.of<T>(context), previous);
}

typedef ProxyProviderBuilder2<T, T2, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  R previous,
);

class ProxyProvider2<T, T2, R> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ProxyProvider2({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  const ProxyProvider2.custom({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    @required ValueWidgetBuilder<R> providerBuilder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder2<T, T2, R> builder;

  @override
  ProxyProvider2<T, T2, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider2.custom(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider2(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
      context, Provider.of<T>(context), Provider.of<T2>(context), previous);
}

typedef ProxyProviderBuilder3<T, T2, T3, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  R previous,
);

class ProxyProvider3<T, T2, T3, R> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ProxyProvider3({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  const ProxyProvider3.custom({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    @required ValueWidgetBuilder<R> providerBuilder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder3<T, T2, T3, R> builder;

  @override
  ProxyProvider3<T, T2, T3, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider3.custom(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider3(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        previous,
      );
}

typedef ProxyProviderBuilder4<T, T2, T3, T4, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  R previous,
);

class ProxyProvider4<T, T2, T3, T4, R> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ProxyProvider4({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  const ProxyProvider4.custom({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    @required ValueWidgetBuilder<R> providerBuilder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder4<T, T2, T3, T4, R> builder;

  @override
  ProxyProvider4<T, T2, T3, T4, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider4.custom(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider4(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        Provider.of<T4>(context),
        previous,
      );
}

typedef ProxyProviderBuilder5<T, T2, T3, T4, T5, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  R previous,
);

class ProxyProvider5<T, T2, T3, T4, T5, R> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ProxyProvider5({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  const ProxyProvider5.custom({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    @required ValueWidgetBuilder<R> providerBuilder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder5<T, T2, T3, T4, T5, R> builder;

  @override
  ProxyProvider5<T, T2, T3, T4, T5, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider5.custom(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider5(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        Provider.of<T4>(context),
        Provider.of<T5>(context),
        previous,
      );
}

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

class ProxyProvider6<T, T2, T3, T4, T5, T6, R> extends ProxyProviderBase<R>
    implements SingleChildCloneableWidget {
  const ProxyProvider6({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    UpdateShouldNotify<R> updateShouldNotify,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super(
          key: key,
          initialBuilder: initialBuilder,
          updateShouldNotify: updateShouldNotify,
          dispose: dispose,
          child: child,
        );

  const ProxyProvider6.custom({
    Key key,
    ValueBuilder<R> initialBuilder,
    @required this.builder,
    @required ValueWidgetBuilder<R> providerBuilder,
    Disposer<R> dispose,
    Widget child,
  })  : assert(builder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final ProxyProviderBuilder6<T, T2, T3, T4, T5, T6, R> builder;

  @override
  ProxyProvider6<T, T2, T3, T4, T5, T6, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider6.custom(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider6(
            key: key,
            initialBuilder: initialBuilder,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }

  @override
  R didChangeDependencies(BuildContext context, R previous) => builder(
        context,
        Provider.of<T>(context),
        Provider.of<T2>(context),
        Provider.of<T3>(context),
        Provider.of<T4>(context),
        Provider.of<T5>(context),
        Provider.of<T6>(context),
        previous,
      );
}
