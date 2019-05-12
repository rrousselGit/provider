import 'package:flutter/widgets.dart';
import 'package:provider/src/listenable_provider.dart';
import 'package:provider/src/provider.dart';

typedef R ProxyBuilder<A, R>(BuildContext context, A a, R previous);

class ProxyProvider<T, R> extends StatefulWidget
    implements SingleChildCloneableWidget {
  const ProxyProvider({
    Key key,
    @required this.builder,
    this.updateShouldNotify,
    this.dispose,
    this.child,
  })  : assert(builder != null),
        providerBuilder = null,
        super(key: key);

  const ProxyProvider.custom({
    Key key,
    @required this.builder,
    @required this.providerBuilder,
    this.dispose,
    this.child,
  })  : assert(builder != null),
        updateShouldNotify = null,
        super(key: key);

  final ProxyBuilder<T, R> builder;
  final UpdateShouldNotify<R> updateShouldNotify;
  final Widget child;
  final Disposer<R> dispose;
  final ValueWidgetBuilder<R> providerBuilder;

  @override
  _ProxyProviderState<T, R> createState() => _ProxyProviderState();

  @override
  ProxyProvider<T, R> cloneWithChild(Widget child) {
    return providerBuilder != null
        ? ProxyProvider.custom(
            key: key,
            builder: builder,
            providerBuilder: providerBuilder,
            dispose: dispose,
            child: child,
          )
        : ProxyProvider(
            key: key,
            builder: builder,
            updateShouldNotify: updateShouldNotify,
            dispose: dispose,
            child: child,
          );
  }
}

class _ProxyProviderState<T, R> extends State<ProxyProvider<T, R>> {
  R value;
  bool _didChangeDependencies = true;

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
      value = widget.builder(context, Provider.of<T>(context), value);
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
