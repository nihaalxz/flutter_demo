import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/pages/Auth/login_page.dart';
import 'package:myfirstflutterapp/pages/notification_page.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/category_service.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/services/wishlist_service.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/models/wishlist_item_model.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> _products = [];
  final AuthService _authService = AuthService();
  AppUser? _currentUser;

  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = loadData();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<Map<String, dynamic>> loadData({bool forceRefresh = false}) async {
    final productService = ProductService();
    final categoryService = CategoryService();
    final wishlistService = WishlistService();

    final results = await Future.wait([
      productService.fetchProducts(forceRefresh: forceRefresh),
      categoryService.getCategories(forceRefresh: forceRefresh),
      wishlistService.getWishlist(),
    ]);

    final fetchedProducts = results[0] as List<Product>;
    final fetchedCategories = results[1] as List<CategoryModel>;
    final wishlistItems = results[2] as List<WishlistItemModel>;

    final wishlistedIds = wishlistItems.map((item) => item.itemId).toSet();

    for (var product in fetchedProducts) {
      product.isWishlisted = wishlistedIds.contains(product.id);
    }

    _products = fetchedProducts;

    return {
      'products': fetchedProducts,
      'categories': fetchedCategories,
    };
  }

  void _onWishlistChanged(int productId, bool isWishlisted) {
    setState(() {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index].isWishlisted = isWishlisted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            /// 🔥 Shimmer while loading
            return _buildShimmerUI();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Failed to load data."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _dataFuture = loadData(forceRefresh: true);
                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!['products'] as List<Product>;
          final categories = snapshot.data!['categories'] as List<CategoryModel>;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = loadData(forceRefresh: true);
              });
            },
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    _SearchBar(),
                    const SizedBox(height: 20),
                    _buildCategoriesSection(categories),
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
                  ]),
                ),
                _buildProductsList(products),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔥 Shimmer Skeleton
  Widget _buildShimmerUI() {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            _SearchBar(),
            const SizedBox(height: 20),
            _shimmerCategories(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                'All Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
          ]),
        ),
        _shimmerProducts(),
      ],
    );
  }

  /// 🔥 Shimmer for categories
  Widget _shimmerCategories() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 10),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 40,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔥 Shimmer for products
  Widget _shimmerProducts() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        childCount: 6,
      ),
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories) {
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
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 80,
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
                        "${AppConfig.ApibaseUrl}${category.icon}",
                        placeholderBuilder: (context) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        colorFilter: const ColorFilter.mode(
                          Colors.amber,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildProductsList(List<Product> products) {
    return products.isEmpty
        ? const SliverFillRemaining(
            child: Center(child: Text('No products found.')),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsPage(productId: product.id),
                      ),
                    );
                  },
                  child: ProductCard(
                    product: product,
                    onWishlistChanged: _onWishlistChanged,
                  ),
                );
              },
              childCount: products.length,
            ),
          );
  }

  Container _SearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(blurRadius: 15, color: Colors.black.withOpacity(0.1)),
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

  AppBar appBar() {
    return AppBar(
      title: const Text(
        'Circlo',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0.0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage: _currentUser?.pictureUrl != null &&
                  _currentUser!.pictureUrl!.isNotEmpty
              ? CachedNetworkImageProvider(
                  "${AppConfig.imageBaseUrl}${_currentUser!.pictureUrl}",
                )
              : null,
          child: _currentUser?.pictureUrl == null ||
                  _currentUser!.pictureUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(BootstrapIcons.bell_fill, color: Colors.black),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }
}
