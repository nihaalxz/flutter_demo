import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../main_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLoginStatus();
    });
  }

  /// Checks the stored token and updates AppStateManager accordingly
  Future<void> _checkInitialLoginStatus() async {
    final authService = AuthService();
    final appState = Provider.of<AppStateManager>(context, listen: false);
    
    try {
      final loggedIn = await authService.isLoggedIn();
      
      if (mounted) {
        // Set the initial state in the AppStateManager.
        appState.initializeLoginStatus(loggedIn);
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // If there's an error checking login status, assume not logged in
      if (mounted) {
        appState.initializeLoginStatus(false);
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// Re-check login status when user attempts to login
  Future<void> _recheckLoginStatus() async {
    setState(() {
      _isInitialized = false;
    });
    await _checkInitialLoginStatus();
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading while checking initial status
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // This Consumer is now the main router for your app.
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        // If the user is logged in, show the MainScreen with a unique key.
        if (appState.isLoggedIn) {
          return MainScreen(key: appState.sessionKey);
        } 
        // Otherwise, show the LoginPage and pass the recheck callback
        else {
          return LoginPage(
            onLoginSuccess: _recheckLoginStatus, // Pass callback to LoginPage
          );
        }
      },
    );
  }
}