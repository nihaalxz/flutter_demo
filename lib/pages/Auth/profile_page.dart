import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/pages/gen/settings_page.dart';
import 'package:myfirstflutterapp/pages/wishlist_page.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'login_page.dart';

/// A complete user profile page that displays user information and provides
/// menu options for account management and logging out.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Fetches the current user's profile details from the AuthService.
  Future<void> _loadUserProfile() async {
    // Ensure loading state is true on refresh
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    final user = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  /// Logs the user out and navigates back to the LoginPage, clearing
  /// the navigation stack to prevent the user from going back.
  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor:Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: _buildProfileView(),
            ),
    );
  }

  /// Builds the main profile view with user info and menu options.
  Widget _buildProfileView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 20),
        _buildProfileHeader(),
        const SizedBox(height: 30),
        _buildSectionTitle("Verification"),
        _buildVerificationMenu(), // New menu for verification info
        const SizedBox(height: 30),
        _buildSectionTitle("Account"),
        _buildProfileMenu(),
        const SizedBox(height: 30),
        _buildSectionTitle("General"),
        _buildGeneralMenu(),
      ],
    );
  }

  /// The top section with the user's picture, name, and email.
  Widget _buildProfileHeader() {
    final String? pictureUrl = _currentUser!.pictureUrl;
    final hasPicture = pictureUrl != null && pictureUrl.isNotEmpty;
    final fullImageUrl = hasPicture
        ? "${AppConfig.imageBaseUrl}$pictureUrl"
        : null;

    // Format the "Member Since" date
String memberSince = '';

if (_currentUser?.joinedAt != null && _currentUser!.joinedAt!.isNotEmpty) {
  try {
    // Trim to remove any leading/trailing whitespace
    final joinedStr = _currentUser!.joinedAt!.trim();

    // Parse ISO 8601 string
    final date = DateTime.parse(joinedStr); // DateTime.parse supports ISO 8601
    memberSince = 'Member since ${DateFormat.yMMMMd().format(date)}';
  } catch (e) {
    // Fallback: show raw string if parsing fails
    memberSince = 'Member since ${_currentUser!.joinedAt}';
    if (kDebugMode) print('Warning: joinedAt not ISO format, showing raw value. $_currentUser!.joinedAt');
  }
} else {
  memberSince = 'Member since unknown';
}

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: hasPicture
              ? CachedNetworkImageProvider(fullImageUrl!)
              : null,
          child: !hasPicture
              ? Icon(Icons.person, size: 50, color: Theme.of(context).iconTheme.color)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser!.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _currentUser!.email,
          style: TextStyle(fontSize: 16, color: Theme.of(context).iconTheme.color),
        ),
        if (memberSince.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            memberSince,
            style: TextStyle(fontSize: 14, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ],
    );
  }

  /// Builds the menu for KYC status and phone number.
  Widget _buildVerificationMenu() {
    final bool isKycVerified = _currentUser?.isKycVerified ?? false;
    final String phoneNumber = _currentUser?.phoneNumber ?? "Not added";

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isKycVerified
                  ? Icons.verified_user_outlined
                  : Icons.report_problem_outlined,
              color: isKycVerified ? Colors.green : Colors.orange,
            ),
            title: const Text(
              'KYC Status',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              isKycVerified ? 'Verified' : 'Not Verified',
              style: TextStyle(
                color: isKycVerified ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.phone_outlined,color: Theme.of(context).iconTheme.color),
            title: const Text(
              'Phone Number',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              phoneNumber,
              style: TextStyle(color: Theme.of(context).iconTheme.color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of tappable menu items related to the user's account.
  Widget _buildProfileMenu() {
    final theme=Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to Edit Profile Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Edit Profile')),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.list_alt_outlined,
            title: 'My Listings',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to My Listings Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to My Listings')),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to Payment Methods Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Payment Methods')),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.heart_broken_rounded,
            title: 'My Wishlists',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: 'Help and Support',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the general settings and logout menu.
  Widget _buildGeneralMenu() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.info,
            title: 'About Us',
            textColor:Theme.of(context).iconTheme.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Theme.of(context).colorScheme.error,
            onTap: _logout, // Call the logout method
          ),
        ],
      ),
    );
  }

  /// A helper to create a title for a menu section.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// A helper to create styled ListTile widgets for the menu.
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[800]),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: textColor == null
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }

  /// A view to show when the user profile fails to load.
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "Could not load profile.",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection and try again.",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
