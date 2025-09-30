import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Services
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import 'my_items_page.dart';
import '../map_picker_page.dart';

// Widget Components
import 'package:myfirstflutterapp/widgets/product-listing/category_dropdown_section.dart';
import 'package:myfirstflutterapp/widgets/product-listing/form_fields_section.dart';
import 'package:myfirstflutterapp/widgets/product-listing/image_picker_section.dart';
import 'package:myfirstflutterapp/widgets/product-listing/submit_button_section.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> with SingleTickerProviderStateMixin {
  // Services
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  CategoryModel? _selectedCategory;
  File? _selectedImage;
  LatLng? _selectedCoordinates;

  // UI state
  bool _isLoading = false;
  late Future<List<CategoryModel>> _categoriesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryService.getCategories();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Callbacks for child widgets
  void _onImagePicked(File image) {
    setState(() {
      _selectedImage = image;
    });
  }

  void _onLocationSelected(String address, LatLng coordinates) {
    setState(() {
      _locationController.text = address;
      _selectedCoordinates = coordinates;
    });
  }

  void _onCategorySelected(CategoryModel? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  /// Validates the form and submits the new listing
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a location from the map.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    _setLoading(true);

    try {
      final newProduct = Product(
        id: 0,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        categoryId: _selectedCategory!.id,
        locationName: _locationController.text,
        latitude: _selectedCoordinates!.latitude,
        longitude: _selectedCoordinates!.longitude,
        image: '',
        categoryName: _selectedCategory!.name,
        ownerId: '',
        ownerName: '',
        availability: true,
        createdAt: DateTime.now(),
        status: 'Pending',
        views: 0,
      );

      await _productService.createProduct(
        product: newProduct,
        image: _selectedImage!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Listing created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyItemsPage()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create listing: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Create New Listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Your Item',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details to list your item for rent',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      ImagePickerSection(
                        selectedImage: _selectedImage,
                        onImagePicked: _onImagePicked,
                      ),
                      const SizedBox(height: 32),
                      FormFieldsSection(
                        nameController: _nameController,
                        descriptionController: _descriptionController,
                        priceController: _priceController,
                        locationController: _locationController,
                        selectedCoordinates: _selectedCoordinates,
                        onLocationSelected: _onLocationSelected,
                      ),
                      const SizedBox(height: 20),
                      CategoryDropdownSection(
                        categoriesFuture: _categoriesFuture,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _onCategorySelected,
                      ),
                      const SizedBox(height: 40),
                      SubmitButtonSection(
                        isLoading: _isLoading,
                        onSubmit: _submitListing,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}