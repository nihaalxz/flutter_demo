import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfirstflutterapp/models/Product_DTO/Product_update_dto.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/services/category_service.dart';
import 'package:myfirstflutterapp/environment/env.dart';

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

  bool _availability = true;
  File? _pickedImage;
  bool _isSaving = false;

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _descController = TextEditingController(text: widget.product.description);
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

          // safety check: if category was deleted
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updateDto = ProductUpdateDto(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        location: widget.product.location, // keep old location
        availability: _availability,
      );

      await _productService.updateItem(
        widget.product.id,
        updateDto,
        imageFile: _pickedImage,
      );

      if (mounted) {
        // ✅ show success first
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Product updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ pop after short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: $e"),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image preview
                    GestureDetector(
                      onTap: _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _pickedImage != null
                            ? Image.file(
                                _pickedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                "${AppConfig.imageBaseUrl}${widget.product.image}",
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      size: 60, color: Colors.grey),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Product Name",
                            border: InputBorder.none,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter product name" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Price (₹)",
                            border: InputBorder.none,
                            prefixText: "₹ ",
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter price" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<int>(
                          value: _categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                          items: _categories
                              .map((cat) => DropdownMenuItem<int>(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategoryId = val),
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: InputBorder.none,
                          ),
                          validator: (v) =>
                              v == null ? "Select a category" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Availability
                    SwitchListTile(
                      title: const Text("Available"),
                      value: _availability,
                      onChanged: (v) => setState(() => _availability = v),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.grey[100],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("Save Changes"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: _saveProduct,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
