import 'package:flutter/widgets.dart';
import 'package:provider/src/adaptive_builder_widget.dart';
import 'package:provider/src/provider.dart';

typedef ProviderBuilder<R> = Widget Function(
    BuildContext context, R value, Widget child);

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
        assert(providerBuilder != null),
        super.custom(
          key: key,
          initialBuilder: initialBuilder,
          providerBuilder: providerBuilder,
          dispose: dispose,
          child: child,
        );

  final R Function(BuildContext context, T value, R previous) builder;

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
  })  : updateShouldNotify = null,
        super(key: key);

  final ValueBuilder<R> initialBuilder;
  final UpdateShouldNotify<R> updateShouldNotify;
  final Widget child;
  final Disposer<R> dispose;
  final ValueWidgetBuilder<R> providerBuilder;

  @override
  _ProxyProviderState<R> createState() => _ProxyProviderState();

  R didChangeDependencies(BuildContext context, R previous);
}

class _ProxyProviderState<R> extends State<ProxyProviderBase<R>> {
  R value;
  bool _didChangeDependencies = true;

  @override
  void initState() {
    super.initState();
    value = widget.initialBuilder?.call(context);
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
      value = widget.didChangeDependencies(context, value);
    }

    if (widget.providerBuilder != null) {
      return widget.providerBuilder(context, value, widget.child);
    }

    return Provider<R>.value(
      value: value,
      child: widget.child,
      updateShouldNotify: widget.updateShouldNotify,
    );
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose(context, value);
    }
    super.dispose();
  }
}
