"""
Color palette for Smart Trip Planner.

Professional, trustworthy color scheme with high contrast for accessibility.
"""
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (trustworthy, professional blue)
  static const Color primary = Color(0xFF2563EB);      // Blue - trust, reliability
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  
  // Neutral colors (clean, minimal)
  static const Color background = Color(0xFFF9FAFB);   // Light gray
  static const Color surface = Color(0xFFFFFFFF);      // White
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  
  // Text colors (high contrast for accessibility)
  static const Color textPrimary = Color(0xFF111827);   // Near black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);       // Green
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color error = Color(0xFFEF4444);         // Red
  static const Color info = Color(0xFF3B82F6);          // Blue
  
  // Border and divider
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Disabled state
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);
}

