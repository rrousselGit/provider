import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/src/adaptive_builder_widget.dart';
import 'package:provider/src/provider.dart';

typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

class StreamProvider<T>
    extends AdaptiveBuilderWidget<Stream<T>, StreamController<T>>
    implements SingleChildCloneableWidget {
  const StreamProvider({
    Key key,
    @required ValueBuilder<StreamController<T>> builder,
    this.initialData,
    this.orElse,
    this.updateShouldNotify,
    this.child,
  }) : super(key: key, builder: builder);

  const StreamProvider.value({
    Key key,
    @required Stream<T> stream,
    this.initialData,
    this.orElse,
    this.updateShouldNotify,
    this.child,
  }) : super.value(key: key, value: stream);

  final T initialData;
  final Widget child;
  final ErrorBuilder<T> orElse;
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  _StreamProviderState<T> createState() => _StreamProviderState<T>();

  @override
  StreamProvider<T> cloneWithChild(Widget child) {
    return builder != null
        ? StreamProvider(
            key: key,
            builder: builder,
            child: child,
            updateShouldNotify: updateShouldNotify,
            initialData: initialData,
            orElse: orElse,
          )
        : StreamProvider.value(
            key: key,
            stream: value,
            child: child,
            updateShouldNotify: updateShouldNotify,
            initialData: initialData,
            orElse: orElse,
          );
  }
}

class _StreamProviderState<T> extends State<StreamProvider<T>>
    with
        AdaptiveBuilderWidgetStateMixin<Stream<T>, StreamController<T>,
            StreamProvider<T>> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: value,
      initialData: widget.initialData,
      builder: (_, snapshot) {
        return Provider<T>.value(
          value: getValue(snapshot, context),
          child: widget.child,
          updateShouldNotify: widget.updateShouldNotify,
        );
      },
    );
  }

  T getValue(AsyncSnapshot<T> snapshot, BuildContext context) {
    if (snapshot.hasError) {
      if (widget.orElse != null) {
        return widget.orElse(context, snapshot.error);
      }
      // ignore: only_throw_errors
      throw snapshot.error;
    }
    return snapshot.data;
  }

  @override
  void disposeBuilt(StreamProvider<T> oldWidget, StreamController<T> built) {
    built?.close();
  }

  @override
  Stream<T> didBuild(StreamController<T> built) {
    return built?.stream;
  }
}
