import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/product_model.dart'; // Import your models
import 'models/category_model.dart';
import 'pages/Auth/auth_wrapper.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register your adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  // Open your boxes (like tables in a database)
  await Hive.openBox('p2p_cache');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
