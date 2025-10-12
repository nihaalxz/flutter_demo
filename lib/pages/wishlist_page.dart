import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

// --- Assumed Imports ---
import '../models/wishlist_item_model.dart';
import '../services/wishlist_service.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final WishlistService _wishlistService = WishlistService();
  late Future<List<WishlistItemModel>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _wishlistService.getWishlist();
  }

  void _refreshWishlist() {
    setState(() {
      _wishlistFuture = _wishlistService.getWishlist();
    });
  }

  Future<void> _removeItem(int itemId, List<WishlistItemModel> items) async {
    // Find the item to remove
    final itemIndex = items.indexWhere((item) => item.itemId == itemId);
    if (itemIndex == -1) return;

    final removedItem = items[itemIndex];

    // Optimistic UI: Remove the item from the list immediately.
    setState(() {
      items.removeAt(itemIndex);
    });

    try {
      await _wishlistService.removeFromWishlist(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Removed from wishlist"),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // If the API call fails, add the item back to the list and show an error.
      if (mounted) {
        setState(() {
          items.insert(itemIndex, removedItem);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect the platform to build the appropriate UI
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }

  // --- Material Design UI (Android) ---
  Widget _buildMaterialPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist"),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  // --- Cupertino Design UI (iOS) ---
  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Wishlist'),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async => _refreshWishlist(),
          ),
          SliverFillRemaining(
            child: _buildBody(isCupertino: true),
          ),
        ],
      ),
    );
  }

  // --- Shared Body Logic ---
  Widget _buildBody({bool isCupertino = false}) {
    return FutureBuilder<List<WishlistItemModel>>(
      future: _wishlistFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error, isCupertino: isCupertino);
        }

        final wishlistItems = snapshot.data ?? [];

        if (wishlistItems.isEmpty) {
          return _buildEmptyState(isCupertino: isCupertino);
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshWishlist(),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final item = wishlistItems[index];
              return _buildWishlistCard(item, wishlistItems);
            },
          ),
        );
      },
    );
  }

  // --- UI Components ---

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(dateOnly).inDays;
      if (difference <= 7) {
        return '$difference ${difference == 1 ? 'day' : 'days'} ago';
      } else {
        return DateFormat('MMM dd').format(date);
      }
    }
  }

  Widget _buildWishlistCard(WishlistItemModel item, List<WishlistItemModel> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final relativeDate = _getRelativeDate(item.createdAt);

    final cardColor = theme.cardColor;
    final titleColor = theme.colorScheme.onBackground;
    final subtitleColor = theme.colorScheme.onBackground.withOpacity(0.85);
    final mutedColor = theme.colorScheme.onBackground.withOpacity(0.6);
    final shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3);
    final surfaceVariant = isDark ? Colors.grey[800] : Colors.grey[200];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(productId: item.itemId),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGE WITH HEART
              Stack(
                children: [
                  Hero(
                    tag: 'product_image_${item.itemId}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: "${AppConfig.imageBaseUrl}${item.image}",
                        width: double.infinity,
                        height: 110,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 110,
                          color: surfaceVariant,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 110,
                          color: surfaceVariant,
                          child: Icon(
                            Icons.broken_image,
                            size: 28,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Heart button - always filled since it's in wishlist
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _removeItem(item.itemId, items),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // DETAILS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TITLE
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // PRICE
                      Text(
                        '₹${item.price.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // OWNER INFO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: surfaceVariant,
                            backgroundImage: (item.ownerProfileImage != null &&
                                    item.ownerProfileImage!.isNotEmpty)
                                ? CachedNetworkImageProvider("${AppConfig.imageBaseUrl}${item.ownerProfileImage}")
                                : null,
                            child: (item.ownerProfileImage == null || item.ownerProfileImage!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 12,
                                    color: mutedColor,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Owner name
                                Text(
                                  item.ownerName ?? 'Unknown Owner',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Location
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: mutedColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.locationName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mutedColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // DATE
                      Text(
                        relativeDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant,
      highlightColor: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error, {required bool isCupertino}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceAll("Exception: ", ""),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            isCupertino
                ? CupertinoButton.filled(
                    onPressed: _refreshWishlist,
                    child: const Text("Try Again"),
                  )
                : ElevatedButton.icon(
                    onPressed: _refreshWishlist,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try Again"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isCupertino}) {
    final emptyView = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCupertino ? CupertinoIcons.heart : Icons.favorite_border,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              "Your wishlist is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start adding items you love to your wishlist",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the ❤️ icon on any product to save it here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );

    // Make the empty state refreshable
    if (isCupertino) {
      return CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: () async => _refreshWishlist()),
          SliverFillRemaining(child: emptyView),
        ],
      );
    } else {
      return RefreshIndicator(
        onRefresh: () async => _refreshWishlist(),
        child: Stack(
          children: [
            ListView(),
            emptyView,
          ],
        ),
      );
    }
  }
}