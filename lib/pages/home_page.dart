import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/pages/gen/settings_page.dart';
import 'package:myfirstflutterapp/pages/my_items_page.dart';
import 'package:myfirstflutterapp/pages/notification_page.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';
import 'package:myfirstflutterapp/pages/profile_page.dart';
import 'package:myfirstflutterapp/pages/wishlist_page.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/category_service.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/services/wishlist_service.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/models/wishlist_item_model.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum MenuItem { item1, item2, item3, item4, item5, item6, item7 }

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

    return {'products': fetchedProducts, 'categories': fetchedCategories};
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
    // ✅ Use a Consumer to get the AppStateManager for the notification count
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: appBar(appState.unreadNotificationCount), // Pass the count
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
              final categories =
                  snapshot.data!['categories'] as List<CategoryModel>;

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
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).iconTheme.color,
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
      },
    );
  }

  /// Shimmer Skeleton
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

  /// Shimmer for categories
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
                  Container(height: 10, width: 40, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Shimmer for products
  Widget _shimmerProducts() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
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
      }, childCount: 6),
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
                        "${category.icon}",
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
            delegate: SliverChildBuilderDelegate((context, index) {
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
            }, childCount: products.length),
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
          fillColor: Theme.of(context).cardColor,
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

  /// ✅ AppBar now accepts the notification count
  AppBar appBar(int notificationCount) {
    return AppBar(
      title: Text(
        'Circlo',
        style: TextStyle(
          color: Theme.of(context).appBarTheme.backgroundColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0.0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            50,
          ), // ensures ripple stays circular
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(), // ✅ navigate here
              ),
            );
          },
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage:
                _currentUser?.pictureUrl != null &&
                    _currentUser!.pictureUrl!.isNotEmpty
                ? CachedNetworkImageProvider(
                    "${AppConfig.imageBaseUrl}${_currentUser!.pictureUrl}",
                  )
                : null,
            child:
                _currentUser?.pictureUrl == null ||
                    _currentUser!.pictureUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
        ),
      ),
      actions: [
        IconButton(
          // ✅ Use the badge helper for the notification icon
          icon: _buildIconWithBadge(
            icon: BootstrapIcons.bell_fill,
            count: notificationCount,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
          tooltip: 'Notifications',
        ),
        PopupMenuButton<MenuItem>(
          onSelected: (value) {
            if (value == MenuItem.item1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Dashboard')),
              );
            }
            if (value == MenuItem.item2) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyItemsPage()),
              );
            }
            if (value == MenuItem.item3) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Wallet')),
              );
            }
            if (value == MenuItem.item4) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Payment History')),
              );
            }
            if (value == MenuItem.item5) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            }
            if (value == MenuItem.item6) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }
            if (value == MenuItem.item7) {}
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: MenuItem.item1,
              child: Row(
                children: [
                  Icon(Icons.speed, color: Theme.of(context).iconTheme.color),
                  SizedBox(width: 4),
                  Text('Dashboard', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item2,
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  SizedBox(width: 4),
                  Text('My Listed Items', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item3,
              child: Row(
                children: [
                  Icon(Icons.wallet, color: Theme.of(context).iconTheme.color),
                  SizedBox(width: 4),
                  Text('Wallet', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item4,
              child: Row(
                children: [
                  Icon(Icons.history, color: Theme.of(context).iconTheme.color),
                  SizedBox(width: 4),
                  Text('Payment History', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item5,
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  SizedBox(width: 4),
                  Text('Wishlist', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item6,
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  SizedBox(width: 4),
                  Text('Settings', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ Helper widget to build an icon with a notification badge.
  Widget _buildIconWithBadge({required IconData icon, required int count}) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon, color: Theme.of(context).iconTheme.color),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
