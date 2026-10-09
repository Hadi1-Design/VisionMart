import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool showGlow;
  final Color? glowColor;
  final Color? severityColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.showGlow = false,
    this.glowColor,
    this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: (glowColor ?? AppColors.primary).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Stack(
              children: [
                if (severityColor != null)
                  Positioned(
                    left: 0,
                    top: 20,
                    bottom: 20,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: severityColor!.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: (padding ?? const EdgeInsets.all(16)).add(
                    EdgeInsets.only(left: severityColor != null ? 8 : 0),
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextGradient extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const TextGradient({
    super.key,
    required this.text,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

class AnimatedTouchable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;

  const AnimatedTouchable({
    super.key, 
    required this.child, 
    this.onTap,
    this.behavior,
  });

  @override
  State<AnimatedTouchable> createState() => _AnimatedTouchableState();
}

class _AnimatedTouchableState extends State<AnimatedTouchable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null ? null : (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
