import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:shimmer/shimmer.dart';

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

  Future<void> _removeItem(
      int itemId, int index, List<WishlistItemModel> items) async {
    // Optimistic UI: Remove the item from the list immediately.
    final removedItem = items.removeAt(index);
    setState(() {});

    try {
      await _wishlistService.removeFromWishlist(itemId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Removed from wishlist."),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      // If the API call fails, add the item back to the list and show an error.
      setState(() {
        items.insert(index, removedItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => _buildShimmerCard(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error, isCupertino: isCupertino);
        }

        final wishlistItems = snapshot.data ?? [];

        if (wishlistItems.isEmpty) {
          return _buildEmptyState(isCupertino: isCupertino);
        }

        return ListView.builder(
          itemCount: wishlistItems.length,
          itemBuilder: (context, index) {
            final item = wishlistItems[index];
            // On iOS, use a swipe-to-delete pattern
            if (isCupertino) {
              return Dismissible(
                key: Key(item.itemId.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeItem(item.itemId, index, wishlistItems);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(CupertinoIcons.delete, color: Colors.white),
                ),
                child: _buildWishlistItemCard(item),
              );
            } else {
              // On Android, use a card with a visible delete button
              return _buildWishlistItemCard(item,
                  index: index, items: wishlistItems);
            }
          },
        );
      },
    );
  }

  // --- UI Components ---

  Widget _buildWishlistItemCard(WishlistItemModel item,
      {int? index, List<WishlistItemModel>? items}) {
    final theme = Theme.of(context);
    final isCupertino = Platform.isIOS;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: item.itemId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isCupertino
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  )
                ],
          border: isCupertino
              ? Border(bottom: BorderSide(color: Colors.grey.shade300))
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: "${AppConfig.imageBaseUrl}${item.image}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Icon(Icons.broken_image, size: 80, color: theme.disabledColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}/day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.availability ? 'Available' : 'Not Available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.availability
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  Text(item.locationName ?? 'Unknown Location'),
                ],
              ),
            ),
            // Only show the delete button on Android
            if (!isCupertino && items != null && index != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                tooltip: "Remove from wishlist",
                onPressed: () => _removeItem(item.itemId, index, items),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                // ✅ FIX: Moved color inside decoration
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      // ✅ FIX: Moved color inside decoration
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      // ✅ FIX: Moved color inside decoration
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Error: ${error}", textAlign: TextAlign.center),
          const SizedBox(height: 16),
          isCupertino
              ? CupertinoButton.filled(onPressed: _refreshWishlist, child: const Text("Retry"))
              : ElevatedButton(onPressed: _refreshWishlist, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isCupertino}) {
    final emptyView = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(
            isCupertino ? CupertinoIcons.heart : Icons.favorite_border,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "Your wishlist is empty.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
           const SizedBox(height: 8),
           Text(
            "Tap the heart on an item to save it.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
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
         child: Stack(children: [ListView(), emptyView]), // ListView enables refresh
       );
    }
  }
}
