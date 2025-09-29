import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/Offer_DTO/OfferResponse_DTO.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/pages/createofferpage.dart';
import 'package:myfirstflutterapp/pages/main_screen.dart';
import 'package:myfirstflutterapp/services/product_service.dart';
import 'package:myfirstflutterapp/services/booking_service.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/offers_service.dart';
import 'package:myfirstflutterapp/widgets/product_details/product_details_loading_shimmer.dart';
import 'package:myfirstflutterapp/widgets/product_details/product_image_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/product_basic_info_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/owner_info_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/date_selection_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/total_price_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/booking_button_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/product_description_widget.dart';
import 'package:myfirstflutterapp/widgets/product_details/similar_products_widget.dart';

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
  String? currentUserId;
  OfferResponseDTO? _offer;

  @override
  void initState() {
    _productService.trackView(widget.productId);
    super.initState();
    _fetchProduct();
    _loadCurrentUser();
    _fetchOffer();
  }

  Future<void> _loadCurrentUser() async {
    final id = await AuthService().getUserId();
    setState(() {
      currentUserId = id;
    });
  }

  Future<void> _fetchOffer() async {
    try {
      final offer = await OfferService().getOfferByProduct(widget.productId);
      setState(() {
        _offer = offer;
      });
    } catch (e) {
      print("Error fetching offer: $e");
    }
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
      final days = endDate!.difference(startDate!).inDays + 1;

      if (_offer != null && _offer!.status == "Accepted") {
        totalPrice = _offer!.offeredPrice * days;
      } else {
        final pricePerDay = (product!.price is num)
            ? (product!.price as num).toDouble()
            : 0.0;
        totalPrice = pricePerDay * days;
      }
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

    final days = endDate!.difference(startDate!).inDays + 1;

    final calculatedTotalPrice = (_offer != null && _offer!.status == "Accepted") 
        ? _offer!.offeredPrice * days
        : totalPrice!;

    try {
      await _bookingService.createBooking(
        itemId: product!.id,
        startDate: startDate!,
        endDate: endDate!,
        totalPrice: calculatedTotalPrice,
        offerId: (_offer != null && _offer!.status == "Accepted") ? _offer!.id : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking requested successfully!")),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 3),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")));
    }
  }

  void _refreshData() {
    _fetchProduct();
    _fetchOffer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(product?.name ?? ""),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () {
              // TODO: implement share
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const ProductDetailsLoadingShimmer()
            : error != null
                ? Center(child: Text("Error: $error"))
                : product == null
                    ? const Center(child: Text("Product not found"))
                    : _buildProductDetailsContent(),
      ),
    );
  }

  Widget _buildProductDetailsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImageWidget(imageUrl: product!.image),
            const SizedBox(height: 16),
            ProductBasicInfoWidget(product: product!),
            const SizedBox(height: 12),
            OwnerInfoWidget(
              product: product!,
              currentUserId: currentUserId,
              onMakeOffer: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateOfferPage(
                      productName: product!.name,
                      originalPrice: product!.price,
                      productId: product!.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            DateSelectionWidget(
              startDate: startDate,
              endDate: endDate,
              onSelectDates: () => _selectDate(context),
              onClearDates: _clearDates,
            ),
            if (totalPrice != null) ...[
              const SizedBox(height: 12),
              TotalPriceWidget(totalPrice: totalPrice!),
            ],
            const SizedBox(height: 16),
            BookingButtonWidget(
              product: product!,
              currentUserId: currentUserId,
              endDate: endDate,
              offer: _offer,
              onRequestBooking: _requestBooking,
            ),
            const SizedBox(height: 24),
            ProductDescriptionWidget(description: product!.description),
            const SizedBox(height: 24),
            if (similarProducts.isNotEmpty)
              SimilarProductsWidget(similarProducts: similarProducts),
          ],
        ),
      ),
    );
  }
}