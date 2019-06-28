import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'delegate_widget.dart';
import 'provider.dart';

class AnimatedProvider<T> extends ValueDelegateWidget<Animation<T>> {
  AnimatedProvider.value({
    Key key,
    @required T value,
    @required InterpolationBuilder<T> interpolate,
    UpdateShouldNotify<T> updateShouldNotify,
    Duration duration,
    Curve curve,
    Widget child,
  }) : this._(
          key: key,
          delegate: _AnimatedProviderBuilderStateDelegate<T>(
            value,
            interpolate,
            duration: duration,
            curve: curve,
          ),
          updateShouldNotify: null,
          child: child,
        );

  AnimatedProvider._({
    Key key,
    @required ValueStateDelegate<Animation<T>> delegate,
    this.updateShouldNotify,
    this.duration,
    this.curve,
    this.child,
  }) : super(key: key, delegate: delegate);

  final UpdateShouldNotify<T> updateShouldNotify;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: delegate.value,
      builder: (context, child) {
        return InheritedProvider<T>(
          value: delegate.value.value,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );
      },
      child: child,
    );
  }
}

typedef InterpolationBuilder<T> = Tween<T> Function(
    T current, T end, Tween<T> previous);

class _AnimatedProviderBuilderStateDelegate<T>
    extends ValueStateDelegate<Animation<T>> {
  _AnimatedProviderBuilderStateDelegate(
    this._currentValue,
    this.builder, {
    this.duration,
    this.curve,
  });

  T _currentValue;
  Duration duration;
  Curve curve;
  InterpolationBuilder<T> builder;

  AnimationController _animationController;
  _TickerProvider _tickerProvider;
  @override
  Animation<T> value;
  Tween<T> _tween;

  @override
  void initDelegate() {
    super.initDelegate();
    _tickerProvider = _TickerProvider();
    _animationController = AnimationController(
      duration: duration,
      vsync: _tickerProvider,
    );
    value = AlwaysStoppedAnimation(_currentValue);
  }

  @override
  void didUpdateDelegate(_AnimatedProviderBuilderStateDelegate<T> old) {
    super.didUpdateDelegate(old);
    _animationController = old._animationController;
    _tickerProvider = old._tickerProvider;
    _tween = old._tween;
    value = old.value;

    if (duration != old.duration) {
      _animationController.duration = duration;
    }
    if (_currentValue != old._currentValue) {
      _tween = builder(value.value, _currentValue, _tween);
      value = (curve != null
              ? _animationController.drive(CurveTween(curve: curve))
              : _animationController)
          .drive(_tween);
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tickerProvider.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class _TickerProvider implements TickerProvider {
  Ticker _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError(
          '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.\n'
          'A SingleTickerProviderStateMixin can only be used as a TickerProvider once. If a '
          'State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.');
    }());
    _ticker = Ticker(onTick);
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker;
  }

  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker.isActive) return true;
      throw FlutterError('$this was disposed with an active Ticker.\n'
          '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose(). Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.\n'
          'The offending ticker was: ${_ticker.toString(debugIncludeStack: true)}');
    }());
  }

  void didChangeDependencies(BuildContext context) {
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
  }
}
