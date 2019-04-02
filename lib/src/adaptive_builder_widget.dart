import 'package:flutter/widgets.dart';

/// A function that creates an object of type [T].
typedef ValueBuilder<T> = T Function(BuildContext context);

abstract class AdaptiveBuilderWidget<T, B> extends StatefulWidget {
  const AdaptiveBuilderWidget({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        value = null,
        super(key: key);

  const AdaptiveBuilderWidget.value({
    Key key,
    @required this.value,
  })  : builder = null,
        super(key: key);

  final ValueBuilder<B> builder;
  final T value;

  _ConstructorType get _type =>
      builder != null ? _ConstructorType.builder : _ConstructorType.value;

  @override
  AdaptiveBuilderWidgetStateMixin<T, B, AdaptiveBuilderWidget<T, B>>
      createState();
}

enum _ConstructorType {
  builder,
  value,
}

mixin AdaptiveBuilderWidgetStateMixin<T, B,
    W extends AdaptiveBuilderWidget<T, B>> on State<W> {
  T value;
  B _built;

  @override
  void initState() {
    super.initState();
    _buildValue(null);
  }

  void _buildValue(W oldWidget) {
    if (widget.builder != null) {
      _built = widget.builder(context);
      final newValue = didBuild(_built);
      changeValue(oldWidget, value, newValue);
      value = newValue;
    } else {
      _built = null;
      changeValue(oldWidget, value, widget.value);
      value = widget.value;
    }
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    final built = _built;
    switch (widget._type) {
      case _ConstructorType.value:
        _buildValue(oldWidget);
        if (oldWidget._type == _ConstructorType.builder) {
          disposeBuilt(oldWidget, built);
        }
        break;
      case _ConstructorType.builder:
        if (oldWidget._type == _ConstructorType.value) {
          _buildValue(oldWidget);
        }
        break;
    }
  }

  T didBuild(B built);

  @override
  void dispose() {
    if (widget._type == _ConstructorType.builder) {
      disposeBuilt(widget, _built);
    }
    super.dispose();
  }

  void changeValue(W oldWidget, T oldValue, T newValue) {}

  void disposeBuilt(W oldWidget, B built);
}
