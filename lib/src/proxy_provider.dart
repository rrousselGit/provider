import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

class ProxyProvider<T, R> extends StatefulWidget
    implements SingleChildCloneableWidget {
  const ProxyProvider({
    Key key,
    @required this.builder,
    this.updateShouldNotify,
    this.child,
  })  : assert(builder != null),
        super(key: key);

  final R Function(BuildContext, T, R) builder;
  final UpdateShouldNotify<R> updateShouldNotify;
  final Widget child;

  @override
  _ProxyProviderState<T, R> createState() => _ProxyProviderState();

  @override
  ProxyProvider<T, R> cloneWithChild(Widget child) {
    return ProxyProvider(
      key: key,
      builder: builder,
      updateShouldNotify: updateShouldNotify,
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

    return Provider<R>.value(
      value: value,
      child: widget.child,
      updateShouldNotify: widget.updateShouldNotify,
    );
  }
}
