// // lib/routes/route_utils.dart
// import 'package:flutter/material.dart';
// import 'app_routes.dart';

// class RouteUtils {
//   // Check if we're already on the MainScreen
//   static bool isMainScreenCurrent(BuildContext context) {
//     return ModalRoute.of(context)?.settings.name == AppRoutes.main;
//   }

//   // Get current tab index from MainScreen arguments
//   static int getCurrentTabIndex(BuildContext context) {
//     final route = ModalRoute.of(context);
//     if (route?.settings.name == AppRoutes.main) {
//       final args = route?.settings.arguments;
//       if (args is int) {
//         return args;
//       } else if (args is Map<String, dynamic>) {
//         return args['initialIndex'] ?? 0;
//       }
//     }
//     return 0;
//   }

//   // Smart navigation that handles both tab switching and full navigation
//   static void smartNavigateToTab(BuildContext context, int tabIndex) {
//     if (isMainScreenCurrent(context) && getCurrentTabIndex(context) == tabIndex) {
//       // Already on the target tab, just pop to root if needed
//       Navigator.of(context).popUntil((route) => route.isFirst);
//     } else {
//       // Navigate to MainScreen with the desired tab
//       AppRoutes.switchToTab(context, tabIndex);
//     }
//   }

//   // Platform-aware back navigation
//   static void platformAwarePop(BuildContext context) {
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     } else {
//       // If can't pop, switch to home tab as fallback
//       AppRoutes.switchToTab(context, 0);
//     }
//   }
// }