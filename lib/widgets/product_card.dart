import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- Assumed Imports ---
import '../models/product_model.dart';
import '../services/wishlist_service.dart';
import '../environment/env.dart'; // For the base URL

class ProductCard extends StatefulWidget {
  final Product product;
  // A callback to notify the parent when the wishlist state changes
  final Function(int productId, bool isWishlisted) onWishlistChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.onWishlistChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLoading = false;
  final WishlistService _wishlistService = WishlistService();

  // The local state now directly reflects the product model's property
  bool get _isWishlisted => widget.product.isWishlisted;

  /// Toggles the wishlist status for the current product.
  Future<void> _toggleWishlist() async {
    if (_isLoading) return; // Prevent multiple taps

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isWishlisted) {
        // If it's already wishlisted, remove it
        await _wishlistService.removeFromWishlist(widget.product.id);
        widget.onWishlistChanged(widget.product.id, false); // Notify parent
        _showSnackBar("Removed from your wishlist.", isError: false);
      } else {
        // If it's not wishlisted, add it
        await _wishlistService.addToWishlist(widget.product.id);
        widget.onWishlistChanged(widget.product.id, true); // Notify parent
        _showSnackBar("Added to your wishlist!", isError: false);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     Theme.of(context);
    // ✅ FIX: Safely parse the date string to prevent crashes.
    final String formattedDate = DateFormat.yMMMd().format(widget.product.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
           color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: "${AppConfig.imageBaseUrl}${widget.product.image}",
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => SizedBox(
                    width: 100,
                    height: 100,
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: _toggleWishlist,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isWishlisted
                                ? Colors.redAccent
                                : Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            // ✅ FIX: Removed the fixed-height SizedBox to prevent vertical overflow.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'By: ${widget.product.ownerName}',
                        style:
                            TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color,),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.product.availability
                          ? 'Available'
                          : 'Not Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.product.availability
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // ✅ FIX: Use Expanded to prevent horizontal overflow with long text.
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color,),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.product.locationName,
                        style:
                            TextStyle(fontSize: 12,color: Theme.of(context).textTheme.bodyMedium?.color,),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style:
                          TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color,),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.product.price.toStringAsFixed(2)}/day',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
