import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xB3FFFFFF); // 70% opacity white
  static const Color lightTextPrimary = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightAccent = Color(0xFF121212);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0C0C0C);
  static const Color darkCardBg = Color(0xB3191919); // 70% opacity dark grey
  static const Color darkTextPrimary = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkAccent = Color(0xFFFFFFFF);
  
  // Danger Color
  static const Color danger = Color(0xFFFF4444);

  // Note Colors (Pastel)
  static const List<Color> noteColors = [
    Colors.transparent, // Default
    Color(0xFFF28B82), // Red
    Color(0xFFFBBC04), // Orange
    Color(0xFFFFF475), // Yellow
    Color(0xFFCCFF90), // Green
    Color(0xFFA7FFEB), // Teal
    Color(0xFFCBF0F8), // Blue
    Color(0xFFAFCBEE), // Dark Blue
    Color(0xFFD7AEFB), // Purple
    Color(0xFFFDCFE8), // Pink
    Color(0xFFE6C9A8), // Brown
    Color(0xFFE8EAED), // Gray
  ];
}
