// lib/theme/theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Light Material theme ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFFF7F8FA),
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0.5,
  ),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF007AFF),
    secondary: Color(0xFF5AC8FA),
  ),
);

// --- Light Cupertino theme ---
const CupertinoThemeData lightCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF007AFF),
  scaffoldBackgroundColor: Color(0xFFF2F2F7),
  barBackgroundColor: Color(0xFFF9F9F9),
);

// --- Dark Material theme (RentHouse-style) ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color.fromARGB(255, 21, 26, 36),
  cardColor: const Color.fromARGB(255, 42, 46, 55),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB( 32, 40, 57,1),
    foregroundColor: Colors.white,
    elevation: 0.5,
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF60A5FA),
  ),
  iconTheme: const IconThemeData(color: Color(0xFF9CA3AF)),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color.fromARGB(255, 120, 139, 182),
    selectedItemColor: Color(0xFF3B82F6),
    unselectedItemColor: Color(0xFF9CA3AF),
  ),
);

// --- Dark Cupertino theme ---
const CupertinoThemeData darkCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF3B82F6),
  scaffoldBackgroundColor:  Color.fromARGB(255, 21, 26, 36),
  barBackgroundColor: Color(0xFF1A2234),
);
