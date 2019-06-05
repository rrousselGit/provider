import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:provider/provider.dart';

class ProxyProvider<T, R> extends ProxyProviderWidget
    implements SingleChildCloneableWidget {
  ProxyProvider({
    Key key,
    this.initialBuilder,
    this.builder,
    this.updateShouldNotify,
    this.reactiveContext,
    this.dispose,
    this.child,
  }) : super(key: key);

  final ValueBuilder<R> initialBuilder;
  final ProxyProviderBuilder<T, R> builder;
  final UpdateShouldNotify<R> updateShouldNotify;
  final ReactiveContext reactiveContext;
  final Widget child;
  final Disposer<R> dispose;

  @override
  _ProxyProviderState<T, R> createState() => _ProxyProviderState();

  @override
  ProxyProvider<T, R> cloneWithChild(Widget child) {
    return ProxyProvider(
      key: key,
      initialBuilder: initialBuilder,
      builder: builder,
      updateShouldNotify: updateShouldNotify,
      reactiveContext: reactiveContext,
      dispose: dispose,
      child: child,
    );
  }
}

class _ProxyProviderState<T, R>
    extends ProxyProviderState<ProxyProvider<T, R>> {
  ReactionDisposer _reactionDisposer;
  ActionController controller;
  R value;

  @override
  void initState() {
    super.initState();
    // TODO(rrousselGit) handle `reactiveContext` update
    controller = ActionController(
        context: widget.reactiveContext, name: 'ProxyProvider');
    value = widget.initialBuilder?.call(context);
  }

  @override
  void didUpdateDependencies() {
    super.didUpdateDependencies();
    _reactionDisposer?.call();
    _reactionDisposer = autorun((_) {
      setState(() {
        final info = controller.startAction();
        try {
          value = widget.builder(context, Provider.of(context), value);
        } finally {
          controller.endAction(info);
        }
      });
    }, onError: (err, _) {
      FlutterError.reportError(FlutterErrorDetails(
        library: 'mobx_provider',
        exception: err,
        context: ErrorDescription('ProxyProvider failed to call `builder`.'),
      ));
      // pipe to FlutterError
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedProvider<R>(
      value: value,
      updateShouldNotify: widget.updateShouldNotify,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    // called _before_ the dispose callback, as it may trigger the reaction again.
    _reactionDisposer?.call();
    widget.dispose?.call(context, value);
    super.dispose();
  }
}
