import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../routes/app_routes.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';
import '../environment/env.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(int productId, bool isWishlisted) onWishlistChanged;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    required this.onWishlistChanged,
    this.compact = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  final WishlistService _wishlistService = WishlistService();

  bool get _isWishlisted => widget.product.isWishlisted;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  Future<void> _toggleWishlist() async {
    final originalStatus = _isWishlisted;

    // Optimistic UI update - immediately update the visual state
    widget.onWishlistChanged(widget.product.id, !originalStatus);
    
    // Play animation
    _animationController.forward().then((_) => _animationController.reverse());

    try {
      if (originalStatus) {
        await _wishlistService.removeFromWishlist(widget.product.id);
      } else {
        await _wishlistService.addToWishlist(widget.product.id);
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        widget.onWishlistChanged(widget.product.id, originalStatus);
        _showSnackBar(e.toString().replaceAll("Exception: ", ""), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToDetails() {
    AppRoutes.push(
      context,
      AppRoutes.productDetails,
      arguments: {
        'productId': widget.product.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final relativeDate = _getRelativeDate(widget.product.createdAt);

    // Use theme colors directly
    final cardColor = theme.cardColor;
    final titleColor = theme.colorScheme.onBackground;
    final subtitleColor = theme.colorScheme.onBackground.withOpacity(0.85);
    final mutedColor = theme.colorScheme.onBackground.withOpacity(0.6);
    final shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3);
    final surfaceVariant = isDark ? Colors.grey[800] : Colors.grey[200];

    // Compact mode adjustments
    final imageHeight = widget.compact ? 110.0 : 170.0;
    final titleSize = widget.compact ? 14.0 : 17.0;
    final priceSize = widget.compact ? 14.0 : 17.0;
    final padding = widget.compact ? 8.0 : 12.0;

    return Container(
      margin: widget.compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          onTap: _navigateToDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGE WITH HEART (HERO)
              Stack(
                children: [
                  Hero(
                    tag: 'product_image_${widget.product.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: "${AppConfig.imageBaseUrl}${widget.product.image}",
                        width: double.infinity,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: imageHeight,
                          color: surfaceVariant,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: imageHeight,
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

                  // Heart button with optimistic UI
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleWishlist,
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
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Icon(
                              _isWishlisted ? Icons.favorite : Icons.favorite_border,
                              color: _isWishlisted ? Colors.redAccent : Colors.white,
                              size: 16,
                            ),
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
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TITLE
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: widget.compact ? 4 : 6),

                      // PRICE - Uses theme's primary color for better integration
                      Text(
                        '₹${widget.product.price.toStringAsFixed(0)}/day',
                        style: TextStyle(
                          fontSize: priceSize, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.green, // Use theme primary color
                        ),
                      ),
                      SizedBox(height: widget.compact ? 6 : 8),

                      // OWNER INFO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: widget.compact ? 12 : 16,
                            backgroundColor: surfaceVariant,
                            backgroundImage: (widget.product.ownerProfileImage != null &&
                                    widget.product.ownerProfileImage!.isNotEmpty)
                                ? CachedNetworkImageProvider("${AppConfig.imageBaseUrl}${widget.product.ownerProfileImage}")
                                : null,
                            child: (widget.product.ownerProfileImage == null || widget.product.ownerProfileImage!.isEmpty)
                                ? Icon(
                                    Icons.person, 
                                    size: widget.compact ? 12 : 16, 
                                    color: mutedColor,
                                  )
                                : null,
                          ),
                          SizedBox(width: widget.compact ? 8 : 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Owner name
                                Text(
                                  widget.product.ownerName,
                                  style: TextStyle(
                                    fontSize: widget.compact ? 12 : 14,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: widget.compact ? 2 : 3),
                                // Location
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on, 
                                      size: widget.compact ? 12 : 14,
                                      color: mutedColor,
                                    ),
                                    SizedBox(width: widget.compact ? 4 : 5),
                                    Expanded(
                                      child: Text(
                                        widget.product.locationName,
                                        style: TextStyle(
                                          fontSize: widget.compact ? 11 : 13,
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

                      SizedBox(height: widget.compact ? 4 : 6),

                      // DATE
                      Text(
                        relativeDate,
                        style: TextStyle(
                          fontSize: widget.compact ? 11 : 13,
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
}