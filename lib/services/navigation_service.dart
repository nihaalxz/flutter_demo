// lib/services/navigation_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../routes/app_routes.dart';
import '../cubit/navigation_cubit.dart';

class NavigationService {
  static void navigateToLogin(BuildContext context) {
    AppRoutes.navigateToLogin(context);
  }

  static void navigateToMainScreen(BuildContext context, {int initialIndex = 0}) {
    AppRoutes.navigateToMainScreen(context, initialIndex: initialIndex);
  }

  static void switchToTab(BuildContext context, int tabIndex) {
    AppRoutes.switchToTab(context, tabIndex);
  }

  static void switchToBookingsTab(BuildContext context) {
    AppRoutes.switchToBookingsTab(context);
  }

  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) {
    return AppRoutes.push<T>(context, routeName, arguments: arguments);
  }

  static void pop(BuildContext context, [dynamic result]) {
    AppRoutes.pop(context, result);
  }

  static void popUntilMain(BuildContext context) {
    AppRoutes.popUntilMain(context);
  }

  // Global navigation without context (use navigatorKey)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void globalNavigateToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  static void globalSwitchToBookingsTab() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.main,
      (route) => false,
      arguments: 3,
    );
  }
}