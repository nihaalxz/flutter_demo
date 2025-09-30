// lib/state/main_tab_notifier.dart
import 'package:flutter/foundation.dart';

class MainTabNotifier extends ValueNotifier<int> {
  MainTabNotifier(int value) : super(value);

  void switchTab(int index) {
    if (index != value) value = index;
  }
}
