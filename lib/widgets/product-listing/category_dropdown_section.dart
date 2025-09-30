import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class CategoryDropdownSection extends StatelessWidget {
  final Future<List<CategoryModel>> categoriesFuture;
  final CategoryModel? selectedCategory;
  final Function(CategoryModel?) onCategorySelected;

  const CategoryDropdownSection({
    super.key,
    required this.categoriesFuture,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.category_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<CategoryModel>>(
            future: categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Material(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.6), // Thicker border
                        width: 1.0, // Increased border width
                      ),
                    ),
                    child: Row(
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading categories...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Material(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  elevation: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.6), // Thicker border
                        width: 2.0, // Increased border width
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Could not load categories',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final categories = snapshot.data!;
              return Material(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
                elevation: 1,
                child: DropdownButtonFormField<CategoryModel>(
                  value: selectedCategory,
                  hint: Text('Select a category', style: Theme.of(context).textTheme.bodyMedium),
                  isExpanded: true,
                  onChanged: onCategorySelected,
                  items: categories.map((CategoryModel category) {
                    return DropdownMenuItem<CategoryModel>(
                      value: category,
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.6), // Thicker border
                        width: 2.0, // Increased border width
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  validator: (value) => value == null ? 'Please select a category' : null,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}