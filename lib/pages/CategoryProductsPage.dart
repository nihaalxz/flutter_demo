import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/widgets/product_card.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  final List<Product> _products = [];
  DateTime? _nextCursor;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialProducts() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
    });
    try {
      final result = await _productService.fetchProductsByCategory(widget.categoryId);
      if (mounted) {
        setState(() {
          _products.clear();
          _products.addAll(result.items);
          _nextCursor = result.nextCursor;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (_isLoadingMore || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final result = await _productService.fetchProductsByCategory(
        widget.categoryId,
        cursor: _nextCursor,
      );
      if (mounted) {
        setState(() {
          _products.addAll(result.items);
          _nextCursor = result.nextCursor;
        });
      }
    } catch (e) {
      // Handle error, maybe show a snackbar
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }
  
  // --- Platform-Specific Scaffolding ---

  Widget _buildMaterialPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.categoryName),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      child: _buildBody(isCupertino: true),
    );
  }

  // --- Updated Body Logic for Grid View ---
  
  Widget _buildBody({bool isCupertino = false}) {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading products',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInitialProducts,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found in ${widget.categoryName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new items',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _fetchInitialProducts,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Grid for products
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70, // Match homepage aspect ratio
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index];
                  return ProductCard(
                    product: product,
                    compact: true, // Use compact mode for grid layout
                    onWishlistChanged: (id, isWishlisted) {
                      setState(() => product.isWishlisted = isWishlisted);
                    },
                  );
                },
                childCount: _products.length,
              ),
            ),
          ),
          
          // Loading indicator at the bottom (only when loading more)
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            ),
          
          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}