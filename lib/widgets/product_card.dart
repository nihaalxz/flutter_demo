import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- Assumed Imports ---
import '../models/product_model.dart';
import '../services/wishlist_service.dart';
import '../environment/env.dart';
import '../pages/product/product_details_page.dart';

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

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final WishlistService _wishlistService = WishlistService();

  // The local state now directly reflects the product model's property
  bool get _isWishlisted => widget.product.isWishlisted;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Toggles the wishlist status using an optimistic UI update.
  Future<void> _toggleWishlist() async {
    // 1. Store the original status in case we need to revert.
    final originalStatus = _isWishlisted;

    // 2. Update the UI immediately, assuming the request will succeed.
    widget.onWishlistChanged(widget.product.id, !originalStatus);

    // Trigger animation
    _animationController.forward().then((_) => _animationController.reverse());

    try {
      // 3. Perform the network request silently in the background.
      if (originalStatus) {
        // If it WAS wishlisted, the new optimistic state is 'false', so remove it.
        await _wishlistService.removeFromWishlist(widget.product.id);
      } else {
        // If it was NOT wishlisted, the new optimistic state is 'true', so add it.
        await _wishlistService.addToWishlist(widget.product.id);
      }
    } catch (e) {
      // 4. If the network call fails, show an error and revert the UI.
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), isError: true);
      
      if (mounted) {
        // Revert the UI by notifying the parent of the original status.
        widget.onWishlistChanged(widget.product.id, originalStatus);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(productId: widget.product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat.yMMMd().format(widget.product.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _navigateToDetails, // Now navigates to details page
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'product_image_${widget.product.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: "${AppConfig.imageBaseUrl}${widget.product.image}",
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(Icons.broken_image, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: _toggleWishlist,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Icon(
                                    _isWishlisted
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isWishlisted
                                        ? Colors.redAccent
                                        : Colors.white,
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // ✅ --- UPDATED OWNER INFO ROW ---
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (widget.product.ownerProfileImage != null && widget.product.ownerProfileImage!.isNotEmpty)
                                ? CachedNetworkImageProvider("${AppConfig.imageBaseUrl}${widget.product.ownerProfileImage}")
                                : null,
                            child: (widget.product.ownerProfileImage == null || widget.product.ownerProfileImage!.isEmpty)
                                ? Icon(Icons.person, size: 18, color: Colors.grey.shade600)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.product.ownerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.product.availability ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.product.availability ? 'Available' : 'Not Available',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.product.availability ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ---------------------------------
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.product.locationName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.product.price.toStringAsFixed(2)}/day',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}