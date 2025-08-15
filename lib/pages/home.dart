import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import the new package
import '../models/category_model.dart'; 
import '../models/product_model.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../environment/env.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables
  List<Product> products = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;

  // Use the API base URL from your environment configuration
  final String _apiBaseUrl = AppConfig.ApibaseUrl; 

  @override
  void initState() {
    super.initState();
    loadData(); // Initial load from cache or network
  }

  /// Fetches data, allowing for a forced refresh to bypass the cache.
  Future<void> loadData({bool forceRefresh = false}) async {
    // Only show the main loading spinner on the very first load.
    if (products.isEmpty && categories.isEmpty) {
        setState(() {
          isLoading = true;
        });
    }

    final productService = ProductService();
    final categoryService = CategoryService();

    try {
      // Fetch both data sets, passing the forceRefresh flag.
      final results = await Future.wait([
        productService.fetchProducts(forceRefresh: forceRefresh),
        categoryService.getCategories(forceRefresh: forceRefresh),
      ]);

      if (mounted) {
        setState(() {
          products = results[0] as List<Product>;
          categories = results[1] as List<CategoryModel>;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data from the server.')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // When the user pulls to refresh, call loadData with forceRefresh = true.
              onRefresh: () => loadData(forceRefresh: true),
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _SearchBar(),
                        const SizedBox(height: 20),
                        _buildCategoriesSection(),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  _buildProductsList(),
                ],
              ),
            ),
    );
  }

  /// Builds the horizontal list of categories.
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 90, // Height for the category items with icons
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 80, // Fixed width for each category item
                margin: const EdgeInsets.only(right: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.network(
                        "$_apiBaseUrl${category.icon}", // Use icon URL from the model
                        placeholderBuilder: (context) => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        colorFilter: const ColorFilter.mode(
                            Colors.amber, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// Builds the vertical list of products as a SliverList.
  Widget _buildProductsList() {
    return products.isEmpty
        ? const SliverFillRemaining(
            child: Center(
              child: Text('No products found.'),
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildProductCard(products[index]);
              },
              childCount: products.length,
            ),
          );
  }

  /// Builds a card widget for a single product.
  Widget _buildProductCard(Product product) {
    final String imageUrl = "$_apiBaseUrl${product.image}";
    String formattedDate = '';
    try {
      final DateTime parsedDate = DateTime.parse(product.createdAt);
      formattedDate = DateFormat.yMMMd().format(parsedDate);
    } catch (e) {
      formattedDate = product.createdAt; 
      print("Error parsing date: $e");
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            // --- REPLACED Image.network with CachedNetworkImage ---
            child: CachedNetworkImage(
              imageUrl: "https://p2prental.runasp.net${product.image}",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                width: 100,
                height: 100,
                child: Icon(Icons.broken_image, color: Colors.grey[400])
              ),
            ),
            // ---------------------------------------------------
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'By: ${product.ownerName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.availability ? 'Available' : 'Not Available',
                        style: TextStyle(
                          fontSize: 12, 
                          color: product.availability ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        product.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}/day',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The search bar widget.
  Container _SearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withOpacity(0.1),
          )
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search Products...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }

  /// The app bar widget.
  AppBar appBar() {
    return AppBar(
      title: const Text(
        'Marketplace',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffF7F8F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgPicture.asset(
            'assets/icons/arrow-left.svg', // Ensure this asset exists
            height: 20,
            width: 20,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(10),
            alignment: Alignment.center,
            width: 37,
            decoration: BoxDecoration(
              color: const Color(0xffF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/icons/three-dots.svg', // Ensure this asset exists
              height: 5,
              width: 5,
            ),
          ),
        ),
      ],
    );
  }
}
