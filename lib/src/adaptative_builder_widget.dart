import 'package:flutter/widgets.dart';

typedef ValueBuilder<T> = T Function(BuildContext context);

abstract class AdaptativeBuilderWidget<T> extends StatefulWidget {
  const AdaptativeBuilderWidget({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        value = null,
        super(key: key);

  const AdaptativeBuilderWidget.value({
    Key key,
    @required this.value,
  })  : builder = null,
        super(key: key);

  final ValueBuilder<T> builder;
  final T value;

  @override
  AdaptativeBuilderWidgetStateMixin<T, AdaptativeBuilderWidget<T>>
      createState();
}

mixin AdaptativeBuilderWidgetStateMixin<R, T extends AdaptativeBuilderWidget<R>>
    on State<T> {
  static bool didChangeBetweenDefaultAndBuilderConstructor(
    AdaptativeBuilderWidget oldWidget,
    AdaptativeBuilderWidget widget,
  ) =>
      isBuilderConstructor(oldWidget) != isBuilderConstructor(widget);

  static bool isBuilderConstructor(AdaptativeBuilderWidget widget) =>
      widget.builder != null;

  R value;

  @override
  void initState() {
    super.initState();
    value = _buildValue();
  }

  R _buildValue() =>
      widget.builder != null ? widget.builder(context) : widget.value;

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (didChangeBetweenDefaultAndBuilderConstructor(oldWidget, widget) ||
        widget.value != oldWidget.value) {
      final previousValue = value;
      value = _buildValue();
      didChangeValue(previousValue);
    }
  }

  void didChangeValue(R previousValue);
}
