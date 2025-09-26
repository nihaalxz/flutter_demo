import 'package:flutter/material.dart';
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
import 'package:myfirstflutterapp/pages/offer_page.dart';
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

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  
  late Future<Map<String, dynamic>> _dataFuture;
  AppUser? _currentUser;
  bool _isFirstLoad = true;
  List<Product> _products = [];
  
  // ✅ NEW: Added state for location loading to fix the error
  bool _isLoadingLocation = true;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      setState(() {
        _dataFuture = loadData();
        _isFirstLoad = false;
      });
      _loadUserProfile();
    }
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
    try {
      final productService = ProductService();
      final categoryService = CategoryService();
      final wishlistService = WishlistService();

      String city = "Loading...";
      bool locationDenied = false;

      // ✅ Update loading state for location
      if (mounted) setState(() => _isLoadingLocation = true);

      try {
        final position = await LocationService.getCurrentPosition();
        city = await LocationService.getCityFromCoordinates(position);
      } on LocationServiceException catch (e) {
        locationDenied = e.type == LocationErrorType.permissionDenied ||
            e.type == LocationErrorType.permissionDeniedForever;
        city = "Location access denied";
      } catch (e) {
        city = "Unable to determine location";
      } finally {
        if (mounted) setState(() => _isLoadingLocation = false);
      }

      final results = await Future.wait([
        productService.fetchProducts(forceRefresh: forceRefresh),
        categoryService.getCategories(forceRefresh: forceRefresh),
        wishlistService.getWishlist(),
      ]);

      final allProducts = results[0] as List<Product>;
      final categories = results[1] as List<CategoryModel>;
      final wishlistItems = results[2] as List<WishlistItemModel>;
      
      final wishlistedIds = wishlistItems.map((item) => item.itemId).toSet();
      for (var product in allProducts) {
        product.isWishlisted = wishlistedIds.contains(product.id);
      }
      
      _products = allProducts;

      return {
        'products': allProducts,
        'categories': categories,
        'city': city,
        'locationDenied': locationDenied,
      };
    } on SocketException {
      throw Exception('No Internet Connection. Please check your network and try again.');
    } catch(e) {
      rethrow;
    }
  }

  void _onWishlistChanged(int productId, bool isWishlisted) {
    setState(() {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index].isWishlisted = isWishlisted;
      }
    });
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
        final bool showMenuBadge = appState.hasUnreadOffers || appState.hasUnreadPayments;

        return Scaffold(
          appBar: HomeAppBar(
            notificationCount: appState.hasUnreadNotifications ? 1 : 0,
            showMenuBadge: showMenuBadge,
            currentUser: _currentUser,
            onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
            onNotificationTap: () {
                appState.clearUnreadNotifications();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationPage()));
            },
            onMenuSelected: _handleMenuSelection,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: FutureBuilder<Map<String, dynamic>>(
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
              
              final allProducts = snapshot.data!['products'] as List<Product>;
              final categories = snapshot.data!['categories'] as List<CategoryModel>;
              final city = snapshot.data!['city'] as String;
              final locationDenied = snapshot.data!['locationDenied'] as bool;
              
              final nearbyProducts = allProducts.where((p) => p.locationName.toLowerCase().contains(city.toLowerCase())).toList();
              final otherProducts = allProducts.where((p) => !nearbyProducts.contains(p)).toList();

              return RefreshIndicator.adaptive(
                onRefresh: _refreshData,
                child: CustomScrollView(
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
                          // ✅ FIX: Pass the loading state to the widget
                          isLoadingLocation: _isLoadingLocation, 
                          onRetryLocation: _refreshData,
                        ),
                        const SizedBox(height: 10),
                      ]),
                    ),
                    if (nearbyProducts.isNotEmpty)
                       ProductsSection(
                          products: nearbyProducts,
                          onProductTap: (product) => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductDetailsPage(productId: product.id))),
                          onWishlistChanged: _onWishlistChanged,
                       ),
                    if (otherProducts.isNotEmpty) const OtherProductsSection(),
                    if (otherProducts.isNotEmpty)
                      ProductsSection(
                          products: otherProducts,
                          onProductTap: (product) => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductDetailsPage(productId: product.id))),
                          onWishlistChanged: _onWishlistChanged,
                      ),
                    if (allProducts.isEmpty) const EmptyState(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  void _handleMenuSelection(MenuItem value) {
    final appState = Provider.of<AppStateManager>(context, listen: false);

    switch (value) {
      case MenuItem.item2: // My Listed Items
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyItemsPage()));
        break;
      case MenuItem.item3: // Offers
        appState.clearUnreadOffers();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OffersPage()));
        break;
      case MenuItem.item4: // Wallet
        appState.clearUnreadPayments();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WalletPage()));
        break;
      case MenuItem.item5: // Payment History
        appState.clearUnreadPayments();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PaymentHistoryPage()));
        break;
      case MenuItem.item6: // Rental History
         Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RentalHistoryPage()));
        break;
      case MenuItem.item7: // Wishlist
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WishlistPage()));
        break;
      case MenuItem.item8: // Settings
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
      default:
        break;
    }
  }
}

