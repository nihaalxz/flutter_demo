// lib/cubit/tab_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class TabCubit extends Cubit<int> {
  TabCubit() : super(0); // Start with home tab (index 0)

  void switchToTab(int index) {
    if (index != state) {
      emit(index);
    }
  }

  void switchToHome() => switchToTab(0);
  void switchToWishlist() => switchToTab(1);
  void switchToCreate() => switchToTab(2);
  void switchToBookings() => switchToTab(3);
  void switchToProfile() => switchToTab(4);
}