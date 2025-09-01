import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- 🌞 Light Themes ---

/// Material theme for Android (Light Mode)
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Color(0xFFECEFF4),
  cardColor: const Color.fromARGB(255, 245, 245, 245),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF5E81AC), // deep red
    secondary: Color(0xFF88C0D0), // accent
    surface: Color(0xFFF5F5F5), // light surface
  ),
);

/// 🌚 Dark Theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color.fromARGB(255, 18, 18, 18),
  cardColor: const Color.fromARGB(255, 36, 36, 36),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF88C0D0), // deep red
    secondary: Color(0xFF5E81AC),
    surface: Color(0xFF3B4252), // dark surface
  ),
);
