import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Element findElementOfWidget<T extends Widget>() {
  return find.byType(T).first.evaluate().first;
}