// lib/widgets/rounded_app_bar.dart

import 'package:flutter/material.dart';

class RoundedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final TextEditingController? searchController; // Optional controller

  const RoundedAppBar({
    super.key,
    required this.subtitle,
    required this.title,
    this.leading,
    this.actions,
    this.searchController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(160.0); // The total height of the AppBar

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        color: Theme.of(context).primaryColor, // Use theme color
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row for profile picture, space, and actions
                Row(
                  children: [
                    if (leading != null) leading!,
                    const Spacer(), // Pushes actions to the right
                    if (actions != null) Row(mainAxisSize: MainAxisSize.min, children: actions!),
                  ],
                ),
                const SizedBox(height: 4),
                // Greeting and Username
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(), // Pushes search bar to the bottom
                // Search Bar
                Container(
                  height: 45, // Set a fixed height for the search bar
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Products...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 10), // Adjust padding
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}