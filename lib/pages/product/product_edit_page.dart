import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:myfirstflutterapp/models/Product_DTO/Product_update_dto.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/services/category_service.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/pages/map_picker_page.dart';

class ProductEditPage extends StatefulWidget {
  final Product product;
  const ProductEditPage({super.key, required this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _locationController;

  bool _availability = true;
  File? _pickedImage;
  bool _isSaving = false;
  LatLng? _selectedCoordinates;

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descController = TextEditingController(text: widget.product.description);
    _locationController = TextEditingController(text: widget.product.locationName);
    _availability = widget.product.availability;

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _selectedCategoryId = widget.product.categoryId;
          if (!_categories.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load categories: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

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

  /// Compress image and convert to .jpg
  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      File? imageToUpload;
      if (_pickedImage != null) {
        imageToUpload = await _compressImage(_pickedImage!);
        if (imageToUpload == null) {
          throw Exception("Failed to process the image.");
        }
      }

      final updateDto = ProductUpdateDto(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        locationName: _locationController.text,
        availability: _availability,
        latitude: _selectedCoordinates?.latitude ?? widget.product.latitude!,
        longitude: _selectedCoordinates?.longitude ?? widget.product.longitude!,
      );

      await _productService.updateItem(
        widget.product.id,
        updateDto,
        imageFile: imageToUpload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Product updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Item")),
      body: SafeArea(
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildTextField(_nameController, "Item Name", "e.g., Canon EOS R5 Camera"),
                    const SizedBox(height: 16),
                    _buildTextField(_descController, "Description", "e.g., Condition, accessories included, etc.", maxLines: 4),
                    const SizedBox(height: 16),
                    _buildTextField(_priceController, "Price per Day (₹)", "e.g., 1500", keyboardType: TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 16),
                    _buildLocationPicker(),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Item is available for rent"),
                      value: _availability,
                      onChanged: (value) => setState(() => _availability = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Save Changes"),
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _pickedImage != null
                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: "${AppConfig.imageBaseUrl}${widget.product.image}",
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Change Image",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a $label' : null,
    );
  }

  Widget _buildLocationPicker() {
    return InkWell(
      onTap: _openMapPicker,
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(child: Text(_locationController.text, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.map_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
      hint: const Text('Select a Category'),
      isExpanded: true,
      onChanged: (int? newValue) => setState(() => _selectedCategoryId = newValue),
      items: _categories.map((CategoryModel category) => DropdownMenuItem<int>(
        value: category.id,
        child: Text(category.name),
      )).toList(),
      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }
}
