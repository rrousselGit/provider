import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:mobx/mobx.dart';

class StoreProvider<T extends Store> extends ValueDelegateWidget<T>
    implements SingleChildCloneableWidget {
  StoreProvider({
    Key key,
    ValueBuilder<T> builder,
    Widget child,
  }) : this._(
          key: key,
          delegate: _StoreBuilderAdaptiveDelegate(builder),
          child: child,
        );

  StoreProvider.value({
    Key key,
    T value,
    UpdateShouldNotify<T> updateShouldNotify,
    Widget child,
  }) : this._(
          key: key,
          delegate: SingleValueDelegate(value),
          updateShouldNotify: updateShouldNotify,
          child: child,
        );

  StoreProvider._({
    Key key,
    ValueAdaptiveDelegate<T> delegate,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, delegate: delegate);

  final Widget child;
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  Widget build(BuildContext context) {
    return InheritedProvider<T>(
      value: delegate.value,
      updateShouldNotify: updateShouldNotify,
      child: child,
    );
  }

  @override
  StoreProvider<T> cloneWithChild(Widget child) => StoreProvider<T>._(
        key: key,
        delegate: delegate,
        updateShouldNotify: updateShouldNotify,
        child: child,
      );
}

class _StoreBuilderAdaptiveDelegate<T extends Store>
    extends ValueAdaptiveDelegate<T> {
  _StoreBuilderAdaptiveDelegate(this.builder);

  final ValueBuilder<T> builder;

  @override
  T value;

  @override
  void initDelegate() {
    value = builder(context);
  }

  @override
  void didUpdateDelegate(_StoreBuilderAdaptiveDelegate<T> old) {
    value = old.value;
  }

  @override
  void dispose() {
    value.dispose();
  }
}
