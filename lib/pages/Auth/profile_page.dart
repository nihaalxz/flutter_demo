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

  Future<void> _logout() async {
    Provider.of<AppStateManager>(context, listen: false).logout();
    await _authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            textColor: theme.textTheme.bodyLarge?.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.info,
            title: 'About Us',
            textColor: theme.textTheme.bodyLarge?.color,
            onTap: () {
              // TODO: Navigate to About Us page
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Theme.of(context).colorScheme.error,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final String? pictureUrl = _currentUser!.pictureUrl;
    final hasPicture = pictureUrl != null && pictureUrl.isNotEmpty;
    final fullImageUrl = hasPicture ? "${AppConfig.imageBaseUrl}$pictureUrl" : null;

    String memberSince = '';
    if (_currentUser?.joinedAt != null && _currentUser!.joinedAt!.isNotEmpty) {
      try {
        final joinedStr = _currentUser!.joinedAt!.trim();
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
          backgroundColor: theme.cardColor,
          backgroundImage: hasPicture ? CachedNetworkImageProvider(fullImageUrl!) : null,
          child: !hasPicture
              ? Icon(
                  Icons.person, 
                  size: 50, 
                  color: theme.iconTheme.color,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser!.fullName,
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currentUser!.email,
          style: TextStyle(
            fontSize: 16, 
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        if (memberSince.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            memberSince,
            style: TextStyle(
              fontSize: 14, 
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationMenu() {
    final theme = Theme.of(context);
    final bool isKycVerified = _currentUser?.isKycVerified ?? false;
    final String phoneNumber = _currentUser?.phoneNumber ?? "Not added";

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isKycVerified ? Icons.verified_user_outlined : Icons.report_problem_outlined,
              color: isKycVerified ? Colors.green : Colors.orange,
            ),
            title: Text(
              'KYC Status',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
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
            leading: Icon(
              Icons.phone_outlined, 
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Phone Number',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            trailing: Text(
              phoneNumber,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color, 
                fontSize: 14,
              ),
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
      shadowColor: Colors.black.withOpacity(0.1),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            textColor:theme.textTheme.bodyLarge?.color,
            onTap: () {
              // TODO: Navigate to Edit Profile
            },
          ),
          _buildMenuTile(
            icon: Icons.list_alt_outlined,
            title: 'My Listings',
            textColor: theme.textTheme.bodyLarge?.color,
            onTap: () {
              // TODO: Navigate to My Listings
            },
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            textColor: theme.textTheme.bodyLarge?.color,
            onTap: () {
              // TODO: Navigate to Payment Methods
            },
          ),
          _buildMenuTile(
            icon: Icons.favorite_border_rounded,
            title: 'My Wishlist',
            textColor: theme.textTheme.bodyLarge?.color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: 'Help and Support',
            textColor: theme.textTheme.bodyLarge?.color,
            onTap: () {
              // TODO: Navigate to Help & Support
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon, 
        color: textColor ?? theme.iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: textColor == null || textColor != theme.colorScheme.error
          ? Icon(
              Icons.arrow_forward_ios, 
              size: 16, 
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            )
          : null,
      onTap: onTap,
    );
  }
  
  Widget _buildErrorView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded, 
              size: 60, 
              color: isDark ? Colors.grey[400] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Could not load profile.", 
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection and try again.",
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
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