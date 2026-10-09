import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Frosted container. Keep blur regions small: BackdropFilter is costly on mid-range GPUs.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = 24, this.padding});
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: cardShadow,
          ),
          child: child,
        ),
      ),
    ),
  );
}
