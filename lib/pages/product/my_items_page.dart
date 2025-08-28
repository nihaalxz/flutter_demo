import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/pages/product/create_listing_page.dart';
import 'package:myfirstflutterapp/pages/product/product_edit_page.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../environment/env.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  final ProductService _productService = ProductService();

  List<Product> _myItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _productService.getMyItems();
      setState(() {
        _myItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _deleteItem(int itemId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(backgroundColor: Colors.red[100]),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _productService.deleteItem(itemId);
                  setState(() => _myItems.removeWhere((i) => i.id == itemId));
                  _showSnackBar('Item deleted successfully.', isError: false);
                } catch (e) {
                  _showSnackBar('Failed to delete item.', isError: true);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _toggleAvailability(Product item) async {
    final oldAvailability = item.availability;

    setState(() {
      final index = _myItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _myItems[index].availability = !oldAvailability;
      }
    });

    try {
      final updated = await _productService.toggleAvailability(item.id);
      setState(() {
        final index = _myItems.indexWhere((i) => i.id == item.id);
        if (index != -1) _myItems[index] = updated;
      });
      _showSnackBar(
        updated.availability ? 'Marked as Available' : 'Marked as Unavailable',
        isError: false,
      );
    } catch (_) {
      setState(() {
        final index = _myItems.indexWhere((i) => i.id == item.id);
        if (index != -1) _myItems[index].availability = oldAvailability;
      });
      _showSnackBar('Failed to update availability.', isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[400] : Colors.green[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Items'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildShimmerLoader()
          : _error != null
              ? _buildErrorState(_error!)
              : _myItems.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myItems.length,
                        itemBuilder: (context, i) =>
                            _buildItemCard(_myItems[i]),
                      ),
                    ),
    );
  }

  Widget _buildItemCard(Product item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: "${AppConfig.imageBaseUrl}${item.image}",
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("Category: ${item.categoryName}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                            .format(item.price),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text("Location: ${item.locationName}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13,fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Text("Views: ${item.views}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),


                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.availability
                        ? Colors.green[50]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    item.availability ? "Available" : "Unavailable",
                    style: TextStyle(
                      color: item.availability
                          ? Colors.green[700]
                          : const Color.fromARGB(255, 236, 8, 8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                MaterialPageRoute(builder: (context) =>  ProductEditPage(product: item)),
              );
                  }, // edit
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: () => _deleteItem(item.id),
                  child: const Text('Delete'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: item.availability
                        ? Colors.grey[600]
                        : Colors.green[600],
                  ),
                  onPressed: () => _toggleAvailability(item),
                  child: Text(
                    item.availability
                        ? 'Mark Unavailable'
                        : 'Mark Available',
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text("No items posted",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("Start by posting an item for rent.",
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CreateListingPage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Post an Item"),
              )
            ],
          ),
        ),
      );

  Widget _buildErrorState(String err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(err, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadItems, child: const Text("Retry")),
          ],
        ),
      );
}
