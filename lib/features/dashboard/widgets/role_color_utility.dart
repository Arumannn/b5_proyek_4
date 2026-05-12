import 'package:flutter/material.dart';

/// Utility class for role-based color theming
/// Provides consistent colors across member selection and display
class RoleColorUtility {
  /// Get role badge background color
  static Color getRoleBadgeColor(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole == 'member') return const Color(0xFFE0E7FF); // Indigo light
    if (lowerRole == 'manager') return const Color(0xFFFCE7F3); // Pink light
    if (lowerRole == 'executive') return const Color(0xFFF0FDFA); // Teal light
    return const Color(0xFFF3F4F6); // Gray light
  }

  /// Get role text color for badges
  static Color getRoleTextColor(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole == 'member') return const Color(0xFF4F46E5); // Indigo
    if (lowerRole == 'manager') return const Color(0xFFDB2777); // Pink
    if (lowerRole == 'executive') return const Color(0xFF0D9488); // Teal
    return const Color(0xFF6B7280); // Gray
  }

  /// Get avatar background color based on role (blue gradient variations)
  static Color getAvatarColor(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole == 'member') return const Color(0xFF3B82F6); // Blue
    if (lowerRole == 'manager') return const Color(0xFF2563EB); // Darker blue
    if (lowerRole == 'executive') return const Color(0xFF1D4ED8); // Even darker blue
    return const Color(0xFF60A5FA); // Light blue
  }
}
