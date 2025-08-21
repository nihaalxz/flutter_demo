import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import '../Auth/login_page.dart';
import '../main_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    // ✅ FIX: Add a minimal delay to ensure all initializations in main() are complete.
    // This pushes the navigation to the next event loop, resolving the race condition.
    await Future.delayed(Duration.zero);

    final bool loggedIn = await _authService.isLoggedIn();

    if (mounted) {
      if (loggedIn) {
        // If logged in, go to MainScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // If not logged in, go to LoginPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while we check the auth status
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
