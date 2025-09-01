import 'package:flutter/material.dart';

/// 🌞 Light Theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Color.fromARGB(0, 255, 255, 255),
  cardColor: const Color.fromARGB(0, 255, 255, 255),
  colorScheme: const ColorScheme.light(
    primary: Color(0xC62828), // deep red
    secondary: Color(0xAD1457), // accent
    surface: Color(0xFFFFFF), // light surface
  ),
);

/// 🌚 Dark Theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0x303F9F),
  cardColor: const Color(0xffffffff),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xE57373 ), // deep red
    secondary: Color(0xF06292),
    surface: Color(0x37474F), // dark surface
  ),
);
