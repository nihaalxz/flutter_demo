import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myfirstflutterapp/pages/map_picker_page.dart';

class FormFieldsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController locationController;
  final LatLng? selectedCoordinates;
  final Function(String, LatLng) onLocationSelected;

  const FormFieldsSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.locationController,
    required this.selectedCoordinates,
    required this.onLocationSelected,
  });

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (result != null) {
      onLocationSelected(
        result['address'] as String,
        result['coordinates'] as LatLng,
      );
    }
  }

  Widget _buildModernTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Material(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a $label';
              }
              if (label.contains('Price') && double.tryParse(value) == null) {
                return 'Please enter a valid price';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernLocationPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Material(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          child: InkWell(
            onTap: () => _openMapPicker(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.6), // Thicker border
                  width: 2.0, // Increased border width
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationController.text.isEmpty ? 'Select location from map' : locationController.text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: locationController.text.isEmpty 
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (locationController.text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap to change location',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.map_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildModernTextField(
            context: context,
            controller: nameController,
            label: 'Item Name',
            icon: Icons.shopping_bag_outlined,
            hint: 'e.g., Canon EOS R5 Camera',
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            context: context,
            controller: descriptionController,
            label: 'Description',
            icon: Icons.description_outlined,
            hint: 'Condition, accessories included, etc.',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            context: context,
            controller: priceController,
            label: 'Price per Day (₹)',
            icon: Icons.currency_rupee_rounded,
            hint: 'e.g., 1500',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildModernLocationPicker(context),
        ],
      ),
    );
  }
}