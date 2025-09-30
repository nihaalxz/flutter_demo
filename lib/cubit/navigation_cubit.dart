// lib/cubit/navigation_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

enum NavItem {
  home,
  wishlist,
  create,
  bookings,
  profile,
}

class NavigationState {
  final NavItem currentTab;
  final bool hasUnreadBookings;
  final bool canPop;

  const NavigationState({
    required this.currentTab,
    this.hasUnreadBookings = false,
    this.canPop = false,
  });

  // Get the index from the enum (uses the built-in index property)
  int get currentIndex => currentTab.index;

  NavigationState copyWith({
    NavItem? currentTab,
    bool? hasUnreadBookings,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      hasUnreadBookings: hasUnreadBookings ?? this.hasUnreadBookings,
    );
  }
}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit()
      : super(const NavigationState(
          currentTab: NavItem.home,
          hasUnreadBookings: false,
        ));

  void switchToTab(int index) {
    if (index >= 0 && index < NavItem.values.length) {
      final newTab = NavItem.values[index];
      emit(state.copyWith(currentTab: newTab));
    }
  }

  void switchToNavItem(NavItem navItem) {
    emit(state.copyWith(currentTab: navItem));
  }

  void updateUnreadBookings(bool hasUnread) {
    emit(state.copyWith(hasUnreadBookings: hasUnread));
  }

  // Convenience methods
  void switchToHome() => switchToNavItem(NavItem.home);
  void switchToWishlist() => switchToNavItem(NavItem.wishlist);
  void switchToCreate() => switchToNavItem(NavItem.create);
  void switchToBookings() => switchToNavItem(NavItem.bookings);
  void switchToProfile() => switchToNavItem(NavItem.profile);
}