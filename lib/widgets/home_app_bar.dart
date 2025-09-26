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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Circlo',
        style: TextStyle(
          color: theme.textTheme.titleLarge?.color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0.0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onProfileTap,
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: currentUser?.pictureUrl != null &&
                    currentUser!.pictureUrl!.isNotEmpty
                ? CachedNetworkImageProvider(
                    "${AppConfig.imageBaseUrl}${currentUser!.pictureUrl}",
                  )
                : null,
            child: (currentUser?.pictureUrl == null ||
                    currentUser!.pictureUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: _buildIconWithBadge(
            icon: BootstrapIcons.bell_fill,
            count: notificationCount,
            theme: theme,
          ),
          onPressed: onNotificationTap,
          tooltip: 'Notifications',
        ),
        PopupMenuButton<MenuItem>(
          onSelected: onMenuSelected,
          icon: _buildIconWithBadge(
            icon: Icons.more_vert_rounded,
            showDot: showMenuBadge, // Use a simple dot for the menu
            theme: theme,
          ),
          itemBuilder: (context) => [
            _buildPopupMenuItem(
              context: context,
              value: MenuItem.item1,
              icon: Icons.speed,
              text: 'Dashboard',
            ),
            _buildPopupMenuItem(
              context: context,
              value: MenuItem.item2,
              icon: Icons.shopping_bag,
              text: 'My Listed Items',
            ),
             _buildPopupMenuItem(
              context: context,
              value: MenuItem.item3,
              icon: Icons.local_offer,
              text: 'Offers',
              showBadge: Provider.of<AppStateManager>(context, listen: false).hasUnreadOffers,
            ),
            _buildPopupMenuItem(
              context: context,
              value: MenuItem.item4,
              icon: Icons.wallet,
              text: 'Wallet',
              showBadge: Provider.of<AppStateManager>(context, listen: false).hasUnreadPayments,
            ),
            _buildPopupMenuItem(
              context: context,
              value: MenuItem.item5,
              icon: Icons.history,
              text: 'Payment History',
            ),
             _buildPopupMenuItem(
              context: context,
              value: MenuItem.item6,
              icon: Icons.history_toggle_off,
              text: 'Rental History',
            ),
            _buildPopupMenuItem(
              context: context,
              value: MenuItem.item7,
              icon: Icons.favorite,
              text: 'Wishlist',
            ),
            _buildPopupMenuItem(
              context: context,
              value: MenuItem.item8,
              icon: Icons.settings,
              text: 'Settings',
            ),
          ],
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
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          if (showBadge)
             Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
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
        Icon(icon, color: theme.iconTheme.color),
        if (count > 0 || showDot)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              // If we have a count, show it, otherwise just show the dot.
              child: count > 0
                  ? Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
