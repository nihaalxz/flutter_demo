import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../models/product_model.dart';
import '../services/offers_service.dart';
import '../environment/env.dart';

class OffersPage extends StatefulWidget {
  final Product product;

  const OffersPage({super.key, required this.product});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final _formKey = GlobalKey<FormState>();
  final _offerController = TextEditingController();
  final _offerService = OfferService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    // ✅ --- THIS IS THE KEY FIX ---
    // Use a null-aware check (`?.`) to safely validate the form.
    // The `?? false` ensures that if the form state is null, we treat it as invalid.
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    // ----------------------------

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_offerController.text);
      await _offerService.createOffer(widget.product.id, amount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your offer has been sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoPage() : _buildMaterialPage();
  }

  Widget _buildMaterialPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make an Offer'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildCupertinoPage() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Make an Offer'),
      ),
      child: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProductHeader(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          Text(
            'Your Offer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the amount you\'d like to offer per day. The owner will be notified of your offer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _offerController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Offer Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            validator: _validateOffer,
          ),
          const SizedBox(height: 32),

          if (_isSubmitting)
            const Center(child: CircularProgressIndicator.adaptive())
          else
            ElevatedButton(
              onPressed: _submitOffer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Offer'),
            ),
        ],
      ),
    );
  }
  
  String? _validateOffer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount.';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number.';
    }
    if (amount >= widget.product.price) {
      return 'Your offer must be less than the current price.';
    }
    if (amount <= 0) {
      return 'Offer must be a positive amount.';
    }
    return null;
  }

  Widget _buildProductHeader() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: "${AppConfig.imageBaseUrl}${widget.product.image}",
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Current Price: ₹${widget.product.price.toStringAsFixed(2)} / day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
