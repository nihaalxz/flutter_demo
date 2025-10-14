// lib/pages/main_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Cubits
import '../cubit/navigation_cubit.dart';

// Routes
import '../routes/app_routes.dart';

// Pages
import './Auth/login_page.dart';
import './home_page.dart';
import './wishlist_page.dart';
import './product/create_listing_page.dart';
import './bookings_page.dart';
import './Auth/profile_page.dart';

// Services & State
import '../services/notification_service.dart';
import '../state/AppStateManager.dart';

// Theme
import '../theme/theme.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  static Route<dynamic> route(RouteSettings settings) {
    return AppRoutes.generateRoute(settings);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StreamSubscription<UnreadUpdate>? _updateSubscription;
  
  // Navigation keys for each tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  // Pages - using IndexedStack for state preservation
  final List<Widget> _pages = const [
    HomePage(),
    WishlistPage(),
    CreateListingPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationCubit>().switchToTab(widget.initialIndex);
    });

    _initializeAppState();
    NotificationService.instance.connectToNotificationHub();
  }

  void _initializeAppState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      appState.fetchAllCounts();

      _updateSubscription = NotificationService.instance.unreadUpdateStream.listen(
        (update) {
          if (!mounted) return;

          final unreadCounts = update.unreadCounts;
          final bookingsCount = unreadCounts['bookingsCount'] ?? 0;
          context.read<NavigationCubit>().updateUnreadBookings(
            bookingsCount > 0,
          );

          // Show notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(update.notification.title),
                  if (update.notification.message != null)
                    Text(
                      update.notification.message!,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              backgroundColor: Theme.of(context).snackBarTheme.backgroundColor ??
                  Theme.of(context).primaryColor,
            ),
          );

          appState.updateCountsFromPush(update.unreadCounts);
        },
        onError: (error) => debugPrint('Notification stream error: $error'),
        cancelOnError: false,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is int) {
      context.read<NavigationCubit>().switchToTab(routeArgs);
    }
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      context.read<NavigationCubit>().switchToTab(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    NotificationService.instance.disconnectFromNotificationHub();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final appState = Provider.of<AppStateManager>(context, listen: false);

    if (index == 3) {
      appState.clearUnreadBookings();
      context.read<NavigationCubit>().updateUnreadBookings(false);
    }

    final currentIndex = context.read<NavigationCubit>().state.currentIndex;
    if (index == currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }

    context.read<NavigationCubit>().switchToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NavigationCubit, NavigationState>(
          listener: (context, state) {},
        ),
      ],
      child: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          if (!appState.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppRoutes.navigateToLogin(context);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildScaffold(appState);
        },
      ),
    );
  }

  Widget _buildScaffold(AppStateManager appState) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navState) {
        return Scaffold(
          body: IndexedStack(
            index: navState.currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context, appState, navState),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, AppStateManager appState, NavigationState navState) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            showBadge: appState.hasUnreadBookings || navState.hasUnreadBookings,
          ),
          label: 'Bookings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: navState.currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ?? theme.primaryColor,
      unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[600],
      showUnselectedLabels: true,
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: 8.0,
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required bool showBadge,
  }) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navState) {
        final isActive = navState.currentIndex == 3;
        final currentIcon = isActive ? activeIcon : icon;
        
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(currentIcon),
            if (showBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
