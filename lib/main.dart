// lib/main.dart (unified approach)
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myfirstflutterapp/cubit/navigation_cubit.dart';
import 'package:myfirstflutterapp/routes/app_routes.dart';
import 'package:myfirstflutterapp/services/navigation_service.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

// --- Assumed Imports ---
import 'models/product_model.dart';
import 'models/category_model.dart';
import 'pages/Auth/auth_check_screen.dart';
import 'services/theme_provider.dart';
import 'Theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        BlocProvider(create: (_) => NavigationCubit()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return OverlaySupport.global(
          child: Platform.isIOS
              ? CupertinoApp(
                  title: 'MapleCOT',
                  debugShowCheckedModeBanner: false,
                  theme: themeProvider.isDarkMode ? darkCupertinoTheme : lightCupertinoTheme,
                  localizationsDelegates: const [
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                    DefaultCupertinoLocalizations.delegate,
                  ],
                  initialRoute: AppRoutes.authCheck,
                  onGenerateRoute: AppRoutes.generateRoute,
                  navigatorKey: NavigationService.navigatorKey,
                  builder: (context, child) {
                    return Material(
                      type: MaterialType.transparency,
                      child: child,
                    );
                  },
                )
              : MaterialApp(
                  title: 'MapleCot',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  initialRoute: AppRoutes.authCheck,
                  onGenerateRoute: AppRoutes.generateRoute,
                  navigatorKey: NavigationService.navigatorKey,
                ),
        );
      },
    );
  }
}