import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart' show Provider;

/// A function that creates an object of type [T].
///
/// See also:
///
///  * [BuilderStateDelegate]
typedef ValueBuilder<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
///
/// See also:
///
///  * [BuilderStateDelegate]
typedef Disposer<T> = void Function(BuildContext context, T value);

/// The state of a [DelegateWidget].
///
/// See also:
///
///  * [ValueStateDelegate]
///  * [BuilderStateDelegate]
abstract class StateDelegate {
  BuildContext _context;

  /// The location in the tree where this widget builds.
  ///
  /// See also [State.context].
  BuildContext get context => _context;

  StateSetter _setState;

  /// Notify the framework that the internal state of this object has changed.
  ///
  /// See the discussion on [State.setState] for more information.
  @protected
  StateSetter get setState => _setState;

  /// Called on [State.initState] or after [DelegateWidget] is rebuilt
  /// with a [StateDelegate] of a different [runtimeType].
  @protected
  @mustCallSuper
  void initDelegate() {}

  /// Called whenever [State.didUpdateWidget] is called
  ///
  /// It is guaranteed for [old] to have the same [runtimeType] as `this`.
  @protected
  @mustCallSuper
  void didUpdateDelegate(covariant StateDelegate old) {}

  /// Called when [DelegateWidget] is unmounted or if it is rebuilt
  /// with a [StateDelegate] of a different [runtimeType].
  @protected
  @mustCallSuper
  void dispose() {}
}

/// A [StatefulWidget] that delegates its [State] implementation to a [StateDelegate].
///
/// This is useful for widgets that must switch between different [State] implementation
/// under the same [runtimeType].
///
/// A typical use-case is a non-leaf widget with constructors that behaves differently, as it is necessary for
/// all of its constructors to share the same [runtimeType] or else its descendants would loose
/// their state.
///
/// See also:
///
///  * [StateDelegate], the equivalent of [State] but for [DelegateWidget].
///  * [Provider], a concrete implementation of [DelegateWidget].
abstract class DelegateWidget extends StatefulWidget {
  /// Initializes [key] for subclasses.
  ///
  /// The argument [delegate] must not be `null`.
  const DelegateWidget({
    Key key,
    this.delegate,
  })  : assert(delegate != null),
        super(key: key);

  /// The current state of [DelegateWidget].
  ///
  /// It should not be `null`.
  @protected
  final StateDelegate delegate;

  /// Describes the part of the user interface represented by this widget.
  ///
  /// It is fine for [build] to depend on the content of [delegate].
  ///
  /// This method is strictly equivalent to [State.build].
  @protected
  Widget build(BuildContext context);

  @override
  StatefulElement createElement() => _DelegateElement(this);

  @override
  _DelegateWidgetState createState() => _DelegateWidgetState();
}

class _DelegateWidgetState extends State<DelegateWidget> {
  @override
  void initState() {
    super.initState();
    _mountDelegate();
    _initDelegate();
  }

  void _initDelegate() {
    assert(() {
      (context as _DelegateElement)._debugIsInitDelegate = true;
      return true;
    }());
    widget.delegate.initDelegate();
    assert(() {
      (context as _DelegateElement)._debugIsInitDelegate = false;
      return true;
    }());
  }

  void _mountDelegate() {
    widget.delegate
      .._context = context
      .._setState = setState;
  }

  void _unmountDelegate(StateDelegate delegate) {
    delegate
      .._context = null
      .._setState = null;
  }

  @override
  void didUpdateWidget(DelegateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      _mountDelegate();
      if (widget.delegate.runtimeType != oldWidget.delegate.runtimeType) {
        oldWidget.delegate.dispose();
        _initDelegate();
      } else {
        widget.delegate.didUpdateDelegate(oldWidget.delegate);
      }
      _unmountDelegate(oldWidget.delegate);
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    widget.delegate.dispose();
    _unmountDelegate(widget.delegate);
    super.dispose();
  }
}

class _DelegateElement extends StatefulElement {
  _DelegateElement(DelegateWidget widget) : super(widget);

  bool _debugIsInitDelegate = false;

  @override
  DelegateWidget get widget => super.widget as DelegateWidget;

  @override
  InheritedWidget inheritFromElement(Element ancestor, {Object aspect}) {
    assert(() {
      if (_debugIsInitDelegate) {
        final targetType = ancestor.widget.runtimeType;
        // error copied from StatefulElement
        throw FlutterError(
            'inheritFromWidgetOfExactType($targetType) or inheritFromElement() was called before ${widget.delegate.runtimeType}.initDelegate() completed.\n'
            'When an inherited widget changes, for example if the value of Theme.of() changes, '
            'its dependent widgets are rebuilt. If the dependent widget\'s reference to '
            'the inherited widget is in a constructor or an initDelegate() method, '
            'then the rebuilt dependent widget will not reflect the changes in the '
            'inherited widget.\n'
            'Typically references to inherited widgets should occur in widget build() methods. Alternatively, '
            'initialization based on inherited widgets can be placed in the didChangeDependencies method, which '
            'is called after initDelegate and whenever the dependencies change thereafter.');
      }
      return true;
    }());
    return super.inheritFromElement(ancestor, aspect: aspect);
  }
}

/// A base class for [StateDelegate] that exposes a [value] of type [T].
///
/// See also:
///
///  * [SingleValueDelegate], which extends [ValueStateDelegate] to store
///  an immutable value.
///  * [BuilderStateDelegate], which extends [ValueStateDelegate]
/// to build [value] from a function and dispose it when the widget is unmounted.
abstract class ValueStateDelegate<T> extends StateDelegate {
  /// The member [value] should not be mutated directly.
  T get value;
}

/// Stores an immutable value.
class SingleValueDelegate<T> extends ValueStateDelegate<T> {
  /// Initializes [value] for subclasses.
  SingleValueDelegate(this.value);

  @override
  final T value;
}

/// A [StateDelegate] that creates and dispose a value from functions.
///
/// See also:
///
///  * [ValueStateDelegate], which [BuilderStateDelegate] implements.
class BuilderStateDelegate<T> extends ValueStateDelegate<T> {
  /// The parameter `builder` must not be `null`.
  BuilderStateDelegate(this._builder, {Disposer<T> dispose})
      : assert(_builder != null),
        _dispose = dispose;

  /// A callback used to create [value].
  ///
  /// Once [value] is initialized, [_builder] will never be called again
  /// and [value] will never change.
  ///
  /// See also:
  ///
  ///  * [value], which [_builder] creates.
  final ValueBuilder<T> _builder;
  final Disposer<T> _dispose;

  T _value;
  @override
  T get value => _value;

  @override
  void initDelegate() {
    super.initDelegate();
    _value = _builder(context);
  }

  @override
  void didUpdateDelegate(BuilderStateDelegate<T> old) {
    super.didUpdateDelegate(old);
    _value = old.value;
  }

  @override
  void dispose() {
    _dispose?.call(context, value);
    super.dispose();
  }
}

/// A [DelegateWidget] that accepts only [ValueStateDelegate] as [delegate].
///
/// See also:
///
///  * [DelegateWidget]
///  * [ValueStateDelegate]
abstract class ValueDelegateWidget<T> extends DelegateWidget {
  /// Initializes [key] for subclasses.
  ///
  /// The argument [delegate] must not be `null`.
  ValueDelegateWidget({
    Key key,
    @required ValueStateDelegate<T> delegate,
  }) : super(key: key, delegate: delegate);

  @override
  @protected
  ValueStateDelegate<T> get delegate =>
      super.delegate as ValueStateDelegate<T>;
}
