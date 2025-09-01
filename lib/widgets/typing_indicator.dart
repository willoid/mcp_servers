import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';
import 'dart:math' as math;

/// ============================================
/// TYPING INDICATOR WIDGET
/// ============================================
/// Animated dots that show when AI is thinking/typing
/// Uses a sine wave animation for smooth pulsing effect
///
/// ANIMATION DETAILS:
/// - 3 dots that pulse in sequence
/// - Each dot has a 0.2 second delay from the previous
/// - Uses sine wave for smooth opacity changes
/// - Repeats continuously while visible
/// ============================================

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  // Animation controller manages the animation timing
  late AnimationController _controller;

  // Animation value goes from 0.0 to 1.0 repeatedly
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Create animation controller with 1.5 second duration
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this, // Sync with screen refresh rate
    )..repeat(); // Repeat animation forever

    // Linear animation from 0 to 1
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    // Clean up animation controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds only when animation value changes
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            // STAGGER EFFECT:
            // Each dot starts animating 0.2 seconds after the previous one
            final delay = index * 0.2;

            // Calculate animation value for this specific dot
            // Clamp ensures value stays between 0 and 1
            final value = (_animation.value - delay).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // SINE WAVE OPACITY:
                // Uses sine function to create smooth pulsing
                // Base opacity: 0.3, Max opacity: 1.0
                color: Colors.grey.withOpacity(
                  0.3 + (0.7 * math.sin(value * math.pi)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
