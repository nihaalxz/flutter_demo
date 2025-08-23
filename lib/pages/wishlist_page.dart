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

  Future<void> _removeItem(int itemId, int index, List<WishlistItemModel> items) async {
    final removedItem = items.removeAt(index); // Optimistic UI
    setState(() {});

    try {
      await _wishlistService.removeFromWishlist(itemId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from wishlist."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Rollback if API fails
      setState(() {
        items.insert(index, removedItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist"),
        backgroundColor: const Color.fromARGB(255, 251, 251, 251),
      ),
      body: FutureBuilder<List<WishlistItemModel>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 9,
              itemBuilder: (_, __) => _buildShimmerCard(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshWishlist,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final wishlistItems = snapshot.data ?? [];

          if (wishlistItems.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refreshWishlist(),
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      "Your wishlist is empty.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshWishlist(),
            child: ListView.builder(
              itemCount: wishlistItems.length,
              itemBuilder: (context, index) {
                final item = wishlistItems[index];
                return _buildWishlistItemCard(item, index, wishlistItems);
              },
            ),
          );
        },
      ),
    );
  }

  // --- Wishlist Item Card ---
  Widget _buildWishlistItemCard(WishlistItemModel item, int index, List<WishlistItemModel> items) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: item.itemId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: "${AppConfig.imageBaseUrl}${item.image}",
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(width: 80, height: 80, color: Colors.white),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}/day',
                      style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.availability ? 'Available' : 'Not Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.availability ? Colors.blueAccent : const Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Remove from wishlist",
                onPressed: () => _removeItem(item.itemId, index, items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Shimmer Loader ---
  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(width: 80, height: 80, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(height: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(height: 14, width: 100, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
