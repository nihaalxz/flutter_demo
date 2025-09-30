import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/pages/product/product_details_page.dart';
import 'package:myfirstflutterapp/state/main_tab_notifier.dart';
import 'package:provider/provider.dart';

class SimilarProductsWidget extends StatelessWidget {
  final List<Product> similarProducts;

  const SimilarProductsWidget({super.key, required this.similarProducts});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Similar Products",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similarProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = similarProducts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(productId: product.id),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: '${AppConfig.imageBaseUrl}${product.image}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.error,
                              size: 40,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Product Name
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      
                      // Price
                      Text(
                        "${currency.format(product.price)}/day",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.locationName,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Availability
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: product.availability == true ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              product.availability == true ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                color: product.availability == true ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}