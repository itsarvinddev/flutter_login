import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_login/src/utils/math_helper.dart';
import 'package:flutter_login/src/utils/matrix.dart';
import 'package:flutter_login/src/utils/widget_helper.dart';

/// The direction in which the text should animate during transitions.
enum AnimatedTextRotation {
  /// Text animates upward (slides up and fades out).
  up,

  /// Text animates downward (slides down and fades out).
  down,
}

/// A widget that animates its [text] vertically with a fade and slide effect,
/// either upwards or downwards depending on [textRotation].
///
/// Commonly used in animated UI elements like tab bars, login cards,
/// or value changes.
///
/// Inspired by 3D tab animations:
/// https://medium.com/flutter-community/flutter-challenge-3d-bottom-navigation-bar-48952a5fd996
class AnimatedText extends StatefulWidget {
  /// Creates an [AnimatedText] widget.
  ///
  /// The [text] parameter must not be null.
  /// By default, [textRotation] is set to [AnimatedTextRotation.up].
  const AnimatedText({
    required this.text,
    super.key,
    this.style,
    this.textRotation = AnimatedTextRotation.up,
  });

  /// The string to be displayed and animated.
  final String text;

  /// The style to apply to the animated text.
  final TextStyle? style;

  /// The direction in which the text rotates or animates.
  ///
  /// Defaults to [AnimatedTextRotation.up].
  final AnimatedTextRotation textRotation;

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  var _newText = '';
  var _oldText = '';
  double? _layoutHeight = 0;
  final GlobalKey<State<StatefulWidget>> _textKey = GlobalKey();

  late Animation<double> _animation;
  late AnimationController _controller;

  double get radius => _layoutHeight! / 2;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0, end: pi / 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _oldText = widget.text;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _layoutHeight = getWidgetSize(_textKey)?.height);
    });
  }

  @override
  void didUpdateWidget(AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      _oldText = oldWidget.text;
      _newText = widget.text;
      _controller.forward().then((_) {
        setState(() {
          final t = _oldText;
          _oldText = _newText;
          _newText = t;
        });
        _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Matrix4 get _matrix {
    // Fix: The text is not centered after applying perspective effect in the web build. Idk why
    if (kIsWeb) {
      return Matrix4.identity();
    }
    return perspective(.006);
  }

  Matrix4 _getFrontSideUp(double value) {
    return _matrix
      ..translate(
        0.0,
        -radius * sin(_animation.value),
        -radius * cos(_animation.value),
      )
      ..rotateX(-_animation.value); // 0 -> -pi/2
  }

  Matrix4 _getBackSideUp(double value) {
    return _matrix
      ..translate(
        0.0,
        radius * cos(_animation.value),
        -radius * sin(_animation.value),
      )
      ..rotateX((pi / 2) - _animation.value); // pi/2 -> 0
  }

  Matrix4 _getFrontSideDown(double value) {
    return _matrix
      ..translate(
        0.0,
        radius * sin(_animation.value),
        -radius * cos(_animation.value),
      )
      ..rotateX(_animation.value); // 0 -> pi/2
  }

  Matrix4 _getBackSideDown(double value) {
    return _matrix
      ..translate(
        0.0,
        -radius * cos(_animation.value),
        -radius * sin(_animation.value),
      )
      ..rotateX(_animation.value - pi / 2); // -pi/2 -> 0
  }

  @override
  Widget build(BuildContext context) {
    final rollUp = widget.textRotation == AnimatedTextRotation.up;
    final oldText = Text(
      _oldText,
      key: _textKey,
      style: widget.style,
      overflow: TextOverflow.visible,
      softWrap: false,
    );
    final newText = Text(
      _newText,
      style: widget.style,
      overflow: TextOverflow.visible,
      softWrap: false,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (_animation.value <= toRadian(85))
            Transform(
              alignment: Alignment.center,
              transform: rollUp
                  ? _getFrontSideUp(_animation.value)
                  : _getFrontSideDown(_animation.value),
              child: oldText,
            ),
          if (_animation.value >= toRadian(5))
            Transform(
              alignment: Alignment.center,
              transform: rollUp
                  ? _getBackSideUp(_animation.value)
                  : _getBackSideDown(_animation.value),
              child: newText,
            ),
        ],
      ),
    );
  }
}
