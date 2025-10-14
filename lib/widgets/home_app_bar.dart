import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:provider/provider.dart';

// This enum must be kept in sync with the one in HomePage
enum MenuItem { item1, item2, item3, item4, item5, item6, item7, item8, item9 }

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int notificationCount;
  final bool showMenuBadge;
  final AppUser? currentUser;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final ValueChanged<MenuItem> onMenuSelected;

  const HomeAppBar({
    super.key,
    required this.notificationCount,
    required this.showMenuBadge,
    this.currentUser,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.onMenuSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Row(
        children: [
          const SizedBox(width: 1),
          // App name with modern styling
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: const Text(
              'RentHouse',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark 
          ? theme.scaffoldBackgroundColor 
          : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onProfileTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceVariant,
              backgroundImage: currentUser?.pictureUrl != null &&
                      currentUser!.pictureUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(
                      "${AppConfig.imageBaseUrl}${currentUser!.pictureUrl}",
                    )
                  : null,
              child: (currentUser?.pictureUrl == null ||
                      currentUser!.pictureUrl!.isEmpty)
                  ? Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ),
      actions: [
        // Modern notification button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onNotificationTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: _buildIconWithBadge(
                  icon: BootstrapIcons.bell_fill,
                  count: notificationCount,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),
        // Modern menu button
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<MenuItem>(
            onSelected: onMenuSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 8),
            elevation: 8,
            icon: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildIconWithBadge(
                  icon: Icons.grid_view_rounded,
                  showDot: showMenuBadge,
                  theme: theme,
                ),
              ),
            ),
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item1,
                icon: Icons.dashboard_rounded,
                text: 'Dashboard',
              ),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item2,
                icon: Icons.inventory_2_rounded,
                text: 'My Listed Items',
              ),
              const PopupMenuDivider(height: 8),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item3,
                icon: Icons.local_offer_rounded,
                text: 'Offers',
                showBadge: Provider.of<AppStateManager>(context, listen: false).hasUnreadOffers,
              ),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item4,
                icon: Icons.account_balance_wallet_rounded,
                text: 'Wallet',
                showBadge: Provider.of<AppStateManager>(context, listen: false).hasUnreadPayments,
              ),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item5,
                icon: Icons.receipt_long_rounded,
                text: 'Payment History',
              ),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item6,
                icon: Icons.history_rounded,
                text: 'Rental History',
              ),
              const PopupMenuDivider(height: 8),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item7,
                icon: Icons.favorite_rounded,
                text: 'Wishlist',
              ),
              _buildPopupMenuItem(
                context: context,
                value: MenuItem.item8,
                icon: Icons.settings_rounded,
                text: 'Settings',
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<MenuItem> _buildPopupMenuItem({
    required BuildContext context,
    required MenuItem value,
    required IconData icon,
    required String text,
    bool showBadge = false,
  }) {
    final theme = Theme.of(context);
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          if (showBadge)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    int count = 0,
    bool showDot = false,
    required ThemeData theme,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          icon,
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
        if (count > 0 || showDot)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: count > 0 
                  ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                  : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: count > 0
                  ? Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}