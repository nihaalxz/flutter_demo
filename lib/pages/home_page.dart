import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/pages/myOffers.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// --- Assumed Imports for all models, services, and widgets ---
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/category_service.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/services/wishlist_service.dart';
import 'package:myfirstflutterapp/services/location_service.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/models/wishlist_item_model.dart';
import 'package:myfirstflutterapp/pages/gen/settings_page.dart';
import 'package:myfirstflutterapp/pages/product/my_items_page.dart';
import 'package:myfirstflutterapp/pages/notification_page.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';
import 'package:myfirstflutterapp/pages/auth/profile_page.dart';
import 'package:myfirstflutterapp/pages/wishlist_page.dart';
import 'package:myfirstflutterapp/pages/payments/wallet_page.dart';
import 'package:myfirstflutterapp/pages/payments/payment_history_page.dart';
import 'package:myfirstflutterapp/pages/rental_history_page.dart';

import '../widgets/home_app_bar.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/categories_section.dart';
import '../widgets/product_section.dart';
import '../widgets/location_section.dart';
import '../widgets/error_empty_states.dart';
import '../widgets/shimmer_effects.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final AuthService _authService;
  late Future<Map<String, dynamic>> _dataFuture;
  AppUser? _currentUser;
  bool _isFirstLoad = true;
  List<Product> _products = [];
  Map<int, Product> _productsMap = {};
  bool _isLoadingLocation = true;
  
  // Cached computations for better performance
  List<Product> _nearbyProducts = [];
  List<Product> _otherProducts = [];
  String? _cachedCity;
  DateTime? _lastLocationFetch;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _initializeData();
      _isFirstLoad = false;
    }
  }

  void _initializeData() {
    setState(() {
      _dataFuture = _loadAllData();
    });
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Handle profile loading error silently
      debugPrint('Failed to load user profile: $e');
    }
  }

  Future<String> _getCachedCity() async {
    // Return cached city if it's fresh (less than 5 minutes old)
    if (_cachedCity != null && 
        _lastLocationFetch != null && 
        DateTime.now().difference(_lastLocationFetch!) < const Duration(minutes: 5)) {
      return _cachedCity!;
    }

    String city = "Loading...";
    
    try {
      final position = await LocationService.getCurrentPosition();
      city = await LocationService.getCityFromCoordinates(position);
    } on LocationServiceException catch (e) {
      city = e.type == LocationErrorType.permissionDenied ||
              e.type == LocationErrorType.permissionDeniedForever
          ? "Location access denied"
          : "Unable to determine location";
    } catch (e) {
      city = "Unable to determine location";
    }

    _cachedCity = city;
    _lastLocationFetch = DateTime.now();
    return city;
  }

  Future<Map<String, dynamic>> _loadAllData({bool forceRefresh = false}) async {
    try {
      if (mounted) setState(() => _isLoadingLocation = true);

      final productService = ProductService();
      final categoryService = CategoryService();
      final wishlistService = WishlistService();

      final city = await _getCachedCity();
      final locationDenied = city == "Location access denied";

      final results = await Future.wait([
        productService.fetchProducts(forceRefresh: forceRefresh),
        categoryService.getCategories(forceRefresh: forceRefresh),
        wishlistService.getWishlist(),
      ]);

      final allProducts = results[0] as List<Product>;
      final categories = results[1] as List<CategoryModel>;
      final wishlistItems = results[2] as List<WishlistItemModel>;
      
      // Update products map for O(1) lookups
      _productsMap = {for (var p in allProducts) p.id: p};
      
      // Update wishlist status efficiently
      final wishlistedIds = wishlistItems.map((item) => item.itemId).toSet();
      for (var product in allProducts) {
        product.isWishlisted = wishlistedIds.contains(product.id);
      }
      
      _products = allProducts;
      _updateProductLists(allProducts, city);

      return {
        'products': allProducts,
        'categories': categories,
        'city': city,
        'locationDenied': locationDenied,
      };
    } on SocketException {
      throw Exception('No Internet Connection. Please check your network and try again.');
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _updateProductLists(List<Product> allProducts, String city) {
    final cityLower = city.toLowerCase();
    _nearbyProducts = allProducts.where((p) => 
        p.locationName.toLowerCase().contains(cityLower)
    ).toList();
    final nearbySet = Set.from(_nearbyProducts);
    _otherProducts = allProducts.where((p) => !nearbySet.contains(p)).toList();
  }

  void _onWishlistChanged(int productId, bool isWishlisted) {
    setState(() {
      final product = _productsMap[productId];
      if (product != null) {
        product.isWishlisted = isWishlisted;
      }
    });
  }

  Future<void> _refreshData() async {
    // Invalidate cache on refresh
    _cachedCity = null;
    _lastLocationFetch = null;
    
    setState(() {
      _dataFuture = _loadAllData(forceRefresh: true);
    });
  }

  void _navigateToProductDetails(int productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(productId: productId)
      )
    );
  }

  Widget _buildProductSections(Map<String, dynamic> data) {
    final allProducts = data['products'] as List<Product>;
    final categories = data['categories'] as List<CategoryModel>;
    final city = data['city'] as String;
    final locationDenied = data['locationDenied'] as bool;

    // Update cached lists with fresh data
    _updateProductLists(allProducts, city);

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            const HomeSearchBar(),
            const SizedBox(height: 20),
            CategoriesSection(categories: categories),
            const SizedBox(height: 20),
            LocationSection(
              currentCity: city,
              locationPermissionDenied: locationDenied,
              isLoadingLocation: _isLoadingLocation,
              onRetryLocation: _refreshData,
            ),
            const SizedBox(height: 10),
          ]),
        ),
        if (_nearbyProducts.isNotEmpty) ...[
          _buildSectionTitle('Near You'),
          _buildProductsSection(_nearbyProducts),
        ],
        if (_otherProducts.isNotEmpty) ...[
          _buildSectionTitle('Other Items'),
          _buildProductsSection(_otherProducts),
        ],
        if (allProducts.isEmpty) const SliverToBoxAdapter(child: EmptyState()),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection(List<Product> products) {
    return ProductsSection(
      products: products,
      onProductTap: (product) => _navigateToProductDetails(product.id),
      onWishlistChanged: _onWishlistChanged,
    );
  }

  Widget _buildBody() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerEffects();
        }

        if (snapshot.hasError) {
          return ErrorState(
            error: snapshot.error,
            onRetry: _refreshData,
          );
        }

        if (!snapshot.hasData) {
          return  ErrorState(
            error: 'No data available',
            onRetry: _refreshData,
          );
        }

        return RefreshIndicator.adaptive(
          onRefresh: _refreshData,
          child: _buildProductSections(snapshot.data!),
        );
      },
    );
  }

