import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// --- Assumed Imports ---
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import 'my_items_page.dart';
import '../map_picker_page.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
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

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryService.getCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Shows a modal bottom sheet to choose between camera and gallery.
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Navigates to the map picker page.
  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        _locationController.text = result['address'] as String;
        _selectedCoordinates = result['coordinates'] as LatLng;
      });
    }
  }
  
  /// Compresses the selected image file to reduce its size before upload.
  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85, // A quality of 80-85 is a great balance.
      minWidth: 1024, // Optional: resize larger images
      minHeight: 1024,
    );

    if (compressedXFile == null) return null;
    return File(compressedXFile.path);
  }

  /// Validates the form and submits the new listing with a compressed image.
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location from the map.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Compress the image before creating the product object
      final compressedImageFile = await _compressImage(_selectedImage!);
      if (compressedImageFile == null) {
        throw Exception("Failed to process the image.");
      }
      
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
        image: compressedImageFile, // Use the compressed file for the upload
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully!'), backgroundColor: Colors.green),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyItemsPage()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create listing: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Listing'),
      ),
      body: SafeArea( // ✅ Added SafeArea here
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Item Name', 'e.g., Canon EOS R5 Camera'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', 'e.g., Condition, accessories included, etc.', maxLines: 4),
              const SizedBox(height: 16),
              _buildTextField(_priceController, 'Price per Day (₹)', 'e.g., 1500', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildLocationPicker(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitListing,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Post My Item'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 40),
                    const SizedBox(height: 8),
                    Text('Tap to add a photo', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a $label';
        }
        return null;
      },
    );
  }

  Widget _buildLocationPicker() {
    return InkWell(
      onTap: _openMapPicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Location',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                _locationController.text.isEmpty
                    ? 'Select location from map'
                    : _locationController.text,
                style: TextStyle(
                  color: _locationController.text.isEmpty ? Colors.grey[600] : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.map_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Could not load categories.');
        }
        final categories = snapshot.data!;
        return DropdownButtonFormField<CategoryModel>(
          value: _selectedCategory,
          hint: const Text('Select a Category'),
          isExpanded: true,
          onChanged: (CategoryModel? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          items: categories.map((CategoryModel category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Text(category.name),
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null ? 'Please select a category' : null,
        );
      },
    );
  }
}
