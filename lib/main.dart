import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

// --- Assumed Imports ---
import 'models/product_model.dart';
import 'models/category_model.dart';
import 'pages/Auth/auth_check_screen.dart';
import 'services/theme_provider.dart';
import 'Theme/theme.dart';

Future<void> main() async {
  // Ensure all necessary bindings are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    print("🚀 Flutter main() reached");
  }

  // Initialize Hive for local caching.
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  await Hive.openBox('p2p_cache');

  // Use MultiProvider to make global state available to the entire app.
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer listens to the ThemeProvider to rebuild the app when the theme changes.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // OverlaySupport is necessary for showing pop-up notification banners.
        return OverlaySupport.global(
          child: Platform.isIOS
              // --- Build the native-looking iOS App ---
              ? CupertinoApp(
                  title: 'MapleCOT',
                  debugShowCheckedModeBanner: false,
                  // ✅ Apply the correct light or dark Cupertino theme.
                  theme: themeProvider.isDarkMode ? darkCupertinoTheme : lightCupertinoTheme,
                  
                  // This provides the necessary "language pack" for any Material
                  // widgets that might be used within the Cupertino app structure.
                  localizationsDelegates: const [
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                    DefaultCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en', ''), // English
                  ],

                  // This builder wraps the app in a Material widget, which is a
                  // robust way to prevent errors if a Material widget is used
                  // on a page without a Scaffold.
                  builder: (context, child) {
                    return Material(
                      type: MaterialType.transparency,
                      child: child,
                    );
                  },
                  home: const AuthCheckScreen(),
                )
              // --- Build the native-looking Android App ---
              : MaterialApp(
                  title: 'MapleCot',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  home: const AuthCheckScreen(),
                ),
        );
      },
    );
  }
}