// Alternative solution - Use PreferredSize wrapper
PreferredSizeWidget _buildAppBar(AppStateManager appState) {
  final bool showMenuBadge = appState.hasUnreadOffers || appState.hasUnreadPayments;

  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: HomeAppBar(
      notificationCount: appState.hasUnreadNotifications ? 1 : 0,
      showMenuBadge: showMenuBadge,
      currentUser: _currentUser,
      onProfileTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const ProfilePage())
      ),
      onNotificationTap: () {
        appState.clearUnreadNotifications();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NotificationPage())
        );
      },
      onMenuSelected: _handleMenuSelection,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: _buildAppBar(appState),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _buildBody(),
        );
      },
    );
  }
  
  void _handleMenuSelection(MenuItem value) {
    final appState = Provider.of<AppStateManager>(context, listen: false);

    switch (value) {
      case MenuItem.item2: // My Listed Items
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MyItemsPage())
        );
        break;
      case MenuItem.item3: // Offers
        appState.clearUnreadOffers();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MyOffersPage())
        );
        break;
      case MenuItem.item4: // Wallet
        appState.clearUnreadPayments();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const WalletPage())
        );
        break;
      case MenuItem.item5: // Payment History
        appState.clearUnreadPayments();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PaymentHistoryPage())
        );
        break;
      case MenuItem.item6: // Rental History
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RentalHistoryPage())
        );
        break;
      case MenuItem.item7: // Wishlist
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const WishlistPage())
        );
        break;
      case MenuItem.item8: // Settings
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsPage())
        );
        break;
      default:
        break;
    }
  }
}