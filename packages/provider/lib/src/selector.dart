import 'package:flutter/widgets.dart';

import 'provider.dart';

class Selector0<T> extends StatefulWidget {
  Selector0(
      {Key key, @required this.builder, @required this.selector, this.child})
      : assert(builder != null),
        assert(selector != null),
        super(key: key);

  final ValueWidgetBuilder<T> builder;
  final T Function(BuildContext context) selector;
  final Widget child;

  @override
  _Selector0State<T> createState() => _Selector0State<T>();
}

class _Selector0State<T> extends State<Selector0<T>> {
  T value;
  Widget cache;
  ValueWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selector(context);

    if (builder != widget.builder || selected != value) {
      value = selected;
      builder = widget.builder;
      cache = widget.builder(
        context,
        selected,
        widget.child,
      );
    }
    return cache;
  }
}
