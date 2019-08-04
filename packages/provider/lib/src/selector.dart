import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

class Selector0<T> extends StatefulWidget
    implements SingleChildCloneableWidget {
  Selector0(
      {Key key, @required this.builder, @required this.selector, this.child})
      : assert(builder != null),
        assert(selector != null),
        super(key: key);

  final ValueWidgetBuilder<T> builder;
  final ValueBuilder<T> selector;
  final Widget child;

  @override
  _Selector0State<T> createState() => _Selector0State<T>();

  @override
  Selector0<T> cloneWithChild(Widget child) {
    return Selector0(
      key: key,
      selector: selector,
      builder: builder,
      child: child,
    );
  }
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

class Selector<A, S> extends Selector0<S> {
  Selector({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(context, Provider.of(context)),
          child: child,
        );
}

class Selector2<A, B, S> extends Selector0<S> {
  Selector2({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

class Selector3<A, B, C, S> extends Selector0<S> {
  Selector3({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

class Selector4<A, B, C, D, S> extends Selector0<S> {
  Selector4({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C, D) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

class Selector5<A, B, C, D, E, S> extends Selector0<S> {
  Selector5({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C, D, E) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}

class Selector6<A, B, C, D, E, F, S> extends Selector0<S> {
  Selector6({
    Key key,
    @required ValueWidgetBuilder<S> builder,
    @required S Function(BuildContext, A, B, C, D, E, F) selector,
    Widget child,
  })  : assert(selector != null),
        super(
          key: key,
          builder: builder,
          selector: (context) => selector(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
          ),
          child: child,
        );
}
