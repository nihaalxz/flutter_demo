import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/pages/gen/settings_page.dart';
import 'package:myfirstflutterapp/pages/wishlist_page.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:provider/provider.dart';

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

  Future<void> _loadUserProfile() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    final user = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  /// ✅ --- THIS IS THE KEY FIX ---
  /// The method no longer takes a context parameter because it's already
  /// available as a property of the State class.
  Future<void> _logout() async {
    // 1. Tell the central state manager to log out.
    // We use the 'context' property that belongs to the widget's state.
    Provider.of<AppStateManager>(context, listen: false).logout();
    
    // 2. Tell the auth service to delete the token from secure storage.
    await _authService.logout();
    
    // 3. Navigation is now handled automatically by the MainScreen/AuthCheckScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: SafeArea(
                    child: _buildProfileView(),
                  ),
                ),
    );
  }

  Widget _buildProfileView() {
    // ... (Your existing build methods for the UI remain the same)
    // The only change is in how the logout button's onTap is called.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
          .copyWith(bottom: 32),
      children: [
        const SizedBox(height: 20),
        _buildProfileHeader(),
        const SizedBox(height: 30),
        _buildSectionTitle("Verification"),
        _buildVerificationMenu(),
        const SizedBox(height: 30),
        _buildSectionTitle("Account"),
        _buildProfileMenu(),
        const SizedBox(height: 30),
        _buildSectionTitle("General"),
        _buildGeneralMenu(),
      ],
    );
  }

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
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.info,
            title: 'About Us',
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to About Us page
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // ✅ The onTap callback now correctly matches the VoidCallback type.
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Theme.of(context).colorScheme.error,
            onTap: _logout, // No context is passed here
          ),
        ],
      ),
    );
  }
  
  // --- The rest of your existing builder methods ---
  // (_buildProfileHeader, _buildVerificationMenu, _buildProfileMenu, etc.)
  // can remain exactly as they are.
  
    Widget _buildProfileHeader() {
    final String? pictureUrl = _currentUser!.pictureUrl;
    final hasPicture = pictureUrl != null && pictureUrl.isNotEmpty;
    final fullImageUrl = hasPicture ? "${AppConfig.imageBaseUrl}$pictureUrl" : null;

    String memberSince = '';
    if (_currentUser?.joinedAt != null && _currentUser!.joinedAt!.isNotEmpty) {
      try {
        final joinedStr = _currentUser!.joinedAt!.trim();
        // Assuming the joinedAt from the token is a Unix timestamp in seconds
        final timestamp = int.parse(joinedStr);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        memberSince = 'Member since ${DateFormat.yMMMMd().format(date)}';
      } catch (e) {
        memberSince = 'Member since unknown';
        if (kDebugMode) {
          print('Warning: could not parse joinedAt date. Value: ${_currentUser!.joinedAt}');
        }
      }
    } else {
      memberSince = 'Member since unknown';
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: hasPicture ? CachedNetworkImageProvider(fullImageUrl!) : null,
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
          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        if (memberSince.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            memberSince,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ],
    );
  }

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
              isKycVerified ? Icons.verified_user_outlined : Icons.report_problem_outlined,
              color: isKycVerified ? Colors.green : Colors.orange,
            ),
            title: const Text('KYC Status', style: TextStyle(fontWeight: FontWeight.w500)),
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
            leading: Icon(Icons.phone_outlined, color: Theme.of(context).iconTheme.color),
            title: const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(
              phoneNumber,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    final theme = Theme.of(context);
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
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to Edit Profile
            },
          ),
          _buildMenuTile(
            icon: Icons.list_alt_outlined,
            title: 'My Listings',
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to My Listings
            },
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to Payment Methods
            },
          ),
          _buildMenuTile(
            icon: Icons.favorite_border_rounded,
            title: 'My Wishlist',
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: 'Help and Support',
            textColor: Theme.of(context).iconTheme.color,
            onTap: () {
              // TODO: Navigate to Help & Support
            },
          ),
        ],
      ),
    );
  }

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
      trailing: textColor == null || textColor != Theme.of(context).colorScheme.error
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
  
    Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text("Could not load profile.", style: TextStyle(fontSize: 18)),
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
