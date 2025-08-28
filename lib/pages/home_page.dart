import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/pages/gen/settings_page.dart';
import 'package:myfirstflutterapp/pages/product/my_items_page.dart';
import 'package:myfirstflutterapp/pages/notification_page.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';
import 'package:myfirstflutterapp/pages/Auth/profile_page.dart';
import 'package:myfirstflutterapp/pages/search_screen.dart';
import 'package:myfirstflutterapp/pages/wallet_page.dart';
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
import 'package:myfirstflutterapp/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum MenuItem { item1, item2, item3, item4, item5, item6, item7 }

class _HomePageState extends State<HomePage> {
  List<Product> _products = [];
  List<Product> _nearbyProducts = [];
  List<Product> _otherProducts = [];
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  String _currentCity = "Loading...";
  List<Product> _filteredProducts = [];
  bool _locationPermissionDenied = false;

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

    try {
      // Check location permission
      final status = await Permission.location.status;
      if (!status.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          setState(() {
            _locationPermissionDenied = true;
            _currentCity = "Location access denied";
          });
          _nearbyProducts = _products;
          _otherProducts = [];
          return {
            'products': _filteredProducts,
            'categories': fetchedCategories,
          };
        }
      }

      final position = await LocationService.getCurrentPosition();
      final city = await LocationService.getCityFromCoordinates(position);

      setState(() {
        _currentCity = city;
        _locationPermissionDenied = false;
      });

      _nearbyProducts = _products
          .where(
            (p) => p.locationName.toLowerCase().contains(city.toLowerCase()),
          )
          .toList();

      _otherProducts = _products
          .where(
            (p) => !p.locationName.toLowerCase().contains(city.toLowerCase()),
          )
          .toList();

      // fallback: if no nearby items, just show all in "Other"
      if (_nearbyProducts.isEmpty) {
        _nearbyProducts = [];
        _otherProducts = _products;
      }
    } catch (e) {
      setState(() {
        _currentCity = "Unable to determine location";
      });
      _nearbyProducts = _products;
      _otherProducts = [];
    }

    return {'products': _filteredProducts, 'categories': fetchedCategories};
  }

  void _onWishlistChanged(int productId, bool isWishlisted) {
    setState(() {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index].isWishlisted = isWishlisted;
      }
    });
  }

  Future<void> _retryLocation() async {
    try {
      final status = await Permission.location.status;
      if (!status.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to show nearby items',
              ),
            ),
          );
          return;
        }
      }

      final position = await LocationService.getCurrentPosition();
      final city = await LocationService.getCityFromCoordinates(position);

      setState(() {
        _currentCity = city;
        _locationPermissionDenied = false;
      });

      _nearbyProducts = _products
          .where(
            (p) => p.locationName.toLowerCase().contains(city.toLowerCase()),
          )
          .toList();

      _otherProducts = _products
          .where(
            (p) => !p.locationName.toLowerCase().contains(city.toLowerCase()),
          )
          .toList();

      if (_nearbyProducts.isEmpty) {
        _nearbyProducts = [];
        _otherProducts = _products;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = loadData(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: _buildAppBar(appState.unreadNotificationCount),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerUI();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error);
              }

              final categories =
                  snapshot.data!['categories'] as List<CategoryModel>;

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSearchBar(context),
                        const SizedBox(height: 20),
                        _buildCategoriesSection(categories),
                        const SizedBox(height: 20),
                        _buildLocationSection(),
                        const SizedBox(height: 10),
                      ]),
                    ),
                    if (_nearbyProducts.isNotEmpty)
                      _buildProductsList(_nearbyProducts),
                    if (_otherProducts.isNotEmpty) _buildOtherProductsSection(),
                    if (_otherProducts.isNotEmpty)
                      _buildProductsList(_otherProducts),
                    if (_products.isEmpty) _buildEmptyState(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Text(
                "Items near ${_currentCity}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.location_pin),
              if (_locationPermissionDenied)
                IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.orange),
                  onPressed: _retryLocation,
                  tooltip: 'Location access denied. Tap to retry.',
                ),
            ],
          ),
          if (_locationPermissionDenied)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                'Location access is needed to show nearby items',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Failed to load data."),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refreshData, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products available'),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherProductsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Divider(thickness: 1),
          Padding(
            padding: EdgeInsets.only(left: 20, top: 10),
            child: Text(
              "Other items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerUI() {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            _buildSearchBar(context),
            const SizedBox(height: 20),
            _buildShimmerCategories(),
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
        _buildShimmerProducts(),
      ],
    );
  }

  Widget _buildShimmerCategories() {
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

  Widget _buildShimmerProducts() {
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
              return CategoryItem(category: category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return products.isEmpty
        ? const SliverToBoxAdapter(child: SizedBox.shrink())
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

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(blurRadius: 15, color: Colors.black.withOpacity(0.1)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        },
        child: IgnorePointer(
          child: TextField(
            enabled: false,
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
        ),
      ),
    );
  }

  AppBar _buildAppBar(int notificationCount) {
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
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
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
          onSelected: (value) => _handleMenuSelection(value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: MenuItem.item1,
              child: Row(
                children: [
                  Icon(Icons.speed, color: Theme.of(context).iconTheme.color),
                  const SizedBox(width: 4),
                  const Text('Dashboard', style: TextStyle(fontSize: 16)),
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
                  const SizedBox(width: 4),
                  const Text('My Listed Items', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item3,
              child: Row(
                children: [
                  Icon(Icons.wallet, color: Theme.of(context).iconTheme.color),
                  const SizedBox(width: 4),
                  const Text('Wallet', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuItem.item4,
              child: Row(
                children: [
                  Icon(Icons.history, color: Theme.of(context).iconTheme.color),
                  const SizedBox(width: 4),
                  const Text('Payment History', style: TextStyle(fontSize: 16)),
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
                  const SizedBox(width: 4),
                  const Text('Wishlist', style: TextStyle(fontSize: 16)),
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
                  const SizedBox(width: 4),
                  const Text('Settings', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuSelection(MenuItem value) {
    switch (value) {
      case MenuItem.item1:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Navigate to Dashboard')));
        break;
      case MenuItem.item2:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const MyItemsPage()));
        break;
      case MenuItem.item3:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const WalletPage()));
        break;
      case MenuItem.item4:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to Payment History')),
        );
        break;
      case MenuItem.item5:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const WishlistPage()));
        break;
      case MenuItem.item6:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
      case MenuItem.item7:
        break;
    }
  }

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

class CategoryItem extends StatelessWidget {
  final CategoryModel category;

  const CategoryItem({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
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
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                "${AppConfig.imageBaseUrl}${category.iconImage}",
              ),
              backgroundColor: Colors.transparent,
              radius: 55,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
