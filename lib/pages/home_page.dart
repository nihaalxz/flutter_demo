import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/models/user_model.dart';
import 'package:myfirstflutterapp/pages/auth/profile_page.dart';
import 'package:myfirstflutterapp/pages/gen/settings_page.dart';
import 'package:myfirstflutterapp/pages/myOffers.dart';
import 'package:myfirstflutterapp/pages/notification_page.dart';
import 'package:myfirstflutterapp/pages/payments/payment_history_page.dart';
import 'package:myfirstflutterapp/pages/payments/wallet_page.dart';
import 'package:myfirstflutterapp/pages/product/my_items_page.dart';
import 'package:myfirstflutterapp/pages/rental_history_page.dart';
import 'package:myfirstflutterapp/pages/wishlist_page.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/category_service.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/state/AppStateManager.dart';
import 'package:myfirstflutterapp/widgets/categories_section.dart';
import 'package:myfirstflutterapp/widgets/error_empty_states.dart';
import 'package:myfirstflutterapp/widgets/home_app_bar.dart';
import 'package:myfirstflutterapp/widgets/home_search_bar.dart';
import 'package:myfirstflutterapp/widgets/location_dropdown.dart';
import 'package:myfirstflutterapp/widgets/product_card.dart';
import 'package:myfirstflutterapp/widgets/shimmer_effects.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final AuthService _authService;
  late final ProductService _productService;
  late final CategoryService _categoryService;

  AppUser? _currentUser;
  List<CategoryModel> _categories = [];
  bool _isLoadingStaticData = true;
  Object? _staticDataError;

  final List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();
  DateTime? _cursor;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  String? _selectedLocation;
  Timer? _locationChangeDebounce;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _productService = ProductService();
    _categoryService = CategoryService();

    _scrollController.addListener(_onScroll);
    _restoreStateAndInitialize();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _locationChangeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _restoreStateAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('saved_location');
    
    if (mounted) {
      setState(() {
        _selectedLocation = savedLocation;
      });
    }
    
    await _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingStaticData = true;
      _staticDataError = null;
      _products.clear();
      _cursor = null;
      _hasNextPage = true;
    });

    _loadUserProfile();

    try {
      await Future.wait([
        _loadCategories(),
        _fetchProductPage(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _staticDataError = e);
    } finally {
      if (mounted) setState(() => _isLoadingStaticData = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories(forceRefresh: true);
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getUserProfile();
      if (mounted) setState(() => _currentUser = user);
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  Future<void> _fetchProductPage() async {
    if (_isLoadingMore || !_hasNextPage) return;

    setState(() => _isLoadingMore = true);

    try {
      final page = await _productService.fetchProductsCursor(
        cursor: _cursor,
        pageSize: 9,
        location: _selectedLocation,
      );

      if (mounted) {
        setState(() {
          _products.addAll(page.items);
          _cursor = page.nextCursor;
          _hasNextPage = _cursor != null;
        });
      }
    } catch (error) {
      debugPrint('Error fetching products: $error');
      
      if (_products.isEmpty) {
        rethrow;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Could not load more items')),
                ],
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _fetchProductPage,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final delta = maxScroll - currentScroll;
      
      if (delta <= 200 && !_isLoadingMore && _hasNextPage) {
        _fetchProductPage();
      }
    }
  }

  void _onLocationChanged(String? newLocation) {
    _locationChangeDebounce?.cancel();
    
    _locationChangeDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _selectedLocation = newLocation;
          _products.clear();
          _cursor = null;
          _hasNextPage = true;
        });
        _fetchProductPage();
      }
    });
  }

  void _onWishlistChanged(int productId, bool isWishlisted) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      setState(() => _products[index].isWishlisted = isWishlisted);
    }
  }

  String _getLocationDisplayText() {
    if (_selectedLocation == null) {
      return "Items from All Kerala";
    } else if (_selectedLocation == 'current_location') {
      return "Items Near You";
    } else {
      return "Items near $_selectedLocation";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: _buildAppBar(appState),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator.adaptive(
            onRefresh: _initializeData,
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoadingStaticData && _products.isEmpty) {
      return const ShimmerEffects(message: "Getting things ready...");
    }

    if (_staticDataError != null && _products.isEmpty) {
      return ErrorState(error: _staticDataError, onRetry: _initializeData);
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate.fixed([
            const HomeSearchBar(),
            const SizedBox(height: 20),
            CategoriesSection(categories: _categories),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getLocationDisplayText(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ]),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = _products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductCard(
                    product: product,
                    onWishlistChanged: _onWishlistChanged,
                  ),
                );
              },
              childCount: _products.length,
            ),
          ),
        ),
        
        if (_isLoadingMore)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
        
        if (_products.isEmpty && !_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLocation != null 
                        ? 'No items found in $_selectedLocation'
                        : 'No items available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _selectedLocation = null);
                        _fetchProductPage();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Show all items'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(AppStateManager appState) {
    final bool showMenuBadge =
        appState.hasUnreadOffers || appState.hasUnreadPayments;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 50),
      child: Column(
        children: [
          HomeAppBar(
            notificationCount: appState.hasUnreadNotifications ? 1 : 0,
            showMenuBadge: showMenuBadge,
            currentUser: _currentUser,
            onProfileTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
            onNotificationTap: () {
              appState.clearUnreadNotifications();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
            onMenuSelected: _handleMenuSelection,
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Color.fromARGB(255, 0, 0, 0)),
                const SizedBox(width: 8),
                Expanded(
                  child: LocationDropdown(
                    selectedLocation: _selectedLocation,
                    onLocationChanged: _onLocationChanged,
                    productService: _productService,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(MenuItem value) {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    switch (value) {
      case MenuItem.item2:
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyItemsPage()));
        break;
      case MenuItem.item3:
        appState.clearUnreadOffers();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyOffersPage()));
        break;
      case MenuItem.item4:
        appState.clearUnreadPayments();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WalletPage()));
        break;
      case MenuItem.item5:
        appState.clearUnreadPayments();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PaymentHistoryPage()));
        break;
      case MenuItem.item6:
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RentalHistoryPage()));
        break;
      case MenuItem.item7:
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WishlistPage()));
        break;
      case MenuItem.item8:
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
      default:
        break;
    }
  }
}