import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haptic played the moment a [Pressable] registers a completed tap.
enum PressHaptic { none, selection, light, medium }

/// A tap wrapper that gives any child a premium tactile response:
/// a quick scale-down the instant a finger lands, then a springy
/// settle back (with a tiny overshoot) when it lifts.
///
/// This is the single tap primitive across Pollora — using it everywhere
/// is what makes the whole app feel consistent, smooth and alive.
///
/// ```dart
/// Pressable(
///   onTap: () => doThing(),
///   child: MyButton(),
/// )
/// ```
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = PressHaptic.none,
    this.behavior = HitTestBehavior.opaque,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale at full press. 1.0 = no shrink. Smaller = punchier.
  final double pressedScale;

  /// Haptic fired on a completed tap. Defaults to none so callers that
  /// already manage their own haptics don't double-buzz.
  final PressHaptic haptic;

  final HitTestBehavior behavior;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Fast press-in, slower springy release.
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 360),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        // easeOutBack on the way back gives a subtle overshoot past 1.0 —
        // the little "pop" that makes a release feel satisfying.
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _pressDown(_) {
    if (!_interactive) return;
    _controller.forward();
  }

  void _pressUp(_) {
    if (!_interactive) return;
    _controller.reverse();
  }

  void _pressCancel() {
    if (!_interactive) return;
    _controller.reverse();
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case PressHaptic.none:
        break;
      case PressHaptic.selection:
        HapticFeedback.selectionClick();
      case PressHaptic.light:
        HapticFeedback.lightImpact();
      case PressHaptic.medium:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _pressDown,
      onTapUp: _pressUp,
      onTapCancel: _pressCancel,
      onTap: _interactive
          ? () {
              _fireHaptic();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _fireHaptic();
              widget.onLongPress!.call();
            },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
