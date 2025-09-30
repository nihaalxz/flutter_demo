// lib/routes/app_routes.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' show Platform;

// Cubit
import '../cubit/navigation_cubit.dart';

// Import all pages
import '../pages/main_screen.dart';
import '../pages/Auth/login_page.dart';
import '../pages/Auth/auth_check_screen.dart';
import '../pages/home_page.dart';
import '../pages/wishlist_page.dart';
import '../pages/product/create_listing_page.dart';
import '../pages/bookings_page.dart';
import '../pages/Auth/profile_page.dart';
import '../pages/product/product_details_page.dart';
import '../pages/createofferpage.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String home = '/home';
  static const String wishlist = '/wishlist';
  static const String createListing = '/create-listing';
  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String productDetails = '/product-details';
  static const String createOffer = '/create-offer';
  static const String authCheck = '/auth-check';

  // Helper function to create platform-appropriate page routes
  static PageRoute<T> _createRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool fullscreenDialog = false,
  }) {
    if (Platform.isIOS) {
      return CupertinoPageRoute<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    } else {
      return MaterialPageRoute<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }
  }

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
      case authCheck:
        return _createRoute(
          builder: (context) => const AuthCheckScreen(),
          settings: settings,
        );
      
      case login:
        return _createRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
      
      case main:
        int initialIndex = 0;
        if (args is int) {
          initialIndex = args;
        } else if (args is Map<String, dynamic>) {
          initialIndex = args['initialIndex'] ?? 0;
        }
        return _createRoute(
          builder: (context) => MainScreen(initialIndex: initialIndex),
          settings: settings,
        );
      
      case home:
        return _createRoute(
          builder: (context) => const HomePage(),
          settings: settings,
        );
      
      case wishlist:
        return _createRoute(
          builder: (context) => const WishlistPage(),
          settings: settings,
        );
      
      case createListing:
        return _createRoute(
          builder: (context) => const CreateListingPage(),
          settings: settings,
          fullscreenDialog: true,
        );
      
      case bookings:
        return _createRoute(
          builder: (context) => const BookingsPage(),
          settings: settings,
        );
      
      case profile:
        return _createRoute(
          builder: (context) => const ProfilePage(),
          settings: settings,
        );
      
      case productDetails:
        // Handle product details route with productId
        if (args is Map<String, dynamic> && args['productId'] != null) {
          final productId = args['productId'] as int;
          return _createRoute(
            builder: (context) => ProductDetailsPage(productId: productId),
            settings: settings,
          );
        } else if (args is int) {
          // Handle case where only productId is passed
          return _createRoute(
            builder: (context) => ProductDetailsPage(productId: args),
            settings: settings,
          );
        } else {
          // Fallback for invalid arguments
          return _createRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Product Details Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invalid arguments: $args',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
            settings: settings,
          );
        }
      
      case createOffer:
        // Handle create offer route
        if (args is Map<String, dynamic>) {
          final productName = args['productName'] as String? ?? '';
          final originalPrice = args['originalPrice'] as double? ?? 0.0;
          final productId = args['productId'] as int? ?? 0;
          
          return _createRoute(
            builder: (context) => CreateOfferPage(
              productName: productName,
              originalPrice: originalPrice,
              productId: productId,
            ),
            settings: settings,
            fullscreenDialog: true,
          );
        } else {
          return _createRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Create Offer Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invalid arguments: $args',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
            settings: settings,
          );
        }
      
      default:
        return _createRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Route Not Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No route defined for: ${settings.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      main,
                      (route) => false,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
          settings: settings,
        );
    }
  }

  // Navigation methods
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }

  static void navigateToMainScreen(BuildContext context, {int initialIndex = 0}) {
    // Update navigation state
    context.read<NavigationCubit>().switchToTab(initialIndex);
    
    // Navigate
    Navigator.of(context).pushNamedAndRemoveUntil(
      main,
      (route) => false,
      arguments: initialIndex,
    );
  }

  static void navigateToAuthCheck(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      authCheck,
      (route) => false,
    );
  }

  static void switchToTab(BuildContext context, int tabIndex) {
    // Update BLoC state
    context.read<NavigationCubit>().switchToTab(tabIndex);
    
    // Navigate to main screen if not already there
    if (ModalRoute.of(context)?.settings.name != main) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        main,
        (route) => false,
        arguments: tabIndex,
      );
    }
  }

  static void switchToBookingsTab(BuildContext context) {
    switchToTab(context, 3);
  }

  // Add this method to your AppRoutes.dart
// In your AppRoutes.dart, just use this simple method:
static void navigateToBookingsFromDetails(BuildContext context) {
  // Update BLoC state
  context.read<NavigationCubit>().switchToBookings();
  
  // Simply navigate to main - let pushNamedAndRemoveUntil handle the stack
  Navigator.of(context).pushNamedAndRemoveUntil(
    main,
    (route) => false,
    arguments: 3,
  );
}

  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacement<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static void popUntilMain(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.settings.name == main);
  }

  static void popUntilRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  // Product-specific navigation helpers
  static void navigateToProductDetails(BuildContext context, int productId) {
    push(
      context,
      productDetails,
      arguments: {'productId': productId},
    );
  }

  static void navigateToCreateOffer(
    BuildContext context, {
    required String productName,
    required double originalPrice,
    required int productId,
  }) {
    push(
      context,
      createOffer,
      arguments: {
        'productName': productName,
        'originalPrice': originalPrice,
        'productId': productId,
      },
    );
  }

  // Tab-specific navigation helpers
  static void navigateToHomeTab(BuildContext context) {
    switchToTab(context, 0);
  }

  static void navigateToWishlistTab(BuildContext context) {
    switchToTab(context, 1);
  }

  static void navigateToCreateTab(BuildContext context) {
    switchToTab(context, 2);
  }

  static void navigateToProfileTab(BuildContext context) {
    switchToTab(context, 4);
  }
}