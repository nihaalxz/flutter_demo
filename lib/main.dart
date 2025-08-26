import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'models/category_model.dart';
import 'pages/Auth/auth_check_screen.dart';
import 'services/theme_provider.dart';
import 'Theme/theme.dart'; // 👈 import our new theme file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ignore: deprecated_member_use
  FlutterNativeSplash.removeAfter(initialization);

  if (kDebugMode) {
    print("🚀 Flutter main() reached");
  }

  await Hive.initFlutter();

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  await Hive.openBox('p2p_cache');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateManager()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> initialization(BuildContext? context) async {
  await Future.delayed(const Duration(seconds: 1));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: lightTheme,     // 🌞 from theme.dart
          darkTheme: darkTheme, // 🌚 from theme.dart
          debugShowCheckedModeBanner: false,
          home: const AuthCheckScreen(),
        );
      },
    );
  }
}
