import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- 🌞 Light Themes ---

/// Material theme for Android (Light Mode)
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFFF7F8FA), // A slightly off-white
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87, // Icon and text color
    elevation: 0.5,
  ),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF007AFF), // A standard blue
    secondary: Color(0xFF5AC8FA),
  ),
);

/// Cupertino theme for iOS (Light Mode)
const CupertinoThemeData lightCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF007AFF), // Standard iOS blue
  scaffoldBackgroundColor: Color(0xFFF2F2F7), // Standard iOS system gray
  barBackgroundColor: Color(0xF0F9F9F9), // Translucent app bar
);


// --- 🌚 Dark Themes ---

/// Material theme for Android (Dark Mode)
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFF121212), // A deep gray
  cardColor: const Color(0xFF1E1E1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0.5,
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF0A84FF), // A brighter blue for dark mode
    secondary: Color(0xFF64D2FF),
  ),
);

/// Cupertino theme for iOS (Dark Mode)
const CupertinoThemeData darkCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF0A84FF), // Brighter iOS blue for dark mode
  scaffoldBackgroundColor: Color(0xFF000000), // Pure black
  barBackgroundColor: Color(0xF01D1D1D), // Translucent dark app bar
);
