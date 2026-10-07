import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors (Clean, modern, highly legible)
  static const Color lightPrimary = Color(0xFF4361EE);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFFE8EEFF);
  static const Color lightOnPrimaryContainer = Color(0xFF2B3A8F);
  
  static const Color lightSecondary = Color(0xFF3F37C9);
  static const Color lightOnSecondary = Colors.white;
  
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightOnBackground = Color(0xFF0F172A);
  
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);
  
  static const Color lightOutline = Color(0xFFCBD5E1);

  // Dark Theme Colors (Deep Sapphire and Dark Gray blend)
  static const Color darkPrimary = Color(0xFF4CC9F0);
  static const Color darkOnPrimary = Color(0xFF0F172A);
  static const Color darkPrimaryContainer = Color(0xFF1E293B);
  static const Color darkOnPrimaryContainer = Color(0xFF38BDF8);
  
  static const Color darkSecondary = Color(0xFF7209B7);
  static const Color darkOnSecondary = Colors.white;
  
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkOnBackground = Color(0xFFF1F5F9);
  
  static const Color darkSurface = Color(0xFF131926);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  
  static const Color darkOutline = Color(0xFF334155);

  // Status & Custom colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Predefined lesson colors
  static const Color math = Color(0xFFFF5722);        // Deep Orange
  static const Color turkish = Color(0xFF2196F3);     // Blue
  static const Color history = Color(0xFF795548);     // Brown
  static const Color geography = Color(0xFF4CAF50);   // Green
  static const Color civics = Color(0xFF009688);      // Teal (Vatandaşlık)
  static const Color geometry = Color(0xFFFF9800);    // Orange
  static const Color physics = Color(0xFF3F51B5);     // Indigo
  static const Color chemistry = Color(0xFF9C27B0);   // Purple
  static const Color biology = Color(0xFF8BC34A);     // Light Green
  static const Color english = Color(0xFF00BCD4);     // Cyan
  
  // Return lesson-specific color based on name/index or ID
  static Color getLessonColor(String name) {
    switch (name.trim().toLowerCase()) {
      case 'matematik':
        return math;
      case 'türkçe':
        return turkish;
      case 'tarih':
        return history;
      case 'coğrafya':
        return geography;
      case 'vatandaşlık':
        return civics;
      case 'geometri':
        return geometry;
      case 'fizik':
        return physics;
      case 'kimya':
        return chemistry;
      case 'biyoloji':
        return biology;
      case 'ingilizce':
        return english;
      default:
        return lightPrimary;
    }
  }
}
