"""
App card widget with consistent styling and subtle interactions.

Provides a clean, professional card design with optional tap interaction.
"""
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'animations.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  
  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin ?? EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: elevation != null ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ] : null,
      ),
      padding: padding ?? EdgeInsets.all(AppSpacing.md),
      child: child,
    );
    
    if (onTap != null) {
      return ScaleTapWidget(
        onTap: onTap,
        child: card,
      );
    }
    
    return card;
  }
}

