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
    // Add a listener to the scroll controller to detect when to load more items.
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
    // Prevent multiple fetches at the same time or if there are no more pages.
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
    // If the user has scrolled to the bottom of the list, fetch more products.
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
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _buildBody(),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.categoryName)),
      child: _buildBody(isCupertino: true),
    );
  }

  // --- Shared Body Logic ---
  
  Widget _buildBody({bool isCupertino = false}) {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No items found in this category.'));
    }

    final listView = ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // If it's the last item and we're loading more, show a spinner.
        if (index == _products.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        
        final product = _products[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(productId: product.id),
              ),
            );
          },
          child: ProductCard(
            product: product,
            onWishlistChanged: (id, isWishlisted) {
              setState(() => product.isWishlisted = isWishlisted);
            },
          ),
        );
      },
    );

    return RefreshIndicator.adaptive(
      onRefresh: _fetchInitialProducts,
      child: listView,
    );
  }
}

