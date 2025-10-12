import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
// --- Assumed Imports ---
import 'package:myfirstflutterapp/services/search_service.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/widgets/product_card.dart';
import 'product_details_page.dart';

/// A page to display the results of a product search.
class ProductResultsPage extends StatefulWidget {
  final String searchQuery;
  final String? location;
  final int? categoryId;

  const ProductResultsPage({
    super.key,
    required this.searchQuery,
    this.location,
    this.categoryId,
  });

  @override
  State<ProductResultsPage> createState() => _ProductResultsPageState();
}

class _ProductResultsPageState extends State<ProductResultsPage> {
  final SearchService _searchService = SearchService();
  late Future<List<Product>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  void _fetchResults() {
    _resultsFuture = _searchService.searchItems(
      query: widget.searchQuery,
      location: widget.location,
      categoryId: widget.categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.searchQuery}"'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: FutureBuilder<List<Product>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _fetchResults();
              });
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70, // Match homepage aspect ratio
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  compact: true, // Use compact mode for grid layout
                  onWishlistChanged: (id, isWishlisted) {
                    setState(() {
                      // Update the product's wishlist status
                      product.isWishlisted = isWishlisted;
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Updated shimmer loader for grid layout
  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6, // Show 6 shimmer items (3 rows)
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 110, // Match compact ProductCard image height
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                // Content placeholder
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Price placeholder
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Owner info placeholder
                      Row(
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 10,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 10,
                                  width: 80,
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
                      const SizedBox(height: 4),
                      // Date placeholder
                      Container(
                        height: 10,
                        width: 50,
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
      },
    );
  }

  /// The view to show when no results are found.
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off, 
              size: 80, 
              color: theme.colorScheme.onBackground.withOpacity(0.5)
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search or filters.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to Search'),
            ),
          ],
        ),
      ),
    );
  }

  /// The view to show when an error occurs.
  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline, 
              size: 64, 
              color: theme.colorScheme.error
            ),
            const SizedBox(height: 24),
            Text(
              "Search Failed",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Something went wrong while searching.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _fetchResults();
                    });
                  },
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}