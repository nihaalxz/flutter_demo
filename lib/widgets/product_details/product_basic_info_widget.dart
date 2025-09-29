import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/models/product_model.dart';

class ProductBasicInfoWidget extends StatelessWidget {
  final Product product;

  const ProductBasicInfoWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${currency.format(product.price)}/day",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Availability Chip
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: product.availability == true ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                product.availability == true ? 'Available for Rent' : 'Currently Unavailable',
                style: TextStyle(
                  color: product.availability == true ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Location
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 4),
            Text(
              product.locationName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.appBarTheme.foregroundColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}