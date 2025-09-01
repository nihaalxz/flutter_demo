import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Assumed Imports ---
import '../services/search_service.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';
import 'package:myfirstflutterapp/pages/product/product_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  List<String> _locations = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  // Filters
  String? _selectedLocation;
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Load recent searches and filter options
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });

    try {
      final locations = await _searchService.getLocations();
      final categories = await _categoryService.getCategories();
      setState(() {
        _locations = locations;
        _categories = categories;
      });
    } catch (e) {
      // Handle error loading filters
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Debounce search input to avoid excessive API calls for suggestions
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _fetchSuggestions(_searchController.text);
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _fetchSuggestions(String term) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final suggestions = await _searchService.getSuggestions(term);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      // Handle error silently for suggestions
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save a search term and perform the search
  void _performSearch(String query) async {
    if (query.isEmpty) return;

    // Save to recent searches
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }
    await prefs.setStringList('recent_searches', _recentSearches);

    // Navigate to results page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductResultsPage(
          searchQuery: query,
          location: _selectedLocation,
          categoryId: _selectedCategory?.id,
        ),
      ),
    );
  }

  void _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recent searches cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(theme),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(0, 184, 184, 184).withValues(),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(45, 0, 0, 0).withValues(),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.colorScheme.onSurface.withValues(),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _performSearch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _suggestions.isEmpty && _searchController.text.isNotEmpty) {
      return _buildLoadingState();
    }

    // Show suggestions if user is typing, otherwise show history and filters
    if (_searchController.text.isNotEmpty && _suggestions.isNotEmpty) {
      return _buildSuggestionsList();
    } else {
      return _buildHistoryAndFilters();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Display autocomplete suggestions
  Widget _buildSuggestionsList() {
    final theme = Theme.of(context);
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: theme.colorScheme.outline.withValues(),
      ),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Icon(
            Icons.search,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            suggestion,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.arrow_outward,
            color: theme.colorScheme.onSurface.withValues(),
            size: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  /// Display recent searches and filter options
  Widget _buildHistoryAndFilters() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Extra bottom padding for button
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildRecentSearchesSection(theme),
            const SizedBox(height: 32),
          ],
          _buildFiltersSection(theme),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _recentSearches
              .map(
                (term) => ActionChip(
                  avatar: Icon(
                    Icons.history,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    term,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(),
                    ),
                  ),
                  onPressed: () {
                    _searchController.text = term;
                    _performSearch(term);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        _buildEnhancedCategoryFilter(theme),
        const SizedBox(height: 20),
        _buildEnhancedLocationFilter(theme),
        const SizedBox(height: 32),
        _buildSearchButton(theme),
      ],
    );
  }

  Widget _buildEnhancedCategoryFilter(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(50, 0, 0, 0).withValues(),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<CategoryModel>(
        value: _selectedCategory,
        hint: Text(
          'All Categories',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(),
          ),
        ),
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: theme.colorScheme.primary,
        ),
        decoration: InputDecoration(
          labelText: 'Category',
          labelStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.category_outlined,
            color: theme.colorScheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        dropdownColor: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        onChanged: (CategoryModel? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        items: _categories.map((CategoryModel category) {
          return DropdownMenuItem<CategoryModel>(
            value: category,
            child: Text(
              category.name,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedLocationFilter(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(112, 0, 0, 0).withValues(),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedLocation,
        hint: Text(
          'Anywhere',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(),
          ),
        ),
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: theme.colorScheme.primary,
        ),
        decoration: InputDecoration(
          labelText: 'Location',
          labelStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.location_on_outlined,
            color: theme.colorScheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        dropdownColor: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        onChanged: (String? newValue) {
          setState(() {
            _selectedLocation = newValue;
          });
        },
        items: _locations.map((String location) {
          return DropdownMenuItem<String>(
            value: location,
            child: Text(
              location,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _performSearch(_searchController.text),
        icon: const Icon(Icons.search_rounded),
        label: const Text(
          'Apply Filters & Search',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 3,
          shadowColor: theme.colorScheme.primary.withValues(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}