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
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.searchQuery}"'),
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(productId: product.id),
                    ),
                  );
                },
                child: ProductCard(
                  product: product,
                  // Wishlist state on this page would require more complex state management
                  // For now, we assume it's not needed or handled differently.
                  onWishlistChanged: (id, isWishlisted) {},
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// A shimmer loading placeholder.
  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 124, // Matches the ProductCard height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  /// The view to show when no results are found.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Results Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// The view to show when an error occurs.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Something went wrong while searching.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _fetchResults();
                });
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
