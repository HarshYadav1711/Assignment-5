"""
Reusable animation widgets for smooth, professional UI transitions.

All animations respect reduced motion preferences and are optimized for performance.
"""
import 'package:flutter/material.dart';

/// Fade in animation for content appearance
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  
  const FadeInWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
  }) : super(key: key);
  
  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final shouldReduceMotion = MediaQuery.of(context).disableAnimations;
    
    if (shouldReduceMotion) {
      return widget.child;
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

/// Slide in animation for list items
class SlideInListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  
  const SlideInListItem({
    Key? key,
    required this.child,
    required this.index,
    this.baseDuration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final shouldReduceMotion = MediaQuery.of(context).disableAnimations;
    
    if (shouldReduceMotion) {
      return child;
    }
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: baseDuration.inMilliseconds + (index * 50),
      ),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Scale animation for button/card taps
class ScaleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  
  const ScaleTapWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  }) : super(key: key);
  
  @override
  State<ScaleTapWidget> createState() => _ScaleTapWidgetState();
}

class _ScaleTapWidgetState extends State<ScaleTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final shouldReduceMotion = MediaQuery.of(context).disableAnimations;
    
    Widget animatedChild = shouldReduceMotion
        ? widget.child
        : ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          );
    
    if (widget.onTap == null) {
      return animatedChild;
    }
    
    return GestureDetector(
      onTapDown: shouldReduceMotion ? null : (_) => _controller.forward(),
      onTapUp: (_) {
        if (!shouldReduceMotion) _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: shouldReduceMotion ? null : () => _controller.reverse(),
      child: animatedChild,
    );
  }
}

/// Smooth state transition widget
class SmoothStateTransition<T> extends StatelessWidget {
  final T currentState;
  final Widget Function(T state) builder;
  final Duration duration;
  
  const SmoothStateTransition({
    Key? key,
    required this.currentState,
    required this.builder,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final shouldReduceMotion = MediaQuery.of(context).disableAnimations;
    
    if (shouldReduceMotion) {
      return builder(currentState);
    }
    
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(currentState),
        child: builder(currentState),
      ),
    );
  }
}

/// Success feedback animation
class SuccessFeedback extends StatefulWidget {
  final String message;
  final Duration displayDuration;
  
  const SuccessFeedback({
    Key? key,
    required this.message,
    this.displayDuration = const Duration(seconds: 2),
  }) : super(key: key);
  
  @override
  State<SuccessFeedback> createState() => _SuccessFeedbackState();
}

class _SuccessFeedbackState extends State<SuccessFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
    
    // Auto-dismiss
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final shouldReduceMotion = MediaQuery.of(context).disableAnimations;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: shouldReduceMotion ? AlwaysStoppedAnimation(1.0) : _scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                widget.message,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

