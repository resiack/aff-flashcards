import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlippableCard extends StatefulWidget {
  const FlippableCard({
    super.key,
    required this.text,
    required this.isFlipped,
    required this.onTap,
    this.showHint = false,
    this.onHintResolved,
  });

  final String text;
  final bool isFlipped;
  final VoidCallback onTap;
  final bool showHint;
  final VoidCallback? onHintResolved;

  @override
  State<FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<FlippableCard>
    with SingleTickerProviderStateMixin {
  static const _pendingDelay = Duration(milliseconds: 500);
  static const _hintDuration = Duration(milliseconds: 1100);
  static const _peakTiltRadians = 0.12;

  bool _isHovering = false;
  bool _isPressed = false;
  bool _isFocused = false;
  Timer? _pendingHintTimer;
  final _focusNode = FocusNode(debugLabel: 'FlippableCard');

  late final AnimationController _hintController;
  late final Animation<double> _tiltFraction;
  late final Animation<double> _iconOpacity;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(vsync: this, duration: _hintDuration);
    _tiltFraction = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _hintController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _iconOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _hintController,
            curve: const Interval(0.05, 0.75, curve: Curves.easeInOut),
          ),
        );
    if (widget.showHint) _scheduleHint();
  }

  @override
  void didUpdateWidget(covariant FlippableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHint && !oldWidget.showHint) _scheduleHint();
  }

  void _scheduleHint() {
    _pendingHintTimer = Timer(_pendingDelay, () {
      _pendingHintTimer = null;
      if (!mounted) return;
      _hintController.forward(from: 0);
      widget.onHintResolved?.call();
    });
  }

  /// Cancels whichever hint stage is active (pending delay or running
  /// animation), if any. Safe to call when neither is active.
  void _cancelHint() {
    if (_pendingHintTimer != null) {
      _pendingHintTimer!.cancel();
      _pendingHintTimer = null;
      widget.onHintResolved?.call();
    } else if (_hintController.isAnimating) {
      _hintController.stop();
      _hintController.value = 0;
    }
  }

  void _handleTap() {
    _cancelHint();
    widget.onTap();
  }

  @override
  void dispose() {
    _pendingHintTimer?.cancel();
    _hintController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = widget.isFlipped ? 'Show question' : 'Reveal answer';
    final scale = _isPressed ? 0.98 : (_isHovering ? 1.02 : 1.0);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      focusable: true,
      focused: _isFocused,
      label: widget.text,
      hint: actionLabel,
      onTap: _handleTap,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          focusNode: _focusNode,
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (hovering) =>
              setState(() => _isHovering = hovering),
          onShowFocusHighlight: (focused) =>
              setState(() => _isFocused = focused),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _handleTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: _handleTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: Container(
              key: const Key('focus-ring'),
              foregroundDecoration: BoxDecoration(
                border: _isFocused
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 120),
                child: AnimatedBuilder(
                  animation: _hintController,
                  builder: (context, child) {
                    final tilt = reducedMotion
                        ? 0.0
                        : _tiltFraction.value * _peakTiltRadians;
                    return Transform(
                      key: const Key('hint-tilt-transform'),
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(tilt),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 48, 48, 24),
                          child: Builder(
                            builder: (context) {
                              final isMultiline = widget.text.contains('\n');
                              return SingleChildScrollView(
                                child: Text(
                                  widget.text,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: isMultiline
                                      ? TextAlign.left
                                      : TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _iconOpacity,
                          builder: (context, _) => Opacity(
                            opacity: _iconOpacity.value,
                            child: Icon(
                              Icons.touch_app,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
