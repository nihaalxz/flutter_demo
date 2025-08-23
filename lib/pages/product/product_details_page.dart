import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../environment/env.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/booking_service.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailsPage extends StatefulWidget {
  final int productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ProductService _productService = ProductService();
  final BookingService _bookingService = BookingService();

  Product? product;
  List<Product> similarProducts = [];
  bool isLoading = true;
  String? error;

  DateTime? startDate;
  DateTime? endDate;
  double? totalPrice;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    try {
      setState(() => isLoading = true);
      final fetchedProduct = await _productService.getProductById(widget.productId);
      final fetchedSimilar = await _productService.getSimilarProducts(widget.productId);

      setState(() {
        product = fetchedProduct;
        similarProducts = fetchedSimilar.take(4).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _selectDate(BuildContext context) async {
    final now = DateTime.now();

    final pickedStart = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: pickedStart.add(const Duration(days: 1)),
      firstDate: pickedStart,
      lastDate: DateTime(now.year + 2),
    );

    setState(() {
      startDate = pickedStart;
      endDate = pickedEnd;
      _calculateTotal();
    });
  }

  void _clearDates() {
    setState(() {
      startDate = null;
      endDate = null;
      totalPrice = null;
    });
  }

  void _calculateTotal() {
    if (startDate != null && endDate != null && product != null) {
      final days = endDate!.difference(startDate!).inDays + 1; // inclusive
      // ignore: unnecessary_type_check
      final pricePerDay = (product!.price is num) ? (product!.price as num).toDouble() : 0.0;
      totalPrice = pricePerDay * days;
    } else {
      totalPrice = null;
    }
  }

  void _requestBooking() async {
    if (product == null || startDate == null || endDate == null || totalPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start and end dates")),
      );
      return;
    }

    try {
      await _bookingService.createBooking(
        itemId: product!.id,
        startDate: startDate!,
        endDate: endDate!,
        totalPrice: totalPrice!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking requested successfully!")),
      );

      if (mounted) Navigator.pushNamed(context, "/my-bookings");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFmt = DateFormat.yMMMd();

    final createdAtDt = _asDateTime(product?.createdAt);
    final createdAtLabel = createdAtDt != null
        ? dateFmt.format(createdAtDt)
        : (product?.createdAt.toString() ?? '');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          product?.name ?? "",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: implement share
            },
          ),
        ],
      ),
      // -------- ONLY THE LOADING BRANCH CHANGED TO SHIMMER --------
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title + Price skeleton
                    Row(
                      children: [
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 20,
                            width: 90,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Availability chip skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Owner block skeleton
                    Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(height: 14, width: double.infinity, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(height: 12, width: 120, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 36,
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 24),

                    // Date selection skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 20,
                        width: 140,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 40,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Total price box skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Request button skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description box skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Similar products skeleton row
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return Container(
                              width: 160,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // --------------------- END SHIMMER BRANCH ---------------------
          : error != null
              ? Center(child: Text("Error: $error"))
              : product == null
                  ? const Center(child: Text("Product not found"))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero image (cached + constrained)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CachedNetworkImage(
                                  imageUrl: "${AppConfig.imageBaseUrl}${product!.image}",
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Center(child: Icon(Icons.broken_image, size: 56)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Price + Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product!.name,
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
                                  "${currency.format(product!.price)}/day",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Availability chip
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (product!.availability == true)
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    (product!.availability == true)
                                        ? 'Available for Rent'
                                        : 'Currently Unavailable',
                                    style: TextStyle(
                                      color: (product!.availability == true)
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Owner block
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: (product!.ownerProfileImage != null &&
                                        product!.ownerProfileImage!.isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                        "${AppConfig.imageBaseUrl}${product!.ownerProfileImage!}",
                                      )
                                    : const AssetImage("assets/icons/constant/empty-user-profilepic.webp")
                                        as ImageProvider,
                              ),
                              title: Text(product!.ownerName),
                              subtitle: Text("Posted on $createdAtLabel"),
                              trailing: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: open chat
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text("Chat"),
                              ),
                              onTap: () {
                                // TODO: navigate to owner products page if needed
                              },
                            ),

                            const Divider(height: 24),

                            // Date selection
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Rental Dates"),
                              subtitle: Text(
                                (startDate != null && endDate != null)
                                    ? "${dateFmt.format(startDate!)} → ${dateFmt.format(endDate!)}"
                                    : "Select rental start & end date",
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _selectDate(context),
                                child: const Text("Pick Dates"),
                              ),
                            ),

                            if (startDate != null || endDate != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _clearDates,
                                  child: const Text("Clear selection"),
                                ),
                              ),

                            if (totalPrice != null)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Total Estimated Price",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      currency.format(totalPrice),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Request button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (product!.availability == true && endDate != null)
                                    ? _requestBooking
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Request Rental"),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Description
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Description",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(product!.description),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Similar products
                            if (similarProducts.isNotEmpty) ...[
                              const Text(
                                "Similar Products",
                                style: TextStyle(
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
                                    final sim = similarProducts[index];
                                    return Container(
                                      width: 160,
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    '${AppConfig.imageBaseUrl}${sim.image}',
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                      child: CircularProgressIndicator()),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    const Icon(Icons.error, size: 40),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            sim.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "${currency.format(sim.price)}/day",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProductDetailsPage(productId: sim.id),
                                                ),
                                              );
                                            },
                                            child: const Text("View"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }
}
