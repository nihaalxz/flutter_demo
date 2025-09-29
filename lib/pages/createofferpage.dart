import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/offers_service.dart';

class CreateOfferPage extends StatefulWidget {
  final String productName;
  final double originalPrice;
  final int productId;

  const CreateOfferPage({
    super.key,
    required this.productName,
    required this.originalPrice,
    required this.productId,
  });

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _offerService = OfferService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isLoading = true);

    final offerValue = double.parse(_controller.text.trim());

    try {
      await _offerService.createOffer(widget.productId, offerValue);
      if (mounted) {
        _showFeedback(
          isError: false,
          title: "Offer Submitted!",
          content: "The owner has been notified of your offer.",
          onDismiss: () => Navigator.of(context).pop(),
        );
      }
    } catch (e) {
      if (mounted) {
        _showFeedback(
          isError: true,
          title: "Submission Failed",
          content: e.toString().replaceAll("Exception: ", ""),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFeedback({
    required bool isError,
    required String title,
    required String content,
    VoidCallback? onDismiss,
  }) {
    if (Platform.isIOS) {
      // Use Cupertino-style dialog for iOS
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
            ),
          ],
        ),
      );
    } else {
      // Use Material-style dialog for Android
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
            ),
          ],
        ),
      );
    }
  }

  String? _validateOffer(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter an offer price.";
    }
    final offerValue = double.tryParse(value);
    if (offerValue == null || offerValue <= 0) {
      return "Please enter a valid positive number.";
    }
    if (offerValue >= widget.originalPrice) {
      return "Offer should be less than the seller's price.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }

  Widget _buildMaterialPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offer for ${widget.productName}"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Offer for ${widget.productName}"),
      ),
      child: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Platform.isIOS
                  ? CupertinoColors.secondarySystemGroupedBackground
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Original Price:", style: TextStyle(fontSize: 18)),
                Text(
                  "₹${widget.originalPrice.toStringAsFixed(2)} / day",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Your Offer',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the amount you\'d like to offer per day. The owner will be notified.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Adaptive Text Field
          TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Offer Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            validator: _validateOffer,
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator.adaptive())
          else
            // Adaptive Button
            Platform.isIOS
                ? CupertinoButton.filled(
                    onPressed: _sendOffer,
                    child: const Text("Submit Offer"),
                  )
                : ElevatedButton(
                    onPressed: _sendOffer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Submit Offer"),
                  ),
        ],
      ),
    );
  }
}