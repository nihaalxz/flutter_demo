import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart'; // We will create this next

/// A page that allows users to change application settings, such as the theme.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get the current theme and toggle it.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // A card provides a clean, modern container for the setting.
          Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(themeProvider.isDarkMode ? 'Enabled' : 'Disabled'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  // When the switch is toggled, call the provider to change the theme.
                  themeProvider.toggleTheme(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
