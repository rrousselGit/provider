import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/src/adaptative_builder_widget.dart';
import 'package:provider/src/provider.dart';

typedef ErrorBuilder<T> = T Function(BuildContext context, Object error);

class StreamProvider<T> extends StatefulWidget
    implements SingleChildCloneableWidget {
  const StreamProvider({
    Key key,
    this.initialData,
    this.builder,
    this.child,
    this.orElse,
    this.updateShouldNotify,
  })  : stream = null,
        assert(builder != null),
        super(key: key);

  const StreamProvider.value({
    Key key,
    this.initialData,
    this.stream,
    this.child,
    this.orElse,
    this.updateShouldNotify,
  })  : builder = null,
        super(key: key);

  const StreamProvider._({
    Key key,
    this.initialData,
    this.stream,
    this.builder,
    this.child,
    this.orElse,
    this.updateShouldNotify,
  }) : super(key: key);

  final ValueBuilder<StreamController<T>> builder;
  final T initialData;
  final Stream<T> stream;
  final Widget child;
  final ErrorBuilder<T> orElse;
  final UpdateShouldNotify<T> updateShouldNotify;

  @override
  _StreamProviderState<T> createState() => _StreamProviderState<T>();

  @override
  StreamProvider<T> cloneWithChild(Widget child) {
    return StreamProvider<T>._(
      key: key,
      initialData: initialData,
      stream: stream,
      updateShouldNotify: updateShouldNotify,
      orElse: orElse,
      builder: builder,
      child: child,
    );
  }
}

class _StreamProviderState<T> extends State<StreamProvider<T>> {
  static bool didChangeBetweenDefaultAndBuilderConstructor(
    StreamProvider oldWidget,
    StreamProvider widget,
  ) =>
      isBuilderConstructor(oldWidget) != isBuilderConstructor(widget);

  static bool isBuilderConstructor(StreamProvider provider) =>
      provider.builder != null;

  Stream<T> stream;
  StreamController<T> controller;

  @override
  void initState() {
    super.initState();
    buildStream();
  }

  void buildStream() {
    if (widget.builder != null) {
      controller = widget.builder(context);
    }
    stream = widget.stream ?? controller?.stream;
  }

  @override
  void didUpdateWidget(StreamProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (didChangeBetweenDefaultAndBuilderConstructor(oldWidget, widget)) {
      buildStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
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
  void dispose() {
    controller?.close();
    super.dispose();
  }
}
