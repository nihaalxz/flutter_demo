import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:provider/provider.dart';
import 'models/product_model.dart';
import 'models/category_model.dart';
import '../pages/Auth/auth_check_screen.dart';
import 'services/theme_provider.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ignore: deprecated_member_use
  FlutterNativeSplash.removeAfter(initialization);

  if (kDebugMode) {
    print("🚀 Flutter main() reached");
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register your adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  // Open your boxes (like tables in a database)
  await Hive.openBox('p2p_cache');

  runApp(
    // ✅ 2. Use MultiProvider to provide all your state managers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AppStateManager(),
        ), // 👈 Add your new provider
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
    // ✅ FIX: Wrap MaterialApp with a Consumer to get the themeProvider
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          // Now 'themeProvider' is defined and can be used here
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,

            // Softer dark mode instead of pure black
            scaffoldBackgroundColor: const Color(0xFF202020),
            cardColor: const Color(0xFF2A2A2A),

            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(255, 249, 0, 0),
              secondary: Colors.amber,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthCheckScreen(),
        );
      },
    );
  }
}
